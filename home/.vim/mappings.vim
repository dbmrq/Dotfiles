let mapleader = " "

" normal mode
autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>

" format paragraphs
nnoremap <leader>gq vipgq

" really go to the end
noremap G G$

" insert single character
nnoremap <leader>s i_<Esc>r
nnoremap <leader>S a_<Esc>r

" go to last change
nnoremap <leader>b `.
" insert at last position
nnoremap <leader>i `^i

" edit and source vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <expr> <leader>sv SourceVimRC()

" select everything
nnoremap <leader>a ggVG

" switch windows
nnoremap <leader>w <c-w><c-w>
nnoremap <leader>W <c-w><c-w>

" move faster
nnoremap <leader>j 15j
nnoremap <leader>k 15k
nnoremap <leader>h 10h
nnoremap <leader>l 10l
vnoremap <leader>j 15j
vnoremap <leader>k 15k
vnoremap <leader>h 10h
vnoremap <leader>l 10l
" nnoremap <C-e> 3<C-e>
" nnoremap <C-y> 3<C-y>

" move in insert mode
inoremap <c-l> <right>
inoremap <c-h> <left>
inoremap <c-o> <esc>o

" copy everything, unwrapping it when necessary
" nnoremap <expr> Y CopyAll()
nnoremap Y y$

" fold
nnoremap <leader>f za
vnoremap <leader>f zf

" make a second <CR> delete comments added automatically
inoremap <expr> <CR> CROrUncomment()

" windows
nnoremap <expr> <leader>= SmartSizeUp()
nnoremap <expr> <leader>- SmartSizeDown()
nnoremap <expr> <leader>sp SmartSplit()

" toggle background color
nnoremap <leader>bg :call ToggleBG()<cr>
command! ToggleBG call ToggleBG()

" spelling
nnoremap <leader>tsp :set spell!<cr>
nnoremap <expr> <leader>sen ToggleSpellLang("en")
nnoremap <expr> <leader>spt ToggleSpellLang("pt")
" correct last mistake from insert mode
inoremap <c-s> <esc>[s1z=A

" Undo points
inoremap . .<C-g>u
inoremap , ,<C-g>u
inoremap ; ;<C-g>u
inoremap ! !<C-g>u
inoremap ? ?<C-g>u
inoremap : :<C-g>u


nnoremap <expr> <leader>, AddCommas()


" From https://blog.petrzemek.net/2016/04/06/
"           things-about-vim-i-wish-i-knew-earlier/

" Quickly select the text that was just pasted.
" This allows you to, e.g., indent it after pasting.
noremap gV `[v`]

" Allows you to easily replace the current word and all its occurrences.
nnoremap <Leader>rc :%s/\<<C-r><C-w>\>/
vnoremap <Leader>rc y:%s/<C-r>"/

" Allows you to easily change the current word and all occurrences to
" something else. The difference between this and the previous mapping is that
" the mapping below pre-fills the current word for you to change.
nnoremap <Leader>cc :%s/\<<C-r><C-w>\>/<C-r><C-w>/g
vnoremap <Leader>cc y:%s/<C-r>"/<C-r>"/g

