#!/usr/bin/env bash

# Shares Bash history between sessions while keeping the commands of the
# current session at the end of the in-memory list (so they come first when
# going back with the up arrow).
#
# This file must be sourced by an interactive shell, not executed: `history`
# only affects the shell it runs in. It prepends `__hist_sync` to
# `${PROMPT_COMMAND}` without exporting it, so child shells are unaffected.
# Sourcing it again in the same shell does nothing. Nothing is done when
# `${HISTFILE}` is unset or empty, which is how bash disables saving history.
#
# NOTE: Known limits:
# - A command with a quoted newline is split into two entries right away.
# - With `HISTCONTROL=erasedups` a retyped duplicate does not grow `HISTCMD`,
#   so it is not logged as a session command.
# - With `HISTTIMEFORMAT` set the timestamp lines break the deduplication.
#
# Per prompt, `__hist_sync` builds a file made of the global history (without
# the session commands) followed by the session commands, and reloads it.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: ${0} must be sourced, not executed." >&2
  exit 1
fi

if declare -F __hist_sync > /dev/null; then
  return 0
fi

# Session log of every command typed in this shell.
__hist_log="${TMPDIR:-/tmp}/.bash_session_history.${$}"

# The files hold the command history, so create them private from the start.
# If this fails, `__hist_sync` notices that the log is not writable.
(umask 077 && : >> "${__hist_log}" && : >> "${__hist_log}.load") 2> /dev/null || :

# Syncs the in-memory history with `${HISTFILE}`. Runs as the first
# `${PROMPT_COMMAND}` hook and preserves `${?}` for the following ones.
# Globals:
#   HISTCMD (read)
#   HISTFILE (read)
#   __hist_log (read)
#   __hist_seen (read-write)
# Returns:
#   The exit status of the last command, as seen on entry.
__hist_sync() {
  local exit_status="${?}"
  local command_text
  local load_file="${__hist_log}.load"

  # Without a history file or a writable log there is nothing to do.
  if [[ -z "${HISTFILE-}" ]]; then
    return "${exit_status}"
  fi
  if ! { : >> "${__hist_log}"; } 2> /dev/null; then
    return "${exit_status}"
  fi

  # The first prompt only records `HISTCMD`, because `${HISTFILE}` is loaded
  # after the rc files ran. Later, `HISTCMD` grows only for commands that
  # bash kept, which skips empty lines and `ignoreboth` commands for free.
  if ((HISTCMD > ${__hist_seen:-HISTCMD})); then
    # NOTE: `fc -ln -1` returned the wrong entry inside `PROMPT_COMMAND`, so
    # use `history 1` and strip the entry number and padding.
    command_text="$(HISTTIMEFORMAT='' history 1)"
    command_text="${command_text#"${command_text%%[![:space:]]*}"}"
    command_text="${command_text#[0-9]*[[:space:]]}"
    printf '%s\n' "${command_text#"${command_text%%[![:space:]]*}"}" >> "${__hist_log}"
  fi

  history -a "${HISTFILE}" 2> /dev/null || :

  # Both parts are deduplicated keeping the last occurrence, so a repeated
  # command ends up closest to the end of the list. In awk, `NR` is the number
  # of the current line over all input and `FNR` the number within the current
  # file, so `NR == FNR` is true only while the first pass reads `HISTFILE`.
  {
    if [[ -r "${HISTFILE}" ]]; then
      awk -v session_log_path="${__hist_log}" '
        BEGIN {
          while ((getline session_line < session_log_path) > 0) {
            session_commands[session_line]
          }
        }
        NR == FNR { last_line_number[$0] = FNR; next }
        last_line_number[$0] == FNR && !($0 in session_commands)
      ' "${HISTFILE}" "${HISTFILE}"
    fi
    awk '
      { last_line_number[$0] = NR; lines[NR] = $0 }
      END {
        for (position = 1; position <= NR; position++) {
          if (last_line_number[lines[position]] == position) print lines[position]
        }
      }
    ' "${__hist_log}"
  } > "${load_file}" 2> /dev/null

  # NOTE: `history -r` silently loads nothing from a process substitution, it
  # needs a regular file. The file is kept per session to avoid a `mktemp`
  # fork on every prompt.
  history -c
  history -r "${load_file}"
  __hist_seen="${HISTCMD}"
  return "${exit_status}"
}

# Removes the files of this session.
# Globals:
#   __hist_log (read)
__hist_cleanup() {
  rm -f "${__hist_log}" "${__hist_log}.load"
  return 0
}

PROMPT_COMMAND="__hist_sync${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}"
# NOTE: This replaces any existing `EXIT` trap, the rc files set none.
trap '__hist_cleanup' EXIT
