
-- http://github.com/dbmrq/dotfiles/

-- Window management


-----------------------------
--  Customization Options  --
-----------------------------

-- The keyboard shortcuts are composed of the `super` modifiers + each of the
-- hotkeys below. You can change the hotkeys to whatever you prefer. The most
-- important are the `resize*` hotkeys, so you may find it easier to set them
-- to the arrow keys (`"Up"`, `"Down"`, etc.). The `move*` hotkeys are only
-- useful if you plan on using more than 2 windows per column/row, so you can
-- just comment them out.

-- UPDATE: Since the latest version, I set the arrow keys as the default and
-- added an option to customize the shortcuts without making changes to this
-- file. Just create the `super` and `winmanHotkeys` tables in your `init.lua`
-- file before `require "winman"` (notice that they have to be global
-- variables, without the `local` keyword). If you prefer you can still just
-- edit this file, though.

local super = super or {"ctrl", "alt", "cmd"}

local hotkeys = winmanHotkeys or {
    resizeUp           = "Up", -- "K", -- Resize window keeping it at the top
    resizeDown         = "Down", -- "J", -- Resize keeping it at the bottom
    resizeLeft         = "Left", -- "H", -- Resize window keeping it left
    resizeRight        = "Right", -- "L", -- Resize window keeping it right
    showDesktop        = "O", -- Show a stripe of the desktop
    cascadeAllWindows  = ",", -- Cascade all windows
    cascadeAppWindows  = ".", -- Cascade windows for the current application
    snapToGrid         = "/", -- Snap windows to the grid
    maximizeWindow     = ";", -- Expand current window to take up whole grid

    -- Only useful if you plan on using more than two windows per column/row:
    -- moveUp = "Up", -- Move window up one cell
    -- moveDown = "Down", -- Move window down one cell
    -- moveLeft = "Left", -- Move window left one cell
    -- moveRight = "Right", -- Move window right one cell
}

local cascadeSpacing = 40 -- the visible margin for each window
                          -- set to 0 to disable cascading


-------------------------------------------------------------------
--  Don't mess with this part unless you know what you're doing  --
-------------------------------------------------------------------

-- Setup {{{1

local grid = require "hs.grid"
grid.setMargins('20,20')
grid.setGrid('6x6')

local hsVersion = hs.processInfo["version"]:gsub('%.', '')
hsVersion = tonumber(hsVersion)

-- hs.window.animationDuration = 0

-- }}}1

-- Helper functions {{{1

-- Keep windows anchored when resizing {{{2

local function snapToBottom(win, cell, screen)-- {{{3
    local newCell = hs.geometry(cell.x, grid.GRIDHEIGHT - cell.h,
                                cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}3

local function snapToTop(win, cell, screen)-- {{{3
    local newCell = hs.geometry(cell.x, 0, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}3

local function snapLeft(win, cell, screen)-- {{{3
    local newCell = hs.geometry(0, cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}3

local function snapRight(win, cell, screen)-- {{{3
    local newCell = hs.geometry(grid.GRIDWIDTH - cell.w,
                                cell.y, cell.w, cell.h)
    grid.set(win, newCell, screen)
end-- }}}3

-- }}}2

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

-- Cascade windows {{{2

function cascade(windows)-- {{{3
    if #windows <= 1 or cascadeSpacing == 0 then
        return
    end
    local frame = largestFrame(windows)

    local nOfSpaces = #windows - 1

    for i, win in ipairs(windows) do
        local offset = (i - 1) * cascadeSpacing
        local rect = {
            x = frame.x + offset,
            y = frame.y + offset,
            w = frame.w - (nOfSpaces * cascadeSpacing),
            h = frame.h - (nOfSpaces * cascadeSpacing),
        }
        win:setFrame(rect)
    end
    local frame = largestFrame(windows)
end-- }}}3

function cascadeOverlappingWindows(secondPass)-- {{{3
    if cascadeSpacing == 0 then return end
    local allWindows = hs.window.allWindows()
    local cascadedWindows = {}
    local needsSecondPass = false
    for i, win in ipairs(allWindows) do
        local title = win:application():title()
        if title == "Terminal" or title == "MacVim" then
            needsSecondPass = true
        end
        if not cascadedWindows[win:id()] then
            local currentCascading = cascadeWindowsOverlapping(win)
            for x, cascadedWin in ipairs(currentCascading) do
                cascadedWindows[cascadedWin:id()] = true
            end
        end
    end
    -- Some windows take longer to resize and won't be overlapping when this
    -- is first called, so we call it again after one second. Right now I'm
    -- just doing it for MacVim and Terminal.app, but you can add others in
    -- the check up there.
    if needsSecondPass and not secondPass then
        hs.timer.doAfter(1, function() cascadeOverlappingWindows(true) end)
    end
end-- }}}3

function cascadeWindowsOverlapping(winA)-- {{{3
    if cascadeSpacing == 0 then return end
    local windows = hs.window.allWindows()
    local overlappingWindows = { winA }
    local frameA = winA:frame()
    for i, winB in ipairs(windows) do
        local frameB = winB:frame()
        if winA:id() ~= winB:id() and overlaps(frameA, frameB) and
            areCascaded(frameA, frameB) then
                table.insert(overlappingWindows, winB)
        end
    end
    cascade(overlappingWindows)
    return overlappingWindows
end-- }}}3

-- }}}2

-- Check for overlapping {{{2

function xOverlaps(frameA, frameB)-- {{{3
    local frameAMaxX = maxX(frameA)
    local frameBMaxX = maxX(frameB)
    if frameA.x >= frameB.x and frameA.x <= frameBMaxX then
        return true
    end
    if frameAMaxX >= frameB.x and frameAMaxX <= frameBMaxX then
        return true
    end
    return false
end-- }}}3

function yOverlaps(frameA, frameB)-- {{{3
    local frameAMaxY = maxY(frameA)
    local frameBMaxY = maxY(frameB)
    if frameA.y >= frameB.y and frameA.y <= frameBMaxY then
        return true
    end
    if frameAMaxY >= frameB.y and frameAMaxY <= frameBMaxY then
        return true
    end
    return false
end-- }}}3

function overlaps(frameA, frameB)-- {{{3
    return xOverlaps(frameA, frameB) and yOverlaps(frameA, frameB)
end-- }}}3

-- }}}2

-- function areWithinTolerance(frameA, frameB, tolerance)-- {{{2
--     return math.abs(frameA.w - frameB.w) < tolerance and
--             math.abs(frameA.h - frameB.h) <tolerance
-- end-- }}}2

function areCascaded(frameA, frameB)-- {{{2
    return math.abs(frameA.w - frameB.w) % cascadeSpacing == 0 and
            math.abs(frameA.h - frameB.h) % cascadeSpacing == 0 and
            math.abs(frameA.x - frameB.x) % cascadeSpacing == 0 and
            math.abs(frameA.y - frameB.y) % cascadeSpacing == 0

end-- }}}2

function maxX(frame)-- {{{2
    return frame.x + frame.w
end-- }}}2

function maxY(win)-- {{{2
    return win.y + win.h
end-- }}}2

function largestFrame(windows)-- {{{2
    local screen = windows[1]:screen():frame()
    local minX = screen.w
    local minY = screen.h
    local maxX = 0
    local maxY = 0
    for i, win in ipairs(windows) do
        local winFrame = win:frame()
        if winFrame.x < minX then
            minX = winFrame.x
        end
        if winFrame.y < minY then
            minY = winFrame.y
        end
    end
    for i, win in ipairs(windows) do
        local winFrame = win:frame()
        local winX = winFrame.x + winFrame.w
        local winY = winFrame.y + winFrame.h
        if winX > maxX then
            maxX = winX
        end
        if winY > maxY then
            maxY = winY
        end
    end
    local width = maxX - minX
    local height = maxY - minY
    return {x = minX, y = minY, w = width, h = height}
end-- }}}2

function getKeys(oldTable)-- {{{2
    local newTable = {}
    for key, value in pairs(oldTable) do
        table.insert(newTable, key)
    end
    return newTable
end-- }}}2

-- }}}1

-- Bindings {{{1

-- Move windows {{{2

if hotkeys["moveUp"] then-- {{{3
    hs.hotkey.bind(super, hotkeys["moveUp"], function()
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
        cascadeOverlappingWindows()
    end)
end-- }}}3

if hotkeys["moveDown"] then-- {{{3
    hs.hotkey.bind(super, hotkeys["moveDown"], function()
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
        cascadeOverlappingWindows()
    end)
end-- }}}3

if hotkeys["moveLeft"] then-- {{{3
    hs.hotkey.bind(super, hotkeys["moveLeft"], function()
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
        cascadeOverlappingWindows()
    end)
end-- }}}3

if hotkeys["moveRight"] then-- {{{3
    hs.hotkey.bind(super, hotkeys["moveRight"], function()
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
        cascadeOverlappingWindows()
    end)
end-- }}}3

-- }}}2

-- Resize windows {{{2

hs.hotkey.bind(super, hotkeys["maximizeWindow"], grid.maximizeWindow)

hs.hotkey.bind(super, hotkeys["resizeDown"], function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y < grid.GRIDHEIGHT - cell.h then
        snapToBottom(win, cell, screen)
        compensateMargins()
        cascadeOverlappingWindows()
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
    cascadeOverlappingWindows()
end)-- }}}3

hs.hotkey.bind(super, hotkeys["resizeUp"], function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.y > 0 then
        snapToTop(win, cell, screen)
        compensateMargins()
        cascadeOverlappingWindows()
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
    cascadeOverlappingWindows()
end)-- }}}3

hs.hotkey.bind(super, hotkeys["resizeLeft"], function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x > 0 then
        snapLeft(win, cell, screen)
        compensateMargins()
        cascadeOverlappingWindows()
        return
    end
    if cell.w <= 2 then
        grow = true
    elseif cell.w >= grid.GRIDWIDTH then
        grow = false
    end
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
    cascadeOverlappingWindows()
end)-- }}}3

hs.hotkey.bind(super, hotkeys["resizeRight"], function()-- {{{3
    local win = hs.window.focusedWindow()
    local cell = grid.get(win)
    local screen = win:screen()
    if cell.x < grid.GRIDWIDTH - cell.w then
        snapRight(win, cell, screen)
        compensateMargins()
        cascadeOverlappingWindows()
        return
    end
    if cell.w <= 2 then
        grow = true
    elseif cell.w >= grid.GRIDWIDTH then
        grow = false
    end
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
    cascadeOverlappingWindows()
end)-- }}}3

-- }}}2

-- Show and hide a stripe of Desktop {{{2
hs.hotkey.bind(super, hotkeys["showDesktop"], function()
    local windows = hs.window.visibleWindows()
    local finished = false
    for i in pairs(windows) do
        local window = windows[i]
        local frame = window:frame()
        local desktop = hs.window.desktop():frame()
        if frame.x + frame.w > desktop.w - 128 and frame ~= desktop then
            frame.w = desktop.w - frame.x - 128
            window:setFrame(frame)
            finished = true
        end
    end
    if finished then return end
    for i in pairs(windows) do
        local window = windows[i]
        local frame = window:frame()
        local desktop = hs.window.desktop():frame()
        if frame.x + frame.w == desktop.w - 128 then
            frame.w = frame.w + 108
            window:setFrame(frame)
        end
    end
end)-- }}}2

-- Snap windows {{{2

hs.hotkey.bind(super, hotkeys["snapToGrid"], function()
    local windows = hs.window.visibleWindows()
    for i in pairs(windows) do
        local window = windows[i]
        grid.snap(window)
        compensateMargins(window)
    end
    -- cascadeOverlappingWindows()
end)

-- }}}2

-- Cascade windows {{{2

hs.hotkey.bind(super, hotkeys["cascadeAllWindows"], function()
    if cascadeSpacing == 0 then return end
    local windows = hs.window.orderedWindows()
    local screen = windows[1]:screen():frame()
    local nOfSpaces = #windows - 1

    local xMargin = screen.w / 10 -- unused horizontal margin
    local yMargin = 20            -- unused vertical margin

    for i, win in ipairs(windows) do
        local offset = (i - 1) * cascadeSpacing
        local rect = {
            x = xMargin + offset,
            y = screen.y + yMargin + offset,
            w = screen.w - (2 * xMargin) - (nOfSpaces * cascadeSpacing),
            h = screen.h - (2 * yMargin) - (nOfSpaces * cascadeSpacing),
        }
        win:setFrame(rect)
    end
end)

-- }}}2

-- Cascade windows for current app {{{2

hs.hotkey.bind(super, hotkeys["cascadeAppWindows"], function()
    if cascadeSpacing == 0 then return end
    local windows = hs.window.orderedWindows()
    local focusedApp = hs.window.focusedWindow():application()
    local appWindows = {}
    for i, window in ipairs(windows) do
        if window:application() == focusedApp then
            table.insert(appWindows, window)
        end
    end
    local screen = appWindows[1]:screen():frame()
    local nOfSpaces = #appWindows - 1

    local xMargin = screen.w / 10 -- unused horizontal margin
    local yMargin = 20            -- unused vertical margin

    for i, win in ipairs(appWindows) do
        local offset = (i - 1) * cascadeSpacing
        local rect = {
            x = xMargin + offset,
            y = screen.y + yMargin + offset,
            w = screen.w - (2 * xMargin) - (nOfSpaces * cascadeSpacing),
            h = screen.h - (2 * yMargin) - (nOfSpaces * cascadeSpacing),
        }
        win:setFrame(rect)
    end
end)

-- }}}2

-- }}}1

