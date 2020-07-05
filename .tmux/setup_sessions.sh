#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


###############################################################################
# Ensure `dotfiles` virtual environment is activated
#
# Globals:
#   None
# Arguments:
#   $1 - dotfiles venv name - optional
# Returns:
#   None
###############################################################################
ensure_dotfiles_venv_activated () {
    local dotfiles_venv="${1:-dotfiles}"

    if [[ -z "${VIRTUAL_ENV+x}" ]] || [[ ! "${VIRTUAL_ENV}" =~ ^.*"${dotfiles_venv}"$ ]];
    then
        source "${dotfiles_venv}/bin/activate" \
        || ( \
            echo "${dotfiles_venv} does not exist. Please create it firstly." \
            && exit 1 \
        )
    fi
}


###############################################################################
# Load all tmux session defined in workspace directory using `tmuxp`.
#
# Globals:
#   None
# Arguments:
#   $1 - workspaces directory - optional
# Returns:
#   None
###############################################################################
load_all_tmux_session_workspaces () {
    local workspaces_directory="${1:-${HOME}/dotfiles/.tmux/workspaces/}"

    find \
        "${workspaces_directory}" \
        -type f \
        -regextype posix-extended \
        -regex ".*\.(yaml|yml|json)" \
    | paste -sd ' ' \
    | xargs tmuxp load -d
}


cd ~/dotfiles \
&& ensure_dotfiles_venv_activated "${HOME}/.virtualenvs/dotfiles" \
&& load_all_tmux_session_workspaces \
; deactivate; (cd - 1> /dev/null)
