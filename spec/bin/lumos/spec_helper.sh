# shellcheck shell=bash
# Plain helper functions only: ShellSpec keywords cannot live in this file.
# Tests never start a real `caffeinate`: `caffeinate`, `ps` and `date` are fakes
# that are first in `${PATH}`, and `kill` is mocked per example with a shell
# function.

# Per-example setup: isolated state directory, fakes in `${PATH}`, safe
# `bedtime_start`.
setup_test_environment() {
  LUMOS_TEST_DIRECTORY="${SHELLSPEC_TMPBASE}/lumos_${SHELLSPEC_SPEC_NO}_${SHELLSPEC_EXAMPLE_NO}"
  mkdir -p "${LUMOS_TEST_DIRECTORY}"
  if [[ -z "${LUMOS_ORIGINAL_PATH:-}" ]]; then
    LUMOS_ORIGINAL_PATH="${PATH}"
  fi

  export XDG_STATE_HOME="${LUMOS_TEST_DIRECTORY}/state"
  export LUMOS_FAKE_PID=""
  export LUMOS_FAKE_NOW=1791597600
  export LUMOS_CAFFEINATE_LOG="${LUMOS_TEST_DIRECTORY}/caffeinate.log"
  export LUMOS_KILL_LOG="${LUMOS_TEST_DIRECTORY}/kill.log"
  unset LUMOS_FAKE_COMMAND
  umask 022

  # Fakes are written once per spec file (macOS scans fresh scripts on first
  # exec, which is slow). They only read exported `LUMOS_*` variables.
  LUMOS_FAKE_EXECUTABLES_DIRECTORY="${SHELLSPEC_TMPBASE}/lumos_bin_${SHELLSPEC_SPEC_NO}"
  if [[ ! -x "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/date" ]]; then
    write_fake_executables
  fi
  PATH="${LUMOS_FAKE_EXECUTABLES_DIRECTORY}:${LUMOS_ORIGINAL_PATH}"

  # Safety net: never dim the real display or keyboard from a spec.
  bedtime_start() { :; }
}

# Writes the `caffeinate`, `ps` and `date` fakes into
# `${LUMOS_FAKE_EXECUTABLES_DIRECTORY}`.
write_fake_executables() {
  mkdir -p "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}"
  # Logs its arguments; with `--` it runs the wrapped command like `caffeinate`
  # does.
  cat > "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/caffeinate" << 'FAKE'
#!/bin/sh
echo "$*" >> "${LUMOS_CAFFEINATE_LOG}"
for argument in "$@"; do
  if [ "${argument}" = "--" ]; then
    while [ "$1" != "--" ]; do shift; done
    shift
    exec "$@"
  fi
done
exit 0
FAKE
  # Only the fake PID is alive; anything else behaves like a dead PID.
  cat > "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/ps" << 'FAKE'
#!/bin/sh
if [ "$1" = "-p" ]; then
  if [ -n "$2" ] && [ "$2" = "${LUMOS_FAKE_PID}" ]; then
    if [ "$3" = "-o" ]; then echo "${LUMOS_FAKE_COMMAND:-caffeinate -i -t 60}"; fi
    exit 0
  fi
  exit 1
fi
exec /bin/ps "$@"
FAKE
  cat > "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/date" << 'FAKE'
#!/bin/sh
if [ "$1" = "+%s" ]; then echo "${LUMOS_FAKE_NOW}"; exit 0; fi
exec /bin/date "$@"
FAKE
  chmod +x "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/caffeinate" "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/ps" \
    "${LUMOS_FAKE_EXECUTABLES_DIRECTORY}/date"
}

# Per-example teardown: stops the fake process, drops mocks, restores `${PATH}`.
teardown_test_environment() {
  if [[ -n "${LUMOS_FAKE_PID:-}" ]]; then
    # `command` bypasses the `kill` function mock.
    command kill "${LUMOS_FAKE_PID}" 2> /dev/null || true
    wait "${LUMOS_FAKE_PID}" 2> /dev/null || true
  fi
  unset -f kill
  PATH="${LUMOS_ORIGINAL_PATH}"
  rm -rf "${LUMOS_TEST_DIRECTORY}"
}

# Spawns a real harmless `sleep` that the fake `ps` reports as `caffeinate`.
spawn_fake_process() {
  sleep 300 > /dev/null 2>&1 < /dev/null &
  LUMOS_FAKE_PID=$!
  export LUMOS_FAKE_PID
}

# Writes the session state file verbatim (`${1}` is the whole content).
write_session_state() {
  mkdir -p "${XDG_STATE_HOME}/lumos"
  printf '%s\n' "${1}" > "${XDG_STATE_HOME}/lumos/session"
}

# Replaces `bedtime_start` with a logger that records whether the session
# state already existed, so a call and its order are observable.
log_bedtime_start() {
  bedtime_start() {
    local order="before launch"
    if [[ -e "${XDG_STATE_HOME}/lumos/session" ]]; then
      order="after launch"
    fi
    echo "bedtime_start called ${order}" >> "${LUMOS_TEST_DIRECTORY}/bedtime.log"
  }
}

# Replaces `kill` with a logger: `<arguments> state=<PID in state file>`.
mock_kill() {
  kill() {
    local state_pid=""
    if [[ -f "${XDG_STATE_HOME}/lumos/session" ]]; then
      read -r state_pid _ < "${XDG_STATE_HOME}/lumos/session" || true
    fi
    echo "$* state=${state_pid}" >> "${LUMOS_KILL_LOG}"
  }
}

# Prints the `caffeinate` log once it has `${1:-1}` lines (max 20 x 0.05s).
caffeinate_log() {
  local want="${1:-1}" tries=0
  touch "${LUMOS_CAFFEINATE_LOG}"
  while ((tries < 20)) && (($(wc -l < "${LUMOS_CAFFEINATE_LOG}") < want)); do
    sleep 0.05
    tries=$((tries + 1))
  done
  cat "${LUMOS_CAFFEINATE_LOG}" 2> /dev/null || true
}

# Prints the kill log (nothing if `kill` was never called).
kill_log() {
  cat "${LUMOS_KILL_LOG}" 2> /dev/null || true
}

# Prints `state=present|absent` and `kills=<count>`.
report_state_and_kills() {
  if [[ -e "${XDG_STATE_HOME}/lumos/session" ]]; then
    echo "state=present"
  else
    echo "state=absent"
  fi
  echo "kills=$(kill_log | wc -l | tr -d ' ')"
}

# Writes a stale/malformed state for the case named `${1}`.
write_stale_state() {
  local future=$((LUMOS_FAKE_NOW + 3600))
  case "${1}" in
    dead) write_session_state "999999 timed ${future} -i" ;;
    other)
      spawn_fake_process
      export LUMOS_FAKE_COMMAND="nvim caffeinate.md"
      write_session_state "${LUMOS_FAKE_PID} timed ${future} -i"
      ;;
    garbage) write_session_state "garbage" ;;
    badvalue) write_session_state "12 timed abc -i" ;;
    badkind) write_session_state "12 other 5 -i" ;;
    badflags) write_session_state "12 timed 5 -x" ;;
    leadzero)
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed 08 -i"
      ;;
    empty)
      mkdir -p "${XDG_STATE_HOME}/lumos"
      : > "${XDG_STATE_HOME}/lumos/session"
      ;;
  esac
}

# Runs `"$@"` in a subshell with real strict mode. `errexit` is ignored under
# `When call` (even in a subshell), so tests of "does not abort" must use
# `When run strict <function>`.
strict() {
  (
    set -euo pipefail
    "$@"
  )
}
