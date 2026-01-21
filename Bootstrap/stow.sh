#!/usr/bin/env bash
#
# Symlink dotfiles to home directory using GNU Stow
# Can be run standalone or called from bootstrap.sh
#
# Usage:
#   ./stow.sh           # Interactive mode - verify and ask before changes
#   ./stow.sh --force   # Non-interactive - stow everything, fix conflicts
#   ./stow.sh --verify  # Only verify, don't make changes
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
MODE="${1:-interactive}"  # interactive, --force, or --verify

# --- Colors ---
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

print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}!${NC} $1"; }
print_err() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }

ask_yes_no() {
    local prompt="$1" default="${2:-n}" reply
    [[ "$default" =~ ^[Yy]$ ]] && prompt="$prompt [Y/n] " || prompt="$prompt [y/N] "
    read -r -p "$prompt" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

# --- Verify a single symlink ---
# Returns: 0=correct, 1=missing, 2=wrong target, 3=is regular file
verify_symlink() {
    local expected_target="$1"
    local link_path="$2"

    if [[ ! -e "$link_path" ]] && [[ ! -L "$link_path" ]]; then
        return 1  # Missing
    elif [[ -L "$link_path" ]]; then
        local actual_target
        actual_target="$(readlink "$link_path")"
        if [[ "$actual_target" == "$expected_target" ]]; then
            return 0  # Correct
        else
            return 2  # Wrong target
        fi
    else
        return 3  # Regular file (conflict)
    fi
}

# --- Check all symlinks for a package ---
check_package() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"
    local issues=()
    local ok_count=0

    # Find all files in the package (excluding .DS_Store)
    while IFS= read -r -d '' file; do
        local rel_path="${file#$pkg_dir/}"
        local target="$DOTFILES_DIR/$pkg/$rel_path"
        local link="$HOME/$rel_path"

        verify_symlink "$target" "$link"
        local status=$?

        case $status in
            0) ((ok_count++)) ;;
            1) issues+=("missing:$rel_path") ;;
            2) issues+=("wrong:$rel_path") ;;
            3) issues+=("conflict:$rel_path") ;;
        esac
    done < <(find "$pkg_dir" -type f ! -name '.DS_Store' ! -name '.stow-local-ignore' -print0 2>/dev/null)

    # Also check directories that need to be symlinked (like .vim/bundle/*)
    while IFS= read -r -d '' dir; do
        local rel_path="${dir#$pkg_dir/}"
        local target="$DOTFILES_DIR/$pkg/$rel_path"
        local link="$HOME/$rel_path"

        # Only check if parent exists and this should be a symlink
        if [[ -L "$link" ]]; then
            verify_symlink "$target" "$link"
            local status=$?
            case $status in
                0) ((ok_count++)) ;;
                2) issues+=("wrong:$rel_path") ;;
            esac
        fi
    done < <(find "$pkg_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.git' -print0 2>/dev/null)

    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "ok:$ok_count"
    else
        printf '%s\n' "${issues[@]}"
    fi
}

# --- Main ---
echo ""
echo -e "${BOLD}Dotfiles Stow Manager${NC}"
echo "Directory: $DOTFILES_DIR"
echo ""

if ! command -v stow >/dev/null 2>&1; then
    print_err "stow is not installed. Run: brew install stow"
    exit 1
fi

cd "$DOTFILES_DIR"

# Get all packages
packages=()
for dir in */; do
    [[ "$dir" == "Bootstrap/" ]] && continue
    packages+=("${dir%/}")
done

if [[ ${#packages[@]} -eq 0 ]]; then
    print_warn "No packages found to stow."
    exit 0
fi

# --- Verification phase ---
echo -e "${BOLD}Checking symlinks...${NC}"
echo ""

needs_stow=()
has_conflicts=()
all_ok=true

for pkg in "${packages[@]}"; do
    result=$(check_package "$pkg")

    if [[ "$result" == ok:* ]]; then
        count="${result#ok:}"
        print_ok "$pkg ($count files linked)"
    else
        all_ok=false
        missing=0 wrong=0 conflicts=0

        while IFS= read -r issue; do
            case "$issue" in
                missing:*) ((missing++)) ;;
                wrong:*) ((wrong++)) ;;
                conflict:*)
                    ((conflicts++))
                    conflict_file="${issue#conflict:}"
                    ;;
            esac
        done <<< "$result"

        if [[ $conflicts -gt 0 ]]; then
            print_err "$pkg: $conflicts conflict(s), $missing missing, $wrong wrong"
            has_conflicts+=("$pkg")
        elif [[ $missing -gt 0 ]] || [[ $wrong -gt 0 ]]; then
            print_warn "$pkg: $missing missing, $wrong wrong"
            needs_stow+=("$pkg")
        fi
    fi
done

echo ""

# --- Handle results based on mode ---
if [[ "$MODE" == "--verify" ]]; then
    if $all_ok; then
        print_ok "All symlinks are correct!"
        exit 0
    else
        print_warn "Some symlinks need attention."
        exit 1
    fi
fi

if $all_ok; then
    print_ok "All symlinks are already correct!"
else
    # Show what needs to be done
    if [[ ${#has_conflicts[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Conflicts found:${NC}"
        echo "  These packages have existing files that would be overwritten:"
        for pkg in "${has_conflicts[@]}"; do
            echo "    • $pkg"
        done
        echo ""
        echo "  Options:"
        echo "    1) Back up conflicting files and remove them, then re-run"
        echo "    2) Use --adopt to move existing files into dotfiles repo:"
        echo "       stow --adopt --restow -v --target=\"\$HOME\" ${has_conflicts[*]}"
        echo ""
    fi

    if [[ ${#needs_stow[@]} -gt 0 ]] || [[ ${#has_conflicts[@]} -gt 0 ]]; then
        if [[ "$MODE" == "--force" ]]; then
            print_info "Force mode: stowing all packages..."
            stow --restow -v --target="$HOME" --ignore='\.DS_Store' "${packages[@]}"
        else
            # Interactive mode
            if [[ ${#needs_stow[@]} -gt 0 ]]; then
                echo "Packages needing symlinks: ${needs_stow[*]}"
                if ask_yes_no "Stow these packages?" "y"; then
                    stow --restow -v --target="$HOME" --ignore='\.DS_Store' "${needs_stow[@]}"
                    print_ok "Packages stowed."
                fi
            fi

            if [[ ${#has_conflicts[@]} -gt 0 ]]; then
                echo ""
                echo "Packages with conflicts: ${has_conflicts[*]}"
                if ask_yes_no "Adopt existing files into dotfiles repo?" "n"; then
                    stow --adopt --restow -v --target="$HOME" --ignore='\.DS_Store' "${has_conflicts[@]}"
                    print_ok "Files adopted and packages stowed."
                    print_warn "Check 'git diff' to review adopted files."
                fi
            fi
        fi
    fi
fi

# --- Update Vim/Neovim plugins ---
echo ""
if [[ "$MODE" == "--verify" ]]; then
    echo "Skipping plugin update in verify mode."
else
    if [[ "$MODE" == "--force" ]]; then
        update_plugins=true
    else
        update_plugins=false
        if ask_yes_no "Update Vim/Neovim plugins?" "y"; then
            update_plugins=true
        fi
    fi

    if $update_plugins; then
        echo "Updating editor plugins..."
        if command -v vim >/dev/null 2>&1; then
            print_info "Updating Vim plugins..."
            vim +PlugUpdate +qall 2>/dev/null || true
        fi
        if command -v nvim >/dev/null 2>&1; then
            print_info "Updating Neovim plugins..."
            nvim --headless +PlugUpdate +qall 2>/dev/null || true
        fi
    fi
fi

echo ""
print_ok "Done."
