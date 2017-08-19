#!/bin/bash

softwareupdate --install --all

# Homebrew {{{1

/usr/local/bin/brew update

/usr/local/bin/brew upgrade

/usr/local/bin/brew prune

/usr/local/bin/brew cleanup

/usr/local/bin/brew cask outdated | xargs /usr/local/bin/brew cask reinstall

/usr/local/bin/brew doctor

# }}}1

# MacVim icon {{{1

/usr/local/bin/dockutil --remove 'MacVim' --allhomes
/usr/local/bin/dockutil --add /usr/local/opt/macvim/MacVim.app --position 2

/usr/local/bin/trash /Applications/MacVim

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

# }}}1

# App Store {{{1

/usr/local/bin/mas upgrade

# }}}1

# RubyGems {{{1

/usr/local/bin/gem update —system
/usr/local/bin/gem update

# }}}1

/usr/local/bin/terminal-notifier -title '.brewupdate.sh' -message 'Software updated!'

