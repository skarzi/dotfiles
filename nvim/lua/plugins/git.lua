return {
	{
		"tpope/vim-fugitive",
		dependencies = {
			"tpope/vim-rhubarb",
		},
		cmd = {
			"Git",
			"GBrowse",
			"Gdiffsplit",
			"Ghdiffsplit",
			"Ggrep",
			"Glgrep",
			"GDelete",
			"GRemove",
			"GRename",
		},
		lazy = true,
	},
}
