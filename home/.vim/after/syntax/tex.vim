syntax match texStatement "\\apud" nextgroup=texRefOption,texCite
syntax match texStatement '\\textcite\*' nextgroup=texRefOption,texCite

for cmd in ['term', 'opus', 'foreign']
    execute 'syntax region texItalStyle matchgroup=texTypeStyle'
        \ 'start="\\' . cmd . '\s*{" end="}"'
        \ 'contains=@NoSpell,@texItalGroup'
endfor

