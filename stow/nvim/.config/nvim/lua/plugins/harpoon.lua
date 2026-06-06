-- Harpoon (v2) — pin a handful of files and jump between them instantly.
-- Migrated from the v1 mark/ui API in the original config to the v2 list API.
return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: add file" })
        vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
            { desc = "Harpoon: quick menu" })

        -- Jump straight to pinned files 1-4
        vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end, { desc = "Harpoon: file 1" })
        vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end, { desc = "Harpoon: file 2" })
        vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end, { desc = "Harpoon: file 3" })
        vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end, { desc = "Harpoon: file 4" })
    end,
}
