#!/bin/bash

source "./functions.sh"

echo "Installing aptitude"
install_aptitude
install_all_via_aptitude

echo "Creating symlinks"
create_symlinks

echo "Installing pyenv and pyenv-virtualenvwrapper"
install_pyenv
install_pyenv_virtualenvwrapper

echo "Installing git-prompt"
install git_prompt

echo "Installing vimiv"
install_vimiv

echo "Setting rxvt as default terminal"
setup_urxvt
