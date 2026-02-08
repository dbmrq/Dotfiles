#!/usr/bin/env bash
#
# Install and update Neovim plugins and spell files
#
# Usage:
#   ./plugins.sh           # Interactive - ask before updating
#   ./plugins.sh --force   # Update without asking
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MODE="${1:-interactive}"

echo ""
echo -e "${BOLD}Neovim Plugin & Spell File Manager${NC}"
echo ""

# Check if neovim is available
has_nvim=false
command -v nvim >/dev/null 2>&1 && has_nvim=true

if ! $has_nvim; then
    print_warn "Neovim is not installed."
    exit 0
fi

# Ask for confirmation in interactive mode
if [[ "$MODE" != "--force" ]]; then
    if ! ask_yes_no "Update Neovim plugins and spell files?" "y"; then
        echo "Skipping update."
        exit 0
    fi
fi

# Install spell files
install_spell_files() {
    local vim_spell_dir="$HOME/.vim/spell"
    local nvim_spell_dir="$HOME/.local/share/nvim/site/spell"
    local spell_mirror="https://ftp.nluug.nl/pub/vim/runtime/spell"

    # Languages to install (add more as needed)
    local languages=("pt" "en")

    mkdir -p "$vim_spell_dir" "$nvim_spell_dir"

    for lang in "${languages[@]}"; do
        # Check both vim and nvim spell directories
        local vim_spell_file="$vim_spell_dir/${lang}.utf-8.spl"
        local nvim_spell_file="$nvim_spell_dir/${lang}.utf-8.spl"

        if [[ -f "$vim_spell_file" ]] || [[ -f "$nvim_spell_file" ]]; then
            echo "  ${lang}.utf-8.spl already installed"
        else
            print_info "Downloading ${lang} spell file..."
            # Install to vim spell dir (shared with nvim via dotfiles)
            if curl -fLo "$vim_spell_file" "${spell_mirror}/${lang}.utf-8.spl" 2>/dev/null; then
                print_ok "Installed ${lang}.utf-8.spl"
            else
                print_warn "Failed to download ${lang} spell file"
            fi
        fi
    done
}

echo "Installing spell files..."
install_spell_files

echo ""
echo "Updating Neovim plugins..."

# Update plugins using lazy.nvim (headless)
print_info "Syncing lazy.nvim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
    print_warn "lazy.nvim sync had issues (may be normal on first run)"
}

echo ""
print_ok "Done."

