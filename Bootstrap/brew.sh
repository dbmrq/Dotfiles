#!/usr/bin/env bash

echo ""
echo "Installing Homebrew and formulae..."
echo ""

if ! hash brew 2>/dev/null; then
    # If Homebrew isn't installed
    echo -e "\nInstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "\nHomebrew already installed. Moving on..."
    brew upgrade
fi

brew install git
brew install git-extras
brew install lua
# brew install zsh
brew install mas
brew install par
brew install stow
brew install ruby
brew install trash
# brew install tldr
# brew install tree
# brew install lua@5.3
# brew install luajit
brew install cscope
brew install pandoc
brew install rename
brew install python
brew install python3
brew install swiftlint
# brew install dockutil
# brew install carthage
# brew install thefuck
# brew install terminal-notifier
brew install curl --with-openssl
brew install difftastic

brew install --cask vlc
brew install --cask java
# brew install --cask calibre
# brew install --cask opensim
# brew install --cask firefox
brew install --cask basictex
brew install --cask appcleaner
brew install --cask hammerspoon
# brew install --cask transmission
# brew install --cask flash-player
brew install --cask google-chrome
brew install --cask the-unarchiver
# brew install --cask github-desktop
# brew install --cask qlcolorcode qlstephen qlmarkdown quicklook-csv qlimagesize

mas install 497799835
sudo xcodebuild -license accept

read -n 1 -s -r -p "A few applications require Xcode to be installed and opened once. Open Xcode now and press any key to continue."

brew install macvim

OSASCRIPT='tell application "Finder" to make alias file to POSIX file "'
OSASCRIPT+=$(find $(brew --prefix) -name MacVim.app)
OSASCRIPT+='" at POSIX file "/Applications/"'
osascript -e $OSASCRIPT

vim +PlugUpdate +qall

brew prune
brew cleanup
brew doctor

echo ""
echo "Done."
echo ""
echo "---"

