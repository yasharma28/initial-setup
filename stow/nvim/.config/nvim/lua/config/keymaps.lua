-- Editor keymaps (non-plugin). Leader is set in options.lua. Plugin-specific
-- maps live next to their plugin spec in lua/plugins/. Every map carries a
-- `desc` so which-key can show a readable label in its popup.

-- Open the file explorer (netrw)
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Explorer (netrw)" })

-- Move the visual selection up/down, re-indenting as it goes
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep the cursor centered while joining, half-page scrolling, and searching
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line (keep cursor)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

-- Paste over a selection without overwriting the unnamed register
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over (keep register)" })

-- Yank / delete to the system clipboard and black-hole register
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })

-- Exit insert mode with Ctrl-c; disable Ex mode
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled (Ex mode)" })

-- Quickfix and location-list navigation, centered
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quickfix next" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quickfix prev" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Loclist next" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Loclist prev" })

-- Rename the word under the cursor across the file (interactive)
vim.keymap.set(
    "n",
    "<leader>s",
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Replace word under cursor" }
)

-- Make the current file executable
vim.keymap.set(
    "n",
    "<leader>x",
    "<cmd>!chmod +x %<CR>",
    { silent = true, desc = "chmod +x current file" }
)

-- Re-source the current file for quick config iteration. Guarded on filetype
-- because `:source` on a non-script buffer (e.g. a .tutor or markdown file)
-- throws E488 — it would try to execute the prose as Vimscript.
vim.keymap.set("n", "<leader><leader>", function()
    if vim.bo.filetype == "lua" or vim.bo.filetype == "vim" then
        vim.cmd("source %")
        vim.notify("Sourced " .. vim.fn.expand("%:t"))
    else
        vim.notify("Not a Lua/Vim file — nothing to source", vim.log.levels.WARN)
    end
end, { desc = "Source current file" })
