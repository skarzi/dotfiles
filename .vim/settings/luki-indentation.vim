" INDENTATION
set autoindent
" tabstop, sets how many spaces = tab
set tabstop=2
" soft tab stops
set softtabstop=2
" shift width
set shiftwidth=2
" printing as many spaces as you check in sts instead tab
set expandtab
set shiftround
" show tab and spaces on end of line
set list
" sets chars for space and for tab
set listchars=trail:_,tab:>-
" be smart when using tabs
set smarttab
" to avoid trouble with conversion
set fileformat=unix
" set local indentatnion settings per filetype
if has('autocmd')
    " enable filetype detection
    filetype on
    augroup vimrc_indentantions
        autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab
        autocmd FileType make,Makefile setlocal ts=8 sts=8 sw=8 noexpandtab
        autocmd FileType groovy setlocal ts=4 sts=4 sw=4 expandtab
    augroup END
endif
" END INDENTATION
