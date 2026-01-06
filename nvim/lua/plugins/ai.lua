return {
	-- TODO(skarzi): Configure `avante.vim`:
	-- + Use gemini and claude ACP.
	-- + Always respect `AGENTS.md` and other files
	-- + Integrate `mcphub`. Reference:
	--   https://ravitemer.github.io/mcphub.nvim/extensions/avante.html
	-- + Check Zen Mode. Reference:
	--   https://github.com/yetone/avante.nvim?tab=readme-ov-file#avante-zen-mode
	{
		"yetone/avante.nvim",
		build = "make",
		event = "VeryLazy",
		version = false,
		dependencies = {
			-- Required.
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			-- Optional.
			"nvim-telescope/telescope.nvim",
			"HakonHarnes/img-clip.nvim",
			"folke/snacks.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
		},
		opts = {
			instructions_file = "AGENTS.md",
			provider = "claude",
			providers = {
				claude = {
					endpoint = "https://api.anthropic.com",
					model = "claude-sonnet-4-20250514",
					timeout = 30000,
					extra_request_body = {
						temperature = 0.75,
						max_tokens = 20480,
					},
				},
				moonshot = {
					endpoint = "https://api.moonshot.ai/v1",
					model = "kimi-k2-0711-preview",
					timeout = 30000,
					extra_request_body = {
						temperature = 0.75,
						max_tokens = 32768,
					},
				},
			},
		},
	},
	-- Avante dependencies.
	{
		"HakonHarnes/img-clip.nvim",
		event = "VeryLazy",
		opts = {
			default = {
				embed_image_as_base64 = false,
				prompt_for_file_name = false,
				drag_and_drop = {
					insert_mode = true,
				},
			},
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown", "Avante" },
		opts = {
			file_types = { "markdown", "Avante" },
		},
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				-- NOTE: Copilot's suggestions are managed by `nvim-cmp`.
				suggestion = { enabled = false },
				panel = { enabled = false },
				-- TODO(skarzi): Figure-out how to load more than one Copilot
				-- suggestion using `nvim-cmp`.
				server_opts_overrides = {
					settings = {
						advanced = {
							inlineSuggestCount = 5,
						},
					},
				},
			})
		end,
	},
}
