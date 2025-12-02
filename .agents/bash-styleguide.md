# Bash Best Practices Summary

<!-- TODO(skarzi): Let's move this file to GitHub agents
`.github/agents/bash-agent/AGENTS.md`.
But still keep it referenced in the root `AGENTS.md` file!

References:

+ https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
+ https://ericmjl.github.io/blog/2025/10/4/how-to-teach-your-coding-agent-with-agentsmd/
+ https://www.anthropic.com/engineering/claude-code-best-practices
+ https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
+ https://www.builder.io/blog/agents-md
-->

**Note:** This guide follows the
[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
When writing bash code, refer to the official style guide for comprehensive
guidelines and best practices.

## 1. Shellcheck Compliance

### Shell Declaration

- **Always declare the shell**: Add `# shellcheck shell=bash` at the top of bash
  scripts
- **Why**: Ensures shellcheck knows the target shell and provides accurate linting

### Source Directives

- **Use `# shellcheck source=/dev/null`** for files that cannot be followed:
  - System files that may not be accessible
  - Variable paths (e.g., `${GVM_DIR}/scripts/gvm`)
  - Wildcard patterns (e.g., `.bash_completion.d/*`)
  - External files that may not exist
- **Why**: Documents why shellcheck cannot follow the source, rather than
  silently ignoring errors

```bash
# shellcheck source=/dev/null  # Variable path, may not be accessible
source "${GVM_DIR}/scripts/gvm"
```

## 2. Modern Bash Syntax

### Use `[[ ]]` Instead of `[ ]`

- **Always prefer `[[ ]]`** over `[ ]` for conditional tests
- **Why**:
  - Better performance (built-in, not external command)
  - Safer (no word splitting or pathname expansion)
  - More features (pattern matching, regex, string comparison operators)
  - Better error handling

```bash
# Good
if [[ -f "${file}" ]]; then
    source "${file}"
fi

# Avoid
if [ -f "$file" ]; then
    source "$file"
fi
```

### Use `source` Instead of `.`

- **Prefer `source`** over `.` for readability
- **Why**: More explicit and self-documenting

## 3. Numeric Comparisons

### Use `(( ... ))` or `-eq` for Integers

- **Prefer `(( ... ))`** for arithmetic expressions and numeric comparisons
- **Use `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge`** inside `[[ ... ]]`
- **Avoid** using `==`, `>`, `<` inside `[[ ... ]]` for numbers (they perform
  string/lexicographical comparison)
- **Why**: Clearer intent and prevents logic errors (e.g., string "10" is
  lexicographically less than "2")

```bash
# Recommended
if (( count > 10 )); then ...

# Acceptable
if [[ "${count}" -gt 10 ]]; then ...

# Avoid (String comparison!)
if [[ "${count}" > 10 ]]; then ...
```

## 4. Command Existence Checks

### Use `command -v` Instead of `which`

- **Always use `command -v`** to check if a command exists
- **Why**:
  - POSIX-compliant (works in all shells)
  - Faster (built-in command)
  - More reliable (doesn't depend on PATH order)
  - `which` is an external command and may not be available

```bash
# Good
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Avoid
if which starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
```

## 5. Error Handling and Defensive Programming

### File Existence and Readability Checks

- **Always check before sourcing/evaluating**:
  - Use `[[ -f "${file}" ]]` for file existence
  - Use `[[ -s "${file}" ]]` for non-empty file
  - Use `[[ -r "${file}" ]]` for readable file
  - Use `[[ -d "${dir}" ]]` for directory existence

```bash
# Good
if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    source "${NVM_DIR}/nvm.sh"
fi

# Avoid
source "${NVM_DIR}/nvm.sh"  # May fail if file doesn't exist
```

### Prefer `if-then-fi` Over `&&` Chains for Conditional Sourcing

- **Use explicit `if-then-fi` blocks** for conditional sourcing
- **Why**: More readable, easier to debug, and avoids SC2015 warnings

```bash
# Good
if [[ -s "${GVM_DIR}/scripts/gvm" ]]; then
    source "${GVM_DIR}/scripts/gvm"
fi

# Avoid (SC2015 warning)
[[ -s "${GVM_DIR}/scripts/gvm" ]] && source "${GVM_DIR}/scripts/gvm"
```

## 6. Variable Management

### Consistent Variable Expansion Format

- **Always use `${VARIABLE}` format** instead of `$VARIABLE`
- **Why**:
  - Prevents ambiguity in variable boundaries
  - Consistent style throughout the codebase
  - Better for string interpolation

```bash
# Good
export PYENV_ROOT="${HOME}/.pyenv"
add_to_path "${PYENV_ROOT}/bin"

# Avoid
export PYENV_ROOT="$HOME/.pyenv"
add_to_path "$PYENV_ROOT/bin"
```

### Proper Quoting

- **Always quote variable expansions** to prevent word splitting and pathname
  expansion
- **Quote all variables** unless you explicitly need word splitting

```bash
# Good
if [[ -f "${HOME}/.bash_aliases" ]]; then
    source "${HOME}/.bash_aliases"
fi

# Avoid
if [[ -f $HOME/.bash_aliases ]]; then
    source $HOME/.bash_aliases
fi
```

### Use `${HOME}` Instead of `~`

- **Prefer `${HOME}`** over `~` in scripts
- **Why**: More explicit, works in all contexts, better for shellcheck

```bash
# Good
export ALACRITTY_HOME="${HOME}/alacritty"

# Avoid
export ALACRITTY_HOME="~/alacritty"
```

### Temporary Variable Cleanup

- **Use `local` variables** in functions
- **Why**: Prevents variable leakage and namespace pollution

```bash
add_to_path() {
    local dir="${1}"
    local should_force_update="${2:-false}"
    # ... function body ...
}
```

## 7. PATH Management

### Centralized PATH Management Function

- **Use a dedicated `add_to_path` function** instead of direct PATH manipulation
- **Benefits**:
  - Prevents duplicate entries
  - Validates directory existence
  - Idempotent operations
  - Optional force-update to move to front

```bash
add_to_path() {
    local dir="${1}"
    local should_force_update="${2:-false}"

    if [[ ! -d "${dir}" ]]; then
        return 1
    fi
    if [[ "${should_force_update}" == "true" ]]; then
        PATH=":${PATH}:"
        PATH="${PATH//:${dir}:/:}"
        PATH="${PATH#:}"
        PATH="${PATH%:} "
    fi
    if [[ ":${PATH}:" != ":${dir}:"* ]]; then
        PATH="${dir}:${PATH}"
    fi
    return 0
}
```

## 8. Function Design (Google Shell Style Guide)

### Function Naming

- **Use lowercase with underscores**: `add_to_path`, `travel_pre_commit`
- **Why**: Consistent with
  [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Function Documentation

- **Document all functions** following the best practices described in the
  [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Each function should include**:
  - **Description**: Brief overview of the function's purpose
  - **Globals**: List of global variables used and modified (if any)
  - **Arguments**: Description of each argument (using `${1}`, `${2}`, etc.)
  - **Outputs**: Information about data written to STDOUT or STDERR (if any)
  - **Returns**: Details on return values other than the default exit status

```bash
# Add a directory to `${PATH}` if it exists and is not already there.
# Globals:
#   PATH (modified)
# Arguments:
#   ${1}: Directory path to add
#   ${2}: If `true`, removes the directory from `${PATH}` first (if present)
#   and then prepends it, ensuring it is at the front (default: `false`).
# Returns:
#   `0` if directory was added or already exists in `${PATH}`
#   `1` if directory doesn't exist
add_to_path() {
    # ... implementation ...
}
```

### Explicit Returns

- **Always use explicit `return` statements** with exit codes
- **Why**: Clear intent and proper error handling

### Local Variables

- **Always declare function variables as `local`**
- **Why**: Prevents variable leakage to global scope

## 9. Comment Style

### Standard Comment Format

- **Full sentences** starting with capital letter and ending with period
- **Exception**: Section headers can be short (e.g., `# pyenv`, `# Bash History`)

```bash
# Good
# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL="ignoreboth"

# Section header (exception)
# pyenv

# Avoid
# don't put duplicate lines
HISTCONTROL="ignoreboth"
```

## 10. Alias Best Practices

### Variable Expansion in Aliases

- **Escape variables** in aliases to ensure expansion at use time,
  not definition time
- **Why**: Aliases expand variables at definition time by default,
  which may not be desired

```bash
# Good - expands at use time
alias i3conf="vim \${HOME}/.i3/config"

# Avoid - expands at definition time
alias i3conf="vim ${HOME}/.i3/config"
```

### Multiline Aliases

- **Use multiline format** for complex aliases
- **Use `&&` for chaining** instead of `;` when error handling matters

```bash
# Good
alias xrandr_home="xmodmap \${HOME}/.Xmodmap \
    && xrandr \
    --output DP2-2 --mode 1920x1200 --pos 0x0 \
    --output eDP1 --mode 1920x1080 --pos 1990x0"
```

## 11. Code Organization

### Logical Section Grouping

- **Group related configurations** together:
  - Initialization and shell options
  - Utilities and helper functions
  - Terminal and prompt configuration
  - Tools and language managers
  - Shell enhancements
  - Development tools
  - Alias loading
  - Work-specific configuration

### Co-location of Related Config

- **Keep tool configuration together**:
  - Environment variables
  - PATH modifications
  - Initialization commands
  - All in one place for each tool

```bash
# pyenv
export PYENV_ROOT="${HOME}/.pyenv"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
add_to_path "${PYENV_ROOT}/bin"
```

## 12. Conditional Expression Optimization

### Combine Conditions When Appropriate

- **Use `&&` within `[[ ]]`** for multiple conditions on the same line
- **Why**: More efficient and readable

```bash
# Good
if [[ -z "${DISPLAY}" && "${XDG_VTNR}" -eq 1 ]]; then
    startx
fi

# Also acceptable (separate checks)
if [[ -z "${DISPLAY}" ]] && [[ "${XDG_VTNR}" -eq 1 ]]; then
    startx
fi
```

## 13. Redirection and Error Suppression

### Proper Error Suppression

- **Use `>/dev/null 2>&1`** to suppress both stdout and stderr
- **Why**: Explicit and clear intent

```bash
# Good
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
```

## 14. Default Values

### Use Parameter Expansion for Defaults

- **Use `${VAR:-default}`** for default values
- **Why**: Clean, POSIX-compliant, and readable

```bash
# Good
local should_force_update="${2:-false}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-${HOME}/.docker}"

# Avoid
if [[ -z "${2}" ]]; then
    should_force_update="false"
else
    should_force_update="${2}"
fi
```

## 15. String Manipulation

### Safe String Operations

- **Use parameter expansion** for string manipulation when possible
- **Why**: Built-in, fast, and safe

```bash
# Remove leading/trailing colons
PATH="${PATH#:}"
PATH="${PATH%:}"

# Pattern replacement
PATH="${PATH//:${dir}:/:}"
```

## 16. Testing and Validation

### Always Validate Inputs

- **Check directory existence** before adding to PATH
- **Check file existence** before sourcing
- **Check command existence** before using

```bash
add_to_path() {
    local dir="${1}"
    if [[ ! -d "${dir}" ]]; then
        return 1
    fi
    # ... rest of function ...
}
```

## Summary Checklist

When writing or refactoring bash scripts, ensure:

- [ ] `# shellcheck shell=bash` at the top
- [ ] Use `[[ ]]` instead of `[ ]`
- [ ] Use `command -v` instead of `which`
- [ ] Check file/command existence before sourcing/evaluating
- [ ] Use `${VARIABLE}` format consistently
- [ ] Quote all variable expansions
- [ ] Use `local` variables in functions
- [ ] Document functions with arguments and return values
- [ ] Use explicit `return` statements
- [ ] Use `source` instead of `.`
- [ ] Use `if-then-fi` for conditional sourcing
- [ ] Escape variables in aliases when needed
- [ ] Use `# shellcheck source=/dev/null` for inaccessible files
- [ ] Write full-sentence comments with periods
- [ ] Group related configurations together
- [ ] Use `add_to_path` for PATH management
- [ ] Validate inputs before use
