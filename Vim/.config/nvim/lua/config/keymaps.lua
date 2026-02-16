-- Neovim keymaps

-- Source essential Vim mappings for consistency
if vim.fn.filereadable(vim.fn.expand('~/.vim/mappings-essential.vim')) == 1 then
  vim.cmd('source ~/.vim/mappings-essential.vim')
end

local map = vim.keymap.set

-- Terminal escape
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
map('t', 'jk', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
map('t', 'kj', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Clear search highlight
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostics
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic quickfix' })

-- Move lines in visual mode
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move up' })

-- Keep cursor centered
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Better paste (don't overwrite register)
map('x', '<leader>p', [["_dP]], { desc = 'Paste without overwrite' })

-- Quick save
map('n', '<leader>W', '<cmd>w<CR>', { desc = 'Save file' })

---------------------------------------------------------------------------
-- Window Management Modal System (<C-b> prefix)
---------------------------------------------------------------------------
-- Mirrors Zellij/Hammerspoon bindings for consistency:
--   <C-b>p = Focus mode, <C-b>n = Resize mode
--   <C-b>h = Move mode,  <C-b>t = Tab mode
-- Note: <C-b> remaps page-up; use <C-u> for half-page scroll instead.
---------------------------------------------------------------------------

local window_mode = nil  -- nil, "focus", "resize", "move", "tab"

local function exit_window_mode()
  window_mode = nil
  -- Remove buffer-local keymaps
  pcall(vim.keymap.del, 'n', 'h', { buffer = 0 })
  pcall(vim.keymap.del, 'n', 'j', { buffer = 0 })
  pcall(vim.keymap.del, 'n', 'k', { buffer = 0 })
  pcall(vim.keymap.del, 'n', 'l', { buffer = 0 })
  pcall(vim.keymap.del, 'n', 'n', { buffer = 0 })
  pcall(vim.keymap.del, 'n', 'x', { buffer = 0 })
  pcall(vim.keymap.del, 'n', '<Esc>', { buffer = 0 })
  pcall(vim.keymap.del, 'n', '<CR>', { buffer = 0 })
  vim.notify('', vim.log.levels.INFO)  -- Clear mode indicator
end

local function enter_focus_mode()
  exit_window_mode()
  window_mode = 'focus'
  vim.keymap.set('n', 'h', '<C-w>h', { buffer = 0, desc = 'Focus left' })
  vim.keymap.set('n', 'j', '<C-w>j', { buffer = 0, desc = 'Focus down' })
  vim.keymap.set('n', 'k', '<C-w>k', { buffer = 0, desc = 'Focus up' })
  vim.keymap.set('n', 'l', '<C-w>l', { buffer = 0, desc = 'Focus right' })
  vim.keymap.set('n', '<Esc>', exit_window_mode, { buffer = 0 })
  vim.keymap.set('n', '<CR>', exit_window_mode, { buffer = 0 })
  vim.notify('[Focus Mode] h/j/k/l focus | Esc/Enter exit', vim.log.levels.INFO)
end

local function enter_resize_mode()
  exit_window_mode()
  window_mode = 'resize'
  vim.keymap.set('n', 'h', '2<C-w><', { buffer = 0, desc = 'Shrink width' })
  vim.keymap.set('n', 'l', '2<C-w>>', { buffer = 0, desc = 'Grow width' })
  vim.keymap.set('n', 'j', '2<C-w>-', { buffer = 0, desc = 'Shrink height' })
  vim.keymap.set('n', 'k', '2<C-w>+', { buffer = 0, desc = 'Grow height' })
  vim.keymap.set('n', '<Esc>', exit_window_mode, { buffer = 0 })
  vim.keymap.set('n', '<CR>', exit_window_mode, { buffer = 0 })
  vim.notify('[Resize Mode] h/j/k/l resize | Esc/Enter exit', vim.log.levels.INFO)
end

local function enter_move_mode()
  exit_window_mode()
  window_mode = 'move'
  vim.keymap.set('n', 'h', '<C-w>H', { buffer = 0, desc = 'Move split left' })
  vim.keymap.set('n', 'j', '<C-w>J', { buffer = 0, desc = 'Move split down' })
  vim.keymap.set('n', 'k', '<C-w>K', { buffer = 0, desc = 'Move split up' })
  vim.keymap.set('n', 'l', '<C-w>L', { buffer = 0, desc = 'Move split right' })
  vim.keymap.set('n', '<Esc>', exit_window_mode, { buffer = 0 })
  vim.keymap.set('n', '<CR>', exit_window_mode, { buffer = 0 })
  vim.notify('[Move Mode] h/j/k/l reposition | Esc/Enter exit', vim.log.levels.INFO)
end

local function enter_tab_mode()
  exit_window_mode()
  window_mode = 'tab'
  vim.keymap.set('n', 'h', 'gT', { buffer = 0, desc = 'Previous tab' })
  vim.keymap.set('n', 'l', 'gt', { buffer = 0, desc = 'Next tab' })
  vim.keymap.set('n', 'n', '<cmd>tabnew<CR>', { buffer = 0, desc = 'New tab' })
  vim.keymap.set('n', 'x', '<cmd>tabclose<CR>', { buffer = 0, desc = 'Close tab' })
  vim.keymap.set('n', '<Esc>', exit_window_mode, { buffer = 0 })
  vim.keymap.set('n', '<CR>', exit_window_mode, { buffer = 0 })
  vim.notify('[Tab Mode] h/l switch | n new | x close | Esc/Enter exit', vim.log.levels.INFO)
end

-- <C-b> prefix bindings (tmux-style for Zellij/macOS symmetry)
map('n', '<C-b>p', enter_focus_mode, { desc = 'Window Focus mode' })
map('n', '<C-b>n', enter_resize_mode, { desc = 'Window Resize mode' })
map('n', '<C-b>h', enter_move_mode, { desc = 'Window Move mode' })
map('n', '<C-b>t', enter_tab_mode, { desc = 'Tab mode' })
