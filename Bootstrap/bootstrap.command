#!/usr/bin/env bash
# Double-click this file to bootstrap a new Mac
cd "$(dirname "$0")" 2>/dev/null || cd ~ || exit 1
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash

