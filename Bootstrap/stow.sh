#!/usr/bin/env bash
#
# Symlink dotfiles to home directory using GNU Stow
#
# Usage:
#   ./stow.sh              # Interactive mode - stow all packages
#   ./stow.sh --force      # Non-interactive - stow everything, adopt conflicts
#   ./stow.sh --verify     # Only verify, don't make changes
#   ./stow.sh Vim Git      # Stow only specified packages
#

set -euo pipefail

# --- Script setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared library for common functions
source "$SCRIPT_DIR/lib.sh"

# --- Global state ---
MODE="interactive"
REQUESTED_PACKAGES=()
PACKAGES=()

# --- Functions ---

# Parse command line arguments
# Sets: MODE, REQUESTED_PACKAGES
parse_args() {
    MODE="interactive"
    REQUESTED_PACKAGES=()
    for arg in "$@"; do
        case "$arg" in
            --force) MODE="force" ;;
            --verify) MODE="verify" ;;
            *) REQUESTED_PACKAGES+=("$arg") ;;
        esac
    done
}

# Get list of packages to stow
# Populates the global PACKAGES array
get_packages() {
    PACKAGES=()
    if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
        for pkg in "${REQUESTED_PACKAGES[@]}"; do
            if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
                PACKAGES+=("$pkg")
            else
                print_warn "Package not found: $pkg"
            fi
        done
    else
        for dir in */; do
            # Skip non-stow directories
            [[ "$dir" == "Bootstrap/" ]] && continue
            [[ "$dir" == "macOS/" ]] && continue  # macOS-specific (apps, not symlinks)
            PACKAGES+=("${dir%/}")
        done
    fi
}

# Verify symlinks without making changes
# Arguments: packages array
# Returns: 0 if all OK, 1 if issues found
verify_symlinks() {
    local -a packages=("$@")
    print_info "Verifying symlinks..."
    if stow --no --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>&1 | grep -q "existing target"; then
        print_warn "Some symlinks need attention."
        stow --no --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>&1 || true
        return 1
    else
        print_ok "All symlinks are correct!"
        return 0
    fi
}

# Handle adopted files that differ from repo
# Arguments: packages array
handle_adopted_files() {
    local -a packages=("$@")
    if ! git diff --quiet 2>/dev/null; then
        echo ""
        print_warn "Some files were adopted into the repo and differ from the original:"
        echo ""
        git diff --name-only
        echo ""

        if [[ "$MODE" == "force" ]]; then
            print_info "Force mode: resetting adopted files to repo versions..."
            git checkout .
            stow --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>/dev/null || true
            print_ok "Adopted files reset to repo versions."
        else
            echo "Options:"
            echo "  1) Reset to repo versions (discard adopted files)"
            echo "  2) Keep adopted files (review with 'git diff')"
            echo ""
            if ask_yes_no "Reset adopted files to repo versions?" "y"; then
                git checkout .
                stow --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>/dev/null || true
                print_ok "Adopted files reset to repo versions."
            else
                print_warn "Keeping adopted files. Review changes with 'git diff'."
            fi
        fi
    else
        print_ok "All symlinks created successfully!"
    fi
}

# --- Main ---
main() {
    parse_args "$@"

    echo ""
    echo -e "${BOLD}Dotfiles Stow Manager${NC}"
    echo "Directory: $DOTFILES_DIR"
    echo ""

    # Ensure stow is installed
    if ! command -v stow >/dev/null 2>&1; then
        print_info "stow is not installed. Installing..."
        if pkg_install stow; then
            print_ok "stow installed successfully"
        else
            print_error "Failed to install stow"
            exit "$E_MISSING_DEP"
        fi
    fi

    cd "$DOTFILES_DIR"

    # Get packages to process (populates PACKAGES array)
    get_packages

    if [[ ${#PACKAGES[@]} -eq 0 ]]; then
        print_warn "No packages found to stow."
        exit "$E_SUCCESS"
    fi

    echo "Packages: ${PACKAGES[*]}"
    echo ""

    # Verify mode: just check status
    if [[ "$MODE" == "verify" ]]; then
        if verify_symlinks "${PACKAGES[@]}"; then
            exit "$E_SUCCESS"
        else
            exit "$E_GENERAL"
        fi
    fi

    # Interactive mode: ask before adopting
    if [[ "$MODE" == "interactive" ]]; then
        echo "This will:"
        echo "  1. Create symlinks from ~/ to your dotfiles"
        echo "  2. If conflicts exist, adopt them into the repo"
        echo "  3. Reset any adopted files that differ from the repo"
        echo ""
        if ! ask_yes_no "Proceed?" "y"; then
            echo "Cancelled."
            exit "$E_USER_ABORT"
        fi
        echo ""
    fi

    # Stow with --adopt to handle conflicts
    print_info "Stowing packages..."
    if ! stow --adopt --restow --target="$HOME" --ignore='\.DS_Store' "${PACKAGES[@]}" 2>&1; then
        print_error "Stow failed"
        exit "$E_GENERAL"
    fi

    # Check if any files were adopted that differ from repo
    handle_adopted_files "${PACKAGES[@]}"

    echo ""
    print_ok "Done."
}

# Only run if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
