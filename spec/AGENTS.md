# Tests

ShellSpec tests live in `spec/`. `make test` runs them.

## Layout

- `spec/bin/<script>/` tests `bin/<script>.sh`. Lumos uses one file per
  function (`command_start_spec.sh`) and a shared `spec_helper.sh`. A smaller
  script can stay in one file (`tmux_setup_sessions_spec.sh`).
- `spec/chezmoi/` mirrors the path under `chezmoi/`.
- `spec/spec_helper.sh` is the ShellSpec entry required by `.shellspec`. It
  does not hold example helpers.
- A subject `spec_helper.sh` holds functions only. `Describe`, `It`, `When`,
  and `The` stay in `*_spec.sh`.

## AAA

Every example is Arrange, Act, Assert, in that order. Put a blank line between
the phases. Do not label them in the example.

1. **Arrange.** Shared setup goes in `BeforeEach`, cleanup in `AfterEach`.
   Inputs and the function `When` calls go in the example.
2. **Act.** Exactly one `When call` or `When run`.
3. **Assert.** Only `The` lines.

`When call` runs in the current shell, so functions and mocks stay visible.
`When run` runs in a subshell. `When run strict` keeps `set -e` on.

ShellSpec checks the status, stdout, and stderr of that one command. When an
assertion needs a log or a state file, the Act function prints them. That
print stays in the Act.

## What to test

Test a branch. A fixed word list with no branch does not need a spec.

## Isolation

- Keep files under `${SHELLSPEC_TMPBASE}` or `mktemp`, and remove them in
  `AfterEach`.
- Do not touch real devices, brightness, or the user's shell session. Lumos
  fakes `caffeinate`, `ps`, and `date`, and replaces `bedtime_start` with `:`.
- `history.sh` is the exception. It is sourced into a real interactive bash,
  because `history` only affects that shell.

## Parameters

Same assertion, different inputs: put a `Parameters` block in the `Describe`
and use `"${1}"` inside the `It`.

## Style

- Start a spec with `# shellcheck shell=bash`.
- Include the subject from `${SHELLSPEC_PROJECT_ROOT}`.
- Do not run `shfmt` on spec files. ShellSpec syntax is not shell syntax, and
  `shfmt` strips the indentation. `make lint-fix-shell-scripts` already skips
  `spec/`.

```bash
It 'offers the display flag after a duration'
  COMP_WORDS=(lumos start 1h "")
  COMP_CWORD=3

  When call show_completions _complete_lumos

  The line 1 of output should eq "-d"
  The line 2 of output should eq "--display"
End
```
