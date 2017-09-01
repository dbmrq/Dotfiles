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

# Preferences {{{1

# based on https://mths.be/macos

echo ""
echo "Setting preferences..."
echo ""

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable Gatekeeper
sudo spctl --master-disable

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array
killall Dock

# Disable Dashboard (seems to be default now?)
# defaults write com.apple.dashboard mcx-disabled -bool true


echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Install SF Mono {{{1

echo ""
echo "Copying SF Mono"
echo ""

cp -v /Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SFMono-* ~/Library/Fonts

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
sudo xcodebuild -license accept

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Homebrew {{{1

echo ""
echo "Installing Homebrew and formulae..."
echo ""

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git
brew install lua
brew install zsh
brew install mas
brew install ruby
brew install fasd
brew install trash
# brew install tldr
# brew install tree
brew install lua@5.3
brew install luajit
brew install cscope
brew install pandoc
brew install python
brew install python3
brew install dockutil
brew install carthage
# brew install thefuck
brew install terminal-notifier
brew install curl --with-openssl

brew tap caskroom/cask
brew cask install vlc
brew cask install java
brew cask install calibre
brew cask install opensim
brew cask install firefox
brew cask install basictex
brew cask install appcleaner
brew cask install hammerspoon
brew cask install transmission
brew cask install google-chrome
brew cask install the-unarchiver
brew cask install qlcolorcode qlstephen qlmarkdown quicklook-csv qlimagesize

sudo chown -R $(whoami):admin /usr/local
sudo chmod -R g+rwx /usr/local
# This is necessary so that `brew prune` can do its thing.

brew prune
brew cleanup

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Prezto {{{1

echo ""
echo "Installing Prezto..."
echo ""

git clone --recursive -j8 https://github.com/sorin-ionescu/prezto.git ~/.zprezto

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Homesick {{{1

echo ""
echo "Installing Homesick and dotfiles..."
echo ""

mkdir -p ~/.vim/backup ~/.vim/swp ~/.vim/undo

sudo gem install homesick
homesick clone dbmrq/dotfiles
homesick symlink --quiet --force dotfiles

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Change Shell {{{1

echo ""
echo "Changing default shell..."
echo ""

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Add gitignore {{{1

echo ""
echo "Adding global gitignore..."
echo ""

git config --global core.excludesfile '~/.gitignore'

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# MAS {{{1

mas signin --dialog ""

# Xcode
mas install 497799835
sudo xcodebuild -license accept

# Pages
mas install 409201541
#Numbers
mas install 409203825

# }}}1

# MacVim {{{1

echo ""
echo "Installilng MacVim and plugins..."
echo ""

brew install macvim --with-override-system-vim --with-luajit --HEAD

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

mkdir -pv ~/Code/Vim

git clone https://github.com/dbmrq/vim-ditto.git ~/Code/Vim/vim-ditto
git clone https://github.com/dbmrq/vim-chalk.git ~/Code/Vim/vim-chalk
git clone https://github.com/dbmrq/vim-dialect.git ~/Code/Vim/vim-dialect
git clone https://github.com/dbmrq/vim-howdy.git ~/Code/Vim/vim-howdy

vim +Plug +qall

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Terminal colorscheme {{{1

echo ""
echo "Adding Terminal color schemes..."
echo ""

git clone https://github.com/dbmrq/terminal-solarized.git ~/Code/Misc/terminal-solarized

open ~/Code/Misc/terminal-solarized/Solarized\ Dark.terminal

open ~/Code/Misc/terminal-solarized/Solarized\ Light.terminal

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# .update.sh {{{1

git clone https://gist.github.com/a755dde62bf109cb5c0d32bec800fa7a.git ~/Desktop/update

mkdir -pv ~/Library/LaunchAgents
mv ~/Desktop/update/com.dbmrq.update.plist ~/Library/LaunchAgents/com.dbmrq.update.plist

trash ~/Desktop/update

sudo chown root:admin ~/.update.sh
sudo chmod 4775 ~/.update.sh
sudo chown root:admin ~/Library/LaunchAgents/com.dbmrq.update.plist
sudo launchctl load ~/Library/LaunchAgents/com.dbmrq.update.plist

# }}}1

# Services {{{1

git clone https://github.com/dbmrq/workflow-translate.git ~/Desktop/tmp
mv ~/Desktop/tmp/Google\ Translate.workflow ~/Library/Services/Google\ Translate.workflow
mv ~/Desktop/tmp/Google\ Translate\ Selection.workflow ~/Library/Services/Google\ Translate\ Selection.workflow
trash ~/Desktop/tmp

git clone https://github.com/dbmrq/workflow-latexmk.git ~/Desktop/tmp
mv ~/Desktop/tmp/latexmk.workflow ~/Library/Services/latexmk.workflow
trash ~/Desktop/tmp

# }}}1

# Misc {{{1

/usr/local/bin/luarocks-5.3 install luasocket

# }}}1

echo "Remember to check Homebrew's results!"


# vim: set tw=0:

