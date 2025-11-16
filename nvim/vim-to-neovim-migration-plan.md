<!-- markdownlint-disable MD013 -->
# Vim to Neovim Migration Plan

## Table of Contents

- [Overview](#overview)
- [Current Configuration Analysis](#current-configuration-analysis)
- [Neovim Configuration Structure](#neovim-configuration-structure)
- [Plugin Migration Analysis](#plugin-migration-analysis)
  - [1. Colorschemes](#1-colorschemes)
  - [2. Development Tools](#2-development-tools)
  - [3. Editor Enhancements](#3-editor-enhancements)
  - [4. Python Development](#4-python-development)
  - [5. Utilities](#5-utilities)
  - [6. Web Development](#6-web-development)
- [Plugins That Can Be Removed or Replaced](#plugins-that-can-be-removed-or-replaced)
- [Custom Hardtime Implementation](#custom-hardtime-implementation)
- [Settings Migration](#settings-migration)
- [Lua Linters and Formatters](#lua-linters-and-formatters)
- [New Neovim-Specific Recommendations](#new-neovim-specific-recommendations)
- [Adding AI Assistance: avante.nvim + copilot.lua](#adding-ai-assistance-avantenvim--copilotlua)
- [Migration Steps](#migration-steps)
- [Keybindings Migration](#keybindings-migration)
- [Your Preferences (Answered)](#your-preferences-answered)
- [Recommended Plugin Installation Priority](#recommended-plugin-installation-priority)
- [Language Servers to Install](#language-servers-to-install)
- [Next Steps](#next-steps)
- [Resources](#resources)

---

## Overview

This document outlines a comprehensive migration plan from your current Vim configuration (`.vim/`) to Neovim. The plan includes:

- Plugin-by-plugin migration analysis
- Settings that need to be migrated
- Recommendations for Neovim-specific alternatives
- Configuration structure and file organization
- Lua linters and formatters
- Integration of `avante.nvim` and `copilot.lua` plugins
- Detailed analysis of plugins that can be removed or replaced

---

## Current Configuration Analysis

### Configuration Structure

- **Main entry point**: `~/.vim/.vimrc`
- **Plugin manager**: Vundle
- **Settings location**: `~/.vim/settings/` (modular configuration files)
- **Plugins location**: `~/.vim/bundle/`
- **Snippets**: `~/.vim/ultisnips/`

### Plugin Categories

1. **Colorschemes** (6 plugins)
2. **Development tools** (13 plugins)
3. **Editor enhancements** (8 plugins)
4. **Python development** (3 plugins)
5. **Utilities** (4 plugins)
6. **Web development** (5 plugins)

---

## Neovim Configuration Structure

### Recommended Neovim Config Structure

Based on your current Vim structure (`.vim/settings/` with modular files), here's the recommended Neovim structure. **Note**: You'll be using a `nvim/` directory in your dotfiles, which will be symlinked to `~/.config/nvim/`:

```text
nvim/
├── init.lua                 # Main entry point
├── lua/
│   ├── core/                # Core Neovim settings
│   │   ├── options.lua       # vim.opt settings
│   │   ├── keymaps.lua      # Keybindings
│   │   ├── autocmds.lua     # Autocommands
│   │   └── init.lua         # Loads all core modules
│   │
│   ├── plugins/             # Plugin configurations
│   │   ├── init.lua         # Plugin manager setup (lazy.nvim)
│   │   ├── core.lua         # Essential plugins (lsp, treesitter, cmp)
│   │   ├── colorschemes.lua # Colorschemes (onedark.nvim)
│   │   ├── lsp.lua          # LSP configuration
│   │   ├── formatting.lua   # conform.nvim configuration
│   │   ├── linting.lua      # nvim-lint configuration
│   │   ├── git.lua          # gitsigns.nvim, fugitive
│   │   ├── ui.lua           # lualine, bufferline, etc.
│   │   ├── editing.lua       # autopairs, surround, comment, etc.
│   │   ├── navigation.lua   # telescope, nvim-tree, aerial
│   │   ├── python.lua        # Python-specific plugins
│   │   ├── rust.lua          # rust-tools.nvim
│   │   ├── go.lua            # go.nvim
│   │   ├── testing.lua      # neotest
│   │   ├── debugging.lua    # nvim-dap
│   │   └── ai.lua           # avante.nvim, copilot.lua
│   │
│   ├── config/              # Custom configurations
│   │   ├── hardtime.lua     # Custom hardtime implementation
│   │   ├── indentation.lua  # Indentation settings
│   │   ├── filetypes.lua    # Filetype-specific settings
│   │   └── utils.lua        # Utility functions
│   │
│   └── snippets/            # LuaSnip snippets
│       ├── python.lua
│       ├── javascript.lua
│       └── html.lua
```

### Example init.lua

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load core settings
require("core")

-- Load plugins
require("plugins")

-- Load custom configs
require("config")
```

### Example core/init.lua

```lua
-- Load all core modules
require("core.options")
require("core.keymaps")
require("core.autocmds")
```

### Example plugins/init.lua

```lua
require("lazy").setup({
  spec = {
    { import = "plugins.core" },
    { import = "plugins.colorschemes" },
    { import = "plugins.lsp" },
    { import = "plugins.formatting" },
    { import = "plugins.linting" },
    { import = "plugins.git" },
    { import = "plugins.ui" },
    { import = "plugins.editing" },
    { import = "plugins.navigation" },
    { import = "plugins.python" },
    { import = "plugins.rust" },
    { import = "plugins.go" },
    { import = "plugins.testing" },
    { import = "plugins.debugging" },
    { import = "plugins.ai" },
  },
  -- lazy.nvim options
})
```

---

## Plugin Migration Analysis

> **Note on Plugin Information**: The following tables include GitHub stars (approximate), maintenance status, last activity, and recommendations. Star counts are approximate and may vary. Maintenance status indicates:
>
> - ✅ **Actively maintained**: Regular commits/updates (within last 3 months)
> - ⚠️ **Moderate**: Occasional updates (3-6 months)
> - ⚠️ **Low/Deprecated**: Rare or no updates (6+ months)
>
> **Recommendation Ratings**:
>
> - ⭐⭐⭐⭐⭐ **Highly Recommended**: Essential, actively maintained, widely used
> - ⭐⭐⭐⭐ **Recommended**: Good choice, actively maintained
> - ⭐⭐⭐ **Good**: Useful but optional or moderate maintenance
> - ⭐⭐ **Optional**: Low priority or low maintenance
> - ⚠️ **Not Recommended**: Deprecated or better alternatives available

### 1. Colorschemes

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `reedes/vim-colors-pencil` | ~1k+ | ✅ Actively maintained | Regular updates | ✅ Compatible | ⭐⭐⭐⭐ **Keep** - Or migrate to Lua version if available |
| `w0ng/vim-hybrid` | ~2k+ | ✅ Actively maintained | Regular updates | ✅ Compatible | ⭐⭐⭐⭐ **Keep** - Popular colorscheme |
| `chase/focuspoint-vim` | ~100+ | ⚠️ Moderate | Occasional updates | ✅ Compatible | ⭐⭐⭐ **Keep** - Works but moderate maintenance |
| `joshdick/onedark.vim` | ~1.5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `navarasu/onedark.nvim` (Lua, better performance) |
| `liuchengxu/space-vim-dark` | ~200+ | ⚠️ Moderate | Occasional updates | ✅ Compatible | ⭐⭐⭐ **Keep** - Works but moderate maintenance |
| `chase/vim-airline-focuspoint` | ~50+ | ⚠️ Low | Rare updates | ✅ Compatible | ⭐⭐ **Optional** - Airline theme, low maintenance |
| `vim-airline/vim-airline-themes` | ~1k+ | ✅ Actively maintained | Regular updates | ✅ Compatible | ⭐⭐⭐⭐ **Keep** - If using vim-airline |

**Recommendation**: Replace `onedark.vim` with `navarasu/onedark.nvim` for better Neovim integration. This is the recommended colorscheme for Neovim.

---

### 2. Development Tools

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `tpope/vim-fugitive` | ~20k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐⭐ **Highly Recommended** - Excellent Git integration, widely used |
| `airblade/vim-gitgutter` | ~8k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `lewis6991/gitsigns.nvim` (Lua, faster) |
| `dense-analysis/ale` | ~13k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-lint` + `nvim-lspconfig` (native LSP) |
| `SirVer/ultisnips` | ~6k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `L3MON4D3/LuaSnip` (Lua, better Neovim integration) |
| `honza/vim-snippets` | ~5k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Compatible with LuaSnip, large snippet collection |
| `wakatime/vim-wakatime` | ~2k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Time tracking, fully compatible |
| `benmills/vimux` | ~1.5k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Tmux integration, you already use this |
| `rust-lang/rust.vim` | ~4k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `simrat39/rust-tools.nvim` (includes syntax + LSP) |
| `amadeus/vim-mjml` | ~100+ | ⚠️ Moderate | Occasional updates | ✅ Keep | ⭐⭐⭐ **Keep** - MJML support, moderate maintenance |
| `majutsushi/tagbar` | ~6k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `stevearc/aerial.nvim` (LSP-aware, more feature-rich) |
| `sheerun/vim-polyglot` | ~5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-treesitter/nvim-treesitter` (better syntax highlighting) |
| `github/copilot.vim` | ~5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use both `avante.nvim` (project-aware AI) and `copilot.lua` (inline autocomplete) |

**Key Replacements**:

- **vim-gitgutter** → `gitsigns.nvim` (Lua, faster)
- **ALE** → `nvim-lint` + `nvim-lspconfig` (native LSP support)
- **UltiSnips** → `LuaSnip` (Lua-based, faster)
- **Tagbar** → `aerial.nvim` (LSP-aware, more feature-rich)
- **vim-polyglot** → `nvim-treesitter` (better syntax highlighting)
- **Copilot.vim** → Use both `avante.nvim` (project-aware AI) and `copilot.lua` (inline autocomplete)

---

### 3. Editor Enhancements

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `vim-pandoc/vim-pandoc` | ~1.5k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Pandoc integration, fully compatible |
| `vim-pandoc/vim-pandoc-syntax` | ~500+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Pandoc syntax highlighting |
| `lervag/vimtex` | ~5k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐⭐ **Highly Recommended** - Excellent LaTeX support, widely used |
| `junegunn/goyo.vim` | ~4k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Distraction-free writing, you already use this |
| `editorconfig/editorconfig-vim` | ~1k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `gpanders/editorconfig.nvim` (Lua, better performance) |
| `kana/vim-operator-user` | ~1k+ | ✅ Actively maintained | Regular updates | ✅ Keep | ⭐⭐⭐⭐ **Keep** - Operator framework, used by other plugins |
| `haya14busa/vim-operator-flashy` | ~200+ | ⚠️ Moderate | Occasional updates | ✅ Keep | ⭐⭐⭐ **Keep** - Visual feedback for operators, you already use this |

**Recommendation**: Replace `editorconfig-vim` with `editorconfig.nvim` for better performance.

---

### 4. Python Development

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `davidhalter/jedi-vim` | ~5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-lspconfig` + `pyrefly`/`pyright`/`jedi-language-server` (native LSP) |
| `tmhedberg/SimpylFold` | ~1k+ | ⚠️ Moderate | Occasional updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-treesitter` folding (better, LSP-aware) |
| `vim-scripts/indentpython.vim` | ~200+ | ⚠️ Low | Rare updates | ⚠️ Remove | ⚠️ **Remove** - Built-in Python indentation is sufficient |

**Key Replacement**: **jedi-vim** → Native LSP with `pyrefly` (recommended, fastest), `pyright`, or `jedi-language-server` (better IDE features, faster).

**Note**: [Pyrefly](https://pyrefly.org/) is a new, extremely fast Python type checker and language server from Meta that can type check over 1.85 million lines of code per second. It's recommended for large codebases and provides lightning-fast autocomplete and instant error feedback.

---

### 5. Utilities

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `bling/vim-airline` | ~13k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-lualine/lualine.nvim` (Lua, better) |
| `bling/vim-bufferline` | ~1k+ | ⚠️ Moderate | Occasional updates | ⚠️ Replace | ⚠️ **Replace** - Use `akinsho/bufferline.nvim` (Lua, better integration) |
| `takac/vim-hardtime` | ~1k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Custom Lua implementation (see below) |
| `tpope/vim-vinegar` | ~5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `nvim-tree/nvim-tree.lua` (better file explorer) |

**Recommendations**:

- **vim-airline** → `lualine.nvim` (modern, Lua-based statusline)
- **vim-bufferline** → `bufferline.nvim` (better Neovim integration)
- **vim-hardtime** → Custom Lua implementation (see Custom Hardtime Implementation section)
- **vim-vinegar** → `nvim-tree.lua` (better file explorer)

---

### 6. Web Development

| Vim Plugin | GitHub Stars | Maintenance Status | Last Activity | Neovim Status | Recommendation |
| --- | --- | --- | --- | --- | --- |
| `mattn/emmet-vim` | ~5k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `windwp/nvim-autopairs` + `windwp/nvim-ts-autotag` |
| `hail2u/vim-css3-syntax` | ~500+ | ✅ Actively maintained | Regular updates | ⚠️ Remove | ⚠️ **Remove** - Treesitter handles CSS3 syntax better |
| `Valloric/MatchTagAlways` | ~500+ | ⚠️ Moderate | Occasional updates | ⚠️ Replace | ⚠️ **Replace** - Use `windwp/nvim-ts-autotag` (treesitter-based, more accurate) |
| `lilydjwg/colorizer` | ~1k+ | ✅ Actively maintained | Regular updates | ⚠️ Replace | ⚠️ **Replace** - Use `norcalli/nvim-colorizer.lua` (Lua, better performance) |
| `diepm/vim-rest-console` | ~1k+ | ✅ Actively maintained | Regular updates | ⚠️ Remove | ⚠️ **Remove** - You're using Bruno now, no longer needed |

**Recommendations**:

- **emmet-vim** → `nvim-autopairs` + `nvim-ts-autotag`
- **vim-css3-syntax** → Treesitter (handles CSS3 automatically)
- **MatchTagAlways** → `nvim-ts-autotag` (treesitter-based, more accurate)
- **colorizer** → `nvim-colorizer.lua` (Lua, faster)
- **vim-rest-console** → Remove (using Bruno now)

---

## Plugins That Can Be Removed or Replaced

### ✅ **Definitely Remove** (Built-in alternatives)

1. **`vim-scripts/indentpython.vim`** → Built-in Python indentation
   - Neovim has built-in Python indentation support via `filetype plugin indent on`
   - **Replacement**: Just use Neovim's built-in Python indentation

2. **`tmhedberg/SimpylFold`** → Treesitter folding
   - Treesitter provides better folding that's LSP-aware
   - **Replacement**: Use treesitter folding or built-in indent folding

3. **`hail2u/vim-css3-syntax`** → Treesitter CSS3 syntax
   - Treesitter provides better CSS3 syntax highlighting
   - **Replacement**: Treesitter handles CSS3 syntax automatically

4. **`Valloric/MatchTagAlways`** → `nvim-ts-autotag`
   - Treesitter-based solution is more accurate
   - **Replacement**: `windwp/nvim-ts-autotag`

5. **`bling/vim-bufferline`** → Redundant with airline tabline
   - If using airline's tabline, bufferline is redundant
   - **Replacement**: Use airline's built-in tabline or switch to `bufferline.nvim`

6. **`sheerun/vim-polyglot`** → Treesitter
   - Treesitter provides better syntax highlighting for most languages
   - **Replacement**: `nvim-treesitter/nvim-treesitter`

### ⚠️ **Consider Removing** (Can replace with simple functions/config)

1. **`takac/vim-hardtime`** → Custom Lua implementation
   - Can be implemented as a simple Lua function if you just want to prevent arrow keys
   - **Replacement**: See Custom Hardtime Implementation section below

2. **`tpope/vim-vinegar`** → Netrw config or nvim-tree
   - vim-vinegar just enhances netrw. You can replicate most features with config
   - **Replacement**: Simple netrw configuration or `nvim-tree.lua`

3. **`lilydjwg/colorizer`** → Only if rarely used
   - Can be replaced with `nvim-colorizer.lua` OR simple function
   - **Replacement**: `norcalli/nvim-colorizer.lua` (if you need it)

4. **`bling/vim-airline`** → Minimal built-in statusline
   - Neovim's built-in statusline can be configured to show most info
   - **Replacement**: Minimal built-in statusline or `lualine.nvim`

5. **`rust-lang/rust.vim`** → If using rust-tools.nvim
   - rust-tools.nvim provides syntax + LSP features
   - **Replacement**: `simrat39/rust-tools.nvim`

6. **`kana/vim-operator-user`** → Only if not creating custom operators
   - If you only use it for vim-operator-flashy, you might not need it
   - **Replacement**: Check if you actually use custom operators

### 📝 **Keep These** (No simple replacement)

- `tpope/vim-fugitive` - Excellent Git integration
- `wakatime/vim-wakatime` - Time tracking
- `benmills/vimux` - Tmux integration
- `vim-pandoc/vim-pandoc` - Pandoc support
- `lervag/vimtex` - LaTeX support
- `junegunn/goyo.vim` - Distraction-free writing
- `amadeus/vim-mjml` - MJML support
- `haya14busa/vim-operator-flashy` - Visual feedback (if you use it)
- `honza/vim-snippets` - Compatible with LuaSnip

---

## Custom Hardtime Implementation

Here's a simple Lua implementation to replace `vim-hardtime`:

```lua
-- config/hardtime.lua
local M = {}

local disabled_keys = {
  '<Up>',
  '<Down>',
  '<Left>',
  '<Right>',
}

function M.setup()
  -- Disable arrow keys in normal and insert mode
  for _, key in ipairs(disabled_keys) do
    vim.keymap.set('n', key, '<Nop>', { desc = 'Hardtime: disabled' })
    vim.keymap.set('i', key, '<Nop>', { desc = 'Hardtime: disabled' })
  end

  -- Optional: Show message when trying to use arrow keys
  -- You can add more sophisticated logic here
end

return M
```

Usage in `config/init.lua`:

```lua
require("config.hardtime").setup()
```

---

## Settings Migration

### Core Settings (Direct Migration)

All settings in the following files can be migrated directly to Neovim:

1. **`luki-appearance.vim`** → `core/options.lua` - Colors, UI layout, line numbers
   - Note: `set t_Co=256` not needed in Neovim (uses true color by default)

2. **`luki-filetypes.vim`** → `config/filetypes.lua` - Filetype detection

3. **`luki-folding.vim`** → `core/folding.lua` or use treesitter
   - Consider using treesitter folding later

4. **`luki-indentation.vim`** → `config/indentation.lua` - Indentation settings

5. **`luki-movement.vim`** → `core/keymaps.lua` - Movement mappings

6. **`luki-searching.vim`** → `core/options.lua` - Search configuration
   - Note: FZF integration may need adjustment

7. **`luki-splitting.vim`** → `core/keymaps.lua` - Window splitting

8. **`luki-stripping.vim`** → `config/utils.lua` - Whitespace stripping

9. **`luki-utils.vim`** → `config/utils.lua` - Utilities
   - **Note**: Python virtualenv support works in Neovim
   - Clipboard setting: Neovim uses `unnamedplus` instead of `unnamed`

10. **`a_luki-leader_key.vim`** → `core/keymaps.lua` - Leader key configuration
    - **Important**: Leader key is set to `,` (comma)
    - Keybindings:
      - `<leader>]` - Next buffer
      - `<leader>[` - Previous buffer
      - `<leader><space>` - Clear search highlight
      - `<leader>o` - Execute current file with Python

### Plugin-Specific Settings

#### ALE → nvim-lint + nvim-lspconfig

**Current** (`ale.vim`):

```vim
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
let g:ale_lint_on_enter = 1
let g:ale_open_list = 1
let g:ale_set_loclist = 1
let g:ale_list_window_size = 5
let g:ale_sign_error = '🐛'
let g:ale_sign_warning = '⚠️'
let g:ale_sign_info = 'ℹ️'
nmap <F7> :ALELint<CR>
nmap <F8> :ALEFix<CR>
```

**Neovim equivalent** (Lua):

```lua
-- nvim-lint configuration (replaces ALE linting)
require('lint').linters_by_ft = {
  python = {'bandit', 'flake8', 'pydocstyle'},
  vue = {'eslint', 'vls'},
  jsx = {'eslint'},
  tsx = {'eslint'},
  lua = {'selene'},
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

-- Keybindings (migrate from ALE)
vim.keymap.set('n', '<F7>', function() require('lint').try_lint() end, { desc = 'Lint' })
vim.keymap.set('n', '<F8>', function() require('conform').format({ async = true }) end, { desc = 'Format' })

-- LSP configuration (replaces ALE for language features)
require('lspconfig').pyright.setup{}
-- or
require('lspconfig').jedi_language_server.setup{}
```

#### ALE Formatting → conform.nvim

**Current** (`ale.vim`):

```vim
let g:ale_fixers = {
\    '*': ['remove_trailing_lines', 'trim_whitespace'],
\    'python': ['black', 'isort', 'remove_trailing_lines', 'trim_whitespace'],
\ }
nnoremap <Leader>z :<C-U>ALEFix isort<CR>
```

**Neovim equivalent with conform.nvim** (Lua):

```lua
-- Helper function to run first available formatter, then additional formatters
local function run_first_available(bufnr, ...)
  local conform = require("conform")
  for index = 1, select("#", ...) do
    local formatter = select(index, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

require("conform").setup({
  formatters_by_ft = {
    -- Python: run ruff or black (first available), then always isort
    python = function(bufnr)
      return { run_first_available(bufnr, "ruff_format", "black"), "isort" }
    end,
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    terraform = { "terraform_fmt" },
    ["*"] = { "trim_whitespace", "trim_newlines" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

-- Format command (replaces ALEFix)
vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

-- isort fix command (replaces <leader>z)
vim.keymap.set('n', '<leader>z', function()
  require("conform").format({ formatters = { "isort" }, async = true })
end, { desc = 'Format with isort' })
```

**Key Features**:

- **Python formatting**: Tries `ruff_format` first, falls back to `black` if not available, then always runs `isort`
- **isort configuration**: Uses your existing isort configuration (no overrides)
- **Format-on-save**: Automatically formats on save with 500ms timeout
- **Manual formatting**: `:Format` command and `<F8>` keybinding
- **isort-only**: `<leader>z` keybinding (migrated from ALE)

#### UltiSnips → LuaSnip

**Current** (`ultisnips.vim`):

```vim
let g:UltiSnipsExpandTrigger='<leader>q'
let g:UltiSnipsJumpForwardTrigger='<leader>q'
let g:UltiSnipsJumpBackwardTrigger='<leader>w'
let g:UltiSnipsListSnippets='<leader>t'
let g:UltiSnipsEditSplit='vertical'
let g:UltiSnipsSnippetDirectories=['ultisnips', 'UltiSnips']
```

**Neovim equivalent** (Lua):

```lua
local luasnip = require("luasnip")

-- Load snippets (migrate from ~/.vim/ultisnips/)
require("luasnip.loaders.from_vscode").lazy_load()
-- Or load from LuaSnip format:
-- require("luasnip.loaders.from_lua").lazy_load({ paths = "nvim/lua/snippets" })

-- Keybindings (migrate from UltiSnips)
vim.keymap.set({ "i", "s" }, "<leader>q", function()
  if luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  end
end, { desc = "Expand or jump snippet" })

vim.keymap.set({ "i", "s" }, "<leader>w", function()
  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  end
end, { desc = "Jump backward in snippet" })

vim.keymap.set("i", "<leader>t", function()
  luasnip.choice_active()
end, { desc = "List snippets" })

-- Edit snippets (similar to UltiSnipsEditSplit)
vim.keymap.set("n", "<leader>es", "<cmd>LuaSnipEdit<CR>", { desc = "Edit snippets" })
```

#### jedi-vim → nvim-lspconfig

**Current** (`jedi-vim.vim`):

```vim
let g:jedi#use_splits_not_buffers='left'
let g:jedi#show_call_signatures=1
```

**Keybindings to migrate** (from jedi-vim comments):

- `<C-Space>` - Completion
- `<leader>g` - Goto assignments
- `<leader>d` - Goto definitions
- `K` - Show documentation/Pydoc
- `<leader>r` - Renaming
- `<leader>n` - Show usages

**Neovim equivalent - Option 1: Pyrefly (Recommended)** ([Pyrefly](https://pyrefly.org/)):

**Installation Method 1: Using mason.nvim (Recommended for Neovim 0.11+)**:

```lua
-- In plugins/lsp.lua or plugins/python.lua
-- 1. Setup Mason and mason-lspconfig
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyrefly" },  -- Auto-install pyrefly
})

-- 2. Configure Pyrefly with nvim-lspconfig
-- If using mason-lspconfig, Pyrefly should work automatically!
-- You can override settings if needed:
require("lspconfig").pyrefly.setup({
  on_attach = function(client, bufnr)
    -- Show signature on hover
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Keybindings (using nvim-cmp for completion)
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', '<leader>g', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>n', vim.lsp.buf.references, opts)
  end,
})
```

**Installation Method 2: System Installation** (if pyrefly is on your PATH):

```lua
-- Ensure pyrefly is installed and available on PATH:
-- pip install pyrefly
-- pyrefly init  # Initialize in your project (optional)

-- Then configure with nvim-lspconfig:
require("lspconfig").pyrefly.setup({
  cmd = { "pyrefly", "lsp" },  -- Standard Pyrefly LSP command
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', '<leader>g', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>n', vim.lsp.buf.references, opts)
  end,
})
```

**Neovim equivalent - Option 2: Pyright**:

```lua
require('lspconfig').pyright.setup{
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', '<leader>g', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>n', vim.lsp.buf.references, opts)
  end
}
```

**Neovim equivalent - Option 3: jedi-language-server**:

```lua
require('lspconfig').jedi_language_server.setup{
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', '<leader>g', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>n', vim.lsp.buf.references, opts)
  end
}
```

**Pyrefly Installation Notes**:

- **Recommended (Neovim 0.11+)**: Use `mason.nvim` - Add `"pyrefly"` to `ensure_installed` in `mason-lspconfig` setup (see example above)
- **Alternative**: System installation - `pip install pyrefly` (ensure it's on your PATH)
- **Project initialization**: `pyrefly init` (optional, creates `pyrefly.toml` config file)

**Note**: Pyrefly is extremely fast (can type check 1.85M+ lines/second) and provides excellent IDE features. It's particularly recommended for large Python codebases. See [official Neovim setup guide](https://pyrefly.org/en/docs/IDE/#neovim) for details.

#### Colorscheme: onedark.vim → onedark.nvim

**Current** (`luki-appearance.vim`):

```vim
colorscheme onedark
```

**Neovim equivalent** (Lua):

```lua
-- Colorscheme: onedark.nvim (replaces onedark.vim)
require('onedark').setup {
  style = 'warmer', -- Options: 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'
}
require('onedark').load()
```

#### vim-airline → lualine.nvim

**Current** (`vim-airline.vim`):

```vim
let g:airline_theme='onedark'
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#bufferline#enabled=1
let g:airline#extensions#branch#enabled=1
let g:airline#extensions#ale#enabled = 1
```

**Neovim equivalent** (Lua):

```lua
-- Statusline: lualine.nvim (replaces vim-airline)
require('lualine').setup {
  options = { theme = 'onedark' },  -- Uses onedark.nvim theme
  extensions = {'fugitive', 'nvim-tree'},
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff'},
    lualine_c = {'filename'},
    lualine_x = {'diagnostics'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  }
}
```

#### Tagbar → aerial.nvim

**Current** (`tagbar.vim`):

```vim
nmap <F4> :TagbarToggle<CR>
```

**Neovim equivalent** (Lua):

```lua
-- aerial.nvim (LSP-aware symbol outline)
require("aerial").setup({
  -- Optional: configure as needed
  on_attach = function(bufnr)
    -- Load aerial on attach
  end,
})

-- Keybinding (migrate from Tagbar)
vim.keymap.set('n', '<F4>', '<cmd>AerialToggle<CR>', { desc = 'Toggle Aerial' })
```

**Alternative**: `simrat39/symbols-outline.nvim` is also a good option, but `aerial.nvim` is more feature-rich and LSP-aware.

---

## Why Use mason.nvim?

### Main Advantages

**mason.nvim** is a portable package manager for Neovim that installs and manages external development tools. Here's why it's recommended:

#### 1. **Centralized Tool Management**

- **Unified Interface**: Install and manage LSP servers, DAP adapters, linters, and formatters all from within Neovim
- **No System Package Manager Needed**: No need to use `npm`, `pip`, `brew`, `apt`, etc. for each tool
- **Consistent Experience**: Same installation process across all tools, regardless of their original package manager

#### 2. **Automatic PATH Integration**

- **Seamless Access**: Installed tools are automatically added to Neovim's PATH
- **Plugin Compatibility**: Other Neovim plugins (like `nvim-lspconfig`, `conform.nvim`, `nvim-lint`) can automatically find and use these tools
- **No Manual Configuration**: No need to manually set up paths or symlinks

#### 3. **Cross-Platform Support**

- **Works Everywhere**: Same installation process on Windows, macOS, and Linux
- **No Platform-Specific Setup**: Avoids the complexity of different package managers on different systems
- **Consistent Behavior**: Tools behave the same way regardless of your operating system

#### 4. **Easy Updates and Management**

- **Simple Updates**: Update all tools with `:MasonUpdate` or update individual tools
- **Version Management**: Mason handles version conflicts and dependencies
- **Clean Uninstallation**: Remove tools easily without leaving system-wide artifacts

#### 5. **Integration with mason-lspconfig.nvim**

- **Auto-Configuration**: `mason-lspconfig.nvim` automatically configures LSP servers installed via Mason
- **Reduced Manual Setup**: Less boilerplate code needed for each LSP server
- **Consistent Configuration**: Ensures all LSP servers are configured the same way

#### 6. **Isolated Installation**

- **No System Pollution**: Tools are installed in Neovim's data directory, not system-wide
- **Per-User**: Each user can have their own set of tools
- **Easy Cleanup**: Removing Neovim config doesn't leave tools scattered across your system

### Example: Without mason.nvim

```bash
# You'd need to install each tool manually:
npm install -g pyright typescript-language-server
pip install pyrefly jedi-language-server
brew install terraform-ls
go install golang.org/x/tools/gopls@latest
# ... and many more, each with different commands
```

### Example: With mason.nvim

```lua
-- Just configure what you need, Mason installs everything:
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "pyright",
    "pyrefly",  -- if available
    "gopls",
    "terraform_ls",
    -- ... etc
  },
})
-- Mason handles all the installation automatically!
```

### When You Might NOT Need mason.nvim

- **If you prefer system package managers**: Some developers prefer using `brew`, `apt`, `npm`, etc. for better system integration
- **If you want system-wide tools**: If you want LSP servers available outside Neovim
- **If you already have everything installed**: If you've already set up all your tools manually

**However**, even in these cases, mason.nvim can still be useful for:

- Managing Neovim-specific tool versions
- Easy updates and maintenance
- Consistent configuration via mason-lspconfig.nvim

---

## Lua Linters and Formatters

### Your Chosen Tools ✅

You've selected the recommended setup:

1. **selene** - Fast Lua linter (written in Rust)
2. **lua-language-server** - LSP for Lua (via mason.nvim)
3. **stylua** - Fast Lua formatter (written in Rust)

### Lua Linters

#### 1. **selene** ⭐⭐⭐⭐⭐ **Selected**

- **GitHub**: `Kampfkarren/selene`
- **Stars**: ~1k+
- **Status**: ✅ Actively maintained
- **Why**: Fast, written in Rust, excellent error messages
- **Installation**: `cargo install selene` or via package manager
- **Usage**: `selene config.lua`

#### 2. **lua-language-server** (LSP) ⭐⭐⭐⭐⭐ **Selected**

- **GitHub**: `LuaLS/lua-language-server`
- **Stars**: ~2k+
- **Status**: ✅ Actively maintained
- **Why**: Provides linting + autocompletion + diagnostics via LSP
- **Installation**: Via `mason.nvim` (recommended) or manually
- **Usage**: Configure via nvim-lspconfig
- **Note**: Requires `mason.nvim` plugin for easy installation

### Lua Formatters

#### 1. **stylua** ⭐⭐⭐⭐⭐ **Selected**

- **GitHub**: `JohnnyMorganz/StyLua`
- **Stars**: ~1.5k+
- **Status**: ✅ Actively maintained
- **Why**: Fast, written in Rust, opinionated (like black for Python)
- **Installation**: `cargo install stylua` or via package manager
- **Usage**: `stylua config.lua`
- **Configuration**: `.stylua.toml` in project root

### Recommended Setup

**For Neovim config linting** (Your Selection):

1. **selene** - Fast, excellent for Neovim configs ✅
2. **lua-language-server** - Via nvim-lspconfig + mason.nvim + mason-lspconfig.nvim for IDE features ✅
3. **stylua** - For formatting ✅

**Configuration example**:

```lua
-- .selene.toml (in nvim/ directory)
std = "lua54"
globals = {
  "vim",
  "use",
  "require",
}
```

```toml
# .stylua.toml (in nvim/ directory)
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
```

### Neovim Config Linting Setup

#### Using selene

**Manual usage**:

```bash
# Install selene
cargo install selene

# Create .selene.toml in nvim/ directory (from dotfiles root)
cat > nvim/.selene.toml << EOF
std = "lua54"
globals = {
  "vim",
  "use",
  "require",
}
EOF

# Lint your config (from dotfiles directory)
selene nvim/
```

**Integration with nvim-lint** (already included in main nvim-lint config):

The main `nvim-lint` configuration (shown in the ALE → nvim-lint section above) already includes selene for Lua files:

```lua
require('lint').linters_by_ft = {
  lua = {'selene'},  -- Lua linter
  -- ... other linters
}
```

#### Using lua-language-server (via nvim-lspconfig + mason.nvim + mason-lspconfig.nvim)

**Why mason.nvim?** See [Why Use mason.nvim?](#why-use-masonnvim) section for detailed advantages.

**Install mason.nvim and mason-lspconfig.nvim**:

```lua
-- In plugins/lsp.lua
{
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
  config = function()
    require("mason").setup()
  end,
},
{
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls" },  -- Auto-install lua-language-server
      automatic_installation = true,     -- Auto-install LSPs on first use
    })
  end,
}
```

**Then configure lua-language-server**:

```lua
-- In plugins/lsp.lua
-- mason-lspconfig automatically sets up the LSP server
-- You just need to configure the settings

require('lspconfig').lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim', 'use', 'require' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
```

**Alternative (simpler)**: If you use `mason-lspconfig.nvim`, you can also use its `handlers` feature:

```lua
-- In plugins/lsp.lua
require("mason-lspconfig").setup_handlers({
  -- Default handler for all servers
  function(server_name)
    require("lspconfig")[server_name].setup({})
  end,
  -- Custom handler for lua_ls
  ["lua_ls"] = function()
    require("lspconfig").lua_ls.setup({
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim", "use", "require" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          telemetry = { enable = false },
        },
      },
    })
  end,
})
```

#### Using stylua for formatting

```bash
# Install stylua
cargo install stylua

# Format your config (from dotfiles directory)
stylua nvim/
```

**Integration with conform.nvim** (already included in main conform.nvim config):

The main `conform.nvim` configuration (shown in the ALE Formatting → conform.nvim section above) already includes stylua for Lua files:

```lua
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    -- ... other formatters
  },
})
```

### Validating Neovim Configs with Makefile and Pre-commit Hooks

Your dotfiles repository includes automated validation for Lua files:

**Makefile target** (`lint-fix-lua`):

```bash
# From dotfiles root directory
make lint-fix-lua

# Or lint specific files
make lint-fix-lua -- nvim/lua/core/keymaps.lua
```

This command:

1. Runs `selene` to lint Lua files in `nvim/` directory (or specified files)
2. Runs `stylua --respect-ignores --verify --check` to check formatting
3. If formatting check fails, automatically fixes files with `stylua` and exits with error (to ensure you review changes)

**Pre-commit hook** (automatic validation):

The `.pre-commit-config.yaml` includes a `lint-fix-lua` hook that:

- Automatically runs on all `.lua` files before each commit
- Lints with `selene` and formats with `stylua`
- Ensures all Neovim config files are valid and properly formatted

**Usage during migration**:

```bash
# After creating/editing Neovim config files, validate them:
make lint-fix-lua

# Or let pre-commit handle it automatically when you commit
git add nvim/
git commit -m "feat(nvim): add mason.nvim config"  # Pre-commit will validate automatically
```

**Benefits**:

- ✅ Catches syntax errors before they cause Neovim startup issues
- ✅ Ensures consistent code style across all config files
- ✅ Validates configs automatically on every commit
- ✅ No need to manually run linters/formatters

---

## New Neovim-Specific Recommendations

### Essential Neovim Plugins

1. **Plugin Manager**: `folke/lazy.nvim` (modern, fast, Lua-based)
   - Replace Vundle

2. **LSP**: `neovim/nvim-lspconfig` (built-in LSP client)
   - Replaces ALE for language features
   - Replaces jedi-vim

3. **Mason**: `williamboman/mason.nvim` + `williamboman/mason-lspconfig.nvim` (LSP/DAP/linter/formatter installer)
   - Easy installation of language servers (including lua-language-server)
   - Manages LSP servers, DAP adapters, linters, and formatters
   - `mason-lspconfig.nvim` automatically configures LSP servers installed via Mason
   - See [Why Use mason.nvim?](#why-use-masonnvim) section below for detailed advantages

4. **Autocompletion**: `hrsh7th/nvim-cmp` + sources
   - Modern completion framework
   - Better than Vim's built-in completion
   - **Recommended sources**: `hrsh7th/cmp-buffer`, `hrsh7th/cmp-path`, `hrsh7th/cmp-nvim-lsp`, `saadparwaiz1/cmp_luasnip`

5. **Treesitter**: `nvim-treesitter/nvim-treesitter`
   - Better syntax highlighting
   - Better folding
   - Better text objects

6. **File Explorer**: `nvim-tree/nvim-tree.lua` (optional, replaces vim-vinegar)
   - Modern file tree

7. **Telescope**: `nvim-telescope/telescope.nvim`
   - Better than FZF integration
   - Fuzzy finder, grep, etc.

8. **Which-Key**: `folke/which-key.nvim`
   - Shows available keybindings

9. **Commenting**: `numToStr/Comment.nvim`
   - Better commenting plugin

### Language-Specific Plugins (Based on Your Stack)

#### Python

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **Pyrefly** (LSP) | New (Meta project) | ✅ Actively maintained | 2025 | ⭐⭐⭐⭐⭐ **Highly Recommended** - Extremely fast, best for large codebases |
| **pyright** (LSP) | ~15k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Widely used, reliable |
| **jedi-language-server** (LSP) | ~1k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐ **Good** - Python-based, similar to jedi-vim |
| **stevearc/conform.nvim** (Formatting) | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Unified formatter, supports black/isort |
| **nvim-neotest/neotest** | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Unified testing framework |
| **nvim-neotest/neotest-python** | ~200+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Python test integration |
| **mfussenegger/nvim-dap** | ~3k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Universal debugging |
| **mfussenegger/nvim-dap-python** | ~500+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Python debugging support |

#### TypeScript/React/Vue

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **typescript-language-server** (LSP) | ~1k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Official TypeScript LSP |
| **@vue/language-server** (LSP) | ~500+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Official Vue LSP |
| **stevearc/conform.nvim** (Formatting) | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Supports Prettier |
| **windwp/nvim-ts-autotag** | ~1k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Auto-close JSX/HTML tags |
| **nvim-neotest/neotest-jest** | ~100+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Jest test integration |
| **marilari88/neotest-vitest** | ~50+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Vitest test integration |

#### Go

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **gopls** (LSP) | Official Go tool | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Official Go LSP |
| **ray-x/go.nvim** | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Enhanced Go tools, test running |
| **rouge8/neotest-go** | ~100+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Go test integration |
| **leoluz/nvim-dap-go** | ~200+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Go debugging support |

#### Rust

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **rust-analyzer** (LSP) | Official Rust tool | ✅ Actively maintained | Daily updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Official Rust LSP |
| **simrat39/rust-tools.nvim** | ~2k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Enhanced Rust features, inlay hints |
| **rouge8/neotest-rust** | ~50+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Rust test integration |

#### DevOps Tools

##### Terraform

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **terraform-ls** (LSP) | HashiCorp official | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Official Terraform LSP |
| **stevearc/conform.nvim** (Formatting) | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Supports terraform fmt |

##### Kubernetes

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **yamlls** (LSP) | ~500+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - YAML/K8s manifest support |

### General Productivity Plugins

| Plugin | GitHub Stars | Maintenance Status | Last Activity | Recommendation |
| --- | --- | --- | --- | --- |
| **windwp/nvim-autopairs** | ~2.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Auto-close brackets, integrates with cmp |
| **kylechui/nvim-surround** | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Lua-based, better than vim-surround |
| **lewis6991/gitsigns.nvim** | ~3.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Replace vim-gitgutter, Lua-based, faster |
| **folke/trouble.nvim** | ~2.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Better diagnostics window |
| **aznhe21/actions-preview.nvim** | ~500+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Preview LSP code actions with diffs, supports telescope/minipick/snacks/nui |
| **lukas-reineke/indent-blankline.nvim** | ~3.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐⭐ **Highly Recommended** - Visual indent guides |
| **norcalli/nvim-colorizer.lua** | ~1.5k+ | ✅ Actively maintained | Regular updates | ⭐⭐⭐⭐ **Recommended** - Replace colorizer, preview colors |

---

## Adding AI Assistance: avante.nvim + copilot.lua

### Plugin Information

| Property | Value |
| --- | --- |
| **GitHub Stars** | ~16k+ |
| **Maintenance Status** | ✅ Actively maintained |
| **Last Activity** | Regular updates |
| **Recommendation** | ⭐⭐⭐⭐⭐ **Highly Recommended** |

### avante.nvim Overview

`avante.nvim` is an AI-powered code assistance plugin that integrates directly into Neovim, providing interactive code suggestions and project-specific instructions.

### Installation (with lazy.nvim)

```lua
{
  "yetone/avante.nvim",
  build = vim.fn.has("win32") ~= 0
      and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
  event = "VeryLazy",
  version = false,
  opts = {
    instructions_file = "avante.md",
    provider = "claude",  -- or "moonshot"
    providers = {
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        timeout = 30000,
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
      moonshot = {
        endpoint = "https://api.moonshot.ai/v1",
        model = "kimi-k2-0711-preview",
        timeout = 30000,
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 32768,
        },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    "HakonHarnes/img-clip.nvim",
    "zbirenbaum/copilot.lua",
    "stevearc/dressing.nvim",
    "folke/snacks.nvim",
  },
}
```

### copilot.lua Installation

```lua
-- In plugins/ai.lua
{
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = { enabled = true },
      panel = { enabled = true },
    })
  end,
}
```

### Configuration Notes

**avante.nvim**:

- Requires API key setup (Claude or Moonshot)
- Creates `avante.md` file in project root for project-specific instructions
- Provides project-aware AI assistance (interactive, chat-like)

**copilot.lua**:

- Requires GitHub Copilot subscription
- Provides inline autocomplete suggestions as you type
- Works seamlessly alongside avante.nvim

**Using Both Together**:

- **avante.nvim** for complex tasks, refactoring, understanding codebases
- **copilot.lua** for quick inline completions while typing
- They complement each other perfectly without conflicts

### avante.nvim vs copilot.lua - Detailed Comparison

**avante.nvim**:

- **Purpose**: AI-powered code assistance with project-specific instructions
- **Features**:
  - Interactive code suggestions with full project context
  - Reads entire codebase for better understanding
  - Project-specific instructions file (`avante.md`)
  - Can analyze multiple files simultaneously
  - More like Cursor AI IDE - project-aware assistance
  - Chat-like interface for code discussions
  - Can generate code based on project patterns
- **Providers**: Claude, Moonshot (requires API keys)
- **Use case**: Complex refactoring, project-wide code generation, understanding large codebases
- **When to use**: When you need AI that understands your entire project structure and coding patterns

**copilot.lua**:

- **Purpose**: GitHub Copilot integration
- **Features**:
  - **Inline autocomplete** - Suggestions appear as you type (like VS Code Copilot)
  - Real-time code completion
  - Works with GitHub Copilot subscription
  - Lightweight, fast suggestions
  - Context-aware but focused on current file/line
- **Use case**: Quick inline code suggestions while typing, traditional autocomplete experience
- **When to use**: When you want GitHub Copilot's inline suggestions as you type

**Key Differences**:

1. **Interaction Model**:
   - **avante.nvim**: Interactive, chat-like, you ask questions and get responses
   - **copilot.lua**: Passive, inline suggestions appear as you type

2. **Context Awareness**:
   - **avante.nvim**: Full project context, can read entire codebase
   - **copilot.lua**: Focused on current file and nearby context

3. **Use Cases**:
   - **avante.nvim**: Better for complex tasks, refactoring, understanding codebases
   - **copilot.lua**: Better for quick inline completions while coding

4. **Can you get all copilot.lua features with avante.nvim?**
   - **Partially**: avante.nvim can provide code suggestions, but it doesn't have the same **inline autocomplete** experience as copilot.lua
   - **avante.nvim** is more interactive (you request help), while **copilot.lua** is more passive (suggestions appear automatically)
   - If you want the traditional "type and get suggestions" experience, you'll need copilot.lua
   - If you're okay with a more interactive, project-aware AI assistant, avante.nvim alone might be sufficient

**Recommendation**: **Use both together** - They complement each other perfectly:

- **avante.nvim** for complex tasks, refactoring, and understanding large codebases
- **copilot.lua** for quick inline autocomplete while typing
- They work seamlessly together without conflicts

---

## Migration Steps

### Phase 1: Setup Neovim Structure

1. **Create Neovim config directory in your dotfiles**:

   ```bash
   mkdir -p nvim
   ```

2. **Create symlink to Neovim config location**:

   ```bash
   ln -s ~/dotfiles/nvim ~/.config/nvim
   ```

   This allows you to keep your Neovim config in your dotfiles repository while Neovim expects it at `~/.config/nvim/`.

3. **Install plugin manager** (lazy.nvim):

   ```bash
   git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
     --branch=stable ~/.local/share/nvim/lazy/lazy.nvim
   ```

4. **Create basic `init.lua`** in your `nvim/` directory:

   ```lua
   -- Bootstrap lazy.nvim
   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
   if not vim.loop.fs_stat(lazypath) then
     vim.fn.system({
       "git",
       "clone",
       "--filter=blob:none",
       "https://github.com/folke/lazy.nvim.git",
       "--branch=stable",
       lazypath,
     })
   end
   vim.opt.rtp:prepend(lazypath)

   -- Load core settings
   require("core")

   -- Load plugins
   require("plugins")

   -- Load custom configs
   require("config")
   ```

5. **Validate your config files**:

   ```bash
   # From dotfiles root directory, validate all Lua files
   make lint-fix-lua
   ```

   This ensures your configs are valid Lua and properly formatted. The pre-commit hook will also validate automatically on commit.

### Phase 2: Migrate Core Settings

1. **Create `nvim/lua/core/` directory** (for core settings)
2. **Create `nvim/lua/config/` directory** (for custom configs like hardtime)
3. **Convert each `.vim/settings/*.vim` file to Lua**:
   - `luki-appearance.vim` → `core/options.lua` (or `core/appearance.lua`)
   - `luki-filetypes.vim` → `config/filetypes.lua`
   - `luki-folding.vim` → `core/folding.lua` (or use treesitter)
   - `luki-indentation.vim` → `config/indentation.lua`
   - `luki-movement.vim` → `core/keymaps.lua`
   - `luki-searching.vim` → `core/options.lua` (search settings)
   - `luki-splitting.vim` → `core/keymaps.lua` (window navigation)
   - `luki-stripping.vim` → `config/utils.lua` (whitespace stripping)
   - `luki-utils.vim` → `config/utils.lua`
   - `a_luki-leader_key.vim` → `core/keymaps.lua` (leader key mappings)

4. **Create custom implementations**:
   - `config/hardtime.lua` - Custom hardtime replacement (see Custom Hardtime Implementation section)

5. **Create `nvim/lua/core/init.lua`** to load all core settings

### Phase 3: Migrate Plugins

1. **Create `nvim/lua/plugins/` directory**

2. **Create plugin files**:
   - `plugins/core.lua` - Essential plugins (lsp, treesitter, cmp)
   - `plugins/colorschemes.lua` - Colorschemes
   - `plugins/dev.lua` - Development tools
   - `plugins/editors.lua` - Editor enhancements
   - `plugins/python.lua` - Python-specific (including Pyrefly LSP config)
   - `plugins/utils.lua` - Utilities
   - `plugins/webdev.lua` - Web development
   - `plugins/ai.lua` - avante.nvim and copilot.lua configuration

3. **Install Language Servers**:
   - **Pyrefly** (recommended): Add `"pyrefly"` to `ensure_installed` in `mason-lspconfig` setup
   - **Alternative**: System installation - `pip install pyrefly` (ensure it's on PATH)
   - **Pyright** (alternative): Add `"pyright"` to `ensure_installed` in `mason-lspconfig` setup, or `npm install -g pyright`
   - Install other LSPs as needed for your languages (preferably via `ensure_installed` in mason-lspconfig)

4. **Migrate plugin configurations**:
   - Convert Vimscript plugin configs to Lua
   - Use Neovim alternatives where recommended
   - Configure Pyrefly LSP in `plugins/python.lua` (see jedi-vim migration section)

5. **Validate your config files** after adding plugins:

   ```bash
   make lint-fix-lua
   ```

### Phase 4: Migrate Snippets

1. **Convert UltiSnips snippets to LuaSnip format**:
   - `~/.vim/ultisnips/*.snippets` → `nvim/lua/snippets/`
   - Or use VSCode JSON format (easier migration)

### Phase 5: Testing

1. **Test each plugin** individually
2. **Verify keybindings** work correctly
3. **Test language servers** (Python, JavaScript, etc.)
4. **Verify colorscheme** works
5. **Test AI assistance** integration (avante.nvim + copilot.lua)

---

## Keybindings Migration

**Leader Key**: `,` (comma) - defined in `a_luki-leader_key.vim`

All your current keybindings should work, but verify:

### Function Keys

- `<F2>` - Paste toggle
- `<F4>` - Tagbar (→ AerialToggle)
- `<F7>` - Lint (→ nvim-lint)
- `<F8>` - Format (→ conform.nvim)

### Leader Key Mappings (`,`)

- `<leader>]` - Next buffer
- `<leader>[` - Previous buffer
- `<leader><space>` - Clear search highlight
- `<leader>o` - Execute current file with Python
- `<leader>q` - Snippet expand (→ LuaSnip)
- `<leader>w` - Snippet backward (→ LuaSnip)
- `<leader>t` - List snippets (→ LuaSnip)
- `<leader>R` - REST console (remove - using Bruno now)
- `<leader>s` - Strip whitespace
- `<leader>z` - isort fix (→ conform.nvim)
- `<leader>vp` - Vimux prompt
- `<leader>vl` - Vimux last command
- `<leader>vi` - Vimux inspect
- `<leader>h/j/k/l>` - Window movement
- `<leader>g` - Goto assignments (jedi-vim → LSP)
- `<leader>d` - Goto definitions (jedi-vim → LSP)
- `<leader>r` - Rename (jedi-vim → LSP)
- `<leader>n` - Show usages (jedi-vim → LSP)

### Other Mappings

- `<C-h/j/k/l>` - Window navigation
- `<space>` - Toggle fold (za)
- `\` - Emmet trigger, vimtex imap leader
- `K` - Show documentation (jedi-vim → LSP hover)
- `<C-Space>` - Completion (jedi-vim → nvim-cmp)

---

## Your Preferences (Answered)

Based on your responses, here are the decisions made for this migration:

1. **Plugin Manager**: ✅ `lazy.nvim` (recommended)

2. **Python LSP**: ✅ `pyrefly` - Extremely fast (1.85M+ lines/second), from Meta, best for large codebases

3. **Statusline**: ✅ `lualine.nvim` - Modern, Lua-based statusline

4. **File Explorer**: ✅ `nvim-tree.lua` - Modern file tree explorer

5. **Fuzzy Finder**: ✅ `telescope.nvim` - Powerful fuzzy finder

6. **AI Assistance**: ✅ **Both selected**
   - **avante.nvim** - Project-aware AI assistance (interactive, chat-like)
   - **copilot.lua** - Traditional GitHub Copilot inline autocomplete
   - **Note**: They work well together - avante.nvim for complex tasks and project understanding, copilot.lua for quick inline completions while typing

7. **Lua Linters & Formatters**: ✅ **Selected**
   - **selene** - Fast Lua linter (written in Rust)
   - **lua-language-server** - Via mason.nvim + nvim-lspconfig
   - **stylua** - Fast Lua formatter (written in Rust)
   - **Note**: Requires `mason.nvim` plugin for easy lua-language-server installation

8. **Migration Approach**: ✅ **Side-by-side with Vim** - Using `nvim/` directory in dotfiles, symlinked to `~/.config/nvim/`
   - This allows you to:
     - Keep Vim working unchanged
     - Test Neovim configuration gradually
     - Update aliases/workflow as needed
     - Switch between Vim and Neovim easily

---

## Recommended Plugin Installation Priority

### Phase 1: Essential (Install First)

1. `folke/lazy.nvim` - Plugin manager
2. `williamboman/mason.nvim` - LSP/DAP/linter/formatter installer
3. `williamboman/mason-lspconfig.nvim` - Auto-configure LSP servers from Mason
4. `neovim/nvim-lspconfig` - LSP client
5. `hrsh7th/nvim-cmp` + sources - Autocompletion
6. `nvim-treesitter/nvim-treesitter` - Syntax highlighting
7. `nvim-telescope/telescope.nvim` - Fuzzy finder
8. `windwp/nvim-autopairs` - Auto-pairs
9. `kylechui/nvim-surround` - Surround text objects
10. `numToStr/Comment.nvim` - Commenting

### Phase 2: Language Support (Based on Your Stack)

**Python:**

- `pyrefly` or `pyright` (LSP)
- `stevearc/conform.nvim` (formatting: black, isort)
- `nvim-neotest/neotest` + `nvim-neotest/neotest-python` (testing)
- `mfussenegger/nvim-dap` + `mfussenegger/nvim-dap-python` (debugging)

**TypeScript/React/Vue:**

- `typescript-language-server` (LSP)
- `@vue/language-server` (Vue LSP)
- `stevearc/conform.nvim` (formatting: prettier)
- `nvim-neotest/neotest` + `nvim-neotest/neotest-jest` or `marilari88/neotest-vitest`

**Go:**

- `gopls` (LSP)
- `ray-x/go.nvim` (enhanced Go tools)
- `nvim-neotest/neotest` + `rouge8/neotest-go`
- `mfussenegger/nvim-dap` + `leoluz/nvim-dap-go`

**Rust:**

- `rust-analyzer` (LSP)
- `simrat39/rust-tools.nvim` (enhanced Rust)
- `nvim-neotest/neotest` + `rouge8/neotest-rust`

**DevOps:**

- `terraform-ls` (Terraform LSP)
- `yamlls` (YAML/K8s LSP)
- Remove: `hashivim/vim-terraform`, `andrewstuart/vim-kubernetes` (not needed - LSP provides better features)

### Phase 3: Productivity Enhancements

1. `lewis6991/gitsigns.nvim` - Git signs (replace vim-gitgutter)
2. `folke/trouble.nvim` - Better diagnostics
3. `aznhe21/actions-preview.nvim` - Preview LSP code actions with diffs (replaces nvim-code-action-menu)
4. `folke/todo-comments.nvim` - TODO highlighting
5. `lukas-reineke/indent-blankline.nvim` - Indent guides
6. `folke/which-key.nvim` - Keybinding helper
7. `ThePrimeagen/harpoon` - Quick file navigation
8. `rmagatti/auto-session` - Session management
9. `folke/noice.nvim` - Modern UI (optional)

### Phase 4: Advanced Features

1. `yetone/avante.nvim` - AI code assistance (project-aware)
2. `zbirenbaum/copilot.lua` - GitHub Copilot inline autocomplete
3. `nvim-tree/nvim-tree.lua` or `stevearc/oil.nvim` - File explorer
4. `akinsho/toggleterm.nvim` - Integrated terminal
5. `aznhe21/actions-preview.nvim` - Preview LSP code actions with diffs (replaces nvim-code-action-menu)

### Quick Start Configuration Example

```lua
-- Minimal setup for your stack
return {
  -- Essential
  { "folke/lazy.nvim" },
  { "williamboman/mason.nvim" },  -- LSP/DAP/linter/formatter installer
  { "williamboman/mason-lspconfig.nvim" },  -- Auto-configure LSP servers
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "nvim-treesitter/nvim-treesitter" },
  { "nvim-telescope/telescope.nvim" },

  -- Colorscheme
  { "navarasu/onedark.nvim" },  -- onedark colorscheme (replaces onedark.vim)

  -- Language support
  { "simrat39/rust-tools.nvim" },  -- Rust
  { "ray-x/go.nvim" },  -- Go
  { "stevearc/conform.nvim" },  -- Formatting

  -- Testing
  { "nvim-neotest/neotest" },
  { "nvim-neotest/neotest-python" },
  { "nvim-neotest/neotest-go" },
  { "nvim-neotest/neotest-rust" },

  -- Productivity
  { "lewis6991/gitsigns.nvim" },
  { "folke/trouble.nvim" },
  { "aznhe21/actions-preview.nvim" },  -- Preview LSP code actions with diffs
  { "windwp/nvim-autopairs" },
  { "kylechui/nvim-surround" },

  -- AI
  { "yetone/avante.nvim" },  -- Project-aware AI assistance
  { "zbirenbaum/copilot.lua" },  -- GitHub Copilot inline autocomplete
}
```

---

## Language Servers to Install

### Python Language Servers

- **Pyrefly** ([pyrefly.org](https://pyrefly.org/)) - Python LSP (recommended, extremely fast)
  - **Installation (Recommended)**: Add `"pyrefly"` to `ensure_installed` in `mason-lspconfig` setup
  - **Installation (Alternative)**: System installation - `pip install pyrefly` (ensure it's on PATH)
  - **Project setup**: `pyrefly init` (optional, creates `pyrefly.toml` config file)
  - **Best for**: Large Python codebases, fast type checking (1.85M+ lines/second)
  - **Neovim setup**: See [official Neovim guide](https://pyrefly.org/en/docs/IDE/#neovim) for detailed instructions
- **Pyright** - Alternative Python LSP (if not using Pyrefly)
  - Installation: `npm install -g pyright`

### TypeScript/JavaScript

- **typescript-language-server** - TypeScript/JavaScript LSP
  - Installation: `npm install -g typescript-language-server typescript`
- **vue-language-server** - Vue.js LSP
  - Installation: `npm install -g @vue/language-server`

### Go Language Servers

- **gopls** - Official Go language server
  - Installation: `go install golang.org/x/tools/gopls@latest`

### C/C++

- **clangd** - LLVM-based C/C++ language server
  - Installation: Usually via package manager or LLVM installation
  - macOS: `brew install llvm` (includes clangd)

### Rust Language Servers

- **rust-analyzer** - Rust language server
  - Installation: Usually via rustup or package manager
  - Or: `rustup component add rust-analyzer`

### DevOps

- **terraform-ls** - Terraform language server
  - Installation: `brew install hashicorp/tap/terraform-ls` or download from releases
- **yamlls** - YAML language server (for Kubernetes manifests)
  - Installation: `npm install -g yaml-language-server`

---

## Next Steps

1. Review this migration plan
2. Answer the questions above
3. I can help create the actual Neovim configuration files
4. Test the migration step-by-step

---

## Resources

- [Neovim Lua Guide](https://github.com/nanotee/nvim-lua-guide)
- [lazy.nvim Documentation](https://github.com/folke/lazy.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [avante.nvim](https://github.com/yetone/avante.nvim) - Project-aware AI assistance
- [copilot.lua](https://github.com/zbirenbaum/copilot.lua) - GitHub Copilot inline autocomplete
- [Pyrefly](https://pyrefly.org/) - Fast Python type checker and language server
- [Neotest](https://github.com/nvim-neotest/neotest) - Testing framework
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) - Debugging framework
- [conform.nvim](https://github.com/stevearc/conform.nvim) - Formatting
- [actions-preview.nvim](https://github.com/aznhe21/actions-preview.nvim) - Preview LSP code actions with diffs
