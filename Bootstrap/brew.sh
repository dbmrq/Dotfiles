#!/usr/bin/env bash
#
# Install Homebrew and common packages
# Can be run standalone or called from bootstrap.sh
#

set -euo pipefail

# --- Determine Homebrew path based on architecture ---
get_brew_path() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "/opt/homebrew/bin/brew"
    else
        echo "/usr/local/bin/brew"
    fi
}

ensure_brew_in_path() {
    if ! command -v brew >/dev/null 2>&1; then
        local brew_path
        brew_path="$(get_brew_path)"
        if [[ -x "$brew_path" ]]; then
            eval "$("$brew_path" shellenv)"
        fi
    fi
}

# --- Install/update Homebrew ---
echo ""
echo "Setting up Homebrew..."
echo ""

if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to current shell
    ensure_brew_in_path

    # Add to profile if not already there
    local brew_path
    brew_path="$(get_brew_path)"
    if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        echo "eval \"\$(${brew_path} shellenv)\"" >> "$HOME/.zprofile"
    fi
else
    echo "Homebrew already installed. Updating..."
    brew update
fi

# --- CLI tools ---
echo ""
echo "Installing CLI tools..."

cli_packages=(
    git
    git-extras
    lua
    mas
    par
    stow
    ruby
    trash-cli
    cscope
    pandoc
    rename
    python3
    swiftlint
)

for pkg in "${cli_packages[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg..."
        brew install "$pkg" || echo "  Warning: Failed to install $pkg"
    fi
done

# --- GUI apps ---
echo ""
echo "Installing GUI applications..."

gui_apps=(
    vlc
    basictex
    appcleaner
    hammerspoon
    google-chrome
    the-unarchiver
)

for app in "${gui_apps[@]}"; do
    if brew list --cask "$app" >/dev/null 2>&1; then
        echo "  $app already installed"
    else
        echo "  Installing $app..."
        brew install --cask "$app" || echo "  Warning: Failed to install $app"
    fi
done

# --- Xcode from App Store ---
echo ""
echo "Installing Xcode from App Store..."

if command -v mas >/dev/null 2>&1; then
    if [[ -d "/Applications/Xcode.app" ]]; then
        echo "  Xcode already installed"
    else
        mas install 497799835 || echo "  Warning: Failed to install Xcode"
    fi

    if [[ -d "/Applications/Xcode.app" ]]; then
        sudo xcodebuild -license accept 2>/dev/null || true
    fi
else
    echo "  Warning: mas not installed, skipping Xcode"
fi

# --- MacVim and Neovim ---
echo ""
echo "Installing Vim editors..."

if brew list macvim >/dev/null 2>&1; then
    echo "  macvim already installed"
else
    brew install macvim || echo "  Warning: Failed to install macvim"
fi

if brew list neovim >/dev/null 2>&1; then
    echo "  neovim already installed"
else
    brew install neovim || echo "  Warning: Failed to install neovim"
fi

# --- Cleanup ---
echo ""
echo "Cleaning up..."
brew cleanup
brew doctor || true

echo ""
echo "Done."
echo ""
