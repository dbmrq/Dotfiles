#!/bin/bash

echo ""
echo "---"

# Software update {{{1

echo ""
echo "`date`: Running softwareupdate"
softwareupdate --install --all

# }}}1

# Homebrew {{{1

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

# }}}1

# MacVim dock icon and alias {{{1

echo ""
echo "`date`: Fixing MacVim Dock icon"

/usr/local/bin/dockutil --remove 'MacVim' --allhomes
/usr/local/bin/dockutil --add /usr/local/opt/macvim/MacVim.app --position 2

echo ""
echo "`date`: Fixing MacVim alias"

/usr/local/bin/trash /Applications/MacVim

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

# }}}1

# App Store {{{1

echo ""
echo "`date`: Running mas upgrade"
/usr/local/bin/mas upgrade

# }}}1

# RubyGems {{{1

echo ""
echo "`date`: Running gem update"
/usr/local/bin/gem update —system
/usr/local/bin/gem update

# }}}1

/usr/local/bin/terminal-notifier -title '.update.sh' -message 'Software updated!' -execute 'open /tmp'

