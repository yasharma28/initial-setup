-- Telescope — fuzzy finder. Keymaps preserved from the original config.
return {
    "nvim-telescope/telescope.nvim",
    version = "*", -- track the latest stable tagged release (currently 0.2.x)
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find git files" })
        vim.keymap.set("n", "<leader>ps", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Grep for a string" })
    end,
}
