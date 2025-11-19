#!/bin/bash

# Manages Bash history across multiple sessions with a focus on preserving
# recent commands from the current session at the top of the history.
#
# This script is intended to be called by `${PROMPT_COMMAND}` in .bashrc:
# `PROMPT_COMMAND="bash /path/to/this_script.sh"`

set -o nounset
set -o pipefail

# Configuration: Number of recent unique commands from the current session
# to keep at the top of the history.
# Allows override from environment for testing, e.g. export BASH_SESSION_PRESERVE_COUNT=3
BASH_SESSION_PRESERVE_COUNT="${BASH_SESSION_PRESERVE_COUNT:-100}"

# File descriptor used for history file locking (common convention: 200).
readonly HISTFILE_LOCK_FD=200

# Global: Stores the HISTCMD value from the end of the previous PROMPT_COMMAND
# execution. Initialized to 0.
declare -gi g_custom_hist_last_seen_histcmd=0

# Cleans up session-specific temporary files.
# Globals:
#   BASHPID (read)
#   TMPDIR (read)
cleanup_session_history() {
  local session_log_file
  session_log_file="${TMPDIR:-/tmp}/.bash_session_history_${BASHPID}"

  if [[ -f "${session_log_file}" ]]; then
    rm -f "${session_log_file}"
  fi

  # Attempt to clean up any stray mktemp files from this script's pattern.
  rm -f "${TMPDIR:-/tmp}/bash_history_load."* \
        "${TMPDIR:-/tmp}/bash_history_patterns."* \
        "${TMPDIR:-/tmp}/bash_unique_hist."*
}

# Logs a new command to the session log if a new, valid command was executed.
# Arguments:
#   $1: Path to the session log file.
# Globals:
#   _INITIAL_HISTCMD (read) - required to make unit tests possible.
#   HISTCMD (read)
#   PROMPT_COMMAND (read)
#   g_custom_hist_last_seen_histcmd (read-write)
# Outputs:
#   None directly. Modifies session log file and g_custom_hist_last_seen_histcmd.
_log_new_command() {
  local session_log_file_path="$1"
  local current_command_text=""
  local is_new_command_executed=false
  local current_histcmd="${_INITIAL_HISTCMD:-$HISTCMD}"

  if (( current_histcmd > g_custom_hist_last_seen_histcmd )); then
    current_command_text="$(fc -ln -1 2>/dev/null)" # Suppress fc errors

    if [[ -n "${current_command_text}" && \
          "${current_command_text}" != "${PROMPT_COMMAND}" && \
          "${current_command_text}" != "main" ]]; then # Assuming main function is named "main"
      is_new_command_executed=true
    fi
  fi

  if [[ "${is_new_command_executed}" == true ]]; then
    echo "${current_command_text}" >> "${session_log_file_path}"
  fi

  # Always update g_custom_hist_last_seen_histcmd to the current_histcmd
  g_custom_hist_last_seen_histcmd="${current_histcmd}"
}

# Gets the N most recent unique commands from the session log.
# Arguments:
#   $1: Path to the session log file.
#   $2: Number of commands to preserve (BASH_SESSION_PRESERVE_COUNT).
# Outputs:
#   Newline-separated list of commands to standard output.
_get_preserved_session_commands_stdout() {
  local session_log_file_path="$1"
  local preserve_count="$2"

  if [[ -f "${session_log_file_path}" ]]; then
    tail --lines="${preserve_count}"  "${session_log_file_path}" | \
    tac | \
    awk '!b[$0]++ {print $0}' | \
    tac
  fi
}

# Acquires an exclusive lock on the history file to prevent concurrent access.
# Arguments:
#   $1: Path to the resolved global HISTFILE.
#   $2: Timeout in seconds (default: 2). If 0, blocks indefinitely.
# Globals:
#   _is_histfile_locked (write) - Set to 1 on success.
# Returns:
#   0 if lock acquired, 1 if lock acquisition failed or timed out.
_acquire_history_lock() {
  local timeout="${2:-2}"
  local lock_file="${1}.lock"

  if [[ ! -f "${lock_file}" ]]; then
    touch "${lock_file}" 2>/dev/null || return 1
  fi

  eval "exec ${HISTFILE_LOCK_FD}>${lock_file}" || return 1

  if command -v flock >/dev/null 2>&1; then
    if [[ "${timeout}" -gt 0 ]]; then
      flock -w "${timeout}" "${HISTFILE_LOCK_FD}" || return 1
    else
      flock "${HISTFILE_LOCK_FD}" || return 1
    fi
  else
    # Fallback when flock is not available (less reliable).
    if [[ -f "${lock_file}" ]]; then
      _is_histfile_locked=1
      return 0
    fi
    return 1
  fi

  _is_histfile_locked=1
  return 0
}

# Releases the history file lock.
# Globals:
#   _is_histfile_locked (read-write)
# Returns:
#   0 on success, 1 if no lock was held.
_release_history_lock() {
  if [[ -n "${_is_histfile_locked:-}" ]]; then
    eval "exec ${HISTFILE_LOCK_FD}>&-" 2>/dev/null || true
    unset _is_histfile_locked
    return 0
  fi
  return 1
}

# Gets unique global commands, filtered against a patterns file.
# Arguments:
#   $1: Path to the resolved global HISTFILE.
#   $2: Path to the patterns file (containing preserved session commands to exclude).
#       Can be an empty string or non-existent file if no patterns.
# Globals:
#   TMPDIR (read)
# Outputs:
#   Newline-separated list of filtered global commands to standard output.
# Returns:
#   0 on success, 1 if its internal mktemp fails.
_get_filtered_global_commands_stdout() {
  local resolved_histfile_path="$1"
  local patterns_file_path="$2"
  local unique_histfile_content_tempfile # Temp file for awk output

  if [[ ! -f "${resolved_histfile_path}" ]]; then
    return 0 # No global history file, output nothing, success.
  fi

  unique_histfile_content_tempfile="$(mktemp "bash_unique_hist.XXXXXX" --tmpdir="${TMPDIR:-/tmp}")"
  if [[ -z "${unique_histfile_content_tempfile}" ]]; then
    echo "Error: Helper: Failed to create temporary file for unique global history." >&2
    return 1 # Indicate failure to create temp file.
  fi

  # Get unique lines from histfile, preserving order.
  awk '!b[$0]++ {print $0}' "${resolved_histfile_path}" > "${unique_histfile_content_tempfile}"

  if [[ -n "${patterns_file_path}" && -s "${patterns_file_path}" ]]; then
    # Filter out commands already preserved from the current session.
    grep --invert-match --fixed-strings --line-regexp \
      --file="${patterns_file_path}" "${unique_histfile_content_tempfile}"
  else
    # Output all unique global history if no patterns file.
    cat "${unique_histfile_content_tempfile}"
  fi

  rm -f "${unique_histfile_content_tempfile}"
  return 0
}

# Main function to manage bash history.
# Globals:
#   BASHPID (read)
#   HISTFILE (read, for default value)
#   HOME (read, for default HISTFILE value)
#   TMPDIR (read)
#   BASH_SESSION_PRESERVE_COUNT (read from config.sh)
#   g_custom_hist_last_seen_histcmd (managed by _log_new_command)
main() {
  local session_log_file
  local temp_hist_for_loading
  local patterns_file="" # Path to temp file for patterns (session commands).
  local session_preserved_cmds_array=() # Array for preserved session commands.
  local filtered_global_cmds_string # String for filtered global commands.
  local resolved_histfile
  local lock_timeout=2  # Timeout in seconds for acquiring lock.

  session_log_file="${TMPDIR:-/tmp}/.bash_session_history_${BASHPID}"
  resolved_histfile="${HISTFILE:-${HOME}/.bash_history}"  # Resolve HISTFILE path
  HISTFILE="${resolved_histfile}"

  # 1. Log new command to session log and update
  # `g_custom_hist_last_seen_histcmd`.
  _log_new_command "${session_log_file}"

  # 2. Acquire lock on history file to prevent concurrent access.
  if ! _acquire_history_lock "${resolved_histfile}" "${HISTFILE_LOCK_TIMEOUT:-${lock_timeout}}"; then
    return 0  # Another instance is running, skip this run.
  fi

  trap '_release_history_lock' EXIT INT TERM

  # 3. Append new history items from shell memory to the global `${HISTFILE}`.
  history -a

  # 4. Get preserved session commands into an array.
  mapfile -t session_preserved_cmds_array < <( \
    _get_preserved_session_commands_stdout "${session_log_file}" "${BASH_SESSION_PRESERVE_COUNT}" \
  )

  # 5. Prepare temporary file for loading new history.
  temp_hist_for_loading="$(mktemp "bash_history_load.XXXXXX" --tmpdir="${TMPDIR:-/tmp}")"
  if [[ -z "${temp_hist_for_loading}" ]]; then
    echo "Error: Main: Failed to create temporary file for loading history." >&2
    _release_history_lock
    trap - EXIT INT TERM
    return 1
  fi
  echo -n '' > "${temp_hist_for_loading}" # Ensure it's empty.

  # 6. Create patterns file if there are preserved session commands.
  if [[ ${#session_preserved_cmds_array[@]} -gt 0 ]]; then
    patterns_file="$(mktemp "bash_history_patterns.XXXXXX" --tmpdir="${TMPDIR:-/tmp}")"
    if [[ -z "${patterns_file}" ]]; then
      echo "Error: Main: Failed to create temporary patterns file." >&2
      rm -f "${temp_hist_for_loading}"
      _release_history_lock
      trap - EXIT INT TERM
      return 1
    fi
    printf "%s\n" "${session_preserved_cmds_array[@]}" > "${patterns_file}"
  fi

  # 7. Get filtered global commands as a string.
  # If `_get_filtered_global_commands_stdout` fails
  # (e.g. its internal `mktemp`), it returns `1`. We capture its output
  # and check its status.
  if ! filtered_global_cmds_string="$(_get_filtered_global_commands_stdout "${resolved_histfile}" "${patterns_file}")"; then
    echo "Warning: Main: Failed to filter global commands. Global history might be incomplete." >&2
    # Proceeding with potentially empty `filtered_global_cmds_string`.
  fi


  # 8. Add preserved session commands to the temporary history load file.
  if [[ ${#session_preserved_cmds_array[@]} -gt 0 ]]; then
    printf "%s\n" "${session_preserved_cmds_array[@]}" >> "${temp_hist_for_loading}"
  fi

  # 9. Add filtered global commands to the temporary history load file.
  if [[ -n "${filtered_global_cmds_string}" ]]; then
    # Ensure trailing newline if string is not empty, `printf` handles this well.
    printf "%s\n" "${filtered_global_cmds_string}" >> "${temp_hist_for_loading}"
  fi

  # 10. Clean up patterns file.
  if [[ -n "${patterns_file}" ]]; then
    rm -f "${patterns_file}"
  fi

  # 11. Clear current in-memory history and load the new one.
  history -c
  if [[ -s "${temp_hist_for_loading}" ]]; then # Only read if file is not empty.
    history -r "${temp_hist_for_loading}"
  fi
  rm -f "${temp_hist_for_loading}" # Clean up the main temporary history file.

  # 12. Release history file lock before returning.
  _release_history_lock
  trap - EXIT INT TERM

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly
  # Set trap only when script is run directly
  trap cleanup_session_history EXIT
  main "${@}"
fi
