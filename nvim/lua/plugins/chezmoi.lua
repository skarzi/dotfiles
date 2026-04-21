return {
	{
		"xvzc/chezmoi.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<leader>cz",
				function()
					require("chezmoi.pick").telescope()
				end,
				desc = "Search all chezmoi files",
			},
		},
		opts = {},
	},
	{
		"alker0/chezmoi.vim",
		lazy = false,
		init = function()
			vim.g["chezmoi#use_tmp_buffer"] = true
			vim.g["chezmoi#source_dir_path"] =
				vim.fn.expand("~/dotfiles/chezmoi")
		end,
	},
}
