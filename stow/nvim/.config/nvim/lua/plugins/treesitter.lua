-- Treesitter — syntax-aware highlighting and indentation.
--
-- On the `main` branch (the rewrite), required for Neovim 0.11+. The old
-- `master` branch is frozen at Neovim 0.11 and crashes on 0.12 with
-- "attempt to call method 'range' (a nil value)", so we cannot use it here.
--
-- The `main` branch dropped the `configs.setup({ highlight = ... })` contract:
-- parsers are installed with require("nvim-treesitter").install(), and
-- highlighting is Neovim-native via vim.treesitter.start() per buffer.
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- the plugin documents that it must not be lazy-loaded
    build = ":TSUpdate",
    config = function()
        -- markdown_inline is listed alongside markdown: markdown injects it for
        -- inline spans, and a missing/mismatched inline parser is what crashed
        -- the highlighter on markdown previews.
        require("nvim-treesitter").install({
            "bash", "c", "cpp", "dockerfile", "go", "hcl", "javascript",
            "json", "lua", "make", "markdown", "markdown_inline", "python",
            "rust", "terraform", "typescript", "vim", "vimdoc", "yaml",
        })

        -- Start treesitter per buffer, but only when a parser for that filetype
        -- is actually available — otherwise vim.treesitter.start() errors. This
        -- replaces the master branch's global `highlight.enable = true`.
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("nvimrc-treesitter", { clear = true }),
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
                if not lang then
                    return
                end
                local ok, added = pcall(vim.treesitter.language.add, lang)
                if not (ok and added) then
                    return
                end
                vim.treesitter.start(args.buf, lang)
                -- Treesitter-based indentation (experimental on the main branch).
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}
