runtime! plugin/sensible.vim

" Appearance

syntax enable
set title
set showcmd

au BufRead *.* setl scrolloff=5 sidescrolloff=7 sidescroll=1

if $BACKGROUND == 'light'
    set background=light
else
    set background=dark
endif

au ColorScheme * hi! EndOfBuffer guifg=#f8f1dd guibg=#f8f1dd

" Status line and ruler
set ruler
set laststatus=0
set showmode

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
" Wrapping
set bri
set wrap
set linebreak
set textwidth=78
set whichwrap+=h,l
set showbreak=...\

au BufRead,BufNewFile */.vim/thesaurus/* set tw=0

" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set shiftround

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

" Undo
if has('persistent_undo')
    set undofile
    set undolevels=5000
endif

" Directories
set undodir=~/.vim/undo/,.
set backupdir=~/.vim/backup/,.,~/tmp,~/
set directory=~/.vim/swp/,.,~/tmp,/var/tmp,/tmp

" TeX
let g:tex_flavor = "latex"
au BufReadPost,BufNewFile *.bbx,*.cbx,*.lbx,*.cls,*.sty set ft=plaintex
let g:tex_comment_nospell=1
let g:tex_itemize_env = 'itemize\|description\|enumerate\|thebibliography' .
                      \ '\|inline\|inlinin\|inlinex\|inlinalt'

" Misc
set hidden
set backupcopy=yes
set clipboard=unnamed
set ignorecase
set smartcase
set visualbell
set noerrorbells
set shortmess+=c
set shortmess+=A
set updatecount=20
set autowrite
set complete+=kspell
set switchbuf+=useopen,usetab
set nojoinspaces
set encoding=utf-8
set incsearch
set hlsearch
set fo+=r

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j
endif

set virtualedit=onemore
set updatetime=2000
set viminfo='1000,f1

autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
    \     exe "normal! g`\"" |
    \ endif

if executable("ag")
    set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column
    set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

autocmd BufReadPost quickfix set nowrap
au BufReadPost,BufNewFile *.md setlocal spell spelllang+=pt
au BufNewFile *.sh 0r ~/.vim/templates/skeleton.sh
