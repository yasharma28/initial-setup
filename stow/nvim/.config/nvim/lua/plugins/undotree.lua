-- Undotree — visualize and navigate the undo history. <leader>u toggles it.
return {
    "mbbill/undotree",
    config = function()
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Undotree toggle" })
    end,
}
