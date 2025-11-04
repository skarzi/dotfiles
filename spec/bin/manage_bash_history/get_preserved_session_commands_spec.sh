Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe '_get_preserved_session_commands_stdout function'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  # label | preserve_count | session_log_content_lines (csv) | expected_output_lines (csv)
  Parameters
    '#1: Basic with duplicates' 2 'cmd1,cmd2_dup,cmd3,cmd2_dup,cmd4' 'cmd2_dup,cmd4'
    '#2: Fewer than count'      3 'cmd1,cmd2'                        'cmd1,cmd2'
    '#3: Empty log'             2 ''                                 ''
    '#4: Preserve only one'     1 'cmd_a,cmd_b,cmd_c'                'cmd_c'
    '#5: Preserve all unique'   5 'cmd_a,cmd_b,cmd_c,cmd_a'          'cmd_b,cmd_c,cmd_a'
  End

  It "gets preserved session commands: case $1 (count:$2 log:${3} -> out:${4})"
    export BASH_SESSION_PRESERVE_COUNT="${2}"  # Use $2 for preserve_count

    log_lines=($(echo "$3" | tr ',' '\n'))
    for line in "${log_lines[@]}"; do
      echo "$line" >> "${SESSION_LOG_FILE_UNDER_TEST}"
    done

    When call _get_preserved_session_commands_stdout "${SESSION_LOG_FILE_UNDER_TEST}" "$BASH_SESSION_PRESERVE_COUNT"
    The status should be success

    expected_log_lines=($(echo "$4" | tr ',' '\n'))

    get_expected_output() {
      for line in "${expected_log_lines[@]}"; do
        echo "${line}"
      done
    }

    if [ ${#expected_log_lines[@]} -eq 0 ]; then
      The output should equal ""
    else
      The output should equal "$(get_expected_output)"
    fi
  End
End

