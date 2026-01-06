return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				mode = "tabs",
				themable = true,
				separator_style = "slant",
			},
		},
	},
	{
		"norcalli/nvim-colorizer.lua",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
		config = function()
			require("colorizer").setup({
				"bash",
				"css",
				"html",
				"javascript",
				"javascriptreact",
				"json",
				"lua",
				"sh",
				"toml",
				"typescript",
				"typescriptreact",
				"vue",
				"yaml",
			})
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertCharPre",
		opts = {},
	},
}
