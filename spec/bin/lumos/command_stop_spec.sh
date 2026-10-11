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
End
