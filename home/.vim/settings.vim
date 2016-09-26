
" Appearance {{{

syntax enable

set title

set relativenumber
set number

set showcmd

set scrolloff=5
set sidescrolloff=7
set sidescroll=1

set background=dark

" }}}

" Wrapping {{{

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

" }}}

" Indentation {{{
set tabstop=4
set shiftwidth=4
set expandtab
set shiftround
" }}}

" Folding {{{
set foldmethod=marker
set foldmarker=\ {{{,\ }}}2
" }}}

" Undo {{{
set undodir=~/.vim/undo/
set undofile
set undolevels=1000
" }}}

" TeX {{{

let g:tex_flavor = "latex"
au BufReadPre,BufNewFile *.bbx,*.cbx,*.lbx,*.cls,*.sty set ft=plaintex

au FileType markdown,text,tex set fo+=12

let g:tex_comment_nospell=1

" }}}

" Misc {{{

set hidden

set backupcopy=yes

set clipboard=unnamed

set ignorecase
set smartcase

set visualbell
set noerrorbells

set shortmess+=c

" }}}

