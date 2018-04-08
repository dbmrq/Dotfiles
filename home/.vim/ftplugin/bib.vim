
source ~/.vim/ftplugin/plaintex.vim

setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
setlocal commentstring=\%\ %s


" Check for missing commas after each field
command! -range=% CheckCommas keepp <line1>,<line2>s/}\n\(\s\+\a\)/},\r\1/gc

" Break lines and align equal signs {{{
" (Experimental. But awesome. Requires vim-easy-align.)

command! AlignEqual 0,$EasyAlign 1 /= {/ { 'right_margin' : 0 }

function! BreakLines()
    g/.*/normal! gww
    normal! gg
    let spaces = repeat(' ', match(getline(search('= {')), '{') + 1)
    execute "%s/\\v^\\s*([^@} %][^=]*)$/" . spaces . "\\1/g"
endfunction

function! Align()
    AlignEqual
    let lastLine = 0
    while line('$') != lastLine
        let lastLine = line('$')
        call BreakLines()
    endwhile
endfunction

command! Align call Align()

" }}}

