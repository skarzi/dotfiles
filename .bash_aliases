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

alias i3conf='vim ~/.i3/config'
alias reload_Xre='xrdb -load ~/.Xresources'
alias pip_upgrade_all='pip freeze | cut -d = -f 1 | xargs pip install -U'
