#!/usr/bin/env bash

echo ""
echo "Installilng MacVim and plugins..."
echo ""

brew install macvim --with-override-system-vim --with-luajit --with-lua --HEAD

osascript -e 'tell application "Finder" to make alias file to POSIX file "/usr/local/opt/macvim/MacVim.app" at POSIX file "/Applications/"'

mkdir -pv ~/Code/Vim

git clone https://github.com/dbmrq/vim-ditto.git ~/Code/Vim/vim-ditto
git clone https://github.com/dbmrq/vim-chalk.git ~/Code/Vim/vim-chalk
git clone https://github.com/dbmrq/vim-dialect.git ~/Code/Vim/vim-dialect
git clone https://github.com/dbmrq/vim-howdy.git ~/Code/Vim/vim-howdy

vim +Plug +qall

echo ""
echo "Done."
echo ""
echo "---"


