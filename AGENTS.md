# AI Agent Guide for `dotfiles`

This document provides context, architectural decisions, and operational
workflows for AI agents working on this `dotfiles` repository.

## 1. Project Context & Philosophy

+ **Primary OS:** macOS.
+ **Secondary OS:** Linux (Debian) - legacy support exists but macOS is the
  driver.
+ **Core Philosophy:** "Design First". Automation should be robust, tested,
  and linted.
+ **Current Phase:** Active migration from Vim (Vimscript) to Neovim (Lua).

## 2. Architecture & Stack

### Shell Environment

+ **Shell:** Bash (assumes Bash 5.3+ features).
+ **Management:** `.bashrc` sources modular files.
+ **Scripts:** Located in `bin/`.
+ **Testing:** `shellspec` is used for unit testing shell scripts in `spec/`.

### Editor Configuration

+ **Legacy:** `.vim/` (Vimscript, Vundle). *Maintenance mode only.*
+ **Modern (Active):** `nvim/` (Lua, Lazy.nvim). *Primary development target.*

### Window Management

+ **macOS:** `yabai` (tiling window manager) + `skhd` (hotkeys).
+ **Linux:** `i3` (legacy configs in `.i3/`).

## 3. Directory Structure Map

+ `bin/`: Utility scripts added to `${PATH}`.
+ `spec/`: Tests for `bin/` scripts (ShellSpec).
+ `nvim/`: Neovim configuration (symlinked to `~/.config/nvim`).
+ `.vim/`: Vim configuration (symlinked to `~/.vim`).
+ `.tmux/`: Tmux configuration and session management.
+ `.github/`: CI workflows and Dependabot config.
+ `git/`: Global git configuration and ignores.

## 4. Operational Workflows

### Verification (Mandatory!)

Agents **must** verify **all** changes using the provided `Makefile`.

+ **Run All Linters:** `make lint` (Aggregates all linters)
+ Run Single Linter: run proper `Makefile` stage, e.g. to run `Markdown` linter
  on a single file: `make lint-fix-md -- AGENTS.md`
+ **Run Unit Tests:** `make test` (ShellSpec)
+ **Run All Checks:** `make all` (Linting + Tests).
  Optionally to run all linters the `pre-commit` command could be used:

```bash
pre-commit run --all-files
```

### Neovim Migration Rules

Refer to `nvim/vim-to-neovim-migration-plan.md` for specific architectural decisions.

### Dependency Management

1) Install all local development dependencies listed in @README.md.
2) Run `make install` to set up the environment.

## 5. Style & Conventions

+ **Commits:** Follow Conventional Commits
  (e.g., `feat(nvim): add lsp`, `fix(bash): correct history path`).
  Validated by `commitlint` on `commit-msg` git hook.
+ **Shell:** follow @.agents/bash-styleguide.md.
+ **Lua:** strictly `selene` and `stylua` compliant.

## 6. Specific Constraints

+ **Do not** hardcode absolute paths unless necessary for system integrations.
  Use `${HOME}` or relative paths.
+ **Do not** assume interactive input. Scripts should be capable of running
  non-interactively or via flags.
+ **Lock Files:** Respect `package-lock.json` and other lock files.
