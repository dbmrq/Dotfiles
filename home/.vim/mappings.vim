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

" this uses zg and zw for the global spellfiles
" and zG and zW for file specific spellfiles.
" :au BufNewFile,BufRead * let &l:spellfile = expand('%:p:h') . '/.' .
"     \ substitute(expand('%:t'), '\(.*\)\..*', '\1', '') . '.utf-8.add'
" nnoremap zG :call LocalSpell("zG")<cr>
" nnoremap zW :call LocalSpell("zW")<cr>
" nnoremap zuG :call LocalSpell("zuG")<cr>
" nnoremap zuW :call LocalSpell("zuW")<cr>
" nnoremap zg :call GlobalSpell("zg")<cr>
" nnoremap zw :call GlobalSpell("zw")<cr>
" nnoremap zug :call GlobalSpell("zug")<cr>
" nnoremap zuw :call GlobalSpell("zuw")<cr>
" vnoremap zG :call LocalSpell("gvzG")<cr>
" vnoremap zW :call LocalSpell("gvzW")<cr>
" vnoremap zuG :call LocalSpell("gvzuG")<cr>
" vnoremap zuW :call LocalSpell("gvzuW")<cr>
" vnoremap zg :call GlobalSpell("gvzg")<cr>
" vnoremap zw :call GlobalSpell("gvzw")<cr>
" vnoremap zug :call GlobalSpell("gvzug")<cr>
" vnoremap zuw :call GlobalSpell("gvzuw")<cr>

