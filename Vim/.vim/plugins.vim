" Plug
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
    Plug 'tommcdo/vim-exchange'
    Plug 'junegunn/vim-easy-align'
    Plug 'junegunn/goyo.vim'
    Plug 'ntpeters/vim-better-whitespace'
    Plug 'tweekmonster/spellrotate.vim'
    Plug 'Raimondi/delimitMate'
    Plug 'lervag/vimtex'
    Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
    Plug 'wellle/targets.vim'
    Plug 'wellle/visual-split.vim'
    Plug 'lifepillar/vim-mucomplete'
    Plug 'plasticboy/vim-markdown'
    Plug 'machakann/vim-highlightedyank'
    Plug 'haya14busa/vim-edgemotion'
    Plug 'simeji/winresizer'
    Plug 'maxbrunsfeld/vim-yankstack'
    Plug 'kshenoy/vim-signature'
    Plug 'markonm/traces.vim'
    Plug 'romainl/vim-cool'
    Plug 'google/vim-searchindex'
    Plug 'nelstrom/vim-visual-star-search'
    " Plug 'altercation/vim-colors-solarized' " Disabled: using terminal colors instead
    Plug 'dbmrq/vim-chalk'
    Plug 'dbmrq/vim-howdy'
    Plug 'dbmrq/vim-bucky'

    " Which-key - shows available keybindings
    if has('nvim')
        Plug 'folke/which-key.nvim'
    else
        Plug 'liuchengxu/vim-which-key'
    endif

call plug#end()

command! Plug so % | PlugUpdate | PlugUpgrade

" vim-better-whitespace
let g:better_whitespace_enabled=1
let g:strip_whitespace_on_save=1
let g:show_spaces_that_precede_tabs=1

" Goyo
" Hide EndOfBuffer ~ characters by matching them to background
autocmd! User GoyoEnter hi! EndOfBuffer ctermfg=bg ctermbg=bg guifg=bg guibg=bg
autocmd! User GoyoLeave hi! EndOfBuffer ctermfg=bg ctermbg=bg guifg=bg guibg=bg

" visual-split
xmap <leader>s <Plug>(Visual-Split-VSSplit)
nmap <leader>s <Plug>(Visual-Split-Split)

" highlightedyank
au ColorScheme * hi! link HighlightedyankRegion FoldColumn
let g:highlightedyank_highlight_duration = 750

" edgemotion
nmap <C-j> <Plug>(edgemotion-j)
nmap <C-k> <Plug>(edgemotion-k)

" Yankstack
let g:yankstack_yank_keys = ['y', 'd', 'c', 'x']
nmap <c-p> <Plug>yankstack_substitute_older_paste

" vim-signature
let g:SignatureIncludeMarkers = ')⚑@#$%ˆ&*('
au ColorScheme * hi! link SignatureMarkLine CursorLine
au ColorScheme * hi! link SignatureMarkerLine CursorLine
au ColorScheme * hi! link SignColumn FoldColumn
au ColorScheme * hi! SignatureMarkText ctermbg=NONE ctermfg=Cyan cterm=bold guibg=NONE guifg=Cyan gui=bold
au ColorScheme * hi! SignatureMarkerText ctermbg=NONE ctermfg=Magenta cterm=bold guibg=NONE guifg=Magenta gui=bold
" MUcomplete
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

au BufRead * inoremap <c-tab> <tab>
inoremap <expr> <esc> pumvisible() ? "\<c-e>" : "<esc>"

function! CYOrCR()
    return pumvisible() ? "\<esc>o" : CROrUncomment()
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
    \           g:mucomplete_with_key && t =~# '\m\k\k$' },
    \ }

let g:mucomplete#popup_direction = { 'keyp' : 1 }
let g:mucomplete#spel#good_words = 1
let g:mucomplete#spel#max = 5

" UltiSnips
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

" Vimtex
let g:vimtex_toc_todo_keywords = ['TODO', 'FIXME', 'IMPORTANT', 'IMPORTANTE']
let g:vimtex_text_obj_enabled = 1
let g:vimtex_imaps_enabled = 0
let g:vimtex_indent_bib_enabled = 0
let g:vimtex_indent_enabled = 1
let g:vimtex_toc_show_help = 0
let g:vimtex_view_automatic = 0
let g:vimtex_syntax_packages = {'biblatex': {'load': 2}}

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

" vim-markdown
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1

" Targets
let g:targets_aiAI = '  ai'

" vim-rsi
let g:rsi_no_meta = 1

" Use terminal colors instead of a vim colorscheme
" The terminal (Ghostty) sets the theme via ANSI colors
" colorscheme solarized  " Disabled: using terminal colors

" delimitMate
let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1

" vim-easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)
" Spellrotate
nmap <silent> =s <Plug>(SpellRotateForward)
nmap <silent> -s <Plug>(SpellRotateBackward)
vmap <silent> =s <Plug>(SpellRotateForwardV)
vmap <silent> -s <Plug>(SpellRotateBackwardV)

" vim-surround
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

" vim-sneak
let g:sneak#use_ic_scs = 1
autocmd ColorScheme * hi! link Sneak Title

nmap f <Plug>Sneak_f
nmap F <Plug>Sneak_F
xmap f <Plug>Sneak_f
xmap F <Plug>Sneak_F
omap f <Plug>Sneak_f
omap F <Plug>Sneak_F
nmap t <Plug>Sneak_t
nmap T <Plug>Sneak_T
xmap t <Plug>Sneak_t
xmap T <Plug>Sneak_T
omap t <Plug>Sneak_t
omap T <Plug>Sneak_T

" vim-textobj-user
function! AroundParA()
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
\ })

function! InsideParI()
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
\ })

function! InsideMarkers()
    normal! [z
    normal! j
    let head_pos = getpos('.')
    normal! ]z
    normal! k
    let tail_pos = getpos('.')
    return ['V', head_pos, tail_pos]
endfunction

call textobj#user#plugin('insidemarkers', {
\   '-': {
\     'select-a-function': 'InsideMarkers',
\     'select-a': 'Iz',
\   },
\ })

nmap <leader>gq gqIp

" Howdy
let g:howdy_ignore = [
        \ 'runtime\/doc\/.*.txt',
        \ 'Table of contents (vimtex)',
        \ '.*\/.git\/.*',
    \ ]

" Chalk
let g:chalk_char = "."

au BufRead,BufNewFile *.vim let b:chalk_add_space = 1
au BufRead,BufNewFile *.tex let b:chalk_align = 1
au BufRead,BufNewFile *.tex let b:chalk_edit = 1
au BufRead,BufNewFile *.tex set foldtext=ShortFoldText()

vmap zf <Plug>Chalk
nmap zf <Plug>Chalk
nmap zF <Plug>ChalkRange
nmap ZF <Plug>ChalkAround
vmap ZF <Plug>ChalkAround
nmap zd <Plug>ChalkDelete
nmap zD <Plug>ChalkDeleteR
vmap zD <Plug>ChalkDeleteR
nmap zE <Plug>ChalkDeleteAll
nmap =z <Plug>ChalkUp
nmap -z <Plug>ChalkDown
vmap =z <Plug>ChalkUp
vmap -z <Plug>ChalkDown

" Which-key configuration
if has('nvim')
    " Neovim: which-key.nvim configuration (Lua)
    lua << EOF
    local ok, wk = pcall(require, "which-key")
    if ok then
        wk.setup({
            delay = 500,
            icons = { mappings = false },
        })
        wk.add({
            { "<leader>b", desc = "Alternate buffer" },
            { "<leader>c", desc = "Change (no yank)" },
            { "<leader>d", desc = "Delete (no yank)" },
            { "<leader>e", group = "Edit" },
            { "<leader>ev", desc = "Edit vimrc" },
            { "<leader>f", desc = "Toggle fold" },
            { "<leader>g", group = "Format" },
            { "<leader>gq", desc = "Format paragraph" },
            { "<leader>p", desc = "Paste (keep register)" },
            { "<leader>s", desc = "Visual split" },
            { "<leader>w", desc = "Next window" },
            { "<leader>x", desc = "Delete char (no yank)" },
            { "<leader>?", desc = "Cheat sheet" },
        })
    end
EOF
else
    " Vim: vim-which-key configuration
    let g:which_key_timeout = 500
    let g:which_key_display_names = {' ': 'SPC', '<CR>': 'RET', '<Tab>': 'TAB'}

    let g:which_key_map = {}
    let g:which_key_map.b = 'Alternate buffer'
    let g:which_key_map.c = 'Change (no yank)'
    let g:which_key_map.d = 'Delete (no yank)'
    let g:which_key_map.e = { 'name': '+Edit', 'v': 'Edit vimrc' }
    let g:which_key_map.f = 'Toggle fold'
    let g:which_key_map.g = { 'name': '+Format', 'q': 'Format paragraph' }
    let g:which_key_map.p = 'Paste (keep register)'
    let g:which_key_map.s = 'Visual split'
    let g:which_key_map.w = 'Next window'
    let g:which_key_map.x = 'Delete char (no yank)'
    let g:which_key_map['?'] = 'Cheat sheet'

    autocmd! User vim-which-key call which_key#register('<Space>', 'g:which_key_map')
    nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
    vnoremap <silent> <leader> :WhichKeyVisual '<Space>'<CR>
endif
