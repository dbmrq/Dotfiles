
" Source .vimrc {{{

function! SourceVimRC()
    let command = ":so $MYVIMRC\<cr>:let &ft=&ft\<cr>:set shortmess+=c\<cr>"
    if has('gui_running') && filereadable(expand('~/.gvimrc'))
        let command = command . ":so ~/.gvimrc\<cr>"
    endif
    return command
endfunction

nnoremap <expr> <leader>sv SourceVimRC()

" }}}

" Copy text unwrapped {{{

function! CopyUnwrapped()
    if &l:formatoptions =~ "t"
        new
        normal! "ay
        setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
        normal! "ap
        %norm vipJ
        normal! ggvG$"+y
        q
    endif
endfunction

nnoremap <leader>y :call CopyUnwrapped()<cr>
vnoremap <leader>y :call CopyUnwrapped()<cr>

" }}}

" Copy everything {{{

function! CopyAll()
    if &l:formatoptions =~ "t"
        return "ma:g/./,-/\\n$/j\<cr>ggvG$\"\+yu\`a"
    endif
    return "maggvG$\"\+yu\`a"
endfunction

nnoremap <expr> <leader>Y CopyAll()

" }}}

" Make a second <CR> delete comments added automatically {{{

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

" }}}

" Split and resize windows {{{

function! SmartSizeUp()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>+"
    elseif winwidth(0) != &columns
        return "5\<c-w>>"
    endif
endfunction
nnoremap <expr> <leader>= SmartSizeUp()

function! SmartSizeDown()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>-"
    elseif winwidth(0) != &columns
        return "5\<c-w><"
    endif
endfunction
nnoremap <expr> <leader>- SmartSizeDown()

function! SmartSplit()
  let l:height=winheight(0)
  let l:width=winwidth(0)
  if (l:height*2 > l:width)
     return ":split\<cr>"
  else
      return ":vsplit\<cr>"
  endif
endfunction
nnoremap <expr> <leader>sp SmartSplit()

" }}}

" toggle background color {{{

function! ToggleBG()
    if &background ==# "dark"
        set background=light
    else
        set background=dark
    endif
    call LightlineUpdate()
endfunction

nnoremap <leader>bg :call ToggleBG()<cr>
command! ToggleBG call ToggleBG()

" }}}

" Add and remove a spelllang {{{

function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction

nnoremap <expr> <leader>sen ToggleSpellLang("en")
nnoremap <expr> <leader>spt ToggleSpellLang("pt")

" }}}

" Surround text with commas {{{

function! AddCommas()
    if getline('.')[col('.')-1] == ' '
        return "i, ,\<ESC>i"
    else
        return "a, ,\<ESC>i"
    endif
endfunction

nnoremap <expr> <leader>, AddCommas()

" }}}

" Auto increment fold markers {{{

function! IncrementMarkers() range
    if a:lastline - a:firstline > 0
        let first_line = a:firstline
        let last_line = a:lastline
    else
        let first_line = 0
        let last_line = line('$')
    endif
    let markers = split(&l:foldmarker, ',')
    let i = 9
    while i > 0
        silent! execute first_line . ',' . last_line . 's/' .
                    \ markers[0] . i . '/' . markers[0] . (i + 1) . '/g'
        silent! execute first_line . ',' . last_line . 's/' .
                    \ markers[0] . '\n/' . markers[0] . '1\r/g'
        silent! execute first_line . ',' . last_line . 's/' .
                    \ markers[1] . i . '/' . markers[1] . (i + 1) . '/g'
        silent! execute first_line . ',' . last_line . 's/' .
                    \ markers[1] . '\n/' . markers[1] . '1\r/g'
        let i -= 1
    endwhile
endfunction

vnoremap <leader>f :IncrementMarkers<cr>gvzf
command! -range=% IncrementMarkers <line1>,<line2>call IncrementMarkers()

" }}}

function! Ventilate()
    normal gggqG
    %s/\([.!?]\)\([\])"']*\)\s/\1\2\r/g
    let pattern = '\v[.!?][])"'']*($|\s)'
    execute 'g/' . pattern . '/execute "normal! V(gq"'
endfunction

