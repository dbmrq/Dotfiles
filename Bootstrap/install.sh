#!/usr/bin/env bash
#
# Dotfiles installer
# curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
#
# - Clones (or updates) the dotfiles repository
# - Runs bootstrap.sh which handles all installation choices
#

set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
REPO_URL="https://github.com/dbmrq/Dotfiles.git"
BASE_URL="https://raw.githubusercontent.com/dbmrq/Dotfiles/master"

# Colors - only enable if we have a real terminal that supports them
setup_colors() {
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
    RED='' GREEN='' YELLOW='' BOLD='' NC=''
}

setup_colors

# Read from /dev/tty to handle curl pipe correctly
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
IS_ROOT=false
[[ "$(id -u)" -eq 0 ]] && IS_ROOT=true

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

echo "Detected: ${GREEN}$([ "$OS" == "macos" ] && echo "macOS" || echo "Linux")${NC}"

# Install essential configs for a user (vim mappings, shell aliases)
# Used by root on Linux to set up configs for users
install_essentials_for_user() {
    local username="$1"
    local home_dir="$2"

    echo "  Installing essentials for ${BOLD}$username${NC}..."

    mkdir -p "$home_dir/.vim" "$home_dir/.config/nvim"

    curl -fsSL "$BASE_URL/Vim/.vimrc" -o "$home_dir/.vimrc"
    curl -fsSL "$BASE_URL/Vim/.vim/settings-essential.vim" -o "$home_dir/.vim/settings-essential.vim"
    curl -fsSL "$BASE_URL/Vim/.vim/mappings-essential.vim" -o "$home_dir/.vim/mappings-essential.vim"

    if [[ ! -f "$home_dir/.config/nvim/init.vim" ]] && [[ ! -f "$home_dir/.config/nvim/init.lua" ]]; then
        cat > "$home_dir/.config/nvim/init.vim" << 'NVIM_INIT'
" Neovim config - sources shared vim configuration
if filereadable(expand('~/.vimrc'))
    source ~/.vimrc
endif
if has('nvim')
    tnoremap <Esc> <C-\><C-n>
    tnoremap jk <C-\><C-n>
    tnoremap kj <C-\><C-n>
endif
NVIM_INIT
    fi

    curl -fsSL "$BASE_URL/Shell/.shell_common" -o "$home_dir/.shell_common"
    curl -fsSL "$BASE_URL/Bash/.bash_aliases" -o "$home_dir/.bash_aliases"

    if [[ -f "$home_dir/.bashrc" ]] && ! grep -q "\.bash_aliases" "$home_dir/.bashrc" 2>/dev/null; then
        echo -e "\n# Load custom aliases\nif [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> "$home_dir/.bashrc"
    fi

    [[ "$username" != "root" ]] && chown -R "$username:" "$home_dir/.vim" "$home_dir/.vimrc" \
        "$home_dir/.config/nvim" "$home_dir/.shell_common" "$home_dir/.bash_aliases" 2>/dev/null || true
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

# --- Main installation flow ---
# Clone (or update) the dotfiles repo and run bootstrap

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

# Run bootstrap - it handles all the "what to install" questions
echo ""
echo "${GREEN}Running bootstrap...${NC}"
echo ""
cd "$DOTFILES_DIR/Bootstrap"
exec ./bootstrap.sh
