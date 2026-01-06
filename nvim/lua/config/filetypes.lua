local M = {}

local group =
	vim.api.nvim_create_augroup("config_filetypes_autocmds", { clear = true })

M.setup = function()
	local function set_filetype(filetype)
		return function()
			vim.bo.filetype = filetype
		end
	end

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = "Jenkinsfile.*",
		callback = set_filetype("groovy"),
		desc = "Set filetype for Jenkinsfile",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = {
			"*/ansible/hosts",
			"*/playbooks/*.y(a)?ml",
		},
		callback = set_filetype("yaml.ansible"),
		desc = "Set filetype for Ansible",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = "*/.github/actions/*.y(a)?ml",
		callback = set_filetype("yaml.ghaction"),
		desc = "Set filetype for GitHub Actions",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = {
			"*.y(a)?ml.(example|sample|ex)",
			".?ansible-lint",
			".?yamllint",
		},
		callback = set_filetype("yaml"),
		desc = "Set filetype for YAML configs",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = ".importlinter",
		callback = set_filetype("cfg"),
		desc = "Set filetype for Python import-linter",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = { "*.py.template", "*.py.(example|sample|ex)" },
		callback = set_filetype("python"),
		desc = "Set filetype for Python templates",
	})

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = group,
		pattern = { "*.ini.(example|sample|ex)", "*.ini.template" },
		callback = set_filetype("dosini"),
		desc = "Set filetype for INI templates",
	})
end

return M
