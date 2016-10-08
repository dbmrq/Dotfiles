
-- Vim style modal bindings

-- Normal mode {{{1

local normal = hs.hotkey.modal.new()

-- I don't remap <esc> because it's just too risky
enterNormal = hs.hotkey.bind({"ctrl"}, "[", function()
    normal:enter()
    hs.alert.show('Normal mode')
end)

-- Movements {{{2

function left() hs.eventtap.keyStroke({}, "Left") end
normal:bind({}, 'h', left, nil, left)
function right() hs.eventtap.keyStroke({}, "Right") end
normal:bind({}, 'l', right, nil, right)
function up() hs.eventtap.keyStroke({}, "Up") end
normal:bind({}, 'k', up, nil, up)
function down() hs.eventtap.keyStroke({}, "Down") end
normal:bind({}, 'j', down, nil, down)
function word() hs.eventtap.keyStroke({"alt"}, "Right") end
normal:bind({}, 'w', word, nil, word)
function back() hs.eventtap.keyStroke({"alt"}, "Left") end
normal:bind({}, 'b', back, nil, back)


normal:bind({}, '0', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Left")
end)-- }}}3

normal:bind({"shift"}, 'h', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Left")
end)-- }}}3

normal:bind({"shift"}, '4', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Right")
end)-- }}}3

normal:bind({"shift"}, 'l', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Right")
end)-- }}}3

normal:bind({}, 'g', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Up")
end)-- }}}3

normal:bind({"shift"}, 'g', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Down")
end)-- }}}3

-- }}}2

-- Insert {{{2

normal:bind({}, 'i', function()-- {{{3
    normal:exit()
    hs.alert.show('Insert mode')
end)-- }}}3

normal:bind({"shift"}, 'i', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Left")
    normal:exit()
    hs.alert.show('Insert mode')
end)-- }}}3

normal:bind({}, 'a', function()-- {{{3
    hs.eventtap.keyStroke({}, "Right")
    normal:exit()
    hs.alert.show('Insert mode')
end)-- }}}3

normal:bind({"shift"}, 'a', function()-- {{{3
    hs.eventtap.keyStroke({"cmd"}, "Right")
    normal:exit()
    hs.alert.show('Insert mode')
end)-- }}}3

normal:bind({}, 'o', nil, function()-- {{{3
    local app = hs.application.frontmostApplication()
    if app:name() == "Finder" then
        hs.eventtap.keyStroke({"cmd"}, "o")
    else
        hs.eventtap.keyStroke({"cmd"}, "Right")
        normal:exit()
        hs.eventtap.keyStroke({}, "Return")
        hs.alert.show('Insert mode')
    end
end)-- }}}3

normal:bind({"shift"}, 'o', nil, function()-- {{{3
    local app = hs.application.frontmostApplication()
    if app:name() == "Finder" then
        hs.eventtap.keyStroke({"cmd", "shift"}, "o")
    else
        hs.eventtap.keyStroke({"cmd"}, "Left")
        normal:exit()
        hs.eventtap.keyStroke({}, "Return")
        hs.eventtap.keyStroke({}, "Up")
        hs.alert.show('Insert mode')
    end
end)-- }}}3

-- }}}2

-- Delete {{{2

local function delete()
    hs.eventtap.keyStroke({}, "delete")
end
normal:bind({}, 'd', delete, nil, delete)

local function fndelete()
    hs.eventtap.keyStroke({}, "Right")
    hs.eventtap.keyStroke({}, "delete")
end
normal:bind({}, 'x', fndelete, nil, fndelete)

-- }}}2

normal:bind({"shift"}, ';', function()-- {{{2
    local app = hs.application.frontmostApplication()
    if app:name() == "Safari" then
        hs.eventtap.keyStroke({"cmd"}, "l") -- go to address bar
    else
        hs.eventtap.keyStroke({"ctrl"}, "space") -- call Alfred
    end
end)-- }}}2

-- Shortcat {{{2
normal:bind({}, 'f', function()
    normal:exit()
    hs.alert.show('Insert mode')
    hs.eventtap.keyStroke({"alt"}, "space")
end)

normal:bind({}, 's', function()
    normal:exit()
    hs.alert.show('Insert mode')
    hs.eventtap.keyStroke({"alt"}, "space")
end)
-- }}}2

normal:bind({}, '/', function() hs.eventtap.keyStroke({"cmd"}, "f") end)

normal:bind({}, 'u', function()-- {{{2
    hs.eventtap.keyStroke({"cmd"}, "z")
end)-- }}}2

normal:bind({"ctrl"}, 'r', function()-- {{{2
    hs.eventtap.keyStroke({"cmd", "shift"}, "z")
end)-- }}}2

normal:bind({}, 'y', function()-- {{{2
    hs.eventtap.keyStroke({"cmd"}, "c")
end)-- }}}2

normal:bind({}, 'p', function()-- {{{2
    hs.eventtap.keyStroke({"cmd"}, "v")
end)-- }}}2

-- }}}1

-- Visual mode {{{1

local visual = hs.hotkey.modal.new()

normal:bind({}, 'v', function() visual:enter() end)

visual:bind({"ctrl"}, '[', function()-- {{{2
    visual:exit()
    hs.eventtap.keyStroke({}, "Right")
    hs.alert.show('Normal mode')
end)-- }}}2

function visual:entered() hs.alert.show('Visual mode') end

-- Movements {{{2

function vleft() hs.eventtap.keyStroke({"shift"}, "Left") end
visual:bind({}, 'h', vleft, nil, vleft)
function vright() hs.eventtap.keyStroke({"shift"}, "Right") end
visual:bind({}, 'l', vright, nil, vright)
function vup() hs.eventtap.keyStroke({"shift"}, "Up") end
visual:bind({}, 'k', vup, nil, vup)
function vdown() hs.eventtap.keyStroke({"shift"}, "Down") end
visual:bind({}, 'j', vdown, nil, vdown)

visual:bind({}, '0', function()-- {{{3
    hs.eventtap.keyStroke({"cmd", "shift"}, "Left")
end)-- }}}3

visual:bind({"shift"}, 'h', function()-- {{{3
    hs.eventtap.keyStroke({"cmd", "shift"}, "Left")
end)-- }}}3

visual:bind({"shift"}, '4', function()-- {{{3
    hs.eventtap.keyStroke({"cmd", "shift"}, "Right")
end)-- }}}3

visual:bind({"shift"}, 'l', function()-- {{{3
    hs.eventtap.keyStroke({"cmd", "shift"}, "Right")
end)-- }}}3


-- }}}2

-- }}}1

hs.window.filter.new('MacVim')-- {{{1
    :subscribe(hs.window.filter.windowFocused,function()
        normal:exit()
        enterNormal:disable()
    end)
    :subscribe(hs.window.filter.windowUnfocused,function()
        enterNormal:enable()
    end)-- }}}1

hs.window.filter.new('Terminal')-- {{{1
    :subscribe(hs.window.filter.windowFocused,function()
        normal:exit()
        enterNormal:disable()
    end)
    :subscribe(hs.window.filter.windowUnfocused,function()
        enterNormal:enable()
    end)-- }}}1

