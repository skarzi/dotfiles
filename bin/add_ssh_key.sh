#!/usr/bin/env bash

SSH_DIRECTORY="${HOME}/.ssh"


###############################################################################
# Return SSH key path with name `${1}`
#
# Exit with failure code when ssh key doesn't exist or read permissions
# aren't granted for user.
#
# Globals:
#   None
# Arguments:
#   $1 - key name
# Returns:
#   SSH key path
###############################################################################
function get_ssh_key_path () {
    local ssh_key_path="${SSH_DIRECTORY}/${1}"

    if [[ ! -r "${ssh_key_path}" ]];
    then
        echo "File: ${ssh_key_path} - doesn't exists or "\
             "read permission is not granted"
        exit 1
    fi

    echo "${ssh_key_path}"
}


###############################################################################
# Add SSH key to SSH agent.
#
# TODO(skarzi): If `ssh-agent` is not running, run it firstly.
#
# Globals:
#   None
# Arguments:
#   $1 - path to SSH key
# Returns:
#   None
###############################################################################
function add_ssh_key () {
    ssh_key_fingerprint="$(ssh-keygen -lf "${1}"  | awk '{print $2}')"

    if ! (ssh-add -l | grep -q "$ssh_key_fingerprint"); then
        echo "Adding ${ssh_key_fingerprint} (${1}) to ssh-agent"
        ssh-add "${1}"
    fi
}


# bash version of pythons: `if __name__ == '__main__':`
if [[ "${BASH_SOURCE[0]}" == "${0}" ]];
then
    ssh_key_path=$(get_ssh_key_path "${1:-id_ed25519}")
    add_ssh_key "${ssh_key_path}"
fi
