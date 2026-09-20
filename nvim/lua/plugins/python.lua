return {
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "mfussenegger/nvim-dap",
            "mfussenegger/nvim-dap-python",
            "nvim-telescope/telescope.nvim",
        },
        ft = "python",
        keys = {
            {
                "<leader>vs",
                "<cmd>VenvSelect<cr>",
                desc = "Select Python venv",
            },
        },
        opts = {
            options = {
                enable_default_searches = false,
                enable_cached_venvs = true,
                cached_venv_automatic_activation = true,
                require_lsp_activation = true,
                search_timeout = 3,
                statusline_func = {
                    ---Returns a formatted string representing the current
                    ---Python virtual environment. If the environment is named
                    ---'.venv', it uses the parent directory's name instead.
                    ---@return string The formatted venv name with an icon,
                    ---or an empty string if no venv is active.
                    lualine = function()
                        local venv_path = require("venv-selector").venv()
                        if not venv_path or venv_path == "" then
                            return ""
                        end
                        local venv_name = vim.fn.fnamemodify(venv_path, ":t")
                        if venv_name == ".venv" then
                            venv_name = vim.fn.fnamemodify(venv_path, ":h:t")
                        end
                        if venv_name then
                            return string.format("🎮 %s", venv_name)
                        end
                        return ""
                    end,
                },
            },
            search = {
                workspace = {
                    command = "fd '/bin/python$' '$WORKSPACE_PATH' --full-path --color never --exclude .git --hidden --no-ignore",
                },
                cwd = {
                    command = "fd '/bin/python$' '$CWD' --full-path --color never --exclude .git --hidden --no-ignore",
                },
            },
        },
    },
}
