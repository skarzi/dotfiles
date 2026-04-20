return {
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
