" Full Vim Settings - extends essential settings with advanced features

" Load essential settings first
source ~/.vim/settings-essential.vim
runtime! plugin/sensible.vim

" Appearance (extends essential)
au BufRead *.* setl scrolloff=5 sidescrolloff=7 sidescroll=1

if $BACKGROUND == 'light'
    set background=light
else
    set background=dark
endif

au ColorScheme * hi! EndOfBuffer guifg=#f8f1dd guibg=#f8f1dd

" Status line customization
set laststatus=0

au ColorScheme * hi! link StatusLine FoldColumn
au ColorScheme * hi! link StatusLineNC LineNr
au ColorScheme * hi! link VertSplit LineNr
set fillchars=

set stl=
set stl+=%=%t%{&mod?'\ ':''}
set stl+=%=%t%{&mod?'+':''}
set stl+=%{winheight(0)<line('$')?'\ ':''}
set stl+=%{winheight(0)<line('$')?PercentThrough():''}
set stl+=%{&readonly&&&ft!='help'?'\ ':''}
set stl+=%{&readonly&&&ft!='help'?'[RO]':''}
set stl+=%{&ft=='help'?'\ ':''}
set stl+=%{&ft=='help'?'[Help]':''}
set stl+=%{&ff!='unix'?'\ ':''}
set stl+=%{&ff!='unix'?'['.&ff.']':''}
set stl+=%{(&fenc!='utf-8'&&&fenc!='')?'\ ':''}
set stl+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
set stl+=\

function! PercentThrough()
    return line('.') * 100 / line('$') . '%'
endfunction

set rulerformat=
set rulerformat+=%25(%=%t%{&mod?'\ +':''}%)
set rulerformat+=%{winheight(0)<line('$')?'\ ':''}
set rulerformat+=%{winheight(0)<line('$')?PercentThrough():''}
set rulerformat+=%{&readonly?'\ ':''}
set rulerformat+=%{&readonly?'[RO]':''}
set rulerformat+=%{&ff!='unix'?'\ ':''}
set rulerformat+=%{&ff!='unix'?'['.&ff.']':''}
set rulerformat+=%{(&fenc!='utf-8'&&&fenc!='')?'\ ':''}
set rulerformat+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}

" Wrapping (extends essential)
set bri
set showbreak=...\

au BufRead,BufNewFile */.vim/thesaurus/* set tw=0

" Folding
set foldmethod=marker
set foldmarker=\ {{{,\ }}}

function! ShortFoldText()
    let text = foldtext()
    if strchars(text) > &l:textwidth
        let regex = '\(.\{,' . (&l:textwidth - 3) . '}\).*$'
        let text = substitute(text, regex, '\1', '') . "..."
    end
    return text
endfunction

set foldtext=ShortFoldText()

" TeX
let g:tex_flavor = "latex"
au BufReadPost,BufNewFile *.bbx,*.cbx,*.lbx,*.cls,*.sty set ft=plaintex
let g:tex_comment_nospell=1
let g:tex_itemize_env = 'itemize\|description\|enumerate\|thebibliography' .
                      \ '\|inline\|inlinin\|inlinex\|inlinalt'

" Misc (extends essential)
set backupcopy=yes
set updatecount=20
set complete+=kspell
set switchbuf+=useopen,usetab
set fo+=r
set virtualedit=onemore
set updatetime=2000
set viminfo='1000,f1

if executable("ag")
    set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column
    set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

autocmd BufReadPost quickfix set nowrap
au BufReadPost,BufNewFile *.md setlocal spell spelllang+=pt
au BufNewFile *.sh 0r ~/.vim/templates/skeleton.sh
