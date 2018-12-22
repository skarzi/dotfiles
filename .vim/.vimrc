set nocompatible

if filereadable($HOME . '/.vim/vundles.vim')
    source $HOME/.vim/vundles.vim
endif

if filereadable($HOME . '/.vim/settings.vim')
    source $HOME/.vim/settings.vim
endif

" Automatic reload of .vimrc
if has('autocmd')
    autocmd! bufwritepost $MYVIMRC source $MYVIMRC
endif
