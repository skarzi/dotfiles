" VIM-AIRLINE CONFIG
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
"  unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = ''
" let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = ''
" let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'
" enable the extensions
let g:airline#extensions#tabline#enabled = 1
" let g:airline_powerline_fonts = 1
let g:airline_theme = 'ravenpower'

" BUFFERLINE
" enable vim-bufferline integration
let g:airline#extensions#bufferline#enabled = 1
" determine whether bufferline will overwrite customization variables
let g:airline#extensions#bufferline#overwrite_variables = 1
" END BUFFERLINE

" FUGITIVE
" enable fugitive integration
let g:airline#extensions#branch#enabled = 1
" change the text for when no branch is detected
let g:airline#extensions#branch#empty_message = ''
" END FUGITIVE
"
 set laststatus=2
" END VIM-AIRLINE CONFIG
