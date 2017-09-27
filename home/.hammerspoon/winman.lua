
-- http://github.com/dbmrq/dotfiles/

-- Window management

local grid = require "hs.grid"
grid.setMargins('20,20')
grid.setGrid('6x6')

local hsVersion = hs.processInfo["version"]:gsub('%.', '')
hsVersion = tonumber(hsVersion)

-- hs.window.animationDuration = 0

-- Helper functions {{{1

-- Keep windows anchored at the bottom {{{2
local function snapToBottom(win, cell, screen)
    local newCell = hs.geometry(cell.x, grid.GRIDHEIGHT - cell.h,
                                cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}2

-- Keep windows anchored at the top {{{2
local function snapToTop(win, cell, screen)
    local newCell = hs.geometry(cell.x, 0, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}2

-- Keep windows anchored to the left {{{2
local function snapLeft(win, cell, screen)
    local newCell = hs.geometry(0, cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}2

-- Keep windows anchored to the right {{{2
local function snapRight(win, cell, screen)
    local newCell = hs.geometry(grid.GRIDWIDTH - cell.w,
                                cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}2

-- Compensate for the double margin between windows {{{2
local function compensateMargins(window)
    if hsVersion >= 0956 then
        -- This has been fixed in version 0.9.56
        return
    end
    local win = window or hs.window.focusedWindow()
    local cell = grid.get(win)
    local frame = win:frame()
    if cell.h < grid.GRIDHEIGHT and cell.h % 1 == 0 then
        if cell.y ~= 0 then
            frame.h = frame.h + grid.MARGINY / 2
            frame.y = frame.y - grid.MARGINY / 2
            win:setFrame(frame)
        end
        if cell.y + cell.h ~= grid.GRIDHEIGHT then
            frame.h = frame.h + grid.MARGINX / 2
            win:setFrame(frame)
        end
    end
    if cell.w < grid.GRIDWIDTH and cell.w % 1 == 0 then
        if cell.x ~= 0 then
            frame.w = frame.w + grid.MARGINY / 2
            frame.x = frame.x - grid.MARGINY / 2
            win:setFrame(frame)
        end
        if cell.x + cell.w ~= grid.GRIDWIDTH then
            frame.w = frame.w + grid.MARGINY / 2
            win:setFrame(frame)
        end
    end
end-- }}}2

-- -- Hide Finder's sidebar when the window is too narrow {{{2
-- -- I used this with a 4x4 grid. It's not as useful with 6x6.
-- function resizeFinderW(cell)
--     local app = hs.application.frontmostApplication()
--     if app:name() == "Finder" then
--         if cell.w == 2 and not grow then
--             app:selectMenuItem({"Visualizar", "Ocultar Barra Lateral"})
--             -- app:selectMenuItem({"View", "Hide Sidebar"}) -- In english
--         else
--             app:selectMenuItem({"Visualizar", "Mostrar Barra Lateral"})
--             -- app:selectMenuItem({"View", "Show Sidebar"}) -- In english
--         end
--     end
-- end-- }}}2

-- -- Hide Finder's toolbar when the window is too short {{{2
-- -- I used this with a 4x4 grid. It's not as useful with 6x6.
-- function resizeFinderH(cell)
--     local app = hs.application.frontmostApplication()
--     if app:name() == "Finder" then
--         if cell.h == 2 and not grow then
--             app:selectMenuItem({"Visualizar", "Ocultar Barra de Ferramentas"})
--             -- app:selectMenuItem({"View", "Hide Toolbar"})
--             app:selectMenuItem({"Visualizar", "Ocultar Barra de Estado"})
--             -- app:selectMenuItem({"View", "Hide Status Bar"})
--         else
--             app:selectMenuItem({"Visualizar", "Mostrar Barra de Ferramentas"})
--             -- app:selectMenuItem({"View", "Show Status Bar"})
--             app:selectMenuItem({"Visualizar", "Mostrar Barra de Estado"})
--             -- app:selectMenuItem({"View", "Show Status Bar"})
--         end
--     end
-- end-- }}}2

-- }}}1

-- Bindings {{{1

-- Move windows {{{2

hs.hotkey.bind(super, 'Up', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    if cell.y == 0 then
        return
    end
    if cell.h == 3 then
        grid.pushWindowUp()
        grid.pushWindowUp()
        grid.pushWindowUp()
    else
        grid.pushWindowUp()
        grid.pushWindowUp()
    end
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'Down', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    if cell.y + cell.h >= grid.GRIDHEIGHT then
        return
    end
    if cell.h == 3 then
        grid.pushWindowDown()
        grid.pushWindowDown()
        grid.pushWindowDown()
    else
        grid.pushWindowDown()
        grid.pushWindowDown()
    end
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'Left', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    if cell.x == 0 then
        return
    end
    if cell.w == 3 then
        grid.pushWindowLeft()
        grid.pushWindowLeft()
        grid.pushWindowLeft()
    else
        grid.pushWindowLeft()
        grid.pushWindowLeft()
    end
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'Right', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    if cell.x + cell.w >= grid.GRIDWIDTH then
        return
    end
    if cell.w == 3 then
        grid.pushWindowRight()
        grid.pushWindowRight()
        grid.pushWindowRight()
    else
        grid.pushWindowRight()
        grid.pushWindowRight()
    end
    compensateMargins()
end)-- }}}3

-- }}}2

-- Resize windows {{{2

hs.hotkey.bind(super, ';', grid.maximizeWindow)

hs.hotkey.bind(super, 'J', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y < grid.GRIDHEIGHT - cell.h then
        snapToBottom(win, cell, screen)
        compensateMargins()
        return
    end
    if cell.h <= 2 then
        grow = true
    elseif cell.h >= grid.GRIDHEIGHT then
        grow = false
    end
    -- resizeFinderH(cell)
    if grow and cell.h >= 4 then
        grid.resizeWindowTaller()
        grid.resizeWindowTaller()
    elseif grow then
        grid.resizeWindowTaller()
    elseif cell.h >= 6 then
        grid.resizeWindowShorter()
        grid.resizeWindowShorter()
    else
        grid.resizeWindowShorter()
    end
    local cell = grid.get(win)
    snapToBottom(win, cell, screen)
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'K', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y > 0 then
        snapToTop(win, cell, screen)
        compensateMargins()
        return
    end
    if cell.h <= 2 then
        grow = true
    elseif cell.h >= grid.GRIDHEIGHT then
        grow = false
    end
    -- resizeFinderH(cell)
    if grow and cell.h >= 4 then
        grid.resizeWindowTaller()
        grid.resizeWindowTaller()
    elseif grow then
        grid.resizeWindowTaller()
    elseif cell.h >= 6 then
        grid.resizeWindowShorter()
        grid.resizeWindowShorter()
    else
        grid.resizeWindowShorter()
    end
    local cell = grid.get(win)
    snapToTop(win, cell, screen)
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'H', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x > 0 then
        snapLeft(win, cell, screen)
        compensateMargins()
        return
    end
    if cell.w <= 2 then
        grow = true
    elseif cell.w >= grid.GRIDWIDTH then
        grow = false
    end
    -- resizeFinderW(cell)
    if grow and cell.w >= 4 then
        grid.resizeWindowWider()
        grid.resizeWindowWider()
    elseif grow then
        grid.resizeWindowWider()
    elseif cell.w >= 6 then
        grid.resizeWindowThinner()
        grid.resizeWindowThinner()
    else
        grid.resizeWindowThinner()
    end
    local cell = grid.get(win)
    snapLeft(win, cell, screen)
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'L', function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x < grid.GRIDWIDTH - cell.w then
        snapRight(win, cell, screen)
        compensateMargins()
        return
    end
    if cell.w <= 2 then
        grow = true
    elseif cell.w >= grid.GRIDWIDTH then
        grow = false
    end
    -- resizeFinderW(cell)
    if grow and cell.w >= 4 then
        grid.resizeWindowWider()
        grid.resizeWindowWider()
    elseif grow then
        grid.resizeWindowWider()
    elseif cell.w >= 6 then
        grid.resizeWindowThinner()
        grid.resizeWindowThinner()
    else
        grid.resizeWindowThinner()
    end
    local cell = grid.get(win)
    snapRight(win, cell, screen)
    compensateMargins()
end)-- }}}3

hs.hotkey.bind(super, 'M', function()-- {{{3
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    local newCell = hs.geometry(1, 0, grid.GRIDWIDTH - 2, grid.GRIDHEIGHT)
    grid.set(win, newCell, screen)
end)-- }}}3

-- Show and hide a stripe of Desktop {{{3
hs.hotkey.bind(super, 'O', function()
    local windows = hs.window.visibleWindows()
    local finished = false
    for i in pairs(windows) do
        local window = windows[i]
        local frame = window:frame()
        local desktop = hs.window.desktop():frame()
        if frame.x + frame.w > desktop.w - 120 and frame ~= desktop then
            frame.w = desktop.w - frame.x - 120
            window:setFrame(frame)
            finished = true
        end
    end
    if finished then return end
    for i in pairs(windows) do
        local window = windows[i]
        local frame = window:frame()
        local desktop = hs.window.desktop():frame()
        if frame.x + frame.w == desktop.w - 120 then
            frame.w = frame.w + 100
            window:setFrame(frame)
        end
    end
end)-- }}}3

-- }}}2

-- Snap {{{2

hs.hotkey.bind(super, '.', function()
    local windows = hs.window.visibleWindows()
    for i in pairs(windows) do
        local window = windows[i]
        grid.snap(window)
        compensateMargins(window)
    end
end)

-- }}}2

-- }}}1

