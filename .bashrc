# If not running interactively, don't do anything.
case $- in
    *i*) ;;
    *) return;;
esac

# Vi mode for command line editing.
set -o vi

export LANG="en_US.UTF-8"

# Bash history
# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# Immediately append to the history file, don't overwrite it.
shopt -s histappend
export HISTSIZE="2000"
export HISTFILESIZE="10000"
# Share history between all bash sessions using custom script.
# To revert previous behavior, use the following command:
# `history -a; history -r; $PROMPT_COMMAND`
export PROMPT_COMMAND="bash ${HOME}/dotfiles/bin/manage_bash_history.sh"

# Check the window size after each command and update it, if necessary.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
# shopt -s globstar


# Set variable identifying the chroot you work in (used in the prompt below).
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# NOTE: Use "rxvt-unicode-256color" for urxvt.
export TERM="xterm-256color"
case "$TERM" in
    xterm-color|*-256color|alacritty) color_prompt=yes;;
esac

# Force color prompt and enable colors for `ls`.
force_color_prompt=yes
export CLICOLOR=1

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='\[\e[0;32m\]\u\[\e[m\]@\[\e[0;32m\]\h\[\e[m\] \[\e[m\][\[\e[0;34m\]\w\[\e[m\]\[\e[m\]] \n\[\e[0;32m\]\$\[\e[m\] '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Set the title to `user@host:dir`.
case "$TERM" in
xterm*|rxvt*|alacritty*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Bash aliases.
if [ -f "${HOME}/.bash_aliases" ]; then
    . "${HOME}/.bash_aliases"
fi

# Set some terminal defaults.
export PAGER=less
export EDITOR=vim
# Enable colored GCC warnings and errors.
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# Use bat for man pages with proper formatting.
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Android Development
export ANDROID_HOME="$HOME/Android/Sdk"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools"
export PATH="${PATH}:/opt/gradle/gradle-4.10.2/bin"

# homebrew
export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"

# nvm
export NVM_AUTO_USE=true
export NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

# starship
eval "$(starship init bash)"

# pyenv
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# pyenv virtualenvwrapper
# Lazy-load virtualenvwrapper for pyenv.
# Note: PYENV_VIRTUALENVWRAPPER_PYENV_VERSION can be set to "system" if needed.
pyenv virtualenvwrapper_lazy

# uv
export PATH="${HOME}/.local/bin:${PATH}"

# BASH completion
if ! shopt -oq posix; then
  if [ -f "${HOMEBREW_PREFIX}/share/bash-completion/bash_completion" ]; then
    source "${HOMEBREW_PREFIX}/share/bash-completion/bash_completion"
  elif [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
  fi
fi
export BASH_COMPLETION_COMPAT_DIR="${HOMEBREW_PREFIX}/etc/bash_completion.d"
[[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]] && . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
for BCFILE in ${HOME}/.bash_completion.d/* ; do
    source "${BCFILE}"
done

# GO language version manager
export GVM_DIR="${HOME}/.gvm"
[[ -s "${GVM_DIR}/scripts/gvm" ]] && source "${GVM_DIR}/scripts/gvm"

export DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# colima
# Uncomment to use Colima Docker socket.
# export DOCKER_HOST="$(colima status --json | jq --raw-output .docker_socket)"
# export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# Uncomment the following lines on Linux systems to enable automatic X server startup on tty 1.
# if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
#     startx
# fi

# rust
export CARGO_HOME="${HOME}/.cargo"
export PATH="${CARGO_HOME}/bin:${PATH}"
source "${CARGO_HOME}/env"

# alacritty
export ALACRITTY_HOME="${HOME}/alacritty"

# fzf
eval "$(fzf --bash)"

# direnv
eval "$(direnv hook bash)"

# Rippling
# CDE CLI bash configuration
source "${HOME}/.cde/.venv/lib/python3.11/site-packages/cde_cli/cde_cli_sh_rc.sh"
