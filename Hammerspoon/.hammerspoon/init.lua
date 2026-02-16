local super = {"ctrl", "alt", "cmd"}

-- Enable CLI (hs command)
require("hs.ipc")

-- Keyboard layout functions for Vim integration
-- Usage from Vim: system('hs -c "getInputSource()"')
--                 system('hs -c "setInputSource(\'com.apple.keylayout.US\')"')
function getInputSource()
    return hs.keycodes.currentSourceID()
end

function setInputSource(sourceID)
    hs.keycodes.currentSourceID(sourceID)
end

-- Load Cherry (Pomodoro timer) - hotkeys moved to Collage menu
Cherry = hs.loadSpoon("Cherry")

-- SpoonInstall for managing Spoons from GitHub
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.dbmrq = {
    url = "https://github.com/dbmrq/Spoons",
    desc = "Personal Spoons",
    data = nil,  -- Force refresh of repo data
}

spoon.SpoonInstall:andUse("Readline", { repo = "dbmrq", start = true })
spoon.SpoonInstall:andUse("SlowQ", { repo = "dbmrq", start = true })

-- Load CheatSheet and WinMan from local development path
-- (Change to SpoonInstall:andUse when ready to push to GitHub)
local devSpoonsPath = os.getenv("HOME") .. "/Documents/Programação/Misc/Spoons/Source"
package.path = devSpoonsPath .. "/?.spoon/init.lua;" .. package.path

hs.loadSpoon("CheatSheet")
spoon.CheatSheet.modifiers = super
spoon.CheatSheet.delay = 0.5
-- Group related commands together in the cheat sheet
-- WinMan modal modes matching Zellij: p=pane, n=resize, h=move, t=tab/spaces
spoon.CheatSheet.keyOrder = {
    "P", "N", "H", "T",
}
spoon.CheatSheet:start()

-- WinMan window management
-- mode = "zellij" uses modal bindings (Super+p/n/h/t) matching Zellij patterns
-- mode = "simple" uses direct bindings (HJKL resize, arrows move)
hs.loadSpoon("WinMan")
spoon.WinMan.modifiers = super
spoon.WinMan.mode = "zellij"  -- Modal bindings: Super+p Focus, Super+n Resize, Super+h Move, Super+t Spaces
spoon.WinMan.gridSize = "6x6"
spoon.WinMan.gridMargins = "15,15"
spoon.WinMan.cascadeSpacing = 40
spoon.WinMan:start()

-- Clear cached modules on reload to avoid stale hotkeys
package.loaded["keylock"] = nil
package.loaded["mocha"] = nil

require "keylock"
require "mocha"

-- Custom functions for Collage submenus
local function redditTopMonth()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.doAfter(0.1, function()
        local selection = hs.pasteboard.getContents()
        local subReddit = string.match(selection, '/r/(.-)/')
        if subReddit then
            hs.alert.show(subReddit)
            hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=month')
        else
            hs.alert.show("No subreddit found in selection")
        end
    end)
end

local function redditTopYear()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.doAfter(0.1, function()
        local selection = hs.pasteboard.getContents()
        local subReddit = string.match(selection, '/r/(.-)/')
        if subReddit then
            hs.alert.show(subReddit)
            hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=year')
        else
            hs.alert.show("No subreddit found in selection")
        end
    end)
end

-- Load Collage with custom submenus (fn callback ensures Spoon is loaded first)
spoon.SpoonInstall:andUse("Collage", {
    repo = "dbmrq",
    start = true,
    fn = function(s)
        s:addSubmenu("Reddit", {
            { title = "Top of the month", fn = redditTopMonth },
            { title = "Top of the year", fn = redditTopYear },
        })
        s:addSubmenu("Caffeinate", {
            { title = "Stay Awake (until disabled)", fn = mochaTurnOn },
            { title = "30 minutes", fn = mochaFor30m },
            { title = "1 hour", fn = mochaFor60m },
            { title = "2 hours", fn = mochaFor2h },
            { title = "-" },  -- Separator
            { title = "Allow Sleep", fn = mochaTurnOff },
        })
        s:addSubmenu("Utils", {
            { title = "Lock Keyboard for Cleaning", fn = lockKeyboard },
        })
        s:addSubmenu("Hammerspoon", {
            { title = "Reload Config", fn = hs.reload },
            { title = "Open Config", fn = function()
                hs.execute("open -a 'Neovide' ~/.hammerspoon/init.lua")
            end },
            { title = "-" },
            { title = "Preferences", fn = hs.openPreferences },
            { title = "Console", fn = hs.openConsole },
        })
        s:addSubmenu("Pomodoro", {
            { title = "Start Timer", fn = function() Cherry:start() end },
        })
    end
})

-- Paste as keystrokes (bypasses paste restrictions)
hs.hotkey.bind({"cmd", "shift"}, "v", function()
    local contents = hs.pasteboard.getContents()
    if contents then
        hs.eventtap.keyStrokes(contents)
    end
end)

-- Type email from git config (no description = hidden from CheatSheet)
hs.hotkey.bind(super, 'M', function()
    local email = hs.execute("git config user.email"):gsub("%s+$", "")
    if email and #email > 0 then
        hs.eventtap.keyStrokes(email)
    else
        hs.alert.show("No email found in git config")
    end
end)

-- Note: Reload (Super+R) and Prefs (Super+P) moved to Collage > Hammerspoon submenu
-- to reduce Super+ hotkey clutter and avoid conflicts with WinMan modal bindings

-- Auto-reload on config changes
local function reloadConfig(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            break
        end
    end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

-- Show load notification (skip if just booted)
local function uptime()
    local days = hs.execute("uptime | grep -o '\\d\\+\\sdays\\?' | grep -o '\\d\\+'")
    local seconds = hs.execute("uptime | grep -o '\\d\\+\\ssecs\\?' | grep -o '\\d\\+'")

    if tonumber(days) then
        local minutes = hs.execute("uptime | awk '{print $5}' | sed -e 's/[^0-9:].*//' | sed 's/:/*60+/g' | bc")
        return (tonumber(days) or 0) * 24 * 60 * 60 + (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)
    elseif tonumber(seconds) then
        return tonumber(seconds)
    else
        local minutes = hs.execute("uptime | awk '{print $3}' | sed -e 's/[^0-9:].*//' | sed 's/:/*60+/g' | bc")
        return (tonumber(minutes) or 0) * 60
    end
end

if uptime() > 1000 then
    hs.alert.show("Hammerspoon loaded")
end
