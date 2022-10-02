#!/usr/bin/env bash

osascript -e 'tell application "System Preferences" to quit'

sudo -v

while true; do sudo -n true; sleep 60; \
    kill -0 "$$" || exit; done 2>/dev/null &

# Software update {{{1

echo ""
echo "Updating macOS..."
echo ""

sudo softwareupdate -i -a

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Xcode developer tools {{{1

echo ""
echo "Installing Xcode developer tools..."
echo ""

xcode-select --install

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Homebrew {{{1
read -p "Run brew.sh? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    /bin/bash brew.sh
fi
# }}}1

# Preferences {{{1
read -p "Run prefs.sh? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    /bin/bash prefs.sh
fi
# }}}1

# Prezto {{{1
read -p "Install Prezto? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Installing Prezto..."
    echo ""

    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

    echo ""
    echo "Done."
    echo ""
    echo "---"
fi
# }}}1

# Terminal colorscheme {{{1
read -p "Add terminal colorscheme? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Adding Terminal color schemes..."
    echo ""

    git clone https://github.com/dbmrq/terminal-solarized.git

    open terminal-solarized/Solarized\ Dark.terminal

    open terminal-solarized/Solarized\ Light.terminal

    trash terminal-solarized

    echo ""
    echo "Done."
    echo ""
    echo "---"
fi
# }}}1

# LaTeX {{{1
read -p "Run tlmgr.sh? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    osascript -e "tell application \"Terminal\" to do script \"source ${PWD}/tlmgr.sh\""
fi
# }}}1

# Symlink dotfiles {{{1
cd $(dirname `pwd`)
stow --target=$HOME --ignore=\.DS_Store */
# }}}1

# vim: set tw=0:

