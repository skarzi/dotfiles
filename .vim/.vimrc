" NOTE: ViM config is no longer actively maintained! Use Neovim instead!
" to use some advanced ViM features, it need to be 'iMproved'
" vint: -ProhibitSetNoCompatible
set nocompatible
" vint: +ProhibitSetNoCompatible

if filereadable($HOME . '/.vim/vundles.vim')
    source $HOME/.vim/vundles.vim
endif

if filereadable($HOME . '/.vim/settings.vim')
    source $HOME/.vim/settings.vim
endif

" automatic reload of .vimrc
if has('autocmd')
    augroup vimrc_self
        autocmd! bufwritepost $MYVIMRC source $MYVIMRC
    augroup END
endif
