
-- http://github.com/dbmrq/dotfiles/

-- Requires you to keep holding Command + Q for a while before closing an app,
-- so you won't do it accidentally.

-- Replaces apps like CommandQ and SlowQuitApps.


-----------------------------
--  Customization Options  --
-----------------------------

local delay = 0.1 -- In seconds


-------------------------------------------------------------------
--  Don't mess with this part unless you know what you're doing  --
-------------------------------------------------------------------

local killedIt = false

function pressedQ()
    killedIt = false
    hs.timer.usleep(1000000 * delay)
end

function repeatQ()
    if killedIt then return end
    killedIt = true
    print("lala")
    hs.application.frontmostApplication():kill()
end

hs.hotkey.bind('cmd', 'Q', pressedQ, nil, repeatQ)

