return {
	{
		"navarasu/onedark.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local onedark = require("onedark")
			onedark.setup({ style = "warmer" })
			onedark.load()
		end,
	},
}
