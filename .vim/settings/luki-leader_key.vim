" LEADER SHORTCUTS
" [,],<space>,o,h,j,k,l,g,d,r,n
" set leader key
let mapleader = ","

" next buffer
nnoremap <Leader>] :n!<CR>
" previous buffer
map <Leader>[ :prev!<CR>
" turn off search highlighting
nnoremap <leader><space> :nohlsearch<CR>
" map <leader>o to execute current file via python
map <Leader>o :!python %<CR>
" map sort function to a key
" vnoremap <leader>s :sort<CR>
" END LEADER SHORTCUTS
