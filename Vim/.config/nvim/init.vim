" Neovim configuration - sources the main Vim config

" Source the main vimrc (which handles both light and full installs)
if filereadable(expand('~/.vimrc'))
    source ~/.vimrc
endif

" Neovim-specific settings
if has('nvim')
    " Use the same plugin directory as Vim
    " (vim-plug handles this automatically)

    " Better terminal support
    tnoremap <Esc> <C-\><C-n>
    tnoremap jk <C-\><C-n>
    tnoremap kj <C-\><C-n>

    " Terminal colors
    set termguicolors
endif

