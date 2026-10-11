# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

Describe 'launch'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'keeps the state private (directory 700, file 600) even with umask 022'
    umask 022
    launch_and_show_permissions() {
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      ls -ld "${XDG_STATE_HOME}/lumos" "$(state_file)" | cut -c1-10
    }

    When call launch_and_show_permissions

    The status should be success
    The line 1 of output should eq 'drwx------'
    The line 2 of output should eq '-rw-------'
  End

  Describe 'timed session that ends immediately'
    Parameters
      0
      5
    End

    It "refuses an expiry $1 seconds before now and touches nothing"
      spawn_fake_process
      write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
      mock_kill
      launch_and_show_state_launches_and_kills() {
        local status=0
        launch timed $((LUMOS_FAKE_NOW - $1)) "-i" || status=$?
        cat "$(state_file)"
        cat "${LUMOS_CAFFEINATE_LOG}" 2> /dev/null || true
        kill_log
        return "${status}"
      }

      When call launch_and_show_state_launches_and_kills "$1"

      The status should be failure
      The stderr should eq 'lumos: The session would end immediately.'
      The lines of output should eq 1
      The line 1 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i"
    End
  End

  It 'fails when the state directory cannot be created'
    mkdir -p "${XDG_STATE_HOME}"
    : > "${XDG_STATE_HOME}/lumos"

    When call launch timed $((LUMOS_FAKE_NOW + 60)) "-i"

    The status should be failure
    The stderr should include 'lumos: Cannot create the state directory.'
  End

  It 'terminates the new caffeinate when the state cannot be written'
    mkdir -p "${XDG_STATE_HOME}/lumos"
    chmod 500 "${XDG_STATE_HOME}/lumos"
    mock_kill
    launch_with_unwritable_state_and_show_kill_log() {
      local status=0
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i" || status=$?
      kill_log
      return "${status}"
    }

    When call launch_with_unwritable_state_and_show_kill_log

    The status should be failure
    The stderr should include 'lumos: Cannot write the session state.'
    The output should match pattern '-TERM [1-9]* state=*'
  End

  It 'terminates the caffeinate of a parallel launch that replaced the state'
    spawn_fake_process
    mock_kill
    launch_replaced_by_parallel_launch_and_show_kills() {
      # Simulates the parallel `launch` writing its state after our first read.
      # shellcheck disable=SC2329  # Invoked by `launch`.
      mkdir() {
        command mkdir "$@"
        printf '%s\n' "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 600)) -i" \
          > "${XDG_STATE_HOME}/lumos/session"
      }
      launch timed $((LUMOS_FAKE_NOW + 60)) "-i"
      unset -f mkdir
      kill_log
    }

    When call launch_replaced_by_parallel_launch_and_show_kills

    The status should be success
    The lines of output should eq 1
    The output should match pattern "-TERM ${LUMOS_FAKE_PID} state=*"
    The output should not include "state=${LUMOS_FAKE_PID}"
  End
End
