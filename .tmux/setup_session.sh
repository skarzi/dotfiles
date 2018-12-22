#!/bin/bash


###############################################################################
# Setup TMUX session with `$1` name defined in `$2` tmux source file
# if session doesn't exist
#
# Globals:
#   None
# Arguments:
#   $1 - session name
#   $2 - tmux source file with session definition
# Returns:
#   None
###############################################################################
setup_tmux_session_from_file () {
    tmux has-session -t "$1" 2> /dev/null || tmux source-file "$2"
}


setup_tmux_session_from_file "$1" "$2"
