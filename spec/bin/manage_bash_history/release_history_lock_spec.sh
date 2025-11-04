Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe '_release_history_lock function'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'releases lock when lock was acquired'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    _acquire_history_lock "${test_histfile}" 2

    When call _release_history_lock

    The status should be success
    The variable _is_histfile_locked should be undefined
  End

  It 'returns failure when no lock was held'
    When call _release_history_lock

    The status should be failure
  End

  It 'releases lock even if file descriptor close fails'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    _acquire_history_lock "${test_histfile}" 2
    # Manually close the file descriptor to simulate it being already closed.
    eval "exec ${HISTFILE_LOCK_FD}>&-" 2>/dev/null || true

    When call _release_history_lock

    The status should be success
    The variable _is_histfile_locked should be undefined
  End

  It 'can be called multiple times safely'
    local test_histfile="${TEST_TMPDIR}/test_history"
    touch "${test_histfile}"
    _acquire_history_lock "${test_histfile}" 2
    _release_history_lock

    When call _release_history_lock

    The status should be failure
  End
End

