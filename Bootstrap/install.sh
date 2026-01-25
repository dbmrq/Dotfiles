#!/usr/bin/env bash
#
# Unified dotfiles installer
# curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
#
# Detects OS (macOS/Linux) and asks user what type of installation they want:
#   - Light: Essential configs only, no cloning required
#   - Full: Complete setup with all configurations
#

set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
REPO_URL="https://github.com/dbmrq/Dotfiles.git"
BASE_URL="https://raw.githubusercontent.com/dbmrq/Dotfiles/master"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

OS="$(detect_os)"

echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Dotfiles Installer                 ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

if [[ "$OS" == "unknown" ]]; then
    echo -e "${RED}Error: Unsupported operating system.${NC}"
    echo "This installer supports macOS and Linux only."
    exit 1
fi

if [[ "$OS" == "macos" ]]; then
    echo -e "Detected: ${GREEN}macOS${NC}"
else
    echo -e "Detected: ${GREEN}Linux${NC}"
fi
echo ""

# Menu
echo "What would you like to install?"
echo ""
echo "  1) ${BOLD}Light${NC} — Essential configs only (Vim, Git aliases)"
echo "     Quick setup for temporary or remote machines."
echo "     Does not clone the repository."
echo ""
echo "  2) ${BOLD}Full${NC} — Complete dotfiles setup"
echo "     Clones the repository and runs the full bootstrap."
if [[ "$OS" == "macos" ]]; then
    echo "     Includes: Homebrew packages, macOS preferences, shell config, etc."
else
    echo "     Includes: Package installation, shell config, and terminal setup."
fi
echo ""
echo "  3) Cancel"
echo ""

read -rp "Choose [1/2/3]: " choice

case "$choice" in
    1)
        # Light installation
        echo ""
        echo -e "${GREEN}Starting light installation...${NC}"
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

            cat > ~/.gitconfig << EOF
# Git configuration - created by dotfiles installer

[include]
    path = ~/.gitconfig-essential

[user]
    name = $git_name
    email = $git_email
EOF
            echo ""
            echo "Created ~/.gitconfig with your settings."
        fi

        # Download shell aliases for Linux
        if [[ "$OS" == "linux" ]]; then
            echo "Downloading shell configuration..."
            curl -fsSL "$BASE_URL/Bash/.bash_aliases" -o ~/.bash_aliases

            # Source in .bashrc if not already
            if [[ -f ~/.bashrc ]]; then
                if ! grep -q "\.bash_aliases" ~/.bashrc 2>/dev/null; then
                    echo "" >> ~/.bashrc
                    echo "# Load custom aliases" >> ~/.bashrc
                    echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> ~/.bashrc
                    echo "Added .bash_aliases sourcing to .bashrc"
                fi
            fi
        fi

        echo ""
        echo -e "${GREEN}Light installation complete!${NC}"
        echo ""
        echo "Installed:"
        echo "  ~/.vimrc"
        echo "  ~/.vim/settings-essential.vim"
        echo "  ~/.vim/mappings-essential.vim"
        echo "  ~/.gitconfig-essential"
        [[ "$OS" == "linux" ]] && echo "  ~/.bash_aliases"
        echo ""
        echo "Essential Vim features: jk/kj escape, H/L for line start/end, space as leader"
        echo "Essential Git aliases: co, ci, st, br, tug, sync, lg, and more"
        echo ""
        ;;

    2)
        # Full installation
        echo ""
        echo -e "${GREEN}Starting full installation...${NC}"
        echo ""

        # Check for git
        if ! command -v git >/dev/null 2>&1; then
            echo -e "${RED}Error: git is not installed.${NC}"
            if [[ "$OS" == "macos" ]]; then
                echo "Install Xcode Command Line Tools first:"
                echo "  xcode-select --install"
            else
                echo "Install git first:"
                echo "  sudo apt install git   # Debian/Ubuntu"
                echo "  sudo dnf install git   # Fedora"
                echo "  sudo pacman -S git     # Arch"
            fi
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
        ;;

    *)
        echo "Cancelled."
        exit 0
        ;;
esac

