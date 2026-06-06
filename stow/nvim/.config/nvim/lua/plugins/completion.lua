-- blink.cmp — completion engine (replaces nvim-cmp). The "default" keymap preset
-- mirrors the old nvim-cmp binds: <C-y> accept, <C-n>/<C-p> select, <C-space>
-- open/docs. version = "1.*" pulls a prebuilt binary (no Rust toolchain needed).
return {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
        completion = { documentation = { auto_show = true } },
        fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
}
