# shellcheck shell=bash
Include "${SHELLSPEC_PROJECT_ROOT}/chezmoi/dot_bash_completion.d/completions/lumos.bash"

# Prints one completion per line. `COMP_WORDS` and `COMP_CWORD` are the caller's.
show_completions() {
  "$@"
  if ((${#COMPREPLY[@]} > 0)); then
    printf '%s\n' "${COMPREPLY[@]}"
  fi
}

Describe 'lumos completion'
  It 'lists subcommands'
    COMP_WORDS=(lumos "")
    COMP_CWORD=1

    When call show_completions _complete_lumos

    The line 1 of output should eq "start"
    The output should include "bedtime"
    The output should include "--help"
  End

  It 'offers the display flag after a duration'
    COMP_WORDS=(lumos start 1h "")
    COMP_CWORD=3

    When call show_completions _complete_lumos

    The line 1 of output should eq "-d"
    The line 2 of output should eq "--display"
  End

  It 'offers the display flag before a duration once a dash is typed'
    COMP_WORDS=(lumos start -)
    COMP_CWORD=2

    When call show_completions _complete_lumos

    The line 1 of output should eq "-d"
    The line 2 of output should eq "--display"
  End

  It 'does not offer the display flag twice'
    COMP_WORDS=(lumos start -d "")
    COMP_CWORD=3

    When call show_completions _complete_lumos

    The output should eq ""
  End

  It 'offers -- and the display flag to run'
    COMP_WORDS=(lumos run "")
    COMP_CWORD=2

    When call show_completions _complete_lumos

    The line 1 of output should eq "-d"
    The line 2 of output should eq "--display"
    The line 3 of output should eq "--"
  End

  It 'offers --short to status'
    COMP_WORDS=(lumos status "")
    COMP_CWORD=2

    When call show_completions _complete_lumos

    The output should eq "--short"
  End
End
