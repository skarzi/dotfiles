# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/bin/lumos.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/lumos/spec_helper.sh"

# The fake `caffeinate` only logs: `command_run` starts it with `-w` on the
# PID of lumos and runs the command itself as a normal foreground child.
Describe 'command_run'
  BeforeEach 'setup_test_environment'
  AfterEach 'teardown_test_environment'

  It 'runs the command and keeps its output'
    When call command_run -- echo hello world

    The status should be success
    The output should eq 'hello world'
  End

  It 'returns the status of the command'
    When call command_run -- sh -c 'exit 7'

    The status should eq 7
  End

  It 'keeps standard input and standard error of the command'
    Data 'typed input'

    When call command_run -- sh -c 'cat; echo oops >&2'

    The output should eq 'typed input'
    The stderr should eq 'oops'
  End

  It 'records a run session for the PID of lumos'
    run_and_show_state() {
      command_run -- true
      cat "$(state_file)"
    }

    When call run_and_show_state

    The status should be success
    The output should match pattern "[1-9]* run $$ -i"
  End

  It 'starts caffeinate watching the PID of lumos'
    run_and_show_caffeinate_log() {
      command_run -- true
      caffeinate_log
    }

    When call run_and_show_caffeinate_log

    The output should eq "-i -w $$"
  End

  It 'adds the display flag only before --'
    run_with_display_and_show_state_and_log() {
      command_run -d -- ls -d /
      cut -d ' ' -f 2- "$(state_file)"
      caffeinate_log
    }

    When call run_with_display_and_show_state_and_log

    The line 1 of output should eq '/'
    The line 2 of output should eq "run $$ -i -d"
    The line 3 of output should eq "-i -d -w $$"
  End

  It 'does not treat flags of the command as its own'
    run_and_show_caffeinate_log() {
      command_run -- ls -d /
      caffeinate_log
    }

    When call run_and_show_caffeinate_log

    The line 2 of output should eq "-i -w $$"
  End

  It 'refuses to replace an active session and runs nothing'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    mock_kill
    report_after_refusal() {
      if [[ -e "${LUMOS_TEST_DIRECTORY}/ran" ]]; then
        echo "command=ran"
      else
        echo "command=skipped"
      fi
      # Nothing to wait for: the refusal happens before `caffeinate` starts.
      sleep 0.2
      touch "${LUMOS_CAFFEINATE_LOG}"
      wc -l < "${LUMOS_CAFFEINATE_LOG}" | tr -d ' '
      cat "$(state_file)"
      report_state_and_kills
    }
    run_against_active_session() {
      # Under errexit the refusal ends the function, so report on exit.
      trap report_after_refusal EXIT
      command_run -- touch "${LUMOS_TEST_DIRECTORY}/ran"
    }

    When run strict run_against_active_session

    The status should eq 1
    The stderr should eq 'lumos: A session is already active. Run `lumos stop` first.'
    The line 1 of output should eq 'command=skipped'
    The line 2 of output should eq '0'
    The line 3 of output should eq "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"
    The line 4 of output should eq 'state=present'
    The line 5 of output should eq 'kills=0'
  End

  It 'replaces a stale session'
    write_stale_state dead
    run_and_show_state() {
      command_run -- true
      cut -d ' ' -f 2 "$(state_file)"
    }

    When call run_and_show_state

    The status should be success
    The output should eq 'run'
  End

  It 'does not run the command when the launch fails'
    mkdir -p "${XDG_STATE_HOME}"
    : > "${XDG_STATE_HOME}/lumos"

    When run strict command_run -- echo ran

    The status should be failure
    The stderr should include 'lumos: Cannot create the state directory.'
    The output should eq ''
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

  It 'reports a bad argument before an active session'
    spawn_fake_process
    write_session_state "${LUMOS_FAKE_PID} timed $((LUMOS_FAKE_NOW + 3600)) -i"

    When call command_run --dispaly -- true

    The status should be failure
    The stderr should include 'lumos: Unknown option: --dispaly.'
    The stderr should not include 'already active'
  End

  It 'runs an external command even when a lumos function has its name'
    When call command_run -- state_file

    The status should eq 127
    The stderr should include 'state_file'
  End

  It 'does not turn a leading dash of the command into an option of command'
    When call command_run -- -v ls

    The status should eq 127
    The stderr should include '-v'
  End

  It 'leaves the umask of the caller to the command'
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
