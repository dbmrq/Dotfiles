command! PDF call system("pandoc -o ".expand('%:r').".pdf ".expand('%'))
command! DOCX call system("pandoc -o ".expand('%:r').".docx ".expand('%'))

" autocmd! BufWritePost <buffer> silent !pandoc % -o %:p:r.pdf -s -S
