
-- http://github.com/dbmrq/dotfiles/

-- Collage

-- Loosely based on @victorso's Clipboard.lua
-- (https://github.com/victorso/.hammerspoon/blob/master/tools/clipboard.lua)

-----------------------------
--  Customization Options  --
-----------------------------

local historySize = 30
local menuWidth = 40

-- After using this with cmd+c for a while, I thought it made more
-- sense to use cmd+x. When I'm copying something important, I like
-- to see it disappear with cmd+x, because it makes me extra sure
-- it really worked. Then if I still want it there I'll just paste
-- it back again.
local modifiers = {"cmd"}
local hotkey = "x"

-------------------------------------------------------------------
--  Don't mess with this part unless you know what you're doing  --
-------------------------------------------------------------------

local menu

local pasteboard = require("hs.pasteboard")
local settings = require("hs.settings")

local history = settings.get("so.dbmrq.hs.clipboard") or {}

function clearAll()-- {{{1
    pasteboard.clearContents()
    history = {}
    settings.set("so.dbmrq.hs.clipboard", history)
    menu:delete()
end-- }}}1

function addToClipboard(item)-- {{{1
    while #history >= historySize do table.remove(history, 1) end
    table.insert(history, item)
    settings.set("so.dbmrq.hs.clipboard", history)
end-- }}}1

populateMenu = function()-- {{{1
    menuData = {}
    if #history == 0 then
        table.insert(menuData, {title = "None", disabled = true})
        return menuData
    end
    for key, value in pairs(history) do
        title = string.len(value) > menuWidth and
            string.sub(value, 0, menuWidth) .. "…" or value
        table.insert(menuData, 1, { title = title,
            fn = function() hs.eventtap.keyStrokes(value) end })
    end
    table.insert(menuData, {title = "-"})
    table.insert(menuData,
        { title = "Clear All", fn = function() clearAll() end })
    return menuData
end-- }}}1

function storeCopy()-- {{{1
    currentContents = pasteboard.getContents()
    if currentContents == history[#history] then return end
    addToClipboard(currentContents)
    setMenu()
end-- }}}1

function setMenu()-- {{{1
    if #history > 0 then
        if not menu then
            menu = hs.menubar.new()
        end
        menu:setTooltip("Clipboard")
        menu:returnToMenuBar()
        menu:setTitle("✂")
        menu:setMenu(populateMenu)
    end
end-- }}}1

copy = hs.hotkey.bind(modifiers, hotkey, function()-- {{{1
    copy:disable()
    if table.concat(modifiers) == "cmd" and hotkey == "x" then
        hs.eventtap.keyStroke({"cmd"}, "x")
    else
        hs.eventtap.keyStroke({"cmd"}, "c")
    end
    copy:enable()
    hs.timer.doAfter(1, storeCopy)
end)-- }}}1

hs.hotkey.bind({"cmd", "shift"}, "v", function()-- {{{1
    currentContents = pasteboard.getContents()
    hs.eventtap.keyStrokes(currentContents)
end)-- }}}1

setMenu()

