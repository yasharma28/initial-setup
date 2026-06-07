-- which-key — discoverability popup. After pressing a prefix (e.g. <leader>),
-- it shows the available follow-up keys and their descriptions. Added as a
-- learning aid: the keymaps themselves carry `desc` strings, which-key just
-- surfaces them. Group labels below name the <leader> sub-menus.
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 300, -- ms to wait after a prefix before the popup appears
        spec = {
            { "<leader>p", group = "project / find" },
            { "<leader>v", group = "lsp / view" },
            { "<leader>g", group = "git / goto" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer-local keymaps (which-key)",
        },
    },
}
