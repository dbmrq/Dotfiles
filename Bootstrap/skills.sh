#!/usr/bin/env bash
#
# Agent Skills Manager
#
# The canonical agent skills live in the dbmrq/agent-skills repository.
# Its scripts/install-all.sh is the only authoritative installer for
# personal, external, and Apple Xcode skills. The legacy `npx skills`
# path has been retired — this script never calls npx and never writes
# skill sources into the dotfiles repo.
#
# This script:
#   1. Ensures ~/.agents is a real directory OUTSIDE this repo. The legacy
#      layout symlinked ~/.agents into the dotfiles working tree; only that
#      managed symlink is removed (when it points into this repo). Real
#      directories and unrelated symlinks are left untouched.
#   2. Locates the canonical agent-skills checkout:
#        $AGENT_SKILLS_DIR                  explicit override
#        an existing checkout under ~/Documents  (e.g. .../Misc/agent-skills)
#        $HOME/.local/share/agent-skills    default clone location
#      and clones it when absent (requires network).
#   3. Runs its scripts/install-all.sh, which installs skills into
#      ~/.agents/skills plus every detected agent skill directory
#      (including ~/.config/opencode/skills).
#
# Usage:
#   ./skills.sh install   # ensure ~/.agents, locate/clone agent-skills, install
#   ./skills.sh update    # alias for install (install-all.sh is idempotent)
#   ./skills.sh status    # show skill layout and status
#
# Environment:
#   AGENT_SKILLS_DIR    path to the agent-skills checkout (override)
#   AGENTS, SCOPE       passed through to scripts/install-all.sh
#

set -euo pipefail

# --- Script setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

# --- Configuration ---
AGENT_SKILLS_REPO="https://github.com/dbmrq/agent-skills.git"
DEFAULT_AGENT_SKILLS_DIR="$HOME/.local/share/agent-skills"

# --- Functions ---

# True if $HOME/.agents is a symlink that resolves into this repo.
agents_dir_is_managed_symlink() {
    [[ -L "$HOME/.agents" ]] || return 1

    local target resolved
    target="$(readlink "$HOME/.agents")"
    if [[ "$target" == /* ]]; then
        resolved="$target"
    else
        resolved="$HOME/$target"
    fi
    # Resolve ".." and symlinks for a reliable containment check.
    if command -v realpath >/dev/null 2>&1; then
        resolved="$(realpath -m "$resolved" 2>/dev/null || echo "$resolved")"
    fi
    case "$resolved" in
        "$DOTFILES_DIR"/*) return 0 ;;
        *) return 1 ;;
    esac
}

ensure_agents_dir() {
    print_header "Ensuring ~/.agents is a real directory"

    if [[ -d "$HOME/.agents" && ! -L "$HOME/.agents" ]]; then
        print_ok "$HOME/.agents is already a real directory"
        return 0
    fi

    if [[ -L "$HOME/.agents" ]]; then
        if agents_dir_is_managed_symlink; then
            print_warn "Removing legacy $HOME/.agents symlink that pointed into this repo"
            rm "$HOME/.agents"
        else
            print_warn "$HOME/.agents is a symlink but does not point into this repo; leaving it untouched"
        fi
    fi

    if [[ ! -d "$HOME/.agents" ]]; then
        mkdir -p "$HOME/.agents"
        print_ok "Created real $HOME/.agents"
    fi
}

# Print the path to the canonical agent-skills checkout.
find_agent_skills_dir() {
    # 1. Explicit override.
    if [[ -n "${AGENT_SKILLS_DIR:-}" ]]; then
        printf '%s' "$AGENT_SKILLS_DIR"
        return 0
    fi

    # 2. Reuse an existing checkout already on this machine (portable glob).
    if [[ -d "$HOME/Documents" ]]; then
        local existing
        existing="$(find "$HOME/Documents" -maxdepth 3 -type d -name agent-skills 2>/dev/null | head -n 1)" || true
        if [[ -n "$existing" ]]; then
            printf '%s' "$existing"
            return 0
        fi
    fi

    # 3. Default clone location.
    printf '%s' "$DEFAULT_AGENT_SKILLS_DIR"
}

# Ensure the agent-skills checkout exists; clone it when missing.
# Prints the checkout path via the AGENT_SKILLS_REPO_DIR global.
ensure_agent_skills_repo() {
    AGENT_SKILLS_REPO_DIR="$(find_agent_skills_dir)"

    if [[ -x "$AGENT_SKILLS_REPO_DIR/scripts/install-all.sh" ]]; then
        print_ok "Using agent-skills checkout at $AGENT_SKILLS_REPO_DIR"
        # Best-effort refresh so the installer itself is current.
        if [[ -d "$AGENT_SKILLS_REPO_DIR/.git" ]] && command_exists git; then
            git -C "$AGENT_SKILLS_REPO_DIR" pull --ff-only >/dev/null 2>&1 || \
                print_warn "Could not refresh agent-skills checkout (network or uncommitted changes); using what is present"
        fi
        return 0
    fi

    if ! command_exists git; then
        print_error "git is required to fetch the agent-skills repo."
        print_error "Install git (e.g. 'xcode-select --install' on macOS), then re-run."
        return "$E_MISSING_DEP"
    fi

    print_info "agent-skills not found at $AGENT_SKILLS_REPO_DIR; cloning..."
    if ! git clone "$AGENT_SKILLS_REPO" "$AGENT_SKILLS_REPO_DIR" 2>&1; then
        print_error "Failed to clone $AGENT_SKILLS_REPO into $AGENT_SKILLS_REPO_DIR"
        print_error "Check your network connection, or set AGENT_SKILLS_DIR to an existing checkout, then re-run."
        return "$E_NETWORK"
    fi
    print_ok "Cloned agent-skills to $AGENT_SKILLS_REPO_DIR"
}

install_skills() {
    ensure_agents_dir
    ensure_agent_skills_repo

    local installer="$AGENT_SKILLS_REPO_DIR/scripts/install-all.sh"
    if [[ ! -x "$installer" ]]; then
        print_error "Canonical installer not found: $installer"
        print_error "Expected the dbmrq/agent-skills repo layout; fix AGENT_SKILLS_DIR if it points elsewhere."
        return "$E_MISSING_DEP"
    fi

    print_header "Installing agent skills via scripts/install-all.sh"
    print_info "Source: $AGENT_SKILLS_REPO_DIR"
    # Run from inside the checkout so `gh repo view` resolves the correct
    # repo (dbmrq/agent-skills) instead of the directory we were called from.
    (cd "$AGENT_SKILLS_REPO_DIR" && "$installer")
}

show_status() {
    print_header "Agent Skills Status"

    if [[ -d "$HOME/.agents" && ! -L "$HOME/.agents" ]]; then
        print_ok "$HOME/.agents is a real directory"
    elif [[ -L "$HOME/.agents" ]]; then
        print_warn "$HOME/.agents is a symlink -> $(readlink "$HOME/.agents")"
    else
        print_warn "$HOME/.agents does not exist"
    fi

    local skills_dir="$HOME/.agents/skills"
    if [[ -d "$skills_dir" ]]; then
        local skills
        skills=$(find "$skills_dir" -maxdepth 1 -type d -not -name ".*" -not -path "$skills_dir" | wc -l | tr -d ' ')
        echo "  $skills skill(s) in $skills_dir"
    else
        print_info "No skills installed in $skills_dir yet"
    fi

    local checkout
    checkout="$(find_agent_skills_dir)"
    if [[ -x "$checkout/scripts/install-all.sh" ]]; then
        print_ok "agent-skills checkout: $checkout"
    else
        print_info "agent-skills checkout (will be cloned on install): $checkout"
    fi

    echo ""
    echo -e "${BOLD}Agent skill directories:${NC}"
    for dir in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.config/opencode/skills" \
               "$HOME/.cursor/skills" "$HOME/.augment/skills" "$HOME/.copilot/skills" "$HOME/.config/agents/skills"; do
        if [[ -d "$dir" ]]; then
            local count
            count=$(find "$dir" -maxdepth 1 -type d -not -name ".*" -not -path "$dir" 2>/dev/null | wc -l | tr -d ' ')
            echo "  $count  $dir"
        fi
    done
}

# --- Main ---
main() {
    case "${1:-install}" in
        install|update)
            install_skills
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 [install|update|status]"
            echo ""
            echo "Commands:"
            echo "  install   Ensure ~/.agents, locate/clone agent-skills, install skills (default)"
            echo "  update    Alias for install (install-all.sh is idempotent)"
            echo "  status    Show current skill layout and status"
            exit "$E_INVALID_ARG"
            ;;
    esac
}

# Only run if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
