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
				["yaml.ansible"] = { "yamllint", "ansible-lint" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				vue = { "eslint_d" },
			}

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
						lint.try_lint()
					end,
				}
			)

			vim.keymap.set("n", "<F7>", function()
				lint.try_lint()
			end, { desc = "Lint current buffer" })
		end,
	},
}
