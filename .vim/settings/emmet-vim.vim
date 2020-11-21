" EMMET CONFIG
" enable just for html/css
let g:user_emmet_install_global=0
if has('autocmd')
    augroup vimrc_emmet
        autocmd filetype html,htmldjango,css,scss,xml,vue EmmetInstall
    augroup END
endif
" set \ as trigger key
let g:user_emmet_leader_key='\'
" END EMMET CONFIG
