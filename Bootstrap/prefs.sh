#!/usr/bin/env bash
#
# Set macOS preferences
# Can be run standalone or called from bootstrap.sh
#

set -euo pipefail

# --- Functions ---

# Close System Preferences/Settings to prevent conflicts
close_system_prefs() {
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
    osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
}

# Configure security settings
configure_security() {
    printf '  Configuring security settings...\n'
    # Allow apps from anywhere (requires sudo)
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        sudo spctl --master-disable 2>/dev/null || true
    fi
}

# Configure Dock settings
configure_dock() {
    printf '  Configuring Dock...\n'
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock mru-spaces -bool false
}

# Configure screenshot settings
configure_screenshots() {
    printf '  Configuring screenshots...\n'
    defaults write com.apple.screencapture disable-shadow -bool true
}

# Configure Safari settings
configure_safari() {
    printf '  Configuring Safari...\n'
    defaults write com.apple.safari ShowFullURLInSmartSearchField -bool true 2>/dev/null || true
}

# Configure Finder settings
configure_finder() {
    printf '  Configuring Finder...\n'
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
}

# Configure other app settings
configure_other_apps() {
    printf '  Configuring other apps...\n'
    defaults write com.apple.iphonesimulator ScreenShotSaveLocation -string "$HOME/Desktop" 2>/dev/null || true
    defaults write com.apple.TextEdit RichText -bool false
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    defaults write com.apple.CrashReporter DialogType -string "none"
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
}

# Configure global settings
configure_global() {
    printf '  Configuring global settings...\n'
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    defaults write -g NSServicesMinimumItemCountForContextSubmenu -int 7
}

# Restart affected apps to apply changes
restart_apps() {
    printf '  Restarting Finder and Dock...\n'
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
}

# --- Main ---
main() {
    printf 'Setting macOS preferences...\n'

    close_system_prefs
    configure_security
    configure_dock
    configure_screenshots
    configure_safari
    configure_finder
    configure_other_apps
    configure_global
    restart_apps

    printf 'Done.\n'
    printf '\n'
    printf 'Note: Some changes may require logging out and back in to take effect.\n'
}

# Only run if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
