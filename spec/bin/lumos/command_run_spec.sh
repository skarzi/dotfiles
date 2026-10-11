# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'command_run'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'forwards the command through caffeinate'
    run_and_show_caffeinate_log_with_command() {
      command_run -- echo hello world
      caffeinate_log
    }

    When call run_and_show_caffeinate_log_with_command

    The status should be success
    The line 1 of output should eq 'hello world'
    The line 2 of output should eq '-i -- echo hello world'
  End

  It 'writes no state'
    run_and_report_state() {
      command_run -- true
      report_state_and_kills
    }

    When call run_and_report_state

    The line 1 of output should eq 'state=absent'
  End

  It 'returns the status of the wrapped command'
    When call command_run -- sh -c 'exit 7'

    The status should eq 7
  End

  It 'adds the display flag only before --'
    run_with_display_and_show_caffeinate_log() {
      command_run -d -- ls -d /
      caffeinate_log
    }

    When call run_with_display_and_show_caffeinate_log

    The line 1 of output should eq '/'
    The line 2 of output should eq '-i -d -- ls -d /'
  End

  It 'does not treat flags of the wrapped command as its own'
    run_and_show_caffeinate_log() {
      command_run -- ls -d /
      caffeinate_log
    }

    When call run_and_show_caffeinate_log

    The line 2 of output should eq '-i -- ls -d /'
  End

  It 'rejects a missing --'
    When call command_run true

    The status should be failure
    The stderr should include 'lumos: Run needs a command after --.'
    The stderr should include 'Usage:'
  End

  It 'rejects an empty command'
    When call command_run --

    The status should be failure
    The stderr should include 'lumos: Run needs a command after --.'
  End

  It 'rejects an unknown flag'
    When call command_run --dispaly -- true

    The status should be failure
    The stderr should include 'lumos: Unknown option: --dispaly.'
  End

  It 'leaves the umask of the caller to the wrapped command'
    umask 022
    run_lumos_script_printing_umask() {
      "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh" run -- sh -c umask
    }

    When run run_lumos_script_printing_umask

    The status should be success
    The output should eq '0022'
  End

  It 'does not glob flags before --'
    When call command_run '*' -- true

    The status should be failure
    The stderr should include 'lumos: Unknown option: *.'
  End
End
