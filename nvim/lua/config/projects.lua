local M = {}

-- List of project paths where linters and formatters should be disabled.
M.ignored_projects = {}

local env_ignored_projects = vim.env.IGNORED_PROJECTS
if env_ignored_projects then
	for _, project_path in ipairs(vim.split(env_ignored_projects, ",")) do
		table.insert(M.ignored_projects, project_path)
	end
end

M._ignored_projects = {}
for _, project_path in ipairs(M.ignored_projects) do
	M._ignored_projects[#M._ignored_projects + 1] =
		vim.fs.normalize(vim.fn.expand(project_path))
end

function M.should_disable_tools(bufnr_or_path)
	local buf_path
	if type(bufnr_or_path) == "string" then
		buf_path = bufnr_or_path
	else
		buf_path = vim.api.nvim_buf_get_name(
			bufnr_or_path or vim.api.nvim_get_current_buf()
		)
	end
	-- If buffer has no name (e.g. new file), don't disable.
	if buf_path == "" then
		return false
	end
	buf_path = vim.fs.normalize(buf_path)
	for _, project_path in ipairs(M._ignored_projects) do
		if vim.startswith(buf_path, project_path) then
			return true
		end
	end
	return false
end

return M
