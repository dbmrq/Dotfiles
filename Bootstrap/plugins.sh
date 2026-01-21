#!/usr/bin/env bash
#
# Install and update Vim/Neovim plugins
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
echo -e "${BOLD}Vim/Neovim Plugin Manager${NC}"
echo ""

# Check if vim or neovim are available
has_vim=false
has_nvim=false
command -v vim >/dev/null 2>&1 && has_vim=true
command -v nvim >/dev/null 2>&1 && has_nvim=true

if ! $has_vim && ! $has_nvim; then
    print_warn "Neither Vim nor Neovim is installed."
    exit 0
fi

# Ask for confirmation in interactive mode
if [[ "$MODE" != "--force" ]]; then
    if ! ask_yes_no "Update Vim/Neovim plugins?" "y"; then
        echo "Skipping plugin update."
        exit 0
    fi
fi

echo "Updating editor plugins..."

# Ensure vim-plug is installed for Vim
if $has_vim; then
    vim_plug="$HOME/.vim/autoload/plug.vim"
    if [[ ! -f "$vim_plug" ]]; then
        print_info "Installing vim-plug for Vim..."
        curl -fLo "$vim_plug" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
fi

# Ensure vim-plug is installed for Neovim
if $has_nvim; then
    nvim_plug="$HOME/.local/share/nvim/site/autoload/plug.vim"
    if [[ ! -f "$nvim_plug" ]]; then
        print_info "Installing vim-plug for Neovim..."
        curl -fLo "$nvim_plug" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
fi

# Update plugins
if $has_vim; then
    print_info "Updating Vim plugins..."
    vim +PlugUpdate +qall 2>/dev/null || true
fi

if $has_nvim; then
    print_info "Updating Neovim plugins..."
    nvim --headless +PlugUpdate +qall 2>/dev/null || true
fi

echo ""
print_ok "Done."

