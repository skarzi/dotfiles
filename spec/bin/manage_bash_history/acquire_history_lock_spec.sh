Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe '_acquire_history_lock function'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'successfully acquires lock when flock is available'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be success
    The variable _is_histfile_locked should equal 1
    The path "${test_histfile}.lock" should be exist
  End

  It 'creates lock file if it does not exist'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be success
    The path "${test_histfile}.lock" should be exist
  End

  It 'uses existing lock file if it already exists'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    touch "${test_histfile}.lock"

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be success
    The variable _is_histfile_locked should equal 1
  End

  It 'handles timeout parameter correctly'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"

    When call _acquire_history_lock "${test_histfile}" 0

    The status should be success
    The variable _is_histfile_locked should equal 1
  End

  It 'falls back when flock is not available'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    mock_flock_unavailable

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be success
    The variable _is_histfile_locked should equal 1
    unmock_command
  End

  It 'fails when lock file cannot be created'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    # Make directory read-only to prevent lock file creation.
    chmod 555 "${TEST_TMPDIR}"

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be failure
    chmod 755 "${TEST_TMPDIR}"  # Restore permissions.
  End

  It 'fails when flock times out'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    mock_flock_command 1

    When call _acquire_history_lock "${test_histfile}" 1

    The status should be failure
    The variable _is_histfile_locked should be undefined
    unmock_flock_command
  End

  It 'fails when flock fails'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    mock_flock_command 1

    When call _acquire_history_lock "${test_histfile}" 2

    The status should be failure
    The variable _is_histfile_locked should be undefined
    unmock_flock_command
  End

  It 'uses default timeout when timeout parameter is not provided'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"

    When call _acquire_history_lock "${test_histfile}"

    The status should be success
    The variable _is_histfile_locked should equal 1
  End
End
