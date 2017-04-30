#!/bin/bash


function install_aptitude()
{
    apt-get update
    apt-get install -y aptitude
}


function install_all_via_aptitude()
{
    aptitude update
    aptitude full-upgrade
    INSTALL='aptitude install -y'

    $INSTALL git vim-nox rxvt-unicode-256color make bzip2 lbzip2
    # python dependencies
    $INSTALL python-dev python-pip python-setuptools
    # i3wm stuff
    $INSTALL i3-wm i3blocks i3lock feh
    # pyenv dependencies
    $INSTALL build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl libncurses5-dev \
        libncursesw5-dev llvm xz-utils tk-dev
    # vimiv dependencies
    $INSTALL python-gobject gtk3 python-pillow jhead
    $INSTALL tmux task-warrior redshift cmus zathura mpv lm-sensors ranger xsel
    $INSTALL scrot keepassx icedove libreoffice lxappearance
    $INSTALL fonts-hack-ttf
}


function setup_urxvt()
{
    # set rxvt as default terminal,
    update-alternatives --set x-terminal-emulator /usr/bin/urxvt
}


function install_pyenv()
{
    cd "${HOME}" || exit 0
    if [ ! -d ".pyenv" ];
    then
        git clone https://github.com/yyuu/pyenv.git "${HOME}/.pyenv"
        # already in .bashrc
        # echo '# PYENV CONF' >> ${HOME}/.bashrc
        # echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ${HOME}/.bashrc
        # echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ${HOME}/.bashrc
        # echo 'eval "$(pyenv init -)"' >> ${HOME}/.bashrc
        # echo -e "\n" >> ${HOME}/.bashrc"
        exec "$SHELL"
    fi
    cd - || exit 1
}


function install_pyenv_virtualenvwrapper()
{
    [ -d "${HOME}/.pyenv" ] || exit 0
    cd "${HOME}/.pyenv/plugins/" || exit 1
    if [ ! -d "pyenv-virtualenvwrapper" ];
    then
        git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ./pyenv-virtualenvwrapper
        # already in .bashrc
        # echo '# PYENV VIRTUALENVWRAPPER CONF' >> ${HOME}/.bashrc
        # echo 'export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"' >> ${HOME}/.bashrc
        # echo -e "\n" >> ${HOME}/.bashrc
        exec "$SHELL"
    fi
    cd - || exit 2
}


function install_git_prompt()
{
    cd "${HOME}" || exit 0
    if [ ! -d ".bash-git-prompt" ];
    then
        git clone https://github.com/magicmonty/bash-git-prompt.git "${HOME}/.bash-git-prompt" --depth=1
        # already in .bashrc
        # echo '# GIT PROMPT CONF' >> ${HOME}/.bashrc
        # echo 'GIT_PROMPT_ONLY_IN_REPO=1' >> ${HOME}/.bashrc
        # echo 'source ${HOME}/.bash-git-prompt/gitprompt.sh' >> ${HOME}/.bashrc
        # echo -e "\n" >> ${HOME}/.bashrc
        exec "$SHELL"
    fi
    cd - || exit 1

}


function install_vimiv()
{
    [ ! -d '/opt/vimiv' ] || exit 0
    git clone https://github.com/karlch/vimiv /opt/vimiv
    cd "/opt/vimiv" || exit 1
    make install
    cd - || exit 2
}


function create_symlinks()
{
    cd ~/dotfiles || exit 0
    FILES=(
        "./.Xmodmap"
        "./.Xresources"
        "./.bash_aliases"
        "./.bashrc"
        "./.i3"
        "./.vim"
        "./.vim/.vimrc"
        "./.vimperator"
        "./.vimperatorrc"
        "./.tmux.conf"
    )
    SYMLINK_NAME=(
        "${HOME}/.Xmodmap"
        "${HOME}/.Xresources"
        "${HOME}/.bash_aliases"
        "${HOME}/.bashrc"
        "${HOME}/.i3"
        "${HOME}/.vim"
        "${HOME}/.vimrc"
        "${HOME}/.vimperator"
        "${HOME}/.vimperatorrc"
        "${HOME}/.tmux.conf"
    )

    for index in ${!FILES[*]};
    do
        echo "Creating symlink: ${FILES[$index]} -> ${SYMLINK_NAME[$index]}"
        ln -s "${FILES[$index]}" "${SYMLINK_NAME[$index]}"
    done
}
