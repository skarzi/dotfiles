# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_bedtime'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  # Runs `command_bedtime "$@"`, then shows the `caffeinate` log, the bedtime
  # log and the state file.
  bedtime_and_show_launch() {
    command_bedtime "$@"
    caffeinate_log
    cat "${LUMOS_TEST_DIRECTORY}/bedtime.log"
    cat "$(state_file)"
  }

  # Runs `command_bedtime "$@"`, then shows the bedtime log and the state
  # report.
  bedtime_and_report_state() {
    local status=0
    command_bedtime "$@" || status=$?
    cat "${LUMOS_TEST_DIRECTORY}/bedtime.log" 2> /dev/null || true
    report_state_and_kills
    return "${status}"
  }

  It 'keeps awake for 12h without the display flag, then calls bedtime_start'
    log_bedtime_start

    When call bedtime_and_show_launch

    The status should be success
    The line 1 of output should eq 'Bedtime mode on: awake 12h (-i)'
    The line 2 of output should eq '-i -t 43200'
    The line 3 of output should eq 'bedtime_start called after launch'
    The line 4 of output should match pattern '[0-9]* timed 1791640800 -i'
  End

  Describe 'with a duration'
    Parameters
      8h 28800
      90m 5400
      30s 30
    End

    It "keeps awake for the given $1"
      log_bedtime_start

      When call bedtime_and_show_launch "$1"

      The status should be success
      The line 1 of output should eq "Bedtime mode on: awake $1 (-i)"
      The line 2 of output should eq "-i -t $2"
      The line 3 of output should eq 'bedtime_start called after launch'
    End
  End

  Describe 'with a bad duration'
    Parameters
      "0m"
      "5d"
      "abc"
      "-5m"
      "1h30m"
      ""
    End

    It "rejects '$1' before dimming"
      log_bedtime_start

      When call bedtime_and_report_state "$1"

      The status should be failure
      The stderr should include 'lumos: Duration must look like 30s, 15m or 2h.'
      The stderr should include 'Usage:'
      The output should not include 'bedtime_start called'
      The output should include 'state=absent'
    End
  End

  It 'rejects two durations before dimming'
    log_bedtime_start

    When call bedtime_and_report_state 8h 9h

    The status should be failure
    The stderr should include 'lumos: Bedtime takes at most one duration.'
    The stderr should include 'Usage:'
    The output should not include 'bedtime_start called'
    The output should include 'state=absent'
  End

  It 'does not dim when launch fails'
    log_bedtime_start
    mkdir -p "${XDG_STATE_HOME}"
    : > "${XDG_STATE_HOME}/lumos"

    When run strict command_bedtime

    The status should be failure
    The stderr should include 'lumos: Cannot create the state directory.'
    The path "${LUMOS_TEST_DIRECTORY}/bedtime.log" should not be exist
  End

  It 'keeps going when the dimming scripts fail, after the session started'
    export LUMOS_TEST_DIRECTORY
    mkdir -p "${LUMOS_TEST_DIRECTORY}/home/dotfiles/bin"
    for dimmer in display_light.sh keyboard_light.sh; do
      cat > "${LUMOS_TEST_DIRECTORY}/home/dotfiles/bin/${dimmer}" << 'FAKE'
#!/bin/sh
state=absent
if [ -e "${XDG_STATE_HOME}/lumos/session" ]; then state=present; fi
echo "$(basename "$0") $* state=${state}" >> "${LUMOS_TEST_DIRECTORY}/dimming.log"
exit 7
FAKE
      chmod +x "${LUMOS_TEST_DIRECTORY}/home/dotfiles/bin/${dimmer}"
    done
    run_lumos_script_bedtime_with_failing_dimmers() {
      HOME="${LUMOS_TEST_DIRECTORY}/home" "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh" bedtime 1h
    }

    When run run_lumos_script_bedtime_with_failing_dimmers

    The status should be success
    The output should include 'Bedtime mode on: awake 1h (-i)'
    The path "${XDG_STATE_HOME}/lumos/session" should be file
    The contents of file "${LUMOS_TEST_DIRECTORY}/dimming.log" should eq "display_light.sh set 0 state=present
keyboard_light.sh set 0 state=present"
  End
End
