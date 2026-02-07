" Essential Vim Mappings
" Core keybindings that work everywhere without plugins

let mapleader = " "
let maplocalleader = ";"

" Marks - swap ' and ` for easier access to exact position
noremap ' `
noremap ` '

" Enter normal mode with jk/kj
autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>
vnoremap <CR> <esc>

" Movements - H/L for beginning/end of line (more intuitive than ^/$)
nnoremap H ^
nnoremap L $
onoremap H ^
onoremap L $
vnoremap H ^
vnoremap L $h

" Move by visual lines when wrap is on
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" Undo points - break undo at punctuation
inoremap . .<C-g>u
inoremap , ,<C-g>u
inoremap ; ;<C-g>u
inoremap ! !<C-g>u
inoremap ? ?<C-g>u
inoremap : :<C-g>u

" Yank to end of line (consistent with D and C)
nnoremap Y y$

" Registers - delete/change without yanking
noremap <leader>d "_d
noremap <leader>c "_c
noremap <leader>s "_s
noremap <leader>x "_x
xnoremap <silent> <leader>p p:let @+=@0<CR>:let @"=@0<CR>

" Fold toggle
nnoremap <leader>f za

" Spell toggle
nnoremap <localleader>ss :set spell!<cr>:set spell?<cr>

" Select text just pasted
noremap gV `[v`]

" Keep visual selection when indenting
vnoremap < <gv
vnoremap > >gv

" Center after search and jumps
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Add blank lines above/below
function! s:BlankUp(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>BlankUp", a:count)
endfunction

function! s:BlankDown(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>BlankDown", a:count)
endfunction

nnoremap <silent> <Plug>BlankUp   :<C-U>call <SID>BlankUp(v:count1)<CR>
nnoremap <silent> <Plug>BlankDown :<C-U>call <SID>BlankDown(v:count1)<CR>

nmap <leader>k <Plug>BlankUp
nmap <leader>j <Plug>BlankDown

" Don't move cursor on * search
nnoremap * *N

" Command-line navigation
cnoremap <C-a> <Home>
cnoremap <C-e> <End>

" Write with sudo
command! W w !sudo tee % > /dev/null

" Quick quit and save
nnoremap <silent> <expr> <localleader>q Quit() . "\<CR>"
nnoremap <silent> <expr> <localleader>Q Quit() . "!\<CR>"
nnoremap <silent> <expr> <localleader>x ":w\<CR>" . Quit() . "\<CR>"

function! Quit()
    if len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) > 1
        return ':bd'
    else | return ':q' | endif
endfunction

" Repeat last macro (Ex mode is rarely useful)
nnoremap Q @@

