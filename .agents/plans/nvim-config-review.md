# Neovim Configuration Review & Improvement Plan

## Context

Full audit of `nvim/` against `.agents/lua-styleguide.md`,
Neovim best practices, plugin version status, and internal
consistency. The config is well-structured with clean modular
separation, but has accumulated bugs, deprecated plugins, and
missed optimizations.

## Execution Strategy

**Execute tasks strictly one at a time, sequentially.**
Complete 1.1, verify, then move to 1.2, verify, then 1.3,
and so on. Each task must be fully implemented, linted, and
verified before starting the next. Propose a git commit
message after each task. Do not batch multiple tasks.

**Mark completed tasks** with `[DONE]` prefix in the heading
once implemented and verified.

---

## Phase 1: Critical Bugs (Must Fix)

### 1.1 [DONE] Broken glob patterns in `config/filetypes.lua`

**Files**: `nvim/lua/config/filetypes.lua`

Migrated from broken autocmd glob patterns to
`vim.filetype.add()` with Lua patterns. Also added missing
`.github/workflows/` pattern and fixed
`function M.setup()` style.

### 1.2 [DONE] `flake8` listed as Python formatter in `formatting.lua`

**Files**: `nvim/lua/plugins/formatting.lua` (line 39)

flake8 is a linter, not a formatter. Remove from Python
formatter function.

### 1.3 [DONE] Lualine requires noice at module parse time

**Files**: `nvim/lua/plugins/ui.lua` (lines 22-23)

**Detailed explanation**: The `opts` table is a plain Lua
table literal. When lazy.nvim processes specs via
`{ import = "plugins.ui" }`, it calls
`require("plugins.ui")` which executes the file. All
expressions inside the `opts` table evaluate at that moment,
including:

```lua
require("noice").api.status.mode.get,      -- evaluates NOW, not when lualine loads
cond = require("noice").api.status.mode.has, -- evaluates NOW
```

This stores function references, so `require("noice")` must
return a module where `api.status.mode.get` and `.has`
already exist. In practice, noice defines these at module
level, so `require("noice")` works even before `setup()`.
But this is fragile because:

1. It **eagerly loads noice** during spec evaluation
   (before any VeryLazy event)
2. It depends on noice's internal module structure being
   available pre-setup
3. If noice ever moves these to post-setup initialization,
   this silently breaks
4. It defeats lazy loading: noice loads at spec parse time,
   not at VeryLazy

The `dependencies = { "folke/noice.nvim" }` does NOT help
here. Dependencies control plugin load order, but `opts`
evaluation happens during spec collection, before any
plugin loads.

**Fix**: Wrap in functions to defer the `require()`:

```lua
{
    function()
        return require("noice").api.status.mode.get()
    end,
    cond = function()
        return require("noice").api.status.mode.has()
    end,
    color = { fg = "DarkOrange" },
},
```

### 1.4 [DONE] Mason org mismatch

**Files**: `nvim/lua/plugins/dependencies.lua` (line 5)

Change `"williamboman/mason.nvim"` to
`"mason-org/mason.nvim"`.

### 1.5 [DONE] Duplicate Docker LSP in `lsp.lua`

**Files**: `nvim/lua/plugins/lsp.lua` (lines 58-59)

`docker_language_server` is the mason-lspconfig v2 name.
`dockerls` is legacy. Remove `dockerls`.

### 1.6 [DONE] `mason-tool-installer` lazy-loads via `cmd` but expects `run_on_start`

**Files**: `nvim/lua/plugins/dependencies.lua`

Change `cmd = {...}` to `event = "VeryLazy"` so auto-install
actually triggers.

---

## Phase 2: High Priority Improvements

### 2.1 [DONE] Missing `vim.opt.number = true`

**Files**: `nvim/lua/core/options.lua`

**Yes, confirmed.** The behavior of `relativenumber`
without `number`:

- `number = false, relativenumber = true`: current line
  shows **0**, others show relative distance
- `number = true, relativenumber = true`: current line
  shows **absolute line number**, others show relative
  distance

With only `relativenumber = true`, the current line
displays `0`. This is almost never intentional. The
standard setup is both enabled together.

### 2.2 [DONE] `:n!`/`:prev!` are arglist commands, not buffer commands

**Files**: `nvim/lua/core/keymaps.lua` (lines 2-3)

**Detailed explanation**: Vim/Neovim has three separate
navigation concepts:

**Navigation concepts in Vim/Neovim:**

- **Argument list**: `:next` (`:n`) / `:previous`
  (`:prev`). Navigates files passed on CLI:
  `nvim a.lua b.lua c.lua`
- **Buffer list**: `:bnext` (`:bn`) / `:bprevious`
  (`:bp`). Navigates all open buffers.
- **Tab pages**: `:tabnext` (`:tabn`) / `:tabprevious`
  (`:tabp`). Navigates tab pages (what bufferline shows).

`:n!` is shorthand for `:next!` (force, even with unsaved
changes). It navigates the **argument list**, which is only
populated when you open nvim with multiple files. If you
opened `nvim single_file.lua`, then `:n!` errors with
`E163: There is only one file to edit`.

Since `bufferline.nvim` is configured with `mode = "tabs"`
(showing tab pages, not buffers), the keymaps should match
what's visually displayed:

**Fix**: Change to tab navigation to match bufferline's
visual display:

```lua
vim.keymap.set("n", "<leader>]",
    "<cmd>tabnext<cr>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>[",
    "<cmd>tabprevious<cr>", { desc = "Prev tab" })
```

Or if buffer navigation is desired (e.g., switching
bufferline to `mode = "buffers"`):

```lua
vim.keymap.set("n", "<leader>]",
    "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>[",
    "<cmd>bprevious<cr>", { desc = "Prev buffer" })
```

### 2.3 [DONE] Harpoon v1 to v2 migration

**Files**: `nvim/lua/plugins/productivity.lua` (lines
80-126)

Harpoon v1 (`master` branch) is frozen. All development on
`harpoon2` branch.

**v1 (current) vs v2 API side-by-side:**

```lua
-- ======================== V1 (current) ========================
{
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        {
            "<leader>mm",
            function() require("harpoon.mark").add_file() end,
            desc = "Harpoon: Add file",
        },
        {
            "<leader>mo",
            function() require("harpoon.ui").toggle_quick_menu() end,
            desc = "Harpoon: Toggle menu",
        },
        {
            "<leader>m1",
            function() require("harpoon.ui").nav_file(1) end,
            desc = "Harpoon: File 1",
        },
        -- ... m2, m3, m4
    },
}

-- ======================== V2 (target) =========================
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        {
            "<leader>mm",
            function() require("harpoon"):list():add() end,
            desc = "Harpoon: Add file",
        },
        {
            "<leader>mo",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end,
            desc = "Harpoon: Toggle menu",
        },
        {
            "<leader>m1",
            function() require("harpoon"):list():select(1) end,
            desc = "Harpoon: File 1",
        },
        {
            "<leader>m2",
            function() require("harpoon"):list():select(2) end,
            desc = "Harpoon: File 2",
        },
        {
            "<leader>m3",
            function() require("harpoon"):list():select(3) end,
            desc = "Harpoon: File 3",
        },
        {
            "<leader>m4",
            function() require("harpoon"):list():select(4) end,
            desc = "Harpoon: File 4",
        },
    },
    config = function()
        require("harpoon"):setup()
    end,
}
```

Key API changes:

- `require("harpoon.mark").add_file()` ->
  `require("harpoon"):list():add()`
- `require("harpoon.ui").toggle_quick_menu()` ->
  `harpoon.ui:toggle_quick_menu(harpoon:list())`
- `require("harpoon.ui").nav_file(N)` ->
  `require("harpoon"):list():select(N)`
- v2 adds `:list():prev()` / `:list():next()` for
  sequential navigation
- v2 requires `harpoon:setup()` call in config

### 2.4 [DONE] Remove `FixCursorHold.nvim`

**Files**: `nvim/lua/plugins/testing.lua` (line 7)

The CursorHold bug was fixed in Neovim 0.8. Remove from
neotest dependencies.

### 2.5 [DONE] Remove `Comment.nvim`

**Files**: `nvim/lua/plugins/core.lua` (lines 100-104)

Neovim 0.10+ has built-in `gc`/`gcc` with treesitter
support. With `opts = {}`, the plugin adds nothing.
Drop-in removal, same keymaps work natively.

### 2.6 [DONE] Replace `norcalli/nvim-colorizer.lua`

**Files**: `nvim/lua/plugins/editing.lua` (lines 14-34)

Unmaintained since ~2020. Replace with
`catgoose/nvim-colorizer.lua`. Also fix: `opts = {}` is
silently ignored when `config` function is present
(lazy.nvim only runs one or the other).

### 2.7 [DONE] DAP keymaps won't trigger lazy loading

**Files**: `nvim/lua/plugins/debugging.lua`

Move keymaps to `keys` spec. Add missing `step_out`.

### 2.8 [DONE] `nvim-autopairs` wrong event

**Files**: `nvim/lua/plugins/editing.lua` (line 39)

Change `event = "InsertCharPre"` to
`event = "InsertEnter"`. `InsertCharPre` fires when a
character is about to be typed, so the plugin only loads
AFTER the first keystroke in insert mode. The first `(`
typed won't auto-close because autopairs hasn't initialized
yet.

### 2.9 [DONE] `actions-preview.nvim` has no lazy loading

**Files**: `nvim/lua/plugins/productivity.lua` (lines 38-48)

**Detailed explanation**: The spec has no lazy-loading
trigger (`event`, `cmd`, `keys`, `ft`). In lazy.nvim,
plugins without any trigger load at startup (unless
`defaults.lazy = true` is set globally, which it is not in
your config). The keymap is defined inside `config`, which
runs at startup since the plugin loads immediately.

**Fix**: Move the keymap to a `keys` spec, which both
registers the keymap AND makes it the lazy-loading trigger:

```lua
{
    "aznhe21/actions-preview.nvim",
    keys = {
        {
            "<leader>ca",
            function()
                require("actions-preview").code_actions()
            end,
            mode = { "v", "n" },
            desc = "Code Actions Preview",
        },
    },
}
```

Now the plugin only loads when `<leader>ca` is pressed for
the first time.

---

## Phase 3: Medium Priority Improvements

### 3.1 [DONE] Use `<cmd>` instead of `:` in keymap RHS

**Files**: `nvim/lua/core/keymaps.lua`

Change `:nohlsearch<cr>`, `:Ex<cr>`, `:n!<cr>`,
`:prev!<cr>` to `<cmd>` form.

### 3.2 [DONE] Add `silent = true` to normal-mode command keymaps

**Files**: `nvim/lua/core/keymaps.lua`

**Why**: When a keymap RHS uses `:command<cr>` form,
Neovim briefly displays the command text in the command
line area (e.g., flashing `:nohlsearch` at the bottom of
the screen). This is visual noise. `silent = true`
suppresses this display.

Note: This is orthogonal to 3.1. Even with `<cmd>` form,
adding `silent = true` is good practice as it also
suppresses any `:echo` output from the command. With
`<cmd>`, the command line flash is already eliminated, so
`silent = true` becomes less critical but still prevents
edge-case noise from commands that produce output.

**Recommendation**: Do 3.1 first (`<cmd>` migration). If
you do that, `silent = true` becomes optional but still a
good defensive default for any keymap running an Ex command.

### 3.3 [DONE] Use `1` not `true` for netrw disable

**Files**: `nvim/lua/core/options.lua` (lines 40-41)

**Why it's non-standard**: This idiom comes from Vimscript
where `let g:loaded_netrw = 1` was the only way to write it
(Vimscript had no boolean type until patch 7.4.1154). Every
piece of documentation uses the number `1`:

- `:help netrw-noload` says `let g:loaded_netrwPlugin = 1`
- nvim-tree's README: `vim.g.loaded_netrw = 1`
- LazyVim, NvChad, kickstart.nvim all use `1`

Using `true` works (Lua boolean is truthy in Vimscript
context), but anyone reading the config who knows the
convention will pause and wonder if it's intentional or a
mistake.

### 3.4 [DONE] `nvim-tree` contradictory `lazy = false` + `cmd`/`keys`

**Files**: `nvim/lua/plugins/ui.lua` (lines 49-57)

**Detailed explanation**: In lazy.nvim, `lazy = false`
means "load this plugin during startup." The `cmd` and
`keys` fields serve dual purposes:

1. **Lazy-loading triggers**: When to load the plugin
   (irrelevant when `lazy = false`)
2. **Registration**: Create keymaps and command aliases

When `lazy = false`, purpose #1 is dead. Purpose #2 still
works, but it's misleading: someone reading the code thinks
the plugin lazy-loads via commands when it actually loads
at startup.

**Two clean approaches:**

- **Option A** (recommended): Remove `lazy = false`, keep
  `cmd`/`keys`. nvim-tree doesn't need to load at startup.
  It should load when you first open it (`<leader>e`) or
  run `:NvimTreeToggle`. The `:Explore`/`:Ex` custom
  commands defined in `config` will also be registered at
  that time.
- **Option B**: Keep `lazy = false`, remove `cmd`, move
  keymaps into `config` function.

Option A is better because it improves startup time.

### 3.5 [DONE] `venv-selector.nvim` contradictory `lazy = false` + `ft`

**Files**: `nvim/lua/plugins/python.lua` (lines 14-15)

Same issue. Remove `lazy = false` to properly lazy-load
via `ft = "python"`.

### 3.6 [DONE] Remove Telescope `branch = "0.1.x"` pin from venv-selector

**Files**: `nvim/lua/plugins/python.lua` (line 10)

**Current state of Telescope**: The default branch on
GitHub is still `master`, but telescope has been evolving.
The `0.1.x` branch was the recommended stable branch for a
long time. However, `master` is now stable and 0.1.x
receives only critical fixes. The lazy-lock.json confirms
your main telescope install is already on `0.1.x`
(`"branch": "0.1.x"`).

The problem here is specifically in `python.lua` where
`venv-selector.nvim` declares telescope as a dependency
with `branch = "0.1.x"`:

```lua
dependencies = {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",   -- <-- This pin
    },
},
```

This creates a version conflict if your main telescope
spec ever moves to master. Remove the `branch` pin from the
dependency declaration; let the main telescope spec in
`core.lua` control the branch. Dependency declarations
should not override the primary spec's branch.

### 3.7 [DONE] Treesitter: remove contradictory `event` when `lazy = false`

**Files**: `nvim/lua/plugins/core.lua` (lines 7-9)

**From nvim-treesitter README**: "This plugin does not
support lazy-loading." The recommended spec is:

```lua
{
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
}
```

Your config already uses `branch = "main"` and
`lazy = false`, which is correct. The
`event = { "BufReadPost", "BufNewFile" }` alongside
`lazy = false` is dead code. `lazy = false` loads the
plugin at startup, before any buffer events fire. Remove
the `event` field.

### 3.8 [DONE] Python linters: ruff + flake8

**Files**: `nvim/lua/plugins/linting.lua` (line 12)

**Acknowledged**: You intentionally run both because flake8
runs plugins not supported by ruff. **No change needed.**
Consider adding a comment explaining this to prevent future
reviewers (or AI agents) from flagging it as redundant.

### 3.9 [DONE] `lua_ls` workspace.library is expensive

**Files**: `nvim/lua/plugins/lsp.lua` (line 44)

**Detailed explanation**:
`vim.api.nvim_get_runtime_file("", true)` returns EVERY
file in the runtime path. With ~60 plugins, this can return
thousands of files. It executes synchronously during LSP
config setup (on `BufReadPre`), adding noticeable delay.

The purpose is to tell lua_ls about Neovim's runtime files
so it can provide completions for `vim.*` APIs and plugin
modules. But loading everything upfront is wasteful since
you only need types for modules you actually `require()`.

**`folke/lazydev.nvim`** solves this properly:

```lua
{
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    },
},
```

What lazydev does:

- Watches your `require()` calls and dynamically adds only
  the needed plugin libraries
- Provides `vim.uv` types via the luv library annotation
- Replaces manual `workspace.library` configuration
  entirely
- Only loads for Lua files (`ft = "lua"`)

Then simplify lua_ls config to just:

```lua
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
        },
    },
})
```

Remove the `workspace.library` block entirely; lazydev
handles it.

Also add `lazydev` as an nvim-cmp source with
`group_index = 0` (highest priority) for enhanced Lua
completions:

```lua
{ name = "lazydev", group_index = 0 },
```

### 3.10 Gitsigns has no keymaps

**Moved to Phase 5** (see 5.2). Keymap tasks grouped together
to coordinate prefix assignments and avoid conflicts.

### 3.11 Neotest keymaps

**Moved to Phase 5** (see 5.3). Keymap tasks grouped together
to coordinate prefix assignments and avoid conflicts.

### 3.12 [DONE] vim-pandoc conflicts with render-markdown.nvim

**Files**: `nvim/lua/plugins/editors.lua`,
`nvim/lua/plugins/ai.lua`

**Resolution**: Removed both `vim-pandoc` and
`vim-pandoc-syntax` entirely from `editors.lua`.
Expanded `render-markdown.nvim` opts with `indent`,
`completions.lsp`, and `nvim-web-devicons` dependency.

### 3.13 [DONE] Lint autocmd missing `desc` field

**Files**: `nvim/lua/plugins/linting.lua` (line 30)

Add `desc = "Run linters on buffer events."`.

### 3.14 [DONE] Guard against duplicate PATH prepending in `mise.lua`

**Files**: `nvim/lua/config/mise.lua`

### 3.15 [DONE] `"Makefile"` in FileType pattern is dead code

**Files**: `nvim/lua/config/indentation.lua` (line 20)

Change `pattern = { "make", "Makefile" }` to
`pattern = "make"`.

---

## Phase 4: Low Priority / Nice-to-Have

### 4.1 [DONE] Missing recommended options

**Files**: `nvim/lua/core/options.lua`

**`vim.opt.undofile = true`**: Neovim saves undo history to
`~/.local/state/nvim/undo/`. Without this, closing a buffer
loses all undo history permanently. With it, you can undo
changes from days ago. Neovim stores one undo file per
buffer, named by path hash. No cleanup needed; the files
are small and Neovim manages them.

**`vim.opt.signcolumn = "yes"`**: The sign column (left
gutter) dynamically appears when diagnostics/git signs
exist and disappears when they don't. This causes text to
shift 2 characters left/right, which is visually jarring
while typing. `"yes"` permanently reserves the column.
Cost: 2 characters of horizontal space. Benefit: zero text
jitter.

**`vim.opt.scrolloff = 8`**: Keeps 8 lines visible
above/below cursor when scrolling. Without this (default
0), the cursor can sit at the very top/bottom of the screen
with no context. Value 8 is a common choice that balances
context with usable viewport.

**`vim.opt.updatetime = 250`**: Controls the delay before
`CursorHold` event fires AND how often the swap file is
written. Default 4000ms (4 seconds) means:

- gitsigns updates gutter 4s after you stop moving
- LSP hover/signature only triggers after 4s idle
- swap file writes are delayed 4s

Reducing to 250ms makes everything feel much snappier. The
only cost is slightly more frequent disk writes (swap
file), which is negligible on modern storage.

### 4.2 [DONE] Replace `goyo.vim` with `zen-mode.nvim`

**Files**: `nvim/lua/plugins/editors.lua` (lines 28-37)

**Detailed comparison:**

**goyo.vim:**

- Language: Vimscript
- Maintenance: Infrequent (junegunn, last update 2021)
- Configuration: Limited (width, height, autocmds)
- Plugin integration: Manual via Goyo enter/leave
  autocmds
- Pairing: limelight.vim (also Vimscript)
- Window control: Centers text, hides UI

**zen-mode.nvim:**

- Language: Lua
- Maintenance: Active (folke)
- Configuration: Full Lua opts (window, plugins,
  on_open/on_close callbacks)
- Plugin integration: Native, auto-disables lualine,
  gitsigns, indent-blankline, bufferline, etc.
- Pairing: twilight.nvim (dims inactive code,
  treesitter-aware)
- Window control: Centers text, hides UI, controls
  width/height/backdrop
- snacks.nvim has `Snacks.zen()` but minimal;
  zen-mode.nvim is more configurable

**Proposed replacement:**

```lua
{
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
        {
            "<leader>G",
            "<cmd>ZenMode<cr>",
            desc = "Toggle Zen Mode (distraction-free)",
        },
    },
    opts = {
        window = {
            width = 80,
        },
        plugins = {
            gitsigns = { enabled = true },
        },
    },
},
```

### 4.3 [DONE] Rename `benmills/vimux` to `preservim/vimux`

**Files**: `nvim/lua/plugins/dev.lua`

### 4.4 Rustaceanvim configuration

**Files**: `nvim/lua/plugins/rust.lua`

**Proposed config with explanation:**

```lua
{
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- Plugin handles its own lazy loading.
    config = function()
        vim.g.rustaceanvim = {
            server = {
                on_attach = function(_, bufnr)
                    local function map(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, {
                            buffer = bufnr,
                            desc = desc,
                        })
                    end

                    -- Use clippy-enhanced hover instead of default K.
                    map("K", function()
                        vim.cmd.RustLsp({ "hover", "actions" })
                    end, "Rust hover actions")

                    -- Expand macro: shows the fully expanded version of
                    -- a macro invocation (critical for debugging proc macros).
                    map("<leader>rm", function()
                        vim.cmd.RustLsp("expandMacro")
                    end, "Expand macro recursively")

                    -- Open docs.rs page for the symbol under cursor.
                    map("<leader>rd", function()
                        vim.cmd.RustLsp("openDocs")
                    end, "Open docs.rs documentation")

                    -- Debug runnables: pick a target and launch DAP.
                    map("<leader>rD", function()
                        vim.cmd.RustLsp("debuggables")
                    end, "Debug Rust target")

                    -- Run tests for the function/module under cursor.
                    map("<leader>rt", function()
                        vim.cmd.RustLsp("testables")
                    end, "Run Rust tests")

                    -- Explain compiler error with rustc --explain.
                    map("<leader>re", function()
                        vim.cmd.RustLsp("explainError")
                    end, "Explain compiler error")

                    -- Smart join: Rust-aware line joining (handles
                    -- trailing commas, match arms, etc.).
                    map("<leader>rj", function()
                        vim.cmd.RustLsp("joinLines")
                    end, "Join lines (Rust-aware)")
                end,
                default_settings = {
                    ["rust-analyzer"] = {
                        -- Use clippy instead of cargo check for
                        -- linting. Catches more issues.
                        checkOnSave = {
                            command = "clippy",
                            extraArgs = { "--all-targets" },
                        },
                    },
                },
            },
            dap = {
                autoload_configurations = true,
            },
        }
    end,
}
```

Note: Inlay hints are enabled by default in Neovim 0.10+
via `vim.lsp.inlay_hint.enable()`. rustaceanvim respects
this. No need to configure them in rust-analyzer settings
unless you want to customize which hints appear.

### 4.5 Fugitive keymaps

**Moved to Phase 5** (see 5.4). Keymap tasks grouped together
to coordinate prefix assignments and avoid conflicts.

### 4.6 [DONE] Aerial telescope + lualine integration

**Files**: `nvim/lua/plugins/navigation.lua`

```lua
{
    "stevearc/aerial.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    cmd = { "AerialToggle", "AerialNext", "AerialPrev" },
    keys = {
        { "<F3>", "<cmd>AerialToggle<cr>", desc = "Toggle Aerial (Outline)" },
        {
            "<leader>fa",
            "<cmd>Telescope aerial<cr>",
            desc = "Search symbols (Aerial)",
        },
    },
    opts = {
        layout = {
            default_direction = "prefer_left",
            min_width = 30,
        },
        filter_kind = {
            "Class",
            "Constructor",
            "Enum",
            "Function",
            "Interface",
            "Method",
            "Module",
            "Struct",
        },
    },
    config = function(_, opts)
        require("aerial").setup(opts)
        -- Register telescope extension for symbol search.
        pcall(function()
            require("telescope").load_extension("aerial")
        end)
    end,
}
```

For lualine integration, add `"aerial"` to a section in
`ui.lua`:

```lua
lualine_c = { "filename", "aerial" },
```

This shows the current function/class name in the
statusline.

### 4.7 [DONE] Consistent `function M.setup()` style

**Files**: `nvim/lua/config/filetypes.lua`

**Best option**: `function M.setup()` is preferred for
three reasons:

1. **Stack traces**: Named functions show `M.setup` in
   error tracebacks. Anonymous functions
   (`M.setup = function()`) show `<anonymous>`, making
   debugging harder.
2. **Style guide**: The module pattern example in
   `.agents/lua-styleguide.md` section 4 explicitly uses
   `function M.setup()`.
3. **Community convention**: LuaRocks style guide, Neovim
   core, and most plugins use the named form.

Change `config/filetypes.lua` line 6 from
`M.setup = function()` to `function M.setup()`.

### 4.8 Move `-` keymap coupling

**Moved to Phase 5** (see 5.5). Keymap tasks grouped together
to coordinate prefix assignments and avoid conflicts.

### 4.9 [DONE] `after/ftplugin/` for indentation

**Files**: `nvim/lua/config/indentation.lua`

**Detailed explanation**: Neovim has a built-in
per-filetype mechanism. When a buffer's filetype is set to
`python`, Neovim automatically sources files in this order:

1. `ftplugin/python.lua` (or `.vim`) in runtime path
2. `after/ftplugin/python.lua` (runs AFTER all other
   ftplugin scripts)

The `after/` prefix ensures your settings override any
plugin defaults.

**Current approach** (autocmd in config/indentation.lua):

```lua
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.opt_local.tabstop = 4
        -- ...
    end,
})
```

**after/ftplugin approach** (create
`nvim/after/ftplugin/python.lua`):

```lua
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
```

**Trade-offs:**

| Aspect | Autocmd (current) | after/ftplugin |
| ------ | ----------------- | -------------- |
| Files | 1 central file | 1 file per filetype |
| Overview | All indentation in one place | Scattered across files |
| Mechanism | Manual autocmd | Built-in Neovim |
| Timing | When autocmd fires | Automatic on filetype set |
| Convention | Valid but manual | Idiomatic Neovim |

For 3 filetypes, the current autocmd approach is perfectly
fine. The after/ftplugin approach is more "Neovim-native"
but creates file scatter. **Recommendation**: Keep the
current approach unless you want to move other
filetype-specific settings (e.g., spell, textwidth) into
per-filetype files. Then after/ftplugin becomes a better
organizational choice.

### 4.10 nvim-cmp vs blink.cmp detailed comparison

**Files**: `nvim/lua/plugins/lsp.lua` (lines 79-201)

**Feature comparison:**

**nvim-cmp:**

- **Performance**: Pure Lua
- **Architecture**: Source-based; each source is a separate
  plugin (cmp-buffer, cmp-path, etc.)
- **Configuration**: Verbose; must configure each source,
  sorting, formatting, mapping separately
- **Snippet engine**: External (LuaSnip, vim-vsnip, etc.)
  Must configure snippet.expand
- **Copilot**: Via copilot-cmp plugin + custom sorting
  comparators
- **Emoji source**: cmp-emoji plugin
- **Formatting**: Manual format function with icons table
- **Community**: Mature (9.4k stars), huge ecosystem
- **Stability**: Battle-tested, rare breaking changes
- **Maintenance**: Slowing down

**blink.cmp:**

- **Performance**: Rust/Zig core for fuzzy matching and
  rendering. Measurably faster on large completion lists
- **Architecture**: Batteries-included; buffer, path,
  snippets, LSP built in. External sources via provider API
- **Configuration**: Simpler defaults; works well out of
  the box, customize what you need
- **Snippet engine**: Built-in native snippet support.
  LuaSnip optional
- **Copilot**: Via blink-copilot plugin or native Copilot
  virtual text
- **Emoji source**: Built-in emoji source
- **Formatting**: Built-in kind icons, customizable via
  opts
- **Community**: Growing fast (6.2k stars), endorsed by
  LazyVim
- **Stability**: Active development, occasional breaking
  changes
- **Maintenance**: Very active (folke-adjacent ecosystem)

**What migration looks like for your specific setup:**

Current (6 plugins + config):

- hrsh7th/nvim-cmp
- hrsh7th/cmp-buffer
- hrsh7th/cmp-emoji
- hrsh7th/cmp-path
- L3MON4D3/LuaSnip + rafamadriz/friendly-snippets +
  saadparwaiz1/cmp_luasnip
- zbirenbaum/copilot-cmp (with custom sorting comparators)

After migration (2 plugins):

- saghen/blink.cmp (includes buffer, path, emoji, snippets,
  LSP)
- fang2hou/blink-copilot (Copilot source for blink)

The 130-line nvim-cmp config would reduce to ~40 lines. The
custom KIND_ICONS table, MENU_ITEMS table, sorting
comparators, and snippet expand function all become
unnecessary.

**Recommendation**: This is a large change. Your current
setup works fine. Plan this as a dedicated migration when
you have time to test thoroughly. Not urgent but the
direction the ecosystem is heading.

### 4.11 Plenary.nvim sunset

**Files**: Multiple plugins depend on it

**Current status**: plenary.nvim's README states: "Critical
bugs will be addressed until 2026-06-30." After that date,
no maintenance.

**What plenary provides and what replaces it:**

| plenary feature | Neovim built-in replacement |
| --------------- | --------------------------- |
| `plenary.job` | `vim.system()` (Neovim 0.10+) |
| `plenary.path` | `vim.fs` module |
| `plenary.async` | Lua coroutines + `vim.uv` |
| `plenary.curl` | `vim.system({"curl", ...})` |
| `plenary.scandir` | `vim.fs.dir()`, `vim.fs.find()` |
| `plenary.filetype` | `vim.filetype` |

**Your plugins that depend on plenary:**

- telescope.nvim (heaviest user)
- harpoon (v1 and v2 both use it)
- todo-comments.nvim
- chezmoi.nvim
- neotest

**Migration path**: This resolves naturally. As plugins
update to drop plenary:

- telescope -> if you migrate to snacks.picker, plenary
  dependency goes away
- harpoon2 -> ThePrimeagen has discussed dropping plenary
  in future
- todo-comments -> folke will likely update
- chezmoi.nvim -> small dependency, easy to update

**No action needed now.** Monitor the June 2026 deadline.
The practical impact is that after that date, any bug in
plenary won't be fixed upstream, but it's mature enough
that critical bugs are unlikely.

### 4.12 [DONE] `lazyredraw = false` is the default

**Files**: `nvim/lua/core/options.lua` (line 10)

Either add comment explaining why or remove.

### 4.13 `chezmoi.nvim` keymap inside config

**Files**: `nvim/lua/plugins/chezmoi.lua`

Move `<leader>cz` to `keys` spec for proper lazy loading.

---

## Style Guide Compliance

- `init.lua` tabs vs 4 spaces (`nvim/init.lua`): Fix
  via `stylua`
- Inconsistent autocmd desc style (Multiple):
  Standardize to sentence case, no period
- `M.setup = function()` vs `function M.setup()`
  (`config/filetypes.lua`): Use `function M.setup()`
- Missing `desc` on lint autocmd
  (`plugins/linting.lua`): Add desc
- Emoji in code (`python.lua` line 40)
  (`plugins/python.lua`): Style guide says avoid

---

## Phase 5: Keymap Audit

All keymap additions grouped here to coordinate prefix
assignments and avoid conflicts. Existing prefix map:

| Prefix | Domain |
| ------ | ------ |
| `<leader>d*` | Debugging (DAP) |
| `<leader>x*` | Diagnostics / Trouble |
| `<leader>v*` | Vimux |
| `<leader>m*` | Harpoon marks |
| `<leader>f*` | Telescope find |
| `<leader>c*` | Code actions |
| `<leader>r*` | Rust (rustaceanvim) |
| `<leader>h*` | Git hunks (gitsigns) |
| `<leader>g*` | Git repo (fugitive) |
| `<leader>t*` | Tests (neotest) |

### 5.1 Keymap conflict audit

Before implementing 5.2-5.5, verify no collisions:

- `<leader>tb` (gitsigns toggle blame) conflicts with any
  `<leader>t*` neotest key -- use `<leader>tB` for blame
  toggle instead.
- `<leader>h` alone (window move left, `keymaps.lua:37`)
  gets a timeout delay once `<leader>h*` hunks exist.
  Low impact -- window moves rarely used vs hunk ops.
- `<leader>g*` (fugitive) must not collide with `<leader>gs`
  if gitsigns also uses that. Gitsigns uses `<leader>hs`
  for stage hunk, so `<leader>gs` is free for fugitive
  Git status.

### 5.2 Gitsigns keymaps

**Files**: `nvim/lua/plugins/ui.lua`

`opts = {}` makes gitsigns a read-only gutter. Add
`on_attach` for buffer-local keymaps using `<leader>h*`
prefix for hunks. Navigation (`]c`/`[c`) must be
diff-mode-aware (fall back to native `]c` in diff view).

```lua
opts = {
    on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
                buffer = bufnr,
                desc = desc,
            })
        end

        -- Navigation (diff-mode aware).
        map("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
            else
                gitsigns.nav_hunk("next")
            end
        end, "Jump to next hunk")
        map("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
            else
                gitsigns.nav_hunk("prev")
            end
        end, "Jump to previous hunk")

        -- Stage/reset.
        map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
        map("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected hunk")
        map("v", "<leader>hr", function()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected hunk")
        map("n", "<leader>hS", gitsigns.stage_buffer, "Stage entire buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "Reset entire buffer")
        map("n", "<leader>hu", gitsigns.undo_stage_hunk, "Undo stage hunk")

        -- Preview/inspect.
        map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
            gitsigns.blame_line({ full = true })
        end, "Blame line (full)")
        map("n", "<leader>tB",
            gitsigns.toggle_current_line_blame,
            "Toggle line blame")

        -- Diff.
        map("n", "<leader>hd", gitsigns.diffthis, "Diff against index")
        map("n", "<leader>hD", function()
            gitsigns.diffthis("~")
        end, "Diff against HEAD")

        -- Text object.
        map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select hunk")
    end,
},
```

Note: toggle blame moved to `<leader>tB` (capital B) to
avoid clash with neotest `<leader>t*` keys.

### 5.3 Neotest keymaps

**Files**: `nvim/lua/plugins/testing.lua`

Prefix `<leader>t*` for tests. Avoid `<leader>tB`
(gitsigns toggle blame). Use `keys` spec for lazy loading.

```lua
keys = {
    {
        "<leader>tn",
        function() require("neotest").run.run() end,
        desc = "Run nearest test",
    },
    {
        "<leader>tf",
        function() require("neotest").run.run(vim.fn.expand("%")) end,
        desc = "Run file tests",
    },
    {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest test",
    },
    {
        "<leader>ts",
        function() require("neotest").run.stop() end,
        desc = "Stop test run",
    },
    {
        "<leader>to",
        function() require("neotest").output.open({ enter = true }) end,
        desc = "Show test output",
    },
    {
        "<leader>tS",
        function() require("neotest").summary.toggle() end,
        desc = "Toggle test summary",
    },
},
config = function()
    require("neotest").setup({
        adapters = {
            require("neotest-python")({ dap = { justMyCode = false } }),
            require("neotest-go"),
        },
    })
end,
```

### 5.4 Fugitive keymaps

**Files**: `nvim/lua/plugins/git.lua`

Prefix `<leader>g*` for repo-level git ops. Gitsigns
uses `<leader>h*` for hunk-level ops -- no collision.

```lua
{
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    keys = {
        { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
        { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
        { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git diff split" },
        { "<leader>go", "<cmd>GBrowse<cr>", desc = "Open on remote" },
        {
            "<leader>go",
            "<cmd>GBrowse<cr>",
            mode = "v",
            desc = "Open selection on remote",
        },
        { "<leader>gw", "<cmd>Gwrite<cr>", desc = "Stage current file" },
        { "<leader>gx", "<cmd>Gread<cr>", desc = "Checkout current file" },
        {
            "<leader>gl",
            "<cmd>Git log --oneline %<cr>",
            desc = "Git log for file",
        },
    },
    cmd = { "Git", "Gdiffsplit", "GBrowse", "Gwrite", "Gread" },
    lazy = true,
},
```

### 5.5 Move `-` keymap coupling

**Files**: `nvim/lua/core/keymaps.lua`, `nvim/lua/plugins/ui.lua`

The `-` -> `:Ex` keymap in `keymaps.lua` depends on
nvim-tree loading (creates `:Ex` in its config). If
nvim-tree fails, `-` errors (netrw is disabled). The
`Ex`/`Explore` cmd stubs added in 3.4 reduce the risk,
but the coupling is still fragile.

**Fix**: Move `-` into nvim-tree's `keys` spec, remove
it from `keymaps.lua`:

```lua
-- In ui.lua nvim-tree keys spec:
{ "-", "<cmd>Ex<cr>", desc = "Explore current directory" },
```

This makes the keymap exist only after nvim-tree loads
(same place that creates `:Ex`). Remove corresponding
line from `core/keymaps.lua`.

---

## Verification Plan

After each phase:

1. `make lint-fix-lua` (selene + stylua)
2. Open nvim, run `:checkhealth`
3. `:Lazy` to verify all plugins load without errors
4. Test affected keymaps manually
5. Open a Python file: verify formatting, linting,
   venv-selector
6. Open a Markdown file: verify no pandoc/render-markdown
   conflict
7. `:Mason` to verify tools install correctly
8. `make all` for full lint/test pass
