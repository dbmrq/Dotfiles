-- Neovim options

-- Source essential Vim settings for consistency
if vim.fn.filereadable(vim.fn.expand('~/.vim/settings-essential.vim')) == 1 then
  vim.cmd('source ~/.vim/settings-essential.vim')
end

local opt = vim.opt

-- Use terminal colors instead of 24-bit GUI colors
-- This lets the terminal (Ghostty) control the colorscheme
opt.termguicolors = false
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

-- Minimal statusline (matches Vim config in settings.vim)
-- Hide statusline, use ruler instead
opt.laststatus = 0
opt.ruler = true

-- Custom rulerformat: filename, modified, percentage
vim.cmd([[
  set rulerformat=%25(%=%t%{&mod?'\ +':''}%)%{winheight(0)<line('$')?'\ '.line('.')*100/line('$').'%%':''}%{&readonly?'\ [RO]':''}%{&ff!='unix'?'\ ['.&ff.']':''}%{(&fenc!='utf-8'&&!empty(&fenc))?'\ ['.&fenc.']':''}
]])

-- Statusline colors (for when it shows, e.g., in splits)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.cmd('hi! link StatusLine FoldColumn')
    vim.cmd('hi! link StatusLineNC LineNr')
    vim.cmd('hi! link VertSplit LineNr')
  end,
})

if vim.env.BACKGROUND == 'light' then
  opt.background = 'light'
else
  opt.background = 'dark'
end
