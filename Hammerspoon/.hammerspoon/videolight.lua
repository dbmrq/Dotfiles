-- http://github.com/dbmrq/dotfiles/

-- Very light cream background on all screens for video calls.
-- Draws behind normal windows so apps remain visible above it.
-- Functions are exposed globally for use in the Collage menu.

local drawing = require "hs.drawing"

local overlays = {}
local watcher
local enabled = false

local presets = {
    softCream = {
        title = "Soft Cream",
        color = { red = 1.0, green = 0.985, blue = 0.95, alpha = 1.0 },
    },
    pureWhite = {
        title = "Pure White",
        color = { red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0 },
    },
    warmGlow = {
        title = "Warm Glow",
        color = { red = 1.0, green = 0.965, blue = 0.9, alpha = 1.0 },
    },
}

local currentPreset = "softCream"

local function currentPresetConfig()
    return presets[currentPreset]
end

local function clearOverlays()
    for _, overlay in pairs(overlays) do
        overlay:delete()
    end
    overlays = {}
end

local function buildOverlay(screen)
    local overlay = drawing.rectangle(screen:fullFrame())
    overlay:setFill(true)
    overlay:setFillColor(currentPresetConfig().color)
    overlay:setStroke(false)
    overlay:setBehaviorByLabels({
        "canJoinAllSpaces",
        "stationary",
        "fullScreenAuxiliary",
    })
    overlay:show()
    overlay:sendToBack()
    return overlay
end

local function refreshOverlays()
    if not enabled then return end

    clearOverlays()
    for _, screen in ipairs(hs.screen.allScreens()) do
        overlays[screen:id()] = buildOverlay(screen)
    end
end

local function startWatcher()
    if watcher then return end

    watcher = hs.screen.watcher.new(function()
        hs.timer.doAfter(0.2, refreshOverlays)
    end)
    watcher:start()
end

local function stopWatcher()
    if not watcher then return end

    watcher:stop()
    watcher = nil
end

local function notifyLightStatus(prefix)
    hs.alert.show(string.format("☀️ %s: %s", prefix, currentPresetConfig().title))
end

local function setPreset(name)
    if not presets[name] then return end

    currentPreset = name
    if enabled then
        refreshOverlays()
        notifyLightStatus("Video light")
    end
end

function videoLightOn()
    if enabled then
        refreshOverlays()
        notifyLightStatus("Video light")
        return
    end

    enabled = true
    startWatcher()
    refreshOverlays()
    notifyLightStatus("Video light on")
end

function videoLightOff()
    if not enabled then
        hs.alert.show("☀️ Video light already off")
        return
    end

    enabled = false
    clearOverlays()
    stopWatcher()
    hs.alert.show("☀️ Video light off")
end

function videoLightToggle()
    if enabled then
        videoLightOff()
    else
        videoLightOn()
    end
end

function videoLightIsOn()
    return enabled
end

function videoLightPresetSoftCream()
    setPreset("softCream")
    videoLightOn()
end

function videoLightPresetPureWhite()
    setPreset("pureWhite")
    videoLightOn()
end

function videoLightPresetWarmGlow()
    setPreset("warmGlow")
    videoLightOn()
end