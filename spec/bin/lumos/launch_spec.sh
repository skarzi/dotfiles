# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'launch'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'keeps the state private (directory 700, file 600) even with umask 022'
    umask 022
    launch_and_show_permissions() {
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      ls -ld "${XDG_STATE_HOME}/lumos" "$(state_file)" | cut -c1-10
    }

    When call launch_and_show_permissions

    The status should be success
    The line 1 of output should eq 'drwx------'
    The line 2 of output should eq '-rw-------'
  End

  Describe 'timed session that ends immediately'
    Parameters
      0
      5
    End

    It "refuses an expiry $1 seconds before now and touches nothing"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
      mock_kill
      launch_and_show_state_launches_and_kills() {
        local status=0
        launch timed $((LUMOS_FAKE_NOW - $1)) "-i" || status=$?
        cat "$(state_file)"
        cat "${LUMOS_CAFFEINATE_LOG}" 2> /dev/null || true
        kill_log
        return "${status}"
      }

      When call launch_and_show_state_launches_and_kills "$1"

      The status should be failure
      The stderr should eq 'lumos: The session would end immediately.'
      The lines of output should eq 1
      The line 1 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    End
  End

  It 'removes the lock after a successful launch'
    launch_and_report_lock() {
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      report_lock
    }

    When call launch_and_report_lock

    The status should be success
    The output should eq 'lock=absent'
  End

  It 'fails when the state directory cannot be created and leaves no lock'
    mkdir -p "${XDG_STATE_HOME}"
    : > "${XDG_STATE_HOME}/lumos"
    launch_failing_and_report_lock() {
      local status=0
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i" || status=$?
      report_lock
      return "${status}"
    }

    When call launch_failing_and_report_lock

    The status should be failure
    The stderr should include 'lumos: Cannot create the state directory.'
    The output should eq 'lock=absent'
  End

  It 'terminates the new caffeinate when the state cannot be written'
    mkdir -p "${XDG_STATE_HOME}/lumos"
    chmod 500 "${XDG_STATE_HOME}/lumos"
    export LUMOS_LOCK_ATTEMPTS=1
    mock_kill
    launch_with_unwritable_state_and_show_kill_log() {
      local status=0
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i" || status=$?
      kill_log
      report_lock
      return "${status}"
    }

    When call launch_with_unwritable_state_and_show_kill_log

    The status should be failure
    The stderr should include 'lumos: Cannot write the session state.'
    The line 1 of output should match pattern '-TERM [1-9]* state=*'
    The line 2 of output should eq 'lock=absent'
  End

  It 'releases the lock when the write fails after the lock was taken'
    # A directory in the way of the temporary file makes the write fail while
    # the lock was taken.
    mkdir -p "${XDG_STATE_HOME}/lumos/session.$$"
    mock_kill
    launch_with_blocked_write_and_show_kill_log() {
      local status=0
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i" || status=$?
      kill_log
      report_lock
      return "${status}"
    }

    When call launch_with_blocked_write_and_show_kill_log

    The status should be failure
    The stderr should include 'lumos: Cannot write the session state.'
    The line 1 of output should match pattern '-TERM [1-9]* state=*'
    The line 2 of output should eq 'lock=absent'
  End

  It 'waits for a held lock and reads the previous session inside it'
    spawn_fake_process
    mock_kill
    hold_lock_then_write_session
    launch_after_wait_and_show_kill_log() {
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      kill_log
      report_lock
    }

    When call launch_after_wait_and_show_kill_log

    The status should be success
    The line 1 of output should match pattern "-TERM ${LUMOS_FAKE_PID} state=*"
    The line 2 of output should eq 'lock=absent'
  End

  Describe 'invalid attempts'
    Parameters
      abc
      "1+"
      ""
      08
    End

    It "falls back to the default attempts for '$1'"
      spawn_fake_process
      mock_kill
      hold_lock_then_write_session
      export LUMOS_LOCK_ATTEMPTS="$1"
      launch_after_wait_and_show_kill_log() {
        launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
        kill_log
      }

      When call launch_after_wait_and_show_kill_log

      The status should be success
      The output should match pattern "-TERM ${LUMOS_FAKE_PID} state=*"
      The stderr should eq ''
    End
  End

  It 'steals a stale lock once the attempts run out and holds it while launching'
    mkdir -p "${XDG_STATE_HOME}/lumos/session.lock"
    export LUMOS_LOCK_ATTEMPTS=2
    launch_over_stale_lock_and_report() {
      # Records the lock at the moment `caffeinate` is started.
      start_caffeinate() {
        report_lock > "${LUMOS_TEST_DIRECTORY}/lock_while_launching" &
      }
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      wait
      report_state_and_kills
      report_lock
      cat "${LUMOS_TEST_DIRECTORY}/lock_while_launching"
    }

    When run strict launch_over_stale_lock_and_report

    The status should be success
    The line 1 of output should eq 'state=present'
    The line 3 of output should eq 'lock=absent'
    The line 4 of output should eq 'lock=present'
  End

  It 'refuses a run while a session is active and releases the lock'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    mock_kill
    refuse_run_and_report() {
      local status=0
      launch run 4242 "-i" || status=$?
      cat "$(state_file)"
      report_state_and_kills
      report_lock
      return "${status}"
    }

    When call refuse_run_and_report

    The status should be failure
    The stderr should eq 'lumos: A session is already active. Run `lumos stop` first.'
    The line 1 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    The line 3 of output should eq 'kills=0'
    The line 4 of output should eq 'lock=absent'
  End
End
