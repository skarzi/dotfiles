# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_start'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'starts caffeinate with -i and records the state'
    start_and_show_launch() {
      command_start 1h
      caffeinate_log
      cat "$(state_file)"
    }

    When call start_and_show_launch

    The status should be success
    The line 1 of output should eq 'Lumos started: 1h (-i)'
    The line 2 of output should eq '-i -t 3600'
    The line 3 of output should match pattern "[0-9]* timed 1791601200 -i"
  End

  Describe 'with a display flag'
    Parameters
      "30m" "-d"
      "30m" "--display"
      "-d" "30m"
      "--display" "30m"
    End

    It "adds the display flag with $1 $2"
      start_with_flag_and_show_launch() {
        command_start "$1" "$2"
        caffeinate_log
        cat "$(state_file)"
      }

      When call start_with_flag_and_show_launch "$1" "$2"

      The line 1 of output should eq 'Lumos started: 30m (-i -d)'
      The line 2 of output should eq '-i -d -t 1800'
      The line 3 of output should match pattern "[0-9]* timed 1791599400 -i -d"
    End
  End

  It 'rejects a bad duration'
    When call command_start 1h30m

    The status should be failure
    The stderr should include 'lumos: Duration must look like 30s, 15m or 2h.'
    The stderr should include 'Usage:'
  End

  It 'rejects a missing duration'
    When call command_start

    The status should be failure
    The stderr should include 'lumos: Duration must look like'
  End

  It 'rejects an unknown flag and starts nothing'
    start_with_unknown_flag_and_report_state() {
      local status=0
      command_start 1h --dispaly || status=$?
      report_state_and_kills
      return "${status}"
    }

    When call start_with_unknown_flag_and_report_state

    The status should be failure
    The stderr should include 'lumos: Unknown option: --dispaly.'
    The stderr should include 'Usage:'
    The output should include 'state=absent'
  End

  It 'drops the flags of the replaced session'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i -d"
    mock_kill

    When call command_start 1h

    The output should eq 'Lumos started: 1h (-i)'
  End

  It 'kills the replaced session only after recording the new one'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    mock_kill
    replace_session_and_show_kill_log() {
      command_start 1h > /dev/null
      kill_log
    }

    When call replace_session_and_show_kill_log

    The output should match pattern "-TERM ${LUMOS_FAKE_PID} state=[0-9]*"
    The output should not end with "state=${LUMOS_FAKE_PID}"
  End

  It 'ignores a failing kill of the old PID'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    kill() { return 1; }

    When run strict command_start 1h

    The status should be success
    The output should eq 'Lumos started: 1h (-i)'
  End
End
