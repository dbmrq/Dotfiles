#!/usr/bin/env bash
#
# Install Homebrew and packages for selected features
#
# Usage:
#   ./brew.sh                    # Install all packages
#   ./brew.sh vim git cli        # Install only specified features
#   ./brew.sh --list             # List available features
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Parse arguments
if [[ "${1:-}" == "--list" ]]; then
    echo "Available features:"
    for f in "${FEATURES[@]}"; do
        name="${f%%:*}"
        echo "  $name - $(get_feature_name "$name")"
    done
    exit 0
fi

# Determine which features to install
if [[ $# -gt 0 ]]; then
    SELECTED_FEATURES=("$@")
else
    # Install all features by default
    SELECTED_FEATURES=()
    for f in "${FEATURES[@]}"; do
        SELECTED_FEATURES+=("${f%%:*}")
    done
fi

# --- Install/update Homebrew ---
echo ""
echo "Setting up Homebrew..."
echo ""

if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_in_path

    brew_path="$(get_brew_path)"
    if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        echo "eval \"\$(${brew_path} shellenv)\"" >> "$HOME/.zprofile"
    fi
else
    echo "Homebrew already installed. Updating..."
    brew update
fi

# Collect all packages to install
all_packages=()
all_casks=()
install_xcode=false

for feature in "${SELECTED_FEATURES[@]}"; do
    # Get brew packages
    pkgs=$(get_brew_packages "$feature")
    for pkg in $pkgs; do
        [[ -n "$pkg" ]] && all_packages+=("$pkg")
    done

    # Get brew casks
    casks=$(get_brew_casks "$feature")
    for cask in $casks; do
        [[ -n "$cask" ]] && all_casks+=("$cask")
    done

    # Check for special post-install
    if [[ "$(get_post_install "$feature")" == "xcode" ]]; then
        install_xcode=true
    fi
done

# --- Install CLI packages ---
if [[ ${#all_packages[@]} -gt 0 ]]; then
    echo ""
    echo "Installing CLI packages..."
    for pkg in "${all_packages[@]}"; do
        if brew list "$pkg" >/dev/null 2>&1; then
            echo "  $pkg already installed"
        else
            echo "  Installing $pkg..."
            brew install "$pkg" || echo "  Warning: Failed to install $pkg"
        fi
    done
fi

# --- Install GUI apps (casks) ---
if [[ ${#all_casks[@]} -gt 0 ]]; then
    echo ""
    echo "Installing GUI applications..."
    for cask in "${all_casks[@]}"; do
        if brew list --cask "$cask" >/dev/null 2>&1; then
            echo "  $cask already installed"
        else
            echo "  Installing $cask..."
            brew install --cask "$cask" || echo "  Warning: Failed to install $cask"
        fi
    done
fi

# --- Xcode from App Store ---
if $install_xcode; then
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
fi

# --- Cleanup ---
echo ""
echo "Cleaning up..."
brew cleanup
brew doctor || true

echo ""
echo "Done."
echo ""
