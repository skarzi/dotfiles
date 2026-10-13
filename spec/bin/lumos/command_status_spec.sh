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

  It 'shows a command run without a countdown'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} run 4242 -i -d"

    When call command_status

    The output should eq "Lumos active: running a command (PID ${LUMOS_FAKE_PID}, -i -d)"
  End

  Describe '--short'
    It 'prints nothing without a session'
      When call command_status --short

      The status should be success
      The output should eq ''
    End

    It 'exits 0 without a session under strict mode'
      When run strict command_status --short

      The status should be success
      The output should eq ''
    End

    Parameters
      7200 "2h 0m"
      5400 "1h 30m"
      3600 "1h 0m"
      3599 "59m"
      90 "1m"
      60 "1m"
      59 "<1m"
      1 "<1m"
    End

    It "prints $2 for a timed session of $1 seconds"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + $1)) -i"

      When call command_status --short

      The status should be success
      The output should eq "$2"
    End

    It 'prints w- and the watched PID for a watch session'
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} watch 4242 -i"

      When call command_status --short

      The output should eq 'w-4242'
    End

    It 'prints r- and the PID of lumos for a run session'
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} run 4242 -i"

      When call command_status --short

      The output should eq 'r-4242'
    End

    It 'prints nothing and drops the state of a dead process'
      write_stale_state dead

      When call command_status --short

      The status should be success
      The output should eq ''
    End
  End

  It 'rejects other arguments'
    When call command_status now

    The status should be failure
    The stderr should include 'lumos: The status command takes only the --short option.'
    The stderr should include 'Usage:'
  End

  It 'rejects extra arguments after --short'
    When call command_status --short now

    The status should be failure
    The stderr should include 'takes only the --short option'
  End
End
