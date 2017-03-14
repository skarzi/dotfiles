" SPLIT LAYOUTS
" new layouts spliting below currently active
set splitbelow
" new layouts spliting right to currently active
set splitright
" map <CTRL-{h,j,k,l}> to move between layouts
nnoremap <C-h> <C-W>h
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-l> <C-W>l
" map <leader>+{h,j,k,l} to move active window
nnoremap <leader>h <C-W>H
nnoremap <leader>j <C-W>J
nnoremap <leader>k <C-W>K
nnoremap <leader>l <C-W>L
" resize window horizontally
nnoremap \| <C-W>\|
" resize window vertically
nnoremap _ <C-W>_
" :sv = vericaly
" :vs = horizontaly
" :only = close everything apart active window
" <C-w>x = exchange active window with his neighbour
" <C-w>r = rotate all windows
" END SPLIT LAYOUTS
