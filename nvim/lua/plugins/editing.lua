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
		"catgoose/nvim-colorizer.lua",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			filetypes = {
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
			},
		},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertCharPre",
		opts = {},
	},
}
