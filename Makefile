SHELL := /usr/bin/env bash

NVM_SETUP_CMD := true  # `nvm` is not used on CI by default.
ifndef CI
	NVM_SETUP_CMD := source $${NVM_DIR}/nvm.sh && nvm use
endif

.PHONY: install-python
install-python:
	@pip install --upgrade pip setuptools
	@pip install --requirement requirements.txt

.PHONY: install-node
install-node:
	@$(NVM_SETUP_CMD) && npm install

.PHONY: install
install: install-python install-node

.PHONY: lint-commit-message
lint-commit-message:
	@$(NVM_SETUP_CMD) && npm run lint:commit-message

.PHONY: lint-pre-commit-hook-config
lint-pre-commit-hook-config:
	@pre-commit validate-config .pre-commit-config.yaml

.PHONY: lint-github-actions
lint-github-actions:
	@actionlint

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
	@$(NVM_SETUP_CMD) && npm run lint:md -- $(filter-out $@,$(MAKECMDGOALS))

.PHONY: lint
lint: lint-yaml lint-vim lint-shell-scripts lint-fix-markdown \
	lint-github-actions lint-pre-commit-hook-config

.PHONY: test-bin
test-bin:
	@shellspec

.PHONY: test
test: test-bin

.PHONY: clean
clean:
	@rm -rf node_modules/

.PHONY: all
all: install lint test

# Prevent make from treating passed filenames as targets.
%:
	@:
