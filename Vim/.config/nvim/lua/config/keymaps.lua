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

-- Window navigation: disabled, Ghostty handles Ctrl+W sequences for splits
-- map('n', '<C-h>', '<C-w><C-h>', { desc = 'Left window' })
-- map('n', '<C-l>', '<C-w><C-l>', { desc = 'Right window' })
-- map('n', '<C-j>', '<C-w><C-j>', { desc = 'Lower window' })
-- map('n', '<C-k>', '<C-w><C-k>', { desc = 'Upper window' })

-- Window resize: disabled, Ghostty handles Ctrl+W +/-/</>
-- map('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase height' })
-- map('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease height' })
-- map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease width' })
-- map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Increase width' })

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
