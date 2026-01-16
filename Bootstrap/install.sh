#!/usr/bin/env bash
#
# One-liner installer for dotfiles
# curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
#

set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
REPO_URL="https://github.com/dbmrq/Dotfiles.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "Installing dotfiles..."
echo ""

# Check for git
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo "Install Xcode Command Line Tools first:"
    echo "  xcode-select --install"
    exit 1
fi

# Clone or update repo
if [[ -d "$DOTFILES_DIR" ]]; then
    echo "Dotfiles directory already exists at $DOTFILES_DIR"
    echo "Updating..."
    cd "$DOTFILES_DIR"
    git pull --rebase || true
else
    echo "Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# Run bootstrap
echo ""
echo -e "${GREEN}Running bootstrap...${NC}"
echo ""
cd "$DOTFILES_DIR/Bootstrap"
exec ./bootstrap.sh

