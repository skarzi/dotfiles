" EMMET CONFIG
" enable just for html/css
let g:user_emmet_install_global=0
if has('autocmd')
    autocmd filetype html,css,scss,xml EmmetInstall
endif
" set / as trigger key
let g:user_emmet_leader_key='\'
" END EMMET CONFIG
