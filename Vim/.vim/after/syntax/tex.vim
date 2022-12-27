
syntax match texInputFile /\\addbibresource\%(\[.\{-}\]\)\=\s*{.\{-}}/
      \ contains=texStatement,texInputCurlies,texInputFileOpt

" execute 'syntax match texCmdRefConcealed /\v\\%(' . join([
"     \   '[Cc]iteauthor\*?',
"     \   '[Cc]ite%(title|year|date)\*?',
"     \   'citeurl',
"     \   '[Pp]arencite\*?',
"     \   'foot%(full)?cite%(text)?',
"     \   'fullcite',
"     \   '[Tt]extcite\*?',
"     \   '[Ss]martcite',
"     \   'supercite',
"     \   '[Aa]utocite\*?',
"     \   '[Ppf]?[Nn]otecite'], '|') . ')/'
"     \ 'nextgroup=texRefConcealedArg,texCite'

" execute 'syntax match texCmdRefConcealed /\v\\%(' . join([
"     \   '[Cc]ites',
"     \   '[Pp]arencites',
"     \   'footcite%(s|texts)',
"     \   '[Tt]extcites',
"     \   '[Ss]martcites',
"     \   'supercites',
"     \   '[Aa]utocites'], '|') . ')/'
"     \ 'nextgroup=texRefConcealedArg,texCites'

" syntax match texStatement "\\singlecite" nextgroup=texRefOptions,texCites
" syntax match texStatement "\\apud" nextgroup=texRefOptions,texCites
" syntax match texStatement "\\textapud" nextgroup=texRefOptions,texCites
syntax region texRefZone matchgroup=texStatement
            \ start="\\cf{" end="}\|%stopzone\>" contains=@texRefGroup

" syntax match texStatement "\\singlecite" nextgroup=texRefOptions,texCites
" syntax match texStatement "\\apud" nextgroup=texRefOptions,texCites
" syntax match texStatement "\\textapud" nextgroup=texRefOptions,texCites
" for cmd in ['term', 'opus', 'foreign']
    " execute 'syntax match texStatement "' . cmd . '" nextgroup=NoSpell,texItalGroup'
    " execute 'syntax region texItalStyle matchgroup=texTypeStyle'
    "     \ 'start="\\' . cmd . '\s*{" end="}"'
    "     \ 'contains=@NoSpell,@texItalGroup'
" endfor

syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\apud\>"
syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\textapud\>"
syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\singlecite\>"

" syn keyword texTodo	contained IMPORTANT IMPORTANTE

