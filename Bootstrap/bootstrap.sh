#!/usr/bin/env bash

osascript -e 'tell application "System Preferences" to quit'

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo ""
echo "Updating macOS..."
sudo softwareupdate -i -a
echo "Done."
echo ""

echo "Installing Xcode developer tools..."
xcode-select --install
echo "Done."
echo ""

read -p "Run brew.sh? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    /bin/bash brew.sh
fi
if ! hash brew 2>/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

read -p "Run prefs.sh? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    /bin/bash prefs.sh
fi

read -p "Install Prezto? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Prezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    echo "Done."
fi

read -p "Add terminal colorscheme? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Adding Terminal color schemes..."
    git clone https://github.com/dbmrq/terminal-solarized.git
    open terminal-solarized/Solarized\ Dark.terminal
    open terminal-solarized/Solarized\ Light.terminal
    trash terminal-solarized
    echo "Done."
fi

read -p "Run tlmgr.sh (LaTeX packages)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    osascript -e "tell application \"Terminal\" to do script \"source ${PWD}/tlmgr.sh\""
fi

read -p "Install actuallymentor/battery? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -s https://raw.githubusercontent.com/actuallymentor/battery/main/setup.sh | bash
fi

read -p "Symlink dotfiles with stow? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$(dirname "$PWD")"
    stow -v --target="$HOME" --ignore='\.DS_Store' */
fi

echo ""
echo "Bootstrap complete!"
