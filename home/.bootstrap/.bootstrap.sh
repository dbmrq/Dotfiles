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
sudo xcodebuild -license accept

echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# Homebrew {{{1

/bin/bash .brew.sh

# }}}1

# MAS {{{1
osascript -e 'tell application "Terminal" to do script "source ~/.bootstrap/.mas.sh"'
# }}}1

# Preferences {{{1

# based on https://mths.be/macos

echo ""
echo "Setting preferences..."
echo ""

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

# Disable Dashboard (seems to be default now?)
# defaults write com.apple.dashboard mcx-disabled -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Set Home as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"

# Hide icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Enable snap-to-grid for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Disable automatic emoji substitution (i.e. use plain text smileys)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false


echo ""
echo "Done."
echo ""
echo "---"

# }}}1

# SF Mono {{{1

echo ""
echo "Copying SF Mono"
echo ""

cp -v /Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SFMono-* ~/Library/Fonts

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

sudo /usr/local/bin/luarocks-5.3 install luasocket

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

# LaTeX {{{1
osascript -e 'tell application "Terminal" to do script "source ~/.bootstrap/.tlmgr.sh"'
# }}}1

read -n 1 -s -r -p "A few applications require Xcode to be installed and opened once. Open Xcode now and press any key to continue."

# Swiftlint {{{1
brew install swiftlint
# }}}1

# MacVim {{{1

/bin/bash .macvim.sh

# }}}1

# Perl {{{1

# brew install perl

# PERL_MM_OPT="INSTALL_BASE=$HOME/.perl5" cpan local::lib

# sudo chown -R `whoami` ~/.perl5

cpan App::cpanminus
sudo cpanm Log::Log4perl
sudo cpanm Log::Dispatch::File
sudo cpanm YAML::Tiny
sudo cpanm File::HomeDir
sudo cpanm Unicode::GCString

# }}}1

# nltk {{{1

pip3 install nltk

ython3 -m nltk.downloader -d /usr/local/share/nltk_data punkt

# }}}1

# Dock {{{1

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array

/usr/local/bin/dockutil --add /Applications/Safari.app
/usr/local/bin/dockutil --add /usr/local/opt/macvim/MacVim.app
/usr/local/bin/dockutil --add /Applications/Utilities/Terminal.app

# }}}1


# Remove group write permissions for directories that would cause problems
# with auto completion
# rm ~/.zcompdump && compaudit && compinit
osascript -e 'tell application "Terminal" to do script "compaudit | xargs chmod g-w"'


# vim: set tw=0:

