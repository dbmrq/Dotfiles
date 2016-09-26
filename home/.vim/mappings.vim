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
vnoremap H ^
vnoremap L $h
noremap G G$

nnoremap <leader>j 15j
nnoremap <leader>k 15k
nnoremap <leader>h 10h
nnoremap <leader>l 10l
vnoremap <leader>j 15j
vnoremap <leader>k 15k
vnoremap <leader>h 10h
vnoremap <leader>l 10l

inoremap <c-l> <right>
inoremap <c-h> <left>
inoremap <c-o> <esc>o

" }}}

" Undo points {{{

inoremap . .<C-g>u
inoremap , ,<C-g>u
inoremap ; ;<C-g>u
inoremap ! !<C-g>u
inoremap ? ?<C-g>u
inoremap : :<C-g>u

" }}}

" Replace word under cursor or selection {{{

nnoremap <Leader>cc :%s/\<<C-r><C-w>\>/<C-r><C-w>/g
vnoremap <Leader>cc y:%s/<C-r>"/<C-r>"/g

" }}}

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

" Yank till end of line {{{
nnoremap Y y$
" }}}

" Fold {{{
nnoremap <leader>f za
" }}}

" Toggle spelling {{{
nnoremap <leader>tsp :set spell!<cr>
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

