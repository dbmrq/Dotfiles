command! Pandoc call system("pandoc " . expand('%') .
            \ " --latex-engine=xelatex -o " . expand('%:r') . ".pdf")

" autocmd! BufWritePost <buffer> silent !pandoc % -o %:p:r.pdf -s -S
