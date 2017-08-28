
super = {"ctrl", "alt", "cmd"}

require "winman"   -- Window management
require "readline" -- Readline style bindings
-- require "vim"      -- Vim style bindings
-- require "clipboard"

-- Meta {{{1

hs.hotkey.bind(super, 'P', function()
  hs.openPreferences()
end)

hs.hotkey.bind(super, 'R', function()
  hs.reload()
end)

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
hs.alert.show("Hammerspoon loaded")

-- }}}1

