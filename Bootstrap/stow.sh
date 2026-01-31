#!/usr/bin/env bash
#
# Symlink dotfiles to home directory using GNU Stow
# Can be run standalone or called from bootstrap.sh
#
# Usage:
#   ./stow.sh                    # Interactive mode - stow all packages
#   ./stow.sh Vim Git            # Stow only specified packages
#   ./stow.sh --force            # Non-interactive - stow everything
#   ./stow.sh --verify           # Only verify, don't make changes
#   ./stow.sh --verify Vim       # Verify only specified packages
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared library for common functions
source "$SCRIPT_DIR/lib.sh"

# Parse arguments - separate flags from package names
MODE="interactive"
REQUESTED_PACKAGES=()
for arg in "$@"; do
    case "$arg" in
        --force) MODE="force" ;;
        --verify) MODE="verify" ;;
        *) REQUESTED_PACKAGES+=("$arg") ;;
    esac
done

# Pre-normalize DOTFILES_DIR for Unicode comparisons (macOS uses NFD, scripts use NFC)
DOTFILES_DIR_NORMALIZED="$(python3 -c "import unicodedata,sys; print(unicodedata.normalize('NFC',sys.argv[1]),end='')" "$DOTFILES_DIR" 2>/dev/null || printf '%s' "$DOTFILES_DIR")"

# Alias for backward compatibility (print_err -> print_error)
print_err() { print_error "$1"; }

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

# Normalize Unicode path to NFC (for comparing paths from different sources)
# macOS filesystem returns NFD, script strings are NFC
normalize_unicode() {
    python3 -c "import unicodedata,sys; print(unicodedata.normalize('NFC',sys.argv[1]),end='')" "$1" 2>/dev/null || printf '%s' "$1"
}

# Cache of HOME paths that are symlinks to dotfiles (computed once)
declare -a DOTFILES_SYMLINKS=()

# Build cache of symlinks in $HOME that point to dotfiles
_build_symlink_cache() {
    local link target
    for link in "$HOME"/.*; do
        if [[ -L "$link" ]]; then
            target="$(readlink "$link")"
            if [[ "$target" == *"Dotfiles"* ]]; then
                DOTFILES_SYMLINKS+=("$link")
            fi
        fi
    done
}

# Check if a path resolves to inside the dotfiles directory
# (to avoid deleting repo files through symlinks)
is_inside_dotfiles() {
    local path="$1"

    # Build cache on first call (use special marker to indicate cache is built)
    if [[ -z "${SYMLINKS_CACHE_BUILT:-}" ]]; then
        _build_symlink_cache
        SYMLINKS_CACHE_BUILT=true
    fi

    # Fast path: check if path starts with any cached symlink
    if [[ ${#DOTFILES_SYMLINKS[@]} -gt 0 ]]; then
        local symlink
        for symlink in "${DOTFILES_SYMLINKS[@]}"; do
            if [[ "$path" == "$symlink" || "$path" == "$symlink/"* ]]; then
                return 0
            fi
        done
    fi

    # Slower path: resolve full path and compare with Unicode normalization
    local real_path
    real_path="$(normalize_unicode "$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")")"

    # Use pre-computed normalized DOTFILES_DIR
    [[ "$real_path" == "$DOTFILES_DIR_NORMALIZED/"* ]]
}

# Check if all conflicting files in a package are identical to repo versions
# Returns 0 if all identical (or already linked to repo), 1 if any differ
check_conflicts_identical() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"

    while IFS= read -r -d '' file; do
        local rel_path="${file#$pkg_dir/}"
        local home_file="$HOME/$rel_path"

        # Skip if it resolves to inside dotfiles (already properly linked)
        if is_inside_dotfiles "$home_file" 2>/dev/null; then
            continue
        fi

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

        # Only remove if it's a regular file, not a symlink, and NOT inside dotfiles
        if [[ -f "$home_file" && ! -L "$home_file" ]]; then
            if ! is_inside_dotfiles "$home_file"; then
                files_to_remove+=("$home_file")
            fi
        fi
    done < <(find "$pkg_dir" -type f ! -name '.DS_Store' ! -name '.stow-local-ignore' -print0 2>/dev/null)

    # Also check top-level directories
    while IFS= read -r -d '' dir; do
        local rel_path="${dir#$pkg_dir/}"
        local home_dir="$HOME/$rel_path"

        # Only remove if it's a regular directory, not a symlink, and NOT inside dotfiles
        if [[ -d "$home_dir" && ! -L "$home_dir" ]]; then
            if ! is_inside_dotfiles "$home_dir"; then
                dirs_to_remove+=("$home_dir")
            fi
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

# --- Verify a single symlink ---
# Returns: 0=correct, 1=missing, 2=wrong target, 3=is regular file
verify_symlink() {
    local expected_target="$1"
    local link_path="$2"

    if [[ ! -e "$link_path" ]] && [[ ! -L "$link_path" ]]; then
        return 1  # Missing
    elif [[ -L "$link_path" ]]; then
        # Symlink exists - check if it points to the right place
        # (handles both relative and absolute symlinks, with Unicode normalization)
        local actual_dest expected_dest
        actual_dest="$(normalize_unicode "$(cd "$(dirname "$link_path")" && cd "$(dirname "$(readlink "$link_path")")" 2>/dev/null && pwd -P)/$(basename "$(readlink "$link_path")")")"
        expected_dest="$(normalize_unicode "$(cd "$(dirname "$expected_target")" 2>/dev/null && pwd -P)/$(basename "$expected_target")")"
        if [[ "$actual_dest" == "$expected_dest" ]]; then
            return 0  # Correct
        else
            return 2  # Wrong target
        fi
    elif is_inside_dotfiles "$link_path"; then
        # File exists and resolves to inside dotfiles (via parent symlink)
        return 0  # Correct (linked through parent directory)
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
    print_info "stow is not installed. Installing..."
    if pkg_install stow; then
        print_ok "stow installed successfully"
    else
        print_err "Failed to install stow"
        exit 1
    fi
fi

cd "$DOTFILES_DIR"

# Get packages to process
packages=()
if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
    # Use only requested packages (validate they exist)
    for pkg in "${REQUESTED_PACKAGES[@]}"; do
        if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
            packages+=("$pkg")
        else
            print_warn "Package not found: $pkg"
        fi
    done
else
    # Use all packages
    for dir in */; do
        [[ "$dir" == "Bootstrap/" ]] && continue
        packages+=("${dir%/}")
    done
fi

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
if [[ "$MODE" == "verify" ]]; then
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

    if [[ ${#has_conflicts[@]} -gt 0 ]]; then
        for pkg in "${has_conflicts[@]}"; do
            if check_conflicts_identical "$pkg"; then
                identical_conflicts+=("$pkg")
            else
                different_conflicts+=("$pkg")
            fi
        done
    fi

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
        if [[ "$MODE" == "force" ]]; then
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

echo ""
print_ok "Done."
