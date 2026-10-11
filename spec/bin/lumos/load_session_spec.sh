# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

# `load_session` must only be called inside `if`, so it is exercised through
# `command_status` and `command_stop`.
Describe 'load_session'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  Describe 'stale state'
    Parameters:matrix
      command_status command_stop
      dead other garbage badvalue badkind badflags leadzero empty
    End

    It "$1 cleans the '$2' state without killing anything"
      mock_kill
      write_stale_state "$2"
      run_command_and_report_state() {
        "$1"
        report_state_and_kills
      }

      When call run_command_and_report_state "$1"

      The status should be success
      The line 1 of output should eq 'Lumos inactive'
      The line 2 of output should eq 'state=absent'
      The line 3 of output should eq 'kills=0'
    End
  End

  Describe 'expired but still running'
    Parameters
      10
      0
    End

    It "terminates a running session that expired $1 seconds ago"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW - $1)) -i"
      mock_kill
      status_and_report_kill_and_state() {
        command_status
        kill_log
        report_state_and_kills
      }

      When call status_and_report_kill_and_state

      The line 1 of output should eq 'Lumos inactive'
      The line 2 of output should eq "-TERM ${LUMOS_FAKE_PID} state=${LUMOS_FAKE_PID}"
      The line 3 of output should eq 'state=absent'
    End
  End

  It 'accepts a state without a trailing newline and a nohup command'
    spawn_fake_process
    export LUMOS_FAKE_COMMAND="nohup caffeinate -i -t 60"
    mkdir -p "${XDG_STATE_HOME}/lumos"
    printf '%s' "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i" \
      > "${XDG_STATE_HOME}/lumos/session"

    When call command_status

    The output should eq "Lumos active: 10m 0s remaining (PID ${LUMOS_FAKE_PID}, -i)"
  End
End
