# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_stop'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'reports inactive without a session and kills nothing'
    mock_kill
    stop_without_session_and_report_kills() {
      command_stop
      report_state_and_kills
    }

    When call stop_without_session_and_report_kills

    The line 1 of output should eq 'Lumos inactive'
    The line 3 of output should eq 'kills=0'
  End

  It 'kills only the stored PID and clears the state'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    mock_kill
    stop_and_report_kill_and_state() {
      command_stop
      kill_log
      report_state_and_kills
    }

    When call stop_and_report_kill_and_state

    The line 1 of output should eq 'Lumos stopped'
    The line 2 of output should eq "-TERM ${LUMOS_FAKE_PID} state=${LUMOS_FAKE_PID}"
    The line 3 of output should eq 'state=absent'
    The line 4 of output should eq 'kills=1'
  End

  It 'ignores a failing kill'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    kill() { return 1; }
    stop_with_failing_kill_and_report_state() {
      command_stop
      report_state_and_kills
    }

    When run strict stop_with_failing_kill_and_report_state

    The status should be success
    The line 1 of output should eq 'Lumos stopped'
    The line 2 of output should eq 'state=absent'
  End

  It 'removes the lock afterwards'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    mock_kill
    stop_and_report_lock() {
      command_stop
      report_lock
    }

    When call stop_and_report_lock

    The line 1 of output should eq 'Lumos stopped'
    The line 2 of output should eq 'lock=absent'
  End

  It 'waits for a held lock and reads the session inside it'
    spawn_fake_process
    mock_kill
    hold_lock_then_write_session
    stop_after_wait_and_show_kill_log() {
      command_stop
      kill_log
      report_lock
    }

    When call stop_after_wait_and_show_kill_log

    The line 1 of output should eq 'Lumos stopped'
    The line 2 of output should match pattern "-TERM ${LUMOS_FAKE_PID} state=*"
    The line 3 of output should eq 'lock=absent'
  End

  It 'does not create the state directory when there is none'
    stop_and_report_state_directory() {
      command_stop
      if [[ -e "${XDG_STATE_HOME}/lumos" ]]; then
        echo "directory=present"
      else
        echo "directory=absent"
      fi
    }

    When call stop_and_report_state_directory

    The status should be success
    The line 1 of output should eq 'Lumos inactive'
    The line 2 of output should eq 'directory=absent'
  End

  It 'steals a stale lock once the attempts run out'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    mkdir "${XDG_STATE_HOME}/lumos/session.lock"
    export LUMOS_LOCK_ATTEMPTS=2
    mock_kill
    stop_over_stale_lock_and_report() {
      command_stop
      report_state_and_kills
      report_lock
    }

    When call stop_over_stale_lock_and_report

    The line 1 of output should eq 'Lumos stopped'
    The line 2 of output should eq 'state=absent'
    The line 3 of output should eq 'kills=1'
    The line 4 of output should eq 'lock=absent'
  End
End
