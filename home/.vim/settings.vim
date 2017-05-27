
" Appearance {{{

syntax enable

set title

set relativenumber
set number

set showcmd

set scrolloff=5
set sidescrolloff=7
set sidescroll=1

if $BACKGROUND == 'light'
    set background=light
else
    set background=dark
endif

" }}}

" Wrapping {{{

set wrap
set linebreak
set textwidth=78
" if executable("par")
"     set formatprg=par\ -w78
" endif
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
set foldmarker=\ {{{,\ }}}
" }}}

" Undo {{{
if has('persistent_undo')
    " set undodir=~/.vim/undo/
    set undofile
    set undolevels=5000
endif
" }}}

" TeX {{{

let g:tex_flavor = "latex"
au BufReadPost,BufNewFile *.bbx,*.cbx,*.lbx,*.cls,*.sty set ft=plaintex

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

set updatecount=20
set autowrite

set complete+=kspell


set nojoinspaces

" change directory to current file's
autocmd BufEnter * if &ft !=? 'tex' | silent! lcd %:p:h

" open file with cursor at last position
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
    \     exe "normal! g`\"" |
    \ endif

" use ag instead of grep
if executable("ag")
    set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column
    set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

" augroup autoquickfix
"     autocmd!
"     autocmd QuickFixCmdPost [^l]* cwindow
"     autocmd QuickFixCmdPost    l* lwindow
" augroup END

" MRU
function! NoFile()
    if @% == ""
        belowright 12new +setl\ buftype=nofile
        set nowrap
        set conceallevel=2
        call matchadd('Conceal',
                    \ '^\zs.*\ze\/.*\/.*\/', 10, 99, {'conceal': '…'})
        0put =v:oldfiles
        execute 'g/^/m0'
        execute 'normal! G'
        " for c in range(char2nr('0'), char2nr('9')) +
        "             \ range(char2nr('a'), char2nr('z')) +
        "             \ range(char2nr('A'), char2nr('Z'))
        "     execute 'nnoremap <buffer> ' . nr2char(c) . ' /' . nr2char(c)
        " endfor
        " nnoremap <buffer> <c-j> j
        " nnoremap <buffer> <c-k> k
        " nnoremap <buffer> <c-h> h
        " nnoremap <buffer> <c-l> l
        nnoremap <buffer> <CR> :call OpenMRUFile()<CR>
    endif
endfunction

function! OpenMRUFile()
    let l:file = getline('.')
    q
    execute 'e' l:file
endfunction

autocmd VimEnter * call NoFile()



" }}}

