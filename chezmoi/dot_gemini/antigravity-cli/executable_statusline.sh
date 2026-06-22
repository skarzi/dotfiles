#!/bin/bash
# shellcheck shell=bash

# Antigravity CLI statusline custom script.
#
# Prints a customized terminal status line based on JSON telemetry from stdin.

set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
readonly RESET="\033[0m" # Reset
readonly BOLD="\033[1m"  # Bold

# Foreground colors (standard 16-color palette).
readonly FG_RED="\033[31m"
readonly FG_GREEN="\033[32m"
readonly FG_YELLOW="\033[33m"
readonly FG_BLUE="\033[34m"
readonly FG_MAGENTA="\033[35m"
readonly FG_CYAN="\033[36m"
readonly FG_WHITE="\033[37m"
readonly FG_GRAY="\033[90m"

# Highlight configurations.
readonly NUM_COLOR="${FG_WHITE}${BOLD}"
readonly DOT="${FG_GRAY} · ${RESET}"

# Generates a visual progress bar for context window usage.
# Globals:
#   None
# Arguments:
#   ${1}: Percentage of context window used (integer 0-100)
#   ${2}: Length of the progress bar in characters
# Outputs:
#   Writes the visual bar string to STDOUT
# Returns:
#   0
generate_context_bar() {
  local -i used_pct="${1:-0}"
  local -i bar_len="${2:-10}"
  local -i filled=$((used_pct * bar_len / 100))
  local bar=""
  local -i index

  for ((index = 0; index < bar_len; index++)); do
    if ((index < filled)); then
      bar="${bar}█"
    else
      bar="${bar}·"
    fi
  done

  echo -n "${bar}"
  return 0
}

# Formats the agent state indicator.
# Globals:
#   RESET
#   BOLD
#   FG_GREEN
#   FG_YELLOW
#   FG_CYAN
#   FG_MAGENTA
#   FG_WHITE
# Arguments:
#   ${1}: The raw state string (e.g., "idle", "thinking")
# Outputs:
#   Writes the formatted state indicator to STDOUT
# Returns:
#   0
format_agent_state() {
  local state="${1:-idle}"
  local state_indicator

  case "${state}" in
    idle) state_indicator="${FG_GREEN}${BOLD}● READY${RESET}" ;;
    thinking) state_indicator="${FG_YELLOW}${BOLD}◆ THINKING${RESET}" ;;
    working) state_indicator="${FG_CYAN}${BOLD}⚙ WORKING${RESET}" ;;
    tool_use) state_indicator="${FG_MAGENTA}${BOLD}🔧 TOOL${RESET}" ;;
    *) state_indicator="${FG_WHITE}${BOLD}⏳ $(echo "${state}" | tr '[:lower:]' '[:upper:]')${RESET}" ;;
  esac

  echo -n "${state_indicator}"
  return 0
}

# Formats the active agent profile and model.
# Globals:
#   RESET
#   FG_GRAY
#   FG_WHITE
#   FG_MAGENTA
# Arguments:
#   ${1}: Active agent profile name
#   ${2}: Active model name
# Outputs:
#   Writes the formatted agent and model info to STDOUT
# Returns:
#   0
format_agent_info() {
  local agent_name="${1}"
  local model_name="${2}"
  local agent_info=""

  if [[ -n "${agent_name}" && -n "${model_name}" ]]; then
    agent_info="${FG_GRAY} ╱ ${FG_WHITE}${agent_name}${FG_GRAY} (${FG_MAGENTA}${model_name}${FG_GRAY})${RESET}"
  elif [[ -n "${agent_name}" ]]; then
    agent_info="${FG_GRAY} ╱ ${FG_WHITE}${agent_name}${RESET}"
  elif [[ -n "${model_name}" ]]; then
    agent_info="${FG_GRAY} ╱ ${FG_MAGENTA}${model_name}${RESET}"
  fi

  echo -n "${agent_info}"
  return 0
}

# Formats the VCS branch status.
# Globals:
#   RESET
#   FG_GRAY
#   FG_RED
#   FG_YELLOW
#   FG_BLUE
# Arguments:
#   ${1}: VCS branch name
#   ${2}: VCS dirty status ("true" or "false")
# Outputs:
#   Writes the formatted VCS status to STDOUT
# Returns:
#   0
format_vcs_info() {
  local vcs_branch="${1}"
  local vcs_dirty="${2:-false}"
  local vcs_info=""

  if [[ -n "${vcs_branch}" ]]; then
    if [[ "${vcs_dirty}" == "true" ]]; then
      vcs_info="${FG_GRAY} ╱ ${FG_RED}⎇ ${vcs_branch}${FG_YELLOW}*${RESET}"
    else
      vcs_info="${FG_GRAY} ╱ ${FG_BLUE}⎇ ${vcs_branch}${RESET}"
    fi
  fi

  echo -n "${vcs_info}"
  return 0
}

# Formats the sandbox configuration badge.
# Globals:
#   RESET
#   FG_GREEN
#   FG_RED
# Arguments:
#   ${1}: Sandbox enabled status ("true" or "false")
# Outputs:
#   Writes the formatted sandbox badge to STDOUT
# Returns:
#   0
format_sandbox_badge() {
  local sandbox_enabled="${1:-false}"
  local sandbox_badge

  if [[ "${sandbox_enabled}" == "true" ]]; then
    sandbox_badge="${FG_GREEN}🔒 SB${RESET}"
  else
    sandbox_badge="${FG_RED}🔓 YOLO${RESET}"
  fi

  echo -n "${sandbox_badge}"
  return 0
}

# Formats the context window usage indicator.
# Globals:
#   RESET
#   FG_GRAY
#   FG_RED
#   FG_YELLOW
#   FG_GREEN
#   NUM_COLOR
# Arguments:
#   ${1}: Percentage of context window used (integer/float string)
# Outputs:
#   Writes the formatted context window text and progress bar to STDOUT
# Returns:
#   0
format_context_info() {
  local used_pct="${1:-0}"
  local pct_fmt
  pct_fmt="$(LC_NUMERIC=C printf "%.1f" "${used_pct}")"

  local -i pct_int
  pct_int="${used_pct%.*}"
  pct_int="${pct_int:-0}"

  local bar_color
  if ((pct_int >= 90)); then
    bar_color="${FG_RED}"
  elif ((pct_int >= 60)); then
    bar_color="${FG_YELLOW}"
  else
    bar_color="${FG_GREEN}"
  fi

  local bar
  bar="$(generate_context_bar "${pct_int}" 10)"

  echo -n "${FG_GRAY}ctx ${bar_color}${bar} ${NUM_COLOR}${pct_fmt}%${RESET}"
  return 0
}

# Formats the artifacts counter indicator.
# Globals:
#   RESET
#   FG_GRAY
#   NUM_COLOR
# Arguments:
#   ${1}: Number of artifacts
# Outputs:
#   Writes the formatted artifacts counter to STDOUT
# Returns:
#   0
format_artifacts_counter() {
  local artifact_count="${1:-0}"

  echo -n "${FG_GRAY}📦 ${NUM_COLOR}${artifact_count}${RESET}"
  return 0
}

# Formats the subagents active list and count.
# Globals:
#   RESET
#   FG_GRAY
#   NUM_COLOR
# Arguments:
#   ${1}: Total count of subagents
#   ${2}: Summary list of subagents names and status
# Outputs:
#   Writes the formatted subagents info to STDOUT
# Returns:
#   0
format_subagents_info() {
  local -i subagents_len="${1:-0}"
  local subagents_info="${2}"

  if ((subagents_len > 0)); then
    echo -n "${FG_GRAY}🤖 ${NUM_COLOR}${subagents_len}${FG_GRAY} (${subagents_info})${RESET}"
  fi
  return 0
}

# Formats the pending inputs notification badge.
# Globals:
#   RESET
#   FG_YELLOW
#   NUM_COLOR
# Arguments:
#   ${1}: Number of pending inputs
# Outputs:
#   Writes the formatted pending inputs badge to STDOUT
# Returns:
#   0
format_pending_inputs() {
  local -i pending_input_count="${1:-0}"

  if ((pending_input_count > 0)); then
    echo -n "${FG_YELLOW}📥 ${NUM_COLOR}${pending_input_count}${RESET}"
  fi
  return 0
}

# Main entry point for the statusline script.
# Parses JSON from stdin and prints the status line to stdout.
# Globals:
#   DOT
#   FG_GRAY
#   RESET
# Arguments:
#   None
# Outputs:
#   Writes the formatted status line to STDOUT
# Returns:
#   0 on success, non-zero on failure
main() {
  local state="idle"
  local used_pct="0"
  local vcs_branch=""
  local vcs_dirty="false"
  local sandbox_enabled="false"
  local artifact_count="0"
  local subagents_len="0"
  local subagents_info=""
  local pending_input_count="0"
  local model_name=""
  local agent_name=""
  local -i terminal_cols=80

  # Read and parse JSON from stdin in a single pass.
  {
    read -r state
    read -r used_pct
    read -r vcs_branch
    read -r vcs_dirty
    read -r sandbox_enabled
    read -r artifact_count
    read -r subagents_len
    read -r subagents_info
    read -r pending_input_count
    read -r model_name
    read -r agent_name
    read -r terminal_cols
  } <<< "$(
    jq -r '
      (.agent_state // "idle"),
      (.context_window.used_percentage // 0),
      (.vcs.branch // ""),
      (.vcs.dirty // false),
      (.sandbox.enabled // false),
      (.artifact_count // 0),
      (if .subagents | type == "array" then (.subagents | length) else 0 end),
      (if .subagents | type == "array" then [.subagents[] | "\(.name)(\(if .status == "thinking" then "◆" elif .status == "working" then "⚙" elif .status == "tool_use" then "🔧" else "●" end))"] | join(",") else "" end),
      (.pending_input_count // 0),
      (.model.display_name // ""),
      (.agent // ""),
      (.terminal_width // 80)
    ' 2> /dev/null || printf "idle\n0\n\nfalse\nfalse\n0\n0\n\n0\n\n\n80\n"
  )"

  local state_indicator
  state_indicator="$(format_agent_state "${state}")"

  local agent_info
  agent_info="$(format_agent_info "${agent_name}" "${model_name}")"

  local vcs_info
  vcs_info="$(format_vcs_info "${vcs_branch}" "${vcs_dirty}")"

  local sandbox_badge
  sandbox_badge="$(format_sandbox_badge "${sandbox_enabled}")"

  local ctx
  ctx="$(format_context_info "${used_pct}")"

  local art_fmt
  art_fmt="$(format_artifacts_counter "${artifact_count}")"

  local sub_fmt
  sub_fmt="$(format_subagents_info "${subagents_len}" "${subagents_info}")"

  local pend_fmt
  pend_fmt="$(format_pending_inputs "${pending_input_count}")"

  # Construct the secondary line elements.
  local parts=()
  [[ -n "${sandbox_badge}" ]] && parts+=("${sandbox_badge}")
  [[ -n "${ctx}" ]] && parts+=("${ctx}")
  [[ -n "${art_fmt}" ]] && parts+=("${art_fmt}")
  [[ -n "${sub_fmt}" ]] && parts+=("${sub_fmt}")
  [[ -n "${pend_fmt}" ]] && parts+=("${pend_fmt}")

  local line2=""
  local part
  local first="true"
  for part in "${parts[@]}"; do
    if [[ "${first}" == "true" ]]; then
      line2="${part}"
      first="false"
    else
      line2="${line2}${DOT}${part}"
    fi
  done

  local line1="${state_indicator}${agent_info}${vcs_info}"

  # Output layout based on terminal width.
  if ((terminal_cols >= 120)); then
    # Wide layout: single line.
    printf "%b\n" "${line1}${FG_GRAY}  │  ${RESET}${line2}"
  elif ((terminal_cols >= 80)); then
    # Medium layout: two lines with borders.
    printf "%b\n" "${FG_GRAY}╭─${RESET} ${line1}"
    printf "%b\n" "${FG_GRAY}╰─${RESET} ${line2}"
  else
    # Narrow layout: compact two lines.
    printf "%b\n" "${state_indicator}${agent_info}"
    printf "%b\n" "${line2}"
  fi

  return 0
}

# NOTE: We cannot use `${@}` env, because it's unsupported by antigravity-cli.
main
