-- Buffers
vim.keymap.set("n", "<leader>]", ":n!<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>[", ":prev!<cr>", { desc = "Previous buffer" })

-- Search
vim.keymap.set(
	"n",
	"<leader><space>",
	":nohlsearch<cr>",
	{ desc = "Clear search highlight" }
)

-- Selection
vim.keymap.set("n", "gV", "`[v`]", { desc = "Select last inserted text" })

-- Indentation
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Window focus
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })

-- Window movement
vim.keymap.set("n", "<leader>h", "<C-w>H", { desc = "Move window left" })
vim.keymap.set("n", "<leader>j", "<C-w>J", { desc = "Move window down" })
vim.keymap.set("n", "<leader>k", "<C-w>K", { desc = "Move window up" })
vim.keymap.set("n", "<leader>l", "<C-w>L", { desc = "Move window right" })

-- Window resizing
vim.keymap.set("n", "|", "<C-w>|", { desc = "Maximize window horizontally" })
vim.keymap.set("n", "_", "<C-w>_", { desc = "Maximize window vertically" })

-- File explorer
vim.keymap.set("n", "-", ":Ex<cr>", { desc = "Explore current directory" })

-- System clipboard
vim.keymap.set(
	{ "n", "v" },
	"<leader>y",
	'"+y',
	{ desc = "Yank into system clipboard" }
)
vim.keymap.set(
	"n",
	"<leader>Y",
	'"+y$',
	{ desc = "Yank until end of line into system clipboard" }
)
vim.keymap.set(
	"n",
	"<leader>yy",
	'"+yy',
	{ desc = "Yank current line into system clipboard" }
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>p",
	'"+p',
	{ desc = "Paste after cursor from system clipboard" }
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>P",
	'"+P',
	{ desc = "Paste before cursor from system clipboard" }
)

-- Command line mode
vim.keymap.set("c", "%%", "<C-R>=fnameescape(expand('%:h')).'/'<cr>", {
	noremap = true,
	silent = true,
	desc = "Expand current file directory",
})

-- Visual mode macros
-- Reference: https://www.rockyourcode.com/run-macro-on-multiple-lines-in-vim/
vim.api.nvim_create_user_command("ExecuteMacroOverVisualRange", function()
	vim.cmd('echo "@"')
	local char = vim.fn.getchar()
	if type(char) == "string" then
		char = vim.fn.char2nr(char)
	end
	local macro_char = vim.fn.nr2char(char)
	vim.cmd(string.format(":'<,'>normal @%s", macro_char))
end, {
	desc = "Execute macro over visual range",
})

-- NOTE: The string keymap is used to ensure Neovim behaves exactly like
-- standard Vim:
-- 1. `:` - enters Command-line Mode.
--    When `:` is typed while text is selected, Neovim automatically exits
--    Visual Mode. This action sets the '< (start) and '> (end) marks to the
--    current selection.
-- 2. `<C-u>` - clears automatically populated visual selection range in the
--    command-line.
-- 3. `ExecuteMacroOverVisualRange` - execute custom command.
--    Because the visual range is cleared with `<C-u>`, the command starts
--    "naked", but the range is manually managed by the command's function to
--    ensure it hits every line in the selection.
-- 4. `<cr>` - Enter key (Carriage Return). Immediately execute the command.
vim.keymap.set("x", "@", ":<C-u>ExecuteMacroOverVisualRange<cr>", {
	silent = true,
	desc = "Execute macro over visual range",
})
