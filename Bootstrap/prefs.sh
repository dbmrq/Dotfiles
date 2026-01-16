#!/usr/bin/env bash

echo "Setting macOS preferences..."

# Allow apps from anywhere
sudo spctl --master-disable

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mru-spaces -bool false

# Screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Safari
defaults write com.apple.safari ShowFullURLInSmartSearchField -bool true

# Finder
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Other apps
defaults write com.apple.iphonesimulator ScreenShotSaveLocation -string "~/Desktop"
defaults write com.apple.TextEdit RichText -bool false
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Global
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write -g NSServicesMinimumItemCountForContextSubmenu -int 7

echo "Done."
