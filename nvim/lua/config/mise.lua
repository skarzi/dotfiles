-- NOTE: `mise` configuration is stored in `config/` not in `plugins/`,
-- because a lot of plugins depend on it, thus it must be configured early.
local M = {}

function M.setup()
	vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
end

return M
