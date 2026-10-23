return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                cpp = { "cpplint", "cppcheck" },
                lua = { "selene" },
                -- NOTE: flake8 runs plugins not covered by ruff.
                python = { "ruff", "flake8", "bandit" },
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                yaml = { "yamllint" },
                make = { "checkmake" },
                ["yaml.ghaction"] = { "yamllint", "actionlint" },
                ["yaml.ansible"] = { "yamllint", "ansible_lint" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                vue = { "eslint_d" },
            }

            ---@param linter lint.Linter Linter instance to check.
            ---@return boolean is_installed Information if linter is installed.
            local function is_installed(linter)
                local cmd = linter.cmd
                if type(cmd) == "function" then
                    local ok, resolved_cmd = pcall(cmd)
                    if not ok then
                        return false
                    end
                    cmd = resolved_cmd
                end
                return type(cmd) == "string" and vim.fn.executable(cmd) == 1
            end

            local lint_opts = { filter = is_installed }
            local lint_augroup =
                vim.api.nvim_create_augroup("lint", { clear = true })
            local projects = require("config.projects")

            vim.api.nvim_create_autocmd(
                { "BufEnter", "BufWritePost", "InsertLeave" },
                {
                    group = lint_augroup,
                    desc = "Run linters on buffer events",
                    callback = function(event)
                        if projects.should_disable_tools(event.buf) then
                            return
                        end
                        lint.try_lint(nil, lint_opts)
                    end,
                }
            )

            vim.keymap.set("n", "<F7>", function()
                lint.try_lint(nil, lint_opts)
            end, { desc = "Lint current buffer" })
        end,
    },
}
