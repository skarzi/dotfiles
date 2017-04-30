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

" python with virtualenv support

" Add the virtualenv's site-packages to vim path
if has('python3')
py3 << EOF
import os.path
import sys
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
EOF
endif
" END OTHER UTILS
