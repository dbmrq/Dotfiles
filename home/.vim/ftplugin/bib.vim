let maplocalleader = " "

vnoremap <localleader>tab :GTabularize /=<cr>
nnoremap <localleader>tab ggVG:GTabularize /=<cr>

command! CheckCommas %s/}\n\([^\n]\)/},\r\1/gc
