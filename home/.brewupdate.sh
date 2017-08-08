#!/bin/bash

echo ""
echo "`date`: Running brew update"
brew update

echo ""
echo "`date`: Running brew upgrade"
brew upgrade

echo ""
echo "`date`: Running brew prune"
brew prune

echo ""
echo "`date`: Running brew cleanup"
brew cleanup

echo ""
echo "`date`: Running brew cask reinstall for outdated casks"
brew cask outdated | xargs brew cask reinstall

echo ""
echo "`date`: Running brew doctor"
brew doctor

echo ""
echo "Fixing /Applications/ alias"

rm /Applications/MacVim.app

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

terminal-notifier -title '.brewupdate.sh' -message 'Homebrew updated!' -appIcon https://brew.sh/img/homebrew-256x256.png

