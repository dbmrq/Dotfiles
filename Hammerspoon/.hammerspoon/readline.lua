
-- http://github.com/dbmrq/dotfiles/

-- Readline-style keybindings for macOS
-- Complements the built-in Cocoa text bindings (C-a, C-e, C-f, C-b, C-n, C-p, C-d, C-k, C-t, C-o)

-- Word movement (M-f, M-b) {{{1
hs.hotkey.bind({"alt"}, 'f', function()
    hs.eventtap.keyStroke({"alt"}, "Right")
end)

hs.hotkey.bind({"alt"}, 'b', function()
    hs.eventtap.keyStroke({"alt"}, "Left")
end)
-- }}}1

-- Word selection with shift (M-F, M-B) {{{1
hs.hotkey.bind({"alt", "shift"}, 'f', function()
    hs.eventtap.keyStroke({"alt", "shift"}, "Right")
end)

hs.hotkey.bind({"alt", "shift"}, 'b', function()
    hs.eventtap.keyStroke({"alt", "shift"}, "Left")
end)
-- }}}1

-- Document navigation (M-<, M->) {{{1
-- Using Alt-, and Alt-. as proxies for Alt-< and Alt->
hs.hotkey.bind({"alt"}, ',', function()
    hs.eventtap.keyStroke({"cmd"}, "Up")
end)

hs.hotkey.bind({"alt"}, '.', function()
    hs.eventtap.keyStroke({"cmd"}, "Down")
end)
-- }}}1

-- Delete word forward (M-d) {{{1
hs.hotkey.bind({"alt"}, 'd', function()
    hs.eventtap.keyStroke({"alt"}, "forwarddelete")
end)
-- }}}1

-- Delete word backward (M-Backspace, C-w) {{{1
-- Alt-Backspace is standard Readline for delete-word-backward
hs.hotkey.bind({"alt"}, 'delete', function()
    hs.eventtap.keyStroke({"alt"}, "delete")
end)

-- Ctrl-w is unix-word-rubout (delete word backward)
hs.hotkey.bind({"ctrl"}, 'w', function()
    hs.eventtap.keyStroke({"alt"}, "delete")
end)
-- }}}1

-- Kill line (C-u) - kill from cursor to beginning of line {{{1
-- macOS doesn't have this by default, only C-k (kill to end)
hs.hotkey.bind({"ctrl"}, 'u', function()
    hs.eventtap.keyStroke({"cmd", "shift"}, "Left")
    hs.eventtap.keyStroke({}, "delete")
end)
-- }}}1

