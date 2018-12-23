if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias l='ls -CF'
alias sl='ls'
alias ll='ls -l'
alias la='ls -A'
alias lla='ls -lA'
alias lls='ls -l'

alias time='time -p'
alias sscrot='scrot -s -e "mv \$f ~/pictures/screenshots"'

alias i3conf='vim ~/.i3/config'
alias reload_Xre='xrdb -load ~/.Xresources'

alias de='deactivate'
alias mk='pyenv virtualenvwrapper && mkvirtualenv'
alias pip_upgrade_all='pip freeze | cut -d = -f 1 | xargs pip install -U'

alias add_ssh_key='bash ~/dotfiles/bin/add_ssh_key.sh'
alias toggle_trackpad='bash ~/dotfiles/bin/toggle_trackpad.sh'
alias pingg='ping 8.8.8.8'

alias dc='docker-compose'
alias dc_run='docker-compose run --rm'

alias rm_pyc="find . -type d -name __pycache__  \
    -o \( -type f -name '*.py[co]' \) -print0 \
    | xargs -0 rm -rf"
