" IMPSORT CONFIG
" just to have 1 imported object per 1 line
let g:impsort_textwidth=1
let g:impsort_start_nextline=1
let g:impsort_relative_last=1
" to turn on my fix to impsort
let g:impsort_end_last_import_with_comma=1
nnoremap <Leader>z :<C-U>ImpSort!<CR>
" END IMPSORT CONFIG
