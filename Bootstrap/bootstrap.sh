#!/usr/bin/env bash
#
# Bootstrap script for setting up a new macOS or Linux machine
# - Detects what's already installed (idempotent)
# - Asks all questions upfront, then runs unattended
# - Each step checks if already done before running
#
# Usage:
#   ./bootstrap.sh            # Interactive mode - detect, verify, ask
#   ./bootstrap.sh --verify   # Only check status, don't make changes
#   ./bootstrap.sh --force    # Install everything without asking
#   ./bootstrap.sh --dry-run  # Show what would be done without doing it
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
export DOTFILES_DIR  # exported for lib.sh
TEMP_FILES=()
SUDO_PID=""
BOOTSTRAP_SUCCESS=false
DRY_RUN=false
MODE="${1:-interactive}"  # interactive, --verify, --force, or --dry-run

# Handle --dry-run flag
if [[ "$MODE" == "--dry-run" ]]; then
    DRY_RUN=true
    MODE="--force"  # Dry-run acts like force mode but doesn't execute
fi

# Source shared library for feature definitions and common functions
source "$SCRIPT_DIR/lib.sh"

# --- Dry-run wrapper ---
# Wraps a command: in dry-run mode, prints it; otherwise, executes it
run_cmd() {
    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} $*"
        return 0
    else
        "$@"
    fi
}

# Same as run_cmd but for sudo commands
run_sudo() {
    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} sudo $*"
        return 0
    else
        sudo "$@"
    fi
}

# --- Cleanup handler ---
cleanup() {
    local exit_code=$?

    # Kill sudo keepalive process
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi

    # Remove temporary files
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        for temp_file in "${TEMP_FILES[@]}"; do
            if [[ -e "$temp_file" ]]; then
                rm -rf "$temp_file" 2>/dev/null || true
            fi
        done
    fi

    # Show completion message
    if $BOOTSTRAP_SUCCESS; then
        echo ""
        echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}║     Bootstrap Complete!                ║${NC}"
        echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "You may want to:"
        echo "  • Restart your terminal for shell changes to take effect"
        echo "  • Log out and back in for all preferences to apply"
        if is_macos; then
            echo "  • Restart your Mac if system updates were installed"
        fi
        echo ""
    elif [[ $exit_code -ne 0 ]]; then
        echo ""
        print_error "Bootstrap interrupted or failed (exit code: $exit_code)"
        echo ""
        echo "Run the script again to retry. Each step will skip if already done."
        echo ""
    fi

    exit $exit_code
}

trap cleanup EXIT INT TERM

# --- Helper functions ---
# (Most helper functions are now in lib.sh)

# Display full system status
show_system_status() {
    print_header "System Status"

    if is_macos; then
        # Xcode CLI tools (macOS only)
        if xcode-select -p >/dev/null 2>&1; then
            print_success "Xcode Command Line Tools"
        else
            print_warning "Xcode Command Line Tools: not installed"
        fi

        # Homebrew
        ensure_brew_in_path
        if command_exists brew; then
            print_success "Homebrew"
        else
            print_warning "Homebrew: not installed"
        fi

        # GUI apps (macOS only)
        local gui_status
        gui_status=$(check_gui_apps_status)
        local gui_installed="${gui_status%:*}"
        local gui_missing="${gui_status#*:}"
        if [[ "$gui_missing" -eq 0 ]]; then
            print_success "GUI applications ($gui_installed apps)"
        else
            print_warning "GUI applications: $gui_installed installed, $gui_missing missing"
        fi

        # Xcode app (macOS only)
        if [[ -d "/Applications/Xcode.app" ]]; then
            print_success "Xcode (App Store)"
        else
            print_warning "Xcode (App Store): not installed"
        fi
    else
        # Linux: show package manager
        local pm
        pm="$(get_package_manager)"
        print_success "Package manager: $pm"
    fi

    # CLI tools (both platforms)
    local cli_status
    cli_status=$(check_cli_tools_status)
    local cli_installed="${cli_status%:*}"
    local cli_missing="${cli_status#*:}"
    if [[ "$cli_missing" -eq 0 ]]; then
        print_success "CLI tools ($cli_installed packages)"
    else
        print_warning "CLI tools: $cli_installed installed, $cli_missing missing"
    fi

    # Dotfiles (both platforms)
    local stow_status
    stow_status=$(check_stow_status)
    if [[ "$stow_status" == "ok" ]]; then
        print_success "Dotfiles symlinks"
    else
        print_warning "Dotfiles: some symlinks need attention"
    fi

    # SSH keys (both platforms)
    local ssh_count
    ssh_count=$(check_ssh_keys_status)
    if [[ "$ssh_count" -gt 0 ]]; then
        print_success "GitHub SSH keys ($ssh_count accounts)"
    else
        print_warning "GitHub SSH keys: not configured"
    fi

    echo ""
}

# Track a temporary file/directory for cleanup
track_temp() {
    TEMP_FILES+=("$1")
}

# --- Compatibility checks ---
check_compatibility() {
    print_header "Checking system compatibility"

    if is_macos; then
        # Get macOS version
        local macos_version
        macos_version="$(sw_vers -productVersion)"
        local major_version
        major_version="$(echo "$macos_version" | cut -d. -f1)"

        print_success "macOS $macos_version detected"

        # Check architecture
        local arch
        arch="$(uname -m)"
        if [[ "$arch" == "arm64" ]]; then
            print_success "Apple Silicon (arm64) detected"
        else
            print_success "Intel ($arch) detected"
        fi

        # Warn about older macOS versions
        if [[ "$major_version" -lt 11 ]]; then
            print_warning "macOS 11+ recommended. Some features may not work."
        fi
    elif is_linux; then
        print_success "Linux detected"

        # Show distribution
        local distro
        distro="$LINUX_DISTRO"
        if [[ "$distro" != "unknown" ]]; then
            print_success "Distribution: $distro"
        fi

        # Show package manager
        local pm
        pm="$(get_package_manager)"
        if [[ "$pm" != "unknown" ]]; then
            print_success "Package manager: $pm"
        else
            print_warning "No supported package manager found"
        fi
    else
        print_error "Unsupported operating system"
        exit 1
    fi

    echo ""
}

# --- Gather git identity ---
gather_git_identity() {
    echo ""
    echo "  This will be used for all git commits on this machine."
    echo ""

    # Try to get existing values as defaults
    local default_name default_email
    default_name=$(git config --global user.name 2>/dev/null || echo "")
    default_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$default_name" ]]; then
        read -r -p "  Your name [$default_name]: " GIT_USER_NAME
        GIT_USER_NAME="${GIT_USER_NAME:-$default_name}"
    else
        read -r -p "  Your name: " GIT_USER_NAME
        while [[ -z "$GIT_USER_NAME" ]]; do
            echo "  Name is required."
            read -r -p "  Your name: " GIT_USER_NAME
        done
    fi

    if [[ -n "$default_email" ]]; then
        read -r -p "  Your email [$default_email]: " GIT_USER_EMAIL
        GIT_USER_EMAIL="${GIT_USER_EMAIL:-$default_email}"
    else
        read -r -p "  Your email: " GIT_USER_EMAIL
        while [[ -z "$GIT_USER_EMAIL" ]]; do
            echo "  Email is required."
            read -r -p "  Your email: " GIT_USER_EMAIL
        done
    fi

    print_success "  Git identity: $GIT_USER_NAME <$GIT_USER_EMAIL>"
}

# --- Gather GitHub account configuration ---
gather_github_accounts() {
    echo ""
    echo "  Add GitHub accounts one at a time. For each account, you'll specify:"
    echo "    - A label (e.g., 'personal', 'work')"
    echo "    - Your display name for commits"
    echo "    - The GitHub username"
    echo "    - Email for commits"
    echo "    - Usernames/orgs to map to this account"
    echo ""

    local account_count=0
    while true; do
        if [[ $account_count -gt 0 ]]; then
            if ! ask_yes_no "  Add another GitHub account?"; then
                break
            fi
        fi

        echo ""
        read -r -p "  Account label (e.g., personal, work): " account_name
        if [[ -z "$account_name" ]]; then
            echo "  Skipping empty label"
            continue
        fi
        # Normalize to lowercase, no spaces
        account_name=$(echo "$account_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

        read -r -p "  Your name (for commits): " display_name
        if [[ -z "$display_name" ]]; then
            echo "  Skipping - name required"
            continue
        fi

        read -r -p "  GitHub username: " github_username
        if [[ -z "$github_username" ]]; then
            echo "  Skipping - username required"
            continue
        fi

        read -r -p "  Email for commits: " account_email
        if [[ -z "$account_email" ]]; then
            echo "  Skipping - email required"
            continue
        fi

        echo "  Which users/orgs should use this account?"
        echo "  (comma-separated, e.g., 'myuser,myorg,another-org')"
        echo "  The username '$github_username' will be added automatically."
        read -r -p "  Additional mappings (or press Enter for none): " extra_mappings

        # Always include the username itself
        local all_mappings="$github_username"
        if [[ -n "$extra_mappings" ]]; then
            all_mappings="$github_username,$extra_mappings"
        fi

        # Store as "label|displayname|username|email|mappings"
        GITHUB_ACCOUNTS+=("$account_name|$display_name|$github_username|$account_email|$all_mappings")
        ((account_count++))
        print_success "  Added account: $account_name ($github_username)"
    done

    # Ask which is default if we have accounts
    if [[ ${#GITHUB_ACCOUNTS[@]} -gt 0 ]]; then
        echo ""
        echo "  Which account should be the default for other repos?"
        local i=1
        for account in "${GITHUB_ACCOUNTS[@]}"; do
            local label username
            label=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f3)
            echo "    $i) $label ($username)"
            ((i++))
        done
        read -r -p "  Choose [1-${#GITHUB_ACCOUNTS[@]}]: " default_choice
        if [[ "$default_choice" =~ ^[0-9]+$ ]] && [[ "$default_choice" -ge 1 ]] && [[ "$default_choice" -le ${#GITHUB_ACCOUNTS[@]} ]]; then
            DEFAULT_GITHUB_ACCOUNT=$((default_choice - 1))
        else
            DEFAULT_GITHUB_ACCOUNT=0
        fi
    fi
}

# --- Gather all choices upfront ---
gather_choices() {
    # Initialize all choices
    DO_MACOS_UPDATE=false
    DO_XCODE_TOOLS=false
    DO_HOMEBREW=false
    DO_BREW_CLI=false
    DO_BREW_APPS=false
    DO_XCODE_APP=false
    DO_PREFS=false
    DO_CLEAR_DOCK=false
    DO_TERMINAL_THEME=false
    DO_LATEX=false
    DO_STOW=false
    DO_PLUGINS=false
    DO_DEFAULT_APPS=false
    DO_GIT_IDENTITY=false
    GIT_USER_NAME=""
    GIT_USER_EMAIL=""
    DO_SHELL_LOCAL=false
    DO_SSH_KEYS=false
    GITHUB_ACCOUNTS=()
    SELECTED_CLI_PACKAGES=()
    SELECTED_GUI_APPS=()
    DEFAULT_GITHUB_ACCOUNT=""

    # First, show current system status (this also caches all the checks)
    show_system_status

    # --- Run all status checks UPFRONT (slow operations) ---
    echo "Checking system state..."

    local has_xcode_tools=false
    local has_brew=false
    local missing_cli=""
    local cli_missing_count=0
    local missing_gui=""
    local gui_missing_count=0
    local has_xcode_app=false

    if is_macos; then
        ensure_brew_in_path
        xcode-select -p >/dev/null 2>&1 && has_xcode_tools=true
        command_exists brew && has_brew=true

        if $has_brew; then
            local cli_status; cli_status=$(check_cli_tools_status)
            cli_missing_count="${cli_status#*:}"
            [[ "$cli_missing_count" -gt 0 ]] && missing_cli=$(get_missing_cli_tools)

            local gui_status; gui_status=$(check_gui_apps_status)
            gui_missing_count="${gui_status#*:}"
            [[ "$gui_missing_count" -gt 0 ]] && missing_gui=$(get_missing_gui_apps)
        fi

        [[ -d "/Applications/Xcode.app" ]] && has_xcode_app=true
    else
        # Linux: check CLI tools directly
        local cli_status; cli_status=$(check_cli_tools_status)
        cli_missing_count="${cli_status#*:}"
        [[ "$cli_missing_count" -gt 0 ]] && missing_cli=$(get_missing_cli_tools)
    fi

    local stow_status; stow_status=$(check_stow_status)
    local ssh_count; ssh_count=$(check_ssh_keys_status)

    echo ""

    # --- Force mode: enable everything that's missing ---
    if [[ "$MODE" == "--force" ]]; then
        print_header "Force mode: installing all missing components"
        if is_macos; then
            DO_MACOS_UPDATE=false  # Never force macOS updates
            $has_xcode_tools || DO_XCODE_TOOLS=true
            $has_brew || DO_HOMEBREW=true
            if [[ "$gui_missing_count" -gt 0 ]]; then
                DO_BREW_APPS=true
                DO_HOMEBREW=true
                read -ra SELECTED_GUI_APPS <<< "$(get_all_gui_casks) $(get_all_gui_formulas)"
            fi
            $has_xcode_app || DO_XCODE_APP=true
        fi
        if [[ "$cli_missing_count" -gt 0 ]]; then
            DO_BREW_CLI=true
            is_macos && DO_HOMEBREW=true
            read -ra SELECTED_CLI_PACKAGES <<< "$(get_all_cli_packages)"
        fi
        [[ "$stow_status" != "ok" ]] && DO_STOW=true
        # Update plugins if vim/neovim are installed
        (command_exists vim || command_exists nvim) && DO_PLUGINS=true
        # Set up default apps (Neovim.app + duti) on macOS
        is_macos && DO_DEFAULT_APPS=true
        show_summary_and_confirm
        return
    fi

    # --- Interactive mode: ask all questions upfront ---
    print_header "Configuration"
    echo "Answer all questions, then the script will run unattended."
    echo ""

    local anything_to_do=false

    # macOS updates - ask only on macOS
    if is_macos && ask_yes_no "Check for macOS updates?"; then
        DO_MACOS_UPDATE=true
        anything_to_do=true
    fi

    # Xcode CLI tools (macOS only)
    if is_macos && ! $has_xcode_tools; then
        if ask_yes_no "Install Xcode Command Line Tools? (required for most tasks)" "y"; then
            DO_XCODE_TOOLS=true
            anything_to_do=true
        fi
    fi

    # Homebrew (macOS only)
    if is_macos && ! $has_brew; then
        if ask_yes_no "Install Homebrew? (required for packages)" "y"; then
            DO_HOMEBREW=true
            anything_to_do=true
        fi
    fi

    # CLI tools - use cached results
    if [[ "$cli_missing_count" -gt 0 ]]; then
        echo ""
        echo "Missing CLI tools: $missing_cli"
        if ask_yes_no "Install all missing CLI tools?" "y"; then
            DO_BREW_CLI=true
            is_macos && DO_HOMEBREW=true
            anything_to_do=true
            read -ra SELECTED_CLI_PACKAGES <<< "$(get_all_cli_packages)"
        else
            # Ask about each missing package
            SELECTED_CLI_PACKAGES=()
            for pkg in $missing_cli; do
                if ask_yes_no "  Install $pkg?"; then
                    SELECTED_CLI_PACKAGES+=("$pkg")
                    DO_BREW_CLI=true
                    is_macos && DO_HOMEBREW=true
                    anything_to_do=true
                fi
            done
        fi
    fi

    # GUI apps - macOS only
    if is_macos && [[ "$gui_missing_count" -gt 0 ]]; then
        echo ""
        echo "Missing GUI apps: $missing_gui"
        if ask_yes_no "Install all missing GUI apps?" "y"; then
            DO_BREW_APPS=true
            DO_HOMEBREW=true
            anything_to_do=true
            read -ra SELECTED_GUI_APPS <<< "$(get_all_gui_casks) $(get_all_gui_formulas)"
        else
            # Ask about each missing app
            SELECTED_GUI_APPS=()
            for app in $missing_gui; do
                if ask_yes_no "  Install $app?"; then
                    SELECTED_GUI_APPS+=("$app")
                    DO_BREW_APPS=true
                    DO_HOMEBREW=true
                    anything_to_do=true
                fi
            done
        fi
    fi

    # Xcode from App Store (macOS only)
    if is_macos && ! $has_xcode_app; then
        if ask_yes_no "Install Xcode from App Store?"; then
            DO_XCODE_APP=true
            anything_to_do=true
        fi
    fi

    # macOS preferences (macOS only)
    if is_macos && ask_yes_no "Apply/reapply macOS preferences?"; then
        DO_PREFS=true
        anything_to_do=true
        if ask_yes_no "  Clear all apps from Dock?"; then
            DO_CLEAR_DOCK=true
        fi
    fi

    # Terminal theme (macOS only)
    if is_macos && ask_yes_no "Install/reinstall Solarized terminal theme?"; then
        DO_TERMINAL_THEME=true
        anything_to_do=true
    fi

    # LaTeX (macOS only, optional - installs BasicTeX + minimal packages)
    if is_macos && ask_yes_no "Install LaTeX (BasicTeX + pandoc support)?"; then
        DO_LATEX=true
        anything_to_do=true
    fi

    # Dotfiles - use cached result
    if [[ "$stow_status" != "ok" ]]; then
        if ask_yes_no "Fix dotfiles symlinks?" "y"; then
            DO_STOW=true
            anything_to_do=true
        fi
    else
        # Even if OK, offer to re-stow (might catch new files)
        if ask_yes_no "Re-check and update dotfiles symlinks?"; then
            DO_STOW=true
            anything_to_do=true
        fi
    fi

    # Vim/Neovim plugins - only ask if vim or neovim selected/installed
    if command_exists vim || command_exists nvim; then
        if ask_yes_no "Update Vim/Neovim plugins?"; then
            DO_PLUGINS=true
            anything_to_do=true
        fi
    fi

    # Default applications (macOS only - Neovim.app + file associations)
    if is_macos; then
        if ask_yes_no "Set up default apps (Neovim for text files)?"; then
            DO_DEFAULT_APPS=true
            anything_to_do=true
        fi
    fi

    # Git identity - check if ~/.gitconfig.local exists with user info
    if [[ ! -f "$HOME/.gitconfig.local" ]] || ! grep -q '^\[user\]' "$HOME/.gitconfig.local" 2>/dev/null; then
        echo ""
        echo "Git needs your identity for commits (name and email)."
        if ask_yes_no "Configure git identity?" "y"; then
            DO_GIT_IDENTITY=true
            anything_to_do=true
            gather_git_identity
        fi
    fi

    # Shell local config - check if ~/.zshrc.local exists
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        if ask_yes_no "Create shell local config file (~/.zshrc.local)?"; then
            DO_SHELL_LOCAL=true
            anything_to_do=true
        fi
    fi

    # SSH keys - use cached result
    if [[ "$ssh_count" -eq 0 ]]; then
        if ask_yes_no "Set up GitHub accounts (SSH keys)?"; then
            DO_SSH_KEYS=true
            anything_to_do=true
            gather_github_accounts
        fi
    else
        if ask_yes_no "Manage GitHub accounts? ($ssh_count currently configured)"; then
            DO_SSH_KEYS=true
            anything_to_do=true
            gather_github_accounts
        fi
    fi

    if ! $anything_to_do; then
        echo ""
        print_success "Everything looks good! Nothing to install."
        echo ""
        BOOTSTRAP_SUCCESS=true
        exit 0
    fi

    show_summary_and_confirm
}

# Show summary of choices and ask for confirmation
show_summary_and_confirm() {
    echo ""
    print_header "Ready to bootstrap"
    echo "The following will be installed/configured:"
    $DO_MACOS_UPDATE && echo "  • macOS updates"
    $DO_XCODE_TOOLS && echo "  • Xcode Command Line Tools"
    $DO_HOMEBREW && echo "  • Homebrew"
    if $DO_BREW_CLI; then
        if is_macos; then
            echo "  • CLI tools via Homebrew"
        else
            echo "  • CLI tools via package manager"
        fi
    fi
    $DO_BREW_APPS && echo "  • GUI apps via Homebrew"
    $DO_XCODE_APP && echo "  • Xcode from App Store"
    $DO_PREFS && echo "  • macOS preferences"
    $DO_CLEAR_DOCK && echo "  • Clear Dock"
    $DO_TERMINAL_THEME && echo "  • Terminal color scheme"
    $DO_LATEX && echo "  • LaTeX (BasicTeX)"
    $DO_STOW && echo "  • Dotfiles symlinks"
    $DO_DEFAULT_APPS && echo "  • Default apps (Neovim for text files)"
    $DO_GIT_IDENTITY && echo "  • Git identity ($GIT_USER_NAME <$GIT_USER_EMAIL>)"
    $DO_SHELL_LOCAL && echo "  • Shell local config (~/.zshrc.local)"
    if $DO_SSH_KEYS && [[ ${#GITHUB_ACCOUNTS[@]} -gt 0 ]]; then
        echo "  • GitHub accounts:"
        for i in "${!GITHUB_ACCOUNTS[@]}"; do
            local account="${GITHUB_ACCOUNTS[$i]}"
            local label username
            label=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f3)
            if [[ "$i" -eq "${DEFAULT_GITHUB_ACCOUNT:-0}" ]]; then
                echo "      - $label ($username) [default]"
            else
                echo "      - $label ($username)"
            fi
        done
    fi
    echo ""

    # In dry-run mode, auto-confirm
    if $DRY_RUN; then
        echo "Proceeding with dry run..."
        return
    fi

    if ! ask_yes_no "Proceed with installation?" "y"; then
        echo "Aborted."
        exit 0
    fi
}

# --- Installation steps ---
# Each step is idempotent (safe to run multiple times)
# Each step checks if already done before running

install_macos_updates() {
    print_header "Updating macOS"
    run_sudo softwareupdate -i -a || print_warning "Some updates may require a restart"
    print_success "macOS updates complete"
}

install_xcode_tools() {
    print_header "Installing Xcode Command Line Tools"

    # Already installed? Skip.
    if xcode-select -p >/dev/null 2>&1; then
        print_success "Xcode Command Line Tools already installed"
        return 0
    fi

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} xcode-select --install"
        print_success "Xcode Command Line Tools would be installed"
        return 0
    fi

    # This opens a dialog; we wait for it to complete
    xcode-select --install 2>/dev/null || true

    # Wait for installation to complete (with timeout)
    local wait_count=0
    local max_wait=120  # 10 minutes
    until xcode-select -p >/dev/null 2>&1; do
        sleep 5
        ((wait_count++))
        if [[ $wait_count -ge $max_wait ]]; then
            print_error "Timed out waiting for Xcode Command Line Tools"
            return 1
        fi
    done
    print_success "Xcode Command Line Tools installed"
}

install_homebrew() {
    print_header "Setting up Homebrew"

    if ! command_exists brew; then
        echo "Installing Homebrew..."
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        else
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add to current shell
            ensure_brew_in_path

            # Add to profile if not already there
            local brew_path
            brew_path="$(get_brew_path)"
            if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo "eval \"\$(${brew_path} shellenv)\"" >> "$HOME/.zprofile"
            fi
        fi
    else
        echo "Homebrew already installed. Updating..."
        run_cmd brew update || print_warning "brew update failed, continuing anyway"
    fi

    print_success "Homebrew ready"
}

install_brew_cli() {
    print_header "Installing CLI tools"

    # Use selected packages if set, otherwise get from JSON
    local packages
    if [[ ${#SELECTED_CLI_PACKAGES[@]} -gt 0 ]]; then
        packages=("${SELECTED_CLI_PACKAGES[@]}")
    else
        # Read from JSON (get_all_cli_packages returns OS-appropriate list)
        read -ra packages <<< "$(get_all_cli_packages)"
    fi

    if is_macos; then
        ensure_brew_in_path
        if ! command_exists brew && ! $DRY_RUN; then
            print_warning "Homebrew not available, skipping CLI tools"
            return 1
        fi

        for pkg in "${packages[@]}"; do
            if ! $DRY_RUN && brew list "$pkg" >/dev/null 2>&1; then
                echo "  $pkg already installed"
            else
                echo "  Installing $pkg..."
                run_cmd brew install "$pkg" || print_warning "Failed to install $pkg"
            fi
        done
    else
        # Linux: use system package manager
        local pm
        pm="$(get_package_manager)"
        if [[ "$pm" == "unknown" ]]; then
            print_warning "No supported package manager found"
            return 1
        fi

        for pkg in "${packages[@]}"; do
            if ! $DRY_RUN && pkg_installed "$pkg"; then
                echo "  $pkg already installed"
            else
                echo "  Installing $pkg..."
                if $DRY_RUN; then
                    echo -e "  ${BLUE}[dry-run]${NC} pkg_install $pkg"
                else
                    pkg_install "$pkg" || print_warning "Failed to install $pkg"
                fi
            fi
        done
    fi

    print_success "CLI tools installed"
}

install_brew_apps() {
    print_header "Installing GUI applications"

    ensure_brew_in_path
    if ! command_exists brew && ! $DRY_RUN; then
        print_warning "Homebrew not available, skipping GUI apps"
        return 1
    fi

    # Use selected apps if set, otherwise get from JSON
    local apps
    if [[ ${#SELECTED_GUI_APPS[@]} -gt 0 ]]; then
        apps=("${SELECTED_GUI_APPS[@]}")
    else
        # Read all GUI apps from JSON (casks + formulas)
        local casks=() formulas=()
        local casks_str formulas_str
        casks_str="$(get_all_gui_casks)"
        formulas_str="$(get_all_gui_formulas)"
        [[ -n "$casks_str" ]] && read -ra casks <<< "$casks_str"
        [[ -n "$formulas_str" ]] && read -ra formulas <<< "$formulas_str"
        apps=()
        [[ ${#casks[@]} -gt 0 ]] && apps+=("${casks[@]}")
        [[ ${#formulas[@]} -gt 0 ]] && apps+=("${formulas[@]}")
    fi

    # Get cask list from JSON for type checking
    local cask_list
    cask_list="$(get_all_gui_casks)"

    for app in "${apps[@]}"; do
        # Check if it's a cask app or brew formula
        if [[ " $cask_list " == *" $app "* ]]; then
            if ! $DRY_RUN && brew list --cask "$app" >/dev/null 2>&1; then
                echo "  $app already installed"
            else
                echo "  Installing $app..."
                run_cmd brew install --cask "$app" || print_warning "Failed to install $app"
            fi
        else
            if ! $DRY_RUN && brew list "$app" >/dev/null 2>&1; then
                echo "  $app already installed"
            else
                echo "  Installing $app..."
                run_cmd brew install "$app" || print_warning "Failed to install $app"
            fi
        fi
    done

    run_cmd brew cleanup || true

    print_success "GUI applications installed"
}

install_xcode_app() {
    print_header "Installing Xcode from App Store"

    ensure_brew_in_path
    if ! command_exists mas && ! $DRY_RUN; then
        print_warning "mas not installed, skipping Xcode App Store install"
        return 0  # Not a failure, just skipped
    fi

    # Check if Xcode is already installed
    if [[ -d "/Applications/Xcode.app" ]]; then
        print_success "Xcode already installed"
    else
        echo "Installing Xcode (this may take a while)..."
        run_cmd mas install 497799835 || print_warning "Failed to install Xcode"
    fi

    # Accept license
    if [[ -d "/Applications/Xcode.app" ]] || $DRY_RUN; then
        run_sudo xcodebuild -license accept 2>/dev/null || true
    fi

    print_success "Xcode setup complete"
}

apply_preferences() {
    print_header "Applying macOS preferences"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} /bin/bash $SCRIPT_DIR/prefs.sh"
        print_success "Preferences would be applied"
        return 0
    fi

    # Close System Preferences/Settings to prevent conflicts
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
    osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

    /bin/bash "$SCRIPT_DIR/prefs.sh"

    print_success "Preferences applied"
}

clear_dock() {
    print_header "Clearing Dock"
    run_cmd defaults write com.apple.dock persistent-apps -array
    run_cmd defaults write com.apple.dock persistent-others -array
    run_cmd killall Dock || true
    print_success "Dock cleared"
}

install_terminal_theme() {
    print_header "Installing Terminal color scheme"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} git clone https://github.com/dbmrq/terminal-solarized.git /tmp/..."
        echo -e "  ${BLUE}[dry-run]${NC} open Solarized Dark.terminal"
        echo -e "  ${BLUE}[dry-run]${NC} open Solarized Light.terminal"
        print_success "Terminal color scheme would be installed"
        return 0
    fi

    local temp_dir
    temp_dir="$(mktemp -d)"
    track_temp "$temp_dir"

    git clone --depth 1 https://github.com/dbmrq/terminal-solarized.git "$temp_dir"
    open "$temp_dir/Solarized Dark.terminal"
    open "$temp_dir/Solarized Light.terminal"

    # Give Terminal time to import
    sleep 2

    # Clean up (also handled by cleanup trap)
    rm -rf "$temp_dir"

    print_success "Terminal color scheme installed"
    print_warning "Set your preferred theme in Terminal preferences"
}

install_latex() {
    print_header "Installing LaTeX (BasicTeX)"

    # Check if BasicTeX is already installed
    if [[ -d "/Library/TeX" ]] && command_exists tlmgr; then
        print_success "BasicTeX already installed"
    else
        # Install BasicTeX via Homebrew cask
        echo "Installing BasicTeX..."
        ensure_brew_in_path
        if command_exists brew; then
            run_cmd brew install --cask basictex || {
                print_warning "Failed to install BasicTeX"
                return 0
            }
            # Add TeX to PATH for current session
            export PATH="/Library/TeX/texbin:$PATH"
        else
            print_warning "Homebrew not available, cannot install BasicTeX"
            return 0
        fi
    fi

    # Ensure tlmgr is in PATH
    if ! command_exists tlmgr; then
        export PATH="/Library/TeX/texbin:$PATH"
    fi

    if ! command_exists tlmgr && ! $DRY_RUN; then
        print_warning "tlmgr not found after installation"
        return 0
    fi

    # Update tlmgr
    echo "Updating TeX Live..."
    run_sudo tlmgr update --self --all 2>/dev/null || true

    # Install minimal packages needed for pandoc
    echo "Installing essential TeX packages for pandoc..."
    run_sudo tlmgr install \
        adjustbox babel-german background bidi collectbox csquotes everypage filehook \
        footmisc footnotebackref framed fvextra letltxmacro ly1 mdframed mweights \
        needspace pagecolor sourcecodepro sourcesanspro titling ucharcat ulem \
        unicode-math upquote xecjk xurl zref 2>/dev/null || true

    print_success "LaTeX setup complete (BasicTeX + pandoc support)"
}

setup_stow() {
    print_header "Symlinking dotfiles"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} $SCRIPT_DIR/stow.sh --force"
        print_success "Dotfiles would be symlinked"
        return 0
    fi

    # Call stow.sh which handles everything (installs stow if needed, stows all packages)
    "$SCRIPT_DIR/stow.sh" --force

    # Set up agent symlinks (cross-package symlinks that stow can't handle)
    setup_agent_symlinks

    print_success "Dotfiles symlinked"
}

setup_agent_symlinks() {
    # Creates ~/.augment/skills -> ~/.agents/skills symlink
    # This allows Augment to find skills while keeping them in the universal ~/.agents location
    # Stow handles ~/.agents -> Dotfiles/Agents/.agents, but can't do cross-package symlinks

    local augment_dir="$HOME/.augment"
    local agents_skills="$HOME/.agents/skills"
    local augment_skills="$augment_dir/skills"

    # Only proceed if ~/.agents/skills exists (stow should have created it)
    if [[ ! -d "$agents_skills" ]]; then
        print_warning "~/.agents/skills not found, skipping agent symlinks"
        return 0
    fi

    # Ensure ~/.augment directory exists (Augment creates this for runtime data)
    if [[ ! -d "$augment_dir" ]]; then
        mkdir -p "$augment_dir"
    fi

    # Create the symlink if it doesn't exist or points to wrong location
    if [[ -L "$augment_skills" ]]; then
        local current_target
        current_target="$(readlink "$augment_skills")"
        if [[ "$current_target" == "$agents_skills" || "$current_target" == "~/.agents/skills" ]]; then
            # Already correct
            return 0
        fi
        # Wrong target, remove and recreate
        rm "$augment_skills"
    elif [[ -e "$augment_skills" ]]; then
        # It's a real directory, back it up
        print_warning "Moving existing ~/.augment/skills to ~/.augment/skills.backup"
        mv "$augment_skills" "$augment_skills.backup"
    fi

    # Create the symlink
    ln -s "$agents_skills" "$augment_skills"
}

setup_plugins() {
    print_header "Updating Vim/Neovim plugins"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} $SCRIPT_DIR/plugins.sh --force"
    else
        # Call the plugins.sh script
        "$SCRIPT_DIR/plugins.sh" --force
    fi

    print_success "Plugins updated"
}

setup_default_apps() {
    print_header "Setting up default applications"

    # Only run on macOS
    if ! is_macos; then
        print_warning "Default apps setup is macOS only, skipping"
        return 0
    fi

    local macos_dir="$DOTFILES_DIR/macOS"

    # Install Neovim.app wrapper
    if [[ -d "$macos_dir/Neovim.app" ]]; then
        echo "Installing Neovim.app wrapper..."
        mkdir -p "$HOME/Applications"

        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} cp -R $macos_dir/Neovim.app ~/Applications/"
        else
            # Copy the app (not symlink, as app bundles work better as copies)
            rm -rf "$HOME/Applications/Neovim.app"
            cp -R "$macos_dir/Neovim.app" "$HOME/Applications/"

            # Register with Launch Services so Spotlight can find it
            /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister "$HOME/Applications/Neovim.app" 2>/dev/null || true
        fi
        print_success "Neovim.app installed to ~/Applications"
    fi

    # Apply duti settings for file associations
    if command_exists duti && [[ -f "$macos_dir/duti.conf" ]]; then
        echo "Setting default applications for file types..."
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} duti $macos_dir/duti.conf"
        else
            duti "$macos_dir/duti.conf" 2>/dev/null || print_warning "Some duti settings may have failed"
        fi
        print_success "Default file associations set"
    elif ! command_exists duti; then
        print_warning "duti not installed, skipping file associations"
        echo "  Install duti with: brew install duti"
    fi

    print_success "Default applications configured"
}

setup_git_identity() {
    print_header "Configuring git identity"

    if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
        print_warning "Git identity not provided, skipping"
        return 0
    fi

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} Would create ~/.gitconfig.local with:"
        echo -e "  ${BLUE}[dry-run]${NC}   name = $GIT_USER_NAME"
        echo -e "  ${BLUE}[dry-run]${NC}   email = $GIT_USER_EMAIL"
        print_success "Git identity would be configured"
        return 0
    fi

    # Create or update ~/.gitconfig.local
    local git_config_local="$HOME/.gitconfig.local"

    # If file exists, try to update just the user section
    if [[ -f "$git_config_local" ]]; then
        # Check if [user] section exists
        if grep -q '^\[user\]' "$git_config_local"; then
            # Update existing user section using git config
            git config --file "$git_config_local" user.name "$GIT_USER_NAME"
            git config --file "$git_config_local" user.email "$GIT_USER_EMAIL"
        else
            # Append user section
            {
                echo ""
                echo "[user]"
                echo "    name = $GIT_USER_NAME"
                echo "    email = $GIT_USER_EMAIL"
            } >> "$git_config_local"
        fi
    else
        # Create new file
        cat > "$git_config_local" << EOF
# Machine-specific Git config
# Generated by bootstrap script on $(date)
# You can edit this file manually

[user]
    name = $GIT_USER_NAME
    email = $GIT_USER_EMAIL
EOF
        # Add credential helper on macOS
        if is_macos; then
            cat >> "$git_config_local" << EOF

[credential]
    helper = osxkeychain
EOF
        fi
    fi

    print_success "Git identity configured in ~/.gitconfig.local"
}

setup_shell_local() {
    print_header "Creating shell local config"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} Would create ~/.zshrc.local"
        print_success "Shell local config would be created"
        return 0
    fi

    local zshrc_local="$HOME/.zshrc.local"

    if [[ -f "$zshrc_local" ]]; then
        print_success "$HOME/.zshrc.local already exists"
        return 0
    fi

    # Create the file with helpful comments
    cat > "$zshrc_local" << 'EOF'
# Machine-specific zsh configuration
# This file is sourced by .zshrc and is NOT tracked in the dotfiles repo
#
# Add machine-specific settings here, such as:
# - Tool-specific paths (uv, nvm, rbenv, etc.)
# - API keys and tokens
# - Work-specific aliases
# - Local overrides

# Example: uv (Python package manager)
# [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

EOF

    print_success "Created ~/.zshrc.local"
    echo "  Add machine-specific shell config to this file."
}

setup_ssh_keys() {
    print_header "Setting up GitHub accounts"

    if [[ ${#GITHUB_ACCOUNTS[@]} -eq 0 ]]; then
        print_warning "No GitHub accounts configured, skipping SSH setup"
        return 0
    fi

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} Would configure ${#GITHUB_ACCOUNTS[@]} GitHub account(s)"
        for account in "${GITHUB_ACCOUNTS[@]}"; do
            local label username
            label=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f3)
            echo -e "  ${BLUE}[dry-run]${NC}   - $label ($username)"
        done
        echo -e "  ${BLUE}[dry-run]${NC} Would create ~/.ssh/config.local"
        echo -e "  ${BLUE}[dry-run]${NC} Would update ~/.gitconfig.local with URL rewrites"
        print_success "GitHub accounts would be configured"
        return 0
    fi

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    local new_keys=()
    local default_account_name=""
    local default_identity_file=""

    # Start building the SSH config
    local ssh_config
    ssh_config="# Machine-specific SSH config for GitHub accounts
# Generated by bootstrap script on $(date)
# Do not edit manually - rerun bootstrap to regenerate

"

    # Get the default account info
    # Format: label|displayname|username|email|mappings
    local default_account="${GITHUB_ACCOUNTS[${DEFAULT_GITHUB_ACCOUNT:-0}]}"
    local default_username
    default_username=$(echo "$default_account" | cut -d'|' -f3)

    # Build URL rewrites for gitconfig (will be appended to existing file)
    local git_url_rewrites=""

    # Process each account
    # Format: label|displayname|username|email|mappings
    for i in "${!GITHUB_ACCOUNTS[@]}"; do
        local account="${GITHUB_ACCOUNTS[$i]}"
        local label username email mappings
        label=$(echo "$account" | cut -d'|' -f1)
        username=$(echo "$account" | cut -d'|' -f3)
        email=$(echo "$account" | cut -d'|' -f4)
        mappings=$(echo "$account" | cut -d'|' -f5)

        local key_file="$HOME/.ssh/id_ed25519_github_$label"
        local host_alias="github-$label"

        # Generate SSH key if it doesn't exist
        if [[ ! -f "$key_file" ]]; then
            echo "Generating SSH key for $label ($username)..."
            ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N ""
            new_keys+=("$label|$username|$key_file")
        else
            echo "  Key for $label already exists"
        fi

        # Add SSH host alias
        ssh_config+="# --- $label ($username) ---
Host $host_alias
    HostName github.com
    User git
    IdentityFile $key_file
    IdentitiesOnly yes

"

        # Add URL rewrites for each mapping
        if [[ -n "$mappings" ]]; then
            local mapping_array=()
            IFS=',' read -ra mapping_array <<< "$mappings"
            for mapping in "${mapping_array[@]}"; do
                mapping=$(echo "$mapping" | xargs)  # trim whitespace
                if [[ -n "$mapping" ]]; then
                    git_url_rewrites+="[url \"git@$host_alias:$mapping/\"]
    insteadOf = git@github.com:$mapping/
    insteadOf = https://github.com/$mapping/

"
                fi
            done
        fi

        # Track the default account
        if [[ "$i" -eq "${DEFAULT_GITHUB_ACCOUNT:-0}" ]]; then
            default_account_name="$label"
            default_identity_file="$key_file"
        fi
    done

    # Add default github.com host (uses the default account)
    ssh_config+="# --- Default (for repos not matching any mapping) ---
Host github.com
    HostName github.com
    User git
    IdentityFile $default_identity_file
    IdentitiesOnly yes
"

    # Write SSH config
    echo "$ssh_config" > ~/.ssh/config.local
    chmod 600 ~/.ssh/config.local
    print_success "SSH config created (~/.ssh/config.local)"

    # Update gitconfig.local - preserve existing content, add/update GitHub settings
    local git_config_local="$HOME/.gitconfig.local"

    # Ensure the file exists (setup_git_identity should have created it)
    if [[ ! -f "$git_config_local" ]]; then
        # Create minimal file if it doesn't exist
        cat > "$git_config_local" << EOF
# Machine-specific Git config
# Generated by bootstrap script on $(date)

EOF
    fi

    # Add github user if not present
    if ! grep -q '^\[github\]' "$git_config_local"; then
        cat >> "$git_config_local" << EOF

[github]
    user = $default_username
EOF
    else
        # Update existing github user
        git config --file "$git_config_local" github.user "$default_username"
    fi

    # Remove old URL rewrites (between markers) and add new ones
    # For simplicity, we'll append new rewrites - they'll override any duplicates
    if [[ -n "$git_url_rewrites" ]]; then
        # Add a marker comment and the URL rewrites
        cat >> "$git_config_local" << EOF

# --- GitHub account URL rewrites ---
# Generated by bootstrap script on $(date)
$git_url_rewrites
EOF
    fi

    print_success "Git config updated (~/.gitconfig.local)"

    # Show public keys for new accounts
    if [[ ${#new_keys[@]} -gt 0 ]]; then
        echo ""
        print_warning "New SSH keys generated! Add these public keys to GitHub:"
        echo ""
        echo "For each account below:"
        echo "  1. Go to the URL shown"
        echo "  2. Click 'New SSH key'"
        echo "  3. Give it a name (e.g., your machine name)"
        echo "  4. Paste the public key"
        echo ""
        for key_info in "${new_keys[@]}"; do
            local label username key_file
            label=$(echo "$key_info" | cut -d'|' -f1)
            username=$(echo "$key_info" | cut -d'|' -f2)
            key_file=$(echo "$key_info" | cut -d'|' -f3)
            echo "=== $label ($username) ==="
            echo "URL: https://github.com/settings/keys"
            echo "Key:"
            cat "${key_file}.pub"
            echo ""
        done
    fi

    print_success "GitHub accounts setup complete (default: $default_account_name)"
}

# --- Main execution ---
main() {
    echo ""
    if is_macos; then
        echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}║     macOS Bootstrap Script             ║${NC}"
        echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
    else
        echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}║     Linux Bootstrap Script             ║${NC}"
        echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
    fi
    if $DRY_RUN; then
        echo -e "${YELLOW}${BOLD}         (DRY RUN - no changes will be made)${NC}"
    fi
    echo ""

    check_compatibility

    # Handle verify mode - just show status and exit
    if [[ "$MODE" == "--verify" ]]; then
        show_system_status
        echo "Run without --verify to install missing components."
        exit 0
    fi

    # Gather choices (what to install)
    gather_choices

    # Request sudo upfront and keep it alive (skip in dry-run mode)
    if ! $DRY_RUN; then
        print_header "Requesting administrator access"
        sudo -v
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        SUDO_PID=$!
    else
        print_header "Dry run - skipping sudo"
    fi

    # Run selected installations
    # Each step is idempotent and checks if already done
    [[ "$DO_MACOS_UPDATE" == "true" ]] && install_macos_updates
    [[ "$DO_XCODE_TOOLS" == "true" ]] && install_xcode_tools
    [[ "$DO_HOMEBREW" == "true" ]] && install_homebrew
    [[ "$DO_BREW_CLI" == "true" ]] && install_brew_cli
    [[ "$DO_BREW_APPS" == "true" ]] && install_brew_apps
    [[ "$DO_XCODE_APP" == "true" ]] && install_xcode_app
    [[ "$DO_PREFS" == "true" ]] && apply_preferences
    [[ "$DO_CLEAR_DOCK" == "true" ]] && clear_dock
    [[ "$DO_TERMINAL_THEME" == "true" ]] && install_terminal_theme
    [[ "$DO_LATEX" == "true" ]] && install_latex
    [[ "$DO_STOW" == "true" ]] && setup_stow
    [[ "$DO_PLUGINS" == "true" ]] && setup_plugins
    [[ "$DO_DEFAULT_APPS" == "true" ]] && setup_default_apps
    [[ "$DO_GIT_IDENTITY" == "true" ]] && setup_git_identity
    [[ "$DO_SHELL_LOCAL" == "true" ]] && setup_shell_local
    [[ "$DO_SSH_KEYS" == "true" ]] && setup_ssh_keys

    # Mark as successful - cleanup handler will display success message
    BOOTSTRAP_SUCCESS=true
}

main "$@"
