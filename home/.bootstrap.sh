#!/usr/bin/env bash

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Software update {{{1

sudo softwareupdate -i -a

# }}}1

# Preferences {{{1

# inspired by https://mths.be/macos

echo "Setting preferences..."

# Trackpad {{{2

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# }}}2

# Screenshots {{{2

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# }}}2

# Finder {{{2

# Finder: disable window animations and Get Info animations
# defaults write com.apple.finder DisableAllAnimations -bool true

# Keep folders on top when sorting by name
# defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`, 'Nlsv'
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
# sudo chflags nohidden /Volumes

# }}}2

# Misc {{{2

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

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

# }}}2

# }}}1

# Xcode {{{1

echo "Installing xcode-select..."

xcode-select --install

# }}}1

# Homebrew {{{1

echo "Installing Homebrew and formulae..."

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git
brew install lua
brew install ruby
brew install luajit
brew install cscope
brew install carthage
brew install trash
brew install fasd
brew install zsh
brew install curl --with-openssl
brew install vim --with-override-system-vi --with-python --with-cscope --with-lua --with-luajit

brew tap caskroom/cask
brew cask install java
brew cask install hammerspoon
brew cask install google-chrome
brew cask install firefox
brew cask install transmission
brew cask install appcleaner
brew cask install the-unarchiver
brew cask install calibre
brew cask install vlc

brew linkapps

brew cleanup

# }}}1

# Prezto {{{1

echo "Installing Prezto..."

git clone https://github.com/sorin-ionescu/prezto.git ~/.zprezto

# }}}1

# Homesick {{{1

echo "Installing Homesick..."

gem install homesick
homesick clone dbmrq/dotfiles
homesick symlink dotfiles
homesick rc dotfiles

# }}}1

# Change Shell {{{1

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

# }}}1

# Terminal colorscheme {{{1

echo "Adding Terminal color schemes..."

open /Users/daniel/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Dark.terminal

open /Users/daniel/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Light.terminal

# }}}1

echo "Remember to check Homebrew's results for aditional instructions!"

