# dotfiles

My configuration files for Neovim, Bash, Yabai, and more.
Managed with [chezmoi](https://www.chezmoi.io/).

## Fresh Installation

To set up this repository on a new machine (macOS), run the bootstrap script
to install prerequisites (`brew`, `chezmoi`, `rage`, `pass-cli`), populate
`rage` keys and avoid circular dependencies:

```bash
# Clone the repository (if not already done).
git clone https://github.com/skarzi/dotfiles.git ~/dotfiles

# Run the bootstrap script.
./bin/bootstrap_chezmoi.sh

# Apply dotfiles.
chezmoi init --apply --verbose --source ~/dotfiles/chezmoi
```

## Local Development

Local development requires [mise](https://mise.jdx.dev/).

Install all tools and dependencies:

```bash
make install
```

### Linting

All linters run via pre-commit hooks. To run them manually:

```bash
make lint-fix
```

To run all pre-commit hooks against all files:

```bash
pre-commit run --all-files
```

### Testing

#### Bash scripts

To run tests for bash scripts:

```bash
make test-bin
```
