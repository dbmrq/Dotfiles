source ~/.vim/ftplugin/plaintex.vim

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

if expand('%:e') != 'tex'
    finish
endif

" Surround words {{{

" \emph
nnoremap <leader>em ciw\emph{<c-r><c-o>"}<esc>
vnoremap <leader>em c\emph{<c-r><c-o>"}<esc>

" other commands
nnoremap <leader>cm viw<esc>a}<esc>bi\{<esc>i
vnoremap <leader>cm <esc>`>a}<esc>`<i\{<esc>i

" }}}

" Show word count when saving {{{

au BufWritePost <buffer> redraw | echo WrittenString() . ' | ' . WordCount()

function! FileSize()
    return substitute(system('du -sh ' .
                \ expand('%')), '^\s\?\(.*\)\s.*', '\1', 'g')
endfunction

function! WrittenString()
    return '"' . expand('%:h:t') . '/' . expand('%:t') .
        \ '" ' . line('$') . ' lines, ' . FileSize() . ' written'
endfunction

function! WordCount()
    return substitute(system('texcount -1 -sum '
        \ . expand('%')), '[^0-9]', '', 'g') . ' words'
endfunction

" }}}

" Replace hardcoded quotes with \enquote {{{1
command! Enquote %s/``\(\_.\{-}\)''/\\enquote{\1}/g
" }}}1

" Better b and e for TeX {{{1
nnoremap <silent> b B
nnoremap <silent> B ?\U[.,;:]\(\s*\\|\n*\\|$*\)*\a?e<cr>:noh<cr>
vnoremap <silent> b B
vnoremap <silent> B ?\U[.,;:]\(\s*\\|\n*\\|$*\)*\a?e<cr><esc>:noh<cr>gv
nnoremap <silent> e /\U\(\a\\|[[=a=]]\\|[[=e=]]\\|[[=i=]]\\|[[=o=]]\\|[[=u=]]\)\ze\(\s\\|\.\\|,\\|;\\|:\\|-\\|)\\|}\\|]\\|$\)/e<cr>:noh<cr>
nnoremap <silent> E /\U[.,;:]\(\s\\|\n\\|$\)<cr>:noh<cr>
vnoremap <silent> e /\U\(\a\\|[[=a=]]\\|[[=e=]]\\|[[=i=]]\\|[[=o=]]\\|[[=u=]]\)\ze\(\s\\|\.\\|,\\|;\\|:\\|-\\|)\\|}\\|]\\|$\)/e<cr><esc>:noh<cr>gv
vnoremap <silent> E /\U[.,;:]\(\s\\|\n\\|$\)<cr><esc>:noh<cr>gv
" }}}1

" Change the closest comma, semicolon or colon int a period {{{1
nnoremap <silent> <leader>. :call MakePeriod()<cr>

function! MakePeriod()
    call FindClosest('[,;:]', ' ')
    if getline('.')[col('.') - 1] == ' '
        execute "normal! r.a \<esc>"
    else
        normal! r.l
    endif
    normal! lgUl
endfunction



" }}}1

set spell
set spelllang=pt

set thesaurus+=~/.vim/thesaurus/academico.txt
set thesaurus+=~/.vim/thesaurus/conjuncoes.txt

