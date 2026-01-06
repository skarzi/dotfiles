local M = {}

local group =
	vim.api.nvim_create_augroup("config_indentation_autocmds", { clear = true })

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "python",
		callback = function()
			vim.opt_local.tabstop = 4
			vim.opt_local.softtabstop = 4
			vim.opt_local.shiftwidth = 4
			vim.opt_local.expandtab = true
		end,
		desc = "Python Indentation",
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "make", "Makefile" },
		callback = function()
			vim.opt_local.tabstop = 8
			vim.opt_local.softtabstop = 8
			vim.opt_local.shiftwidth = 8
			vim.opt_local.expandtab = false
		end,
		desc = "Makefile Indentation",
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "groovy",
		callback = function()
			vim.opt_local.tabstop = 4
			vim.opt_local.softtabstop = 4
			vim.opt_local.shiftwidth = 4
			vim.opt_local.expandtab = true
		end,
		desc = "Groovy Indentation",
	})
end

return M
