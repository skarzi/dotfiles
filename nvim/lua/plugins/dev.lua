return {
	{
		"wakatime/vim-wakatime",
		event = "VeryLazy",
	},
	{
		"benmills/vimux",
		cmd = {
			"VimuxRunLastCommand",
			"VimuxPromptCommand",
			"VimuxSendKeys",
			"VimuxClear",
		},
		keys = {
			{
				"<leader>vp",
				"<cmd>VimuxPromptCommand<cr>",
				desc = "Vimux: Prompt Command",
			},
			{
				"<leader>vl",
				"<cmd>VimuxRunLastCommand<cr>",
				desc = "Vimux: Run Last Command",
			},
			{
				"<leader>vi",
				"<cmd>VimuxInspectRunner<cr>",
				desc = "Vimux: Inspect Runner",
			},
		},
	},
	-- TODO(skarzi): Find better alternative.
	{ "amadeus/vim-mjml", ft = { "mjml" } },
}
