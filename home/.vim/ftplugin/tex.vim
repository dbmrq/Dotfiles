source ~/.vim/ftplugin/plaintex.vim

set spell
set spelllang=pt


" Replace hardcoded quotes with \enquote
command! Enquote %s/``\(\_.\{-}\)''/\\enquote{\1}/g


" Surround words {{{

" \emph
nnoremap <leader>em viw<esc>a}<esc>bi\emph{<esc>
vnoremap <leader>em <esc>`>a}<esc>`<i\emph{<esc>%

" other commands
nnoremap <leader>cm viw<esc>a}<esc>bi\{<esc>i
vnoremap <leader>cm <esc>`>a}<esc>`<i\{<esc>i

"}}}


" Show word count when saving {{{

au BufWritePost <buffer> redraw | echo WrittenString() . ' | ' . WordCount()

function! WrittenString()
    return '"' . expand('%:h:t') . '/' . expand('%:t') .
        \ '" ' . line('$') . ' lines written'
endfunction

function! WordCount()
    return substitute(system('texcount -1 -sum '
        \ . expand('%')), '[^0-9]', '', 'g') . ' words'
endfunction

" }}}


" Install packages {{{

function! InstallPackages()
    let winview = winsaveview()
    call inputsave()
    let cmd = ['sudo -S tlmgr install']
    %call add(cmd, matchstr(getline('.'),
                \ '\\usepackage\(\[.*\]\)\?{\zs.*\ze\}'))
    %call add(cmd, matchstr(getline('.'),
                \ '\\RequirePackage\(\[.*\]\)\?{\zs.*\ze\}'))
    echomsg join(cmd)
    let pass = inputsecret('Enter sudo password:') . "\n"
    echo system(join(cmd), pass)
    call inputrestore()
    call winrestview(winview)
endfunction

command! InstallPackages call InstallPackages()

" }}}

