local M = {}

-- selene: allow(incorrect_standard_library_use)
local unpack = unpack or table.unpack

---Returns the first available formatter or list of formatters from the given arguments.
---If an argument is a table, it is returned if at least one of its formatters is available.
---@param bufnr number The buffer number to check availability for.
---@param ... string|string[] Formatter name or lists of formatter names.
---@return string[] The first available entry, or the first entry if none are available.
M.pick_first_available = function(bufnr, ...)
	local conform = require("conform")
	for index = 1, select("#", ...) do
		local formatter = select(index, ...)
		if type(formatter) == "table" and not vim.tbl_isempty(formatter) then
			for _, nested_formatter in ipairs(formatter) do
				if
					conform.get_formatter_info(nested_formatter, bufnr).available
				then
					return formatter
				end
			end
		elseif conform.get_formatter_info(formatter, bufnr).available then
			return { formatter }
		end
	end
	local first_formatter = select(1, ...)
	if type(first_formatter) == "table" then
		return first_formatter
	end
	return { first_formatter }
end

---Recursively flattens a list of strings or tables of strings into a single list of strings.
---@param ... string|string[] The arguments to flatten.
---@return string[] The flattened list of strings.
M.flatten = function(...)
	local result = {}
	local function _flatten(...)
		for index = 1, select("#", ...) do
			local element = select(index, ...)
			if type(element) == "table" then
				_flatten(unpack(element))
			else
				table.insert(result, element)
			end
		end
	end
	_flatten(...)
	return result
end

return M
