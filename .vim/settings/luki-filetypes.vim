" FILETYPES
if has('autocmd')
    " enable filetype detection
    filetype on
    augroup vimrc_autocmds
        autocmd BufNewFile,BufRead Jenkinsfile setf groovy
        autocmd BufNewFile,BufRead */ansible/hosts setf yaml.ansible
        autocmd BufNewFile,BufRead */playbooks/*.yml setf yaml.ansible
        autocmd BufNewFile,BufRead .importlinter setf cfg
    augroup END
endif
" END FILETYPES
