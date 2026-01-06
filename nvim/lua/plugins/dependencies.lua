return {
	{
		"whoissethdaniel/mason-tool-installer.nvim",
		dependencies = {
			"williamboman/mason.nvim",
		},
		cmd = {
			"MasonToolsInstall",
			"MasonToolsInstallSync",
			"MasonToolsUpdate",
			"MasonToolsUpdateSync",
			"MasonToolsClean",
		},
		config = function()
			require("mason-tool-installer").setup({
				run_on_start = true,
				auto_update = true,
				start_delay = 5000,
				-- NOTE: Check `nvim/lua/plugins/lsp.lua` for LSPs configuration.
				ensure_installed = {
					-- Linters and formatters
					"actionlint",
					"ansible-lint",
					"bandit",
					"checkmake",
					"cpplint",
					"dotenv-linter",
					"eslint_d",
					"flake8",
					"markdownlint-cli2",
					"ruff",
					"selene",
					"shellcheck",
					"shfmt",
					"stylua",
					"tflint",
					"tfsec",
					"vale",
					"vint",
					"yamllint",
					"editorconfig-checker",
					-- DAPs
					"bash-debug-adapter",
					"cpptools",
					"debugpy",
				},
				integrations = {
					["mason-lspconfig"] = true,
					["mason-nvim-dap"] = true,
				},
			})
		end,
	},
}
