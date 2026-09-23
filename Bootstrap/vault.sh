#!/usr/bin/env bash
#
# Vaultwarden credential helper for the dotfiles repo.
#
# Centralizes CLI/SSH/API credentials in a self-hosted Vaultwarden instance
# (Bitwarden-compatible, accessed through the `bw` CLI). The script can install
# and configure the CLI, log in, unlock the vault, export secrets to the
# environment, sync OpenCode credentials, restore App Store Connect files, and
# load SSH keys into an ssh-agent (Bitwarden desktop agent first, `ssh-add`
# fallback).
#
# Usage:
#   vault.sh init                     Install/configure/log in/unlock (idempotent)
#   vault.sh status                   Show CLI, server, account and lock status
#   vault.sh unlock [--print]         Unlock, cache session/env, sync credentials
#   vault.sh lock                     Lock the vault and clear cached secrets
#   vault.sh export                   Print export lines for the cached session
#   vault.sh get <item> [field]       Print a secret (password|username|notes|field)
#   vault.sh put <item> [options]     Store a login item (password from stdin/prompt)
#   vault.sh env [--print]            Export env vars listed in vault-env.conf
#   vault.sh sync-opencode            Regenerate OpenCode auth.json from the vault
#   vault.sh ssh-load [--print]       Ensure ssh-agent and load vault SSH keys
#   vault.sh ssh-upload <keyfile> [name]
#                                     Store a local SSH key pair in the vault
#   vault.sh gh-upload                Store the current gh token in the vault
#   vault.sh gh-login                 Authenticate gh from the vault token
#   vault.sh asc-restore              Restore ~/.config/app-store-connect from vault
#   vault.sh asc-upload               Store ~/.config/app-store-connect in the vault
#
# Configuration (environment overrides):
#   VAULT_SERVER_URL       Vaultwarden base URL (default https://vault.abacate.top)
#   VAULT_ACCOUNT          Account email (default machines@abacate.top)
#   VAULT_KEYCHAIN_SERVICE Keychain service name (default vault.abacate.top)
#   VAULT_CACHE_DIR        Session/env cache (default ~/.cache/dotfiles/vault)
#   VAULT_ENV_CONF         Env mapping file (default Bootstrap/vault-env.conf)
#   VAULT_SSH_ITEM_PREFIX  SSH key item prefix (default SSH_KEY_)
#   BW_PASSWORD            Master password, bypasses keychain/prompt
#
# The master password is read from BW_PASSWORD, then the macOS keychain (or
# libsecret on Linux), then prompted. On macOS the session and exported
# secrets are cached with mode 0600 so new shells and processes can pick them
# up without re-entering the password.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"
export DOTFILES_DIR

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# --- Configuration -----------------------------------------------------------

VAULT_SERVER_URL="${VAULT_SERVER_URL:-https://vault.abacate.top}"
VAULT_ACCOUNT="${VAULT_ACCOUNT:-machines@abacate.top}"
VAULT_KEYCHAIN_SERVICE="${VAULT_KEYCHAIN_SERVICE:-vault.abacate.top}"
VAULT_CACHE_DIR="${VAULT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/vault}"
VAULT_ENV_CONF="${VAULT_ENV_CONF:-$SCRIPT_DIR/vault-env.conf}"
VAULT_SSH_ITEM_PREFIX="${VAULT_SSH_ITEM_PREFIX:-SSH_KEY_}"
OPENCODE_AUTH_JSON="${OPENCODE_AUTH_JSON:-$HOME/.local/share/opencode/auth.json}"
ASC_DIR="${ASC_DIR:-$HOME/.config/app-store-connect}"
ASC_ITEM_NAME="${ASC_ITEM_NAME:-APPSTORE_CONNECT}"
GITHUB_ITEM_NAME="${GITHUB_ITEM_NAME:-GITHUB_TOKEN}"
# Bitwarden desktop SSH agent socket (macOS). The desktop app must be running,
# unlocked, and have the SSH agent enabled for this to be used.
BITWARDEN_DESKTOP_SOCK="${BITWARDEN_DESKTOP_SOCK:-$HOME/Library/Group Containers/LTZ2PFU5D6.com.bitwarden.desktop/s.bw}"

# Provider -> vault item mapping used by `sync-opencode`.
OPENCODE_PROVIDER_ITEMS="nvidia=NVIDIA_API_KEY abacate=ABACATE_API_KEY openrouter=OPENROUTER_API_KEY opencode-go=OPENCODE_GO_API_KEY"

SESSION_FILE="$VAULT_CACHE_DIR/session"
ENV_FILE="$VAULT_CACHE_DIR/env"
AGENT_FILE="$VAULT_CACHE_DIR/agent"

# Globals set by resolver helpers (kept out of command substitution so they
# survive; see resolve_master_password/ensure_unlock).
MASTER_PASSWORD=""
MASTER_PASSWORD_SOURCE=""
VAULT_SESSION=""
VAULT_ITEMS_JSON=""

# --- Usage -------------------------------------------------------------------

usage() {
    cat <<'EOF'
Usage: vault.sh <command> [args]

Commands:
  init                     Install/configure/log in/unlock (idempotent)
  status                   Show CLI, server, account and lock status
  unlock [--print]         Unlock, cache session/env, sync credentials
  lock                     Lock the vault and clear cached secrets
  export                   Print export lines for the cached session
  get <item> [field]       Print a secret (password|username|notes|field)
  put <item> [options]     Store a login item; password from stdin or prompt
                           Options: --username USER --notes TEXT --uri URI
  env [--print]            Export env vars listed in vault-env.conf
  sync-opencode            Regenerate OpenCode auth.json from the vault
  ssh-load [--print]       Ensure ssh-agent and load vault SSH keys
  ssh-upload <keyfile> [name]
                           Store a local SSH key pair in the vault
  gh-upload                Store the current gh token in the vault
  gh-login                 Authenticate gh from the vault token
  asc-restore              Restore ~/.config/app-store-connect from the vault
  asc-upload               Store ~/.config/app-store-connect in the vault

Environment overrides: VAULT_SERVER_URL, VAULT_ACCOUNT, VAULT_KEYCHAIN_SERVICE,
VAULT_CACHE_DIR, VAULT_ENV_CONF, VAULT_SSH_ITEM_PREFIX, BW_PASSWORD
EOF
}

die() {
    print_error "$1"
    exit "${2:-$E_GENERAL}"
}

# --- Small helpers -----------------------------------------------------------

ensure_cache_dir() {
    if [[ ! -d "$VAULT_CACHE_DIR" ]]; then
        mkdir -p "$VAULT_CACHE_DIR"
        chmod 700 "$VAULT_CACHE_DIR"
    fi
}

# Shell-quote a value for safe `export VAR=<value>` lines.
shell_quote() {
    jq -rn --arg v "$1" '$v | @sh'
}

# Validate a bw session key against the local CLI state.
session_is_valid() {
    local session="$1"
    [[ -n "$session" ]] || return 1
    BW_SESSION="$session" bw status 2>/dev/null | jq -e '.status == "unlocked"' >/dev/null 2>&1
}

# Return the vault items JSON, reusing a single `bw list items` call when one
# is already in memory (unlock runs env + opencode + ssh sync in one go).
vault_items() {
    if [[ -n "$VAULT_ITEMS_JSON" ]]; then
        printf '%s' "$VAULT_ITEMS_JSON"
    else
        bw list items --session "$BW_SESSION"
    fi
}

# Fetch one field from a vault item. Field: password|username|notes|ssh-key|<custom>.
bw_item_field() {
    local item="$1" field="${2:-password}" json
    json="$(bw get item "$item" --session "$BW_SESSION" 2>/dev/null)" || return 1
    case "$field" in
        password) printf '%s' "$json" | jq -r '.login.password // empty' ;;
        username) printf '%s' "$json" | jq -r '.login.username // empty' ;;
        notes)    printf '%s' "$json" | jq -r '.notes // empty' ;;
        ssh-key)  printf '%s' "$json" | jq -r '.sshKey.privateKey // empty' ;;
        ssh-public-key) printf '%s' "$json" | jq -r '.sshKey.publicKey // empty' ;;
        *)        printf '%s' "$json" | jq -r --arg f "$field" '(.fields // [])[] | select(.name == $f) | .value // empty' ;;
    esac
}

# Create or update an item by name. Arguments: name, item-json (without id).
save_item_by_name() {
    local name="$1" item_json="$2"
    local existing_id
    existing_id="$(vault_items | jq -r --arg n "$name" '[.[] | select(.name == $n)][0].id // empty')"
    local encoded
    encoded="$(printf '%s' "$item_json" | bw encode)"
    if [[ -n "$existing_id" ]]; then
        bw edit item "$existing_id" "$encoded" --session "$BW_SESSION" >/dev/null
        print_ok "Updated vault item: $name"
    else
        bw create item "$encoded" --session "$BW_SESSION" >/dev/null
        print_ok "Created vault item: $name"
    fi
    # Invalidate the in-memory item cache so later lookups see the change.
    VAULT_ITEMS_JSON=""
}

# --- Bitwarden CLI setup -----------------------------------------------------

install_bw_binary() {
    # Linux without npm: install the official release binary into ~/.local/bin.
    local url="https://vault.bitwarden.com/download/?app=cli&platform=linux"
    local tmp
    tmp="$(make_temp_dir)"
    if ! curl -fsSL "$url" -o "$tmp/bw.zip"; then
        rm -rf "$tmp"
        print_error "Failed to download the Bitwarden CLI"
        return 1
    fi
    unzip -q -o "$tmp/bw.zip" -d "$tmp"
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/bw" "$HOME/.local/bin/bw"
    rm -rf "$tmp"
    print_ok "Installed bw to $HOME/.local/bin/bw"
}

ensure_bw() {
    if command_exists bw; then
        return 0
    fi
    print_info "Bitwarden CLI (bw) is not installed. Installing..."
    if is_macos; then
        ensure_brew_in_path
        if command_exists brew; then
            brew install bitwarden-cli
        else
            die "Homebrew is required to install bitwarden-cli on macOS"
        fi
    elif command_exists npm; then
        npm install -g @bitwarden/cli
    else
        install_bw_binary
    fi
    if ! command_exists bw; then
        die "bw installation failed"
    fi
}

ensure_server() {
    local current
    current="$(bw config server 2>/dev/null || true)"
    if [[ "$current" != "$VAULT_SERVER_URL" ]]; then
        print_info "Configuring bw server: $VAULT_SERVER_URL"
        if ! bw config server "$VAULT_SERVER_URL" >/dev/null 2>&1; then
            die "Could not set the bw server. Log out first if it points elsewhere."
        fi
    fi
}

# Resolve the master password into MASTER_PASSWORD, recording its source in
# MASTER_PASSWORD_SOURCE (env|keychain|keyring|prompt).
resolve_master_password() {
    MASTER_PASSWORD=""
    MASTER_PASSWORD_SOURCE=""

    if [[ -n "${BW_PASSWORD:-}" ]]; then
        MASTER_PASSWORD="$BW_PASSWORD"
        MASTER_PASSWORD_SOURCE="env"
        return 0
    fi

    if is_macos && command_exists security; then
        if MASTER_PASSWORD="$(security find-generic-password -s "$VAULT_KEYCHAIN_SERVICE" -a "$VAULT_ACCOUNT" -w 2>/dev/null)"; then
            MASTER_PASSWORD_SOURCE="keychain"
            return 0
        fi
    elif command_exists secret-tool; then
        if MASTER_PASSWORD="$(secret-tool lookup service "$VAULT_KEYCHAIN_SERVICE" account "$VAULT_ACCOUNT" 2>/dev/null)"; then
            MASTER_PASSWORD_SOURCE="keyring"
            return 0
        fi
    fi

    if [[ -t 0 || -e /dev/tty ]]; then
        read -r -s -p "Master password for $VAULT_ACCOUNT: " MASTER_PASSWORD </dev/tty
        printf '\n' >&2
        MASTER_PASSWORD_SOURCE="prompt"
        return 0
    fi
    return 1
}

store_master_password() {
    local pw="$1"
    if is_macos && command_exists security; then
        security add-generic-password -U -s "$VAULT_KEYCHAIN_SERVICE" -a "$VAULT_ACCOUNT" -w "$pw" >/dev/null
        print_ok "Master password stored in the macOS keychain"
    elif command_exists secret-tool; then
        printf '%s' "$pw" | secret-tool store --label="Vaultwarden ($VAULT_ACCOUNT)" \
            service "$VAULT_KEYCHAIN_SERVICE" account "$VAULT_ACCOUNT" >/dev/null 2>&1
        print_ok "Master password stored in the system keyring"
    else
        print_warning "No keychain/keyring available; password not stored"
    fi
}

ensure_login() {
    local status
    status="$(bw status 2>/dev/null | jq -r '.status // "unauthenticated"' 2>/dev/null || echo unauthenticated)"
    if [[ "$status" == "unauthenticated" || -z "$status" ]]; then
        print_info "Logging in as $VAULT_ACCOUNT..."
        resolve_master_password || die "Could not determine the master password"
        if BW_PASSWORD="$MASTER_PASSWORD" bw login "$VAULT_ACCOUNT" --passwordenv BW_PASSWORD --raw >/dev/null 2>&1; then
            print_ok "Logged in"
        else
            # Two-step login or new-device verification needs interaction.
            print_warning "Non-interactive login failed; running interactive login"
            if [[ -e /dev/tty ]]; then
                bw login "$VAULT_ACCOUNT" </dev/tty
            else
                die "Login requires interaction (2FA or new device verification)"
            fi
        fi
    fi
}

# Unlock (or reuse) the vault and set VAULT_SESSION.
ensure_unlock() {
    local session
    if session_is_valid "${BW_SESSION:-}"; then
        VAULT_SESSION="$BW_SESSION"
        return 0
    fi
    if [[ -r "$SESSION_FILE" ]] && session_is_valid "$(cat "$SESSION_FILE")"; then
        VAULT_SESSION="$(cat "$SESSION_FILE")"
        return 0
    fi

    print_info "Unlocking the vault..."
    resolve_master_password || die "Could not determine the master password"
    session="$(BW_PASSWORD="$MASTER_PASSWORD" bw unlock --passwordenv BW_PASSWORD --raw)"
    if [[ -z "$session" ]]; then
        die "Unlock failed"
    fi
    VAULT_SESSION="$session"
    print_ok "Vault unlocked"
}

require_session() {
    if session_is_valid "${BW_SESSION:-}"; then
        return 0
    fi
    if [[ -r "$SESSION_FILE" ]] && session_is_valid "$(cat "$SESSION_FILE")"; then
        BW_SESSION="$(cat "$SESSION_FILE")"
        export BW_SESSION
        return 0
    fi
    die "Vault is locked. Run: vault unlock"
}

# --- Commands ----------------------------------------------------------------

cmd_init() {
    ensure_bw
    ensure_server
    ensure_login
    ensure_unlock
    BW_SESSION="$VAULT_SESSION"
    export BW_SESSION
    ensure_cache_dir
    printf '%s' "$VAULT_SESSION" > "$SESSION_FILE"
    chmod 600 "$SESSION_FILE"

    if [[ "$MASTER_PASSWORD_SOURCE" == "prompt" ]]; then
        if ask_yes_no "Store the master password in the keychain/keyring?" "y"; then
            store_master_password "$MASTER_PASSWORD"
        fi
    fi

    VAULT_ITEMS_JSON="$(bw list items --session "$BW_SESSION")"
    cmd_env --quiet || true
    cmd_sync_opencode --quiet || true
    cmd_ssh_load --quiet || true
    print_ok "Vaultwarden is ready (session cached in $SESSION_FILE)"
}

cmd_status() {
    if ! command_exists bw; then
        print_warning "bw (Bitwarden CLI) is not installed. Run: vault init"
        return 1
    fi
    local server session
    server="$(bw config server 2>/dev/null || true)"
    session="${BW_SESSION:-}"
    if ! session_is_valid "$session" && [[ -r "$SESSION_FILE" ]]; then
        session="$(cat "$SESSION_FILE")"
    fi
    printf 'Server:  %s\n' "${server:-<unset>}"
    printf 'Account: %s\n' "$VAULT_ACCOUNT"
    if session_is_valid "$session"; then
        printf 'Status:  unlocked\n'
        if [[ "$session" == "${BW_SESSION:-}" ]]; then
            print_ok "Current BW_SESSION is valid"
        else
            print_ok "Cached session is valid ($SESSION_FILE)"
        fi
    else
        printf 'Status:  %s\n' "$(bw status 2>/dev/null | jq -r '.status // "unknown"' 2>/dev/null || echo unknown)"
        print_warn "No valid session. Run: vault unlock"
    fi
}

cmd_unlock() {
    local print_exports=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --print) print_exports=true ;;
            --quiet) : ;; # accepted for symmetry; unlock is already quiet
            *) die "Unknown option: $1" "$E_INVALID_ARG" ;;
        esac
        shift
    done

    ensure_bw
    ensure_server
    ensure_login
    ensure_unlock
    BW_SESSION="$VAULT_SESSION"
    export BW_SESSION
    ensure_cache_dir
    printf '%s' "$VAULT_SESSION" > "$SESSION_FILE"
    chmod 600 "$SESSION_FILE"

    VAULT_ITEMS_JSON="$(bw list items --session "$BW_SESSION")"
    cmd_env --quiet || true
    cmd_sync_opencode --quiet || true
    cmd_ssh_load --quiet || true
    print_ok "Credentials cached in $VAULT_CACHE_DIR"

    if $print_exports; then
        printf 'export BW_SESSION=%s\n' "$(shell_quote "$VAULT_SESSION")"
        [[ -r "$ENV_FILE" ]] && cat "$ENV_FILE"
        [[ -r "$AGENT_FILE" ]] && cat "$AGENT_FILE"
    fi
}

cmd_lock() {
    if command_exists bw; then
        bw lock >/dev/null 2>&1 || true
    fi
    rm -f "$SESSION_FILE" "$ENV_FILE" "$AGENT_FILE"
    print_ok "Vault locked and cached secrets removed"
}

cmd_export() {
    require_session
    printf 'export BW_SESSION=%s\n' "$(shell_quote "$BW_SESSION")"
    [[ -r "$ENV_FILE" ]] && cat "$ENV_FILE"
    [[ -r "$AGENT_FILE" ]] && cat "$AGENT_FILE"
}

cmd_get() {
    if [[ $# -lt 1 ]]; then
        die "Usage: vault.sh get <item> [field]" "$E_INVALID_ARG"
    fi
    require_session
    local value
    value="$(bw_item_field "$1" "${2:-password}")" || die "Vault item not found: $1"
    if [[ -z "$value" ]]; then
        die "Field '${2:-password}' is empty for vault item: $1"
    fi
    printf '%s\n' "$value"
}

cmd_put() {
    if [[ $# -lt 1 ]]; then
        die "Usage: vault.sh put <item> [--username USER] [--notes TEXT] [--uri URI]" "$E_INVALID_ARG"
    fi
    local name="$1"
    shift
    local user="" notes="" uri=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --username) user="${2:-}"; shift 2 ;;
            --notes) notes="${2:-}"; shift 2 ;;
            --uri) uri="${2:-}"; shift 2 ;;
            *) die "Unknown option: $1" "$E_INVALID_ARG" ;;
        esac
    done
    require_session

    local value=""
    if [[ ! -t 0 ]]; then
        value="$(cat)"
    elif [[ -e /dev/tty ]]; then
        read -r -s -p "Secret for $name: " value </dev/tty
        printf '\n' >&2
    fi
    [[ -n "$value" ]] || die "No secret provided (pass it on stdin or enter it interactively)"

    local item_json
    item_json="$(jq -n --arg n "$name" --arg u "$user" --arg v "$value" --arg notes "$notes" --arg uri "$uri" \
        '{organizationId: null, folderId: null, type: 1, name: $n, notes: (if $notes == "" then null else $notes end), favorite: false, fields: [], login: {username: (if $u == "" then null else $u end), password: $v, totp: null, uris: (if $uri == "" then [] else [{uri: $uri}] end)}}')"
    save_item_by_name "$name" "$item_json"
}

cmd_env() {
    local print_exports=false quiet=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --print) print_exports=true ;;
            --quiet) quiet=true ;;
            *) die "Unknown option: $1" "$E_INVALID_ARG" ;;
        esac
        shift
    done

    require_session
    if [[ ! -f "$VAULT_ENV_CONF" ]]; then
        print_warning "No env mapping found at $VAULT_ENV_CONF"
        return 0
    fi
    ensure_cache_dir

    local items_json tmp line var item value
    items_json="$(vault_items)"
    tmp="$ENV_FILE.tmp"
    : > "$tmp"
    chmod 600 "$tmp"

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        # Trim whitespace
        line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [[ -n "$line" ]] || continue
        var="${line%%=*}"
        item="${line#*=}"
        if [[ -z "$var" || -z "$item" || "$var" == "$line" ]]; then
            print_warning "Skipping malformed mapping line: $line"
            continue
        fi
        value="$(printf '%s' "$items_json" | jq -r --arg n "$item" '[.[] | select(.name == $n)][0] | (.login.password // .notes // empty)')"
        if [[ -z "$value" ]]; then
            print_warning "Vault item not found for $var: $item"
            continue
        fi
        printf 'export %s=%s\n' "$var" "$(shell_quote "$value")" >> "$tmp"
    done < "$VAULT_ENV_CONF"

    mv "$tmp" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    if $print_exports; then
        cat "$ENV_FILE"
    fi
    $quiet || print_ok "Exported vault env vars to $ENV_FILE"
}

cmd_sync_opencode() {
    local quiet=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet) quiet=true ;;
            *) die "Unknown option: $1" "$E_INVALID_ARG" ;;
        esac
        shift
    done

    require_session
    local items_json auth_json tmp pair provider item value
    items_json="$(vault_items)"
    if [[ -f "$OPENCODE_AUTH_JSON" ]]; then
        auth_json="$(cat "$OPENCODE_AUTH_JSON")"
    else
        auth_json='{}'
    fi

    for pair in $OPENCODE_PROVIDER_ITEMS; do
        provider="${pair%%=*}"
        item="${pair#*=}"
        value="$(printf '%s' "$items_json" | jq -r --arg n "$item" '[.[] | select(.name == $n)][0] | (.login.password // empty)')"
        if [[ -z "$value" ]]; then
            print_warning "Vault item not found for provider $provider: $item"
            continue
        fi
        auth_json="$(printf '%s' "$auth_json" | jq --arg p "$provider" --arg k "$value" '.[$p] = {type: "api", key: $k}')"
    done

    mkdir -p "$(dirname "$OPENCODE_AUTH_JSON")"
    tmp="$OPENCODE_AUTH_JSON.tmp"
    printf '%s\n' "$auth_json" > "$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$OPENCODE_AUTH_JSON"
    $quiet || print_ok "OpenCode auth.json synced from the vault"
}

# Return 0 when the Bitwarden desktop agent is reachable and already exposes at
# least one of the vault SSH key fingerprints.
desktop_agent_has_vault_keys() {
    local keys="$1"
    is_macos || return 1
    [[ -S "$BITWARDEN_DESKTOP_SOCK" ]] || return 1
    local agent_fps fp _id _name
    agent_fps="$(SSH_AUTH_SOCK="$BITWARDEN_DESKTOP_SOCK" ssh-add -l 2>/dev/null | awk '{print $2}' || true)"
    [[ -n "$agent_fps" ]] || return 1
    while IFS="$(printf '\t')" read -r _id _name fp; do
        [[ -n "$fp" ]] || continue
        if printf '%s\n' "$agent_fps" | grep -qxF "$fp"; then
            return 0
        fi
    done <<< "$keys"
    return 1
}

ensure_system_agent() {
    if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
        local rc=0
        ssh-add -l >/dev/null 2>&1 || rc=$?
        if [[ "$rc" -ne 2 ]]; then
            export SSH_AUTH_SOCK
            return 0
        fi
    fi
    print_info "Starting ssh-agent..."
    eval "$(ssh-agent -s)" >/dev/null
    export SSH_AUTH_SOCK SSH_AGENT_PID
}

cmd_ssh_load() {
    local print_exports=false quiet=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --print) print_exports=true ;;
            --quiet) quiet=true ;;
            *) die "Unknown option: $1" "$E_INVALID_ARG" ;;
        esac
        shift
    done

    require_session
    local items_json keys
    items_json="$(vault_items)"
    keys="$(printf '%s' "$items_json" | jq -r --arg p "$VAULT_SSH_ITEM_PREFIX" '.[] | select(.type == 5 and (.name | startswith($p))) | [.id, .name, (.sshKey.keyFingerprint // "")] | @tsv')"

    if [[ -z "$keys" ]]; then
        print_warning "No SSH keys found in the vault (items named ${VAULT_SSH_ITEM_PREFIX}*)"
        return 0
    fi

    local sock="" id name fp agent_fps
    if desktop_agent_has_vault_keys "$keys"; then
        sock="$BITWARDEN_DESKTOP_SOCK"
        print_ok "Using the Bitwarden desktop SSH agent"
    else
        ensure_system_agent
        sock="$SSH_AUTH_SOCK"
        agent_fps="$(ssh-add -l 2>/dev/null | awk '{print $2}' || true)"
        while IFS="$(printf '\t')" read -r id name fp; do
            [[ -n "$id" ]] || continue
            if [[ -n "$fp" ]] && printf '%s\n' "$agent_fps" | grep -qxF "$fp"; then
                continue
            fi
            print_info "Loading $name into the ssh-agent"
            if ! bw get item "$id" --session "$BW_SESSION" | jq -r '.sshKey.privateKey' | ssh-add - >/dev/null 2>&1; then
                print_warning "Failed to load $name into the ssh-agent"
            fi
        done <<< "$keys"
        $quiet || print_ok "Vault SSH keys are loaded in the ssh-agent"
    fi

    ensure_cache_dir
    {
        printf 'export SSH_AUTH_SOCK=%s\n' "$(shell_quote "$sock")"
        if [[ -n "${SSH_AGENT_PID:-}" ]]; then
            printf 'export SSH_AGENT_PID=%s\n' "$SSH_AGENT_PID"
        fi
    } > "$AGENT_FILE.tmp"
    chmod 600 "$AGENT_FILE.tmp"
    mv "$AGENT_FILE.tmp" "$AGENT_FILE"
    if $print_exports; then
        cat "$AGENT_FILE"
    fi
}

cmd_ssh_upload() {
    if [[ $# -lt 1 ]]; then
        die "Usage: vault.sh ssh-upload <private-key-file> [item-name]" "$E_INVALID_ARG"
    fi
    local keyfile="$1" name="${2:-}"
    [[ -f "$keyfile" ]] || die "Key file not found: $keyfile"
    require_session

    local pub fp tmp
    if [[ -f "${keyfile}.pub" ]]; then
        pub="$(cat "${keyfile}.pub")"
    else
        pub="$(ssh-keygen -y -f "$keyfile")"
    fi
    tmp="$(make_temp_file .pub)"
    printf '%s\n' "$pub" > "$tmp"
    fp="$(ssh-keygen -lf "$tmp" | awk '{print $2}')"
    rm -f "$tmp"

    if [[ -z "$name" ]]; then
        local base
        base="$(basename "$keyfile")"
        base="${base#id_ed25519_}"
        base="${base#id_rsa_}"
        base="${base#id_ecdsa_}"
        base="${base#id_}"
        name="${VAULT_SSH_ITEM_PREFIX}$(printf '%s' "$base" | tr '[:lower:]-' '[:upper:]_')"
    fi

    local item_json
    item_json="$(jq -n --arg n "$name" --rawfile priv "$keyfile" --arg pub "$pub" --arg fp "$fp" \
        '{organizationId: null, folderId: null, type: 5, name: $n, notes: null, favorite: false, fields: [], sshKey: {privateKey: $priv, publicKey: $pub, keyFingerprint: $fp}}')"
    save_item_by_name "$name" "$item_json"
}

cmd_gh_upload() {
    command_exists gh || die "gh CLI is not installed"
    require_session
    local token user notes item_json
    token="$(gh auth token 2>/dev/null || true)"
    [[ -n "$token" ]] || die "gh is not authenticated (run: gh auth login)"
    user="$(gh api user --jq .login 2>/dev/null || true)"
    notes="GitHub CLI token for ${user:-unknown account}. Restore with: vault gh-login"
    item_json="$(jq -n --arg n "$GITHUB_ITEM_NAME" --arg user "$user" --arg token "$token" --arg notes "$notes" \
        '{organizationId: null, folderId: null, type: 1, name: $n, notes: $notes, favorite: false, fields: [], login: {username: $user, password: $token, totp: null, uris: []}}')"
    save_item_by_name "$GITHUB_ITEM_NAME" "$item_json"
}

cmd_gh_login() {
    command_exists gh || die "gh CLI is not installed"
    require_session
    local token
    token="$(bw_item_field "$GITHUB_ITEM_NAME" password)" || die "Vault item not found: $GITHUB_ITEM_NAME"
    [[ -n "$token" ]] || die "No token stored in vault item: $GITHUB_ITEM_NAME"
    printf '%s' "$token" | gh auth login --with-token
    gh auth status || true
    print_ok "gh authenticated from the vault"
}

cmd_asc_upload() {
    require_session
    local creds_file="$ASC_DIR/credentials.json"
    [[ -f "$creds_file" ]] || die "Not found: $creds_file"
    local p8_path p8_name item_json
    p8_path="$(jq -r '.private_key_path // empty' "$creds_file")"
    p8_path="${p8_path/#\~/$HOME}"
    [[ -n "$p8_path" ]] || die "private_key_path missing in $creds_file"
    [[ -f "$p8_path" ]] || die "Private key not found: $p8_path"
    p8_name="$(basename "$p8_path")"

    item_json="$(jq -n --arg n "$ASC_ITEM_NAME" --rawfile creds "$creds_file" --arg p8name "$p8_name" --rawfile p8 "$p8_path" \
        '{organizationId: null, folderId: null, type: 2, name: $n, notes: "App Store Connect API credentials. Restore with: vault asc-restore", favorite: false, secureNote: {type: 0}, fields: [{name: "credentials.json", value: $creds, type: 1}, {name: $p8name, value: $p8, type: 1}]}')"
    save_item_by_name "$ASC_ITEM_NAME" "$item_json"
}

cmd_asc_restore() {
    require_session
    local item_json p8_name
    item_json="$(bw get item "$ASC_ITEM_NAME" --session "$BW_SESSION" 2>/dev/null)" \
        || die "Vault item not found: $ASC_ITEM_NAME"
    p8_name="$(printf '%s' "$item_json" | jq -r '[(.fields // [])[] | select(.name != "credentials.json")][0].name // empty')"

    mkdir -p "$ASC_DIR"
    chmod 700 "$ASC_DIR"
    # Stream bytes directly (jq -j) so trailing newlines survive.
    printf '%s' "$item_json" | jq -j '(.fields // [])[] | select(.name == "credentials.json") | .value' > "$ASC_DIR/credentials.json.tmp"
    if [[ ! -s "$ASC_DIR/credentials.json.tmp" ]]; then
        rm -f "$ASC_DIR/credentials.json.tmp"
        die "credentials.json field missing in vault item: $ASC_ITEM_NAME"
    fi
    chmod 600 "$ASC_DIR/credentials.json.tmp"
    mv "$ASC_DIR/credentials.json.tmp" "$ASC_DIR/credentials.json"
    if [[ -n "$p8_name" ]]; then
        printf '%s' "$item_json" | jq -j --arg n "$p8_name" '(.fields // [])[] | select(.name == $n) | .value' > "$ASC_DIR/$p8_name.tmp"
        chmod 600 "$ASC_DIR/$p8_name.tmp"
        mv "$ASC_DIR/$p8_name.tmp" "$ASC_DIR/$p8_name"
    fi
    print_ok "Restored App Store Connect credentials to $ASC_DIR"
}

# --- Main --------------------------------------------------------------------

main() {
    local cmd="${1:-status}"
    if [[ $# -gt 0 ]]; then
        shift
    fi
    case "$cmd" in
        init)          cmd_init "$@" ;;
        status)        cmd_status "$@" ;;
        unlock)        cmd_unlock "$@" ;;
        lock)          cmd_lock "$@" ;;
        export)        cmd_export "$@" ;;
        get)           cmd_get "$@" ;;
        put)           cmd_put "$@" ;;
        env)           cmd_env "$@" ;;
        sync-opencode) cmd_sync_opencode "$@" ;;
        ssh-load)      cmd_ssh_load "$@" ;;
        ssh-upload)    cmd_ssh_upload "$@" ;;
        gh-upload)     cmd_gh_upload "$@" ;;
        gh-login)      cmd_gh_login "$@" ;;
        asc-restore)   cmd_asc_restore "$@" ;;
        asc-upload)    cmd_asc_upload "$@" ;;
        help|--help|-h) usage ;;
        *)
            usage
            exit "$E_INVALID_ARG"
            ;;
    esac
}

main "$@"
