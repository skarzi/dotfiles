# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'main'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  Describe 'help'
    It 'prints help without arguments'
      When call main

      The status should be success
      The line 1 of output should start with 'Usage: lumos'
    End

    Parameters
      help
      -h
      --help
    End

    It "prints help for $1"
      When call main "$1"

      The status should be success
      The line 1 of output should start with 'Usage: lumos'
    End
  End

  Describe 'extra arguments'
    Parameters
      stop
      help
    End

    It "rejects extra arguments for $1"
      When call main "$1" now

      The status should be failure
      The stderr should include "lumos: The $1 command takes no arguments."
      The stderr should include 'Usage:'
    End
  End

  Describe 'status'
    It 'routes status --short to the compact status'
      When call main status --short

      The status should be success
      The output should eq ''
    End

    It 'rejects other arguments for status'
      When call main status now

      The status should be failure
      The stderr should include 'lumos: The status command takes only the --short option.'
      The stderr should include 'Usage:'
    End
  End

  Describe 'unknown command'
    It 'rejects an unknown command with usage on STDERR'
      When call main nope

      The status should be failure
      The stderr should include 'lumos: Unknown command: nope.'
      The stderr should include 'Usage:'
    End
  End
End
