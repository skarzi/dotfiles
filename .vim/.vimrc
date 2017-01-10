set nocompatible

if filereadable(expand('~/.vim/vundles.vim'))
    source ~/.vim/vundles.vim
endif

source ~/.vim/settings.vim

" Automatic reload of .vimrc
if has('autocmd')
    autocmd! bufwritepost $MYVIMRC source $MYVIMRC
endif
