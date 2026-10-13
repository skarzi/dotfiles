# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_adjust'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'adds time, keeps the flags and starts the new one before killing the old'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i -d"
    mock_kill
    adjust_and_show_launch_kill_and_state() {
      command_adjust 30m
      caffeinate_log
      kill_log
      cat "$(state_file)"
    }

    When call adjust_and_show_launch_kill_and_state

    The status should be success
    The line 1 of output should eq 'Lumos adjusted: +30m, 1h 30m remaining (-i -d)'
    The line 2 of output should eq '-i -d -t 5400'
    The line 3 of output should match pattern "-TERM ${LUMOS_FAKE_PID} state=[0-9]*"
    The line 3 of output should not end with "state=${LUMOS_FAKE_PID}"
    The line 4 of output should match pattern "[0-9]* timed 1791603000 -i -d"
  End

  It 'subtracts time and keeps the flags'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i -d"
    mock_kill
    adjust_and_show_launch_and_state() {
      command_adjust -15m
      caffeinate_log
      cat "$(state_file)"
    }

    When call adjust_and_show_launch_and_state

    The status should be success
    The line 1 of output should eq 'Lumos adjusted: -15m, 45m 0s remaining (-i -d)'
    The line 2 of output should eq '-i -d -t 2700'
    The line 3 of output should match pattern "[0-9]* timed 1791600300 -i -d"
  End

  Describe 'adding time'
    Parameters
      "+30m"
      "30m"
    End

    It "treats $1 as an addition and prints the sign"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
      mock_kill

      When call command_adjust "$1"

      The status should be success
      The output should eq 'Lumos adjusted: +30m, 1h 30m remaining (-i)'
    End
  End

  It 'accepts an adjustment that leaves one second'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 61)) -i"
    mock_kill

    When call command_adjust -60s

    The status should be success
    The output should eq 'Lumos adjusted: -60s, 0m 1s remaining (-i)'
  End

  Describe 'adjustment that would end the session'
    Parameters
      "-10m"
      "-11m"
    End

    It "rejects $1 and leaves the session untouched"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
      mock_kill
      adjust_and_show_state_launches_and_kills() {
        local status=0
        command_adjust "$1" || status=$?
        cat "$(state_file)"
        cat "${LUMOS_CAFFEINATE_LOG}" 2> /dev/null || true
        kill_log
        return "${status}"
      }

      When call adjust_and_show_state_launches_and_kills "$1"

      The status should be failure
      The stderr should eq 'lumos: That would end the session. Use `lumos stop` instead.'
      The lines of output should eq 1
      The line 1 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    End
  End

  Describe 'zero adjustment'
    Parameters
      "0m"
      "+0m"
      "-0m"
      "0s"
      "0h"
    End

    It "skips $1 with a notice and leaves the session untouched"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
      mock_kill
      adjust_and_show_state_launches_and_kills() {
        command_adjust "$1"
        cat "$(state_file)"
        cat "${LUMOS_CAFFEINATE_LOG}" 2> /dev/null || true
        kill_log
      }

      When call adjust_and_show_state_launches_and_kills "$1"

      The status should be success
      The lines of output should eq 2
      The line 1 of output should eq 'Lumos unchanged: the adjustment is zero.'
      The line 2 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    End

    It "skips $1 even without a session"
      When call command_adjust "$1"

      The status should be success
      The output should eq 'Lumos unchanged: the adjustment is zero.'
    End
  End

  It 'fails without a session'
    When call command_adjust 30m

    The status should be failure
    The stderr should eq 'lumos: There is no active timed session to adjust.'
  End

  Describe 'session that is not timed'
    Parameters
      watch
      run
    End

    It "fails on a $1 session and leaves it alone"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} $1 4242 -i"
      mock_kill
      adjust_untimed_session_and_report_state() {
        local status=0
        command_adjust 30m || status=$?
        report_state_and_kills
        return "${status}"
      }

      When call adjust_untimed_session_and_report_state

      The status should be failure
      The stderr should eq 'lumos: There is no active timed session to adjust.'
      The line 1 of output should eq 'state=present'
      The line 2 of output should eq 'kills=0'
    End
  End

  Describe 'invalid adjustments'
    Parameters
      "00m"
      "0"
      "--5m"
      "+-5m"
      "-1.5h"
      "-1h30m"
      "abc"
      ""
      "-"
      "+"
    End

    It "rejects '$1'"
      When call command_adjust "$1"

      The status should be failure
      The stderr should include 'lumos: Adjustment must look like +30m, -15m or 2h.'
      The stderr should include 'Usage:'
    End
  End

  It 'rejects extra arguments with a count message'
    When call command_adjust 1h -d

    The status should be failure
    The stderr should include 'lumos: Adjust takes exactly one duration.'
    The stderr should include 'Usage:'
  End
End
