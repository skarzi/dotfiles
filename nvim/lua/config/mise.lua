-- NOTE: `mise` configuration is stored in `config/` not in `plugins/`,
-- because a lot of plugins depend on it, thus it must be configured early.
local M = {}

-- TODO(skarzi): If `PATH` manipulation grows, extract to `core/path.lua`.
function M.setup()
    local shims = vim.env.HOME .. "/.local/share/mise/shims"
    if not vim.env.PATH:find(shims, 1, true) then
        vim.env.PATH = shims .. ":" .. vim.env.PATH
    end
end

return M
