#!/usr/bin/env bash

echo ""
echo "Installing Homebrew and formulae..."
echo ""

if ! hash brew 2>/dev/null; then
    echo -e "\nInstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo -e "\nHomebrew already installed. Upgrading..."
    brew upgrade
fi

# CLI tools
brew install git
brew install git-extras
brew install lua
brew install mas
brew install par
brew install stow
brew install ruby
brew install trash
brew install cscope
brew install pandoc
brew install rename
brew install python3
brew install swiftlint

# GUI apps
brew install --cask vlc
brew install --cask basictex
brew install --cask appcleaner
brew install --cask hammerspoon
brew install --cask google-chrome
brew install --cask the-unarchiver

# Install Xcode from App Store
mas install 497799835
sudo xcodebuild -license accept

read -n 1 -s -r -p "Open Xcode once before continuing. Press any key when ready."
echo ""

brew install macvim
vim +PlugUpdate +qall

brew cleanup
brew doctor

echo ""
echo "Done."
echo ""
