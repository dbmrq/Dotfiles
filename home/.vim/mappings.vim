
" Mappings and commands

let mapleader = " "
let maplocalleader = ";"

command! Center silent! exe 'normal! ggVG:center' . winwidth('%') . '\<CR>'

" Marks {{{1

noremap ' `
noremap ` '

nnoremap à `a
nnoremap è `a
nnoremap ì `a
nnoremap ò `a
nnoremap ù `a
nnoremap á 'a
nnoremap é 'a
nnoremap í 'a
nnoremap ó 'a
nnoremap ú 'a

" }}}1

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
nnoremap K H
nnoremap J L
" I'll use <CR> and <BS> so split and join

" }}}

" Undo points {{{

inoremap . .<C-g>u
inoremap , ,<C-g>u
inoremap ; ;<C-g>u
inoremap ! !<C-g>u
inoremap ? ?<C-g>u
inoremap : :<C-g>u

" }}}

" " Tab completion and pop up menu {{{1
" inoremap <expr> <TAB>  pumvisible() ? "\<c-n>" : "\<TAB>"
" inoremap <expr> <S-TAB>  pumvisible() ? "\<c-p>" : "\<S-TAB>"
" inoremap <expr> <c-j>  pumvisible() ? "\<Down>" : "j"
" inoremap <expr> <c-k>  pumvisible() ? "\<Up>" : "<Esc>lDA"
" " }}}1

" " Insert single character {{{
" nnoremap <leader>i i_<Esc>r
" nnoremap <leader>I a_<Esc>r
" " }}}

" " Resize windows {{{1

" function! HasHorizontalSplit()
"     return &lines - winheight(0) > 2
" endfunction

" function! HasVerticalSplit()
"     return winwidth(0) != &columns
" endfunction

" nnoremap <expr> <m-up> HasHorizontalSplit() ? ":res +5\<CR>" : ":split\<CR>"
" nnoremap <expr> <m-down> HasHorizontalSplit() ? ":res -5\<CR>" : ":split\<CR>"
" nnoremap <expr> <m-right> HasVerticalSplit() ? ":vertical res +5\<CR>" : ":vsplit\<CR>"
" nnoremap <expr> <m-left> HasVerticalSplit() ? ":vertical res -5\<CR>" : ":vsplit\<CR>"

" " }}}1

" Switch windows, buffers and quickfix items {{{

nnoremap <leader>w <c-w><c-w>
nnoremap <leader>b :b#<cr>

if has('gui_macvim')
    let macvim_skip_cmd_opt_movement = 1
endif

nnoremap <F13> :buffers<CR>:buffer<Space>

nnoremap <expr> <Down> NextBufferOrQF('next')
nnoremap <expr> <Up> NextBufferOrQF('previous')
nnoremap <expr> <Left> NextBufferOrQF('first')
nnoremap <expr> <Right> NextBufferOrQF('last')

function! NextBufferOrQF(command) 
    for i in range(1, winnr('$')) 
        let bnum = winbufnr(i) 
        if getbufvar(bnum, '&buftype') == 'quickfix' 
            return ":c" . a:command . "\<cr>zvzz"
        endif 
    endfor 
    return ":b" . a:command . "\<cr>"
endfunction 

" nnoremap <c-Right> <c-w>l
" nnoremap <c-Left> <c-w>h
" nnoremap <c-Up> <c-w>k
" nnoremap <c-Down> <c-w>j

" }}}

" Yank {{{

nnoremap Y y$

function! s:YankUnwrapped(type, ...)
    if a:0
        normal! gv"ay
    elseif a:type == 'line'
        normal! `[V`]"ay
    else
        normal! `[v`]"ay
    endif
    new
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    normal! "ap
    %normal! vipJ
    normal! ggvG$"+y
    q
endfunction

vnoremap <leader>y :call <SID>YankUnwrapped(visualmode(), 1)<CR>
nnoremap <leader>y :set opfunc=<SID>YankUnwrapped<CR>g@

" }}}

" Registers {{{1

noremap <leader>d "_d
noremap <leader>c "_c
noremap <leader>s "_s
noremap <leader>x "_x
" xnoremap <leader>p "_dP
xnoremap <silent> <leader>p p:let @+=@0<CR>:let @"=@0<CR>

" " Use unnamed register for yank and paste, but delete to Z {{{2

" nnoremap <expr> y (v:register ==# '"' ? '"+' : '') . 'y'
" nnoremap <expr> yy (v:register ==# '"' ? '"+' : '') . 'yy'
" nnoremap <expr> Y (v:register ==# '"' ? '"+' : '') . 'Y'
" xnoremap <expr> y (v:register ==# '"' ? '"+' : '') . 'y'
" xnoremap <expr> Y (v:register ==# '"' ? '"+' : '') . 'Y'

" nnoremap <expr> p (v:register ==# '"' ? '"+' : '') . 'p'
" nnoremap <expr> P (v:register ==# '"' ? '"+' : '') . 'P'

" nnoremap <expr> d (v:register ==# '"' ? '"z' : '') . 'd'
" nnoremap <expr> dd (v:register ==# '"' ? '"z' : '') . 'dd'
" nnoremap <expr> D (v:register ==# '"' ? '"z' : '') . 'D'
" xnoremap <expr> d (v:register ==# '"' ? '"z' : '') . 'd'
" xnoremap <expr> D (v:register ==# '"' ? '"z' : '') . 'D'

" nnoremap <expr> c (v:register ==# '"' ? '"z' : '') . 'c'
" nnoremap <expr> cc (v:register ==# '"' ? '"z' : '') . 'cc'
" nnoremap <expr> C (v:register ==# '"' ? '"z' : '') . 'C'
" xnoremap <expr> c (v:register ==# '"' ? '"z' : '') . 'c'
" xnoremap <expr> C (v:register ==# '"' ? '"z' : '') . 'C'

" " nnoremap <expr> s (v:register ==# '"' ? '"z' : '') . 's'
" "  <expr> S (v:register ==# '"' ? '"z' : '') . 'S'
" " xnoremap <expr> s (v:register ==# '"' ? '"z' : '') . 's'
" " xnoremap <expr> S (v:register ==# '"' ? '"z' : '') . 'S'

" " }}}2

" }}}1

" Fold {{{
nnoremap <leader>f za
" }}}

" Spell {{{

nnoremap <localleader>ss :set spell!<cr>:set spell?<cr>

function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction

nnoremap <expr> <localleader>sen ToggleSpellLang("en")
nnoremap <expr> <localleader>spt ToggleSpellLang("pt")

" Correct last mistake from insert mode
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

" Add blank lines {{{1

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

nnoremap <leader>aa mn{O<esc>}o<esc>`n
vmap <leader>aa <esc>`<<Plug>BlankUp`><Plug>BlankDown<esc>`<kV`>j

" }}}1

" Open current file's directory {{{1
" autocmd BufEnter * if &ft !=? 'tex' | silent! lcd %:p:h

command! CD silent! lcd %:p:h
command! Finder silent exe '!open ' . expand("%:p:h")
command! Term silent exe '! osascript
            \ -e "tell application \"Terminal\" to activate"
            \ -e "tell application \"Terminal\" to do script \"cd ' .
            \ expand("%:p:h") . '\""'
" }}}1

" Write and/or quit {{{1

command! W w !sudo tee % > /dev/null

nnoremap <silent> <expr> <localleader>q Quit() . "\<CR>"
nnoremap <silent> <expr> <localleader>Q Quit() . "!\<CR>"
nnoremap <silent> <expr> <localleader>x ":w\<CR>" . Quit() . "\<CR>"

function! Quit()
    if len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) > 1
        return ':bd' " if there's more than one buffer, bdelete
    else | return ':q' | endif
endfunction

" }}}1

" Close the quickfix window {{{1
autocmd BufReadPost quickfix nnoremap <buffer> q :q<CR>
" }}}1

" Macros {{{1
nnoremap Q @@
" }}}1

" vimgrep {{{1
command! -nargs=1 G exe "vimgrep /<args>/g **/*." . expand('%:e') | cw
" }}}1

" Make a second <CR> delete comments added automatically {{{1

function! CROrUncomment()
    for comment in map(split(&l:comments, ','),
        \ 'substitute(v:val, "^.\\{-}:", "", "")')
            if getline('.') =~ '\V' . escape(comment, '\') . ' \$'
                return repeat("\<BS>", strchars(comment) + 1)
            endif
    endfor
    return "\<cr>"
endfunction

inoremap <expr> <CR> CROrUncomment()

" }}}1

" " Toggle background color {{{1

" function! s:toggleBG()
"     if &background ==# "dark"
"         set background=light
"     else
"         set background=dark
"     endif
"     if exists("g:loaded_lightline")
"         call LightlineUpdate()
"     endif
" endfunction

" nnoremap <leader>bg :call <SID>toggleBG()<cr>
" command! ToggleBG call <SID>toggleBG()

" " }}}1

" Add text between commas {{{1

function! s:addCommas()
    if getline('.')[col('.')-1] == ' '
        return "i, ,\<ESC>i"
    else
        return "a, ,\<ESC>i"
    endif
endfunction

nnoremap <expr> <leader>, <SID>addCommas()

" }}}1

" Split and join lines {{{1

" function! s:FindClosest(...)
"     let line = getline('.')
"     let col = col('.') - 1
"     for arg in a:000
"         let i = 0
"         while i < &l:textwidth
"             if line[col - i] =~ arg
"                 call cursor(line, col - i + 1)
"                 return
"             elseif line[col + i] =~ arg
"                 call cursor(line, col + i + 1)
"                 return
"             endif
"             let i += 1
"         endwhile
"     endfor
" endfunction

" function! s:split()
"     let line = getline('.')
"     let col = col('.') - 1
"     let i = 0
"     while i < (&l:textwidth / 2)
"         if line[col - i] == ' '
"             call cursor(line, col - i + 1)
"             execute "normal! r\<cr>"
"             return
"         elseif line[col + i] == ' '
"             call cursor(line, col + i + 1)
"             execute "normal! r\<cr>"
"             return
"         endif
"         let i += 1
"     endwhile
"     execute "normal! i\<cr>"
" endfunction

" nnoremap <CR> i<CR><esc>
" au FileType markdown,text,tex nnoremap <CR> :call <SID>FindClosest(' ')<CR>r<CR>

nnoremap <BS> J
nnoremap <CR> i<CR><esc>
autocmd BufReadPost quickfix silent! unmap <CR>

" }}}1

" Strip repeated lines {{{1

function! s:stripRepeatedLines()
    let lastLine = 0
    while line('$') != lastLine
        let lastLine = line('$')
        %s/\(^.*$\)\n^\1$/\1/g
    endwhile
endfunction

command! StripLines silent! call <SID>stripRepeatedLines()

" }}}1

" Thesaurus {{{1

function! s:thesaurus()
    let s:saved_ut = &ut
    if &ut > 200 | let &ut = 200 | endif
    augroup ThesaurusAuGroup
        autocmd CursorHold,CursorHoldI <buffer>
                    \ let &ut = s:saved_ut |
                    \ set iskeyword-=32 |
                    \ autocmd! ThesaurusAuGroup
    augroup END
    return ":set iskeyword+=32\<cr>vaWovea\<c-x>\<c-t>"
endfunction

nnoremap <expr> <leader>t <SID>thesaurus()

" }}}1

" Paste while substituting target {{{1

function! TargetPaste(type, ...)
    let savedRegister = &l:clipboard == 'unnamed' ? @* : @"
    if a:type == 'line'
        normal! `[V`]p
    else
        normal! `[v`]p
    endif
    if &l:clipboard =~ 'unnamed'
        let @* = savedRegister
    else
        let @" = savedRegister
    endif
endfunction

nnoremap <leader>r :set opfunc=TargetPaste<CR>g@

" }}}1

" Replace text {{{1

" Replace last search pattern
nnoremap <localleader>cl :%s/<C-r>///g<left><left>

function! Replace(type, ...)
    if a:0
        normal! gv"my
    elseif a:type == 'line'
        normal! `[V`]"my
    else
        normal! `[v`]"my
    endif
    let selection = escape(@m, '\?')
    let selection = substitute(selection, '\n', '\\n', 'g')
    let command = input('', ":%s/" . selection . "//gc\<left>\<left>\<left>")
    " call inputsave()
    " let replacement = input('Replace "' . selection . '" with: ')
    " let command = input('', "%s/\\V" . selection . "//gc")
    " call inputrestore()
    execute command
endfunction

nnoremap <localleader>c :set opfunc=Replace<CR>g@
vnoremap <localleader>c :call Replace(visualmode(), 1)<CR>

function! ReplaceLastChange()
    let pattern = substitute(escape(@*, '\?'), '\n', '\\n', 'g')
    let replacement = substitute(escape(@., '\?'), '\n', '\\r', 'g')
    try
        execute "%s/\\V" . pattern . "/" . replacement . "/gc"
    catch /E486/
        echo 'Pattern not found: "' . pattern . '"'
    endtry
endfunction

nnoremap <localleader>cc :call ReplaceLastChange()<cr>

" }}}1

" " Indentation {{{1

" vnoremap < <gv
" vnoremap > >gv

" " }}}1

" Auto mkdir {{{1
function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END
" }}}1

" Edit vimrc {{{
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
" }}}

" Source .vimrc {{{1

if exists("g:loaded_sourceVimRC")
  finish
endif
let g:loaded_sourceVimRC = 1

function! s:sourceVimRC()
    so $MYVIMRC
    if has('gui_running') && filereadable(expand('~/.gvimrc'))
        so ~/.gvimrc
    endif
    let &ft=&ft
    set shortmess+=c
    if exists("g:loaded_gitgutter")
        call gitgutter#highlight#define_sign_column_highlight()
        call gitgutter#highlight#define_highlights()
    endif
    if exists("g:loaded_lightline")
        call LightlineUpdate()
    endif
endfunction

nnoremap <localleader>sv :call <SID>sourceVimRC()<CR>
command! SourceVimRC call <SID>sourceVimRC()

autocmd BufWritePost $MYVIMRC,~/.vim/*.vim SourceVimRC

" }}}1

