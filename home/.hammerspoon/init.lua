
super = {"ctrl", "alt", "cmd"}

require "nightshift"
require "clipboard"
require "winman"   -- Window management
require "vim"      -- Vim style bindings
require "readline" -- Readline style bindings

-- Personal bindings {{{1

-- Safari {{{2

safariAddressBar = hs.hotkey.bind({"shift"}, ';', function()---- {{{3
    local app = hs.application.frontmostApplication():name()
    local element = hs.uielement.focusedElement():role()
    if app == "Safari" and not string.find(element, "Text") then
        hs.eventtap.keyStroke({"cmd"}, "l")
    else
        hs.eventtap.keyStrokes(':')
    end
end)-- }}}3

safariSearch = hs.hotkey.bind({}, '/', function()---- {{{3
    local app = hs.application.frontmostApplication():name()
    local element = hs.uielement.focusedElement():role()
    if app == "Safari" and not string.find(element, "Text") then
        hs.eventtap.keyStroke({"cmd"}, "f")
    else
        hs.eventtap.keyStrokes('/')
    end
end)-- }}}3

safariFocusPage = hs.hotkey.bind({'ctrl'}, 'c', function()---- {{{3
    local app = hs.application.frontmostApplication():name()
    if app == "Safari" then
        hs.eventtap.keyStroke({}, "escape")
        hs.eventtap.keyStroke({"shift"}, "tab")
        local element = hs.uielement.focusedElement():role()
        local i = 0
        while string.find(element, "Button") and i <= 10 do
            hs.eventtap.keyStroke({}, "escape")
            hs.eventtap.keyStroke({"shift"}, "tab")
            print(element)
            element = hs.uielement.focusedElement():role()
            i = i + 1
        end
    end
end)-- }}}3

hs.window.filter.new('Safari')-- {{{3
    :subscribe(hs.window.filter.windowFocused,function()
        safariAddressBar:enable()
        safariSearch:enable()
        safariFocusPage:enable()
    end)
    :subscribe(hs.window.filter.windowUnfocused,function()
        safariAddressBar:disable()
        safariSearch:disable()
        safariFocusPage:disable()
    end)-- }}}3

-- }}}2

-- -- For debugging {{{2

-- hs.hotkey.bind({}, '.', function()
--     local element = hs.uielement.focusedElement():role()
--     hs.alert.show(element)
-- end)

-- hs.hotkey.bind({"ctrl"}, '.', function()
--     hs.screen.restoreGamma()
-- end)

-- -- }}}2

-- }}}1

-- Reload config {{{1

function reloadConfig(files)---- {{{2
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            break
        end
    end
end-- }}}2

hs.pathwatcher.new(os.getenv("HOME") ..
    "/.hammerspoon/", reloadConfig):start()
hs.pathwatcher.new(os.getenv("HOME") ..
    ".homesick/repos/dotfiles/home/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")

-- }}}1

