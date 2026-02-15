local super = {"ctrl", "alt", "cmd"}

Cherry = hs.loadSpoon("Cherry")
Cherry:bindHotkeys()

-- SpoonInstall for managing Spoons from GitHub
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.dbmrq = {
    url = "https://github.com/dbmrq/Spoons",
    desc = "Personal Spoons",
}

spoon.SpoonInstall:andUse("Readline", { repo = "dbmrq", start = true })
spoon.SpoonInstall:andUse("SlowQ", { repo = "dbmrq", start = true })

-- WinMan window management
spoon.SpoonInstall:andUse("WinMan", {
    repo = "dbmrq",
    start = true,
    config = {
        modifiers = super,
    },
    fn = function(s)
        -- Use vim-style hjkl for resize, arrows for move
        s:bindHotkeys({
            resizeUp = "K",
            resizeDown = "J",
            resizeLeft = "H",
            resizeRight = "L",
            moveUp = "Up",
            moveDown = "Down",
            moveLeft = "Left",
            moveRight = "Right",
        })
    end
})

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
        s:addSubmenu("Utils", {
            { title = "Lock Keyboard for Cleaning", fn = lockKeyboard },
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

-- Type email from git config
hs.hotkey.bind(super, 'M', function()
    local email = hs.execute("git config user.email"):gsub("%s+$", "")
    if email and #email > 0 then
        hs.eventtap.keyStrokes(email)
    else
        hs.alert.show("No email found in git config")
    end
end)

-- Meta hotkeys
hs.hotkey.bind(super, 'P', function() hs.openPreferences() end)
hs.hotkey.bind(super, 'R', function() hs.reload() end)

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
