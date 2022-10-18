scriptencoding utf-8

" VIM-AIRLINE CONFIG
if !exists('g:airline_symbols')
    let g:airline_symbols={}
endif
"  unicode symbols
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_symbols.linenr='ln'
let g:airline_symbols.maxlinenr=' ≣'
let g:airline_symbols.branch='↯'
let g:airline_symbols.paste='P'
let g:airline_symbols.whitespace='Ξ'

let g:airline_theme='onedark'

" TABLINE
let g:airline#extensions#tabline#enabled=1
" END TABLINE

" BUFFERLINE
" enable vim-bufferline integration
let g:airline#extensions#bufferline#enabled=1
" determine whether bufferline will overwrite customization variables
let g:airline#extensions#bufferline#overwrite_variables=1
" END BUFFERLINE

" FUGITIVE
" enable fugitive integration
let g:airline#extensions#branch#enabled=1
" change the text for when no branch is detected
let g:airline#extensions#branch#empty_message=''
" END FUGITIVE

" ALE
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#ale#error_symbol = '🐛'
let g:airline#extensions#ale#warning_symbol = '⚠️'
" END ALE

 set laststatus=2
" END VIM-AIRLINE CONFIG
