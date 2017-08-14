#!/bin/bash

echo ""
echo "`date`: Running brew update"
/usr/local/bin/brew update

echo ""
echo "`date`: Running brew upgrade"
/usr/local/bin/brew upgrade

echo ""
echo "`date`: Running brew prune"
/usr/local/bin/brew prune

echo ""
echo "`date`: Running brew cleanup"
/usr/local/bin/brew cleanup

echo ""
echo "`date`: Running brew cask reinstall for outdated casks"
/usr/local/bin/brew cask outdated | xargs /usr/local/bin/brew cask reinstall

echo ""
echo "`date`: Running brew doctor"
/usr/local/bin/brew doctor

echo ""
echo "Fixing /Applications/ alias"


/usr/local/bin/dockutil --remove 'MacVim' --allhomes
/usr/local/bin/dockutil --add /usr/local/opt/macvim/MacVim.app --position 2


rm /Applications/MacVim

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'


terminal-notifier -title '.brewupdate.sh' -message 'Homebrew updated!' -appIcon https://brew.sh/img/homebrew-256x256.png

