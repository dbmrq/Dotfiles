
-- Complements mac OS's default Readline bindings

hs.hotkey.bind({"alt"}, 'f', function()-- {{{2
    hs.eventtap.keyStroke({"alt"}, "Right")
end)-- }}}2

hs.hotkey.bind({"alt"}, 'b', function()-- {{{2
    hs.eventtap.keyStroke({"alt"}, "Left")
end)-- }}}2

hs.hotkey.bind({"alt"}, ',', function()-- {{{2
    hs.eventtap.keyStroke({"cmd"}, "Up")
end)-- }}}2

hs.hotkey.bind({"alt"}, '.', function()-- {{{2
    hs.eventtap.keyStroke({"cmd"}, "Down")
end)-- }}}2

hs.hotkey.bind({"alt"}, 'd', function()-- {{{2
    hs.eventtap.keyStroke({"ctrl", "alt", "shift"}, "f")
    hs.eventtap.keyStroke({}, "delete")
end)-- }}}2

hs.hotkey.bind({"ctrl"}, 'w', function()-- {{{2
    hs.eventtap.keyStroke({"ctrl"}, "k")
end)-- }}}2

