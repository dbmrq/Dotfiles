#!/usr/bin/env bash
#
# Shared library for bootstrap scripts
# Source this file to get common functions and feature definitions
#

# --- Exit Codes ---
# Use meaningful exit codes for different failure types
readonly E_SUCCESS=0        # Successful execution
readonly E_GENERAL=1        # General/unspecified error
readonly E_MISSING_DEP=2    # Missing dependency (command not found)
readonly E_USER_ABORT=3     # User cancelled operation
readonly E_INVALID_ARG=4    # Invalid argument or option
readonly E_OS_UNSUPPORTED=5 # Unsupported operating system
readonly E_PERMISSION=6     # Permission denied
readonly E_NETWORK=7        # Network error (download failed)

# --- Configuration ---
# Use readonly for constants that should not change during execution
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR

DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$LIB_DIR")}"
readonly DOTFILES_DIR

readonly BREWFILE="$LIB_DIR/Brewfile"
readonly PACKAGES_DEBIAN="$LIB_DIR/packages-debian.txt"

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
# Print a green checkmark with message (compact format)
print_ok() { printf '%b✓%b %s\n' "${GREEN}" "${NC}" "$1"; }

# Print a green success message (message also green)
print_success() { printf '%b✓ %s%b\n' "${GREEN}" "$1" "${NC}"; }

# Print a yellow warning indicator (compact format)
print_warn() { printf '%b!%b %s\n' "${YELLOW}" "${NC}" "$1"; }

# Print a yellow warning message (message also yellow)
print_warning() { printf '%b! %s%b\n' "${YELLOW}" "$1" "${NC}"; }

# Print a red error message
print_error() { printf '%b✗%b %s\n' "${RED}" "${NC}" "$1" >&2; }

# Print a blue info indicator
print_info() { printf '%b→%b %s\n' "${BLUE}" "${NC}" "$1"; }

# Print a bold blue section header
print_header() { printf '\n%b%b==> %s%b\n' "${BLUE}" "${BOLD}" "$1" "${NC}"; }

# --- Prompt Functions ---
# Ask a yes/no question with configurable default
# Arguments:
#   $1 - The prompt message to display
#   $2 - Default answer: "y" for yes (default), "n" for no
# Returns:
#   0 if user answered yes, 1 if no
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local reply

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
# Check if a command exists in PATH
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if command exists, 1 otherwise
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Temporary File Helpers ---
# Create a secure temporary file using mktemp
# Arguments:
#   $1 - Optional suffix for the temp file (e.g., ".txt")
# Returns:
#   Prints the path to the created temp file
#   Exit code 0 on success, E_GENERAL on failure
make_temp_file() {
    local suffix="${1:-}"
    local temp_file
    if [[ -n "$suffix" ]]; then
        temp_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles.XXXXXX$suffix") || return "$E_GENERAL"
    else
        temp_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles.XXXXXX") || return "$E_GENERAL"
    fi
    printf '%s' "$temp_file"
}

# Create a secure temporary directory using mktemp
# Returns:
#   Prints the path to the created temp directory
#   Exit code 0 on success, E_GENERAL on failure
make_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX") || return "$E_GENERAL"
    printf '%s' "$temp_dir"
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

# Ensure TMPDIR points to a user-writable location
# Some tools (like npx) fail when the system temp dir has restricted permissions
ensure_user_tmpdir() {
    local user_tmp="$HOME/.cache/tmp"

    # Check if current TMPDIR is writable
    if [[ -n "${TMPDIR:-}" ]] && [[ -d "$TMPDIR" ]] && [[ -w "$TMPDIR" ]]; then
        # Current TMPDIR is fine, test if we can actually create files
        if touch "$TMPDIR/.write_test" 2>/dev/null; then
            rm -f "$TMPDIR/.write_test"
            return 0
        fi
    fi

    # Fall back to user cache directory
    mkdir -p "$user_tmp"
    chmod 700 "$user_tmp"
    export TMPDIR="$user_tmp"
    export TMP="$user_tmp"
    export TEMP="$user_tmp"
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
# Arguments:
#   $@ - Package names to install
# Returns:
#   0 on success, 1 on failure or unknown package manager
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

# Check if a package is installed using the system package manager
# Arguments:
#   $1 - Package name to check
# Returns:
#   0 if installed, 1 if not installed or unknown package manager
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

# Get the path to the Homebrew executable based on architecture
# Returns:
#   Path to brew binary (Apple Silicon or Intel)
get_brew_path() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        printf '%s' "/opt/homebrew/bin/brew"
    else
        printf '%s' "/usr/local/bin/brew"
    fi
}

# Ensure Homebrew is available in the current PATH
# Evaluates brew shellenv if brew exists but isn't in PATH
ensure_brew_in_path() {
    if ! command_exists brew; then
        local brew_path
        brew_path="$(get_brew_path)"
        if [[ -x "$brew_path" ]]; then
            eval "$("$brew_path" shellenv)"
        fi
    fi
}

# Check if a Homebrew formula is installed
# Arguments:
#   $1 - Formula name to check
# Returns:
#   0 if installed, 1 otherwise
brew_pkg_installed() {
    local pkg="$1"
    ensure_brew_in_path
    command_exists brew && brew list "$pkg" >/dev/null 2>&1
}

# Check if a Homebrew cask is installed
# Arguments:
#   $1 - Cask name to check
# Returns:
#   0 if installed, 1 otherwise
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
