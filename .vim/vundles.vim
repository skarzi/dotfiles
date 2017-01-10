" VUNDLE CONFIG
set nocompatible              " be iMproved, required
filetype off                  " required
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
set rtp+=~/.vim/vundles_lists
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" run all vundles splitted to smaller categories
runtime vim_improvements.vundle
runtime py.vundle
runtime git.vundle
runtime colorschemes.vundle
runtime webdev.vundle
runtime code_completion.vundle

call vundle#end()            " required
filetype plugin indent on
" END VUNDLE CONFIG
