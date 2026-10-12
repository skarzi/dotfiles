# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

# `load_session` and `read_session` must only be called inside `if`, so they
# are exercised through `command_stop` (repairs) and `command_status` (reads).
Describe 'load_session'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  Describe 'stale state'
    Parameters
      dead other foreign garbage badvalue badkind badflags leadzero empty
    End

    It "stop cleans the '$1' state without killing anything"
      mock_kill
      write_stale_state "$1"
      stop_and_report_state() {
        command_stop
        report_state_and_kills
      }

      When call stop_and_report_state

      The status should be success
      The line 1 of output should eq 'Lumos inactive'
      The line 2 of output should eq 'state=absent'
      The line 3 of output should eq 'kills=0'
    End
  End

  Describe 'read-only status'
    Parameters:matrix
      command_status print_short_status
      dead other foreign garbage badvalue badkind badflags leadzero empty
    End

    It "$1 keeps the '$2' state and kills nothing"
      mock_kill
      write_stale_state "$2"
      status_and_report_state() {
        "$1" > /dev/null
        report_state_and_kills
      }

      When call status_and_report_state "$1"

      The line 1 of output should eq 'state=present'
      The line 2 of output should eq 'kills=0'
    End
  End

  Describe 'expired but still running'
    Parameters
      10
      0
    End

    It "stop terminates a running session that expired $1 seconds ago"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW - $1)) -i"
      mock_kill
      stop_and_report_kill_and_state() {
        command_stop
        kill_log
        report_state_and_kills
      }

      When call stop_and_report_kill_and_state

      The line 1 of output should eq 'Lumos inactive'
      The line 2 of output should eq "-TERM ${LUMOS_FAKE_PID} state=${LUMOS_FAKE_PID}"
      The line 3 of output should eq 'state=absent'
    End

    It "status leaves a session that expired $1 seconds ago alone"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW - $1)) -i"
      mock_kill
      status_and_report_state() {
        command_status
        report_state_and_kills
      }

      When call status_and_report_state

      The line 1 of output should eq 'Lumos expired, but caffeinate is still running. Run `lumos stop`.'
      The line 2 of output should eq 'state=present'
      The line 3 of output should eq 'kills=0'
    End
  End

  It 'accepts a state without a trailing newline'
    spawn_fake_process
    mkdir -p "${XDG_STATE_HOME}/lumos"
    printf '%s' "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i" \
      > "${XDG_STATE_HOME}/lumos/session"

    When call command_status

    The output should eq "Lumos active: 10m 0s remaining (PID ${LUMOS_FAKE_PID}, -i)"
  End

  Describe 'process before exec'
    Parameters
      "bash /Users/me/dotfiles/bin/lumos.sh start 1h"
      "/bin/bash /Users/me/dotfiles/bin/lumos.sh bedtime"
      "/opt/homebrew/bin/bash /x/lumos.sh run -- ls"
    End

    It "counts '$1' as the new session"
      spawn_fake_process
      export LUMOS_FAKE_COMMAND="$1"
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"

      When call command_status

      The output should eq "Lumos active: 10m 0s remaining (PID ${LUMOS_FAKE_PID}, -i)"
    End
  End

  Describe 'foreign caffeinate'
    Parameters
      "caffeinate -i -t 300"
      "nohup caffeinate -i -t 300"
      "/usr/bin/caffeinate -i"
    End

    It "does not accept '$1'"
      spawn_fake_process
      export LUMOS_FAKE_COMMAND="$1"
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"

      When call command_status

      The output should eq 'Lumos inactive'
    End
  End
End
