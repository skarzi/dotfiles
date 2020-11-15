" FILETYPES
if has('autocmd')
    " enable filetype detection
    filetype on
    augroup vimrc_filetypes
        autocmd BufNewFile,BufRead Jenkinsfile set filetype=groovy
        autocmd BufNewFile,BufRead */ansible/hosts set filetype=yaml.ansible
        autocmd BufNewFile,BufRead */playbooks/*.yml set filetype=yaml.ansible
        autocmd BufNewFile,BufRead */playbooks/*.yaml set filetype=yaml.ansible
        autocmd BufNewFile,BufRead *.yaml.example set filetype=yaml
        autocmd BufNewFile,BufRead .ansible-lint set filetype=yaml
        autocmd BufNewFile,BufRead .yamllint set filetype=yaml
        autocmd BufNewFile,BufRead *.yml.example set filetype=yaml
        autocmd BufNewFile,BufRead .importlinter set filetype=cfg
        autocmd BufNewFile,BufRead *.py.template set filetype=python
        autocmd BufNewFile,BufRead *.py.example set filetype=python
    augroup END
endif
" END FILETYPES
