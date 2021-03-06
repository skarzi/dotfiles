" VUNDLE CONFIG
filetype off                  " required
" set the runtime path to include Vundle and initialize
set runtimepath+=~/.vim/bundle/Vundle.vim
set runtimepath+=~/.vim/vundles
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" run all vundles splitted to smaller categories
runtime utils.vundle
runtime py.vundle
runtime colorschemes.vundle
runtime webdev.vundle
runtime dev.vundle
runtime editors.vundle

call vundle#end()            " required
filetype plugin indent on
" END VUNDLE CONFIG
