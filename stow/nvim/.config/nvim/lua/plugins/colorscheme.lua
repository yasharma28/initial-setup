-- moonfly colorscheme (kept from the original config). Loaded eagerly with high
-- priority so it applies before other UI plugins draw their first frame.
return {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("moonfly")
        -- Transparent background: show the terminal's background through nvim.
        -- (The original config intended this but had a bug — `none` was nil.)
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end,
}
