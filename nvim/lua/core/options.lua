-- EditorConfig
vim.g.editorconfig = true

-- Appearance
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.relativenumber = true
vim.opt.showcmd = true
vim.opt.cursorline = true
vim.opt.wildmenu = true
vim.opt.lazyredraw = false
vim.opt.textwidth = 80
vim.opt.colorcolumn = "+0"

-- Indentation
vim.opt.autoindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.list = true
vim.opt.listchars = { trail = "_", tab = ">-" }
vim.opt.smarttab = true
vim.opt.fileformat = "unix"

-- Search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.showmatch = true
vim.opt.path:append("**")

-- Splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- netrw
vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true

-- Status
vim.opt.laststatus = 3 -- Global status line.
