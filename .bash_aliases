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

# alias add_ssh_key='source ${HOME}/dotfiles/bin/add_ssh_key.sh'
alias toggle_trackpad='bash ~/dotfiles/bin/toggle_trackpad.sh'
alias pingg='ping 8.8.8.8'

alias dr='docker'
alias dc='docker-compose'
alias dc_run='docker-compose run --rm'

alias rm_pyc="find . -type d -name __pycache__  \
    -o \( -type f -name '*.py[co]' \) -print0 \
    | xargs -0 rm -rf"

alias xrandr_home="xmodmap ~/.Xmodmap \
    && xrandr \
        --output DP2-1 --rotate left --auto --right-of eDP1 \
        --output DP2-2 --auto --right-of DP2-1"
alias xrandr_home2="xmodmap ~/.Xmodmap \
    && xrandr \
        --output HDMI1 --auto --left-of eDP1"
alias xrandr_work="xmodmap ~/.Xmodmap \
    && xrandr \
        --output HDMI2 --auto --above eDP1 \
        --output DP1 --auto --rotate left --left-of HDMI2"
