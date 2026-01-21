#!/usr/bin/env bash
#
# Shared library for bootstrap scripts
# Source this file to get common functions and feature definitions
#

# --- Configuration ---
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_JSON="$LIB_DIR/features.json"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$LIB_DIR")}"

# --- Colors (with fallback for basic terminals) ---
setup_colors() {
    if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
    fi
}

# Initialize colors immediately when sourced
setup_colors

# --- Common Output Functions ---
print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}!${NC} $1"; }
print_warning() { echo -e "${YELLOW}! $1${NC}"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }
print_header() { echo -e "\n${BLUE}${BOLD}==> $1${NC}"; }

# --- Prompt Functions ---
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    read -rp "$prompt" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

# --- Command Helpers ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Homebrew Helpers ---
get_brew_path() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "/opt/homebrew/bin/brew"
    else
        echo "/usr/local/bin/brew"
    fi
}

ensure_brew_in_path() {
    if ! command_exists brew; then
        local brew_path
        brew_path="$(get_brew_path)"
        if [[ -x "$brew_path" ]]; then
            eval "$("$brew_path" shellenv)"
        fi
    fi
}

# Check if a brew formula is installed
brew_pkg_installed() {
    local pkg="$1"
    ensure_brew_in_path
    command_exists brew && brew list "$pkg" >/dev/null 2>&1
}

# Check if a brew cask is installed
brew_cask_installed() {
    local cask="$1"
    ensure_brew_in_path
    command_exists brew && brew list --cask "$cask" >/dev/null 2>&1
}

# --- JSON Parsing (uses Python, available on macOS) ---
_json_query() {
    local query="$1"
    python3 -c "
import json, sys
with open('$FEATURES_JSON') as f:
    data = json.load(f)
$query
" 2>/dev/null
}

# Get list of all feature keys
get_feature_keys() {
    _json_query "print(' '.join(data['features'].keys()))"
}

# Get human-readable name for a feature
get_feature_name() {
    local feature="$1"
    _json_query "print(data['features'].get('$feature', {}).get('name', '$feature'))"
}

# Get brew packages for a feature (space-separated)
get_brew_packages() {
    local feature="$1"
    _json_query "print(' '.join(data['features'].get('$feature', {}).get('brew_packages', [])))"
}

# Get brew casks for a feature (space-separated)
get_brew_casks() {
    local feature="$1"
    _json_query "print(' '.join(data['features'].get('$feature', {}).get('brew_casks', [])))"
}

# Get stow package for a feature
get_stow_package() {
    local feature="$1"
    _json_query "print(data['features'].get('$feature', {}).get('stow_package') or '')"
}

# Get post-install type for a feature
get_post_install() {
    local feature="$1"
    _json_query "print(data['features'].get('$feature', {}).get('post_install') or '')"
}

# Get all CLI packages (space-separated)
get_all_cli_packages() {
    _json_query "print(' '.join(data.get('cli_packages', [])))"
}

# Get all GUI casks (space-separated)
get_all_gui_casks() {
    _json_query "print(' '.join(data.get('gui_apps', {}).get('casks', [])))"
}

# Get all GUI formulas (space-separated)
get_all_gui_formulas() {
    _json_query "print(' '.join(data.get('gui_apps', {}).get('formulas', [])))"
}

# --- Status Checking Functions ---

# Check status of CLI tools: returns "installed:missing" counts
check_cli_tools_status() {
    local installed=0 missing=0
    local packages
    packages=$(get_all_cli_packages)
    for pkg in $packages; do
        if brew_pkg_installed "$pkg"; then
            ((installed++))
        else
            ((missing++))
        fi
    done
    echo "$installed:$missing"
}

# Get list of missing CLI tools (space-separated)
get_missing_cli_tools() {
    local missing=()
    local packages
    packages=$(get_all_cli_packages)
    for pkg in $packages; do
        if ! brew_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[*]}"
}

# Check status of GUI apps: returns "installed:missing" counts
check_gui_apps_status() {
    local installed=0 missing_count=0
    local casks formulas
    casks=$(get_all_gui_casks)
    formulas=$(get_all_gui_formulas)

    for cask in $casks; do
        if brew_cask_installed "$cask"; then
            ((installed++))
        else
            ((missing_count++))
        fi
    done

    for formula in $formulas; do
        if brew_pkg_installed "$formula"; then
            ((installed++))
        else
            ((missing_count++))
        fi
    done

    echo "$installed:$missing_count"
}

# Get list of missing GUI apps (space-separated)
get_missing_gui_apps() {
    local missing=()
    local casks formulas
    casks=$(get_all_gui_casks)
    formulas=$(get_all_gui_formulas)

    for cask in $casks; do
        if ! brew_cask_installed "$cask"; then
            missing+=("$cask")
        fi
    done

    for formula in $formulas; do
        if ! brew_pkg_installed "$formula"; then
            missing+=("$formula")
        fi
    done

    echo "${missing[*]}"
}

# Check if dotfiles are properly symlinked
check_stow_status() {
    if [[ -x "$LIB_DIR/stow.sh" ]]; then
        if "$LIB_DIR/stow.sh" --verify >/dev/null 2>&1; then
            echo "ok"
        else
            echo "needs_attention"
        fi
    else
        echo "unknown"
    fi
}

# Check if SSH keys exist for GitHub
check_ssh_keys_status() {
    local count=0
    for key in ~/.ssh/id_ed25519_github_*; do
        [[ -f "$key" ]] && ((count++))
    done
    echo "$count"
}

# Check prezto status
check_prezto_status() {
    [[ -d "${ZDOTDIR:-$HOME}/.zprezto" ]] && echo "installed" || echo "missing"
}

# --- Feature Detection ---

# Check if a feature is fully installed
# Returns 0 if installed, 1 if missing something
is_feature_installed() {
    local feature="$1"
    local brew_pkgs brew_casks stow_pkg

    ensure_brew_in_path

    brew_pkgs=$(get_brew_packages "$feature")
    brew_casks=$(get_brew_casks "$feature")
    stow_pkg=$(get_stow_package "$feature")

    # Check brew packages
    for pkg in $brew_pkgs; do
        if ! brew_pkg_installed "$pkg"; then
            return 1
        fi
    done

    # Check brew casks
    for cask in $brew_casks; do
        if ! brew_cask_installed "$cask"; then
            return 1
        fi
    done

    # Check stow package (just check if main symlinks exist)
    if [[ -n "$stow_pkg" ]]; then
        local pkg_dir="$DOTFILES_DIR/$stow_pkg"
        if [[ -d "$pkg_dir" ]]; then
            # Check if at least the top-level items are symlinked
            for item in "$pkg_dir"/.*; do
                local base_name
                base_name="$(basename "$item")"
                [[ "$base_name" == "." || "$base_name" == ".." ]] && continue
                [[ "$base_name" == ".DS_Store" ]] && continue
                [[ "$base_name" == ".stow-local-ignore" ]] && continue
                local home_item="$HOME/$base_name"
                if [[ ! -L "$home_item" && ! -e "$home_item" ]]; then
                    return 1
                fi
            done
        fi
    fi

    # Special checks
    case "$feature" in
        xcode)
            [[ -d "/Applications/Xcode.app" ]] || return 1
            ;;
    esac

    return 0
}

# Get list of missing features (space-separated)
get_missing_features() {
    local missing=()
    local features
    features=$(get_feature_keys)
    for name in $features; do
        if ! is_feature_installed "$name"; then
            missing+=("$name")
        fi
    done
    echo "${missing[*]}"
}
