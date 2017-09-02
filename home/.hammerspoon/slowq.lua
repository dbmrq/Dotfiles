
-- Slow Cmd-Q so you don't quit apps accidentally. Replaces apps like CommandQ
-- and SlowQuitApps. This works better if you have luasocket, which has to be
-- installed with Lua 5.3 to work with Hammerspoon.

socket = require "socket"

pressedQTime = 0

hs.hotkey.bind('cmd', 'Q',
    function()
        if socket then
            pressedQTime = socket.gettime()
        else
            pressedQTime = os.time()
        end
    end, nil,
    function()
        if socket then
            if pressedQTime > 0 and socket.gettime() - pressedQTime > 0.2 then
                pressedQTime = 0
                hs.application.frontmostApplication():kill()
            end
        else
            if pressedQTime > 0 and os.time() - pressedQTime > 0 then
                pressedQTime = 0
                hs.application.frontmostApplication():kill()
            end
        end
    end
)

