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

# # Trackpad {{{2

# # Trackpad: enable tap to click for this user and for the login screen
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# # }}}2

# # Screenshots {{{2

# # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
# defaults write com.apple.screencapture type -string "png"

# # Disable shadow in screenshots
# defaults write com.apple.screencapture disable-shadow -bool true

# # }}}2

# # Finder {{{2

# # Finder: disable window animations and Get Info animations
# # defaults write com.apple.finder DisableAllAnimations -bool true

# # Keep folders on top when sorting by name
# # defaults write com.apple.finder _FXSortFoldersFirst -bool true

# # When performing a search, search the current folder by default
# defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# # Use column view in all Finder windows by default
# # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`, 'Nlsv'
# defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# # Show the ~/Library folder
# chflags nohidden ~/Library

# # Show the /Volumes folder
# # sudo chflags nohidden /Volumes

# # }}}2

# Misc {{{2

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Restart automatically if the computer freezes
# sudo systemsetup -setrestartfreeze on

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Prevent Time Machine from prompting to use new hard drives as backup volume
# defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Automatically quit printer app once the print jobs complete
# defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
# defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
# defaults write com.apple.CrashReporter DialogType -string "none"

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array
killall Dock

# }}}2

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
brew install tree
brew install ruby
brew install fasd
brew install trash
brew install luajit
brew install cscope
brew install pandoc
brew install python
brew install python3
brew install thefuck
brew install dockutil
brew install carthage
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

echo "Remember to check Homebrew's results!"


# vim: set tw=0:

