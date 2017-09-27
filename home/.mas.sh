#!/usr/bin/env bash

brew install mas

mas signin --dialog ""

# Xcode
mas install 497799835
sudo xcodebuild -license accept

# Pages
mas install 409201541
#Numbers
mas install 409203825

