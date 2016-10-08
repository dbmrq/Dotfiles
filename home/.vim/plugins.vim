
" vim-rsi {{{1
let g:rsi_no_meta = 1
" }}}1

" " Schlepp {{{1

" function! SchleppDetect(direction)
"     let mode = mode()
"     let command = ""
"     if mode ==# 'v'
"         let command .= "\<c-v>"
"     endif
"     let command .= "\<Plug>Schlepp" . a:direction
"     if mode ==# 'V'
"         let command .= "zRgv"
"     endif
"     return command
" endfunction

" vmap <silent> <expr> <Left> SchleppDetect("Left")
" vmap <silent> <expr> <Right> SchleppDetect("Right")
" vmap <silent> <expr> <Up> SchleppDetect("Up")
" vmap <silent> <expr> <Down> SchleppDetect("Down")

" " }}}1

" golden-ratio {{{1
let g:golden_ratio_autocommand = 0
let g:golden_ratio_exclude_nonmodifiable = 1
" }}}1

" goyo {{{1

nnoremap <leader>gy :Goyo<cr>

" }}}1

" undotree {{{1
nnoremap <leader>ut :UndotreeToggle<cr>
" }}}1

" Solarized {{{1
colorscheme solarized
" }}}1

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

au FileType markdown,text,tex DittoOn

nmap <leader>di <Plug>ToggleDitto

nmap +d <Plug>DittoGood
nmap _d <Plug>DittoBad
nmap =d <Plug>DittoNext
nmap -d <Plug>DittoPrev
nmap ]d <Plug>DittoMore
nmap [d <Plug>DittoLess

" }}}1

" gitgutter {{{1

let g:gitgutter_map_keys = 0

" }}}1

" ArgWrap {{{1

nnoremap <silent> <leader>aw :ArgWrap<cr>

let g:argwrap_tail_comma = 1

" }}}1

" splitjoin {{{1

" let g:splitjoin_split_mapping = 'K'
" let g:splitjoin_join_mapping = 'J'

" nmap J :SplitjoinJoin<cr>
" nmap K :SplitjoinSplit<cr>

" nnoremap <expr> J argwrap#validateRange(argwrap#findClosestRange()) ?
"     \ ":ArgWrap<cr>" : ":SplitjoinJoin<cr>"

" nnoremap <expr> K argwrap#validateRange(argwrap#findClosestRange()) ?
"     \ ":ArgWrap<cr>" : ":SplitjoinSplit<cr>"

" }}}1

" delimitMate {{{1

let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1

" }}}1

" vim-easy-align {{{1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" }}}1

"unimpaired.vim {{{1

" move lines up and down
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

" }}}1

" Spellrotate {{{1

nmap <silent> =s <Plug>(SpellRotateForward)
nmap <silent> -s <Plug>(SpellRotateBackward)
vmap <silent> =s <Plug>(SpellRotateForwardV)
vmap <silent> -s <Plug>(SpellRotateBackwardV)

" }}}1

" CtrlP {{{1

" run :CtrlPMRU when vim is opened without any file
function! NoFile()
    if @% == ""
        :CtrlPMRU
    endif
endfunction
autocmd VimEnter * call NoFile()

let g:ctrlp_map = ''
nnoremap <c-p> :CtrlP 

let g:ctrlp_working_path_mode = 'c'
let g:ctrlp_path_nolim = 1
" let g:ctrlp_show_hidden = 1
" let g:ctrlp_max_files = 0
" let g:ctrlp_max_depth = 40

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

" lightline.vim {{{1

set noshowmode

let g:lightline = {'colorscheme': 'solarized',}


augroup LightLineColorscheme
    autocmd!
    autocmd ColorScheme * call LightlineUpdate()
augroup END

function! LightlineUpdate()
    if !exists('g:loaded_lightline')
        return
    endif
    try
        if g:colors_name =~# 'wombat\|solarized\|landscape\
                            \ |jellybeans\|seoul256\|Tomorrow'
            let g:lightline.colorscheme =
                \ substitute(substitute(g:colors_name, '-', '_', 'g'),
                \ '256.*', '', '')
            call lightline#init()
            call lightline#colorscheme()
            call lightline#update()
        endif
    catch
    endtry
endfunction

" }}}1

" UltiSnips {{{1

" Use <CR> to accept snippets
let g:UltiSnipsExpandTrigger = "<nop>"
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

" }}}1

" Reedes {{{1

" nnoremap <leader>tp :TogglePencil<cr>

" augroup reedes
"   autocmd!
"   autocmd FileType markdown,mkd,text,tex call pencil#init()
"                                      \ | call textobj#sentence#init()
" augroup END

" let g:pencil#conceallevel = 0
" let g:pencil#textwidth = &textwidth

" }}}1

" incsearch.vim {{{1

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

if !exists('g:hlsearch_set')
    set hlsearch
endif
let g:hlsearch_set = 1
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)zv:ShowSearchIndex<CR>
map N  <Plug>(incsearch-nohl-N)zv:ShowSearchIndex<CR>
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

let g:indexed_search_mappings = 0
augroup incsearch-indexed
    autocmd!
    autocmd User IncSearchLeave ShowSearchIndex
augroup END

" }}}1

" " vim-pandoc {{{1

" let g:pandoc#after#modules#enabled = ["ultisnips"]
" let g:pandoc#syntax#conceal#use = 0

" }}}1

" vim-sneak {{{1

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

" }}}1

" " vim-expand-region {{{1

" vmap v <Plug>(expand_region_expand)
" vmap <C-v> <Plug>(expand_region_shrink)
" call expand_region#custom_text_objects({
"     \ 'i(': 1, 'i)': 1, 'ib': 1, 'i{': 1, 'i}': 1, 'iB': 1,
"              \ 'i[': 1, 'i]': 1, 'i<': 1, 'i>': 1, 'it': 1,
"     \ 'A(': 1, 'A)': 1, 'Ab': 1, 'A{': 1, 'A}': 1, 'AB': 1,
"              \ 'A[': 1, 'A]': 1, 'A<': 1, 'A>': 1, 'At': 1,
"     \ "i'": 1, 'i"': 1, 'i`': 1, "A'": 1, 'A"': 1, 'A`': 1,
"     \ 'i,': 1, 'i;': 1, 'A,': 1, 'A;': 1, 'as': 1, 'is': 1,
"     \ 'ii': 1, 'ai': 1, 'i\': 1, 'a\': 1,
"     \ })

" " }}}1

" yankstack {{{1

let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 'x', 'y']
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_newer_paste

" }}}1

" Vimtex {{{1

let g:vimtex_text_obj_enabled = 1
let g:vimtex_imaps_enabled = 0
let g:vimtex_indent_bib_enabled = 0
let g:vimtex_format_enabled = 1

" }}}1

" NeoComplete {{{1

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

" <C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
" inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? "\<C-y>" : "\<Space>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" }}}1

" neocomplete/Vimtex compatibility {{{1

" let g:neocomplete#enable_refresh_always = 1

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

let last_spell_changedtick = -1
let last_spell_count = 1

" }}}1

" local-indent {{{1

au BufReadPre,BufNewFile *.bbx,*.cbx,*.lbx,*.cls,*.sty LocalIndentGuide +hl

" }}}1

