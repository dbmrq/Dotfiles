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
# Safety: --adopt copies conflicting $HOME files into the repo, so this script
# refuses to run while the repo has uncommitted changes. --force aborts with an
# error; interactive mode asks first with a non-destructive default (abort).
# Any restore after adoption is scoped to files stow actually adopted, so
# unrelated working-tree edits are never reset.
#

set -euo pipefail

# --- Script setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Allow DOTFILES_DIR to be overridden (e.g. for tests against a throwaway repo);
# lib.sh preserves an existing value, and the default stays the repo root.
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"

# Source shared library for common functions
source "$SCRIPT_DIR/lib.sh"

# --- Global state ---
MODE="interactive"
REQUESTED_PACKAGES=()
PACKAGES=()
# Tracked files that were already modified before stow --adopt ran. These are
# pre-existing user changes and are never reset by handle_adopted_files.
PRE_ADOPT_DIRTY=()

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
        local os
        os=$(uname -s)
        for dir in */; do
            # Skip non-stow directories
            [[ "$dir" == "Bootstrap/" ]] && continue
            [[ "$dir" == "macOS/" ]] && continue  # macOS-specific (apps, not symlinks)
            if [[ "$os" != "Darwin" ]]; then
                [[ "$dir" == "Hammerspoon/" ]] && continue
                [[ "$dir" == "TeX/" ]] && continue
            fi
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

# Return 0 if $1 is present in the remaining arguments
_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Refuse to run stow --adopt when the working tree has uncommitted changes, so
# adoption can never silently discard (or clobber) unrelated user edits.
# Records the pre-existing dirty paths in PRE_ADOPT_DIRTY for later scoping.
# Exits with E_GENERAL in --force mode; interactive mode asks first with a
# non-destructive default (abort).
pre_adopt_safety_check() {
    PRE_ADOPT_DIRTY=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && PRE_ADOPT_DIRTY+=("$f")
    done < <(git diff --name-only HEAD)

    if [[ ${#PRE_ADOPT_DIRTY[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    print_warn "The dotfiles repo has uncommitted changes:"
    echo ""
    git diff --name-only HEAD
    echo ""
    print_warn "stow --adopt would overwrite repo files and could discard these"
    print_warn "changes. Nothing will be reset automatically."

    if [[ "$MODE" == "force" ]]; then
        print_error "Aborting: commit or clean up the changes above, then re-run stow.sh."
        exit "$E_GENERAL"
    fi

    if ask_yes_no "Abort before adopting to preserve these changes?" "y"; then
        print_error "Aborting: resolve the uncommitted changes first."
        exit "$E_USER_ABORT"
    fi
    print_warn "Proceeding anyway; the changes above will be left untouched."
}

# Handle adopted files that differ from repo
# Arguments: packages array
# Restores only the files stow --adopt changed in this run (paths not already
# dirty before adoption), so unrelated pre-existing edits are never reset.
handle_adopted_files() {
    local -a packages=("$@")
    local -a adopted=()
    local f

    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        # Guard with a length check: bash 3.2 + set -u errors on expanding an
        # empty array, so only expand PRE_ADOPT_DIRTY when it has elements.
        if (( ${#PRE_ADOPT_DIRTY[@]} == 0 )) || ! _contains "${PRE_ADOPT_DIRTY[@]}" "$f"; then
            adopted+=("$f")
        fi
    done < <(git diff --name-only HEAD)

    if [[ ${#adopted[@]} -gt 0 ]]; then
        echo ""
        print_warn "Files adopted from \$HOME differ from the repo:"
        echo ""
        printf '%s\n' "${adopted[@]}"
        echo ""

        if [[ "$MODE" == "force" ]]; then
            print_info "Force mode: resetting adopted files to repo versions..."
            git checkout -- "${adopted[@]}"
            stow --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>/dev/null || true
            print_ok "Adopted files reset to repo versions."
        else
            echo "Options:"
            echo "  1) Reset to repo versions (discard adopted files)"
            echo "  2) Keep adopted files (review with 'git diff')"
            echo ""
            if ask_yes_no "Reset adopted files to repo versions?" "y"; then
                git checkout -- "${adopted[@]}"
                stow --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>/dev/null || true
                print_ok "Adopted files reset to repo versions."
            else
                print_warn "Keeping adopted files. Review changes with 'git diff'."
            fi
        fi
    elif [[ ${#PRE_ADOPT_DIRTY[@]} -gt 0 ]]; then
        print_warn "Leaving pre-existing uncommitted changes untouched."
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

    # Pre-create real config directories that Stow would otherwise fold into
    # whole-directory symlinks into the repo (see ensure_managed_config_dirs).
    ensure_managed_config_dirs

    # Refuse to adopt over uncommitted changes so unrelated edits are never
    # silently reset (see pre_adopt_safety_check).
    pre_adopt_safety_check

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
