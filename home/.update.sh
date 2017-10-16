#!/bin/bash

echo ""
echo "---"

# Software update {{{1

echo ""
echo "`date`: Running software update"
echo ""
softwareupdate --install --all

# }}}1

# Homebrew {{{1

echo ""
echo "`date`: Running brew update"
echo ""
/usr/local/bin/brew update

echo ""
echo "`date`: Running brew upgrade"
echo ""
upgraderesult=$(/usr/local/bin/brew upgrade)
if [[ "$upgraderesult" ]]; then
    echo "$upgraderesult"
fi

echo ""
echo "`date`: Running brew prune"
echo ""
/usr/local/bin/brew prune

echo ""
echo "`date`: Running brew cleanup"
echo ""
/usr/local/bin/brew cleanup

echo ""
echo "`date`: Running brew cask reinstall for outdated casks"
echo ""
/usr/local/bin/brew cask outdated | xargs /usr/local/bin/brew cask reinstall

# }}}1

# MacVim dock icon and alias {{{1

if echo "$upgraderesult" | grep -q 'macvim'; then

    echo ""
    echo "`date`: Fixing MacVim Dock icon"
    echo ""

    /usr/local/bin/dockutil --remove 'MacVim' --allhomes
    /usr/local/bin/dockutil --add /usr/local/opt/macvim/MacVim.app --position 2

    echo ""
    echo "`date`: Fixing MacVim alias"
    echo ""

    /usr/local/bin/trash /Applications/MacVim

    osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

fi

# }}}1

# App Store {{{1

echo ""
echo "`date`: Running mas upgrade"
echo ""
/usr/local/bin/mas upgrade

# }}}1

# # RubyGems {{{1

# echo ""
# echo "`date`: Running gem update"
# echo ""
# sudo gem update —-system
# sudo gem update

# # }}}1

/usr/local/bin/terminal-notifier -title '.update.sh' -message 'Software updated!' -execute 'open /tmp'

