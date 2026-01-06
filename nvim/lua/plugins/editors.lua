local pandoc_filetypes = { "markdown", "pandoc", "rst", "textile" }

return {
	{
		"vim-pandoc/vim-pandoc",
		ft = pandoc_filetypes,
		dependencies = {
			"vim-pandoc/vim-pandoc-syntax",
		},
		init = function()
			vim.g["pandoc#modules#disabled"] = { "folding" }
		end,
	},
	{
		"vim-pandoc/vim-pandoc-syntax",
		ft = pandoc_filetypes,
	},
	{
		"lervag/vimtex",
		ft = { "tex" },
		init = function()
			vim.g.vimtex_imaps_leader = "\\"
			vim.g.vimtex_view_method = "skim"
		end,
	},
	{
		"junegunn/goyo.vim",
		cmd = "Goyo",
		keys = {
			{
				"<leader>G",
				"<cmd>Goyo<cr>",
				desc = "Toggle Goyo (Distraction-free)",
			},
		},
	},
}
