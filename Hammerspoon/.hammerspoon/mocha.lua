-- http://github.com/dbmrq/dotfiles/

-- Prevent your computer from going to sleep
-- Functions are exposed globally for use in Collage submenu

local caf = require "hs.caffeinate"

local menu
local timer

local function showMenu(duration)
    if not menu then
        menu = hs.menubar.new()
    end
    menu:returnToMenuBar()
    if duration then
        local mins = math.floor(duration / 60)
        menu:setTitle("☕️ " .. mins .. "m")
        menu:setTooltip("Mocha - " .. mins .. " minutes remaining")
    else
        menu:setTitle("☕️")
        menu:setTooltip("Mocha - Click to disable")
    end
    menu:setClickCallback(function() mochaTurnOff() end)
end

local function enableCaffeinate()
    caf.set("displayIdle", true, true)
    caf.set("systemIdle", true, true)
    caf.set("system", true, true)
end

local function disableCaffeinate()
    caf.set("displayIdle", false, false)
    caf.set("systemIdle", false, false)
    caf.set("system", false, false)
end

-- Turn off caffeinate and clean up
function mochaTurnOff()
    if timer then
        timer:stop()
        timer = nil
    end
    disableCaffeinate()
    if menu then
        menu:delete()
        menu = nil
    end
    hs.alert.show("☕️ Sleep allowed")
end

-- Keep awake indefinitely
function mochaTurnOn()
    if timer then timer:stop(); timer = nil end
    enableCaffeinate()
    showMenu(nil)
    hs.alert.show("☕️ Staying awake")
end

-- Keep awake for a specific duration (in seconds)
function mochaFor(seconds)
    if timer then timer:stop() end
    enableCaffeinate()
    showMenu(seconds)
    hs.alert.show("☕️ Staying awake for " .. math.floor(seconds / 60) .. " minutes")

    local remaining = seconds
    timer = hs.timer.doEvery(60, function()
        remaining = remaining - 60
        if remaining <= 0 then
            mochaTurnOff()
        else
            showMenu(remaining)
        end
    end)
end

-- Convenience functions for common durations
function mochaFor30m() mochaFor(30 * 60) end
function mochaFor60m() mochaFor(60 * 60) end
function mochaFor2h() mochaFor(2 * 60 * 60) end

