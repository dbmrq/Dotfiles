
" Copy text unwrapped {{{1

function! CopyUnwrapped(type, ...)
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

vnoremap <leader>y :call CopyUnwrapped(visualmode(), 1)<CR>
nnoremap <leader>y :set opfunc=CopyUnwrapped<CR>g@

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

" Split and resize windows {{{1

function! s:smartSizeUp()
    if winwidth(0) == &columns
        " if there are no vertical splits
        return ":res +5\<CR>"
    else
        return ":vertical res +5\<CR>"
    endif
endfunction
nnoremap <expr> <leader>= <SID>smartSizeUp()

function! s:smartSizeDown()
    if winwidth(0) == &columns
        " if there are no vertical splits
        return ":res -5\<CR>"
    else
        return ":vertical res -5\<CR>"
    endif
endfunction
nnoremap <expr> <leader>- <SID>smartSizeDown()

function! s:smartSplit()
    let l:height=winheight(0)
    let l:width=winwidth(0)
    if l:width > 2 * &tw + 4 || l:width > l:height * 3
        return ":vsplit\<cr>"
    else
        return ":split\<cr>"
    endif
endfunction
nnoremap <expr> <leader>sp <SID>smartSplit()

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

" Add and remove a spelllang {{{1

function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction

nnoremap <expr> <leader>sen ToggleSpellLang("en")
nnoremap <expr> <leader>spt ToggleSpellLang("pt")

" }}}1

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

" Set cursor to the closest specified character {{{1
function! FindClosest(...)
    let line = getline('.')
    let col = col('.') - 1
    for arg in a:000
        let i = 0
        while i < &l:textwidth
            if line[col - i] =~ arg
                call cursor(line, col - i + 1)
                return
            elseif line[col + i] =~ arg
                call cursor(line, col + i + 1)
                return
            endif
            let i += 1
        endwhile
    endfor
endfunction
" }}}1

" Split lines at space {{{1

function! s:split()
    let line = getline('.')
    let col = col('.') - 1
    let i = 0
    while i < (&l:textwidth / 2)
        if line[col - i] == ' '
            call cursor(line, col - i + 1)
            execute "normal! r\<cr>"
            return
        elseif line[col + i] == ' '
            call cursor(line, col + i + 1)
            execute "normal! r\<cr>"
            return
        endif
        let i += 1
    endwhile
    execute "normal! i\<cr>"
endfunction

nnoremap J :call FindClosest(' ')<cr>r<cr>
nnoremap K J

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
" }}}1

" Replace text {{{1

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
    call inputsave()
    let replacement = input('Replace "' . selection . '" with: ')
    " let command = input('', "%s/\\V" . selection . "//gc")
    call inputrestore()
    execute "%s/\\V" . selection . "/" . replacement . "/gc"
    " execute command
endfunction

nnoremap <leader>c :set opfunc=Replace<CR>g@
vnoremap <leader>c :call Replace(visualmode(), 1)<CR>


function! ReplaceLastChange()
    let pattern = substitute(escape(@*, '\?'), '\n', '\\n', 'g')
    let replacement = substitute(escape(@., '\?'), '\n', '\\r', 'g')
    try
        execute "%s/\\V" . pattern . "/" . replacement . "/gc"
    catch /E486/
        echo 'Pattern not found: "' . pattern . '"'
    endtry
endfunction

nnoremap <leader>cc :call ReplaceLastChange()<cr>

" }}}1

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

nnoremap <leader>sv :call <SID>sourceVimRC()<CR>
command! SourceVimRC call <SID>sourceVimRC()

autocmd BufWritePost $MYVIMRC,~/.vim/*.vim SourceVimRC

" }}}1

