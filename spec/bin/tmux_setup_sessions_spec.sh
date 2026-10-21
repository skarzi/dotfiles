# shellcheck shell=bash

Describe 'bin/tmux_setup_sessions.sh'
setup() {
  test_dir="$(mktemp -d)"
  workspaces="${test_dir}/workspaces"
  bash_executable="$(command -v bash)"
  mkdir -p "${workspaces}/nested"
  cat > "${test_dir}/tmuxp" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
  chmod +x "${test_dir}/tmuxp"
}

cleanup() {
  rm -rf "${test_dir}"
}

# Point the script at a missing `tmuxp`, `tmux`, or `yq`.
# `script_path` is passed to `env` so the spec shell keeps `rm` and `bash`.
setup_missing_cli() {
  local missing_cli="${1}"
  local bin_dir="${test_dir}/bin"

  mkdir -p "${bin_dir}"
  script_path="${PATH}"
  export TMUXP="${test_dir}/tmuxp"
  case "${missing_cli}" in
    tmuxp)
      export TMUXP="${test_dir}/missing-tmuxp"
      ;;
    tmux)
      ln -s "$(command -v yq)" "${bin_dir}/yq"
      script_path="${bin_dir}"
      ;;
    yq)
      ln -s "$(command -v tmux)" "${bin_dir}/tmux"
      script_path="${bin_dir}"
      ;;
    *)
      printf 'unknown cli: %s\n' "${missing_cli}" >&2
      return 1
      ;;
  esac
}
BeforeEach 'setup'
AfterEach 'cleanup'

It 'loads only workspaces marked x-should-auto-load true'
printf 'x-should-auto-load: true\n' > "${workspaces}/ready.yaml"
printf 'x-should-auto-load: "true"\n' > "${workspaces}/nested/quoted.yml"
cat > "${workspaces}/nested/data.json" << 'EOF'
{
  "x-should-auto-load": true
}
EOF
printf 'x-should-auto-load: false\n' > "${workspaces}/skip.yaml"
printf 'session_name: plain\n' > "${workspaces}/unset.yaml"
printf 'windows:\n  - x-should-auto-load: true\n' \
  > "${workspaces}/nested-key.yaml"
printf 'not a workspace\n' > "${workspaces}/notes.txt"
printf 'x-should-auto-load: true\n' > "${workspaces}/secret.yaml.age"
export TMUXP="${test_dir}/tmuxp"

When run command bash \
  "${SHELLSPEC_PROJECT_ROOT}/bin/tmux_setup_sessions.sh" \
  "${workspaces}"

The status should be success
The output should include "${workspaces}/ready.yaml"
The output should include "${workspaces}/nested/quoted.yml"
The output should include "${workspaces}/nested/data.json"
The output should not include "${workspaces}/skip.yaml"
The output should not include "${workspaces}/unset.yaml"
The output should not include "${workspaces}/nested-key.yaml"
The output should not include "secret.yaml.age"
The stderr should include '`x-should-auto-load` is false'
The stderr should include '`x-should-auto-load` is unset'
End

It 'fails when no workspace sets x-should-auto-load true'
printf 'x-should-auto-load: false\n' > "${workspaces}/skip.yaml"
export TMUXP="${test_dir}/tmuxp"

When run command bash \
  "${SHELLSPEC_PROJECT_ROOT}/bin/tmux_setup_sessions.sh" \
  "${workspaces}"

The status should be failure
The output should eq ''
The stderr should include '`x-should-auto-load` is false'
End

It 'fails when the workspaces directory does not exist'
export TMUXP="${test_dir}/tmuxp"

When run command bash \
  "${SHELLSPEC_PROJECT_ROOT}/bin/tmux_setup_sessions.sh" \
  "${test_dir}/no-such-dir"

The status should be failure
The stderr should include 'no such directory'
End

Parameters
tmuxp "tmuxp is not executable"
tmux "tmux is not installed."
yq "yq is not installed."
End
It "fails when $1 is missing"
setup_missing_cli "$1"

When run command env \
  PATH="${script_path}" \
  TMUXP="${TMUXP}" \
  "${bash_executable}" \
  "${SHELLSPEC_PROJECT_ROOT}/bin/tmux_setup_sessions.sh" \
  "${workspaces}"

The status should be failure
The output should eq ''
The stderr should include "$2"
End
End
