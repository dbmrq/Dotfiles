let mapleader = " "

" Enter normal mode {{{

autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>
vnoremap <CR> <esc>

" }}}

" Movements {{{

nnoremap H ^
nnoremap L $
onoremap H ^
onoremap L $
vnoremap H ^
vnoremap L $h
noremap G G$

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
inoremap <expr> <c-k>  pumvisible() ? "\<Up>" : "<Esc>lDA"
" }}}1

" Replace last search pattern {{{1

nnoremap <Leader>cl :%s/<C-r>///g<left><left>

" }}}1

" Insert single character {{{
nnoremap <leader>i i_<Esc>r
nnoremap <leader>I a_<Esc>r
" }}}

" Edit vimrc {{{
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
" }}}

" Switch windows and buffers {{{
nnoremap <leader>ww <c-w><c-w>
" nnoremap <leader>W <c-w><c-w>
nnoremap <leader>b :b#<cr>
" }}}

" Yank {{{
nnoremap Y y$
" nnoremap <leader>Y :%y+<cr>
" }}}

" Fold {{{
nnoremap <leader>f za
" }}}

" Toggle spelling {{{
nnoremap <leader>s :set spell!<cr>:set spell?<cr>
" }}}

" Correct last mistake from insert mode {{{
inoremap <c-s> <esc>D[s1z=$mNp`Nla
" }}}

" Show current syntax group {{{
map <leader>hi :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
    \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
    \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
    \ . ">"<CR>
" }}}

" Select text just pasted {{{
noremap gV `[v`]
" }}}

" Add blank lines above and below current paragraphs {{{1
nnoremap <leader>a mn{O<esc>}o<esc>`n
vnoremap <leader>a <esc>`<O<esc>`>o<esc>gv

" Also add fold
nmap <leader>A {O<esc>}o<esc>{V}<Plug>Chalk<esc>a

" }}}1

" Sudo save {{{
command! W w !sudo tee % > /dev/null
" }}}

" Open current file's directory {{{1
command! Finder silent exe '!open ' . expand("%:p:h")
command! Terminal silent exe '! osascript
            \ -e "tell application \"Terminal\" to activate"
            \ -e "tell application \"Terminal\" to do script \"cd ' .
            \ expand("%:p:h") . '\""'
" }}}1

" Buffers {{{1

noremap <Right> :bnext<cr>
noremap <Left> :bprevious<cr>
noremap <Up> :bfirst<cr>
noremap <Down> :blast<cr>

nnoremap <silent> <expr> <leader>q Quit() . "\<CR>"
nnoremap <silent> <expr> <leader>Q Quit() . "!\<CR>"
nnoremap <silent> <expr> <leader>x ":w\<CR>" . Quit() . "\<CR>"

if exists('*Quit')
    finish
endif

function! Quit()
    if len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) > 1
        return ':bd' " if there's more than one buffer, bdelete
    else | return ':q' | endif
endfunction

" }}}1

" Macros {{{1
nnoremap Q @@
" }}}1

