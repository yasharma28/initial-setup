-- Filetype-specific autocmds. Replaces the deprecated vim.api.nvim_exec call
-- from the old config with the modern nvim_create_autocmd API.

local group = vim.api.nvim_create_augroup("nvimrc-filetype", { clear = true })

-- YAML uses 2-space indentation (overrides the global 4-space default)
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "yaml",
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.expandtab = true
    end,
})

-- Strip trailing whitespace on save (was a manual keymap before)
vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = "*",
    callback = function()
        local save = vim.fn.winsaveview()
        vim.cmd([[keeppatterns %s/\s\+$//e]])
        vim.fn.winrestview(save)
    end,
})
