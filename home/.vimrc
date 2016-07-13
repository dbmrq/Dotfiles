set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'tpope/vim-sensible'
    Plugin 'tpope/vim-unimpaired'
    Plugin 'tpope/vim-surround'
    Plugin 'tpope/vim-repeat'
    Plugin 'Shougo/neocomplete.vim'
    Plugin 'lervag/vimtex'
    Plugin 'SirVer/ultisnips'
    Plugin 'honza/vim-snippets'
    Plugin 'Raimondi/delimitMate'
    Plugin 'godlygeek/tabular'
    Plugin 'ntpeters/vim-better-whitespace'
    Plugin 'junegunn/goyo.vim'
    Plugin 'yegappan/mru'
    Plugin 'scrooloose/nerdcommenter'
    Plugin 'terryma/vim-expand-region'
    Plugin 'mbbill/undotree'
    Plugin 'justinmk/vim-sneak'
    Plugin 'maxbrunsfeld/vim-yankstack'
    Plugin 'itchyny/lightline.vim'
    Plugin 'henrik/vim-indexed-search'
    Plugin 'haya14busa/incsearch.vim'
    Plugin 'kopischke/vim-stay'
    Plugin 'tommcdo/vim-exchange'
    Plugin 'nelstrom/vim-visual-star-search'
    Plugin 'Konfekt/FastFold'
    Plugin 'vim-pandoc/vim-pandoc'
    Plugin 'vim-pandoc/vim-pandoc-syntax'
    Plugin 'vim-pandoc/vim-pandoc-after'
    Plugin 'wellle/targets.vim'
    Plugin 'kana/vim-textobj-user'
    Plugin 'kana/vim-textobj-line'
    Plugin 'kana/vim-textobj-indent'
    Plugin 'kana/vim-textobj-entire'
    Plugin 'kana/vim-textobj-syntax'
    Plugin 'reedes/vim-pencil'
    Plugin 'reedes/vim-textobj-sentence'
    " Plugin 'tpope/vim-abolish'
    " Plugin 'reedes/vim-wordy'
    Plugin 'https://github.com/altercation/vim-colors-solarized.git'
call vundle#end()

filetype plugin indent on

source ~/.vim/settings.vim
source ~/.vim/functions.vim
source ~/.vim/mappings.vim
source ~/.vim/plugins.vim

