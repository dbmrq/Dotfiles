set tabstop=2
set shiftwidth=2
set expandtab

command! CheckBreaks %s/^\([^%]\+\)\n/\1%\r/gc

let maplocalleader = " "

let b:AutoPairs={'(':')', '[':']', '{':'}','"':'"'}
inoremap `` ``''<esc>hi


vnoremap <leader>` <esc>`>a''<esc>`<i``<esc>%
nnoremap <leader>` viw<esc>a''<esc>bbi``<esc>
