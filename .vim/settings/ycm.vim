" YOUCOMPLETEME CONFIG
" dont run ycm for these files
let g:ycm_filetype_blacklist = {
      \ 'python' : 1,
      \ 'notes' : 1,
      \ 'markdown' : 1,
      \ 'vimwiki' : 1,
      \}
let g:ycm_filetype_specific_completion_to_disable = {
      \ 'gitcommit': 1
      \}
" path to python 2.7
let g:ycm_python_binary_path = 'python2.7'
" END YOUCOMPLETEME CONFIG
