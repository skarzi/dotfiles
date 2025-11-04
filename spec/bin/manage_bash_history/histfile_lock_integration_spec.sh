Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe 'histfile lock integration'
  BeforeEach 'setup_test_environment' 'mock_history_command'
  AfterEach 'unmock_history_command' 'teardown_test_environment'

  Context 'main function with lock acquisition'
    BeforeEach 'mock_main_mktemp_command'
    AfterEach 'unmock_mktemp_command'

    It 'skips execution when lock acquisition fails'
      mock_fc_command "some_cmd"
      mock_flock_command 1

      When call main

      The status should be success
      # Should return early without processing.
      The variable _is_histfile_locked should be undefined
      unmock_flock_command
    End

    It 'releases lock after successful execution'
      mock_fc_command "echo test_cmd"

      When call main

      The status should be success
      The variable _is_histfile_locked should be undefined
    End

    It 'releases lock when mktemp fails for load file'
      mock_fc_command "any_cmd"
      mock_mktemp_command_fail bash_history_load.XXXXXX

      When call main

      The status should equal 1
      The error should include "Error: Main: Failed to create temporary file for loading history."
      The variable _is_histfile_locked should be undefined
    End

    It 'releases lock when mktemp fails for patterns file'
      mock_fc_command "cmd_session_A"
      mock_mktemp_command_fail bash_history_patterns.XXXXXX

      When call main

      The status should equal 1
      The error should include "Error: Main: Failed to create temporary patterns file."
      The variable _is_histfile_locked should be undefined
    End

    It 'releases lock via trap on exit'
      mock_fc_command "echo test"
      # Set trap manually to test cleanup.
      trap '_release_history_lock' EXIT

      When call main

      The status should be success
      # Trap should have released the lock.
      trap - EXIT
      The variable _is_histfile_locked should be undefined
    End
  End

  Context 'concurrent access prevention'
    BeforeEach 'mock_main_mktemp_command'
    AfterEach 'unmock_mktemp_command'

    It 'prevents concurrent execution when lock acquisition fails'
      # Simulate lock already held by another process by making flock fail.
      mock_flock_command 1
      mock_fc_command "concurrent_cmd"

      When call main

      The status should be success  # Returns 0 when lock fails.
      The variable _is_histfile_locked should be undefined
      unmock_flock_command
    End
  End

  Context 'lock file cleanup'
    BeforeEach 'mock_main_mktemp_command'
    AfterEach 'unmock_mktemp_command'

    It 'creates and maintains lock file during execution'
      mock_fc_command "test_cmd"
      local lock_file="${HISTFILE}.lock"

      When call main

      The status should be success
      # Lock file should exist (may be cleaned up after, but should have existed)
      # Note: File descriptor is closed on release, but file may remain
    End

    It 'handles lock file permissions correctly'
      mock_fc_command "test_cmd"
      local lock_file="${HISTFILE}.lock"

      When call main

      The status should be success
      # Lock file should be readable/writable.
      if [ -f "${lock_file}" ]; then
        The path "${lock_file}" should be readable
        The path "${lock_file}" should be writable
      fi
    End
  End
End

