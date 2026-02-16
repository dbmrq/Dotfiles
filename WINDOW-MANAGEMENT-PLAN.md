# Unified Window Management Plan

Cross-environment keyboard-driven window management with consistent modal bindings.

## Design Principles

1. **Zellij patterns are canonical** — macOS mirrors with `Super`, Neovim with `<C-b>`
2. **Modal approach** — Prefix enters mode, `hjkl` acts, `Esc`/`Enter` exits
3. **Stacking is first-class** — Zellij stacked panes ↔ macOS cascaded windows
4. **CheatSheet as mode indicator** — Shows available keys while in mode
5. **Full replacement** — Remove old bindings, clean slate

---

## Binding Scheme

### Zellij (Use Defaults)

| Entry | Mode | Actions |
|-------|------|---------|
| `Ctrl+p` | Pane | `hjkl` focus, `n` new, `x` close, `f` fullscreen, `w` floating |
| `Ctrl+t` | Tab | `hl` switch, `n` new, `x` close, `r` rename |
| `Ctrl+n` | Resize | `hjkl` resize |
| `Ctrl+h` | Move | `hjkl` reposition pane |
| `Ctrl+s` | Scroll | scroll, `/` search |
| `Ctrl+g` | Locked | passthrough to app |

Stacked panes: `j`/`k` in Pane mode cycles through stacked panes.

### macOS / Hammerspoon

| Entry | Mode | Actions |
|-------|------|---------|
| `Super+p` | Focus | `hjkl` focus direction, `j`/`k` cycles cascade, `f` maximize, `x` close |
| `Super+n` | Resize | `hjkl` grow/shrink window |
| `Super+h` | Move | `hjkl` snap to grid position |
| `Super+t` | Tab/Spaces | `hl` switch Spaces, `n` new Space |

Mode exit: `Esc` or `Enter`

Quick actions (no mode):
- `Super+,` — Cascade all windows
- `Super+.` — Cascade app windows  
- `Super+1-3` — Move window to screen N

### Neovim

| Entry | Mode | Actions |
|-------|------|---------|
| `<C-b>p` | Focus | `hjkl` focus split (or use native `<C-w>hjkl`) |
| `<C-b>n` | Resize | `hjkl` resize split |
| `<C-b>h` | Move | `hjkl` move/exchange split |
| `<C-b>t` | Tabs | `hl` switch tabs (`gt`/`gT`), `n` new, `x` close |

Note: Uses `<C-b>` as tmux-style prefix for full symmetry with Zellij/macOS.
Remaps `<C-b>` (page up) — use `<C-u>` for scrolling instead.

---

## CheatSheet Behavior

1. **Long press Super** → Shows mode overview:
   ```
   p - Focus    n - Resize    h - Move    t - Spaces
   ```

2. **Press Super+p** → Immediately shows Focus mode commands:
   ```
   [Focus Mode]
   h/j/k/l - focus direction    j/k - cycle stack
   f - maximize    x - close    Esc/Enter - exit
   ```

3. **Mode action or Esc/Enter** → CheatSheet disappears, exit mode

---

## Mental Model

```
Layer      Prefix    Focus   Resize   Move    Tabs/Spaces
─────────────────────────────────────────────────────────
Zellij     Ctrl+       p       n        h         t
macOS      Super+      p       n        h         t
Neovim     <C-b>       p       n        h         t
```

Within each mode: `hjkl` = direction, `x` = close, `f` = fullscreen, `Esc`/`Enter` = exit

---

## To-Do List

### Phase 0: Design Decisions
- [x] DECIDED: Use Zellij true defaults (p/n/h/t) — confirmed correct
- [x] DECIDED: Keep mode-less quick actions for maximize, cascade, screen move
- [x] DECIDED: Cascade cycling overloads `j`/`k` in Focus mode (when windows overlap, focus = cycle)
- [x] DECIDED: WinMan supports dual modes: "zellij" (modal, default) and "simple" (current behavior)
- [x] DECIDED: Neovim uses `<C-b>` prefix (tmux-style) for full symmetry — remaps page-up (use `<C-u>` instead)

### Phase 1: Zellij Cleanup
- [ ] Remove custom keybinds from `Zellij/.config/zellij/config.kdl`
- [ ] Document that we're using Zellij defaults

### Phase 2: Hammerspoon Modal System
- [ ] Create new branch in Spoons repo
- [ ] Add dual-mode support to WinMan.spoon:
  - [ ] `WinMan.mode = "zellij"` (default) — modal bindings
  - [ ] `WinMan.mode = "simple"` — current direct bindings (HJKL resize, arrows move)
- [ ] Implement `hs.hotkey.modal` infrastructure for zellij mode
- [ ] Implement Focus mode (`Super+p`)
  - [ ] `hjkl` for directional focus (`hs.window.focusWindow{West,South,North,East}`)
  - [ ] When target window overlaps current (cascaded), cycle z-order instead
  - [ ] `f` for maximize
  - [ ] `x` for close window
  - [ ] `Esc`/`Enter` to exit mode
- [ ] Implement Resize mode (`Super+n`)
  - [ ] `hjkl` for grow/shrink (reuse existing resize logic)
- [ ] Implement Move mode (`Super+h`)
  - [ ] `hjkl` for grid snapping (reuse existing move logic)
- [ ] Implement Spaces mode (`Super+t`)
  - [ ] `hl` for switching Spaces
  - [ ] `n` for new Space (if possible via accessibility)
- [ ] Keep quick actions in both modes:
  - [ ] `Super+;` — Maximize
  - [ ] `Super+,` — Cascade all
  - [ ] `Super+.` — Cascade app
  - [ ] `Super+1-3` — Move to screen N

### Phase 3: CheatSheet Integration
- [ ] Add `showModeHints(modeName, hints)` method to CheatSheet spoon
- [ ] Add `hideModeHints()` method
- [ ] In WinMan modal:entered(), call `spoon.CheatSheet:showModeHints(...)`
- [ ] In WinMan modal:exited(), call `spoon.CheatSheet:hideModeHints()`
- [ ] Long press Super (existing behavior) shows mode overview:
  ```
  p - Focus    n - Resize    h - Move    t - Spaces
  ```
- [ ] Mode entry shows that mode's commands immediately (no delay)

### Phase 4: Neovim Consistency
- [ ] Set up `<C-b>` as modal prefix (remaps page-up)
- [ ] Implement Focus mode (`<C-b>p`)
  - [ ] `hjkl` focuses splits
  - [ ] `Esc`/`Enter` exits
- [ ] Implement Resize mode (`<C-b>n`)
  - [ ] `hjkl` resizes splits
- [ ] Implement Move mode (`<C-b>h`)
  - [ ] `hjkl` moves/exchanges splits
- [ ] Implement Tab mode (`<C-b>t`)
  - [ ] `hl` switches tabs, `n` new, `x` close
- [ ] Consider statusline indicator for active mode
- [ ] Consider which-key.nvim for visual mode hints

---

## Files to Modify

1. `Zellij/.config/zellij/config.kdl` — Remove custom keybinds (just Shift+h/l for tab move)
2. `Hammerspoon/.hammerspoon/Spoons/WinMan.spoon/init.lua` — Add dual-mode support + modal system
3. `Hammerspoon/.hammerspoon/Spoons/CheatSheet.spoon/init.lua` — Add mode hints API
4. `Hammerspoon/.hammerspoon/init.lua` — Configure WinMan mode preference
5. `Vim/.config/nvim/lua/config/keymaps.lua` — Add modal window bindings

---

## Notes

- WinMan spoon will be extended with dual-mode support (not replaced)
- CheatSheet spoon needs new API for programmatic mode hints
- Both spoons are in dbmrq/Spoons repo — changes go there, then SpoonInstall pulls updates
- Neovim modal system: consider which-key.nvim integration for visual hints
- Cascade cycling rationale: when windows are stacked/cascaded, directional focus naturally
  becomes z-order cycling since they share the same position. `j` = next in stack, `k` = prev.

---

## Implementation Details

### Hammerspoon Modal System

Use `hs.hotkey.modal` for clean mode management:

```lua
-- Example structure
local focusMode = hs.hotkey.modal.new(super, "p")

function focusMode:entered()
    -- Show CheatSheet with Focus mode commands
end

function focusMode:exited()
    -- Hide CheatSheet
end

focusMode:bind({}, "h", function()
    hs.window.focusedWindow():focusWindowWest()
end)
focusMode:bind({}, "escape", function() focusMode:exit() end)
focusMode:bind({}, "return", function() focusMode:exit() end)
```

### Cascade Stack Cycling

When windows are cascaded, they share similar positions. To cycle:
1. Get all windows that overlap with current window
2. Order by z-index (front to back)
3. `j` focuses next in stack, `k` focuses previous
4. Use `hs.window.orderedWindows()` for z-order

### Spaces Control (macOS)

For `Super+t` Spaces mode:
- `hs.spaces` module for Space manipulation
- `hs.eventtap.keyStroke({"ctrl"}, "left/right")` for switching
- Creating new Space may require accessibility permissions

### Neovim Modal Approach

Using `<C-b>` as tmux-style prefix gives full symmetry with Zellij/macOS.

**Option A: Simple state + buffer-local keymaps**

```lua
local window_mode = nil  -- nil, "focus", "resize", "move", "tab"

local function exit_mode()
    window_mode = nil
    -- Remove buffer-local keymaps
    pcall(vim.keymap.del, 'n', 'h', {buffer = 0})
    pcall(vim.keymap.del, 'n', 'j', {buffer = 0})
    pcall(vim.keymap.del, 'n', 'k', {buffer = 0})
    pcall(vim.keymap.del, 'n', 'l', {buffer = 0})
    pcall(vim.keymap.del, 'n', '<Esc>', {buffer = 0})
    pcall(vim.keymap.del, 'n', '<CR>', {buffer = 0})
end

local function enter_resize_mode()
    exit_mode()  -- Clean up any existing mode
    window_mode = "resize"
    vim.keymap.set('n', 'h', '<C-w><', {buffer = 0, desc = "shrink width"})
    vim.keymap.set('n', 'l', '<C-w>>', {buffer = 0, desc = "grow width"})
    vim.keymap.set('n', 'j', '<C-w>-', {buffer = 0, desc = "shrink height"})
    vim.keymap.set('n', 'k', '<C-w>+', {buffer = 0, desc = "grow height"})
    vim.keymap.set('n', '<Esc>', exit_mode, {buffer = 0})
    vim.keymap.set('n', '<CR>', exit_mode, {buffer = 0})
end

-- Bind <C-b> as prefix
vim.keymap.set('n', '<C-b>p', enter_focus_mode, {desc = "Focus mode"})
vim.keymap.set('n', '<C-b>n', enter_resize_mode, {desc = "Resize mode"})
vim.keymap.set('n', '<C-b>h', enter_move_mode, {desc = "Move mode"})
vim.keymap.set('n', '<C-b>t', enter_tab_mode, {desc = "Tab mode"})
```

**Option B: which-key.nvim hydra-style**

```lua
-- which-key v3 has built-in hydra support
local wk = require("which-key")
wk.add({
    { "<C-b>", group = "window" },
    { "<C-b>n", group = "resize" },
    { "<C-b>nh", "<C-w><", desc = "shrink width" },
    { "<C-b>nl", "<C-w>>", desc = "grow width" },
    { "<C-b>nj", "<C-w>-", desc = "shrink height" },
    { "<C-b>nk", "<C-w>+", desc = "grow height" },
    { "<C-b>h", group = "move" },
    { "<C-b>hh", "<C-w>H", desc = "move left" },
    { "<C-b>hl", "<C-w>L", desc = "move right" },
    -- etc
})
```

**Note:** `<C-b>` remaps page-up. Use `<C-u>` for half-page up (more common anyway).

