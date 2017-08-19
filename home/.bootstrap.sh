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
# defaults write com.apple.dock persistent-apps -array

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
brew install macvim --with-override-system-vim --with-luajit --HEAD
osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

brew tap caskroom/cask
brew cask install vlc
brew cask install java
brew cask install calibre
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
homesick symlink dotfiles

sudo chown root:admin ~/.update.sh
sudo chmod 4775 ~/.update.sh
sudo chown root:admin ~/Library/LaunchAgents/com.dbmrq.update.plist
sudo launchctl load ~/Library/LaunchAgents/com.dbmrq.update.plist

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

# Vim plugins {{{1

echo ""
echo "Installilng Vim plugins..."
echo ""

mkdir -pv ~/Code/Vim

git clone https://github.com/dbmrq/vim-ditto ~/Code/Vim/vim-ditto
git clone https://github.com/dbmrq/vim-chalk ~/Code/Vim/vim-chalk
git clone https://github.com/dbmrq/vim-dialect ~/Code/Vim/vim-dialect
git clone https://github.com/dbmrq/vim-howdy ~/Code/Vim/vim-howdy

vim +Plug +qall

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# TeX {{{1

echo ""
echo "Installing tex packages"
echo ""

sudo tlmgr update --self --all

sudo tlmgr install scheme-medium collection-humanities collection-langgreek \
collection-langother collection-latexextra collection-pictures logreq \
biblatex biber biblatex-abnt abntex2

mkdir -pv ~/Code/LaTeX/Bibliography
mkdir -pv ~/Code/LaTeX/Classes
mkdir -pv ~/Code/LaTeX/Packages

ln -s ~/Code/LaTeX/Classes ~/Library/texmf/tex/latex/classes
ln -s ~/Code/LaTeX/Packages ~/Library/texmf/tex/latex/packages
ln -s ~/Code/LaTeX/Bibliography ~/Library/texmf/bibtex/bib

git clone https://github.com/dbmrq/dbmrq.cls ~/Code/LaTeX/Classes/dbmrq
git clone https://github.com/dbmrq/tex-sensible ~/Code/LaTeX/Packages/sensible
git clone https://github.com/abntex/biblatex-abnt ~/Code/LaTeX/Packages/biblatex-abnt

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# MAS {{{1

mas signin --dialog ""

# Xcode
mas install 497799835
# Pages
mas install 409201541
#Numbers
mas install 409203825

# }}}1

# Terminal colorscheme {{{1

echo ""
echo "Adding Terminal color schemes..."
echo ""

open ~/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Dark.terminal

open ~/.homesick/repos/dotfiles/home/Library/Colors/Solarized\ Light.terminal

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

echo "Remember to check Homebrew's results!"

