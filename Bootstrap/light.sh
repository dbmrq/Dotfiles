#!/usr/bin/env bash
#
# Light dotfiles installer - essential configs without cloning the full repo
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/light.sh | bash
#
# Installs:
#   - Essential Vim settings and mappings
#   - Essential Git aliases
#

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/dbmrq/Dotfiles/master"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${GREEN}Installing light dotfiles...${NC}"
echo ""

# Create directories
mkdir -p ~/.vim

# Download Vim files
echo "Downloading Vim configuration..."
curl -fsSL "$BASE_URL/Vim/.vimrc" -o ~/.vimrc
curl -fsSL "$BASE_URL/Vim/.vim/settings-essential.vim" -o ~/.vim/settings-essential.vim
curl -fsSL "$BASE_URL/Vim/.vim/mappings-essential.vim" -o ~/.vim/mappings-essential.vim

# Download Git config
echo "Downloading Git configuration..."
curl -fsSL "$BASE_URL/Git/.gitconfig-essential" -o ~/.gitconfig-essential

# Check if .gitconfig already exists
if [[ -f ~/.gitconfig ]]; then
    # Check if it already includes essential
    if grep -q "gitconfig-essential" ~/.gitconfig 2>/dev/null; then
        echo -e "${YELLOW}Git config already includes essential settings.${NC}"
    else
        echo -e "${YELLOW}Existing .gitconfig found.${NC}"
        echo "To use the essential aliases, add this to your ~/.gitconfig:"
        echo ""
        echo "[include]"
        echo "    path = ~/.gitconfig-essential"
        echo ""
    fi
else
    # Ask for git user info
    echo ""
    echo -e "${YELLOW}Git user configuration:${NC}"
    read -rp "  Your name: " git_name
    read -rp "  Your email: " git_email

    # Create minimal gitconfig that includes essential
    cat > ~/.gitconfig << EOF
# Git configuration - created by light dotfiles installer

[include]
    path = ~/.gitconfig-essential

[user]
    name = $git_name
    email = $git_email
EOF
    echo ""
    echo "Created ~/.gitconfig with your settings."
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Installed:"
echo "  ~/.vimrc"
echo "  ~/.vim/settings-essential.vim"
echo "  ~/.vim/mappings-essential.vim"
echo "  ~/.gitconfig-essential"
echo ""
echo "Essential Vim features: jk/kj escape, H/L for line start/end, space as leader"
echo "Essential Git aliases: co, ci, st, br, tug, sync, lg, and more"
echo ""

