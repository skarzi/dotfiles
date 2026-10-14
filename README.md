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

## Manual Actions

Steps `chezmoi` cannot automate. Perform them after `chezmoi init --apply`.

### macOS: grant Alacritty Full Disk Access

Required to access protected folders such as `~/Downloads` from Alacritty and
tmux. This permission **cannot** be granted through `chezmoi` or macOS
`defaults`.

1. Install Alacritty and launch it once.
2. Open `System Settings → Privacy & Security → Full Disk Access`:

  ```bash
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
   ```

1. Click `+`, select Alacritty, and enable its toggle.
2. Fully quit Alacritty (`⌘Q`) and reopen it.
3. Verify access, both directly and inside tmux:

  ```bash
  ls ~/Downloads
  ```

If access stops working despite the toggle being enabled, remove Alacritty
from the list, add it again, and relaunch it.

Existing tmux servers may also need restarting. Save your work first:
`tmux kill-server` terminates all sessions and their running processes.

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
