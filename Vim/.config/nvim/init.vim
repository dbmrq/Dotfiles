" Neovim configuration
" Uses Lua-based config with lazy.nvim for modern Neovim features
" Falls back to Vim config if Lua files are not available

if has('nvim')
    " Check if Lua config exists
    let s:lua_config = stdpath('config') . '/lua/config/lazy.lua'
    if filereadable(s:lua_config)
        " Use modern Lua-based configuration
        lua require('config.options')
        lua require('config.keymaps')
        lua require('config.lazy')
        lua require('config.lsp')
    else
        " Fallback: source the main vimrc
        if filereadable(expand('~/.vimrc'))
            source ~/.vimrc
        endif

        " Basic Neovim-specific settings
        tnoremap <Esc> <C-\><C-n>
        tnoremap jk <C-\><C-n>
        tnoremap kj <C-\><C-n>
        set termguicolors
    endif
endif
