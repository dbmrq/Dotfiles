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

# Check if two files are identical (works for files and directories)
files_identical() {
    local file1="$1" file2="$2"
    if [[ -f "$file1" && -f "$file2" ]]; then
        diff -q "$file1" "$file2" >/dev/null 2>&1
    elif [[ -d "$file1" && -d "$file2" ]]; then
        diff -rq "$file1" "$file2" >/dev/null 2>&1
    else
        return 1
    fi
}

# Check if all conflicting files in a package are identical to repo versions
# Returns 0 if all identical, 1 if any differ
check_conflicts_identical() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"

    while IFS= read -r -d '' file; do
        local rel_path="${file#$pkg_dir/}"
        local home_file="$HOME/$rel_path"

        # Only check actual conflicts (regular files, not symlinks)
        if [[ -f "$home_file" && ! -L "$home_file" ]]; then
            if ! files_identical "$file" "$home_file"; then
                return 1  # Found a difference
            fi
        elif [[ -d "$home_file" && ! -L "$home_file" ]]; then
            if ! files_identical "$file" "$home_file"; then
                return 1
            fi
        fi
    done < <(find "$pkg_dir" -type f ! -name '.DS_Store' ! -name '.stow-local-ignore' -print0 2>/dev/null)

    return 0  # All identical
}

# Remove conflicting files that match repo (so stow can create symlinks)
remove_identical_conflicts() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"

    # First collect all files to remove (to handle directories properly)
    local files_to_remove=()
    local dirs_to_remove=()

    while IFS= read -r -d '' file; do
        local rel_path="${file#$pkg_dir/}"
        local home_file="$HOME/$rel_path"

        if [[ -f "$home_file" && ! -L "$home_file" ]]; then
            files_to_remove+=("$home_file")
        fi
    done < <(find "$pkg_dir" -type f ! -name '.DS_Store' ! -name '.stow-local-ignore' -print0 2>/dev/null)

    # Also check top-level directories
    while IFS= read -r -d '' dir; do
        local rel_path="${dir#$pkg_dir/}"
        local home_dir="$HOME/$rel_path"

        if [[ -d "$home_dir" && ! -L "$home_dir" ]]; then
            dirs_to_remove+=("$home_dir")
        fi
    done < <(find "$pkg_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.git' -print0 2>/dev/null)

    # Remove files
    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        for f in "${files_to_remove[@]}"; do
            rm -f "$f"
        done
    fi

    # Remove now-empty directories
    if [[ ${#dirs_to_remove[@]} -gt 0 ]]; then
        for d in "${dirs_to_remove[@]}"; do
            rm -rf "$d" 2>/dev/null || true
        done
    fi
}

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
                conflict:*) ((conflicts++)) ;;
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
    # Check conflicts - separate into identical (auto-fixable) and different
    identical_conflicts=()
    different_conflicts=()

    for pkg in "${has_conflicts[@]}"; do
        if check_conflicts_identical "$pkg"; then
            identical_conflicts+=("$pkg")
        else
            different_conflicts+=("$pkg")
        fi
    done

    # Auto-fix identical conflicts
    if [[ ${#identical_conflicts[@]} -gt 0 ]]; then
        echo -e "${GREEN}Auto-fixing conflicts (files identical to repo):${NC}"
        for pkg in "${identical_conflicts[@]}"; do
            echo "  • $pkg"
        done
        echo ""
        print_info "Removing duplicates and creating symlinks..."
        for pkg in "${identical_conflicts[@]}"; do
            remove_identical_conflicts "$pkg"
        done
        # Add these to the stow list
        needs_stow+=("${identical_conflicts[@]}")
    fi

    # Show remaining conflicts that need manual attention
    if [[ ${#different_conflicts[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Conflicts found (files differ from repo):${NC}"
        echo "  These packages have existing files that differ from the repo:"
        for pkg in "${different_conflicts[@]}"; do
            echo "    • $pkg"
        done
        echo ""
        echo "  Options:"
        echo "    1) Back up conflicting files and remove them, then re-run"
        echo "    2) Use --adopt to move existing files into dotfiles repo:"
        echo "       stow --adopt --restow -v --target=\"\$HOME\" ${different_conflicts[*]}"
        echo ""
    fi

    if [[ ${#needs_stow[@]} -gt 0 ]] || [[ ${#different_conflicts[@]} -gt 0 ]]; then
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

            if [[ ${#different_conflicts[@]} -gt 0 ]]; then
                echo ""
                echo "Packages with conflicts: ${different_conflicts[*]}"
                if ask_yes_no "Adopt existing files into dotfiles repo?" "n"; then
                    stow --adopt --restow -v --target="$HOME" --ignore='\.DS_Store' "${different_conflicts[@]}"
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

        # Ensure vim-plug is installed for Vim
        vim_plug="$HOME/.vim/autoload/plug.vim"
        if [[ ! -f "$vim_plug" ]]; then
            echo "  Installing vim-plug for Vim..."
            curl -fLo "$vim_plug" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        fi

        # Ensure vim-plug is installed for Neovim
        nvim_plug="$HOME/.local/share/nvim/site/autoload/plug.vim"
        if [[ ! -f "$nvim_plug" ]]; then
            echo "  Installing vim-plug for Neovim..."
            curl -fLo "$nvim_plug" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        fi

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
