#!/bin/bash

echo ""
echo "`date`: Running brew update"
brew update

echo ""
echo "`date`: Running brew upgrade"
brew upgrade

echo ""
echo "`date`: Running brew cleanup"
brew cleanup

echo ""
echo "`date`: Running brew cask reinstall"
brew cask outdated | xargs brew cask reinstall

