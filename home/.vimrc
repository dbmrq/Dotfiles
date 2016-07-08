" VUNDLE

set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'tpope/vim-sensible'
    Plugin 'tpope/vim-unimpaired'
    Plugin 'tpope/vim-surround'
    Plugin 'Shougo/neocomplete.vim'
    Plugin 'lervag/vimtex'
    Plugin 'SirVer/ultisnips'
    Plugin 'honza/vim-snippets'
    Plugin 'Raimondi/delimitMate'
    Plugin 'godlygeek/tabular'
    Plugin 'ntpeters/vim-better-whitespace'
    Plugin 'junegunn/goyo.vim'
    Plugin 'yegappan/mru'
    Plugin 'scrooloose/nerdcommenter'
    Plugin 'terryma/vim-expand-region'
    Plugin 'mbbill/undotree'
    Plugin 'justinmk/vim-sneak'
    Plugin 'maxbrunsfeld/vim-yankstack'
    Plugin 'itchyny/lightline.vim'
    Plugin 'henrik/vim-indexed-search'
    Plugin 'haya14busa/incsearch.vim'
    Plugin 'kopischke/vim-stay'
    Plugin 'Konfekt/FastFold'
    Plugin 'vim-pandoc/vim-pandoc'
    Plugin 'vim-pandoc/vim-pandoc-syntax'
    Plugin 'vim-pandoc/vim-pandoc-after'
    Plugin 'wellle/targets.vim'
    Plugin 'kana/vim-textobj-user'
    Plugin 'kana/vim-textobj-line'
    Plugin 'kana/vim-textobj-indent'
    Plugin 'kana/vim-textobj-entire'
    Plugin 'kana/vim-textobj-syntax'
    Plugin 'reedes/vim-pencil'
    Plugin 'reedes/vim-textobj-sentence'
    " Plugin 'tpope/vim-abolish'
    " Plugin 'reedes/vim-wordy'
    Plugin 'https://github.com/altercation/vim-colors-solarized.git'
call vundle#end()

filetype plugin indent on


" OPTIONS

syntax enable

set hidden

set relativenumber
set number

set showcmd

set tabstop=4
set shiftwidth=4
set expandtab
set shiftround

set wrap
set linebreak
set textwidth=78
if executable("par")
    set formatprg=par\ -w78
endif
let &colorcolumn="79,".join(range(101,999),",")

set backupcopy=yes
set clipboard=unnamed
set ignorecase
set smartcase
set scrolloff=3
set sidescrolloff=7
set sidescroll=1

set undolevels=1000

set title

set visualbell
set noerrorbells

set undodir=~/.vim/undo/
set undofile

let g:tex_comment_nospell=1

let g:tex_flavor = "latex"
au BufRead,BufNewFile *.bbx setfiletype plaintex
au BufRead,BufNewFile *.cbx setfiletype plaintex
au BufRead,BufNewFile *.lbx setfiletype plaintex
au BufRead,BufNewFile *.cls setfiletype plaintex
au BufRead,BufNewFile *.sty setfiletype plaintex

" I also added this to ftplugin/tex.vim, but vimtex
" resets it afterwards, so it must be done here.
au BufRead,BufNewFile *.tex set comments+=b:\\item

" run :MRU when vim is opened without any file (just "vim")
function! NoFile()
    if @% == ""
        :MRU
    endif
endfunction
autocmd VimEnter * call NoFile()


" APPEARANCE

colorscheme solarized
let g:lightline = {'colorscheme': 'solarized',}

set background=dark


" MAPPINGS

let mapleader = " "

" normal mode
autocmd InsertEnter * set timeoutlen=50
autocmd InsertLeave * set timeoutlen=750
inoremap jk <esc>
inoremap kj <esc>
inoremap JK <esc>
inoremap KJ <esc>
" vnoremap jk <esc>
" vnoremap kj <esc>
" vnoremap JK <esc>
" vnoremap KJ <esc>
" cnoremap jk <C-c>
" cnoremap kj <C-c>
" cnoremap JK <C-c>
" cnoremap KJ <C-c>

" format paragraphs
nnoremap <leader>gq vipgq

" really go to the end
noremap G G$

" insert single character
nnoremap <leader>s i_<Esc>r
nnoremap <leader>S a_<Esc>r

" go to last change
nnoremap <leader>b `.
" insert at last position
nnoremap <leader>i `^i


" edit and source vimrc

nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <expr> <leader>sv SourceVimRC()

function! SourceVimRC()
    let command = ":so $MYVIMRC\<cr>:let &ft=&ft\<cr>:set shortmess+=c\<cr>"
    if has('gui_running') && filereadable(expand('~/.gvimrc'))
        let command = command . ":so ~/.gvimrc\<cr>"
    endif
    return command
endfunction


" select everything
nnoremap <leader>a ggVG


" spelling

nnoremap zz 1z=
nnoremap <leader>tsp :set spell!<cr>
nnoremap <expr> <leader>sen ToggleSpellLang("en")
nnoremap <expr> <leader>spt ToggleSpellLang("pt")

function! ToggleSpellLang(lang)
    if &l:spelllang =~ a:lang
        return ":setlocal spell spelllang-=" . a:lang . "\<cr>"
    else
        return ":setlocal spell spelllang+=" . a:lang . "\<cr>"
    endif
endfunction


" switch windows
nnoremap <leader>w <c-w><c-w>
nnoremap <leader>W <c-w><c-w>

" move lines up and down
" (needs unimpaired.vim)
let s:uname = system("uname -s")
if !has("gui_running") && s:uname =~ "Darwin"
    nmap k [e
    nmap j ]e
    vmap k [egv
    vmap j ]egv
else
    nmap <m-k> [e
    vmap <m-k> [egv
    nmap <m-j> ]e
    vmap <m-j> ]egv
endif

" move faster
nnoremap <leader>j 20j
nnoremap <leader>k 20k
nnoremap <leader>h 10h
nnoremap <leader>l 10l
vnoremap <leader>j 20j
vnoremap <leader>k 20k
vnoremap <leader>h 10h
vnoremap <leader>l 10l
" nnoremap <C-e> 3<C-e>
" nnoremap <C-y> 3<C-y>

" move in insert mode
inoremap <c-l> <right>
inoremap <c-h> <left>

" fold
nnoremap <leader>f za
vnoremap <leader>f zf

" copy everything, unwrapping it when necessary
function! CopyAll()
    if &l:formatoptions =~ "t"
        return "ma:g/./,-/\\n$/j\<cr>ggvG$\"\+yu\`a"
    endif
    return "maggvG$\"\+yu\`a"
endfunction
nnoremap <expr> Y CopyAll()

" make a second <CR> delete comments added automatically
function! CROrUncomment()
    for comment in map(split(&l:comments, ','),
        \ 'substitute(v:val, "^.\\{-}:", "", "")')
            if getline('.') =~ '\V' . escape(comment, '\') . ' \$'
                return repeat("\<BS>", strchars(comment) + 1)
            endif
    endfor
    return "\<cr>"
endfunction
inoremap <expr> <CR> CROrUncomment()

" windows

function! SmartSizeUp()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>+"
    elseif winwidth(0) != &columns
        return "5\<c-w>>"
    endif
endfunction
nnoremap <expr> <leader>= SmartSizeUp()

function! SmartSizeDown()
    if winheight(0) + &cmdheight + 1 != &lines
          " current window is part of a horizontal split
        return "5\<c-w>-"
    elseif winwidth(0) != &columns
        return "5\<c-w><"
    endif
endfunction
nnoremap <expr> <leader>- SmartSizeDown()

function! SmartSplit()
  let l:height=winheight(0)
  let l:width=winwidth(0)
  if (l:height*2 > l:width)
     return ":split\<cr>"
  else
      return ":vsplit\<cr>"
  endif
endfunction
nnoremap <expr> <leader>sp SmartSplit()

" toggle background color
function! ToggleBG()
    if &background ==# "dark"
        set background=light
    else
        set background=dark
    endif
    let g:lightline = {'colorscheme': 'solarized',}
endfunction
nnoremap <leader>bg :call ToggleBG()<cr>
command! ToggleBG call ToggleBG()

" plugins
nnoremap <leader>ut :UndotreeToggle<cr>
nnoremap <leader>gy :Goyo<cr>
nnoremap <leader>tp :TogglePencil<cr>


" PLUGIN SETTINGS


" vim-surround

function! ChangeDetectedSurrounding()
    let chars = ['(', '[', '{', '<', '"', '`', "'",
               \ '.', ',', ';', ':', '~', '!', '?', '/', '\', '|']
    let column = 1
    while col('.')-column >= 0
        echom getline('.')[col('.')-column]
        let char = getline('.')[col('.')-column]
        if index(chars, char) >= 0
            echom "cs" . char
            return "cs" . char
        endif
        let column += 1
    endwhile
endfunction

nmap <expr> cd ChangeDetectedSurrounding()


" NERD Commenter

let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'

" lightline.vim

set noshowmode

augroup LightLineColorscheme
    autocmd!
    autocmd ColorScheme * call s:lightline_update()
augroup END

function! s:lightline_update()
    if !exists('g:loaded_lightline')
        return
    endif
    try
        if g:colors_name =~# 'wombat\|solarized\|landscape\
                            \ |jellybeans\|seoul256\|Tomorrow'
            let g:lightline.colorscheme =
                \ substitute(substitute(g:colors_name, '-', '_', 'g'),
                           \ '256.*', '', '') .
                \ (g:colors_name ==# 'solarized' ? '_' . &background : '')
            call lightline#init()
            call lightline#colorscheme()
            call lightline#update()
        endif
    catch
    endtry
endfunction


" UltiSnips

" Use <CR> to accept snippets
let g:UltiSnipsExpandTrigger = "<c-j>"
let g:ulti_expand_res = 0
function! SnippetOrCR()
    let snippet = UltiSnips#ExpandSnippet()
    if g:ulti_expand_res > 0
        return snippet
    else
        return CROrUncomment()
    endif
endfunction
inoremap <silent><expr> <CR> "<C-R>=SnippetOrCR()<CR>"


" Reedes

augroup reedes
  autocmd!
  autocmd FileType markdown,mkd,text,tex call pencil#init()
                                     \ | call textobj#sentence#init()
augroup END

let g:pencil#conceallevel = 0
let g:pencil#textwidth = &textwidth


" incsearch.vim

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

let g:indexed_search_mappings = 0
augroup incsearch-indexed
    autocmd!
    autocmd User IncSearchLeave ShowSearchIndex
augroup END

nnoremap <silent>n nzv:ShowSearchIndex<CR>
nnoremap <silent>N Nzv:ShowSearchIndex<CR>


" vim-pandoc

let g:pandoc#after#modules#enabled = ["ultisnips"]
let g:pandoc#syntax#conceal#use = 0


" vim-sneak

let g:sneak#use_ic_scs = 1
hi clear SneakPluginTarget
hi link SneakPluginTarget Search

"replace 'f' with 1-char Sneak
nmap f <Plug>Sneak_f
nmap F <Plug>Sneak_F
xmap f <Plug>Sneak_f
xmap F <Plug>Sneak_F
omap f <Plug>Sneak_f
omap F <Plug>Sneak_F
"replace 't' with 1-char Sneak
nmap t <Plug>Sneak_t
nmap T <Plug>Sneak_T
xmap t <Plug>Sneak_t
xmap T <Plug>Sneak_T
omap t <Plug>Sneak_t
omap T <Plug>Sneak_T


" vim-expand-region

call expand_region#custom_text_objects({
    \ 'i(': 1, 'i)': 1, 'ib': 1, 'i{': 1, 'i}': 1, 'iB': 1,
             \ 'i[': 1, 'i]': 1, 'i<': 1, 'i>': 1, 'it': 1,
    \ 'A(': 1, 'A)': 1, 'Ab': 1, 'A{': 1, 'A}': 1, 'AB': 1,
             \ 'A[': 1, 'A]': 1, 'A<': 1, 'A>': 1, 'At': 1,
    \ "i'": 1, 'i"': 1, 'i`': 1, "A'": 1, 'A"': 1, 'A`': 1,
    \ 'i,': 1, 'i;': 1, 'A,': 1, 'A;': 1, 'as': 1, 'is': 1,
    \ 'ii': 1, 'ai': 1,
    \ })


" incsearch.vim

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)


" yankstack

let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 'x', 'X', 'y', 'Y']
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_newer_paste


" Vimtex

let g:vimtex_indent_bib_enabled = 0
let g:vimtex_fold_enabled = 1
let g:latex_fold_preamble = 1
let g:vimtex_fold_envs = 0
let g:vimtex_fold_sections = []


" NeoComplete

" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 2
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
" inoremap <expr><C-l>     neocomplete#complete_common_string()

" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags


" neocomplete/Vimtex compatibility

if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.tex =
        \ '\v\\%('
        \ . '\a*cite\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
        \ . '|\a*ref%(\s*\{[^}]*|range\s*\{[^,}]*%(}\{)?)'
        \ . '|hyperref\s*\[[^]]*'
        \ . '|includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
        \ . '|%(include%(only)?|input)\s*\{[^}]*'
        \ . '|\a*(gls|Gls|GLS)(pl)?\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
        \ . '|includepdf%(\s*\[[^]]*\])?\s*\{[^}]*'
        \ . '|includestandalone%(\s*\[[^]]*\])?\s*\{[^}]*'
        \ . ')'

