return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/noice.nvim",
		},

		event = "VeryLazy",
		opts = {
			options = {
				theme = "onedark",
				component_separators = "|",
				section_separators = "",
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = {
					{
						require("noice").api.status.mode.get,
						cond = require("noice").api.status.mode.has,
						color = { fg = "DarkOrange" },
					},
					"venv-selector",
					"encoding",
					"fileformat",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
	{
		"nvim-tree/nvim-tree.lua",
		lazy = false,
		cmd = { "NvimTreeOpen", "NvimTreeToggle", "NvimTreeFocus" },
		keys = {
			{
				"<leader>e",
				"<cmd>NvimTreeToggle<cr>",
				desc = "Explorer Toggle",
			},
		},
		config = function()
			require("nvim-tree").setup({
				disable_netrw = true,
				hijack_netrw = true,
				renderer = { group_empty = true },
				filters = {
					dotfiles = false,
				},
				view = { relativenumber = true },
				actions = {
					change_dir = { enable = false },
				},
			})

			local explore_with_nvim_tree = function(opts)
				local path = opts.args ~= "" and opts.args or nil
				require("nvim-tree.api").tree.open({
					current_window = true,
					find_file = true,
					path = path,
					focus = true,
				})
			end

			vim.api.nvim_create_user_command(
				"Explore",
				explore_with_nvim_tree,
				{ nargs = "?", complete = "dir", desc = "Explore directory" }
			)
			vim.api.nvim_create_user_command(
				"Ex",
				explore_with_nvim_tree,
				{ nargs = "?", complete = "dir", desc = "Explore directory" }
			)
		end,
	},
}
