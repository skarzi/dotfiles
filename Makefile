SHELL := /usr/bin/env bash
STYLUA_CMD := stylua --respect-ignores --verify

NVM_SETUP_CMD := true  # `nvm` is not used on CI by default.
ifndef CI
	NVM_SETUP_CMD := source $${NVM_DIR}/nvm.sh && nvm use
endif

# Dynamically extract Makefile stages from .PHONY declarations.
_MAKEFILE_TARGETS := $(shell grep -h '^.PHONY:' $(firstword $(MAKEFILE_LIST)) | sed 's/^.PHONY: //' | tr ' ' '\n' | sort -u)
EXTRA_ARGS = $(filter-out $(_MAKEFILE_TARGETS),$(MAKECMDGOALS))

.PHONY: install-python
install-python:
	@pip install --upgrade pip setuptools
	@pip install --requirement requirements.txt

.PHONY: install-node
install-node:
	@$(NVM_SETUP_CMD) && npm install

.PHONY: install-rust
install-rust:
	@cargo install selene stylua

.PHONY: install
install: install-python install-node install-rust

.PHONY: lint-commit-message
lint-commit-message:
	@$(NVM_SETUP_CMD) && npm run lint:commit-message

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

.PHONY: lint-shell-scripts
lint-shell-scripts:
	@find . -type f -name "*.sh" \
	| grep -v ".vim/bundle" \
	| grep -v "spec/" \
	| paste -sd ' ' - \
	| xargs shellcheck

.PHONY: lint-fix-markdown
lint-fix-markdown:
	@$(NVM_SETUP_CMD) && npm run lint:md -- $(or $(EXTRA_ARGS),**/*.md)

.PHONY: lint-fix-lua
lint-fix-lua:
	@selene $(or $(EXTRA_ARGS),nvim/)
	@$(STYLUA_CMD) --check $(or $(EXTRA_ARGS),nvim/) || ($(STYLUA_CMD) $(or $(EXTRA_ARGS),nvim/) && exit 1)

.PHONY: lint
lint: lint-yaml lint-vim lint-shell-scripts lint-fix-markdown \
	lint-github-actions lint-pre-commit-hook-config lint-fix-lua

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
