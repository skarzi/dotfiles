Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe 'main function (orchestration)'
  BeforeEach 'setup_test_environment' 'mock_history_command'
  AfterEach 'unmock_history_command' 'teardown_test_environment'

  Context 'first command in session, empty global HISTFILE'
    BeforeEach 'mock_main_mktemp_command'
    AfterEach 'unmock_mktemp_command'
    It 'prepares the history load file correctly'
      # _INITIAL_HISTCMD is set to 1 by the top-level setup_test_environment.
      mock_fc_command "echo first_cmd"

      When call main

      The status should be success

      get_expected_output() {
        printf '%s\n' "-a"
        printf '%s\n' "-c"
        printf '%s\n' "-r ${_mock_history_load_file_path}"
      }

      The file "${_history_command_spy_log_path}" should be exist
      The contents of file "${_history_command_spy_log_path}" should equal "$(get_expected_output)"

      # Check the captured file content (captured by history spy before deletion)
      The file "${_captured_history_load_file_path}" should be exist
      The contents of file "${_captured_history_load_file_path}" should equal "echo first_cmd"
      The contents of file "${SESSION_LOG_FILE_UNDER_TEST}" should equal "echo first_cmd"
      The variable g_custom_hist_last_seen_histcmd should equal "$_INITIAL_HISTCMD"
    End
  End

  Context 'new command, existing session & global HISTFILE, no overlaps'
    BeforeEach 'mock_main_mktemp_command'
    AfterEach 'unmock_mktemp_command'
    It 'orders commands: session first, then unique global'
      g_custom_hist_last_seen_histcmd=2
      export _INITIAL_HISTCMD=3
      mock_fc_command "cmd_session_C"
      echo "cmd_session_A" > "${SESSION_LOG_FILE_UNDER_TEST}"
      echo "cmd_session_B" >> "${SESSION_LOG_FILE_UNDER_TEST}"
      echo "cmd_global_X" > "${HISTFILE}"
      echo "cmd_global_Y" >> "${HISTFILE}"

      get_expected_output() {
        printf '%s\n' "cmd_session_A"
        printf '%s\n' "cmd_session_B"
        printf '%s\n' "cmd_session_C"
        printf '%s\n' "cmd_global_X"
        printf '%s\n' "cmd_global_Y"
      }

      When call main

      The status should be success
      # Check the captured file content (captured by history spy before deletion)
      The file "${_captured_history_load_file_path}" should be exist
      The contents of file "${_captured_history_load_file_path}" should equal "$(get_expected_output)"
      The variable g_custom_hist_last_seen_histcmd should equal "$_INITIAL_HISTCMD"
    End
  End

  Context 'main function mktemp failure for load file'
    BeforeEach 'mock_mktemp_command_fail bash_history_load.XXXXXX'
    AfterEach 'unmock_mktemp_command'
    It 'exits with error if temp_hist_for_loading mktemp fails'
      mock_fc_command "any_cmd"

      When call main
      The status should equal 1
      The error should include "Error: Main: Failed to create temporary file for loading history."
    End
  End

   Context 'main function mktemp failure for patterns file'
    BeforeEach 'mock_mktemp_command_fail bash_history_patterns.XXXXXX'
    AfterEach 'unmock_mktemp_command'
    It 'exits with error if patterns_file mktemp fails'
      # Need some session commands to trigger patterns file creation
      mock_fc_command "cmd_session_A"

      When call main
      The status should equal 1
      The error should include "Error: Main: Failed to create temporary patterns file."
      The path "${TEST_TMPDIR}/mock_history_load_file" should not be exist
    End
  End
End
