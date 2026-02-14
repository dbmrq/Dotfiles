
-- http://github.com/dbmrq/dotfiles/

-- Readline-style keybindings for macOS
-- Complements the built-in Cocoa text bindings (C-a, C-e, C-f, C-b, C-n, C-p, C-d, C-k, C-t, C-o)

local M = {}
M.hotkeys = {}

-- Action functions {{{1
M.actions = {
    wordForward = function()
        hs.eventtap.keyStroke({"alt"}, "Right")
    end,

    wordBackward = function()
        hs.eventtap.keyStroke({"alt"}, "Left")
    end,

    wordSelectForward = function()
        hs.eventtap.keyStroke({"alt", "shift"}, "Right")
    end,

    wordSelectBackward = function()
        hs.eventtap.keyStroke({"alt", "shift"}, "Left")
    end,

    docStart = function()
        hs.eventtap.keyStroke({"cmd"}, "Up")
    end,

    docEnd = function()
        hs.eventtap.keyStroke({"cmd"}, "Down")
    end,

    deleteWordForward = function()
        hs.eventtap.keyStroke({"alt"}, "forwarddelete")
    end,

    deleteWordBackward = function()
        hs.eventtap.keyStroke({"alt"}, "delete")
    end,

    killToStart = function()
        hs.eventtap.keyStroke({"cmd", "shift"}, "Left")
        hs.eventtap.keyStroke({}, "delete")
    end,
}
-- }}}1

-- Helper to bind and track hotkeys {{{1
local function bind(mods, key, actionName)
    local fn = M.actions[actionName]
    if not fn then
        print("readline: unknown action " .. actionName)
        return
    end
    local hk = hs.hotkey.new(mods, key, fn)
    if hk then
        hk:enable()
        table.insert(M.hotkeys, hk)
    else
        print("readline: failed to create hotkey for " .. key)
    end
end
-- }}}1

-- Keybindings {{{1
bind({"alt"}, 'f', "wordForward")
bind({"alt"}, 'b', "wordBackward")
bind({"alt", "shift"}, 'f', "wordSelectForward")
bind({"alt", "shift"}, 'b', "wordSelectBackward")
bind({"alt"}, ',', "docStart")
bind({"alt"}, '.', "docEnd")
bind({"alt"}, 'd', "deleteWordForward")
bind({"ctrl"}, 'w', "deleteWordBackward")
bind({"ctrl"}, 'u', "killToStart")
-- }}}1

-- Cleanup function (useful for reloading)
function M.disable()
    for _, hk in ipairs(M.hotkeys) do
        hk:disable()
    end
end

return M
