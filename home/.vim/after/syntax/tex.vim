for cmd in ['term', 'opus', 'foreign']
    execute 'syntax region texItalStyle matchgroup=texTypeStyle'
        \ 'start="\\' . cmd . '\s*{" end="}"'
        \ 'contains=@NoSpell,@texItalGroup'
endfor

execute 'syntax match texStatement /\v\\%(' . join([
    \   '[Cc]iteauthor\*?',
    \   '[Cc]ite%(title|year|date)\*?',
    \   'citeurl',
    \   '[Pp]arencite\*?',
    \   'foot%(full)?cite%(text)?',
    \   'fullcite',
    \   '[Tt]extcite\*?',
    \   '[Ss]martcite',
    \   'supercite',
    \   '[Aa]utocite\*?',
    \   '[Ppf]?[Nn]otecite'], '|') . ')/'
    \ 'nextgroup=texRefOption,texCite'

execute 'syntax match texStatement /\v\\%(' . join([
    \   '[Cc]ites',
    \   '[Pp]arencites',
    \   'footcite%(s|texts)',
    \   '[Tt]extcites',
    \   '[Ss]martcites',
    \   'supercites',
    \   '[Aa]utocites'], '|') . ')/'
    \ 'nextgroup=texRefOptions,texCites'

syntax match texStatement "\\apud" nextgroup=texRefOptions,texCites
syntax match texStatement "\\textapud" nextgroup=texRefOptions,texCites

syn keyword texTodo	contained IMPORTANT IMPORTANTE

