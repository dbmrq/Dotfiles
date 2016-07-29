syntax enable

set hidden

set relativenumber
set number

set showcmd

set tabstop=4
set shiftwidth=4
set expandtab
set shiftround

set wrap
set linebreak
set textwidth=78
if executable("par")
    set formatprg=par\ -w78
endif
if &l:formatoptions =~ "t"
    let &colorcolumn="79,".join(range(101,999),",")
else
    let &colorcolumn="79"
endif

set backupcopy=yes
set clipboard=unnamed
set ignorecase
set smartcase
set scrolloff=5
set sidescrolloff=7
set sidescroll=1

set undolevels=1000

set title

set visualbell
set noerrorbells

set foldmethod=marker

set undodir=~/.vim/undo/
set undofile

let g:tex_comment_nospell=1

let g:tex_flavor = "latex"
au BufRead,BufNewFile *.bbx set ft=plaintex
au BufRead,BufNewFile *.cbx set ft=plaintex
au BufRead,BufNewFile *.lbx set ft=plaintex
au BufRead,BufNewFile *.cls set ft=plaintex
au BufRead,BufNewFile *.sty set ft=plaintex

colorscheme solarized
let g:lightline = {'colorscheme': 'solarized',}

set background=dark

