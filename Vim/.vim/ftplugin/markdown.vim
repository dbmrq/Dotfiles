command! PDF call system("pandoc -o " . fnameescape(expand('%:r')) . ".pdf " . fnameescape(expand('%')))
command! DOCX call system("pandoc -o " . fnameescape(expand('%:r')) . ".docx " . fnameescape(expand('%')))

" autocmd! BufWritePost <buffer> silent !pandoc % -o %:p:r.pdf -s -S
