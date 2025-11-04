Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe 'cleanup_session_history function'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'removes session-specific log file'
    touch "${SESSION_LOG_FILE_UNDER_TEST}"

    When call cleanup_session_history
    The status should be success
    The path "${SESSION_LOG_FILE_UNDER_TEST}" should not be exist
  End

  It 'removes mktemp pattern files'
    # Setup: Create dummy files matching the patterns.
    touch "${TMPDIR}/bash_history_load.abc"
    touch "${TMPDIR}/bash_history_patterns.xyz"
    touch "${TMPDIR}/bash_unique_hist.123"

    When call cleanup_session_history
    The status should be success
    The path "${TMPDIR}/bash_history_load.abc" should not be exist
    The path "${TMPDIR}/bash_history_patterns.xyz" should not be exist
    The path "${TMPDIR}/bash_unique_hist.123" should not be exist
  End

  It 'does not remove unrelated files'
    # Setup: Create an unrelated file.
    touch "${TMPDIR}/some_other_file_that_should_not_be_deleted"

    When call cleanup_session_history
    The status should be success
    The path "${TMPDIR}/some_other_file_that_should_not_be_deleted" should be exist
  End

  It 'runs successfully if files do not exist'
    # No specific file creation needed here, as we are testing the case
    # where the target files are already absent.
    # setup_test_environment ensures a clean TMPDIR and that
    # SESSION_LOG_FILE_UNDER_TEST is initially empty (or created then emptied).
    # We can additionally ensure they are not present if setup_test_environment
    # were to create them.
    rm -f "${SESSION_LOG_FILE_UNDER_TEST}"
    rm -f "${TMPDIR}/bash_history_load."*
    rm -f "${TMPDIR}/bash_history_patterns."*
    rm -f "${TMPDIR}/bash_unique_hist."*


    When call cleanup_session_history
    The status should be success
  End
End
