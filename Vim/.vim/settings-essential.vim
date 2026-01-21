" Essential Vim Settings
" Minimal, portable configuration that works everywhere without plugins

" Appearance
syntax enable
set title
set showcmd
set number
set ruler
set laststatus=2
set showmode
set scrolloff=5
set sidescrolloff=7
set sidescroll=1

" Wrapping
set wrap
set linebreak
set textwidth=78
set whichwrap+=h,l

" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set shiftround
set autoindent
set smartindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Undo and backup
if has('persistent_undo')
    set undofile
    set undolevels=5000
    if !isdirectory($HOME . '/.vim/undo')
        call mkdir($HOME . '/.vim/undo', 'p')
    endif
    set undodir=~/.vim/undo/,.
endif
set backupdir=~/.vim/backup/,.,~/tmp,~/
set directory=~/.vim/swp/,.,~/tmp,/var/tmp,/tmp

" Splits
set splitbelow
set splitright

" Misc
set hidden
set backspace=indent,eol,start
set clipboard=unnamed
set visualbell
set noerrorbells
set shortmess+=c
set shortmess+=A
set autowrite
set nojoinspaces
set encoding=utf-8
set autoread
set confirm
set history=1000
set wildmenu
set wildmode=longest:full,full
set ttimeoutlen=10
set mouse=a

if v:version > 703 || v:version == 703 && has('patch541')
    set formatoptions+=j
endif

" Remember cursor position
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
    \     exe "normal! g`\"" |
    \ endif
