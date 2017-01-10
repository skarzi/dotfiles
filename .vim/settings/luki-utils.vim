"EXCESS LINE
"Highlight excess line length
if has('autocmd')
    augroup vimrc_autocmds
        autocmd!
        " highlight characters past column 80
        autocmd FileType python highlight Excess ctermbg=236 guibg=Black
        autocmd FileType python match Excess /\%80v.*/
        autocmd FileType python set nowrap
    augroup END
endif
" END EXCESS LINE

" SWAP FILES
set nobackup
set nowritebackup
set noswapfile
" END SWAP FILES

" OTHER UTILS
set clipboard=unnamed
" hide buffers not close them
" set hidden

" toggle between paste mode
set pastetoggle=<F2>

" map 'jk' to <ESC>
inoremap jk <ESC>
" map 'kj' to <ESC>
inoremap kj <ESC>
" END OTHER UTILS
