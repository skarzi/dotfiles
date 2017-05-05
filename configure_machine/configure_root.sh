#!/bin/bash

source "./functions.sh"

echo "Installing aptitude\n"
install_aptitude

echo "Installing packages, dependencies etc\n"
install_all_via_aptitude

echo "Installing vimiv\n"
install_vimiv

echo "Setting rxvt as default terminal\n"
setup_urxvt
