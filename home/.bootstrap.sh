#!/usr/bin/env bash

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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

# }}}2

# }}}1

# Xcode {{{1

echo "Installing xcode-select..."

if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? 'Install XCode Command Line Tools'

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Point the `xcode-select` developer directory to
    # the appropriate directory from within `Xcode.app`
    # https://github.com/alrra/dotfiles/issues/13

    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
    print_result $? 'Make "xcode-select" developer directory point to Xcode'

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'

fi

# }}}1

# Homebrew {{{1

echo "Installing Homebrew and formulae..."

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew tap caskroom/cask

brew install zsh zsh-completions
brew install bash

brew install lua
brew install ruby
brew install luajit
brew install cscope

brew install vim --with-override-system-vi --with-python --with-cscope --with-lua --with-luajit

brew install git

brew install trash

brew cask install hammerspoon

brew cask install google-chrome
brew cask install firefox

brew cleanup

# }}}1

# Prezto {{{1

echo "Installing Prezto..."

git clone https://github.com/sorin-ionescu/prezto.git ~/Desktop/.zprezto
rsync -a ~/Desktop/.zprezto ~/
trash ~/Desktop/.zprezto

# }}}1

# Homesick {{{1

echo "Installing Homesick..."

gem install homesick
homesick clone dbmrq/dotfiles
homesick symlink dotfiles
homesick rc dotfiles

# }}}1

# Terminal colorscheme {{{1

open /Users/daniel/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Dark.terminal

open /Users/daniel/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Light.terminal

# }}}1

