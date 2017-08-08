#!/usr/bin/env bash

osascript -e 'tell application "System Preferences" to quit'

sudo -v

while true; do sudo -n true; sleep 60; \
    kill -0 "$$" || exit; done 2>/dev/null &

# Software update {{{1

sudo softwareupdate -i -a

# }}}1

# Preferences {{{1

# based on https://mths.be/macos

echo "Setting preferences..."

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
# defaults write com.apple.dock persistent-apps -array

# }}}2

# }}}1

# Install SF Mono {{{1
cp -v /Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SFMono-* ~/Library/Fonts
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
brew install tree
brew install ruby
brew install luajit
brew install cscope
brew install pandoc
brew install python
brew install python3
brew install thefuck
brew install carthage
brew install trash
brew install fasd
brew install zsh
brew install curl --with-openssl
brew install macvim --with-override-system-vim --with-luajit --HEAD
osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

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
brew cask install basictex

sudo chown -R $(whoami):admin /usr/local
sudo chmod -R g+rwx /usr/local
# Unfortunately this seems to be necessary for now, since we can't run `brew`
# as root and otherwise `brew prune` won't be able to do its thing.

brew cleanup
brew prune

# }}}1

# Prezto {{{1

echo "Installing Prezto..."

git clone --recursive -j8 https://github.com/sorin-ionescu/prezto.git ~/.zprezto

# }}}1

# Homesick {{{1

echo "Installing Homesick..."

mkdir -p ~/.vim/backup ~/.vim/swp ~/.vim/undo

sudo gem install homesick
homesick clone dbmrq/dotfiles
homesick symlink dotfiles

sudo chmod +x ~/.tlmgr.sh
sudo chown root ~/.brewupdate.sh
sudo chmod 4755 ~/.brewupdate.sh
sudo chown root ~/Library/LaunchAgents/com.dbmrq.brewupdate.plist
sudo launchctl load ~/Library/LaunchAgents/com.dbmrq.brewupdate.plist

# }}}1

# Change Shell {{{1

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

# }}}1

# Add gitignore {{{1

git config --global core.excludesfile '~/.gitignore'

# }}}1

# Vim plugins {{{1

echo "Installilng Vim plugins..."

vim +Plug +qall

# }}}1

# TeX packages {{{1

sudo tlmgr update --self --all

sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
collection-langother collection-latexextra collection-pictures logreq \
biblatex biber biblatex-abnt abntex2

# }}}1

# Terminal colorscheme {{{1

echo "Adding Terminal color schemes..."

open ~/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Dark.terminal

open ~/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Light.terminal

# }}}1

echo "Remember to check Homebrew's results!"

