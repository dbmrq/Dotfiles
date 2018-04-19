#!/usr/bin/env bash

if ! osascript -e "id of application \"Hammerspoon\"" >/dev/null; then
    # If Hammerspoon isn't installed

    if ! hash brew 2>/dev/null; then
        # If Homebrew isn't installed
        echo -e "\nInstalling Homebrew..."
        /usr/bin/ruby -e "$(curl -fsSL https://goo.gl/p2uJdM)"
    else
        echo -e "\nHomebrew already installed. Moving on..."
    fi

    if ! brew cask --version &>/dev/null; then
        # If Homebrew-Cask isn't tapped
        echo -e "\nTapping Homebrew-Cask..."
        brew tap caskroom/cask
    else
        echo -e "\nHomebrew-Cask already tapped. Moving on..."
    fi

    echo -e "\nInstalling Hammerspoon..."
    brew cask install hammerspoon

else
    echo -e "\nHammerspoon already installed. Moving on..."
fi


mkdir -p ~/.hammerspoon


echo -e "\nCopying files..."
curl -L https://goo.gl/BUfggH \
    --output ~/.hammerspoon/winman.lua >/dev/null 2>&1
curl -L https://goo.gl/DWMPPd \
    --output ~/.hammerspoon/slowq.lua >/dev/null 2>&1
curl -L https://goo.gl/Bs45UY \
    --output ~/.hammerspoon/cherry.lua >/dev/null 2>&1
curl -L https://goo.gl/Wa3QuJ \
    --output ~/.hammerspoon/collage.lua >/dev/null 2>&1
curl -L https://goo.gl/JeEW68 \
    --output ~/.hammerspoon/mocha.lua >/dev/null 2>&1


echo -e "\nModifying ~/.hammerspoon/init.lua"

if [ ! -f ~/.hammerspoon/init.lua ]; then
    touch ~/.hammerspoon/init.lua
fi


if ! grep -q "https://github.com/dbmrq/dotfiles" ~/.hammerspoon/init.lua; then
cat <<EOT >> ~/.hammerspoon/init.lua

---------------------------------------
-- https://github.com/dbmrq/dotfiles --
---------------------------------------

-- Features are used with super + hotkey. You can uncomment these lines to
-- change the keyboard shortcuts according to your preferences:

-- super = {"ctrl", "alt", "cmd"}

-- cherryHotkey = "C"

-- mochaHotkey = "M"

-- winmanHotkeys = {
--     resizeUp           = "Up",    -- Resize keeping it at the top
--     resizeDown         = "Down",  -- Resize keeping it at the bottom
--     resizeLeft         = "Left",  -- Resize window keeping it left
--     resizeRight        = "Right", -- Resize window keeping it right
--     showDesktop        = "O",     -- Show a stripe of the desktop
--     cascadeAllWindows  = ",",     -- Cascade all windows
--     cascadeAppWindows  = ".",     -- Cascade for current application
--     snapToGrid         = "/",     -- Snap windows to the grid
--     maximizeWindow     = ";",     -- Expand window to take up whole grid

--     -- Only useful if you plan on using more than 2 windows per column/row:
--     -- moveUp    = "Up",    -- Move window up one cell
--     -- moveDown  = "Down",  -- Move window down one cell
--     -- moveLeft  = "Left",  -- Move window left one cell
--     -- moveRight = "Right", -- Move window right one cell
-- }

-- By default, collage uses Command + Shift + C. Uncomment this and set it to
-- true if you want everything you copy with Command + C to go into the menu:

-- collageByDefault = false

-- (All these options must go before the "require" statements.)

EOT
fi


if ! grep -q "require \"winman\"" ~/.hammerspoon/init.lua; then
    echo -e "\nrequiring winman.lua"
    echo "require \"winman\"   -- Window management" >> \
        ~/.hammerspoon/init.lua
else
    echo -e "\nwinman.lua already required. Moving on..."
fi

if ! grep -q "require \"slowq\"" ~/.hammerspoon/init.lua; then
    echo -e "\nrequiring slowq.lua"
    echo "require \"slowq\"    -- Avoid accidental Cmd-Q" >> \
        ~/.hammerspoon/init.lua
else
    echo -e "\nslowq.lua already required. Moving on..."
fi

if ! grep -q "require \"cherry\"" ~/.hammerspoon/init.lua; then
    echo -e "\nrequiring cherry.lua"
    echo "require \"cherry\"   -- Tiny Pomodoro timer" >> \
        ~/.hammerspoon/init.lua
else
    echo -e "\ncherry.lua already required. Moving on..."
fi

if ! grep -q "require \"collage\"" ~/.hammerspoon/init.lua; then
    echo -e "\nrequiring collage.lua"
    echo "require \"collage\"  -- Clipboard management" >> \
        ~/.hammerspoon/init.lua
else
    echo -e "\ncollage.lua already required. Moving on..."
fi

if ! grep -q "require \"mocha\"" ~/.hammerspoon/init.lua; then
    echo -e "\nrequiring mocha.lua"
    echo "require \"mocha\"    -- Prevent Mac from sleeping" >> \
        ~/.hammerspoon/init.lua
else
    echo -e "\nmocha.lua already required. Moving on..."
fi

echo -e "\nDONE!"

echo -e "\nCheck your ~/.hammerspoon directory to see what's new!"

echo -e "\nIf this is the first time you install Hammerspoon, don't forget to
open it and follow the instructions to allow Accessibility access.\n"

read -n 1 -s -r -p "Press any key to quit."

