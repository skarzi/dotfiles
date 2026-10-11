# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_watch'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'watches a running PID with -w'
    spawn_fake_process
    watch_and_show_launch() {
      command_watch "${LUMOS_FAKE_PID}"
      caffeinate_log
      cat "$(state_file)"
    }

    When call watch_and_show_launch

    The status should be success
    The line 1 of output should eq "Lumos watching PID ${LUMOS_FAKE_PID} (-i)"
    The line 2 of output should eq "-i -w ${LUMOS_FAKE_PID}"
    The line 3 of output should match pattern "[0-9]* watch ${LUMOS_FAKE_PID} -i"
  End

  It 'adds the display flag'
    spawn_fake_process
    watch_with_display_and_show_caffeinate_log() {
      command_watch "${LUMOS_FAKE_PID}" -d
      caffeinate_log
    }

    When call watch_with_display_and_show_caffeinate_log

    The line 1 of output should eq "Lumos watching PID ${LUMOS_FAKE_PID} (-i -d)"
    The line 2 of output should eq "-i -d -w ${LUMOS_FAKE_PID}"
  End

  It 'rejects a dead PID'
    When call command_watch 999999

    The status should be failure
    The stderr should include 'lumos: PID must belong to a running process.'
    The stderr should include 'Usage:'
  End

  It 'rejects a non-numeric PID'
    When call command_watch abc

    The status should be failure
    The stderr should include 'lumos: PID must belong to a running process.'
  End
End
