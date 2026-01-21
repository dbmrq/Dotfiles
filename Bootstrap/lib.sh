#!/usr/bin/env bash
#
# Shared library for bootstrap scripts
# Source this file to get common functions and feature definitions
#

# --- Feature Definitions ---
# Each feature has: brew packages, brew casks, stow package, post-install flag
# Format: "feature_name:brew_pkgs:brew_casks:stow_pkg:post_install"

declare -a FEATURES=(
    "vim:macvim,neovim::Vim:plugins"
    "git:git,git-extras::Git:"
    "hammerspoon::hammerspoon:Hammerspoon:"
    "ssh:::SSH:"
    "tex::basictex:TeX:tlmgr"
    "zsh:::Zsh:"
    "cli:lua,mas,par,stow,ruby,trash-cli,cscope,pandoc,rename,python3,swiftlint:::"
    "gui::vlc,appcleaner,google-chrome,the-unarchiver::"
    "xcode::::xcode"
)

# Human-readable names for features
get_feature_name() {
    case "$1" in
        vim) echo "Vim/Neovim" ;;
        git) echo "Git" ;;
        hammerspoon) echo "Hammerspoon" ;;
        ssh) echo "SSH" ;;
        tex) echo "TeX/LaTeX" ;;
        zsh) echo "Zsh" ;;
        cli) echo "CLI Tools" ;;
        gui) echo "GUI Apps" ;;
        xcode) echo "Xcode" ;;
        *) echo "$1" ;;
    esac
}

# --- Feature Parsing Functions ---

# Get brew packages for a feature
get_brew_packages() {
    local feature="$1"
    for f in "${FEATURES[@]}"; do
        local name="${f%%:*}"
        if [[ "$name" == "$feature" ]]; then
            local rest="${f#*:}"
            local pkgs="${rest%%:*}"
            echo "${pkgs//,/ }"
            return
        fi
    done
}

# Get brew casks for a feature
get_brew_casks() {
    local feature="$1"
    for f in "${FEATURES[@]}"; do
        local name="${f%%:*}"
        if [[ "$name" == "$feature" ]]; then
            local rest="${f#*:}"
            rest="${rest#*:}"
            local casks="${rest%%:*}"
            echo "${casks//,/ }"
            return
        fi
    done
}

# Get stow package for a feature
get_stow_package() {
    local feature="$1"
    for f in "${FEATURES[@]}"; do
        local name="${f%%:*}"
        if [[ "$name" == "$feature" ]]; then
            local rest="${f#*:}"
            rest="${rest#*:}"
            rest="${rest#*:}"
            local stow="${rest%%:*}"
            echo "$stow"
            return
        fi
    done
}

# Get post-install type for a feature
get_post_install() {
    local feature="$1"
    for f in "${FEATURES[@]}"; do
        local name="${f%%:*}"
        if [[ "$name" == "$feature" ]]; then
            local post="${f##*:}"
            echo "$post"
            return
        fi
    done
}

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

# --- Common Output Functions ---
print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }

# --- Prompt Functions ---
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    read -rp "$prompt" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
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
    if ! command -v brew >/dev/null 2>&1; then
        local brew_path
        brew_path="$(get_brew_path)"
        if [[ -x "$brew_path" ]]; then
            eval "$("$brew_path" shellenv)"
        fi
    fi
}

# --- Feature Detection ---

# Check if a feature is fully installed
# Returns 0 if installed, 1 if missing something
is_feature_installed() {
    local feature="$1"
    local brew_pkgs brew_casks stow_pkg

    brew_pkgs=$(get_brew_packages "$feature")
    brew_casks=$(get_brew_casks "$feature")
    stow_pkg=$(get_stow_package "$feature")

    # Check brew packages
    for pkg in $brew_pkgs; do
        if ! brew list "$pkg" >/dev/null 2>&1; then
            return 1
        fi
    done

    # Check brew casks
    for cask in $brew_casks; do
        if ! brew list --cask "$cask" >/dev/null 2>&1; then
            return 1
        fi
    done

    # Check stow package (just check if main symlinks exist)
    if [[ -n "$stow_pkg" ]]; then
        local pkg_dir="${DOTFILES_DIR:-$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")}/$stow_pkg"
        if [[ -d "$pkg_dir" ]]; then
            # Check if at least the top-level items are symlinked
            for item in "$pkg_dir"/.*; do
                [[ "$(basename "$item")" == "." || "$(basename "$item")" == ".." ]] && continue
                [[ "$(basename "$item")" == ".DS_Store" ]] && continue
                [[ "$(basename "$item")" == ".stow-local-ignore" ]] && continue
                local home_item="$HOME/$(basename "$item")"
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

# Get list of missing features
get_missing_features() {
    local missing=()
    for f in "${FEATURES[@]}"; do
        local name="${f%%:*}"
        if ! is_feature_installed "$name"; then
            missing+=("$name")
        fi
    done
    echo "${missing[*]}"
}

# Initialize colors when sourced
setup_colors

