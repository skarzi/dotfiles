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
		keys = {
			{
				"<leader>ca",
				function()
					require("actions-preview").code_actions()
				end,
				mode = { "v", "n" },
				desc = "Code Actions Preview",
			},
		},
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
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = (function()
			local harpoon_keys = {
				{
					"<leader>mm",
					function()
						require("harpoon"):list():add()
					end,
					desc = "Harpoon: Add file",
				},
				{
					"<leader>mo",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "Harpoon: Toggle menu",
				},
				{
					"<leader>mn",
					function()
						require("harpoon"):list():next()
					end,
					desc = "Harpoon: Next file",
				},
				{
					"<leader>mp",
					function()
						require("harpoon"):list():prev()
					end,
					desc = "Harpoon: Prev file",
				},
			}

			for mark_number = 1, 4 do
				table.insert(harpoon_keys, {
					"<leader>m" .. mark_number,
					function()
						require("harpoon"):list():select(mark_number)
					end,
					desc = "Harpoon: File " .. mark_number,
				})
				table.insert(harpoon_keys, {
					"<leader>md" .. mark_number,
					function()
						require("harpoon"):list():remove_at(mark_number)
					end,
					desc = "Harpoon: Remove file " .. mark_number,
				})
			end

			return harpoon_keys
		end)(),
		config = function()
			require("harpoon"):setup()
		end,
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
