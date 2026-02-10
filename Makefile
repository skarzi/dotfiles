SHELL := /usr/bin/env bash
STYLUA_CMD := stylua --respect-ignores --verify

# Dynamically extract Makefile stages from .PHONY declarations.
_MAKEFILE_TARGETS := $(shell grep -h '^.PHONY:' $(firstword $(MAKEFILE_LIST)) | sed 's/^.PHONY: //' | tr ' ' '\n' | sort -u)
EXTRA_ARGS = $(filter-out $(_MAKEFILE_TARGETS),$(MAKECMDGOALS))
GEMINI_SETTINGS_JSON_SCHEMA_URL := https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json

.PHONY: install-python
install-python:
	@uv sync

.PHONY: install-node
install-node:
	@npm install

.PHONY: install-rust
install-rust:
	@cargo install selene stylua $(EXTRA_ARGS)

.PHONY: install
install: install-python install-node install-rust

.PHONY: lint-commit-message
lint-commit-message:
	@npm run lint:commit-message

.PHONY: lint-pre-commit-hook-config
lint-pre-commit-hook-config:
	@pre-commit validate-config .pre-commit-config.yaml

.PHONY: lint-github-actions
lint-github-actions:
	@actionlint $(EXTRA_ARGS)

.PHONY: lint-yaml
lint-yaml:
	@yamllint --format github .

.PHONY: lint-vim
lint-vim:
	@vint .vim/.vimrc .vim/*.vim .vim/vundles/ .vim/settings/

.PHONY: lint-fix-shell-scripts
lint-fix-shell-scripts:
	@_DEFAULT_FILES="$$(find . -type f -name '*.sh' | grep -Ev '(\.vim/bundle/|spec/)' | paste -sd ' ' -)" \
	&& shellcheck $(or $(EXTRA_ARGS),$${_DEFAULT_FILES}) \
	&& shfmt --write --diff $(or $(EXTRA_ARGS),$${_DEFAULT_FILES})

.PHONY: lint-fix-markdown
lint-fix-markdown:
	@npm run lint:md -- $(or $(EXTRA_ARGS),"**/*.md")

.PHONY: lint-fix-lua
lint-fix-lua:
	@selene $(or $(EXTRA_ARGS),nvim/)
	@$(STYLUA_CMD) --check $(or $(EXTRA_ARGS),nvim/) || ($(STYLUA_CMD) $(or $(EXTRA_ARGS),nvim/) && exit 1)

.PHONY: lint-ssh-config
lint-ssh-config:
	@ssh -G -F chezmoi/dot_ssh/config dummy.host > /dev/null

.PHONY: lint-gemini-settings
lint-gemini-settings:
	@check-jsonschema \
		--schemafile $(GEMINI_SETTINGS_JSON_SCHEMA_URL) \
		chezmoi/dot_gemini/settings.json

.PHONY: lint
lint: lint-yaml lint-vim lint-fix-shell-scripts lint-fix-markdown \
	lint-github-actions lint-pre-commit-hook-config lint-fix-lua \
	lint-ssh-config lint-gemini-settings

.PHONY: test-bin
test-bin:
	@shellspec $(EXTRA_ARGS)

.PHONY: test
test: test-bin

.PHONY: clean
clean:
	@rm -rf node_modules/

.PHONY: all
all: install lint test
