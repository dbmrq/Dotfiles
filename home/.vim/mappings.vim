let mapleader = " "

" normal mode
autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>
" vnoremap jk <esc>
" vnoremap kj <esc>
" vnoremap JK <esc>
" vnoremap KJ <esc>
" cnoremap jk <C-c>
" cnoremap kj <C-c>
" cnoremap JK <C-c>
" cnoremap KJ <C-c>

" format paragraphs
nnoremap <leader>gq vipgq

" really go to the end
noremap G G$

" insert single character
" nnoremap <leader>s i_<Esc>r
" nnoremap <leader>S a_<Esc>r

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

" move lines up and down
" (needs unimpaired.vim)
let s:uname = system("uname -s")
if !has("gui_running") && s:uname =~ "Darwin"
    nmap k [e
    nmap j ]e
    vmap k [egv
    vmap j ]egv
else
    nmap <m-k> [e
    vmap <m-k> [egv
    nmap <m-j> ]e
    vmap <m-j> ]egv
endif

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

" copy everything, unwrapping it when necessary
nnoremap <expr> Y CopyAll()

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
nnoremap zz 1z=
nnoremap <leader>tsp :set spell!<cr>
nnoremap <expr> <leader>sen ToggleSpellLang("en")
nnoremap <expr> <leader>spt ToggleSpellLang("pt")
nnoremap <c-m> :call LoopSpell()<CR>

" plugins
nnoremap <leader>ut :UndotreeToggle<cr>
nnoremap <leader>gy :Goyo<cr>
nnoremap <leader>tp :TogglePencil<cr>

