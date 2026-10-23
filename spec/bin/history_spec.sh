# shellcheck shell=bash
# shellcheck disable=SC2016  # Session lines expand inside the spawned bash.

# Drives a real interactive bash with `bin/history.sh` sourced, no mocks.
Describe 'bin/history.sh'
setup() {
  test_dir="$(mktemp -d)"
  mkdir "${test_dir}/tmp"
}
cleanup() {
  rm -rf "${test_dir}"
}
BeforeEach 'setup'
AfterEach 'cleanup'

# Seeds `${HISTFILE}` with the given lines.
seed_histfile() {
  printf '%s\n' "$@" > "${test_dir}/histfile"
}

# Runs the given lines as one interactive session, then dumps the in-memory
# history without entry numbers to "${OUT}/history". Lines can use `${OUT}`
# and `${HISTFILE}`. An optional `${PC}` becomes the pre-existing
# (not exported) `${PROMPT_COMMAND}`.
run_session() {
  local pc_line=''
  if [[ -n "${PC-}" ]]; then
    printf -v pc_line 'PROMPT_COMMAND=%q' "${PC}"
  fi
  cat > "${test_dir}/rc" << EOF
unset PROMPT_COMMAND
umask 022
${pc_line}
HISTFILE="${test_dir}/histfile"
HISTCONTROL=ignoreboth
HISTSIZE=2000
shopt -s histappend
export TMPDIR="${test_dir}/tmp"
OUT="${test_dir}"
source "${SHELLSPEC_PROJECT_ROOT}/bin/history.sh"
EOF
  {
    printf '%s\n' "$@"
    printf '%s\n' " history | sed 's/^ *[0-9]* *//' > \"\${OUT}/history\""
  } | bash --rcfile "${test_dir}/rc" -i > /dev/null 2> "${test_dir}/stderr"
}

It 'writes HISTFILE mid-session'
When call run_session ': s1' ' cp "${HISTFILE}" "${OUT}/mid"'

The contents of file "${test_dir}/mid" should eq ': s1'
End

It 'keeps a command appended by another session in the global part'
seed_histfile ': g1'

When call run_session ': s1' ' echo ": o1" >> "${HISTFILE}"' ': s2'

The contents of file "${test_dir}/history" should eq $': g1\n: o1\n: s1\n: s2'
End

It 'collapses duplicates keeping the last one'
seed_histfile ': a' ': b' ': a' ': c'

When call run_session ': s1' ': s2' ': s1'

The contents of file "${test_dir}/history" should eq $': b\n: a\n: c\n: s2\n: s1'
End

It 'moves a command retyped in the session out of the global part'
seed_histfile ': g1' ': g2'

When call run_session ': g1'

The contents of file "${test_dir}/history" should eq $': g2\n: g1'
End

It 'skips empty lines and commands with a leading space'
seed_histfile ': g1' ': s2'

When call run_session ': s1' '' ' : hidden' ': s2'

The contents of file "${test_dir}/history" should eq $': g1\n: s1\n: s2'
End

It 'preserves the exit status for the pre-existing PROMPT_COMMAND'
PC='exit_status=$?; declare -F __hist_sync > /dev/null && ((exit_status == 3)) && echo rc=3 > "${OUT}/status"'

When call run_session ' ( exit 3 )'

The contents of file "${test_dir}/status" should eq 'rc=3'
End

It 'does not export the hook to child shells'
When call run_session \
  ' bash -c "echo \${PROMPT_COMMAND-unset}" > "${OUT}/child"' \
  ' echo "${PROMPT_COMMAND}" > "${OUT}/parent"'

The contents of file "${test_dir}/child" should eq 'unset'
The contents of file "${test_dir}/parent" should include '__hist_sync'
End

It 'leaves no session files behind after exit'
When call run_session ': s1' ' ls -A "${TMPDIR}" > "${OUT}/mid"'

The contents of file "${test_dir}/mid" should include '.bash_session_history.'
The value "$(ls -A "${test_dir}/tmp")" should be blank
End

It 'errors when executed instead of sourced'
When run command bash "${SHELLSPEC_PROJECT_ROOT}/bin/history.sh"

The status should be failure
The stderr should include 'must be sourced'
End

It 'keeps the session files private'
When call run_session ': s1' \
  ' find "${TMPDIR}" -name ".bash_session_history.*" -perm 600 > "${OUT}/private"' \
  ' find "${TMPDIR}" -name ".bash_session_history.*" ! -perm 600 > "${OUT}/other"'

The value "$(grep -c . "${test_dir}/private")" should eq 2
The value "$(cat "${test_dir}/other")" should be blank
End
End
