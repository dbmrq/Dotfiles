#!/usr/bin/env bash
#
# Interactive Homebrew package installer
# Allows selecting which package categories to install
#
# Usage:
#   ./brew.sh              Interactive mode - select categories
#   ./brew.sh --all        Install everything from Brewfile
#   ./brew.sh --list       List available categories
#   ./brew.sh --category cli_essential   Install specific category
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"

# Source shared library
source "$SCRIPT_DIR/lib.sh"

# Check for Homebrew
ensure_brew_in_path
if ! command -v brew >/dev/null 2>&1; then
    print_error "Homebrew is not installed."
    echo "Install it with:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# Parse Brewfile and extract categories
declare -A CATEGORIES
declare -A CATEGORY_NAMES
declare -A CATEGORY_PACKAGES

parse_brewfile() {
    local current_category=""

    while IFS= read -r line; do
        # Check for category comment
        if [[ "$line" =~ ^#[[:space:]]*category:[[:space:]]*(.+)$ ]]; then
            current_category="${BASH_REMATCH[1]}"
            CATEGORIES["$current_category"]=1
        # Check for section header (for display name)
        elif [[ "$line" =~ ^#[[:space:]]*=+$ ]]; then
            continue
        elif [[ "$line" =~ ^#[[:space:]]*([^=].+[^=])[[:space:]]*$ ]] && [[ -n "$current_category" ]]; then
            if [[ -z "${CATEGORY_NAMES[$current_category]:-}" ]]; then
                CATEGORY_NAMES["$current_category"]="${BASH_REMATCH[1]}"
            fi
        # Check for brew/cask line
        elif [[ "$line" =~ ^(brew|cask)[[:space:]]+\"([^\"]+)\" ]] && [[ -n "$current_category" ]]; then
            local pkg="${BASH_REMATCH[2]}"
            CATEGORY_PACKAGES["$current_category"]+="$pkg "
        fi
    done < "$BREWFILE"
}

list_categories() {
    echo ""
    echo -e "${BOLD}Available Categories:${NC}"
    echo ""
    for cat in "${!CATEGORIES[@]}"; do
        local name="${CATEGORY_NAMES[$cat]:-$cat}"
        local pkgs="${CATEGORY_PACKAGES[$cat]:-}"
        local count
        count=$(echo "$pkgs" | wc -w | tr -d ' ')
        echo -e "  ${GREEN}$cat${NC}: $name ($count packages)"
        if [[ -n "$pkgs" ]]; then
            echo "    Packages: $pkgs"
        fi
    done
    echo ""
}

install_category() {
    local category="$1"
    local pkgs="${CATEGORY_PACKAGES[$category]:-}"

    if [[ -z "$pkgs" ]]; then
        print_warn "No packages found for category: $category"
        return
    fi

    print_header "Installing $category packages..."

    for pkg in $pkgs; do
        # Check if it's a cask or formula
        if grep -q "^cask \"$pkg\"" "$BREWFILE"; then
            if brew_cask_installed "$pkg"; then
                print_ok "$pkg (already installed)"
            else
                print_info "Installing cask: $pkg"
                brew install --cask "$pkg" || print_warn "Failed to install $pkg"
            fi
        else
            if brew_pkg_installed "$pkg"; then
                print_ok "$pkg (already installed)"
            else
                print_info "Installing: $pkg"
                brew install "$pkg" || print_warn "Failed to install $pkg"
            fi
        fi
    done
}

interactive_select() {
    echo ""
    echo -e "${BOLD}Homebrew Package Installer${NC}"
    echo "Select which categories to install:"
    echo ""

    local selected=()
    local i=1
    local cat_array=()

    for cat in "${!CATEGORIES[@]}"; do
        cat_array+=("$cat")
        local name="${CATEGORY_NAMES[$cat]:-$cat}"
        local pkgs="${CATEGORY_PACKAGES[$cat]:-}"
        local count
        count=$(echo "$pkgs" | wc -w | tr -d ' ')
        echo "  $i) $name ($count packages)"
        ((i++))
    done

    echo ""
    echo "  a) Install all"
    echo "  q) Quit"
    echo ""
    read -rp "Enter numbers separated by spaces (e.g., 1 3 5): " choices

    if [[ "$choices" == "q" ]]; then
        echo "Cancelled."
        exit 0
    fi

    if [[ "$choices" == "a" ]]; then
        selected=("${cat_array[@]}")
    else
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#cat_array[@]} )); then
                selected+=("${cat_array[$((choice-1))]}")
            fi
        done
    fi

    if [[ ${#selected[@]} -eq 0 ]]; then
        print_warn "No categories selected."
        exit 0
    fi

    echo ""
    echo -e "${BOLD}Selected categories:${NC}"
    for cat in "${selected[@]}"; do
        echo "  - ${CATEGORY_NAMES[$cat]:-$cat}"
    done
    echo ""

    if ask_yes_no "Proceed with installation?" "y"; then
        for cat in "${selected[@]}"; do
            install_category "$cat"
        done
        echo ""
        print_ok "Installation complete!"
    fi
}

# Parse the Brewfile
parse_brewfile

# Main
case "${1:-interactive}" in
    --all)
        print_header "Installing all packages from Brewfile..."
        brew bundle --file="$BREWFILE"
        ;;
    --list)
        list_categories
        ;;
    --category)
        if [[ -z "${2:-}" ]]; then
            print_error "Please specify a category"
            list_categories
            exit 1
        fi
        install_category "$2"
        ;;
    interactive|"")
        interactive_select
        ;;
    *)
        echo "Usage: $0 [--all|--list|--category <name>]"
        exit 1
        ;;
esac
