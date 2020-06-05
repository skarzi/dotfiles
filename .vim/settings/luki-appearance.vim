" COLORS
" use 256 colors
set t_Co=256
let g:python_highlight_all=1
" set syntax hightlighting depending on file type
syntax on
set background=dark
let g:hybrid_custom_term_colors = 1
" hybrid, gotham, dracula, space-vim-dark, onedark
colorscheme space-vim-dark
" line number colors
highlight Normal ctermbg=none
" TODO: find better color
highlight LineNr ctermfg=DarkGrey ctermbg=none
" END COLORS

" UI LAYOUT
" show relative line numbers
set relativenumber
" show command in bottom bar
set showcmd
" highlight current line
set cursorline
" load filetype-specific indent files
filetype indent on
" visual autocomlepte for command menu
set wildmenu
" redraw only when we need to
set lazyredraw
" width of document (used by gd)
set textwidth=79
" set coloring for 80 column
set colorcolumn=80
highlight ColorColumn ctermbg=25
" END UI LAYOUT
