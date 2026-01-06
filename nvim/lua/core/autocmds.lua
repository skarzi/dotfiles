local group = vim.api.nvim_create_augroup("core_autocmds", { clear = true })

-- Enable spell checking for specific filetypes
local spell_filetype_patterns = {
	markdown = { "en", "pl", "es" },
	html = { "en", "pl" },
	tex = { "en", "pl", "es" },
	gitcommit = { "en" },
}

for filetype, langs in pairs(spell_filetype_patterns) do
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = filetype,
		callback = function()
			vim.opt_local.spell = true
			vim.opt_local.spelllang = langs
		end,
		desc = "Enable spell checking",
	})
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
	desc = "Highlight yanked text",
})

-- Set ColorColumn highlight on ColorScheme change
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
	group = group,
	callback = function()
		vim.api.nvim_set_hl(
			0,
			"ColorColumn",
			{ ctermbg = "DarkBlue", bg = "DarkBlue" }
		)
	end,
	desc = "Set ColorColumn highlight",
})
