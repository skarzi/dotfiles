Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe '_log_new_command function'
  BeforeEach 'setup_test_environment' 'mock_fc_command'
  AfterEach 'unmock_fc_command' 'teardown_test_environment'

  # label | last_seen_histcmd | current_histcmd | fc_output (mocked) | expected_log_content | expected_new_last_seen_histcmd
  Parameters
    '#1: New command'                 0  1  "echo 'test'"                  "echo 'test'" 1
    '#2: No new histcmd'              1  1  "echo 'ignored test'"          ""            1
    '#3: Empty fc output'             1  2  ""                             ""            2
    '#4: fc output is ''main'''       1  2  "main"                         ""            2
    '#5: fc output is PROMPT_COMMAND' 1  2  "fake_prompt_command_for_test" ""            2
  End

  It "handles command logging: $1 (seen_histcmd:$2 current_histcmd:$3 fc_out:'${4}' -> log:'${5}', new_seen_histcmd:${6})"
    g_custom_hist_last_seen_histcmd=$2
    export _INITIAL_HISTCMD=$3
    _mock_fc_command_output="$4"
    # SESSION_LOG_FILE_UNDER_TEST is set in setup_test_environment and used by _log_new_command.

    When call _log_new_command "${SESSION_LOG_FILE_UNDER_TEST}"
    The status should be success  # Function itself doesn't return error status for these logic cases.
    The contents of file "${SESSION_LOG_FILE_UNDER_TEST}" should equal "$5"  # Use $5 for expected_log_content.
    The variable g_custom_hist_last_seen_histcmd should equal "$6"  # Use $6 for expected_new_last_seen_histcmd.
  End
End
