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

" delete surrounding command
nmap daC F\df{f}x

" }}}

" Show word count when saving {{{

au BufWritePost <buffer> redraw | echo WrittenString() . ' | ' . WordCount()

function! FileSize()
    return substitute(system('du -sh ' .
                \ expand('%')), '^\s\?\(.*\)\s.*', '\1', 'g')
endfunction

function! WrittenString()
    return '"' . expand('%:t') . '" ' . FileSize()
endfunction

function! WordCount()
    return substitute(system('texcount -1 -sum '
        \ . expand('%')), '[^0-9]', '', 'g') . ' words'
endfunction

" }}}

" Replace hardcoded quotes with \enquote {{{1
command! Enquote %s/``\(\_.\{-}\)''/\\enquote{\1}/g
" }}}1


command! StripWeirdWhitespaces %s/^[^\a\d]$//gc

command! ConvertAccents %s/é/é/g | %s/ú/ú/g | %s/ó/ó/g
            \ | %s/ã/ã/g | %s/ê/ê/g | %s/à/à/g | %s/ç/ç/g | %s/õ/õ/g


" Better b, e and w for TeX {{{1

nnoremap <silent> b B
vnoremap <silent> b B

nnoremap <silent> B ?\U\([.,;:?!{(\[]\\|-\s\)\(\s*\\|\d*\\|\n*\\|$*\)*\a?e<cr>:noh<cr>
vnoremap <silent> B ?\U\([.,;:?!{(\[]\\|-\s\)\(\s*\\|\d*\\|\n*\\|$*\)*\a?e<cr><esc>:noh<cr>gv

nnoremap <silent> e E
vnoremap <silent> e E

nnoremap <silent> E /\U\([.,;:?!})\]]\(\s\\|\d\\|\n\\|$\)\\|\s-\)<cr>:noh<cr>
vnoremap <silent> E /\U\([.,;:?!})\]]\(\s\\|\d\\|\n\\|$\)\\|\s-\)<cr><esc>:noh<cr>gv

" nnoremap <silent> e /\U\(\a\\|[[=a=]]\\|[[=e=]]\\|[[=i=]]\\|[[=o=]]\\|[[=u=]]\)\ze\(\s\\|\.\\|,\\|;\\|:\\|-\\|)\\|}\\|]\\|$\)/e<cr>:noh<cr>
" vnoremap <silent> e /\U\(\a\\|[[=a=]]\\|[[=e=]]\\|[[=i=]]\\|[[=o=]]\\|[[=u=]]\)\ze\(\s\\|\.\\|,\\|;\\|:\\|-\\|)\\|}\\|]\\|$\)/e<cr><esc>:noh<cr>gv

nnoremap <silent> w W
vnoremap <silent> w W

nnoremap <silent> W /\U\([.,;:?!})\]]\n*%\?\(\s\\|\d\\|\n\\|$\)\\|\s-\)\a/e<cr>:noh<cr>
vnoremap <silent> W /\U\([.,;:?!})\]]\n*%\?\(\s\\|\d\\|\n\\|$\)\\|\s-\)\a/e<cr><esc>:noh<cr>gv

" }}}1

" Change the closest comma, semicolon or colon into a period {{{1

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

" Symbols {{{1

" Can't do this because it screws up with some accented characters
" let s:uname = system("uname -s")
" if !has("gui_running") && s:uname =~ "Darwin"
"     inoremap s §
"     inoremap p ¶
" else
"     inoremap <m-s> §
"     inoremap <m-p> ¶
" endif

inoremap <F5> §
inoremap <F6> ¶

" }}}1

" Add space when pasting at period or new line {{{1

function! PasteOrSpacePaste()
    let char = getline('.')[col('.') - 1]
    if char == '.' || char == ''
        return "a \<esc>p"
    else
        return "p"
    endif
endfunction

nnoremap <expr> p PasteOrSpacePaste()

" }}}1

" formatprg {{{1
if executable("latexindent")
    set formatprg=latexindent\ -m
    " set formatprg=latexindent\ -m\ -y=\"modifyLineBreaks:oneSentencePerLine:manipulateSentences:1\"\ \|\ latexindent\ -m
endif
" }}}1

set spell
set spelllang=pt

set thesaurus+=~/.vim/thesaurus/academico.txt
set thesaurus+=~/.vim/thesaurus/conjuncoes.txt

