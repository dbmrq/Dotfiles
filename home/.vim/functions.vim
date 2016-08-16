function! SourceVimRC()
    let command = ":so $MYVIMRC\<cr>:let &ft=&ft\<cr>:set shortmess+=c\<cr>"
    if has('gui_running') && filereadable(expand('~/.gvimrc'))
        let command = command . ":so ~/.gvimrc\<cr>"
    endif
    return command
endfunction

function! CopyAll()
    if &l:formatoptions =~ "t"
        return "ma:g/./,-/\\n$/j\<cr>ggvG$\"\+yu\`a"
    endif
    return "maggvG$\"\+yu\`a"
endfunction

function! CROrUncomment()
    for comment in map(split(&l:comments, ','),
        \ 'substitute(v:val, "^.\\{-}:", "", "")')
            if getline('.') =~ '\V' . escape(comment, '\') . ' \$'
                return repeat("\<BS>", strchars(comment) + 1)
            endif
    endfor
    return "\<cr>"
endfunction

function! SmartSizeUp()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>+"
    elseif winwidth(0) != &columns
        return "5\<c-w>>"
    endif
endfunction

function! SmartSizeDown()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>-"
    elseif winwidth(0) != &columns
        return "5\<c-w><"
    endif
endfunction

function! SmartSplit()
  let l:height=winheight(0)
  let l:width=winwidth(0)
  if (l:height*2 > l:width)
     return ":split\<cr>"
  else
      return ":vsplit\<cr>"
  endif
endfunction

function! ToggleBG()
    if &background ==# "dark"
        set background=light
    else
        set background=dark
    endif
    let g:lightline = {'colorscheme': 'solarized',}
endfunction

function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction

function! Ventilate()
    normal gggqG
    %s/\([.!?]\)\([\])"']*\)\s/\1\2\r/g
    let pattern = '\v[.!?][])"'']*($|\s)'
    execute 'g/' . pattern . '/execute "normal! V(gq"'
endfunction

