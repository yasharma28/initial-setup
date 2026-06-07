-- Editor options. Leader is set here (before lazy loads, so plugin mappings
-- pick it up). Filetype-specific tweaks live in autocmds.lua.

vim.g.mapleader = " "

vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.listchars = { space = "_", tab = ">~" }
vim.opt.list = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Faster CursorHold (LSP diagnostics, gitsigns, etc.)
vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
