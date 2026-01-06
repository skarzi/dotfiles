return {
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"mfussenegger/nvim-dap",
			"mfussenegger/nvim-dap-python",
			{
				"nvim-telescope/telescope.nvim",
				branch = "0.1.x",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
		},
		lazy = false,
		ft = "python",
		keys = {
			{
				"<leader>vs",
				"<cmd>VenvSelect<cr>",
				desc = "Select Python venv",
			},
		},
		opts = {
			search = {},
			options = {
				statusline_func = {
					---Returns a formatted string representing the current Python virtual environment.
					---If the environment is named '.venv', it uses the parent directory's name instead.
					---@return string The formatted venv name with an icon, or an empty string if no venv is active.
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
		},
	},
}
