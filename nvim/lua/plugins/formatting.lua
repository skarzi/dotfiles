local lists = require("plugins.logic.lists")

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<F8>",
			function()
				require("conform").format({
					async = true,
					lsp_format = "fallback",
				})
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			["*"] = { "trim_whitespace", "trim_newlines" },
			css = { "prettier" },
			html = { "prettier" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			javascriptvue = { "prettier" },
			json = { "prettier", "jq" },
			lua = { "stylua" },
			markdown = { "prettier", "markdownlint-cli2" },
			python = function(bufnr)
				return lists.flatten({
					lists.pick_first_available(bufnr, {
						"ruff_organize_imports",
						"ruff_format",
						"ruff_fix",
					}, { "black", "isort" }),
					"flake8",
				})
			end,
			rust = { "rustfmt" },
			sh = { "shfmt" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			typescriptvue = { "prettier" },
			yaml = { "prettier" },
		},
		format_on_save = function(bufnr)
			local projects = require("config.projects")
			if projects.should_disable_tools(bufnr) then
				return
			end
			return {
				timeout_ms = 500,
				lsp_format = "fallback",
			}
		end,
	},
}
