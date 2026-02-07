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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared library for common functions
source "$SCRIPT_DIR/lib.sh"

# --- Parse arguments ---
MODE="interactive"
REQUESTED_PACKAGES=()
for arg in "$@"; do
    case "$arg" in
        --force) MODE="force" ;;
        --verify) MODE="verify" ;;
        *) REQUESTED_PACKAGES+=("$arg") ;;
    esac
done

# --- Main ---
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
        exit 1
    fi
fi

cd "$DOTFILES_DIR"

# --- Get packages to process ---
packages=()
if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
    for pkg in "${REQUESTED_PACKAGES[@]}"; do
        if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
            packages+=("$pkg")
        else
            print_warn "Package not found: $pkg"
        fi
    done
else
    for dir in */; do
        [[ "$dir" == "Bootstrap/" ]] && continue
        packages+=("${dir%/}")
    done
fi

if [[ ${#packages[@]} -eq 0 ]]; then
    print_warn "No packages found to stow."
    exit 0
fi

echo "Packages: ${packages[*]}"
echo ""

# --- Verify mode: just check status ---
if [[ "$MODE" == "verify" ]]; then
    print_info "Verifying symlinks..."
    # Try a dry-run stow to check for issues
    if stow --no --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>&1 | grep -q "existing target"; then
        print_warn "Some symlinks need attention."
        stow --no --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>&1 || true
        exit 1
    else
        print_ok "All symlinks are correct!"
        exit 0
    fi
fi

# --- Interactive mode: ask before adopting ---
if [[ "$MODE" == "interactive" ]]; then
    echo "This will:"
    echo "  1. Create symlinks from ~/ to your dotfiles"
    echo "  2. If conflicts exist, adopt them into the repo"
    echo "  3. Reset any adopted files that differ from the repo"
    echo ""
    if ! ask_yes_no "Proceed?" "y"; then
        echo "Cancelled."
        exit 0
    fi
    echo ""
fi

# --- Stow with --adopt to handle conflicts ---
print_info "Stowing packages..."

# Use --adopt to move conflicting files into the repo
# This allows stow to create symlinks even when files already exist
if ! stow --adopt --restow --target="$HOME" --ignore='\.DS_Store' "${packages[@]}" 2>&1; then
    print_error "Stow failed"
    exit 1
fi

# --- Check if any files were adopted that differ from repo ---
if ! git diff --quiet 2>/dev/null; then
    echo ""
    print_warn "Some files were adopted into the repo and differ from the original:"
    echo ""
    git diff --name-only
    echo ""

    if [[ "$MODE" == "force" ]]; then
        print_info "Force mode: resetting adopted files to repo versions..."
        git checkout .
        # Re-stow after reset to ensure symlinks are correct
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

echo ""
print_ok "Done."
