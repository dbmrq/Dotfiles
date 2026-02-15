
-- http://github.com/dbmrq/dotfiles/

-- Prevent your computer from going to sleep


-----------------------------
--  Customization Options  --
-----------------------------

-- Use the modifiers + hotkey to prevent your computer from sleeping. Click
-- the menu bar icon to allow it to sleep again.
local modifiers = {"ctrl", "alt", "cmd"}
local hotkey = "M"


-------------------------------------------------------------------
--  Don't mess with this part unless you know what you're doing  --
-------------------------------------------------------------------

local caf = require "hs.caffeinate"

local menu

local function enable()
    caf.set("displayIdle", true, true)
    caf.set("systemIdle", true, true)
    caf.set("system", true, true)
    if not menu then
        menu = hs.menubar.new()
    end
    menu:returnToMenuBar()
    menu:setTitle("☕️")
    menu:setTooltip("Mocha")
    menu:setClickCallback(function() disable() end)
end

function disable()
    caf.set("displayIdle", false, false)
    caf.set("systemIdle", false, false)
    caf.set("system", false, false)
    menu:delete()
end

hs.hotkey.bind(modifiers, hotkey, "Keep Awake (Mocha)", function() enable() end)

