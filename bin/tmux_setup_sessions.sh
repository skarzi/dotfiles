#!/usr/bin/env bash
# shellcheck shell=bash

# Load tmuxp workspaces under `${HOME}/.config/tmux/workspaces/` that set
# `x-should-auto-load: true`. Any other file is
# skipped.

set -eufo pipefail

# Return 0 when ${1} sets `x-should-auto-load` to true.
#
# Reads the root `x-should-auto-load` with `yq`. Only the lowercase words
# `true` and `false` are recognized. tmuxp does not read this key.
#
# Globals:
#   None
# Arguments:
#   ${1}: Workspace file path.
# Outputs:
#   Writes a skip reason to STDERR when the workspace is not auto-loaded.
# Returns:
#   0 when the workspace should load, 1 otherwise.
is_workspace_auto_load_enabled() {
  local workspace_file="${1}"
  local auto_load_setting=""
  local auto_load_field="\`x-should-auto-load\`"

  if ! auto_load_setting="$(
    yq -r '.["x-should-auto-load"]' "${workspace_file}"
  )"; then
    printf 'tmux_setup_sessions: skip %s: cannot read %s\n' \
      "${workspace_file}" "${auto_load_field}" >&2
    return 1
  fi
  if [[ "${auto_load_setting}" == "null" ]]; then
    printf 'tmux_setup_sessions: skip %s: %s is unset\n' \
      "${workspace_file}" "${auto_load_field}" >&2
    return 1
  fi
  if [[ "${auto_load_setting}" != "true" ]]; then
    printf 'tmux_setup_sessions: skip %s: %s is %s\n' \
      "${workspace_file}" "${auto_load_field}" "${auto_load_setting}" >&2
    return 1
  fi
  return 0
}

# Return 0 when `tmux`, `yq`, and the tmuxp executable ${1} are usable.
#
# Globals:
#   None
# Arguments:
#   ${1}: tmuxp executable path.
# Outputs:
#   Writes a missing-command reason to STDERR.
# Returns:
#   0 when every CLI is usable, 1 otherwise.
has_required_clis() {
  local tmuxp_executable="${1}"

  if [[ ! -x "${tmuxp_executable}" ]]; then
    printf 'tmux_setup_sessions: tmuxp is not executable: %s\n' \
      "${tmuxp_executable}" >&2
    return 1
  fi
  if ! command -v tmux > /dev/null 2>&1; then
    printf 'tmux_setup_sessions: tmux is not installed.\n' >&2
    return 1
  fi
  if ! command -v yq > /dev/null 2>&1; then
    printf 'tmux_setup_sessions: yq is not installed.\n' >&2
    return 1
  fi
  return 0
}

# Load every auto-load tmuxp workspace file under ${1}.
#
# Globals:
#   HOME (read)
#   TMUXP (read): tmuxp executable. Defaults to the dotfiles virtualenv.
# Arguments:
#   ${1}: Workspaces directory. Defaults to ${HOME}/.config/tmux/workspaces.
# Outputs:
#   Writes errors to STDERR. tmuxp writes its own messages to STDOUT.
# Returns:
#   0 when every selected workspace loads.
#   1 when setup fails, nothing is selected, or tmuxp fails.
load_all_tmux_session_workspaces() {
  local workspaces_directory="${1:-${HOME}/.config/tmux/workspaces}"
  local tmuxp_executable="${TMUXP:-${HOME}/dotfiles/.venv/bin/tmuxp}"
  local sorted_workspace_paths=""
  local workspace_file=""
  local loaded_workspace_count=0
  local failed_workspace_count=0
  local -a workspace_files=()

  if [[ ! -d "${workspaces_directory}" ]]; then
    printf 'tmux_setup_sessions: no such directory: %s\n' \
      "${workspaces_directory}" >&2
    return 1
  fi
  if ! has_required_clis "${tmuxp_executable}"; then
    return 1
  fi

  sorted_workspace_paths="$(
    find "${workspaces_directory}" \
      -type f \
      \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) \
      | LC_ALL=C sort
  )"
  if [[ -z "${sorted_workspace_paths}" ]]; then
    printf 'tmux_setup_sessions: no workspace files in %s\n' \
      "${workspaces_directory}" >&2
    return 1
  fi

  mapfile -t workspace_files <<< "${sorted_workspace_paths}"
  for workspace_file in "${workspace_files[@]}"; do
    if ! is_workspace_auto_load_enabled "${workspace_file}"; then
      continue
    fi
    if ! "${tmuxp_executable}" load -d "${workspace_file}"; then
      printf 'tmux_setup_sessions: failed to load %s\n' \
        "${workspace_file}" >&2
      failed_workspace_count=$((failed_workspace_count + 1))
      continue
    fi
    loaded_workspace_count=$((loaded_workspace_count + 1))
  done

  if ((failed_workspace_count != 0 || loaded_workspace_count == 0)); then
    return 1
  fi
  return 0
}

load_all_tmux_session_workspaces \
  "${1:-${HOME}/.config/tmux/workspaces}"
