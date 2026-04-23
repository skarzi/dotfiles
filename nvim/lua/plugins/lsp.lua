return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            require("mason").setup()

            vim.lsp.config("*", {
                capabilities = cmp_nvim_lsp.default_capabilities(),
            })

            vim.lsp.config("pyrefly", {
                root_dir = function(bufnr, on_dir)
                    local projects = require("config.projects")
                    if projects.should_disable_tools(bufnr) then
                        return
                    end
                    local root = vim.fs.root(bufnr, {
                        "pyproject.toml",
                        "setup.py",
                        "setup.cfg",
                        "requirements.txt",
                        ".git",
                    })
                    if root then
                        on_dir(root)
                    end
                end,
            })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        telemetry = { enable = false },
                    },
                },
            })

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "ansiblels",
                    "bashls",
                    "cmake",
                    "djlsp",
                    "docker_compose_language_service",
                    "docker_language_server",
                    "gopls",
                    "html",
                    "jinja_lsp",
                    "lua_ls",
                    "pyrefly",
                    "rust_analyzer",
                    "ts_ls",
                    "vue_ls",
                    "yamlls",
                },
                automatic_enable = {
                    exclude = {
                        "rust_analyzer", -- Managed by `rustaceanvim`.
                    },
                },
            })
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-emoji",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            "saadparwaiz1/cmp_luasnip",
            "zbirenbaum/copilot.lua",
            "zbirenbaum/copilot-cmp",
        },
        config = function()
            local DEFAULT_GROUP_INDEX = 2
            local KIND_ICONS = {
                Text = "",
                Method = "󰆧",
                Function = "󰊕",
                Constructor = "",
                Field = "󰇽",
                Variable = "󰂡",
                Class = "󰠱",
                Interface = "",
                Module = "",
                Property = "󰜢",
                Unit = "",
                Value = "󰎠",
                Enum = "",
                Keyword = "󰌋",
                Snippet = "",
                Color = "󰏘",
                File = "󰈙",
                Reference = "",
                Folder = "󰉋",
                EnumMember = "",
                Constant = "󰏿",
                Struct = "",
                Event = "",
                Operator = "󰆕",
                TypeParameter = "󰅲",
                -- Custom types.
                Copilot = "",
            }
            local MENU_ITEMS = {
                buffer = "[Buffer]",
                nvim_lsp = "[LSP]",
                luasnip = "[LuaSnip]",
                nvim_lua = "[Lua]",
                latex_symbols = "[LaTeX]",
                -- Custom types.
                copilot = "[Copilot]",
            }
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
            })
            require("copilot_cmp").setup()
            vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "Green" })

            cmp.setup({
                completion = {
                    completeopt = "menu,menuone,preview,noselect",
                },
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                sorting = {
                    priority_weight = 2,
                    comparators = {
                        require("copilot_cmp.comparators").prioritize,
                        -- Default comparator list and order for `nvim-cmp`.
                        cmp.config.compare.offset,
                        -- NOTE: Commented-out in `nvim-cmp` too.
                        -- cmp.config.compare.scopes,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        cmp.config.compare.recently_used,
                        cmp.config.compare.locality,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                formatting = {
                    format = function(entry, vim_item)
                        vim_item.kind = string.format(
                            "%s %s",
                            KIND_ICONS[vim_item.kind],
                            vim_item.kind
                        )
                        vim_item.menu = MENU_ITEMS[entry.source.name]
                        return vim_item
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-u>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            cmp.complete()
                        end
                    end, { "i", "s" }),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                }),
                sources = cmp.config.sources({
                    { name = "lazydev", group_index = 0 },
                    { name = "copilot", group_index = DEFAULT_GROUP_INDEX },
                    { name = "nvim_lsp", group_index = DEFAULT_GROUP_INDEX },
                    { name = "luasnip", group_index = DEFAULT_GROUP_INDEX },
                    { name = "path", group_index = DEFAULT_GROUP_INDEX },
                    { name = "buffer", group_index = DEFAULT_GROUP_INDEX },
                }),
            })
        end,
    },
}
