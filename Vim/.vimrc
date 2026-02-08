" Load settings - full version sources essential, or use essential directly
if filereadable(expand('~/.vim/settings.vim'))
    source ~/.vim/settings.vim
elseif filereadable(expand('~/.vim/settings-essential.vim'))
    source ~/.vim/settings-essential.vim
endif

" Load mappings - full version sources essential, or use essential directly
if filereadable(expand('~/.vim/mappings.vim'))
    source ~/.vim/mappings.vim
elseif filereadable(expand('~/.vim/mappings-essential.vim'))
    source ~/.vim/mappings-essential.vim
endif

" NOTE: Plugins are managed in Neovim via lazy.nvim (~/.config/nvim/)
" Vim is kept minimal for quick editing and remote usage
