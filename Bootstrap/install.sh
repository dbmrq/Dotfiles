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

# Colors - only enable if we have a real terminal that supports them
setup_colors() {
    # Check if /dev/tty exists and supports colors
    if [[ -e /dev/tty ]] && command -v tput >/dev/null 2>&1; then
        local colors
        colors=$(tput colors 2>/dev/null) || colors=0
        if [[ "$colors" -ge 8 ]]; then
            RED=$(tput setaf 1)
            GREEN=$(tput setaf 2)
            YELLOW=$(tput setaf 3)
            BOLD=$(tput bold)
            NC=$(tput sgr0)
            return
        fi
    fi
    # Fallback: no colors
    RED='' GREEN='' YELLOW='' BOLD='' NC=''
}

setup_colors

# Read from /dev/tty to handle curl pipe correctly
# Usage: read_input "prompt" variable_name
read_input() {
    local prompt="$1"
    if [[ -e /dev/tty ]]; then
        # shellcheck disable=SC2229
        read -rp "$prompt" "$2" </dev/tty
    else
        echo "Error: Cannot read input (no terminal available)." >&2
        exit 1
    fi
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

OS="$(detect_os)"

# Check if running as root
IS_ROOT=false
TARGET_USER=""
if [[ "$(id -u)" -eq 0 ]]; then
    IS_ROOT=true
fi

echo ""
echo "${BOLD}╔════════════════════════════════════════╗${NC}"
echo "${BOLD}║     Dotfiles Installer                 ║${NC}"
echo "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

if [[ "$OS" == "unknown" ]]; then
    echo "${RED}Error: Unsupported operating system.${NC}"
    echo "This installer supports macOS and Linux only."
    exit 1
fi

if [[ "$OS" == "macos" ]]; then
    echo "Detected: ${GREEN}macOS${NC}"
else
    echo "Detected: ${GREEN}Linux${NC}"
fi

# Install essential configs for a user (vim mappings, shell aliases)
# Usage: install_essentials_for_user <username> <home_dir>
install_essentials_for_user() {
    local username="$1"
    local home_dir="$2"

    echo "  Installing essentials for ${BOLD}$username${NC}..."

    # Create vim directory
    mkdir -p "$home_dir/.vim"

    # Download Vim files
    curl -fsSL "$BASE_URL/Vim/.vimrc" -o "$home_dir/.vimrc"
    curl -fsSL "$BASE_URL/Vim/.vim/settings-essential.vim" -o "$home_dir/.vim/settings-essential.vim"
    curl -fsSL "$BASE_URL/Vim/.vim/mappings-essential.vim" -o "$home_dir/.vim/mappings-essential.vim"

    # Download shell aliases
    curl -fsSL "$BASE_URL/Shell/.shell_common" -o "$home_dir/.shell_common"
    curl -fsSL "$BASE_URL/Bash/.bash_aliases" -o "$home_dir/.bash_aliases"

    # Source in .bashrc if not already
    if [[ -f "$home_dir/.bashrc" ]]; then
        if ! grep -q "\.bash_aliases" "$home_dir/.bashrc" 2>/dev/null; then
            {
                echo ""
                echo "# Load custom aliases"
                echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi"
            } >> "$home_dir/.bashrc"
        fi
    fi

    # Fix ownership if installing for another user
    if [[ "$username" != "root" ]]; then
        chown -R "$username:" "$home_dir/.vim" "$home_dir/.vimrc" \
            "$home_dir/.shell_common" "$home_dir/.bash_aliases" 2>/dev/null || true
    fi
}

# Handle root user
if $IS_ROOT; then
    if [[ "$OS" != "linux" ]]; then
        echo ""
        echo "${RED}Error: Running as root is not recommended on macOS.${NC}"
        exit 1
    fi

    echo ""
    echo "${YELLOW}Running as root.${NC}"
    echo ""
    echo "Options:"
    echo "  1) ${BOLD}System setup${NC} — Install packages + essential configs"
    echo "     Installs neovim/vim, git, curl system-wide."
    echo "     Adds vim mappings and shell aliases for root and selected users."
    echo ""
    echo "  2) ${BOLD}Switch user${NC} — Run as a regular user instead"
    echo "     For full dotfiles setup (cloning repo, etc.)"
    echo ""
    echo "  3) Cancel"
    echo ""
    read_input "Choose [1/2/3]: " root_choice

    # shellcheck disable=SC2154
    case "$root_choice" in
        1)
            echo ""
            echo "${GREEN}Installing system packages...${NC}"
            echo ""

            # Detect package manager and install packages
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update
                apt-get install -y neovim vim git curl
            elif command -v dnf >/dev/null 2>&1; then
                dnf install -y neovim vim git curl
            elif command -v pacman >/dev/null 2>&1; then
                pacman -Sy --noconfirm neovim vim git curl
            elif command -v apk >/dev/null 2>&1; then
                apk add --no-cache neovim vim git curl
            elif command -v zypper >/dev/null 2>&1; then
                zypper install -y neovim vim git curl
            else
                echo "${YELLOW}Warning: Unknown package manager. Skipping package installation.${NC}"
            fi

            echo ""
            echo "${GREEN}Installing essential configs...${NC}"
            echo ""

            # Always install for root
            install_essentials_for_user "root" "/root"

            # Ask about other users
            echo ""
            read_input "Install essentials for other users? [y/N]: " install_others
            # shellcheck disable=SC2154
            if [[ "$install_others" =~ ^[Yy]$ ]]; then
                # List regular users (UID >= 1000, with home directories)
                echo ""
                echo "Available users:"
                users=()
                while IFS=: read -r username _ uid _ _ home _; do
                    if [[ "$uid" -ge 1000 ]] && [[ -d "$home" ]]; then
                        users+=("$username:$home")
                        echo "  - $username ($home)"
                    fi
                done < /etc/passwd

                if [[ ${#users[@]} -eq 0 ]]; then
                    echo "  (no regular users found)"
                else
                    echo ""
                    read_input "Install for all listed users? [Y/n]: " install_all
                    # shellcheck disable=SC2154
                    if [[ ! "$install_all" =~ ^[Nn]$ ]]; then
                        for user_entry in "${users[@]}"; do
                            username="${user_entry%%:*}"
                            home="${user_entry#*:}"
                            install_essentials_for_user "$username" "$home"
                        done
                    else
                        read_input "Enter usernames (space-separated): " selected_users
                        # shellcheck disable=SC2154
                        for username in $selected_users; do
                            home=$(getent passwd "$username" | cut -d: -f6)
                            if [[ -n "$home" ]] && [[ -d "$home" ]]; then
                                install_essentials_for_user "$username" "$home"
                            else
                                echo "  ${YELLOW}Skipping $username (user not found)${NC}"
                            fi
                        done
                    fi
                fi
            fi

            echo ""
            echo "${GREEN}System setup complete!${NC}"
            echo ""
            echo "Installed:"
            echo "  • System packages: neovim, vim, git, curl"
            echo "  • Vim config: essential mappings (jk escape, H/L, space leader)"
            echo "  • Shell aliases: navigation, safety prompts, git shortcuts"
            echo ""
            echo "To set neovim as the default editor, the shell config sets:"
            echo "  export EDITOR='nvim'"
            echo "  alias vim='nvim'"
            echo ""
            exit 0
            ;;
        2)
            echo ""
            read_input "Enter username to switch to: " TARGET_USER
            if ! id "$TARGET_USER" >/dev/null 2>&1; then
                echo "${RED}Error: User '$TARGET_USER' does not exist.${NC}"
                exit 1
            fi
            echo "Switching to user '$TARGET_USER'..."
            exec su - "$TARGET_USER" -c "curl -fsSL '$BASE_URL/Bootstrap/install.sh' | bash"
            ;;
        *)
            echo "Cancelled."
            exit 0
            ;;
    esac
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

read_input "Choose [1/2/3]: " choice

# shellcheck disable=SC2154
case "$choice" in
    1)
        # Light installation
        echo ""
        echo "${GREEN}Starting light installation...${NC}"
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
                echo "${YELLOW}Git config already includes essential settings.${NC}"
            else
                echo "${YELLOW}Existing .gitconfig found.${NC}"
                echo "To use the essential aliases, add this to your ~/.gitconfig:"
                echo ""
                echo "[include]"
                echo "    path = ~/.gitconfig-essential"
                echo ""
            fi
        else
            # Ask for git user info
            echo ""
            echo "${YELLOW}Git user configuration:${NC}"
            read_input "  Your name: " git_name
            read_input "  Your email: " git_email

            # shellcheck disable=SC2154
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
            curl -fsSL "$BASE_URL/Shell/.shell_common" -o ~/.shell_common
            curl -fsSL "$BASE_URL/Bash/.bash_aliases" -o ~/.bash_aliases

            # Source in .bashrc if not already
            if [[ -f ~/.bashrc ]]; then
                if ! grep -q "\.bash_aliases" ~/.bashrc 2>/dev/null; then
                    {
                        echo ""
                        echo "# Load custom aliases"
                        echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi"
                    } >> ~/.bashrc
                    echo "Added .bash_aliases sourcing to .bashrc"
                fi
            fi
        fi

        echo ""
        echo "${GREEN}Light installation complete!${NC}"
        echo ""
        echo "Installed:"
        echo "  ~/.vimrc"
        echo "  ~/.vim/settings-essential.vim"
        echo "  ~/.vim/mappings-essential.vim"
        echo "  ~/.gitconfig-essential"
        if [[ "$OS" == "linux" ]]; then
            echo "  ~/.shell_common"
            echo "  ~/.bash_aliases"
        fi
        echo ""
        echo "Essential Vim features: jk/kj escape, H/L for line start/end, space as leader"
        echo "Essential Git aliases: co, ci, st, br, tug, sync, lg, and more"
        echo ""
        ;;

    2)
        # Full installation
        echo ""
        echo "${GREEN}Starting full installation...${NC}"
        echo ""

        # Check for git
        if ! command -v git >/dev/null 2>&1; then
            echo "${RED}Error: git is not installed.${NC}"
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
        echo "${GREEN}Running bootstrap...${NC}"
        echo ""
        cd "$DOTFILES_DIR/Bootstrap"
        exec ./bootstrap.sh
        ;;

    *)
        echo "Cancelled."
        exit 0
        ;;
esac

