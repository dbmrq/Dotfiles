
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
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>+"
    elseif winwidth(0) != &columns
        return "5\<c-w>>"
    endif
endfunction
nnoremap <expr> <leader>= <SID>smartSizeUp()

function! s:smartSizeDown()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>-"
    elseif winwidth(0) != &columns
        return "5\<c-w><"
    endif
endfunction
nnoremap <expr> <leader>- <SID>smartSizeDown()

function! s:smartSplit()
  let l:height=winheight(0)
  let l:width=winwidth(0)
  if (l:height*2 > l:width)
     return ":split\<cr>"
  else
      return ":vsplit\<cr>"
  endif
endfunction
nnoremap <expr> <leader>sp <SID>smartSplit()

" }}}1

" Toggle background color {{{1

function! s:toggleBG()
    if &background ==# "dark"
        set background=light
    else
        set background=dark
    endif
    call s:lightlineUpdate()
endfunction

nnoremap <leader>bg :call <SID>toggleBG()<cr>
command! ToggleBG call <SID>toggleBG()

" }}}1

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

nnoremap J :call <SID>split()<cr>
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

function! s:ventilate()
    normal gggqG
    %s/\([.!?]\)\([\])"']*\)\s/\1\2\r/g
    let pattern = '\v[.!?][])"'']*($|\s)'
    execute 'g/' . pattern . '/execute "normal! V(gq"'
endfunction

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

