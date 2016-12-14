let mapleader = " "

" Enter normal mode {{{

autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>

" }}}

" Movements {{{

nnoremap H ^
nnoremap L $
onoremap H ^
onoremap L $
vnoremap H ^
vnoremap L $h
noremap G G$

inoremap <c-l> <right>
inoremap <c-h> <left>

" }}}

" Undo points {{{

inoremap . .<C-g>u
inoremap , ,<C-g>u
inoremap ; ;<C-g>u
inoremap ! !<C-g>u
inoremap ? ?<C-g>u
inoremap : :<C-g>u

" }}}

" Tab completion and pop up menu {{{1
inoremap <expr> <TAB>  pumvisible() ? "\<c-n>" : "\<TAB>"
inoremap <expr> <S-TAB>  pumvisible() ? "\<c-p>" : "\<S-TAB>"
inoremap <expr> <c-j>  pumvisible() ? "\<Down>" : "j"
inoremap <expr> <c-k>  pumvisible() ? "\<Up>" : "k"
" }}}1

" replace last search pattern {{{1

nnoremap <Leader>cl :%s/<C-r>///g<left><left>

" }}}1

" Insert single character {{{
nnoremap <leader>i i_<Esc>r
nnoremap <leader>I a_<Esc>r
" }}}

" Edit vimrc {{{
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
" }}}

" Switch windows {{{
nnoremap <leader>w <c-w><c-w>
nnoremap <leader>W <c-w><c-w>
" }}}

" Yank {{{
nnoremap Y y$
nnoremap <expr> <leader>Y :%y+<cr>
" }}}

" Fold {{{
nnoremap <leader>f za
" }}}

" Toggle spelling {{{
nnoremap <leader>s :set spell!<cr>:set spell?<cr>
" }}}

" Correct last mistake from insert mode {{{
inoremap <c-s> <esc>[s1z=A
" }}}

" Show current syntag group {{{
map <leader>hi :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
    \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
    \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
    \ . ">"<CR>
" }}}

" Select text just pasted {{{
noremap gV `[v`]
" }}}

