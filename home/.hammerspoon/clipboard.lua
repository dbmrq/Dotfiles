
-- http://github.com/dbmrq/dotfiles/

-- Clipboard

-- Loosely based on @victorso's Clipboard.lua
-- (https://github.com/victorso/.hammerspoon/blob/master/tools/clipboard.lua)

local historySize = 30
local menuWidth = 40

local icon = hs.menubar.new()
icon:setTooltip("Clipboard")
icon:setTitle("✂")

local pasteboard = require("hs.pasteboard")
local settings = require("hs.settings")
local lastChange = pasteboard.changeCount()

local history = settings.get("so.daniel.hs.clipboard") or {}

function clearAll()-- {{{1
    pasteboard.clearContents()
    history = {}
    settings.set("so.daniel.hs.clipboard", history)
    now = pasteboard.changeCount()
end-- }}}1

function clearLastItem()-- {{{1
    table.remove(history, #history)
    settings.set("so.daniel.hs.clipboard", history)
    now = pasteboard.changeCount()
end-- }}}1

function addToClipboard(item)-- {{{1
    -- limit quantity of entries
    while (#history >= historySize) do
        table.remove(history, 1)
    end
    table.insert(history, item)
    settings.set("so.daniel.hs.clipboard", history)
end-- }}}1

function copyOrPaste(string,key)-- {{{1
    if (key.alt == true) then
      hs.eventtap.keyStrokes(string)
    else
      pasteboard.setContents(string)
      last_change = pasteboard.changeCount()
    end
end-- }}}1

populateMenu = function(key)-- {{{1
    menuData = {}
    if (#history == 0) then
        table.insert(menuData, {title="None", disabled = true})
    else
        for k, v in pairs(history) do
            if string.len(v) > menuWidth then
                table.insert(menuData, 1,
                    {title=string.sub(v, 0, menuWidth).."…",
                    fn = function() copyOrPaste(v, key) end })
            else
                table.insert(menuData, 1,
                    {title=v, fn = function() copyOrPaste(v, key) end })
            end
        end
    end
    table.insert(menuData, {title="-"})
    table.insert(menuData,
        {title="Clear All", fn = function() clearAll() end })
    return menuData
end-- }}}1

function storeCopy()-- {{{1
    now = pasteboard.changeCount()
    if now > lastChange then
        currentContents = pasteboard.getContents()
        addToClipboard(currentContents)
        lastChange = now
    end
end-- }}}1

copy = hs.hotkey.bind({"cmd"}, "c", function()-- {{{1
    copy:disable()
    hs.eventtap.keyStroke({"cmd"}, "c")
    copy:enable()
    hs.timer.doAfter(1, storeCopy)
end)-- }}}1

icon:setMenu(populateMenu)

