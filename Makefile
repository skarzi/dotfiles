SHELL := /usr/bin/env bash
STYLUA_CMD := stylua --respect-ignores --verify

# Dynamically extract Makefile stages from .PHONY declarations.
_MAKEFILE_TARGETS := $(shell grep -h '^.PHONY:' $(firstword $(MAKEFILE_LIST)) | sed 's/^.PHONY: //' | tr ' ' '\n' | sort -u)
EXTRA_ARGS = $(filter-out $(_MAKEFILE_TARGETS),$(MAKECMDGOALS))
GEMINI_SETTINGS_JSON_SCHEMA_URL := https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json

.DEFAULT_GOAL := help

#: Install Python dependencies.
.PHONY: install-python
install-python:
	@uv sync --locked --dev

#: Install Node dependencies.
.PHONY: install-node
install-node:
	@npm install

#: Install Rust dependencies.
.PHONY: install-rust
install-rust:
	@cargo install selene stylua $(EXTRA_ARGS)

#: Install pre-commit dependency and hook.
.PHONY: install-pre-commit
install-pre-commit:
	@uv tool install pre-commit
	@uv tool run pre-commit install

#: Install all dependencies.
.PHONY: install
install: install-python install-node install-rust

#: Lint the commit message.
.PHONY: lint-commit-message
lint-commit-message:
	@npm run lint:commit-message

#: Lint the pre-commit config.
.PHONY: lint-pre-commit-hook-config
lint-pre-commit-hook-config:
	@uv tool run pre-commit validate-config .pre-commit-config.yaml

#: Lint GitHub Actions files.
.PHONY: lint-github-actions
lint-github-actions:
	@actionlint $(EXTRA_ARGS)

#: Lint YAML files.
.PHONY: lint-yaml
lint-yaml:
	@uv run yamllint --format github .

#: Lint and fix shell scripts.
.PHONY: lint-fix-shell-scripts
lint-fix-shell-scripts:
	@_DEFAULT_FILES="$$(find . -type f -name '*.sh' | grep -Ev '(\.vim/bundle/|spec/)' | paste -sd ' ' -)" \
	&& shellcheck $(or $(EXTRA_ARGS),$${_DEFAULT_FILES}) \
	&& shfmt --write --diff $(or $(EXTRA_ARGS),$${_DEFAULT_FILES})

#: Lint and fix Markdown files.
.PHONY: lint-fix-markdown
lint-fix-markdown:
	@npm run lint:md -- $(or $(EXTRA_ARGS),"**/*.md")

#: Lint and fix Lua files.
.PHONY: lint-fix-lua
lint-fix-lua:
	@selene $(or $(EXTRA_ARGS),nvim/)
	@$(STYLUA_CMD) --check $(or $(EXTRA_ARGS),nvim/) || ($(STYLUA_CMD) $(or $(EXTRA_ARGS),nvim/) && exit 1)

#: Lint SSH config.
.PHONY: lint-ssh-config
lint-ssh-config:
	@ssh -G -F chezmoi/dot_ssh/config dummy.host > /dev/null

#: Lint Gemini CLI settings.
.PHONY: lint-gemini-settings
lint-gemini-settings:
	@uv run check-jsonschema \
		--no-cache \
		--schemafile $(GEMINI_SETTINGS_JSON_SCHEMA_URL) \
		chezmoi/dot_gemini/settings.json

#: Lint and fix the whole project.
.PHONY: lint
lint: lint-yaml lint-fix-shell-scripts lint-fix-markdown \
	lint-github-actions lint-pre-commit-hook-config lint-fix-lua \
	lint-ssh-config lint-gemini-settings

#: Test the project's binaries.
.PHONY: test-bin
test-bin:
	@shellspec $(EXTRA_ARGS)

#: Run all project tests.
.PHONY: test
test: test-bin

#: Clean up the project.
.PHONY: clean
clean:
	@rm -rf node_modules/

#: Install, lint, and test.
.PHONY: all
all: install lint test

#: Show available targets.
.PHONY: help
help:
	@awk '/^#: / { sub(/^#: /, ""); desc = desc ? desc " " $$0 : $$0; next } /^[a-zA-Z_-]+:/ && desc { sub(/:.*/, ""); printf "\033[36m%-28s\033[0m %s\n", $$0, desc; desc = "" }' $(MAKEFILE_LIST) | sort
