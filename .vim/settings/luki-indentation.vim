" INDENTATION
set autoindent
" tabstop, sets how many spaces = tab
set ts=4
" soft tab stops
set sts=4
" shift width
set sw=4
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
if has("autocmd")
    " enable filetype detection
    filetype on
    autocmd FileType make setlocal ts=8 sts=8 sw=8 noexpandtab
    autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType css,scss setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType js setlocal ts=2 sts=2 sw=2 expandtab
endif
" END INDENTATION
