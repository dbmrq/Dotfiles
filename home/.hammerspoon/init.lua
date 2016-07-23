rightPosTracker = 0
leftPosTracker = 0
topPosTracker = 0
bottomPosTracker = 0

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    if leftPosTracker == 0 then
        f.x = max.x + 20
        f.y = max.y + 20
        f.w = max.w / 2 - 30
        f.h = max.h - 40
        win:setFrame(f)
        leftPosTracker = 1
    elseif leftPosTracker == 1 then
        f.x = max.x + 20
        f.y = max.y + 20
        f.w = max.w / 1.5 - 30
        f.h = max.h - 40
        win:setFrame(f)
        leftPosTracker = 2
    else
        f.x = max.x + 20
        f.y = max.y + 20
        f.w = max.w / 3 - 30
        f.h = max.h - 40
        win:setFrame(f)
        leftPosTracker = 0
    end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "L", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    if rightPosTracker == 0 then
        f.x = max.x + (max.w / 2) + 10
        f.y = max.y + 20
        f.w = max.w / 2 - 30
        f.h = max.h - 40
        win:setFrame(f)
        rightPosTracker = 1
    elseif rightPosTracker == 1 then
        f.x = max.x + (max.w / 1.5) + 10
        f.y = max.y + 20
        f.w = max.w / 3 - 30
        f.h = max.h - 40
        win:setFrame(f)
        rightPosTracker = 2
    else
        f.x = max.x + (max.w / 3) + 10
        f.y = max.y + 20
        f.w = max.w / 1.5 - 30
        f.h = max.h - 40
        win:setFrame(f)
        rightPosTracker = 0
    end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "K", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    if topPosTracker == 0 then
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + 20
        -- f.w = max.w / 2 - 30
        f.h = max.h / 2 - 30
        win:setFrame(f)
        topPosTracker = 1
    elseif topPosTracker == 1 then
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + 20
        -- f.w = max.w / 2 - 30
        f.h = max.h / 3 - 30
        win:setFrame(f)
        topPosTracker = 2
    else
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + 20
        -- f.w = max.w / 2 - 30
        f.h = max.h / 1.5 - 30
        win:setFrame(f)
        topPosTracker = 0
    end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "J", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    if bottomPosTracker == 0 then
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + (max.h / 2) + 10
        -- f.w = max.w / 2 - 30
        f.h = max.h / 2 - 30
        win:setFrame(f)
        bottomPosTracker = 1
    elseif bottomPosTracker == 1 then
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + (max.h / 1.5) + 10
        -- f.w = max.w / 2 - 30
        f.h = max.h / 3 - 30
        win:setFrame(f)
        bottomPosTracker = 2
    else
        -- f.x = max.x + (max.w / 2) + 10
        f.y = max.y + (max.h / 3) + 10
        -- f.w = max.w / 2 - 30
        f.h = max.h / 1.5 - 30
        win:setFrame(f)
        bottomPosTracker = 0
    end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, ";", function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x + 20
    f.y = max.y + 20
    f.w = max.w - 40
    f.h = max.h - 40
    win:setFrame(f)
end)


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
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")

