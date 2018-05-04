

" Plug {{{1

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.vim/bundle')

    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-rsi'
    Plug 'kana/vim-textobj-user'
    Plug 'kana/vim-textobj-line'
    Plug 'kana/vim-textobj-indent'
    Plug 'kana/vim-textobj-entire'
    Plug 'kana/vim-textobj-fold'
    Plug 'justinmk/vim-sneak'
    " Plug 'kana/vim-textobj-syntax'
    Plug 'tommcdo/vim-exchange'
    Plug 'junegunn/vim-easy-align'
    " Plug 'AndrewRadev/splitjoin.vim'
    " Plug 'FooSoft/vim-argwrap'
    " Plug 'ntpeters/vim-better-whitespace'
    Plug 'tweekmonster/spellrotate.vim'
    Plug 'google/vim-searchindex'
    Plug 'nelstrom/vim-visual-star-search'
    Plug 'Raimondi/delimitMate'
    Plug 'romainl/vim-cool'
    " Plug 'mbbill/undotree'
    Plug 'lervag/vimtex'
    " Plug 'sheerun/vim-polyglot'
    Plug 'altercation/vim-colors-solarized'
    Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
    Plug 'wellle/targets.vim'
    " Plug 'Shougo/neocomplete.vim'
    Plug 'lifepillar/vim-mucomplete'
    Plug 'plasticboy/vim-markdown'

    Plug '~/Code/Vim/vim-ditto'
    Plug '~/Code/Vim/vim-chalk'
    Plug '~/Code/Vim/vim-dialect'
    Plug '~/Code/Vim/vim-howdy'
    Plug '~/Code/Vim/vim-redacted'

call plug#end()

command! Plug so % | PlugUpdate | PlugUpgrade

" }}}1


" MUcomplete {{{1

imap <plug>Unused <plug>(MUcompleteCR)

function! MyThesaurus()
    let s:saved_ut = &ut
    if &ut > 200 | let &ut = 200 | endif
    augroup ThesaurusAuGroup
    autocmd CursorHold,CursorHoldI <buffer>
            \ let &ut = s:saved_ut |
            \ set iskeyword-=32 |
            \ autocmd! ThesaurusAuGroup
    augroup END
    set iskeyword+=32
    return "\<c-x>\<c-t>"
endfunction

let g:mucomplete#user_mappings = { 'mythes': "\<c-r>=MyThesaurus()\<cr>" }

set infercase
set completeopt+=menuone
set completeopt+=noselect
set complete-=kspell
set complete-=t
set complete-=i

" This is remapped by UltiSnips, hence the autocmd
au BufRead * inoremap <c-tab> <tab>

" inoremap <expr> <c-e> mucomplete#popup_exit("\<c-e>")
inoremap <expr> <c-y> mucomplete#popup_exit("\<c-y>")

inoremap <expr>  <esc> pumvisible() ? mucomplete#popup_exit("\<c-e>") : "<esc>"

function! CYOrCR()
    return pumvisible() ? "\<esc>o" : CROrUncomment()
    " This stops CR from deleting characters when the typed word
    " and the completed word are the same
    " (https://github.com/lifepillar/vim-mucomplete/issues/61)
endfunction
inoremap <silent> <expr> <CR> "<C-R>=CYOrCR()<CR>"


let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#cycle_all = 1

inoremap <silent> <plug>(MUcompleteBwdKey) <c-k>
imap <expr> <c-k>  pumvisible() ? "<plug>(MUcompleteCycBwd)" : "<Esc>lDA"

let g:mucomplete#chains = {
      \ 'default' : ['path', 'ulti', 'omni', 'mythes', 'keyp', 'incl', 'uspl'],
      \ 'vim'     : ['path', 'cmd', 'keyp']
      \ }

let g:mucomplete#can_complete = {}
let g:mucomplete#can_complete.default = {
    \ 'uspl' : { t -> t =~# '\a\{2}$' },
    \ 'mythes': { t -> g:mucomplete_with_key && strlen(&thesaurus) > 0 },
    \ 'incl': { t -> g:mucomplete_with_key && t =~# '\m\k\k$' },
    \ 'tags': { t -> !empty(tagfiles()) &&
    \	        g:mucomplete_with_key && t =~# '\m\k\k$' },
    \ }

let g:mucomplete#popup_direction = { 'keyp' : 1 }

let g:mucomplete#spel#good_words = 1
let g:mucomplete#spel#max = 5

" }}}1

" UltiSnips {{{1

" Use <CR> to accept snippets
let g:UltiSnipsExpandTrigger = "<nop>"
let g:ulti_expand_res = 0

function! SnipOrCYOrCR()
    let snippet = UltiSnips#ExpandSnippet()
    if g:ulti_expand_res > 0
        return snippet
    elseif pumvisible() && exists("g:loaded_mucomplete")
        return CYOrCR()
    else
        return CROrUncomment()
    endif
endfunction
inoremap <silent> <expr> <CR> "<C-R>=SnipOrCYOrCR()<CR>"

" }}}1

" Vimtex {{{1

autocmd User VimtexEventInitPost exe 'cd' fnameescape(b:vimtex.root)
autocmd User VimtexEventInitPost
            \ command! CD exe 'cd' fnameescape(b:vimtex.root)
autocmd User VimtexEventInitPost
            \ command! -nargs=1 G silent exe 'cd' b:vimtex.root |
            \ silent vimgrep /<args>/g **/*.tex |
            \ cw

let g:vimtex_text_obj_enabled = 1
let g:vimtex_imaps_enabled = 0
let g:vimtex_indent_bib_enabled = 0
let g:vimtex_indent_enabled = 0
let g:vimtex_index_split_pos = "full"
let g:vimtex_toc_fold = 1
let g:vimtex_toc_fold_level_start = 2
let g:vimtex_index_show_help = 0
let g:vimtex_view_automatic = 0
" let g:vimtex_quickfix_open_on_warning = 1

" let g:vimtex_quickfix_latexlog = {'fix_paths':0}

let g:vimtex_compiler_latexmk = {
    \ 'backend' : 'jobs',
    \ 'continuous' : 0,
    \ 'options' : [
    \   '-pdf',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \ ],
    \}

function! ToggleOption(option)
    let index = index(g:vimtex_compiler_latexmk["options"], a:option)
    if index >= 0
        call remove(g:vimtex_compiler_latexmk["options"], index)
        echom(a:option . " removed from latexmk's options")
    else
        call add(g:vimtex_compiler_latexmk["options"], a:option)
        echom(a:option . " added to latexmk's options")
    endif
endfunction

autocmd User VimtexEventInitPost
            \ command! RC call ToggleOption("-norc")

let g:vimtex_toc_hotkeys = {
    \ 'enabled' : 1,
    \ 'keys' : 'asdfjkleurei',
    \ 'leader' : '<space>',
    \}

" let g:VimtexImportante = {
"       \ 're' : g:vimtex#re#not_bslash . '\%\c\s*IMPORTANTE\s*:?\s*\zs.*',
"       \ 'in_preamble' : 1,
"       \}

" function! g:VimtexImportante.get_entry(context) abort dict
"   return {
"         \ 'title'  : 'IMPORTANTE: ' .
"             \ matchstr(a:context.file, '\(\/.*\).*\/\zs\a.*\.\a\a\a') .
"             \ ' - line ' . a:context.lnum,
"         \ 'number' : '[!]',
"         \ 'file'   : a:context.file,
"         \ 'line'   : a:context.lnum,
"         \ 'level'  : a:context.max_level,
"         \ 'rank'   : a:context.lnum_total,
"         \ }
" endfunction

" let g:vimtex_toc_custom_matchers = [g:VimtexImportante]

" }}}1

" " NeoComplete {{{1

" " Since High Sierra ~/.cache, the default directory, is owned by root
" let g:neocomplete#data_directory = "~/.vim/neocomplete"

" " Disable AutoComplPop.
" let g:acp_enableAtStartup = 0
" " Use neocomplete.
" let g:neocomplete#enable_at_startup = 1
" " Use smartcase.
" let g:neocomplete#enable_smart_case = 1
" " Set minimum syntax keyword length.
" let g:neocomplete#sources#syntax#min_keyword_length = 2
" let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" " Plugin key-mappings.
" inoremap <expr><C-g>     neocomplete#undo_completion()
" " inoremap <expr><C-l>     neocomplete#complete_common_string()

" " <C-h>, <BS>: close popup and delete backword char.
" " inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
" " inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
" " Close popup by <Space>.
" "inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

" " Enable omni completion.
" autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
" autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
" autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
" autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
" autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" if !exists('g:neocomplete#sources#omni#input_patterns')
"     let g:neocomplete#sources#omni#input_patterns = {}
"   endif
"   let g:neocomplete#sources#omni#input_patterns.tex =
"         \ g:vimtex#re#neocomplete

" " let last_spell_changedtick = -1
" " let last_spell_count = 1

" " }}}1

" vim-markdown {{{1

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1

" }}}1

" Targets {{{1
let g:targets_aiAI = '  ai'
" }}}1

" " vim-polyglot {{{1
" let g:polyglot_disabled = ['latex']
" " }}}1

" vim-rsi {{{1
let g:rsi_no_meta = 1
" }}}1

" " undotree {{{1
" nnoremap <leader>ut :UndotreeToggle<cr>
" " }}}1

" Solarized {{{1
colorscheme solarized
" }}}1

" " ArgWrap {{{1

" nnoremap <silent> <leader>aw :ArgWrap<cr>

" let g:argwrap_tail_comma = 1

" " }}}1

" " splitjoin {{{1

" let g:splitjoin_split_mapping = 'K'
" let g:splitjoin_join_mapping = 'J'

" nmap J :SplitjoinJoin<cr>
" nmap K :SplitjoinSplit<cr>

" nnoremap <expr> J argwrap#validateRange(argwrap#findClosestRange()) ?
"     \ ":ArgWrap<cr>" : ":SplitjoinJoin<cr>"

" nnoremap <expr> K argwrap#validateRange(argwrap#findClosestRange()) ?
"     \ ":ArgWrap<cr>" : ":SplitjoinSplit<cr>"

" " }}}1

" delimitMate {{{1

let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1

" }}}1

" vim-easy-align {{{1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" }}}1

""unimpaired.vim {{{1

"" move lines up and down
"let s:uname = system("uname -s")
"if !has("gui_running") && s:uname =~ "Darwin"
"    nmap k [e
"    nmap j ]e
"    vmap k [egv
"    vmap j ]egv
"else
"    nmap <m-k> [e
"    vmap <m-k> [egv
"    nmap <m-j> ]e
"    vmap <m-j> ]egv
"endif

"" }}}1

" Spellrotate {{{1

nmap <silent> =s <Plug>(SpellRotateForward)
nmap <silent> -s <Plug>(SpellRotateBackward)
vmap <silent> =s <Plug>(SpellRotateForwardV)
vmap <silent> -s <Plug>(SpellRotateBackwardV)

" }}}1

" vim-surround {{{1

function! LookLeft(char)
    let column = 2
    while col('.')-column >= 0
        let char = getline('.')[col('.')-column]
        if char == a:char
            return 1
        endif
        let column += 1
    endwhile
    return 0
endfunc

function! LookRight(char)
    let column = 0
    while col('.')+column <= col('$')
        let char = getline('.')[col('.')+column]
        if char == a:char
            return 1
        endif
        let column += 1
    endwhile
    return 0
endfunc

function! ChangeDetectedSurrounding()
    let pairs = {'(': ')', '[': ']', '{': '}', '<': '>',
               \ '`': '`', '"': '"', "'": "'"}
    let chars = ['.', ',', ';', ':', '~', '-', '=',
               \ '!', '?', '/', '\', '|']
    let surroundings = copy(chars)
    for pair in items(pairs)
        call extend(surroundings, pair)
    endfor
    let char = getline('.')[col('.')-1]
    if index(surroundings, char) >= 0
        echo "cs" . char
        return "cs" . char
    endif
    for pair in items(pairs)
        if LookLeft(pair[0]) && LookRight(pair[1])
            echo "cs" . pair[0]
            return "cs" . pair[0]
        endif
    endfor
    for char in chars
        if LookLeft(char) && LookRight(char)
            echo "cs" . char
            return "cs" . char
        endif
    endfor
endfunction

nmap <expr> cd ChangeDetectedSurrounding()

" }}}1

" vim-sneak {{{1

let g:sneak#use_ic_scs = 1
" hi clear SneakPluginTarget
" hi link SneakPluginTarget Search
autocmd ColorScheme * hi! link Sneak Title

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

" }}}1

" " yankstack {{{1

" let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 'x', 'y']
" nmap <leader>p <Plug>yankstack_substitute_older_paste
" nmap <leader>P <Plug>yankstack_substitute_newer_paste

" " }}}1

" vim-textobj-user {{{1

function! AroundParA()" {{{2
  normal! {
  let head_pos = getpos('.')
  normal! }
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction

call textobj#user#plugin('aroundpar', {
\   '-': {
\     'select-a-function': 'AroundParA',
\     'select-a': 'Ap',
\   },
\ })" }}}2

function! InsideParI()" {{{2
    let head = line(".")
    while strlen(getline(head - 1)) > strlen(getline(head)) / 2
        let head -= 1
    endwhile

    let tail = line(".")
    while strlen(getline(tail + 1)) > strlen(getline(tail)) / 2
        let tail += 1
    endwhile

    let head_pos = [bufnr('%'), head, 1, 0]
    let tail_pos = [bufnr('%'), tail, strlen(getline(tail)), 0]

  return ['v', head_pos, tail_pos]
endfunction

call textobj#user#plugin('insidepar', {
\   '-': {
\     'select-a-function': 'InsideParI',
\     'select-a': 'Ip',
\   },
\ })" }}}2

nmap <leader>gq gqIp

" }}}1

" Howdy {{{

let g:howdy_ignore = [
        \ 'runtime\/doc\/.*.txt',
        \ 'Table of contents (vimtex)',
        \ '.*\/.git\/.*',
    \ ]

" }}}

" chalk {{{1

vmap zf <Plug>Chalk
nmap zf <Plug>Chalk
nmap zF <Plug>ChalkRange
nmap Zf <Plug>SingleChalk
nmap ZF <Plug>SingleChalkUp
nmap =z <Plug>ChalkUp
nmap -z <Plug>ChalkDown
vmap =z <Plug>ChalkUp
vmap -z <Plug>ChalkDown

" }}}1

" ditto {{{1

" au FileType markdown,text,tex DittoOn

nmap <leader>d <Plug>Ditto
vmap <leader>d <Plug>Ditto

nmap +d <Plug>DittoGood
nmap _d <Plug>DittoBad
nmap =d <Plug>DittoNext
nmap -d <Plug>DittoPrev
nmap ]d <Plug>DittoMore
nmap [d <Plug>DittoLess

" }}}1

