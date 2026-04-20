return {
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		cmd = { "AerialToggle", "AerialNext", "AerialPrev" },
		keys = {
			{
				"<F3>",
				"<cmd>AerialToggle<cr>",
				desc = "Toggle Aerial (Outline)",
			},
			{
				"<leader>fa",
				"<cmd>Telescope aerial<cr>",
				desc = "Search symbols (Aerial)",
			},
		},
		opts = {
			lazy_load = true,
			layout = {
				default_direction = "prefer_right",
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
			pcall(function()
				require("telescope").load_extension("aerial")
			end)
		end,
	},
}
