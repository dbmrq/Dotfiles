
-- http://github.com/dbmrq/dotfiles/

-- Complements macOS's default Readline bindings

hs.hotkey.bind({"alt"}, 'f', function()-- {{{1
    hs.eventtap.keyStroke({"alt"}, "Right")
end)-- }}}1

hs.hotkey.bind({"alt"}, 'b', function()-- {{{1
    hs.eventtap.keyStroke({"alt"}, "Left")
end)-- }}}1

hs.hotkey.bind({"alt"}, ',', function()-- {{{1
    hs.eventtap.keyStroke({"cmd"}, "Up")
end)-- }}}1

hs.hotkey.bind({"alt"}, '.', function()-- {{{1
    hs.eventtap.keyStroke({"cmd"}, "Down")
end)-- }}}1

hs.hotkey.bind({"alt"}, 'd', function()-- {{{1
    hs.eventtap.keyStroke({"ctrl", "alt", "shift"}, "f")
    hs.eventtap.keyStroke({}, "delete")
end)-- }}}1

hs.hotkey.bind({"ctrl"}, 'w', function()-- {{{1
    hs.eventtap.keyStroke({"ctrl"}, "k")
end)-- }}}1

