# Chezmoi Best Practices & Style Guide

<!-- TODO(skarzi): Let's move this file to GitHub agents
`.github/agents/chezmoi-agent/AGENTS.md`.
But still keep it referenced in the root `AGENTS.md` file!

References:

+ https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
+ https://ericmjl.github.io/blog/2025/10/4/how-to-teach-your-coding-agent-with-agentsmd/
+ https://www.anthropic.com/engineering/claude-code-best-practices
+ https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
+ https://www.builder.io/blog/agents-md
-->

This document establishes the standards and workflows for managing dotfiles
using `chezmoi` in this repository.

## 1. Core Philosophy

- **One Source of Truth**: The `chezmoi/` directory (the "source directory" in
  chezmoi terminology) is the definitive state. **Do not** edit configuration
  files in your home directory directly. Edit the source, then apply.
- **Idempotency**: All scripts and templates **must** be idempotent. Running
  `chezmoi apply` multiple times should result in the same stable state without
  errors or unintended side effects.
- **Declarative Configuration**: Define *what* the system should look like, not
  just the steps to get there.

## 2. Naming Conventions & Attributes

Chezmoi uses filename prefixes and suffixes to manage attributes. Strictly
adhere to these conventions to ensure consistent behavior.

### File Prefixes

- **`dot_`**: Creates a dotfile (hidden file).
  - *Source*: `dot_bashrc` $\rightarrow$ *Target*: `.bashrc`
- **`executable_`**: Sets the executable permission bit (0755).
  - *Source*: `executable_yabairc` $\rightarrow$ *Target*: `yabai` (executable)
- **`private_`**: Sets restricted permissions (0600) for sensitive files.
  - *Source*: `private_ssh_config` $\rightarrow$ *Target*: `ssh_config` (0600)
- **`exact_`**: Enforces exact state on directories (removes untracked files in
  the destination).
  - *Warning*: `exact_dir/` will delete **any** file in `~/dir` that is not in
    the source. Use with caution.

### File Suffixes

- **`.tmpl`**: Indicates the file is a Go template. It will be processed before
  being written to the destination.
  - *Source*: `dot_bash_aliases.tmpl` $\rightarrow$ *Target*: `.bash_aliases`

## 3. Templates (`.tmpl`)

### Syntax & Logic

- **Whitespace Control**: Always use `{{-` and/or `-}}` to strip surrounding
  whitespace, preventing blank lines in generated files.
  - *Good*: `{{- if eq .chezmoi.os "darwin" -}}`
- **Quoting**: Quote all string literals and variable expansions in functions.
  - *Good*: `{{- if eq .env "work" -}}`
  - *Bad*: `{{ if eq .env work }}`

### Data Access

- **Standard Data**: Use built-in variables like `.chezmoi.os`,
  `.chezmoi.arch`, and `.chezmoi.homeDir`.
- **Custom Data**: Define custom variables (e.g., `email`, `env`) in
  `.chezmoi.toml.tmpl` under the `[data]` section.
- **Conditionals**: Use templates to handle OS or environment-specific logic
  within a single file, rather than maintaining duplicates.

```bash
# dot_bash_aliases.tmpl
{{- if eq .chezmoi.os "darwin" }}
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
{{- end }}
```

## 4. Scripts (`.chezmoiscripts`)

Scripts execute during `chezmoi apply`. They are powerful but require strict
safety disciplines.

### Execution Lifecycle (Naming)

- **`run_once_`**: Runs **only** if the script content has changed (tracked by
  hash). Use for "install" tasks.
  - *Example*: `run_once_install-brew.sh`
- **`run_onchange_`**: Runs whenever the file content changes. Use for
  configuration enforcement or installing dependencies from a list.
  - *Example*: `run_onchange_install-packages.sh.tmpl`
- **`before_` / `after_`**: Modifiers to control execution order relative to
  file copying.
  - *Usage*: `run_once_before_decrypt-key.sh` runs before config files are
    placed.

### Script Best Practices

- **Bash Styleguide**: All bash scripts **must** follow the
  [Bash Styleguide](.agents/bash-styleguide.md).
- **Shebang & Safety**: Always start with `#!/usr/bin/env bash` and `set -eufo
  pipefail`.
- **Hash-Based Triggers**: To trigger a script when *another* file changes
  (e.g., re-running `brew bundle` when `Brewfile` changes), include the
  checksum of that file in a comment.

```bash
#!/usr/bin/env bash

set -eufo pipefail

# Brewfile hash:
# {{ include "dot_config/brew/Brewfile" | sha256sum }}

brew bundle install --file "{{ .chezmoi.sourceDir }}/dot_config/brew/Brewfile"
```

## 5. Configuration (`.chezmoi.toml.tmpl`)

- **Interactive Init**: Use `prompt.*` functions (e.g., `promptString`,
  `promptChoice`) to capture user intent during initialization (`chezmoi
  init`).
- **Data Section**: Store globally accessible variables in the `[data]` section.

```toml
[data]
    email = {{ promptString "email" | quote }}
    env = {{ promptChoice "env" (list "personal" "work") | quote }}
```

## 6. OS & Environment Abstraction

- **`.chezmoiignore`**: Use this file to exclude entire files or directories
  based on the target OS. This keeps the source directory clean while allowing
  repo-wide management.

```text
# .chezmoiignore
{{ if ne .chezmoi.os "darwin" }}
dot_config/karabiner
dot_config/yabai
{{ end }}
```

## 8. Encryption & Secrets

Managing sensitive data (SSH keys, tokens, work configs) requires strict
adherence to security protocols.

### Core Tools

- **Encryption**: Uses `age` (via `rage`) for file encryption.
- **Secret Management**: Uses `pass-cli` (Proton Pass) to store and retrieve
  sensitive values (like IDs or keys) during templates rendering or bootstrapping.

### Workflows

1. **Structured Secrets**:
   - Store API keys, passwords, and IDs in Proton Pass.
   - Retrieve them dynamically in templates using `pass-cli` integration
     (e.g. `protonPassJSON`).

2. **Unstructured Data**:
   - Use `chezmoi`'s built-in `age` encryption for configuration files
     (e.g. work-related bash aliases).
   - Use this for work-related configs or entire files that contain sensitive
     logic.
   - Files containing secrets should reside in `.encrypted_data/` or have
     `encrypted_` prefix.

3. **Key Management**:
   - **Never** commit unencrypted secrets or private keys to git.

## Summary Checklist

- [ ] Files managed by chezmoi are **not** edited in `~` directly.
- [ ] Templates use `{{- ... -}}` for clean whitespace control.
- [ ] Bash scripts follow the [Bash Styleguide](.agents/bash-styleguide.md).
- [ ] OS-specific files are handled via `.chezmoiignore` or template logic.
- [ ] `run_onchange_` scripts track their dependencies via `sha256sum`.
- [ ] Structured secrets are retrieved via Proton Pass integrations.
- [ ] Unstructured sensitive data is encrypted with `age`/`rage`.
