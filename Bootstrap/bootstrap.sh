#!/usr/bin/env bash
#
# Bootstrap script for setting up a new macOS machine
# - Detects what's already installed and verifies configuration
# - Asks only about things that need to be installed/fixed
# - Saves state so interrupted runs can be resumed
# - Idempotent: safe to run multiple times
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
STATE_FILE="$SCRIPT_DIR/.bootstrap_state"
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

# Selected features for installation (populated by gather_choices)
SELECTED_FEATURES=()

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

    # Handle state file based on success/failure
    if $BOOTSTRAP_SUCCESS; then
        # Success: remove state file
        rm -f "$STATE_FILE" 2>/dev/null || true
        echo ""
        echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}║     Bootstrap Complete!                ║${NC}"
        echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "You may want to:"
        echo "  • Restart your terminal for shell changes to take effect"
        echo "  • Log out and back in for all preferences to apply"
        echo "  • Restart your Mac if system updates were installed"
        echo ""
    elif [[ $exit_code -ne 0 ]]; then
        # Failure: state file is preserved for resume
        echo ""
        print_error "Bootstrap interrupted or failed (exit code: $exit_code)"
        echo ""
        echo "Your progress has been saved. Run the script again to resume."
        echo "To start fresh, delete: $STATE_FILE"
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

    # Xcode CLI tools
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

    # CLI tools
    local cli_status
    cli_status=$(check_cli_tools_status)
    local cli_installed="${cli_status%:*}"
    local cli_missing="${cli_status#*:}"
    if [[ "$cli_missing" -eq 0 ]]; then
        print_success "CLI tools ($cli_installed packages)"
    else
        print_warning "CLI tools: $cli_installed installed, $cli_missing missing"
    fi

    # GUI apps
    local gui_status
    gui_status=$(check_gui_apps_status)
    local gui_installed="${gui_status%:*}"
    local gui_missing="${gui_status#*:}"
    if [[ "$gui_missing" -eq 0 ]]; then
        print_success "GUI applications ($gui_installed apps)"
    else
        print_warning "GUI applications: $gui_installed installed, $gui_missing missing"
    fi

    # Xcode app
    if [[ -d "/Applications/Xcode.app" ]]; then
        print_success "Xcode (App Store)"
    else
        print_warning "Xcode (App Store): not installed"
    fi

    # Prezto
    if [[ "$(check_prezto_status)" == "installed" ]]; then
        print_success "Prezto"
    else
        print_warning "Prezto: not installed"
    fi

    # Dotfiles
    local stow_status
    stow_status=$(check_stow_status)
    if [[ "$stow_status" == "ok" ]]; then
        print_success "Dotfiles symlinks"
    else
        print_warning "Dotfiles: some symlinks need attention"
    fi

    # SSH keys
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

# Mark a step as completed in state file
mark_step_complete() {
    local step="$1"
    echo "$step" >> "$STATE_FILE"
}

# Check if a step was already completed
step_completed() {
    local step="$1"
    [[ -f "$STATE_FILE" ]] && grep -qxF "$step" "$STATE_FILE"
}

# Save choices to state file
save_choices() {
    {
        echo "# Bootstrap choices - $(date)"
        echo "CHOICE_MACOS_UPDATE=$DO_MACOS_UPDATE"
        echo "CHOICE_XCODE_TOOLS=$DO_XCODE_TOOLS"
        echo "CHOICE_HOMEBREW=$DO_HOMEBREW"
        echo "CHOICE_BREW_CLI=$DO_BREW_CLI"
        echo "CHOICE_BREW_APPS=$DO_BREW_APPS"
        echo "CHOICE_XCODE_APP=$DO_XCODE_APP"
        echo "CHOICE_PREFS=$DO_PREFS"
        echo "CHOICE_CLEAR_DOCK=$DO_CLEAR_DOCK"
        echo "CHOICE_PREZTO=$DO_PREZTO"
        echo "CHOICE_TERMINAL_THEME=$DO_TERMINAL_THEME"
        echo "CHOICE_LATEX=$DO_LATEX"
        echo "CHOICE_LATEX_DIR=$LATEX_DIR"
        echo "CHOICE_STOW=$DO_STOW"
        echo "CHOICE_PLUGINS=$DO_PLUGINS"
        echo "CHOICE_SSH_KEYS=$DO_SSH_KEYS"
        echo "CHOICE_SSH_DEFAULT=$DEFAULT_GITHUB_ACCOUNT"
        # Save GitHub accounts array
        echo "CHOICE_GITHUB_ACCOUNT_COUNT=${#GITHUB_ACCOUNTS[@]}"
        for i in "${!GITHUB_ACCOUNTS[@]}"; do
            echo "CHOICE_GITHUB_ACCOUNT_$i=${GITHUB_ACCOUNTS[$i]}"
        done
    } >> "$STATE_FILE"
}

# Load choices from state file
load_choices() {
    if [[ -f "$STATE_FILE" ]]; then
        local account_count=0
        # shellcheck source=/dev/null
        while IFS='=' read -r key value; do
            case "$key" in
                CHOICE_MACOS_UPDATE) DO_MACOS_UPDATE="$value" ;;
                CHOICE_XCODE_TOOLS) DO_XCODE_TOOLS="$value" ;;
                CHOICE_HOMEBREW) DO_HOMEBREW="$value" ;;
                CHOICE_BREW_CLI) DO_BREW_CLI="$value" ;;
                CHOICE_BREW_APPS) DO_BREW_APPS="$value" ;;
                CHOICE_XCODE_APP) DO_XCODE_APP="$value" ;;
                CHOICE_PREFS) DO_PREFS="$value" ;;
                CHOICE_CLEAR_DOCK) DO_CLEAR_DOCK="$value" ;;
                CHOICE_PREZTO) DO_PREZTO="$value" ;;
                CHOICE_TERMINAL_THEME) DO_TERMINAL_THEME="$value" ;;
                CHOICE_LATEX) DO_LATEX="$value" ;;
                CHOICE_LATEX_DIR) LATEX_DIR="$value" ;;
                CHOICE_STOW) DO_STOW="$value" ;;
                CHOICE_PLUGINS) DO_PLUGINS="$value" ;;
                CHOICE_SSH_KEYS) DO_SSH_KEYS="$value" ;;
                CHOICE_SSH_DEFAULT) DEFAULT_GITHUB_ACCOUNT="$value" ;;
                CHOICE_GITHUB_ACCOUNT_COUNT) account_count="$value" ;;
                CHOICE_GITHUB_ACCOUNT_*) GITHUB_ACCOUNTS+=("$value") ;;
            esac
        done < "$STATE_FILE"
        return 0
    fi
    return 1
}

# --- Compatibility checks ---
check_compatibility() {
    print_header "Checking system compatibility"

    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script only runs on macOS"
        exit 1
    fi

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

    echo ""
}

# --- Gather GitHub account configuration ---
gather_github_accounts() {
    echo ""
    echo "  Add GitHub accounts one at a time. For each account, you'll specify:"
    echo "    - A name (e.g., 'personal', 'work')"
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
        read -r -p "  Account name (e.g., personal, work, enterprise): " account_name
        if [[ -z "$account_name" ]]; then
            echo "  Skipping empty account name"
            continue
        fi
        # Normalize to lowercase, no spaces
        account_name=$(echo "$account_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

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

        # Store as "name|username|email|mappings"
        GITHUB_ACCOUNTS+=("$account_name|$github_username|$account_email|$all_mappings")
        ((account_count++))
        print_success "  Added account: $account_name ($github_username)"
    done

    # Ask which is default if we have accounts
    if [[ ${#GITHUB_ACCOUNTS[@]} -gt 0 ]]; then
        echo ""
        echo "  Which account should be the default for other repos?"
        local i=1
        for account in "${GITHUB_ACCOUNTS[@]}"; do
            local name username
            name=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f2)
            echo "    $i) $name ($username)"
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
    DO_PREZTO=false
    DO_TERMINAL_THEME=false
    DO_LATEX=false
    LATEX_DIR=""
    DO_STOW=false
    DO_PLUGINS=false
    DO_SSH_KEYS=false
    GITHUB_ACCOUNTS=()
    SELECTED_CLI_PACKAGES=()
    SELECTED_GUI_APPS=()
    DEFAULT_GITHUB_ACCOUNT=""

    # First, show current system status (this also caches all the checks)
    show_system_status

    # --- Run all status checks UPFRONT (slow operations) ---
    echo "Checking system state..."
    ensure_brew_in_path

    local has_xcode_tools=false
    xcode-select -p >/dev/null 2>&1 && has_xcode_tools=true

    local has_brew=false
    command_exists brew && has_brew=true

    local missing_cli=""
    local cli_missing_count=0
    if $has_brew; then
        local cli_status; cli_status=$(check_cli_tools_status)
        cli_missing_count="${cli_status#*:}"
        [[ "$cli_missing_count" -gt 0 ]] && missing_cli=$(get_missing_cli_tools)
    fi

    local missing_gui=""
    local gui_missing_count=0
    if $has_brew; then
        local gui_status; gui_status=$(check_gui_apps_status)
        gui_missing_count="${gui_status#*:}"
        [[ "$gui_missing_count" -gt 0 ]] && missing_gui=$(get_missing_gui_apps)
    fi

    local has_xcode_app=false
    [[ -d "/Applications/Xcode.app" ]] && has_xcode_app=true

    local prezto_status; prezto_status=$(check_prezto_status)
    local stow_status; stow_status=$(check_stow_status)
    local ssh_count; ssh_count=$(check_ssh_keys_status)

    echo ""

    # --- Force mode: enable everything that's missing ---
    if [[ "$MODE" == "--force" ]]; then
        print_header "Force mode: installing all missing components"
        DO_MACOS_UPDATE=false  # Never force macOS updates
        $has_xcode_tools || DO_XCODE_TOOLS=true
        $has_brew || DO_HOMEBREW=true
        if [[ "$cli_missing_count" -gt 0 ]]; then
            DO_BREW_CLI=true
            DO_HOMEBREW=true
            read -ra SELECTED_CLI_PACKAGES <<< "$(get_all_cli_packages)"
        fi
        if [[ "$gui_missing_count" -gt 0 ]]; then
            DO_BREW_APPS=true
            DO_HOMEBREW=true
            read -ra SELECTED_GUI_APPS <<< "$(get_all_gui_casks) $(get_all_gui_formulas)"
        fi
        $has_xcode_app || DO_XCODE_APP=true
        [[ "$prezto_status" != "installed" ]] && DO_PREZTO=true
        [[ "$stow_status" != "ok" ]] && DO_STOW=true
        # Update plugins if vim/neovim are installed
        (command_exists vim || command_exists nvim) && DO_PLUGINS=true
        save_choices
        show_summary_and_confirm
        return
    fi

    # --- Interactive mode: ask all questions upfront ---
    print_header "Configuration"
    echo "Answer all questions, then the script will run unattended."
    echo ""

    local anything_to_do=false

    # macOS updates - always ask (optional)
    if ask_yes_no "Check for macOS updates?"; then
        DO_MACOS_UPDATE=true
        anything_to_do=true
    fi

    # Xcode CLI tools
    if ! $has_xcode_tools; then
        if ask_yes_no "Install Xcode Command Line Tools? (required for most tasks)" "y"; then
            DO_XCODE_TOOLS=true
            anything_to_do=true
        fi
    fi

    # Homebrew
    if ! $has_brew; then
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
            DO_HOMEBREW=true
            anything_to_do=true
            read -ra SELECTED_CLI_PACKAGES <<< "$(get_all_cli_packages)"
        else
            # Ask about each missing package
            SELECTED_CLI_PACKAGES=()
            for pkg in $missing_cli; do
                if ask_yes_no "  Install $pkg?"; then
                    SELECTED_CLI_PACKAGES+=("$pkg")
                    DO_BREW_CLI=true
                    DO_HOMEBREW=true
                    anything_to_do=true
                fi
            done
        fi
    fi

    # GUI apps - use cached results
    if [[ "$gui_missing_count" -gt 0 ]]; then
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

    # Xcode from App Store
    if ! $has_xcode_app; then
        if ask_yes_no "Install Xcode from App Store?"; then
            DO_XCODE_APP=true
            anything_to_do=true
        fi
    fi

    # macOS preferences - always ask (can be reapplied)
    if ask_yes_no "Apply/reapply macOS preferences?"; then
        DO_PREFS=true
        anything_to_do=true
        if ask_yes_no "  Clear all apps from Dock?"; then
            DO_CLEAR_DOCK=true
        fi
    fi

    # Prezto - use cached result
    if [[ "$prezto_status" != "installed" ]]; then
        if ask_yes_no "Install Prezto (Zsh framework)?" "y"; then
            DO_PREZTO=true
            anything_to_do=true
        fi
    fi

    # Terminal theme - always ask (can be reinstalled)
    if ask_yes_no "Install/reinstall Solarized terminal theme?"; then
        DO_TERMINAL_THEME=true
        anything_to_do=true
    fi

    # LaTeX - always ask
    if ask_yes_no "Set up LaTeX packages?"; then
        DO_LATEX=true
        anything_to_do=true
        read -r -p "  Directory for TeX supporting files: " LATEX_DIR
        LATEX_DIR="${LATEX_DIR/#\~/$HOME}"
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

    # Save choices for potential resume
    save_choices

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
    $DO_BREW_CLI && echo "  • CLI tools via Homebrew"
    $DO_BREW_APPS && echo "  • GUI apps via Homebrew"
    $DO_XCODE_APP && echo "  • Xcode from App Store"
    $DO_PREFS && echo "  • macOS preferences"
    $DO_CLEAR_DOCK && echo "  • Clear Dock"
    $DO_PREZTO && echo "  • Prezto"
    $DO_TERMINAL_THEME && echo "  • Terminal color scheme"
    $DO_LATEX && echo "  • LaTeX packages${LATEX_DIR:+ (to: $LATEX_DIR)}"
    $DO_STOW && echo "  • Dotfiles symlinks"
    if $DO_SSH_KEYS && [[ ${#GITHUB_ACCOUNTS[@]} -gt 0 ]]; then
        echo "  • GitHub accounts:"
        for i in "${!GITHUB_ACCOUNTS[@]}"; do
            local account="${GITHUB_ACCOUNTS[$i]}"
            local name username
            name=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f2)
            if [[ "$i" -eq "${DEFAULT_GITHUB_ACCOUNT:-0}" ]]; then
                echo "      - $name ($username) [default]"
            else
                echo "      - $name ($username)"
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
        rm -f "$STATE_FILE"
        echo "Aborted."
        exit 0
    fi
}

# Check for and handle resuming a previous run
check_resume() {
    if [[ -f "$STATE_FILE" ]]; then
        echo ""
        print_warning "A previous bootstrap run was interrupted."
        echo ""

        # Show what was completed
        local completed_steps
        completed_steps=$(grep -v '^#' "$STATE_FILE" | grep -v '^CHOICE_' | grep -v '^$' || true)
        if [[ -n "$completed_steps" ]]; then
            echo "Completed steps:"
            echo "$completed_steps" | while read -r step; do
                echo "  ✓ $step"
            done
            echo ""
        fi

        echo "Options:"
        echo "  1) Resume from where you left off (recommended)"
        echo "  2) Start fresh (discard previous progress)"
        echo "  3) Cancel"
        echo ""
        read -r -p "Choose [1/2/3]: " choice

        case "$choice" in
            1)
                if load_choices; then
                    print_success "Resuming previous run..."
                    return 0  # Resume
                else
                    print_warning "Could not load previous choices. Starting fresh."
                    rm -f "$STATE_FILE"
                    return 1  # Fresh start
                fi
                ;;
            2)
                rm -f "$STATE_FILE"
                return 1  # Fresh start
                ;;
            *)
                echo "Cancelled."
                exit 0
                ;;
        esac
    fi
    return 1  # No state file, fresh start
}

# --- Installation steps ---
# Each step:
# - Checks if already completed (for resume)
# - Is idempotent (safe to run multiple times)
# - Marks itself complete on success

run_step() {
    local step_name="$1"
    local step_func="$2"

    # In dry-run mode, don't check/mark completion
    if ! $DRY_RUN && step_completed "$step_name"; then
        print_success "$step_name (already completed)"
        return 0
    fi

    if $step_func; then
        # Don't mark complete in dry-run mode
        if ! $DRY_RUN; then
            mark_step_complete "$step_name"
        fi
        return 0
    else
        return 1
    fi
}

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

    ensure_brew_in_path
    if ! command_exists brew && ! $DRY_RUN; then
        print_warning "Homebrew not available, skipping CLI tools"
        return 1
    fi

    # Use selected packages if set, otherwise get from JSON
    local packages
    if [[ ${#SELECTED_CLI_PACKAGES[@]} -gt 0 ]]; then
        packages=("${SELECTED_CLI_PACKAGES[@]}")
    else
        # Read from JSON
        read -ra packages <<< "$(get_all_cli_packages)"
    fi

    for pkg in "${packages[@]}"; do
        if ! $DRY_RUN && brew list "$pkg" >/dev/null 2>&1; then
            echo "  $pkg already installed"
        else
            echo "  Installing $pkg..."
            run_cmd brew install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done

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

install_prezto() {
    print_header "Installing Prezto"

    local prezto_dir="${ZDOTDIR:-$HOME}/.zprezto"

    if [[ -d "$prezto_dir" ]]; then
        print_success "Prezto already installed"
        return 0
    fi

    run_cmd git clone --recursive https://github.com/sorin-ionescu/prezto.git "$prezto_dir"
    print_success "Prezto installed"
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
    print_header "Installing LaTeX packages"

    # Ensure tlmgr is available
    if ! command_exists tlmgr; then
        # BasicTeX installs here
        export PATH="/Library/TeX/texbin:$PATH"
    fi

    if ! command_exists tlmgr && ! $DRY_RUN; then
        print_warning "tlmgr not found. Install BasicTeX first."
        return 0  # Not a fatal error
    fi

    echo "Updating TeX Live..."
    run_sudo tlmgr update --self --all || true

    echo "Installing TeX packages..."
    run_sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
        collection-langother collection-latexextra collection-pictures logreq \
        biblatex biber || print_warning "Some packages may have failed"

    # Set up directories (idempotent - mkdir -p and ln -sf are safe to repeat)
    if [[ -n "${LATEX_DIR:-}" ]]; then
        run_cmd mkdir -p "${LATEX_DIR}/Classes"
        run_cmd mkdir -p "${LATEX_DIR}/Packages"
        run_cmd mkdir -p "${LATEX_DIR}/Bibliography"
        run_cmd mkdir -p ~/Library/texmf/tex/latex
        run_cmd mkdir -p ~/Library/texmf/bibtex

        # Clone repositories (only if not exists)
        if [[ ! -d "${LATEX_DIR}/Classes/dbmrq" ]] || $DRY_RUN; then
            run_cmd git clone https://github.com/dbmrq/tex-dbmrq.git "${LATEX_DIR}/Classes/dbmrq"
        else
            echo "  dbmrq already cloned"
        fi
        if [[ ! -d "${LATEX_DIR}/Packages/biblatex-abnt" ]] || $DRY_RUN; then
            run_cmd git clone https://github.com/abntex/biblatex-abnt.git "${LATEX_DIR}/Packages/biblatex-abnt"
        else
            echo "  biblatex-abnt already cloned"
        fi

        # Create symlinks (idempotent with -sf)
        run_cmd ln -sf "${LATEX_DIR}/Classes" ~/Library/texmf/tex/latex/classes
        run_cmd ln -sf "${LATEX_DIR}/Packages" ~/Library/texmf/tex/latex/packages
        run_cmd ln -sf "${LATEX_DIR}/Bibliography" ~/Library/texmf/bibtex/bib
    fi

    print_success "LaTeX setup complete"
}

setup_stow() {
    print_header "Symlinking dotfiles"

    ensure_brew_in_path
    if ! command_exists stow && ! $DRY_RUN; then
        print_warning "stow not installed, skipping dotfiles"
        return 0  # Not a fatal error
    fi

    cd "$DOTFILES_DIR"

    # Get stow packages from selected features
    local packages=()
    if [[ ${#SELECTED_FEATURES[@]} -gt 0 ]]; then
        for feature in "${SELECTED_FEATURES[@]}"; do
            local stow_pkg
            stow_pkg=$(get_stow_package "$feature")
            if [[ -n "$stow_pkg" && -d "$DOTFILES_DIR/$stow_pkg" ]]; then
                packages+=("$stow_pkg")
            fi
        done
    else
        # Fallback: stow all packages if no features selected
        for dir in */; do
            [[ "$dir" == "Bootstrap/" ]] && continue
            packages+=("${dir%/}")
        done
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages found to stow"
        return 0
    fi

    echo "Stowing: ${packages[*]}"

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} $SCRIPT_DIR/stow.sh --force ${packages[*]}"
    else
        # Call the stow.sh script with the selected packages
        "$SCRIPT_DIR/stow.sh" --force "${packages[@]}"
    fi

    print_success "Dotfiles symlinked"
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

setup_ssh_keys() {
    print_header "Setting up GitHub accounts"

    if [[ ${#GITHUB_ACCOUNTS[@]} -eq 0 ]]; then
        print_warning "No GitHub accounts configured, skipping SSH setup"
        return 0
    fi

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} Would configure ${#GITHUB_ACCOUNTS[@]} GitHub account(s)"
        for account in "${GITHUB_ACCOUNTS[@]}"; do
            local name username
            name=$(echo "$account" | cut -d'|' -f1)
            username=$(echo "$account" | cut -d'|' -f2)
            echo -e "  ${BLUE}[dry-run]${NC}   - $name ($username)"
        done
        echo -e "  ${BLUE}[dry-run]${NC} Would create ~/.ssh/config.local"
        echo -e "  ${BLUE}[dry-run]${NC} Would create ~/.gitconfig.local"
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

    # Start building the gitconfig
    local git_config
    git_config="# Machine-specific Git config for GitHub accounts
# Generated by bootstrap script on $(date)
# Do not edit manually - rerun bootstrap to regenerate

"

    # Process each account
    for i in "${!GITHUB_ACCOUNTS[@]}"; do
        local account="${GITHUB_ACCOUNTS[$i]}"
        local name username email mappings
        name=$(echo "$account" | cut -d'|' -f1)
        username=$(echo "$account" | cut -d'|' -f2)
        email=$(echo "$account" | cut -d'|' -f3)
        mappings=$(echo "$account" | cut -d'|' -f4)

        local key_file="$HOME/.ssh/id_ed25519_github_$name"
        local host_alias="github-$name"

        # Generate SSH key if it doesn't exist
        if [[ ! -f "$key_file" ]]; then
            echo "Generating SSH key for $name ($username)..."
            ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N ""
            new_keys+=("$name|$username|$key_file")
        else
            echo "  Key for $name already exists"
        fi

        # Add SSH host alias
        ssh_config+="# --- $name ($username) ---
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
                    git_config+="[url \"git@$host_alias:$mapping/\"]
    insteadOf = git@github.com:$mapping/
    insteadOf = https://github.com/$mapping/

"
                fi
            done
        fi

        # Track the default account
        if [[ "$i" -eq "${DEFAULT_GITHUB_ACCOUNT:-0}" ]]; then
            default_account_name="$name"
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

    # Write the configs
    echo "$ssh_config" > ~/.ssh/config.local
    chmod 600 ~/.ssh/config.local
    print_success "SSH config created (~/.ssh/config.local)"

    echo "$git_config" > ~/.gitconfig.local
    print_success "Git config created (~/.gitconfig.local)"

    # Show public keys for new accounts
    if [[ ${#new_keys[@]} -gt 0 ]]; then
        echo ""
        print_warning "New SSH keys generated! Add these public keys to GitHub:"
        for key_info in "${new_keys[@]}"; do
            local name username key_file
            name=$(echo "$key_info" | cut -d'|' -f1)
            username=$(echo "$key_info" | cut -d'|' -f2)
            key_file=$(echo "$key_info" | cut -d'|' -f3)
            echo ""
            echo "=== $name ($username) - https://github.com/settings/keys ==="
            cat "${key_file}.pub"
        done
        echo ""
    fi

    print_success "GitHub accounts setup complete (default: $default_account_name)"
}

# --- Main execution ---
main() {
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║     macOS Bootstrap Script             ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
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

    # Check for resume or gather new choices
    if check_resume; then
        # Resuming: show what will be done
        show_summary_and_confirm
    else
        # Fresh start: gather choices
        gather_choices
    fi

    # Request sudo upfront and keep it alive (skip in dry-run mode)
    if ! $DRY_RUN; then
        print_header "Requesting administrator access"
        sudo -v
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        SUDO_PID=$!
    else
        print_header "Dry run - skipping sudo"
    fi

    # Run selected installations with step tracking
    # Each step checks if already completed and marks itself done
    if [[ "$DO_MACOS_UPDATE" == "true" ]]; then
        run_step "macOS updates" install_macos_updates
    fi

    if [[ "$DO_XCODE_TOOLS" == "true" ]]; then
        run_step "Xcode Command Line Tools" install_xcode_tools
    fi

    if [[ "$DO_HOMEBREW" == "true" ]]; then
        run_step "Homebrew" install_homebrew
    fi

    if [[ "$DO_BREW_CLI" == "true" ]]; then
        run_step "CLI tools" install_brew_cli
    fi

    if [[ "$DO_BREW_APPS" == "true" ]]; then
        run_step "GUI applications" install_brew_apps
    fi

    if [[ "$DO_XCODE_APP" == "true" ]]; then
        run_step "Xcode from App Store" install_xcode_app
    fi

    if [[ "$DO_PREFS" == "true" ]]; then
        run_step "macOS preferences" apply_preferences
    fi

    if [[ "$DO_CLEAR_DOCK" == "true" ]]; then
        run_step "Clear Dock" clear_dock
    fi

    if [[ "$DO_PREZTO" == "true" ]]; then
        run_step "Prezto" install_prezto
    fi

    if [[ "$DO_TERMINAL_THEME" == "true" ]]; then
        run_step "Terminal color scheme" install_terminal_theme
    fi

    if [[ "$DO_LATEX" == "true" ]]; then
        run_step "LaTeX packages" install_latex
    fi

    if [[ "$DO_STOW" == "true" ]]; then
        run_step "Dotfiles symlinks" setup_stow
    fi

    if [[ "$DO_PLUGINS" == "true" ]]; then
        run_step "Vim/Neovim plugins" setup_plugins
    fi

    if [[ "$DO_SSH_KEYS" == "true" ]]; then
        run_step "SSH keys for GitHub" setup_ssh_keys
    fi

    # Mark as successful - cleanup handler will display success message
    BOOTSTRAP_SUCCESS=true
}

main "$@"
