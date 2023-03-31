
-- http://github.com/dbmrq/dotfiles/

-- Requires you to keep holding Command + Q for a while before closing an app,
-- so you won't do it accidentally.

-- Replaces apps like CommandQ and SlowQuitApps.

alertStyle = {
    strokeWidth  = 0,
    strokeColor = { white = 0, alpha = 0 },
    fillColor   = { white = 0, alpha = 0 },
    textColor = hs.drawing.color["red"],
    textFont  = "SF Pro Display Bold",
    textSize  = 200,
    radius = 0,
    atScreenEdge = 0,
    fadeInDuration = 0.15,
    fadeOutDuration = 0.15,
    padding = -50,
}


local delay = 4
local killedIt = false
local timer
local alert

function pressQ()
    killedIt = false
    timer = hs.timer.doEvery(1, tick)
    timer:fire()
end

function holdQ()
    if delay <= 0 and not killedIt then
        killedIt = true
        timer:stop()
        hs.alert.closeSpecific(alert)
        hs.application.frontmostApplication():kill()
    end
end

function releaseQ()
    killedIt = false
    timer:stop()
    delay = 4
    hs.alert.closeSpecific(alert)
end

function tick()
    hs.alert.closeSpecific(alert)
    alert = hs.alert(delay-1, alertStyle, nil, 1)
    delay = delay - 1
end

hs.hotkey.bind('cmd', 'Q', pressQ, releaseQ, holdQ)

