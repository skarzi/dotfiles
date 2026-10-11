# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'parse_duration'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  Describe 'valid durations'
    Parameters
      "30s" "30"
      "15m" "900"
      "90m" "5400"
      "2h" "7200"
      "12h" "43200"
      "999999s" "999999"
    End

    It "converts $1 to $2 seconds"
      When call parse_duration "$1"

      The status should be success
      The output should eq "$2"
    End
  End

  Describe 'invalid durations'
    Parameters
      "0m"
      "-5m"
      "1.5h"
      "1h30m"
      "5d"
      "05m"
      ""
      "m"
      "1000000s"
    End

    It "rejects '$1'"
      When call parse_duration "$1"

      The status should be failure
      The output should eq ""
    End
  End
End
