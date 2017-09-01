
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

function uptime()-- uptime in seconds {{{2

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

if uptime() > 300 then
    -- I don't want the alert when I turn on the computer
    hs.alert.show("Hammerspoon loaded")
end

-- }}}1

-- Slow Cmd-Q so you don't quit apps accidentally {{{1

socket = require "socket"
pressedQTime = 0

hs.hotkey.bind(
    'cmd',
    'Q',
    function()
        if socket then
            pressedQTime = socket.gettime()
        else
            pressedQTime = os.time()
        end
    end,
    nil,
    function()
        if socket then
            if pressedQTime > 0 and socket.gettime() - pressedQTime > 0.2 then
                pressedQTime = 0
                hs.application.frontmostApplication():kill()
            end
        else
            if pressedQTime > 0 and os.time() - pressedQTime > 1 then
                pressedQTime = 0
                hs.application.frontmostApplication():kill()
            end
        end
    end
)

-- }}}1

