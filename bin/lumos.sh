#!/usr/bin/env bash
# shellcheck shell=bash

# Keeps the Mac awake: a stateful wrapper around `caffeinate` (Bash 3.2 safe).
# State is one line, `pid kind value flags`, in the file of `state_file`.

# Prints the one-line synopsis to STDOUT.
usage() {
  echo "Usage: lumos {start|adjust|watch|run|stop|status|bedtime|help} [args]"
}

# Prints the full help text to STDOUT.
command_help() {
  cat << 'EOF'
Usage: lumos <command> [options]

  lumos start <duration> [-d|--display]     Start a timed session.
  lumos adjust <+|-duration>                Add or remove time (timed sessions).
  lumos watch <pid> [-d|--display]          Stay awake while <pid> is running.
  lumos run [-d|--display] -- <command...>  Stay awake while <command> runs.
  lumos stop                                Stop the session.
  lumos status [--short]                    Show the session (--short: compact).
  lumos bedtime [duration]                  Dim the lights, stay awake (12h).
  lumos help                                Show this help.

Durations: 30s, 15m, 2h. `-d` also keeps the display on. `stop` does not
restore brightness. `-i` does not block clamshell sleep on battery
(`caffeinate -s` needs AC power).
EOF
}

# Prints `lumos: ` and the message `${1}` to STDERR.
print_error() {
  printf 'lumos: %s\n' "${1}" >&2
}

# Prints the message `${1}` and the synopsis to STDERR.
report_bad_arguments() {
  print_error "${1}"
  usage >&2
}

# Prints the state file path, under `${XDG_STATE_HOME}` or `~/.local/state`.
state_file() {
  printf '%s\n' "${XDG_STATE_HOME:-${HOME}/.local/state}/lumos/session"
}

# Prints the seconds in a duration like `30s`, `15m` or `2h`; returns `1` if
# `${1}` is not one.
parse_duration() {
  local duration_text="${1:-}" duration_pattern='^[1-9][0-9]{0,5}[smh]$'
  local amount="${duration_text%?}"

  if ! [[ ${duration_text} =~ ${duration_pattern} ]]; then
    return 1
  fi
  case "${duration_text}" in
    *s) echo "${amount}" ;;
    *m) echo $((amount * 60)) ;;
    *h) echo $((amount * 3600)) ;;
  esac
  return 0
}

# Prints seconds `${1}` as `Xh Ym` (1 hour or more) or `Xm Ys`.
format_remaining() {
  local seconds="${1}"

  if ((seconds >= 3600)); then
    echo "$((seconds / 3600))h $((seconds % 3600 / 60))m"
  else
    echo "$((seconds / 60))m $((seconds % 60))s"
  fi
}

# Sets `display_flags` to `-i` or `-i -d` from `-d|--display` in `${@}`.
# Returns `1` on any other argument.
parse_display() {
  local argument

  display_flags="-i"
  for argument in "$@"; do
    case "${argument}" in
      -d | --display) display_flags="-i -d" ;;
      *)
        report_bad_arguments "Unknown option: ${argument}."
        return 1
        ;;
    esac
  done
  return 0
}

# The name `caffeinate` runs under (`exec -a`), so only lumos sessions match.
CAFFEINATE_PROCESS_NAME="lumos-caffeinate"

# Reads the live session into `session_pid`, `session_kind`, `session_value` and
# `session_flags` without changing anything. Call only inside `if`: the return
# status (`0` active, `1` not) is the answer.
# Not live: no state, malformed state, a dead or foreign process, or an expired
# timed session (also sets `session_expired` to `true`: the `caffeinate -t`
# timer pauses in sleep, so it can outlive it). A `bash ...lumos.sh` process is
# the new `caffeinate` between `fork` and `exec`.
read_session() {
  local file now process_command state_number_pattern='^[1-9][0-9]{0,11}$'

  session_expired=false
  file="$(state_file)"
  if [[ ! -f "${file}" ]]; then
    return 1
  fi

  session_pid="" session_kind="" session_value="" session_flags=""
  read -r session_pid session_kind session_value session_flags \
    < "${file}" || true
  if ! [[ ${session_pid} =~ ${state_number_pattern} &&
    ${session_value} =~ ${state_number_pattern} ]] \
    || [[ "${session_kind}" != "timed" && "${session_kind}" != "watch" ]] \
    || [[ "${session_flags}" != "-i" && "${session_flags}" != "-i -d" ]]; then
    return 1
  fi

  process_command="$(ps -p "${session_pid}" -o command= 2> /dev/null || true)"
  case "${process_command}" in
    "${CAFFEINATE_PROCESS_NAME}"\ * | *bash\ *lumos.sh*) ;;
    *) return 1 ;;
  esac

  now="$(date +%s)"
  if [[ "${session_kind}" == "timed" ]] && ((session_value <= now)); then
    session_expired=true
    return 1
  fi
  return 0
}

# Like `read_session`, but also repairs: removes stale state and terminates an
# expired session. Call only inside `if`.
load_session() {
  local file

  if read_session; then
    return 0
  fi
  if [[ "${session_expired}" == true ]]; then
    kill -TERM "${session_pid}" 2> /dev/null || true
  fi
  file="$(state_file)"
  if [[ -f "${file}" ]]; then
    rm -f "${file}"
  fi
  return 1
}

# Starts `caffeinate "$@"` in the background as `${CAFFEINATE_PROCESS_NAME}`,
# ignoring hangup like `nohup` does. The PID is in `$!`.
start_caffeinate() {
  (
    trap '' HUP
    exec -a "${CAFFEINATE_PROCESS_NAME}" caffeinate "$@"
  ) > /dev/null 2>&1 &
}

# Starts a new `caffeinate`, records it, then terminates the previous one.
# Callers must keep errexit active (no `||`/`if` context). `umask 077` is here,
# not in the main guard, so `command_run` leaves the caller's umask alone.
# Arguments:
#   ${1}: Kind, `timed` or `watch`.
#   ${2}: Expiry epoch (`timed`) or watched PID (`watch`).
#   ${3}: Flags, `-i` or `-i -d`.
# Returns:
#   `1` if the state cannot be written (the new `caffeinate` is terminated).
launch() {
  umask 077
  local new_kind="${1}" new_value="${2}" new_flags="${3}" previous_pid=""
  local concurrent_pid="" stale_pid new_pid now file
  now="$(date +%s)"
  file="$(state_file)"

  if [[ "${new_kind}" == "timed" ]] && ((new_value <= now)); then
    print_error "The session would end immediately."
    return 1
  fi
  if load_session; then
    previous_pid="${session_pid}"
  fi
  if ! mkdir -p "$(dirname "${file}")"; then
    print_error "Cannot create the state directory."
    return 1
  fi

  if [[ "${new_kind}" == "timed" ]]; then
    # shellcheck disable=SC2086  # Flags are intentionally split.
    start_caffeinate ${new_flags} -t $((new_value - now))
  else
    # shellcheck disable=SC2086  # Flags are intentionally split.
    start_caffeinate ${new_flags} -w "${new_value}"
  fi
  new_pid=$!

  # Also terminate the `caffeinate` of a parallel `launch` that replaced the
  # state meanwhile.
  # TODO(skarzi): A parallel `launch` writing between this read and the `mv`
  # still orphans its `caffeinate`; fix by wrapping `launch` in a `mkdir` lock.
  if read_session && [[ "${session_pid}" != "${previous_pid}" ]]; then
    concurrent_pid="${session_pid}"
  fi
  if ! printf '%s %s %s %s\n' "${new_pid}" "${new_kind}" "${new_value}" \
    "${new_flags}" > "${file}.$$" || ! mv "${file}.$$" "${file}"; then
    kill -TERM "${new_pid}" 2> /dev/null || true
    print_error "Cannot write the session state."
    return 1
  fi

  for stale_pid in "${previous_pid}" "${concurrent_pid}"; do
    if [[ -n "${stale_pid}" ]]; then
      kill -TERM "${stale_pid}" 2> /dev/null || true
    fi
  done
  return 0
}

# Dims the display and the keyboard; edit to taste. Failures are ignored so
# dimming never blocks the session. Restore manually with each `toggle`.
bedtime_start() {
  "${HOME}/dotfiles/bin/display_light.sh" set 0 || :
  "${HOME}/dotfiles/bin/keyboard_light.sh" set 0 || :
}

# Starts a timed session (`${1}` duration, optional `-d|--display`).
command_start() {
  local duration="${1:-}" seconds flags now

  if ! seconds="$(parse_duration "${duration}")"; then
    report_bad_arguments "Duration must look like 30s, 15m or 2h."
    return 1
  fi
  parse_display "${@:2}" || return 1
  flags="${display_flags}"

  now="$(date +%s)"
  launch timed $((now + seconds)) "${flags}"
  echo "Lumos started: ${duration} (${flags})"
}

# Adds or removes time on the active timed session, keeping its flags.
# `${1}` is a duration with an optional sign: `+30m` or `30m` adds, `-15m`
# removes. A zero adjustment (`0m`) is skipped with a notice. A result of zero
# or less is an error, so a typo cannot end the session.
command_adjust() {
  local argument="${1:-}" sign="+" seconds expiry flags remaining

  if [[ $# -ne 1 ]]; then
    report_bad_arguments "Adjust takes exactly one duration."
    return 1
  fi
  case "${argument:0:1}" in
    + | -)
      sign="${argument:0:1}"
      argument="${argument:1}"
      ;;
  esac
  case "${argument}" in
    0s | 0m | 0h)
      echo "Lumos unchanged: the adjustment is zero."
      return 0
      ;;
  esac
  if ! seconds="$(parse_duration "${argument}")"; then
    report_bad_arguments "Adjustment must look like +30m, -15m or 2h."
    return 1
  fi
  if ! load_session || [[ "${session_kind}" != "timed" ]]; then
    print_error "There is no active timed session to adjust."
    return 1
  fi
  if [[ "${sign}" == "-" ]]; then
    seconds=$((0 - seconds))
  fi
  expiry=$((session_value + seconds))
  flags="${session_flags}"
  remaining=$((expiry - $(date +%s)))
  if ((remaining <= 0)); then
    print_error "That would end the session. Use \`lumos stop\` instead."
    return 1
  fi

  launch timed "${expiry}" "${flags}"
  echo "Lumos adjusted: ${sign}${argument}," \
    "$(format_remaining "${remaining}") remaining (${flags})"
}

# Stays awake while the PID `${1}` runs (optional `-d|--display`).
command_watch() {
  local pid="${1:-}" flags pid_pattern='^[1-9][0-9]{0,9}$'

  if ! [[ ${pid} =~ ${pid_pattern} ]] || ! ps -p "${pid}" > /dev/null 2>&1; then
    report_bad_arguments "PID must belong to a running process."
    return 1
  fi
  parse_display "${@:2}" || return 1
  flags="${display_flags}"

  launch watch "${pid}" "${flags}"
  echo "Lumos watching PID ${pid} (${flags})"
}

# Runs `${@}` after `--` with `caffeinate`, optional `-d|--display` before it.
# Stateless; returns the command's exit status.
command_run() {
  local flags="-i" unknown_option=""

  while [[ $# -gt 0 && "${1}" != "--" ]]; do
    case "${1}" in
      -d | --display) flags="-i -d" ;;
      *) unknown_option="${unknown_option:-${1}}" ;;
    esac
    shift
  done
  if [[ $# -lt 2 ]]; then
    report_bad_arguments "Run needs a command after --."
    return 1
  fi
  if [[ -n "${unknown_option}" ]]; then
    report_bad_arguments "Unknown option: ${unknown_option}."
    return 1
  fi
  shift

  # shellcheck disable=SC2086  # Flags are intentionally split.
  caffeinate ${flags} -- "${@}" || return "$?"
}

# Stops the active session and prints the result. Brightness is untouched.
command_stop() {
  if load_session; then
    kill -TERM "${session_pid}" 2> /dev/null || true
    rm -f "$(state_file)"
    echo "Lumos stopped"
  else
    echo "Lumos inactive"
  fi
}

# Prints `1h 59m`, `12m`, `<1m` or `watch` for prompts; nothing if inactive.
print_short_status() {
  local remaining

  read_session || return 0
  remaining=$((session_value - $(date +%s)))
  if [[ "${session_kind}" == "watch" ]]; then
    echo "watch"
  elif ((remaining >= 3600)); then
    echo "$((remaining / 3600))h $((remaining % 3600 / 60))m"
  elif ((remaining >= 60)); then
    echo "$((remaining / 60))m"
  else
    echo "<1m"
  fi
}

# Shows the session; `--short` prints only the compact form.
command_status() {
  local now remaining

  if [[ "${1:-}" == "--short" && $# -eq 1 ]]; then
    print_short_status
    return 0
  elif [[ $# -gt 0 ]]; then
    report_bad_arguments "The status command takes only the --short option."
    return 1
  fi
  if ! read_session; then
    if [[ "${session_expired}" == true ]]; then
      echo "Lumos expired, but caffeinate is still running. Run \`lumos stop\`."
    else
      echo "Lumos inactive"
    fi
    return 0
  fi

  now="$(date +%s)"
  if [[ "${session_kind}" == "timed" ]]; then
    remaining="$(format_remaining $((session_value - now)))"
    echo "Lumos active: ${remaining} remaining" \
      "(PID ${session_pid}, ${session_flags})"
  else
    echo "Lumos active: watching PID ${session_value}" \
      "(PID ${session_pid}, ${session_flags})"
  fi
}

# Stays awake with `-i` for the duration `${1}` (`12h` by default), then dims
# the lights. The duration is validated first and `launch` runs before the
# dimming, so a slow dimming script never delays the session and a failed
# `launch` never dims.
command_bedtime() {
  local duration="${1-12h}" seconds now

  if [[ $# -gt 1 ]]; then
    report_bad_arguments "Bedtime takes at most one duration."
    return 1
  fi
  if ! seconds="$(parse_duration "${duration}")"; then
    report_bad_arguments "Duration must look like 30s, 15m or 2h."
    return 1
  fi
  now="$(date +%s)"
  launch timed $((now + seconds)) "-i"
  bedtime_start
  echo "Bedtime mode on: awake ${duration} (-i)"
}

# Dispatches `${1}` (default `help`) to its `command_*` function.
main() {
  local subcommand="${1:-help}"

  if [[ $# -gt 0 ]]; then
    shift
  fi
  case "${subcommand}" in
    -h | --help) subcommand="help" ;;
  esac
  case "${subcommand}" in
    start) command_start "$@" ;;
    adjust) command_adjust "$@" ;;
    watch) command_watch "$@" ;;
    run) command_run "$@" ;;
    bedtime) command_bedtime "$@" ;;
    status) command_status "$@" ;;
    stop | help)
      if [[ $# -gt 0 ]]; then
        report_bad_arguments "The ${subcommand} command takes no arguments."
        return 1
      fi
      "command_${subcommand}"
      ;;
    *)
      report_bad_arguments "Unknown command: ${subcommand}."
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  main "$@"
fi
