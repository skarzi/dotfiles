# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_status'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'reports inactive without a session'
    When call command_status

    The status should be success
    The output should eq 'Lumos inactive'
  End

  Describe 'timed session'
    Parameters
      5400 "1h 30m"
      1 "0m 1s"
      3600 "1h 0m"
      3599 "59m 59s"
      1500 "25m 0s"
    End

    It "shows $2 remaining for a timed session of $1 seconds"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + $1)) -i"

      When call command_status

      The status should be success
      The output should eq "Lumos active: $2 remaining (PID ${LUMOS_FAKE_PID}, -i)"
    End
  End

  It 'shows the watched PID without a countdown'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} watch 4242 -i -d"

    When call command_status

    The output should eq "Lumos active: watching PID 4242 (PID ${LUMOS_FAKE_PID}, -i -d)"
  End
End
