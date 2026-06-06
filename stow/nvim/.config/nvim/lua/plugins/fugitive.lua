-- vim-fugitive — Git inside nvim. <leader>gs opens the status window.
return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status (fugitive)" })
    end,
}
