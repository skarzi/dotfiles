setup_test_environment() {
  TEST_TMPDIR="${SHELLSPEC_TMPBASE}/test_history_tmp_${SHELLSPEC_SPEC_NO}"
  mkdir -p "${TEST_TMPDIR}"
  export TMPDIR="${TEST_TMPDIR}"
  export BASHPID="spec_$$_${SHELLSPEC_EXAMPLE_NO}"

  # Assuming main script allows BASH_SESSION_PRESERVE_COUNT to be overridden
  # by setting it in the environment before the script's 'readonly' declaration,
  # or by modifying the script to check an override variable.
  export BASH_SESSION_PRESERVE_COUNT=3

  export HISTFILE="${TEST_TMPDIR}/.test_global_bash_history"
  >"${HISTFILE}"  # Ensure HISTFILE is empty initially.

  # Define session log file path (used by the script).
  # This variable is for convenience in tests; the script calculates it internally.
  SESSION_LOG_FILE_UNDER_TEST="${TMPDIR}/.bash_session_history_${BASHPID}"
  >"${SESSION_LOG_FILE_UNDER_TEST}"  # Ensure session log is empty initially.

  # Reset script-specific global state variables.
  # The main script (manage_bash_history.sh) declares 'g_custom_hist_last_seen_histcmd'
  # globally using 'declare -gi'. We can directly reset it here.
  g_custom_hist_last_seen_histcmd=0

  export _INITIAL_HISTCMD=1
  export PROMPT_COMMAND="fake_prompt_command_for_test"
  
  # Path to captured history load file (captured by history spy before deletion)
  _captured_history_load_file_path="${TEST_TMPDIR}/captured_history_load_file"
}


teardown_test_environment() {
  if [ -d "${TEST_TMPDIR:-}" ]; then
    rm -rf "${TEST_TMPDIR}"
  fi
  unset TMPDIR BASHPID HISTFILE BASH_SESSION_PRESERVE_COUNT PROMPT_COMMAND
  unset g_custom_hist_last_seen_histcmd _INITIAL_HISTCMD SESSION_LOG_FILE_UNDER_TEST
  unset _mock_fc_command_output
  unset _mock_history_load_file_path _mock_patterns_file_path
  unset _mock_helper_unique_history_path
  unset _captured_history_load_file_path
  unset _mock_flock_exit_status
  unset _is_histfile_locked
}


# Mock `fc -ln -1`.
mock_fc_command() {
  _mock_fc_command_output="${1:-}"

  fc () {
    if [ "${1:-}" = "-ln" ] && [ "${2:-}" = "-1" ]; then
      echo "${_mock_fc_command_output:-}"
    else
      command fc "$@"
    fi
  }
}


unmock_fc_command() {
  unset -f mock_fc_command
}


# Mock `mktemp` for files created directly by `main` function.
mock_main_mktemp_command() {
  _mock_history_load_file_path="${TEST_TMPDIR}/mock_history_load_file"
  _mock_patterns_file_path="${TEST_TMPDIR}/mock_patterns_file"

  mktemp() {
    _template_prefix=$(echo "$1" | sed "s/\.XXXXXX//")
    case "${_template_prefix}" in
      "bash_history_load") echo "${_mock_history_load_file_path}" ;;
      "bash_history_patterns") echo "${_mock_patterns_file_path}" ;;
      *) command mktemp "$@" --tmpdir="${TEST_TMPDIR}" ;;
    esac
  }
}


# Mock `mktemp` for `_get_filtered_global_commands_stdout` helper's internal use.
mock_helper_unique_hist_mktemp_command() {
  _mock_helper_unique_history_path="${TEST_TMPDIR}/mock_helper_unique_history"
  mktemp() {
    _template_prefix=$(echo "$1" | sed "s/\.XXXXXX//")
    if [ "${_template_prefix}" = "bash_unique_hist" ]; then
      echo "${_mock_helper_unique_history_path}"
    else
      command mktemp "$@" --tmpdir="${TEST_TMPDIR}"
    fi
  }
}


# Mock `mktemp` to fail specifically for the "bash_unique_hist" template.
mock_mktemp_command_fail() {
  _template="${1:-bash_history_patterns.XXXXXX}"

  mktemp() {
    if [ "$1" = "${_template}" ]; then
      echo "" && return 1
    else
      # Allow the load file mktemp to succeed
      command mktemp "$@"
    fi
  }
}


unmock_mktemp_command() {
    unset -f mktemp
}


# Mock (spy) `history` builtin command.
mock_history_command() {
  _history_command_spy_log_path="${TEST_TMPDIR}/history_command_spy.log"

  history() {
    # Use printf "%s\n" "$*" to reliably log all arguments as a single line.
    printf "%s\n" "$*" >> "${_history_command_spy_log_path}"
    
    # If this is a history -r command and we're tracking a load file, capture its contents
    if [ "$1" = "-r" ] && [ -n "${2:-}" ] && [ -n "${_mock_history_load_file_path:-}" ] && [ "$2" = "${_mock_history_load_file_path}" ]; then
      if [ -f "${_mock_history_load_file_path}" ] && [ -n "${_captured_history_load_file_path:-}" ]; then
        cp "${_mock_history_load_file_path}" "${_captured_history_load_file_path}"
      fi
    fi
    
    # Execute the original `history` command to maintain its real behavior.
    command history "$@"
  }
}


unmock_history_command() {
  unset -f history
}

# Mock `flock` command to simulate lock acquisition scenarios.
# Arguments:
#   $1: Exit status code (0 for success, non-zero for failure). Default: 0
mock_flock_command() {
  _mock_flock_exit_status="${1:-0}"
  
  flock() {
    if [[ "${_mock_flock_exit_status}" -eq 0 ]]; then
      command flock "$@" 2>/dev/null || return 0
    else
      return "${_mock_flock_exit_status}"
    fi
  }
}


unmock_flock_command() {
  unset -f flock
  unset _mock_flock_exit_status
}


# Mock `command -v flock` to return failure (simulating flock not available).
mock_flock_unavailable() {
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "flock" ]; then
      return 1
    fi
    command "$@"
  }
}


unmock_command() {
  unset -f command
}
