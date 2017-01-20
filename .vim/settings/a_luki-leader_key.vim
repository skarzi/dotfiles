" LEADER SHORTCUTS
" [,],<space>,o,h,j,k,l,g,d,r,n,s,q,Q,w,z,R
" set leader key
let mapleader = ","

" next buffer
nnoremap <leader>] :n!<CR>
" previous buffer
map <leader>[ :prev!<CR>
" turn off search highlighting
nnoremap <leader><space> :nohlsearch<CR>
" map <leader>o to execute current file via python
map <leader>o :!python %<CR>
" END LEADER SHORTCUTS
