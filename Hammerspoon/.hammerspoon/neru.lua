-- Neru integration for keyboard-driven scrolling and hints
-- https://github.com/y3owk1n/neru
--
-- Keybindings (Zellij-inspired):
--   Super+S → Enter modal, then:
--     j/k = Scroll, s = Hints, g = Grid, q = Quad-Grid, Esc = Exit

local hotkey = require("hs.hotkey")
local super = super or {"ctrl", "alt", "cmd"}

local NERU_PATHS = {"/opt/homebrew/bin/neru", "/usr/local/bin/neru"}

local function findNeru()
    for _, path in ipairs(NERU_PATHS) do
        if hs.fs.attributes(path) then return path end
    end
    if hs.fs.attributes("/Applications/Neru.app") then
        return "/Applications/Neru.app/Contents/MacOS/neru"
    end
    return nil
end

local neruPath = findNeru()

local function neruCmd(cmd)
    if neruPath then hs.execute(neruPath .. " " .. cmd, true) end
end

-- Modal with CheatSheet integration
local neruModal = hotkey.modal.new()

local hints = {
    {"j/k", "Scroll"}, {"s", "Hints"}, {"g", "Grid"},
    {"q", "Quad-Grid"}, {"Esc", "Exit"},
}

function neruModal:entered()
    if spoon.CheatSheet and spoon.CheatSheet.showModeHints then
        spoon.CheatSheet:showModeHints("Scroll", hints)
    end
end

function neruModal:exited()
    if spoon.CheatSheet and spoon.CheatSheet.hideModeHints then
        spoon.CheatSheet:hideModeHints()
    end
end

-- Helper to bind key that exits modal and runs neru command
local function bindNeruKey(key, cmd)
    neruModal:bind({}, key, function()
        neruModal:exit()
        neruCmd(cmd)
    end)
end

neruModal:bind({}, "escape", function() neruModal:exit() end)
neruModal:bind({}, "return", function() neruModal:exit() end)

bindNeruKey("j", "scroll")
bindNeruKey("k", "scroll")
bindNeruKey("s", "hints")
bindNeruKey("g", "grid")
bindNeruKey("q", "quadgrid")

if neruPath then
    hs.hotkey.bind(super, "S", "Scroll Mode", function() neruModal:enter() end)
end
