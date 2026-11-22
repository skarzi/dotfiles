return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "folke/noice.nvim",
        },

        event = "VeryLazy",
        opts = {
            options = {
                theme = "onedark",
                component_separators = "|",
                section_separators = "",
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { "filename", "aerial" },
                lualine_x = {
                    {
                        function() -- Display function.
                            return require("noice").api.status.mode.get()
                        end,
                        cond = function()
                            return require("noice").api.status.mode.has()
                        end,
                        color = { fg = "DarkOrange" },
                    },
                    "venv-selector",
                    "encoding",
                    "fileformat",
                    "filetype",
                },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
    },
    {
        "nvim-tree/nvim-tree.lua",
        -- Load at startup so `hijack_directories` catches `nvim <dir>`.
        lazy = false,
        cmd = {
            "NvimTreeOpen",
            "NvimTreeToggle",
            "NvimTreeFocus",
            "Explore",
            "Ex",
        },
        keys = {
            {
                "<leader>e",
                "<cmd>NvimTreeToggle<cr>",
                desc = "Explorer Toggle",
            },
        },
        config = function()
            -- Keys in the tree (defaults, no tabs): <CR> open in place
            -- (replace the tree buffer; overridden below), <C-v> vertical
            -- split, <C-x> horizontal split, <C-e> same as <CR>, g? all keys.
            local function on_attach(bufnr)
                local api = require("nvim-tree.api")
                api.map.on_attach.default(bufnr)
                vim.keymap.set("n", "<CR>", api.node.open.replace_tree_buffer, {
                    desc = "nvim-tree: Open: In Place",
                    buffer = bufnr,
                    noremap = true,
                    silent = true,
                    nowait = true,
                })
                -- Undo defaults: H/M/L are screen motions, not filters
                -- (dotfiles/bookmark/group empty); do not close on q.
                for _, key in ipairs({ "H", "M", "L", "q" }) do
                    vim.keymap.del("n", key, { buffer = bufnr })
                end
            end

            require("nvim-tree").setup({
                on_attach = on_attach,
                disable_netrw = true,
                hijack_netrw = true,
                renderer = { group_empty = true },
                filters = {
                    dotfiles = false,
                },
                view = { relativenumber = true },
                actions = {
                    change_dir = { enable = false },
                },
            })

            local explore_with_nvim_tree = function(opts)
                local path = opts.args ~= "" and opts.args or nil
                require("nvim-tree.api").tree.open({
                    current_window = true,
                    find_file = true,
                    path = path,
                    focus = true,
                })
            end

            vim.api.nvim_create_user_command(
                "Explore",
                explore_with_nvim_tree,
                { nargs = "?", complete = "dir", desc = "Explore directory" }
            )
            vim.api.nvim_create_user_command(
                "Ex",
                explore_with_nvim_tree,
                { nargs = "?", complete = "dir", desc = "Explore directory" }
            )
        end,
    },
}
