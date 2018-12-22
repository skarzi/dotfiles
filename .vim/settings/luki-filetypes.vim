" FILETYPES
if has('autocmd')
    " enable filetype detection
    filetype on
    augroup vimrc_autocmds
        autocmd BufNewFile,BufRead Jenkinsfile setf groovy
    augroup END
endif
" END FILETYPES
