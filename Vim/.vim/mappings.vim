" Full Vim Mappings - extends essential mappings with advanced features

" Load essential mappings first
source ~/.vim/mappings-essential.vim

command! Center silent! exe 'normal! ggVG:center' . winwidth('%') . '\<CR>'

" Marks (accented characters for Brazilian keyboard)
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

" Switch buffers and quickfix items (extends essential)
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

" Yank unwrapped text
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

" Spell (extends essential)
function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction

nnoremap <expr> <localleader>sen ToggleSpellLang("en")
nnoremap <expr> <localleader>spt ToggleSpellLang("pt")
inoremap <c-s> <esc>D[s1z=$mNp`Nla

" Show current syntax group
map <leader>hi :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
    \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
    \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
    \ . ">"<CR>

" Add blank lines
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

" Open current file's directory (macOS-specific)
command! CD silent! lcd %:p:h
command! Finder silent exe '!open ' . expand("%:p:h")
command! Term silent exe '! osascript
            \ -e "tell application \"Terminal\" to activate"
            \ -e "tell application \"Terminal\" to do script \"cd ' .
            \ expand("%:p:h") . '\""'

" vimgrep
command! -nargs=1 G exe "vimgrep /<args>/g **/*." . expand('%:e') | cw

" Make a second <CR> delete comments added automatically
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

" Add text between commas
function! s:addCommas()
    if getline('.')[col('.')-1] == ' '
        return "i, ,\<ESC>i"
    else
        return "a, ,\<ESC>i"
    endif
endfunction

nnoremap <expr> <leader>, <SID>addCommas()

" Strip repeated lines
function! s:stripRepeatedLines()
    let lastLine = 0
    while line('$') != lastLine
        let lastLine = line('$')
        %s/\(^.*$\)\n^\1$/\1/g
    endwhile
endfunction

command! StripLines silent! call <SID>stripRepeatedLines()

" Thesaurus
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

" Paste while substituting target
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

" Replace text
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

" Auto mkdir
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

" Source .vimrc
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
