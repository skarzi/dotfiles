#!/bin/bash

SSH_DIRECTORY="${HOME}/.ssh"


###############################################################################
# Return SSH key path with name `${1}_rsa`
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
get_ssh_key_path () {
    ssh_key_path="${SSH_DIRECTORY}/${1}_rsa"
    if [[ ! -r "${ssh_key_path}" ]];
    then
        echo "File: ${ssh_key_path} - doesn't exists or"\
             "read permission is not granted"
        exit 1
    fi
}


###############################################################################
# Add SSH key to SSH agent.
#
# If `ssh-agent` is not running, run it firstly.
#
# Globals:
#   None
# Arguments:
#   $1 - ssh key path
# Returns:
#   None
###############################################################################
add_ssh_key () {
    (
        ssh-add "${1}" 2> dev/null \
        || (eval "$(ssh-agent -s)" && ssh-add "${1}" 2> /dev/null)
    ) \
    && echo "Identity added: ${1} (${1})"
}


# bash version of pythons: `if __name__ == '__main__':`
if [[ "${BASH_SOURCE[0]}" == "${0}" ]];
then
    get_ssh_key_path "${1:-id}"
    add_ssh_key "${ssh_key_path}"
fi
