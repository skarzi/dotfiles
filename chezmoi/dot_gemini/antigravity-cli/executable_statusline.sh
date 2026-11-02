#!/usr/bin/env bash
# shellcheck shell=bash

# Antigravity CLI statusline custom script.
#
# Prints a customized terminal status line based on JSON telemetry from stdin.

set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
readonly RESET=$'\033[0m'
readonly BOLD=$'\033[1m'

# Foreground colors (standard 16-color palette).
readonly FG_RED=$'\033[31m'
readonly FG_GREEN=$'\033[32m'
readonly FG_YELLOW=$'\033[33m'
readonly FG_BLUE=$'\033[34m'
readonly FG_MAGENTA=$'\033[35m'
readonly FG_CYAN=$'\033[36m'
readonly FG_WHITE=$'\033[37m'
readonly FG_GRAY=$'\033[90m'

# Highlight configurations.
readonly NUMBER_COLOR="${FG_WHITE}${BOLD}"
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
  local -i used_percentage="${1:-0}"
  local -i bar_length="${2:-10}"
  local -i filled=$((used_percentage * bar_length / 100))
  local bar=""
  local -i index

  for ((index = 0; index < bar_length; index++)); do
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
#   BOLD
#   FG_CYAN
#   FG_GREEN
#   FG_MAGENTA
#   FG_WHITE
#   FG_YELLOW
#   RESET
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
    *) state_indicator="${FG_WHITE}${BOLD}⏳ ${state^^}${RESET}" ;;
  esac

  echo -n "${state_indicator}"
  return 0
}

# Formats the active agent profile and model.
# Globals:
#   FG_GRAY
#   FG_MAGENTA
#   FG_WHITE
#   RESET
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
#   FG_BLUE
#   FG_GRAY
#   FG_RED
#   FG_YELLOW
#   RESET
# Arguments:
#   ${1}: VCS branch name
#   ${2}: VCS dirty status ("true" or "false")
# Outputs:
#   Writes the formatted VCS status to STDOUT
# Returns:
#   0
format_vcs_info() {
  local vcs_branch="${1}"
  local is_vcs_dirty="${2:-false}"
  local vcs_info=""

  if [[ -n "${vcs_branch}" ]]; then
    if [[ "${is_vcs_dirty}" == "true" ]]; then
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
#   FG_GREEN
#   FG_RED
#   RESET
# Arguments:
#   ${1}: Sandbox enabled status ("true" or "false")
# Outputs:
#   Writes the formatted sandbox badge to STDOUT
# Returns:
#   0
format_sandbox_badge() {
  local is_sandbox_enabled="${1:-false}"
  local sandbox_badge

  if [[ "${is_sandbox_enabled}" == "true" ]]; then
    sandbox_badge="${FG_GREEN}🔒 SB${RESET}"
  else
    sandbox_badge="${FG_RED}🔓 YOLO${RESET}"
  fi

  echo -n "${sandbox_badge}"
  return 0
}

# Formats the execution cycle mode indicator.
# Globals:
#   BOLD
#   FG_CYAN
#   FG_MAGENTA
#   FG_WHITE
#   FG_YELLOW
#   RESET
# Arguments:
#   ${1}: Raw cycle mode string (e.g., "auto", "plan", "accept-edits")
# Outputs:
#   Writes the formatted cycle mode indicator to STDOUT
# Returns:
#   0
format_cycle_mode() {
  local mode="${1}"
  local mode_indicator=""

  if [[ -z "${mode}" ]]; then
    return 0
  fi

  local mode_label="${mode^^}"

  case "${mode_label}" in
    AUTO) mode_indicator="${FG_CYAN}${BOLD}${mode_label}${RESET}" ;;
    PLAN) mode_indicator="${FG_MAGENTA}${BOLD}${mode_label}${RESET}" ;;
    ACCEPT-EDITS) mode_indicator="${FG_YELLOW}${BOLD}${mode_label}${RESET}" ;;
    *) mode_indicator="${FG_WHITE}${BOLD}${mode_label}${RESET}" ;;
  esac

  echo -n "${mode_indicator}"
  return 0
}

# Formats the Vim editor mode indicator.
# Globals:
#   BOLD
#   FG_BLUE
#   FG_GREEN
#   FG_MAGENTA
#   FG_RED
#   FG_WHITE
#   FG_YELLOW
#   RESET
# Arguments:
#   ${1}: Raw vim mode string (e.g., "NORMAL", "INSERT")
# Outputs:
#   Writes the formatted vim mode indicator to STDOUT
# Returns:
#   0
format_vim_mode() {
  local mode="${1}"
  local mode_indicator=""

  if [[ -z "${mode}" ]]; then
    return 0
  fi

  local mode_label="${mode^^}"

  case "${mode_label}" in
    NORMAL) mode_indicator="${FG_GREEN}${BOLD}${mode_label}${RESET}" ;;
    INSERT) mode_indicator="${FG_BLUE}${BOLD}${mode_label}${RESET}" ;;
    VISUAL | VISUAL-LINE | VISUAL-BLOCK) mode_indicator="${FG_MAGENTA}${BOLD}${mode_label}${RESET}" ;;
    REPLACE) mode_indicator="${FG_RED}${BOLD}${mode_label}${RESET}" ;;
    COMMAND) mode_indicator="${FG_YELLOW}${BOLD}${mode_label}${RESET}" ;;
    *) mode_indicator="${FG_WHITE}${BOLD}${mode_label}${RESET}" ;;
  esac

  echo -n "${mode_indicator}"
  return 0
}

# Formats the context window usage indicator.
# Globals:
#   FG_GRAY
#   FG_GREEN
#   FG_RED
#   FG_YELLOW
#   NUMBER_COLOR
#   RESET
# Arguments:
#   ${1}: Percentage of context window used (integer/float string)
# Outputs:
#   Writes the formatted context window text and progress bar to STDOUT
# Returns:
#   0
format_context_info() {
  local used_percentage="${1:-0}"
  local formatted_percentage
  formatted_percentage="$(LC_NUMERIC=C printf "%.1f" "${used_percentage}")"

  local -i integer_percentage
  integer_percentage="${used_percentage%.*}"
  integer_percentage="${integer_percentage:-0}"

  local bar_color
  if ((integer_percentage >= 90)); then
    bar_color="${FG_RED}"
  elif ((integer_percentage >= 60)); then
    bar_color="${FG_YELLOW}"
  else
    bar_color="${FG_GREEN}"
  fi

  local bar
  bar="$(generate_context_bar "${integer_percentage}" 10)"

  echo -n "${FG_GRAY}ctx ${bar_color}${bar} ${NUMBER_COLOR}${formatted_percentage}%${RESET}"
  return 0
}

# Formats the artifacts counter indicator.
# Globals:
#   FG_GRAY
#   NUMBER_COLOR
#   RESET
# Arguments:
#   ${1}: Number of artifacts
# Outputs:
#   Writes the formatted artifacts counter to STDOUT
# Returns:
#   0
format_artifacts_counter() {
  local artifact_count="${1:-0}"

  echo -n "${FG_GRAY}📦 ${NUMBER_COLOR}${artifact_count}${RESET}"
  return 0
}

# Formats the subagents active list and count.
# Globals:
#   FG_GRAY
#   NUMBER_COLOR
#   RESET
# Arguments:
#   ${1}: Total count of subagents
#   ${2}: Summary list of subagents names and status
# Outputs:
#   Writes the formatted subagents info to STDOUT
# Returns:
#   0
format_subagents_info() {
  local -i subagents_length="${1:-0}"
  local subagents_info="${2}"

  if ((subagents_length > 0)); then
    echo -n "${FG_GRAY}🤖 ${NUMBER_COLOR}${subagents_length}${FG_GRAY} (${subagents_info})${RESET}"
  fi
  return 0
}

# Formats the pending inputs notification badge.
# Globals:
#   FG_YELLOW
#   NUMBER_COLOR
#   RESET
# Arguments:
#   ${1}: Number of pending inputs
# Outputs:
#   Writes the formatted pending inputs badge to STDOUT
# Returns:
#   0
format_pending_inputs() {
  local -i pending_input_count="${1:-0}"

  if ((pending_input_count > 0)); then
    echo -n "${FG_YELLOW}📥 ${NUMBER_COLOR}${pending_input_count}${RESET}"
  fi
  return 0
}

# Calculates the visible terminal display width of a string.
# Strips ANSI escape sequences and accounts for 2-column wide emoji characters.
# Globals:
#   None
# Arguments:
#   ${1}: String possibly containing ANSI escapes and Unicode characters
# Outputs:
#   Writes the integer display width to STDOUT
# Returns:
#   0
get_visible_length() {
  local input_string="${1}"
  local escape_char=$'\033'

  # Strip ANSI escape sequences using bash extended globbing.
  shopt -s extglob
  local clean_string="${input_string//${escape_char}\[*([0-9;])[a-zA-Z]/}"
  clean_string="${clean_string//\\033\[*([0-9;])[a-zA-Z]/}"

  local -i character_length="${#clean_string}"

  # Count emojis that occupy 2 terminal columns (each adds 1 to character length).
  # Known 2-column wide emojis in this script: 🔒 🔓 ⚙ 🔧 ⏳ 📦 🤖 📥
  local emoji_stripped="${clean_string//[🔒🔓⚙🔧⏳📦🤖📥]/}"
  local -i emoji_count=$((character_length - ${#emoji_stripped}))
  local -i display_width=$((character_length + emoji_count))

  echo -n "${display_width}"
  return 0
}

# Joins an array of strings using the statusline separator dot.
# Globals:
#   DOT
# Arguments:
#   ${@}: Strings to join
# Outputs:
#   Writes the joined string to STDOUT
# Returns:
#   0
join_with_dot() {
  local result=""
  local is_first="true"
  local item

  for item in "${@}"; do
    if [[ "${is_first}" == "true" ]]; then
      result="${item}"
      is_first="false"
    else
      result="${result}${DOT}${item}"
    fi
  done

  echo -n "${result}"
  return 0
}

# Formats a statusline line with left content and right-aligned content.
# Globals:
#   None
# Arguments:
#   ${1}: Left-hand content string
#   ${2}: Right-hand content string (sticked to right side)
#   ${3}: Target terminal width in columns (integer)
#   ${4}: Optional prefix string (default: "")
# Outputs:
#   Writes the formatted line to STDOUT
# Returns:
#   0
format_aligned_line() {
  local left_content="${1}"
  local right_content="${2}"
  local -i target_width="${3:-80}"
  local prefix="${4:-}"

  if [[ -z "${right_content}" ]]; then
    printf "%b\n" "${prefix}${left_content}"
    return 0
  fi

  local -i prefix_length
  prefix_length="$(get_visible_length "${prefix}")"

  local -i left_length
  left_length="$(get_visible_length "${left_content}")"

  local -i right_length
  right_length="$(get_visible_length "${right_content}")"

  local -i padding_length=$((target_width - prefix_length - left_length - right_length))

  if ((padding_length >= 1)); then
    local spaces
    spaces="$(printf "%*s" "${padding_length}" "")"
    printf "%b\n" "${prefix}${left_content}${spaces}${right_content}"
  elif [[ -n "${left_content}" ]]; then
    printf "%b\n" "${prefix}${left_content} ${right_content}"
  else
    printf "%b\n" "${prefix}${right_content}"
  fi

  return 0
}

# Main entry point for the statusline script.
# Parses JSON from stdin and prints the status line to stdout.
# Globals:
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
  local used_percentage="0"
  local vcs_branch=""
  local is_vcs_dirty="false"
  local is_sandbox_enabled="false"
  local artifact_count="0"
  local subagents_length="0"
  local subagents_info=""
  local pending_input_count="0"
  local model_name=""
  local agent_name=""
  local cycle_mode=""
  local vim_mode=""
  local -i terminal_width=80

  # Read and parse JSON from stdin in a single pass.
  {
    read -r state
    read -r used_percentage
    read -r vcs_branch
    read -r is_vcs_dirty
    read -r is_sandbox_enabled
    read -r artifact_count
    read -r subagents_length
    read -r subagents_info
    read -r pending_input_count
    read -r model_name
    read -r agent_name
    read -r cycle_mode
    read -r vim_mode
    read -r terminal_width
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
      (.cycle_mode // ""),
      (.vim.mode // ""),
      (.terminal_width // 80)
    ' 2> /dev/null || printf "idle\n0\n\nfalse\nfalse\n0\n0\n\n0\n\n\n\n\n80\n"
  )"

  local state_indicator
  state_indicator="$(format_agent_state "${state}")"

  local agent_info
  agent_info="$(format_agent_info "${agent_name}" "${model_name}")"

  local vcs_info
  vcs_info="$(format_vcs_info "${vcs_branch}" "${is_vcs_dirty}")"

  local sandbox_badge
  sandbox_badge="$(format_sandbox_badge "${is_sandbox_enabled}")"

  local cycle_mode_indicator
  cycle_mode_indicator="$(format_cycle_mode "${cycle_mode}")"

  local vim_mode_indicator
  vim_mode_indicator="$(format_vim_mode "${vim_mode}")"

  local context_info
  context_info="$(format_context_info "${used_percentage}")"

  local artifacts_indicator
  artifacts_indicator="$(format_artifacts_counter "${artifact_count}")"

  local subagents_indicator
  subagents_indicator="$(format_subagents_info "${subagents_length}" "${subagents_info}")"

  local pending_inputs_indicator
  pending_inputs_indicator="$(format_pending_inputs "${pending_input_count}")"

  # Construct the secondary line left elements.
  local left_parts=()
  [[ -n "${sandbox_badge}" ]] && left_parts+=("${sandbox_badge}")
  [[ -n "${cycle_mode_indicator}" ]] && left_parts+=("${cycle_mode_indicator}")
  [[ -n "${context_info}" ]] && left_parts+=("${context_info}")
  [[ -n "${artifacts_indicator}" ]] && left_parts+=("${artifacts_indicator}")
  [[ -n "${subagents_indicator}" ]] && left_parts+=("${subagents_indicator}")
  [[ -n "${pending_inputs_indicator}" ]] && left_parts+=("${pending_inputs_indicator}")

  # Construct the secondary line right elements (only vim mode on right side).
  local right_parts=()
  [[ -n "${vim_mode_indicator}" ]] && right_parts+=("${vim_mode_indicator}")

  local secondary_line_left
  secondary_line_left="$(join_with_dot "${left_parts[@]}")"

  local secondary_line_right
  secondary_line_right="$(join_with_dot "${right_parts[@]}")"

  local primary_line="${state_indicator}${agent_info}${vcs_info}"

  # Output layout based on terminal width.
  if ((terminal_width >= 120)); then
    # Wide layout: single line with right-aligned status elements.
    local wide_line_content="${primary_line}${FG_GRAY}  │  ${RESET}${secondary_line_left}"
    format_aligned_line "${wide_line_content}" "${secondary_line_right}" "${terminal_width}" ""
  elif ((terminal_width >= 80)); then
    # Medium layout: two lines with borders.
    printf "%b\n" "${FG_GRAY}╭─${RESET} ${primary_line}"
    format_aligned_line "${secondary_line_left}" "${secondary_line_right}" "${terminal_width}" "${FG_GRAY}╰─${RESET} "
  else
    # Narrow layout: compact two lines.
    printf "%b\n" "${state_indicator}${agent_info}"
    format_aligned_line "${secondary_line_left}" "${secondary_line_right}" "${terminal_width}" ""
  fi

  return 0
}

# NOTE: We cannot use `${@}` env, because it's unsupported by antigravity-cli.
main
