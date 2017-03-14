" YOUCOMPLETEME CONFIG
" dont run ycm for these filetypes
let g:ycm_filetype_blacklist={
    \ 'python': 1,
    \ 'notes': 1,
    \ 'vimwiki': 1,
\}
let g:ycm_filetype_specific_completion_to_disable={
    \ 'gitcommit': 1
\}
let g:ycm_python_binary_path='python'
let g:ycm_server_python_interpreter='python2.7'
" END YOUCOMPLETEME CONFIG
