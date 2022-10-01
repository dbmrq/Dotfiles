let maplocalleader = " "

set tabstop=2
set shiftwidth=2
set expandtab

" Curly braces get confusing with TeX
setlocal foldmarker=\ >>>,\ <<<

" Add % to the end of lines
command! CheckBreaks %s/^\([^%]\+\)\n/\1%\r/gc

" Replace diacritics {{{1

function! s:diacritics()
    %s/\V{\\'a}/á/g
    %s/\V{\\`a}/à/g
    %s/\Và/à/g
    %s/\V{\\ˆa}/â/g
    %s/\V{\\~a}/ã/g
    %s/\Vã/ã/g
    %s/\V{\\'A}/Á/g
    %s/\V{\\`A}/À/g
    %s/\V{\\ˆA}/Â/g
    %s/\V{\\~A}/Ã/g

    %s/\V{\\'e}/é/g
    %s/\Vé/é/g
    %s/\V{\\^e}/ê/g
    %s/\Vê/ê/g
    %s/\V{\\'E}/É/g
    %s/\V{\\^E}/Ê/g

    %s/\V{\\'i}/í/g
    %s/\V{\\'I}/Í/g

    %s/\V{\\'o}/ó/g
    %s/\Vó/ó/g
    %s/\V{\\ˆo}/ô/g
    %s/\V{\\~o}/õ/g
    %s/\Võ/õ/g
    %s/\V{\\'O}/Ó/g
    %s/\V{\\ˆO}/Ô/g
    %s/\V{\\~O}/Õ/g

    %s/\V{\\'u}/ú/g
    %s/\Vú/ú/g
    %s/\V{\\"u}/ü/g
    %s/\V{\\'U}/Ú/g
    %s/\V{\\"U}/Ü/g

    %s/\V{\\c c}/ç/g
    %s/\Vç/ç/g
endfunction

command! ReplaceDiacritics silent! call <SID>diacritics()

" }}}1

