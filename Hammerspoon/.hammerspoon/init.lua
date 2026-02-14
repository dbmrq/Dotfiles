super = {"ctrl", "alt", "cmd"}

winmanHotkeys = {
    resizeUp = "K", resizeDown = "J", resizeLeft = "H", resizeRight = "L",
    showDesktop = "O", cascadeAllWindows = ",", cascadeAppWindows = ".",
    snapToGrid = "/", maximizeWindow = ";",
    moveUp = "Up", moveDown = "Down", moveLeft = "Left", moveRight = "Right"
}

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

-- Clear cached modules on reload to avoid stale hotkeys
package.loaded["winman"] = nil
package.loaded["snippets"] = nil
package.loaded["collage"] = nil
package.loaded["mocha"] = nil

require "winman"
require "snippets"
require "collage"
require "mocha"

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
