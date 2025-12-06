# Lua & Neovim Style Guide

<!-- TODO(skarzi): Let's move this file to GitHub agents
`.github/agents/lua-agent/AGENTS.md`.
But still keep it referenced in the root `AGENTS.md` file!

References:

+ https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
+ https://ericmjl.github.io/blog/2025/10/4/how-to-teach-your-coding-agent-with-agentsmd/
+ https://www.anthropic.com/engineering/claude-code-best-practices
+ https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
+ https://www.builder.io/blog/agents-md
-->

This document establishes the coding standards and best practices for Lua
development within this repository, specifically tailored for Neovim
configuration.

## 1. Formatting & Syntax

- **Indentation**: Use **4 spaces** for indentation. Do not use hard tabs.
- **Line Length**: Limit lines to **80 characters**.
- **Encoding**: Use UTF-8.
- **Trailing Whitespace**: Strip trailing whitespace.
- **End of File**: Ensure a single newline at the end of the file.

## 2. Naming Conventions

- **Variables & Functions**: Use `snake_case`.
  - *Good*: `local user_name`, `function calculate_total()`
  - *Bad*: `local userName`, `function CalculateTotal()`
- **Types/Classes**: Use `PascalCase` (if using metatables/classes).
- **Constants**: Use `SCREAMING_SNAKE_CASE`.
  - *Good*: `local MAX_RETRIES = 5`
- **Private/Internal**: Prefix with underscore `_` for module-private variables
  or functions that aren't exported.
  - *Example*: `local _helper_function = function() ... end`
- **Meaningful Names**:
  - **Never** use single-letter variable names (e.g., `i`, `j`, `k`, `x`). Use
      descriptive names like `index`, `count`, `char`, `line_number`.
  - **Never** use meaningless names like `temp`, `foo`, `data`. Use names that
      describe the content or purpose.

## 3. Comments & Documentation

- **Format**: Write comments as full sentences.
  - Start with a **Capital letter**.
  - End with a **period**.
  - *Example*: `-- Load the configuration for the colorscheme.`
- **Exceptions**: Section headers or lists of tools (e.g., `LSPs`, `Linters`) do
  not require punctuation.
- **Avoid Obvious Comments**: Do not explain *what* the code is doing if it is
  self-explanatory. Focus on *why*.
  - *Bad*: `vim.opt.number = true -- Enable line numbers`
  - *Good*: `vim.opt.relativenumber = true -- Use relative numbers for easier
      navigation`
- **Style**:
  - Use `--` for single-line comments.
  - Use `---` for EmmyLua style documentation annotations (recommended for
      functions).
- **Keymaps**: Always provide a `desc` field in keymap options explaining what
  the shortcut does.

## 4. Lua Idioms

- **Scope**: Always use `local` for variables and functions unless they strictly
  need to be global (which is rare in Neovim configs).
- **Modules**: Use the standard module pattern.

    ```lua
    local M = {}

    function M.setup()
        -- ...
    end

    return M
    ```

- **Conditionals**: Explicitly check for `nil` when necessary, but remember that
  `nil` and `false` are the only falsy values in Lua. `0` and `""` are true.

## 5. Neovim Best Practices

### Configuration

- **Options**: Use `vim.opt` (global) and `vim.opt_local` (buffer-local) API
  instead of `vim.cmd("set ...")` or `vim.o`.
  - *Good*: `vim.opt.relativenumber = true`
  - *Bad*: `vim.cmd("set relativenumber")`
- **Globals**: Use `vim.g` for global variables (e.g., plugin flags).

### Keymappings

- **API**: Use `vim.keymap.set`.
- **Description**: **Mandatory** `desc` field. It should be a short, concise,
  precise sentence **without** a trailing period.
- **Structure**:

    ```lua
    vim.keymap.set("n", "<leader>f", function()
        -- logic
    end, { desc = "Find files" })
    ```

### Autocommands

- **Groups**: Always use `augroup` to prevent duplication. Clear the group on
  definition.
- **API**: Use `vim.api.nvim_create_autocmd`.

    ```lua
    local group = vim.api.nvim_create_augroup(
        "MyPluginAutoCmds",
        { clear = true }
    )
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "lua",
        callback = function()
            -- logic
        end,
        desc = "Setup Lua specific settings.",
    })
    ```

### Plugins

- **Manager**: Use `lazy.nvim` specifications.
- **Lazy Loading**: Prefer `event`, `cmd`, `ft`, or `keys` to lazy load
  plugins. Avoid `lazy = false` unless necessary (e.g., colorschemes, startup
  dashboards).
- **Dependencies**: Define dependencies explicitly within the plugin spec.

### APIs

- **No Aliasing**: Do not alias standard Neovim modules (like `vim.keymap`,
  `vim.opt`, `vim.api`) to local variables. Use the fully qualified name for
  clarity and consistency.
  - *Bad*: `local keymap = vim.keymap; keymap.set(...)`
  - *Good*: `vim.keymap.set(...)`
- **Vimscript vs Lua**: Prefer Lua standard library or `vim.*` APIs over
  `vim.cmd` or `vim.fn` where a native Lua equivalent exists.
  - *Example*: Use `vim.tbl_contains` instead of calling a Vimscript function.
- **Filesystem**: Use `vim.uv` (or `vim.loop` on older versions) for file
  system operations when performance matters, or `vim.fs` helpers.

## 6. Project Structure

- **`init.lua`**: Entry point. Should be minimal and require other modules.
- **`lua/core/`**: Core settings (`options`, `keymaps`).
- **`lua/plugins/`**: Plugin specifications (returned as tables for
  `lazy.nvim`).
- **`lua/config/`**: Custom logic, filetype overrides, and utility functions.
- **Reference**: Follow the established pattern in `nvim/`.

## 7. References

- [LuaRocks Style Guide](https://github.com/luarocks/lua-style-guide)
- [Lua Users Style Guide](http://lua-users.org/wiki/LuaStyleGuide)
- [Cursor Lua Best Practices](https://cursor.directory/lua-development-best-practices)
