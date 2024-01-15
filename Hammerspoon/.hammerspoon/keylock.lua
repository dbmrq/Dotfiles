
-- http://github.com/dbmrq/dotfiles/

local alertStyle = {--  ....................................................... {{{1
    strokeWidth  = 0,
    strokeColor = { white = 0, alpha = 0 },
    fillColor   = { white = 0, alpha = 0 },
    textColor = hs.drawing.color["red"],
    textFont  = "SF Pro Display Bold",
    textSize  = 150,
    radius = 0,
    atScreenEdge = 0,
    fadeInDuration = 0.15,
    fadeOutDuration = 0.15,
    padding = -50,
}--  .................................................................... }}}1

local timer
local alert
local delay = 20

local lockMode = hs.eventtap.new(
    {"all"},
    function(event)
        return true
    end
)

function lockKeyboard()
    delay = 20
    lockMode:start()
    timer = hs.timer.doEvery(1, function()
        if delay >= 0 then
            hs.alert.closeSpecific(alert)
            alert = hs.alert('Keyboard Locked\nfor ' .. delay .. ' Seconds', alertStyle, nil, 1)
            delay = delay - 1
        else
            hs.alert.closeSpecific(alert)
            alert = hs.alert('Keyboard Unlocked', alertStyle, nil, 1)
            lockMode:stop()
            timer:stop()
        end
    end)
end

-- enterLockMode = hs.hotkey.bind({"ctrl"}, "[", lockKeyboard)

