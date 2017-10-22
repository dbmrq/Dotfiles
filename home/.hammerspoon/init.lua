
super = {"ctrl", "alt", "cmd"}

require "slowq"    -- Avoid accidental cmd-Q
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

function uptime()---- {{{2

    local days = hs.execute("uptime | \
        grep -o '\\d\\+\\sdays' | grep -o '\\d\\+'")

    local seconds = hs.execute("uptime | \
        grep -o '\\d\\+\\ssecs' | grep -o '\\d\\+'")

    if tonumber(days) then
        local minutes = hs.execute("uptime | awk '{print $5}' | \
                sed -e 's/[^0-9:].*//' | sed 's/:/*60+/g' | bc")
        local minutes = tonumber(minutes) or 0
        local seconds = tonumber(seconds) or 0
        local days = tonumber(days) or 0
        return (days * 24 * 60 + minutes) * 60 + seconds
    elseif tonumber(seconds) then
        return tonumber(seconds)
    else
        local minutes = hs.execute("uptime | awk '{print $3}' | \
            sed -e 's/[^0-9:].*//' | sed 's/:/*60+/g' | bc")
        local minutes = tonumber(minutes) or 0
        return minutes * 60
    end

end-- }}}2

hs.pathwatcher.new(os.getenv("HOME") ..
    "/.hammerspoon/", reloadConfig):start()
hs.pathwatcher.new(os.getenv("HOME") ..
    ".homesick/repos/dotfiles/home/.hammerspoon/", reloadConfig):start()

if uptime() > 1000 then
-- I don't want the alert when I have just turned on the computer
    hs.alert.show("Hammerspoon loaded")
end

-- }}}1

