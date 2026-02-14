-- Readline bindings test suite
-- Usage:
--   require("readline_test").runAll()       -- Run unit tests (verify keystrokes sent)
--   require("readline_test").runE2E()       -- Run e2e tests in TextEdit
--   require("readline_test").checkHotkeys() -- Verify hotkeys are registered
--   require("readline_test").list()         -- List available tests

local M = {}

-- Test state
local testResults = {}

-- Helper: wait for UI to settle
local function wait(seconds)
    hs.timer.usleep(seconds * 1000000)
end

-- Get readline module
local function getReadline()
    local readline = package.loaded["readline"]
    if not readline or not readline.actions then
        print("❌ readline module not loaded or has no actions table")
        print("   Try reloading Hammerspoon first")
        return nil
    end
    return readline
end

--------------------------------------------------------------------------------
-- Unit Tests: Verify each action sends the correct keystrokes (via mocking)
--------------------------------------------------------------------------------

-- Capture keystrokes by mocking hs.eventtap.keyStroke
local function captureKeystrokes(fn)
    local captured = {}
    local originalKeyStroke = hs.eventtap.keyStroke

    hs.eventtap.keyStroke = function(mods, key)
        local modFlags = {}
        for _, mod in ipairs(mods or {}) do
            modFlags[mod] = true
        end
        table.insert(captured, {mods = modFlags, key = key})
    end

    fn()

    hs.eventtap.keyStroke = originalKeyStroke
    return captured
end

-- Format captured keystrokes for display
local function formatKeystrokes(captured)
    local parts = {}
    for _, ks in ipairs(captured) do
        local modStr = ""
        if ks.mods.alt then modStr = modStr .. "⌥" end
        if ks.mods.cmd then modStr = modStr .. "⌘" end
        if ks.mods.ctrl then modStr = modStr .. "⌃" end
        if ks.mods.shift then modStr = modStr .. "⇧" end
        table.insert(parts, modStr .. ks.key)
    end
    return table.concat(parts, ", ")
end

-- Check if captured keystrokes match expected
local function keystrokesMatch(captured, expectedMods, expectedKey)
    if #captured ~= 1 then return false end
    local ks = captured[1]
    if ks.key:lower() ~= expectedKey:lower() then return false end
    for _, mod in ipairs(expectedMods) do
        if mod == "alt" and not ks.mods.alt then return false end
        if mod == "cmd" and not ks.mods.cmd then return false end
        if mod == "ctrl" and not ks.mods.ctrl then return false end
        if mod == "shift" and not ks.mods.shift then return false end
    end
    return true
end

-- Check if captured has multiple keystrokes matching a sequence
local function keystrokeSequenceMatches(captured, expectedSeq)
    if #captured ~= #expectedSeq then return false end
    for i, expected in ipairs(expectedSeq) do
        if not keystrokesMatch({captured[i]}, expected.mods, expected.key) then
            return false
        end
    end
    return true
end

-- Record test result
local function recordResult(name, passed, expected, actual)
    table.insert(testResults, {
        name = name,
        passed = passed,
        expected = expected,
        actual = actual
    })
    if passed then
        print("✅ " .. name)
    else
        print("❌ " .. name)
        print("   Expected: " .. tostring(expected))
        print("   Actual:   " .. tostring(actual))
    end
end

-- Unit test definitions
local unitTests = {
    {name = "wordForward", expectedMods = {"alt"}, expectedKey = "right"},
    {name = "wordBackward", expectedMods = {"alt"}, expectedKey = "left"},
    {name = "wordSelectForward", expectedMods = {"alt", "shift"}, expectedKey = "right"},
    {name = "wordSelectBackward", expectedMods = {"alt", "shift"}, expectedKey = "left"},
    {name = "docStart", expectedMods = {"cmd"}, expectedKey = "up"},
    {name = "docEnd", expectedMods = {"cmd"}, expectedKey = "down"},
    {name = "deleteWordForward", expectedMods = {"alt"}, expectedKey = "forwarddelete"},
    {name = "deleteWordBackward", expectedMods = {"alt"}, expectedKey = "delete"},
    {name = "killToStart", isSequence = true, expectedSeq = {
        {mods = {"cmd", "shift"}, key = "left"},
        {mods = {}, key = "delete"}
    }},
}

-- Run unit tests (verify keystrokes via mocking)
function M.runAll()
    testResults = {}

    print("\n" .. string.rep("=", 50))
    print("Unit Tests: Verify Actions Send Correct Keystrokes")
    print(string.rep("=", 50) .. "\n")

    local readline = getReadline()
    if not readline then return false end

    for _, test in ipairs(unitTests) do
        local actionFn = readline.actions[test.name]
        if not actionFn then
            recordResult(test.name, false, "function exists", "not found")
        else
            local captured = captureKeystrokes(actionFn)
            local actualStr = formatKeystrokes(captured)

            local passed, expectedStr
            if test.isSequence then
                passed = keystrokeSequenceMatches(captured, test.expectedSeq)
                local parts = {}
                for _, e in ipairs(test.expectedSeq) do
                    local modPart = #e.mods > 0 and (table.concat(e.mods, "+") .. "+") or ""
                    table.insert(parts, modPart .. e.key)
                end
                expectedStr = table.concat(parts, ", ")
            else
                passed = keystrokesMatch(captured, test.expectedMods, test.expectedKey)
                expectedStr = table.concat(test.expectedMods, "+") .. "+" .. test.expectedKey
            end

            recordResult(test.name, passed, expectedStr, actualStr)
        end
    end

    return M.printSummary()
end

--------------------------------------------------------------------------------
-- E2E Tests: Verify actions have correct effect in TextEdit
--------------------------------------------------------------------------------

-- TextEdit helpers
local function setupTextEdit()
    hs.application.launchOrFocus("TextEdit")
    wait(0.5)
    hs.eventtap.keyStroke({"cmd"}, "n")
    wait(0.5)
end

local function teardownTextEdit()
    hs.eventtap.keyStroke({"cmd"}, "w")
    wait(0.2)
    hs.eventtap.keyStroke({"cmd"}, "d")  -- Don't save
    wait(0.2)
end

local function setFieldText(text, cursorAtStart)
    hs.pasteboard.setContents(text)
    hs.eventtap.keyStroke({"cmd"}, "a")
    wait(0.1)
    hs.eventtap.keyStroke({"cmd"}, "v")
    wait(0.1)
    if cursorAtStart then
        hs.eventtap.keyStroke({"cmd"}, "Left")
    end
    wait(0.1)
end

local function getFieldText()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd"}, "a")
    wait(0.1)
    hs.eventtap.keyStroke({"cmd"}, "c")
    wait(0.1)
    local text = hs.pasteboard.getContents() or ""
    hs.eventtap.keyStroke({}, "Right")
    wait(0.05)
    return text
end

local function getTextAfterCursor()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd", "shift"}, "Right")
    wait(0.1)
    hs.eventtap.keyStroke({"cmd"}, "c")
    wait(0.1)
    local text = hs.pasteboard.getContents() or ""
    hs.eventtap.keyStroke({}, "Right")
    wait(0.05)
    return text
end

local function getTextBeforeCursor()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd", "shift"}, "Left")
    wait(0.1)
    hs.eventtap.keyStroke({"cmd"}, "c")
    wait(0.1)
    local text = hs.pasteboard.getContents() or ""
    hs.eventtap.keyStroke({}, "Left")  -- Deselect, cursor at start
    wait(0.05)
    return text
end

local function getSelectedText()
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    wait(0.1)
    return hs.pasteboard.getContents() or ""
end

-- For verifying empty field: type marker, select all, check only marker exists
local function verifyFieldEmpty()
    local marker = "✓"
    hs.eventtap.keyStrokes(marker)
    wait(0.1)
    hs.pasteboard.clearContents()
    hs.eventtap.keyStroke({"cmd"}, "a")
    wait(0.1)
    hs.eventtap.keyStroke({"cmd"}, "c")
    wait(0.1)
    local text = hs.pasteboard.getContents() or ""
    -- Clean up: delete the marker
    hs.eventtap.keyStroke({}, "delete")
    wait(0.05)
    return text == marker
end

-- E2E test definitions
-- check types: "afterCursor", "allText", "selected"
local e2eTests = {
    -- Word movement
    {name = "wordForward", setup = {"one two three", true},
     expected = " two three", check = "afterCursor",
     desc = "Move forward one word"},

    {name = "wordBackward", setup = {"one two three", false},
     expected = "three", check = "afterCursor",
     desc = "Move backward one word"},

    -- Word selection
    {name = "wordSelectForward", setup = {"one two three", true},
     expected = "one", check = "selected",
     desc = "Select forward one word"},

    {name = "wordSelectBackward", setup = {"one two three", false},
     expected = "three", check = "selected",
     desc = "Select backward one word"},

    -- Document navigation
    {name = "docStart", setup = {"one two three", false},
     expected = "one two three", check = "afterCursor",
     desc = "Move to start of document"},

    {name = "docEnd", setup = {"one two three", true},
     expected = "one two three", check = "beforeCursor",
     desc = "Move to end of document"},

    -- Deletion
    {name = "deleteWordForward", setup = {"one two three", true},
     expected = " two three", check = "allText",
     desc = "Delete word forward"},

    {name = "deleteWordBackward", setup = {"one two three", false},
     expected = "one two ", check = "allText",
     desc = "Delete word backward"},

    {name = "killToStart", setup = {"one two three", false},
     expected = true, check = "isEmpty",
     desc = "Kill from cursor to start of line"},
}

-- Run e2e tests in TextEdit
function M.runE2E()
    testResults = {}

    print("\n" .. string.rep("=", 50))
    print("E2E Tests: Verify Actions Work in TextEdit")
    print(string.rep("=", 50) .. "\n")

    local readline = getReadline()
    if not readline then return false end

    setupTextEdit()

    for _, test in ipairs(e2eTests) do
        setFieldText(test.setup[1], test.setup[2])
        wait(0.2)

        local actionFn = readline.actions[test.name]
        if actionFn then
            actionFn()
            wait(0.3)

            local actual
            if test.check == "afterCursor" then
                actual = getTextAfterCursor()
            elseif test.check == "beforeCursor" then
                actual = getTextBeforeCursor()
            elseif test.check == "selected" then
                actual = getSelectedText()
            elseif test.check == "isEmpty" then
                actual = verifyFieldEmpty()
            else
                actual = getFieldText()
            end

            recordResult(test.name .. " (e2e)", actual == test.expected, test.expected, actual)
        else
            recordResult(test.name .. " (e2e)", false, "function exists", "not found")
        end

        wait(0.3)
    end

    teardownTextEdit()
    return M.printSummary()
end

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

function M.printSummary()
    local passed, failed = 0, 0
    for _, r in ipairs(testResults) do
        if r.passed then passed = passed + 1 else failed = failed + 1 end
    end

    print("\n" .. string.rep("-", 40))
    print("Passed: " .. passed .. "/" .. #testResults)

    if failed > 0 then
        print("⚠️  " .. failed .. " test(s) failed")
        return false
    else
        print("✅ All tests passed!")
        return true
    end
end

function M.list()
    print("\nUnit tests (runAll):")
    for _, t in ipairs(unitTests) do
        print("  " .. t.name)
    end
    print("\nE2E tests (runE2E):")
    for _, t in ipairs(e2eTests) do
        print("  " .. t.name)
    end
end

-- Check that all readline hotkeys are registered and enabled
function M.checkHotkeys()
    print("\n" .. string.rep("=", 50))
    print("Checking Readline Hotkey Registration")
    print(string.rep("=", 50) .. "\n")

    local readline = package.loaded["readline"]
    if not readline or not readline.hotkeys then
        print("❌ readline module not loaded or has no hotkeys table")
        return false
    end

    local expectedBindings = {
        "wordForward (Alt-f)",
        "wordBackward (Alt-b)",
        "wordSelectForward (Alt-Shift-f)",
        "wordSelectBackward (Alt-Shift-b)",
        "docStart (Alt-,)",
        "docEnd (Alt-.)",
        "deleteWordForward (Alt-d)",
        "deleteWordBackward (Ctrl-w)",
        "killToStart (Ctrl-u)",
    }

    local allOk = true
    print("Registered hotkeys: " .. #readline.hotkeys)
    print("")

    for i, hk in ipairs(readline.hotkeys) do
        local isEnabled = hk.enabled ~= false
        local status = isEnabled and "✅" or "❌"
        local idx = hk.idx or "?"
        local desc = expectedBindings[i] or "(extra hotkey)"
        print(string.format("%s [%s] %s", status, idx, desc))
        if not isEnabled then
            allOk = false
        end
    end

    print("")
    if #readline.hotkeys ~= #expectedBindings then
        print("⚠️  Expected " .. #expectedBindings .. " hotkeys, found " .. #readline.hotkeys)
        allOk = false
    end

    if allOk then
        print("✅ All hotkeys registered and enabled!")
    else
        print("❌ Some hotkeys have issues")
    end

    return allOk
end

return M

