---------------------
--  Reload config  --
---------------------

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

hs.pathwatcher.new(os.getenv("HOME") ..
    "/.hammerspoon/", reloadConfig):start()
hs.pathwatcher.new(os.getenv("HOME") ..
    ".homesick/repos/dotfiles/home/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")


--------------------------
--  Window positioning  --
--------------------------

local hotkey = require "hs.hotkey"
local super = {"ctrl", "alt", "cmd"}

local grid = require "hs.grid"

grid.setMargins('20,20')
grid.setGrid('4x4')


local function snapToBottom(win, cell, screen)
    local newCell =
        hs.geometry(cell.x, grid.GRIDHEIGHT - cell.h, cell.w, cell.h)
    grid.set(win, newCell, screen)
end

local function snapToTop(win, cell, screen)
    local newCell =
        hs.geometry(cell.x, 0, cell.w, cell.h)
    grid.set(win, newCell, screen)
end

local function snapToLeft(win, cell, screen)
    local newCell =
        hs.geometry(0, cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end

local function snapToRight(win, cell, screen)
    local newCell =
        hs.geometry(grid.GRIDWIDTH - cell.w, cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end

local function compensateMargins()
    -- Compensate for the double margin between windows
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local frame = win:frame()
    if cell.h < grid.GRIDHEIGHT and cell.h % 1 == 0 then
        if cell.y == 0 then
            frame.h = frame.h + grid.MARGINX / 2
            win:setFrame(frame)
        else
            frame.h = frame.h + grid.MARGINY / 2
            frame.y = frame.y - grid.MARGINY / 2
            win:setFrame(frame)
        end
    end
    if cell.w < grid.GRIDWIDTH and cell.w % 1 == 0 then
        if cell.x == 0 then
            frame.w = frame.w + grid.MARGINY / 2
            win:setFrame(frame)
        else
            frame.w = frame.w + grid.MARGINY / 2
            frame.x = frame.x - grid.MARGINY / 2
            win:setFrame(frame)
        end
    end
end


hotkey.bind(super, ';', grid.maximizeWindow)

hs.hotkey.bind(super, 'Left', function()
    grid.pushWindowLeft()
    compensateMargins()
end)

hs.hotkey.bind(super, 'Down', function()
    grid.pushWindowDown()
    compensateMargins()
end)
hs.hotkey.bind(super, 'Up', function()
    grid.pushWindowUp()
    compensateMargins()
end)
hs.hotkey.bind(super, 'Right', function()
    grid.pushWindowRight()
    compensateMargins()
end)

hotkey.bind(super, 'J', function()
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y < grid.GRIDHEIGHT - cell.h and cell.h % 1 == 0 then
        snapToBottom(win, cell, screen)
        compensateMargins()
        return
    elseif cell.h % 1 ~= 0 then
        snapToBottom(win, cell, screen)
        grid.snap(win)
        compensateMargins()
        return
    end
    if cell.h <= 1 then
        growing = true
    elseif cell.h >= grid.GRIDHEIGHT then
        growing = false
    end
    if growing then
        grid.resizeWindowTaller()
    else
        grid.resizeWindowShorter()
    end
    local cell = grid.get(win)
    snapToBottom(win, cell, screen)
    compensateMargins()
end)

hotkey.bind(super, 'K', function()
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y > 0 and cell.h % 1 == 0 then
        snapToTop(win, cell, screen)
        compensateMargins()
        return
    elseif cell.h % 1 ~= 0 then
        snapToTop(win, cell, screen)
        grid.snap(win)
        compensateMargins()
        return
    end
    if cell.h <= 1 then
        growing = true
    elseif cell.h >= grid.GRIDHEIGHT then
        growing = false
    end
    if growing then
        grid.resizeWindowTaller()
    else
        grid.resizeWindowShorter()
    end
    local cell = grid.get(win)
    snapToTop(win, cell, screen)
    compensateMargins()
end)

hotkey.bind(super, 'H', function()
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x > 0 and cell.w % 1 == 0 then
        snapToLeft(win, cell, screen)
        compensateMargins()
        return
    elseif cell.w % 1 ~= 0 then
        snapToLeft(win, cell, screen)
        grid.snap(win)
        compensateMargins()
        return
    end
    if cell.w <= 1 then
        growing = true
    elseif cell.w >= grid.GRIDWIDTH then
        growing = false
    end
    if growing then
        grid.resizeWindowWider()
    else
        grid.resizeWindowThinner()
    end
    local cell = grid.get(win)
    snapToLeft(win, cell, screen)
    compensateMargins()
end)

hotkey.bind(super, 'L', function()
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x < grid.GRIDWIDTH - cell.w and cell.w % 1 == 0 then
        snapToRight(win, cell, screen)
        compensateMargins()
        return
    elseif cell.w % 1 ~= 0 then
        snapToRight(win, cell, screen)
        grid.snap(win)
        compensateMargins()
        return
    end
    if cell.w <= 1 then
        growing = true
    elseif cell.w >= grid.GRIDWIDTH then
        growing = false
    end
    if growing then
        grid.resizeWindowWider()
    else
        grid.resizeWindowThinner()
    end
    local cell = grid.get(win)
    snapToRight(win, cell, screen)
    compensateMargins()
end)

