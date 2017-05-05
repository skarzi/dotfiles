#!/bin/bash

source "./functions.sh"

echo "Creating symlinks\n"
create_symlinks

echo "Installing pyenv and pyenv-virtualenvwrapper\n"
install_pyenv
install_pyenv_virtualenvwrapper

echo "Installing git-prompt\n"
install_git_prompt

echo "Installing Vundle.vim\n"
install_vundle
