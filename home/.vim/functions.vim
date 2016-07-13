
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


" Loop through spellling mistakes

" let s:spell_position = []
" let s:spell_count = 0
" let s:spell_word = ""

" function! LoopSpell()

"     if s:spell_position != getpos('.') ||
"             \ (s:spell_count > 0 && s:spell_word !~ expand("<cword>"))
"         let s:spell_count = 0
"         let s:spell_position = getpos('.')
"     endif

"     if getline('.')[col('.')-1] =~# '[.,;-=\(\)\{\}\[\] ]'
"         return
"     endif

"     if s:spell_count > 0
"         silent execute "normal! u"
"     endif

"     let s:current_word = expand("<cword>")
"     if len(s:current_word) <= 0
"         return
"     endif

"     let s:spell_suggestions = spellsuggest(expand(s:current_word))
"     if len(s:spell_suggestions) <= 0
"         return
"     endif

"     if s:spell_count >= len(s:spell_suggestions)
"         let s:spell_word = s:current_word
"         let s:spell_count = 0
"     else
"         let s:spell_word = s:spell_suggestions[s:spell_count]
"         let s:spell_count += 1
"     endif
"     silent execute "normal! ciw" . s:spell_word
"     silent execute "normal! b"
"     let s:spell_position = getpos('.')

" endfunction

