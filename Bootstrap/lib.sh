#!/usr/bin/env bash
#
# Shared library for bootstrap scripts
# Source this file to get common functions and feature definitions
#

# --- Configuration ---
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$LIB_DIR")}"
BREWFILE="$LIB_DIR/Brewfile"
PACKAGES_DEBIAN="$LIB_DIR/packages-debian.txt"

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

# --- OS Detection ---
# Returns: "macos", "linux", or "unknown"
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

# Cache OS detection result
OS="${OS:-$(detect_os)}"

# Check if running on macOS
is_macos() {
    [[ "$OS" == "macos" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OS" == "linux" ]]
}

# Get Linux distribution name (lowercase)
# Returns: debian, ubuntu, fedora, arch, rhel, centos, opensuse, alpine, or "unknown"
get_linux_distro() {
    if ! is_linux; then
        echo "none"
        return
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            debian|ubuntu|linuxmint|pop) echo "debian" ;;
            fedora) echo "fedora" ;;
            rhel|centos|rocky|alma) echo "rhel" ;;
            arch|manjaro|endeavouros) echo "arch" ;;
            opensuse*|sles) echo "opensuse" ;;
            alpine) echo "alpine" ;;
            *) echo "${ID:-unknown}" ;;
        esac
    elif command_exists lsb_release; then
        lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Cache distro detection result (only on Linux)
if is_linux; then
    LINUX_DISTRO="${LINUX_DISTRO:-$(get_linux_distro)}"
else
    LINUX_DISTRO="none"
fi

# --- Package Manager Detection (Linux) ---
# Returns the appropriate package manager command for the current system
get_package_manager() {
    if is_macos; then
        echo "brew"
    elif command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists apk; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Install packages using the appropriate package manager
# Usage: pkg_install pkg1 pkg2 ...
pkg_install() {
    local pm
    pm="$(get_package_manager)"

    case "$pm" in
        brew)
            brew install "$@"
            ;;
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        yum)
            sudo yum install -y "$@"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$@"
            ;;
        zypper)
            sudo zypper install -y "$@"
            ;;
        apk)
            sudo apk add "$@"
            ;;
        *)
            print_error "Unknown package manager"
            return 1
            ;;
    esac
}

# Check if a package is installed (Linux package managers)
pkg_installed() {
    local pkg="$1"
    local pm
    pm="$(get_package_manager)"

    case "$pm" in
        brew)
            brew list "$pkg" >/dev/null 2>&1
            ;;
        apt)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Qi "$pkg" >/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$pkg" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# --- Homebrew Helpers (macOS-specific) ---
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

# --- Package List Parsing ---
# These functions read from Brewfile (macOS) or packages-debian.txt (Linux)

# Parse Brewfile and extract brew formulas (one per line)
_parse_brewfile_formulas() {
    if [[ ! -f "$BREWFILE" ]]; then
        return
    fi
    # Extract package names from lines like: brew "git"  # comment
    grep -E '^brew "' "$BREWFILE" | sed 's/brew "//;s/".*//'
}

# Parse Brewfile and extract casks (one per line)
_parse_brewfile_casks() {
    if [[ ! -f "$BREWFILE" ]]; then
        return
    fi
    # Extract cask names from lines like: cask "hammerspoon"  # comment
    grep -E '^cask "' "$BREWFILE" | sed 's/cask "//;s/".*//'
}

# Parse packages-debian.txt (simple line-based format)
_parse_debian_packages() {
    if [[ ! -f "$PACKAGES_DEBIAN" ]]; then
        return
    fi
    # Skip comments and empty lines
    grep -v '^#' "$PACKAGES_DEBIAN" | grep -v '^$'
}

# Get all CLI packages for current OS (space-separated)
get_all_cli_packages() {
    if is_macos; then
        _parse_brewfile_formulas | tr '\n' ' '
    else
        _parse_debian_packages | tr '\n' ' '
    fi
}

# Get all GUI casks (space-separated, macOS only)
get_all_gui_casks() {
    if ! is_macos; then
        return
    fi
    _parse_brewfile_casks | tr '\n' ' '
}

# Get all GUI formulas (space-separated, macOS only)
# Note: We no longer have separate GUI formulas (neovim is in CLI)
get_all_gui_formulas() {
    echo ""
}

# --- Legacy Feature Functions (for backward compatibility) ---
# These will be removed in Phase 4 when bootstrap.sh is overhauled

# Stow packages are now auto-detected from directories
get_stow_packages() {
    local packages=()
    for dir in "$DOTFILES_DIR"/*/; do
        local name
        name="$(basename "$dir")"
        [[ "$name" == "Bootstrap" ]] && continue
        packages+=("$name")
    done
    echo "${packages[*]}"
}

# Legacy: get_feature_keys - returns stow package names as "features"
get_feature_keys() {
    get_stow_packages
}

# Legacy: get_feature_name - just returns the feature name
get_feature_name() {
    echo "$1"
}

# Legacy: feature_applies_to_os - all features apply (OS-specific logic removed)
feature_applies_to_os() {
    return 0
}

# Legacy: get_stow_package - returns the feature name itself
get_stow_package() {
    echo "$1"
}

# Legacy: get_brew_packages - returns empty (packages now in Brewfile)
get_brew_packages() {
    echo ""
}

# Legacy: get_brew_casks - returns empty (casks now in Brewfile)
get_brew_casks() {
    echo ""
}

# Legacy: get_linux_packages - returns empty (packages now in packages-debian.txt)
get_linux_packages() {
    echo ""
}

# Legacy: get_post_install - returns empty (post-install logic simplified)
get_post_install() {
    echo ""
}

# Legacy: is_feature_macos_only - returns false (OS-specific logic removed)
is_feature_macos_only() {
    return 1
}

# Legacy: is_feature_linux_only - returns false (OS-specific logic removed)
is_feature_linux_only() {
    return 1
}

# --- Status Checking Functions ---

# Check if a CLI package is installed (works on both macOS and Linux)
cli_pkg_installed() {
    local pkg="$1"
    if is_macos; then
        brew_pkg_installed "$pkg"
    else
        pkg_installed "$pkg"
    fi
}

# Check status of CLI tools: returns "installed:missing" counts
check_cli_tools_status() {
    local installed=0 missing=0
    local packages
    packages=$(get_all_cli_packages)
    for pkg in $packages; do
        if cli_pkg_installed "$pkg"; then
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
        if ! cli_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[*]}"
}

# Check status of GUI apps: returns "installed:missing" counts (macOS only)
check_gui_apps_status() {
    # GUI apps only on macOS
    if ! is_macos; then
        echo "0:0"
        return
    fi

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

# Get list of missing GUI apps (space-separated, macOS only)
get_missing_gui_apps() {
    # GUI apps only on macOS
    if ! is_macos; then
        echo ""
        return
    fi

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

# Check prezto status (deprecated - Prezto removed in Phase 3)
# Always returns "installed" to skip Prezto installation prompts
check_prezto_status() {
    echo "installed"
}

# --- Feature Detection ---

# Check if a feature is fully installed
# Returns 0 if installed, 1 if missing something
is_feature_installed() {
    local feature="$1"
    local stow_pkg

    # Skip features that don't apply to this OS
    if ! feature_applies_to_os "$feature"; then
        return 0  # Consider it "installed" if it doesn't apply
    fi

    if is_macos; then
        ensure_brew_in_path

        local brew_pkgs brew_casks
        brew_pkgs=$(get_brew_packages "$feature")
        brew_casks=$(get_brew_casks "$feature")

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
    else
        # Linux: check Linux packages
        local linux_pkgs
        linux_pkgs=$(get_linux_packages "$feature")
        for pkg in $linux_pkgs; do
            if ! pkg_installed "$pkg"; then
                return 1
            fi
        done
    fi

    # Check stow package (just check if main symlinks exist)
    stow_pkg=$(get_stow_package "$feature")
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

    # Special checks (macOS only)
    if is_macos; then
        case "$feature" in
            xcode)
                [[ -d "/Applications/Xcode.app" ]] || return 1
                ;;
        esac
    fi

    return 0
}

# Get list of missing features for current OS (space-separated)
get_missing_features() {
    local missing=()
    local features
    features=$(get_feature_keys)
    for name in $features; do
        # Only check features that apply to this OS
        if feature_applies_to_os "$name" && ! is_feature_installed "$name"; then
            missing+=("$name")
        fi
    done
    echo "${missing[*]}"
}
