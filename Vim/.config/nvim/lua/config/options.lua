-- Neovim options

-- Source essential Vim settings for consistency
if vim.fn.filereadable(vim.fn.expand('~/.vim/settings-essential.vim')) == 1 then
  vim.cmd('source ~/.vim/settings-essential.vim')
end

local opt = vim.opt

opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.swapfile = false
opt.mouse = 'a'
opt.clipboard = 'unnamedplus'
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = 'split'
opt.scrolloff = 10
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
opt.breakindent = true
opt.showmode = false

if vim.env.BACKGROUND == 'light' then
  opt.background = 'light'
else
  opt.background = 'dark'
end
