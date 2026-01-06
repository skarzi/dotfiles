return {
	{
		"folke/trouble.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/todo-comments.nvim",
		},
		cmd = { "Trouble" },
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Toggle Trouble Diagnostics",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>xl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
		},
		opts = {},
	},
	{
		"aznhe21/actions-preview.nvim",
		config = function()
			vim.keymap.set(
				{ "v", "n" },
				"<leader>ca",
				require("actions-preview").code_actions,
				{ desc = "Code Actions Preview" }
			)
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			highlight = {
				-- Reference: https://github.com/folke/todo-comments.nvim/pull/255#issuecomment-2049839007
				pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]],
			},
			search = {
				pattern = [[(KEYWORDS)\s*(\(\w+\))?:]],
			},
		},
		cmd = { "TodoQuickFix" },
		keys = {
			{
				"]C",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next TODO comment",
			},
			{
				"[C",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous TODO comment",
			},
		},
	},
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<leader>mm",
				function()
					require("harpoon.mark").add_file()
				end,
				desc = "Harpoon: Add file",
			},
			{
				"<leader>mo",
				function()
					require("harpoon.ui").toggle_quick_menu()
				end,
				desc = "Harpoon: Toggle menu",
			},
			{
				"<leader>m1",
				function()
					require("harpoon.ui").nav_file(1)
				end,
				desc = "Harpoon: File 1",
			},
			{
				"<leader>m2",
				function()
					require("harpoon.ui").nav_file(2)
				end,
				desc = "Harpoon: File 2",
			},
			{
				"<leader>m3",
				function()
					require("harpoon.ui").nav_file(3)
				end,
				desc = "Harpoon: File 3",
			},
			{
				"<leader>m4",
				function()
					require("harpoon.ui").nav_file(4)
				end,
				desc = "Harpoon: File 4",
			},
		},
	},
	{
		"rmagatti/auto-session",
		opts = {
			log_level = "error",
			allowed_dirs = {
				"~/dotfiles",
				"~/dev/*",
				"~/work/*",
			},
		},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			lsp = {
				-- NOTE: Override Markdown rendering so that **cmp** and other
				-- plugins use **Treesitter**.
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			cmdline = {
				view = "cmdline",
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
		},
	},
}
