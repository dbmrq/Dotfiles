let maplocalleader = " "

set tabstop=2
set shiftwidth=2
set expandtab

" Curly braces get confusing with TeX
setlocal foldmarker=\ >>>,\ <<<

" Add % to the end of lines
command! CheckBreaks %s/^\([^%]\+\)\n/\1%\r/gc

