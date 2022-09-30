
-- https://github.com/dbmrq/dotfiles

super = {"ctrl", "alt", "cmd"}

winmanHotkeys = {resizeUp = "K", resizeDown = "J", resizeLeft = "H",
    resizeRight = "L", showDesktop = "O", cascadeAllWindows = ",",
    cascadeAppWindows = ".", snapToGrid = "/", maximizeWindow = ";",
    moveUp = "Up", moveDown = "Down", moveLeft = "Left", moveRight = "Right"}

Round = hs.loadSpoon("RoundedCorners")
Round.radius = 10
Round:start()
Cherry = hs.loadSpoon("Cherry")
Cherry:bindHotkeys()

require "winman"   -- Window management
require "slowq"    -- Avoid accidental Cmd-Q
-- require "cherry"   -- Tiny Pomodoro timer
require "collage"  -- Clipboard management
require "mocha"    -- Prevent Mac from sleeping
require "readline" -- Readline style bindings
-- require "vim"      -- Vim style bindings


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
        grep -o '\\d\\+\\sdays\\?' | grep -o '\\d\\+'")

    local seconds = hs.execute("uptime | \
        grep -o '\\d\\+\\ssecs\\?' | grep -o '\\d\\+'")

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

hs.hotkey.bind(super, 'M', function()
    hs.eventtap.keyStroke({"cmd"}, "c")
    local selection = hs.pasteboard.getContents()
    local subReddit = string.match(selection, '/r/(.-)/')
    hs.alert.show(subReddit)
    hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=month')
end)

hs.hotkey.bind(super, 'Y', function()
    hs.eventtap.keyStroke({"cmd"}, "c")
    local selection = hs.pasteboard.getContents()
    local subReddit = string.match(selection, '/r/(.-)/')
    hs.alert.show(subReddit)
    hs.eventtap.keyStrokes('https://www.redditp.com/r/' .. subReddit .. '/top/?t=year')
end)


-- hs.hotkey.bind(super, 'D', function()
--     local _, numero = hs.dialog.textPrompt('Quantas notas?', 'Quantas notas 10 devem ser inseridas?')
--     hs.timer.usleep(5000000)
--     for _ = tonumber(numero),0,-1 do
--             hs.eventtap.keyStrokes("10")
--             hs.eventtap.keyStroke({}, "tab")
--             hs.eventtap.keyStroke({}, "tab")
--             hs.eventtap.keyStroke({}, "tab")
--     end
--     hs.alert.show("Notas inseridas! 🥳")
-- end)

hs.hotkey.bind(super, 'M', function()
    local copiado = hs.pasteboard.getContents()
    local notas = {}
    for s in copiado:gmatch("([^\n]*)\n?") do
        -- hs.alert.show(s)
        table.insert(notas, s)
    end
    for _, nota in ipairs(notas) do
        if string.match(nota, "%d") == nil or nota == '' or tonumber(nota) == 0 then
            -- hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "space")
            hs.eventtap.keyStroke({}, "tab")
        -- elseif nota == 0 then
        --     hs.eventtap.keyStrokes(nota)
        --     hs.eventtap.keyStroke({}, "tab")
        --     hs.eventtap.keyStroke({}, "tab")
        --     hs.eventtap.keyStroke({}, "tab")
        else
            hs.eventtap.keyStrokes(nota)
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
            hs.eventtap.keyStroke({}, "tab")
        end
    end
    hs.alert.show("Notas inseridas! 🥳")
end)


