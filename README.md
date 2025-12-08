# dotfiles

My configuration files for vim, i3wm, urxvt, bash and more.
Feel free to use them!

## Local Development

Local development requires the following tools:

+ [pyenv](https://github.com/pyenv/pyenv) - Python Version Manager
+ [nvm](https://github.com/nvm-sh/nvm) - Node Version Manager
+ [rustup](https://rustup.rs/) - Rust toolchain installer
+ [checkmake](https://github.com/checkmake/checkmake) - Makefile linter
+ [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linter
+ [actionlint](https://github.com/rhysd/actionlint) - GitHub Actions linter
+ [shellspec](https://github.com/shellspec/shellspec) - Shell script testing framework
+ [pre-commit](https://github.com/pre-commit/pre-commit) - Pre-commit hooks manager

After installing required tools, let's install all necessary dependencies
with the following command:

```bash
make install
```

### Linting

All linters run on pre-commit hook. To run them manually,
let's use the following command:

```bash
make lint
```

To run all pre-commit hooks against all files, use the following command:

```bash
pre-commit run --all-files
```

### Testing

#### Bash scripts

To run tests for bash scripts, use the following command:

```bash
make test-bin
```
