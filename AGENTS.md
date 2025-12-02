# AI Agent Guide for `dotfiles`

This document provides context, architectural decisions, and operational
workflows for AI agents working on this `dotfiles` repository.

## 1. Project Context & Philosophy

- **Primary OS:** macOS.
- **Secondary OS:** Linux (Debian) - legacy support exists but macOS is the
  driver.
- **Core Philosophy:** "Design First". Automation should be robust, tested,
  and linted.
- **Current Phase:** Active migration from Vim (Vimscript) to Neovim (Lua).

## 2. Architecture & Stack

### Shell Environment

- **Shell:** Bash (assumes Bash 5.3+ features).
- **Management:** `.bashrc` sources modular files.
- **Scripts:** Located in `bin/`.
- **Testing:** `shellspec` is used for unit testing shell scripts in `spec/`.

### Editor Configuration

- **Legacy:** `.vim/` (Vimscript, Vundle). *Maintenance mode only.*
- **Modern (Active):** `nvim/` (Lua, Lazy.nvim). *Primary development target.*

### Window Management

- **macOS:** `yabai` (tiling window manager) + `skhd` (hotkeys).
- **Linux:** `i3` (legacy configs in `.i3/`).

## 3. Directory Structure Map

- `bin/`: Utility scripts added to `${PATH}`.
- `spec/`: Tests for `bin/` scripts (ShellSpec).
- `nvim/`: Neovim configuration (symlinked to `~/.config/nvim`).
- `.vim/`: Vim configuration (symlinked to `~/.vim`).
- `.tmux/`: Tmux configuration and session management.
- `.github/`: CI workflows and Dependabot config.
- `git/`: Global git configuration and ignores.
- `.agents/`: Configuration and guides for AI agents.

## 4. Operational Workflows

### Verification (Mandatory!)

Agents **must** verify **all** changes using the provided `Makefile`.

**Common Targets:**

| Goal | Command | Notes |
| :--- | :--- | :--- |
| **Run Everything** | `make all` | Run linters & tests. Use before "Finish". |
| **Run Tests** | `make test` | Runs `shellspec` tests in `spec/`. |
| **Lint All** | `make lint` | Runs all configured linters. |
| **Lint Shell** | `make lint-shell-scripts` | Uses `shellcheck`. |
| **Fix Lua** | `make lint-fix-lua` | Uses `selene` (lint) / `stylua` (format). |
| **Fix Markdown** | `make lint-fix-markdown` | Uses `markdownlint-cli2`. |
| **Lint YAML** | `make lint-yaml` | Uses `yamllint`. |

**Targeting Specific Files:**
Most lint targets accept arguments to run on specific files to save time:

```bash
make lint-fix-markdown -- AGENTS.md
make lint-shell-scripts -- bin/my_script.sh
```

### Neovim Migration Rules

Refer to `nvim/vim-to-neovim-migration-plan.md` for specific architectural decisions.

### Dependency Management

1. Install all local development dependencies listed in [`README.md`](README.md).
2. Run `make install` to set up the environment.

## 5. Style & Conventions

- **Commits:** Follow Conventional Commits
  (e.g., `feat(nvim): add lsp`, `fix(bash): correct history path`).
  Validated by `commitlint` on `commit-msg` git hook.
- **Shell:** Follow [`.agents/bash-styleguide.md`](.agents/bash-styleguide.md).
- **Lua:** Strictly `selene` and `stylua` compliant.

## 6. Specific Constraints

- **Do not** hardcode absolute paths unless necessary for system integrations.
  Use `${HOME}` or relative paths.
- **Do not** assume interactive input. Scripts should be capable of running
  non-interactively or via flags.
- **Lock Files:** Respect `package-lock.json` and other lock files.
