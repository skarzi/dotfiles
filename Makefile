SHELL := /usr/bin/env bash

.PHONY: install
install:
	@pip install --upgrade pip setuptools
	@pip install --requirement requirements.txt
	@npm install

.PHONY: lint_yaml
lint_yaml:
	@yamllint --format github .

.PHONY: lint_vim
lint_vim:
	@vint .vim/.vimrc .vim/*.vim .vim/vundles/ .vim/settings/

.PHONY: lint_shell_scripts
lint_shell_scripts:
	@find . -type f -name "*.sh" \
	| grep -v ".vim/bundle" \
	| grep -v "spec/" \
	| paste -sd ' ' - \
	| xargs shellcheck

# TODO(skarzi): Migrate to ``markdownlint-cli2``.
.PHONY: lint_markdown
lint_markdown:
	@npx markdownlint .

.PHONY: lint
lint: lint_yaml lint_vim lint_shell_scripts lint_markdown

.PHONY: test_bin
test_bin:
	@shellspec

.PHONY: test
test: test_bin

.PHONY: clean
clean:
	@rm -rf node_modules/

.PHONY: all
all: install test
