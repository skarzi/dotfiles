# shellcheck shell=bash
# If not running interactively, don't do anything.
case $- in
    *i*) ;;
    *) return;;
esac

# INITIALIZATION AND SHELL OPTIONS
# Vi mode for command line editing.
set -o vi

export LANG="en_US.UTF-8"

# Bash history
# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL="ignoreboth"
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
# Editor and pager configuration
export PAGER="less"
export EDITOR="vim"

# Enable colored GCC warnings and errors.
export GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"
# Use bat for man pages with proper formatting.
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat --theme=TwoDark -p -lman'"

# BASH UTILITIES
# Add a directory to `${PATH}` if it exists and is not already there.
# Arguments:
#   ${1}: Directory path to add
#   ${2}: If `true`, removes the directory from `${PATH}` first (if present)
#   and then prepends it, ensuring it is at the front (default: `false`).
# Returns:
#   `0` if directory was added or already exists in `${PATH}`
#   `1` if directory doesn't exist
add_to_path() {
    local dir="${1}"
    local should_force_update="${2:-false}"

    if [[ ! -d "${dir}" ]]; then
        return 1
    fi
    if [[ "${should_force_update}" == "true" ]]; then
        PATH=":${PATH}:"
        PATH="${PATH//:${dir}:/:}"
        PATH="${PATH#:}"
        PATH="${PATH%:}"
    fi
    if [[ ":${PATH}:" != *":${dir}:"* ]]; then
        PATH="${dir}:${PATH}"
    fi
    return 0
}

# TERMINAL
# NOTE: Use "rxvt-unicode-256color" for urxvt.
export TERM="xterm-256color"
export CLICOLOR=1
export ALACRITTY_HOME="${HOME}/alacritty"

# starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# SHELL ENHANCEMENTS
# BASH completion
if ! shopt -oq posix; then
    if [[ -f "${HOMEBREW_PREFIX}/share/bash-completion/bash_completion" ]]; then
        # shellcheck source=/dev/null  # System file, may not be accessible
        source "${HOMEBREW_PREFIX}/share/bash-completion/bash_completion"
    elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
        # shellcheck source=/dev/null  # System file, may not be accessible
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        # shellcheck source=/dev/null  # System file, may not be accessible
        source /etc/bash_completion
    fi
fi
export BASH_COMPLETION_COMPAT_DIR="${HOMEBREW_PREFIX}/etc/bash_completion.d"
if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    # shellcheck source=/dev/null  # System file, may not be accessible
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
fi
if [[ -d "${HOME}/.bash_completion.d" ]]; then
    # shellcheck source=/dev/null  # Wildcard pattern, files may not be accessible
    for bcfile in "${HOME}"/.bash_completion.d/*; do
        if [[ -r "${bcfile}" ]]; then
            source "${bcfile}"
        fi
    done
fi

# TOOLS
# homebrew
export HOMEBREW_PREFIX="/opt/homebrew"
add_to_path "${HOMEBREW_PREFIX}/bin" "true"

# nvm
export NVM_AUTO_USE=true
export NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    # shellcheck source=/dev/null  # System file, may not be accessible
    source "${NVM_DIR}/nvm.sh"
fi
if [[ -s "${NVM_DIR}/bash_completion" ]]; then
    # shellcheck source=/dev/null  # System file, may not be accessible
    source "${NVM_DIR}/bash_completion"
fi

# pyenv
export PYENV_ROOT="${HOME}/.pyenv"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
add_to_path "${PYENV_ROOT}/bin"

# pyenv virtualenvwrapper
# Lazy-load virtualenvwrapper for pyenv.
# Note: PYENV_VIRTUALENVWRAPPER_PYENV_VERSION can be set to "system" if needed.
if command -v pyenv >/dev/null 2>&1; then
    pyenv virtualenvwrapper_lazy
fi

# uv
add_to_path "${HOME}/.local/bin"

# GVM
# GO language version manager
export GVM_DIR="${HOME}/.gvm"
if [[ -s "${GVM_DIR}/scripts/gvm" ]]; then
    # shellcheck source=/dev/null  # Variable path, may not be accessible
    source "${GVM_DIR}/scripts/gvm"
fi

# rust
export CARGO_HOME="${HOME}/.cargo"
if [[ -f "${CARGO_HOME}/env" ]]; then
    # shellcheck source=/dev/null  # Variable path, may not be accessible
    source "${CARGO_HOME}/env"
fi

# Android Development
export ANDROID_HOME="${HOME}/Android/Sdk"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
if [[ -d "${ANDROID_HOME}" ]]; then
    add_to_path "${ANDROID_HOME}/tools"
    add_to_path "${ANDROID_HOME}/platform-tools"
fi
add_to_path "/opt/gradle/gradle-4.10.2/bin"

# fzf
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# Docker
export DOCKER_CONFIG="${DOCKER_CONFIG:-${HOME}/.docker}"
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# colima
# Uncomment to use Colima Docker socket.
# export DOCKER_HOST="$(colima status --json | jq --raw-output .docker_socket)"
# export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# ALIAS LOADING
if [[ -f "${HOME}/.bash_aliases" ]]; then
    # shellcheck source=/dev/null  # External file, may not be accessible
    source "${HOME}/.bash_aliases"
fi

# LINUX X-SERVER
# Uncomment the following lines on Linux systems to enable automatic X server startup on tty 1.
# if [[ -z "${DISPLAY}" && "${XDG_VTNR}" -eq 1 ]]; then
#     startx
# fi
