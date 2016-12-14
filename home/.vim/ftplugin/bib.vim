
setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
setlocal commentstring=\%\ %s


" Check for missing commas after each field
command! -range=% CheckCommas keepp <line1>,<line2>s/}\n\(\s\+\a\)/},\r\1/gc

" Replace diacritics {{{1

function! s:diacritics()
    %s/\V{\\'a}/á/g
    %s/\V{\\`a}/à/g
    %s/\V{\\ˆa}/â/g
    %s/\V{\\~a}/ã/g
    %s/\V{\\'A}/Á/g
    %s/\V{\\`A}/À/g
    %s/\V{\\ˆA}/Â/g
    %s/\V{\\~A}/Ã/g

    %s/\V{\\'e}/é/g
    %s/\V{\\^e}/ê/g
    %s/\V{\\'E}/É/g
    %s/\V{\\^E}/Ê/g

    %s/\V{\\'i}/í/g
    %s/\V{\\'I}/Í/g

    %s/\V{\\'o}/ó/g
    %s/\V{\\ˆo}/ô/g
    %s/\V{\\~o}/õ/g
    %s/\V{\\'O}/Ó/g
    %s/\V{\\ˆO}/Ô/g
    %s/\V{\\~O}/Õ/g

    %s/\V{\\'u}/ú/g
    %s/\V{\\"u}/ü/g
    %s/\V{\\'U}/Ú/g
    %s/\V{\\"U}/Ü/g

    %s/\V{\\c c}/ç/g
endfunction

command! ReplaceDiacritics silent! call <SID>diacritics()

" }}}1

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


