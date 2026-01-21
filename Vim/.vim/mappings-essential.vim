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

" Switch windows and buffers
nnoremap <leader>w <c-w><c-w>
nnoremap <leader>b :b#<cr>

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

" Close quickfix with q
autocmd BufReadPost quickfix nnoremap <buffer> q :q<CR>

" Edit vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" Cheat sheet - quick reference of keybindings
command! Cheat call ShowCheatSheet()
nnoremap <leader>? :Cheat<CR>

function! ShowCheatSheet()
    let l:cheat = [
        \ '═══════════════════════════════════════════════════════════════════',
        \ '                         QUICK REFERENCE                           ',
        \ '═══════════════════════════════════════════════════════════════════',
        \ '',
        \ '  MOVEMENTS                          EDITING                       ',
        \ '  ─────────────────────────────────  ───────────────────────────── ',
        \ '  H / L      Start / End of line    Y         Yank to end of line ',
        \ '  j / k      Visual line up/down    <leader>d Delete (no yank)    ',
        \ '  <C-d/u>    Half-page + center     <leader>c Change (no yank)    ',
        \ '  n / N      Next/prev + center     <leader>p Paste (keep register)',
        \ '  *          Search word (stay)     gV        Select last paste   ',
        \ '  gj / gk    Actual line up/down    < / >     Indent (keep sel)   ',
        \ '',
        \ '  NORMAL MODE                        INSERT MODE                   ',
        \ '  ─────────────────────────────────  ───────────────────────────── ',
        \ '  Q          Repeat last macro      jk / kj   Exit to normal      ',
        \ '  <leader>f  Toggle fold            <C-a/e>   Line start/end      ',
        \ '  <leader>w  Next window                                          ',
        \ '  <leader>b  Alternate buffer       COMMAND LINE                  ',
        \ '  ;q / ;x    Quit / Save+quit       ───────────────────────────── ',
        \ '  <leader>ev Edit vimrc             <C-a/e>   Line start/end      ',
        \ '',
        \ '  MARKS                              VIM DEFAULTS TO REMEMBER      ',
        \ '  ─────────────────────────────────  ───────────────────────────── ',
        \ "  '          Jump to mark (exact)   J         Join lines          ",
        \ "  `          Jump to mark (line)    K         Keyword lookup      ",
        \ '  (swapped for easier exact jump)   <CR>      Move down           ',
        \ '                                    g;/g,     Jump changelist     ',
        \ '  LEADERS                            gi        Resume insert      ',
        \ '  ─────────────────────────────────  gv        Reselect visual    ',
        \ '  <Space>    Leader                 gf        Go to file          ',
        \ '  ;          Local leader           zt/zz/zb  Scroll top/mid/bot  ',
        \ '',
        \ '═══════════════════════════════════════════════════════════════════',
        \ '  Press q or <Esc> to close                                        ',
        \ '═══════════════════════════════════════════════════════════════════',
        \ ]

    " Create a new scratch buffer
    new
    setlocal buftype=nofile bufhidden=wipe noswapfile nowrap
    setlocal nonumber norelativenumber
    call setline(1, l:cheat)
    setlocal nomodifiable

    " Size the window to fit content
    execute 'resize ' . (len(l:cheat) + 1)

    " Close with q or Escape
    nnoremap <buffer> q :close<CR>
    nnoremap <buffer> <Esc> :close<CR>
endfunction
