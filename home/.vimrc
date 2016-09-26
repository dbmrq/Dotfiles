if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.vim/bundle')

    Plug 'danielbmarques/vim-ditto'
    Plug 'danielbmarques/vim-dialect'

    Plug 'tpope/vim-sensible'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-repeat'
    Plug 'junegunn/goyo.vim'
    Plug 'junegunn/vim-easy-align'
    Plug 'tommcdo/vim-exchange'
    Plug 'AndrewRadev/splitjoin.vim'
    Plug 'Shougo/neocomplete.vim'
    Plug 'lervag/vimtex'
    Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
    Plug 'Raimondi/delimitMate'
    Plug 'ntpeters/vim-better-whitespace'
    Plug 'ctrlpvim/ctrlp.vim'
    Plug 'terryma/vim-expand-region'
    Plug 'airblade/vim-gitgutter'
    " Plug 'chrisbra/NrrwRgn'
    Plug 'FooSoft/vim-argwrap'
    Plug 'mbbill/undotree'
    Plug 'justinmk/vim-sneak'
    Plug 'maxbrunsfeld/vim-yankstack'
    Plug 'itchyny/lightline.vim'
    Plug 'henrik/vim-indexed-search'
    Plug 'haya14busa/incsearch.vim'
    Plug 'tweekmonster/spellrotate.vim'
    Plug 'nelstrom/vim-visual-star-search'
    Plug 'Konfekt/FastFold'
    " Plug 'vim-pandoc/vim-pandoc'
    " Plug 'vim-pandoc/vim-pandoc-syntax'
    " Plug 'vim-pandoc/vim-pandoc-after'
    Plug 'wellle/targets.vim'
    Plug 'kana/vim-textobj-user'
    Plug 'kana/vim-textobj-line'
    Plug 'kana/vim-textobj-indent'
    Plug 'kana/vim-textobj-entire'
    Plug 'kana/vim-textobj-syntax'
    Plug 'keith/swift.vim'
    Plug 'altercation/vim-colors-solarized'

call plug#end()

command! Plug PlugUpdate | PlugUpgrade | PlugClean! | PlugDiff


source ~/.vim/settings.vim
source ~/.vim/mappings.vim
source ~/.vim/functions.vim
source ~/.vim/plugins.vim

