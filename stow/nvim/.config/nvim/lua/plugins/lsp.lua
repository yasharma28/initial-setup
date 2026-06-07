-- LSP — modern nvim 0.11/0.12 setup: mason installs the servers, and the native
-- vim.lsp.config()/vim.lsp.enable() API configures them (no lsp-zero, which is
-- deprecated). mason-lspconfig auto-enables each installed server on startup.
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "mason-org/mason-lspconfig.nvim",
        "saghen/blink.cmp",
    },
    config = function()
        -- Buffer-local keymaps, applied only when a server attaches to a buffer.
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("nvimrc-lsp-attach", { clear = true }),
            callback = function(event)
                -- Helper so each LSP map keeps the buffer-local opts and adds a desc.
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(
                        mode,
                        lhs,
                        rhs,
                        { buffer = event.buf, remap = false, desc = desc }
                    )
                end
                map("n", "<leader>gd", vim.lsp.buf.definition, "Go to definition")
                map("n", "K", vim.lsp.buf.hover, "Hover docs")
                map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace symbol")
                map("n", "<leader>vd", vim.diagnostic.open_float, "Show diagnostic")
                -- Un-inverted from the original: ] goes forward, [ goes back.
                map("n", "]d", function()
                    vim.diagnostic.jump({ count = 1, float = true })
                end, "Next diagnostic")
                map("n", "[d", function()
                    vim.diagnostic.jump({ count = -1, float = true })
                end, "Prev diagnostic")
                map("n", "<leader>vca", vim.lsp.buf.code_action, "Code action")
                map("n", "<leader>vrr", vim.lsp.buf.references, "References")
                map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename symbol")
                map("i", "<C-h>", vim.lsp.buf.signature_help, "Signature help")
            end,
        })

        -- Give every server blink.cmp's completion capabilities.
        vim.lsp.config("*", {
            capabilities = require("blink.cmp").get_lsp_capabilities(),
        })

        -- lua_ls: declare the `vim` global so editing nvim config is warning-free.
        vim.lsp.config("lua_ls", {
            settings = { Lua = { diagnostics = { globals = { "vim" } } } },
        })

        require("mason-lspconfig").setup({
            ensure_installed = {
                "ansiblels",
                "bashls",
                "docker_compose_language_service",
                "dockerls",
                "golangci_lint_ls",
                "gopls",
                "lua_ls",
                "pylsp",
                "rust_analyzer",
                "terraformls",
                "ts_ls",
                "yamlls",
            },
        })
    end,
}
