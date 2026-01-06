return {
	-- TODO(skarzi): Test and install also
	-- [nvim-treesitter-textobjects](`https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main`)
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local treesitter_langs = {
				"bash",
				"c",
				"go",
				"gotmpl",
				"gpg",
				"helm",
				"html",
				"htmldjango",
				"javascript",
				"jinja",
				"jinja_inline",
				"json",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"rust",
				"terraform",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"vue",
				"yaml",
			}
			local treesitter = require("nvim-treesitter")
			treesitter.setup()

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local buf = args.buf
					-- Do not use treesitter for `chezmoi`.
					if string.find(vim.bo[buf].filetype, "chezmoitmpl") then
						return
					end
					-- Enable highlighting.
					pcall(vim.treesitter.start, buf)
					-- Enable folding.
					-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					-- vim.wo.foldmethod = "expr"
					-- Enable experimental indentation.
					-- vim.bo.indentexpr =
					-- 	"v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
			vim.api.nvim_create_user_command("TSInstallAll", function()
				require("nvim-treesitter").install(
					treesitter_langs,
					{ summary = true }
				)
			end, { nargs = 0, desc = "Install all TreeSitter plugins" })
			vim.api.nvim_create_user_command("TSUpdateAll", function()
				require("nvim-treesitter").update(
					treesitter_langs,
					{ summary = true }
				)
			end, { nargs = 0, desc = "Update all TreeSitter plugins" })
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{
				"<leader>fg",
				"<cmd>Telescope live_grep<cr>",
				desc = "Live Grep",
			},
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{
				"<leader>fh",
				"<cmd>Telescope help_tags<cr>",
				desc = "Help Tags",
			},
		},
		opts = {},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"numToStr/Comment.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
}
