#!/usr/bin/env bash
#
# Set macOS preferences
# Can be run standalone or called from bootstrap.sh
#

set -euo pipefail

echo "Setting macOS preferences..."

# Close System Preferences/Settings to prevent conflicts
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# --- Security ---
echo "  Configuring security settings..."
# Allow apps from anywhere (requires sudo)
if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
    sudo spctl --master-disable 2>/dev/null || true
fi

# --- Dock ---
echo "  Configuring Dock..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mru-spaces -bool false

# --- Screenshots ---
echo "  Configuring screenshots..."
defaults write com.apple.screencapture disable-shadow -bool true

# --- Safari ---
echo "  Configuring Safari..."
defaults write com.apple.safari ShowFullURLInSmartSearchField -bool true 2>/dev/null || true

# --- Finder ---
echo "  Configuring Finder..."
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

# Icon arrangement (these may fail if plist doesn't exist yet)
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" \
    ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" \
    ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# --- Other Apps ---
echo "  Configuring other apps..."
defaults write com.apple.iphonesimulator ScreenShotSaveLocation -string "$HOME/Desktop" 2>/dev/null || true
defaults write com.apple.TextEdit RichText -bool false
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# --- Global Settings ---
echo "  Configuring global settings..."
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write -g NSServicesMinimumItemCountForContextSubmenu -int 7

# --- Restart affected apps ---
echo "  Restarting Finder and Dock..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Done."
echo ""
echo "Note: Some changes may require logging out and back in to take effect."
