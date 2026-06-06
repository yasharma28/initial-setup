# Neovim config

A modular [lazy.nvim](https://lazy.folke.io) configuration. Migrated from a
ThePrimeagen-style Packer config to the current ecosystem standard, targeting
Neovim 0.11+ (built/tested on 0.12).

## Requirements

- **Neovim 0.11+** — Treesitter uses the `main` branch, which requires it. The
  old `master` branch does not work on Neovim 0.12.
- **tree-sitter CLI** — the `main` branch compiles parsers from source. Install
  with `brew install tree-sitter-cli` (the `tree-sitter` formula ships only the
  library, not the CLI).
- **A C compiler** (`cc`) — present by default on macOS via the Xcode CLT.

## Structure

```
init.lua                 # wiring only: load config modules, then bootstrap lazy
lua/config/
  options.lua            # vim.opt settings + leader
  keymaps.lua            # editor keymaps (non-plugin)
  autocmds.lua           # filetype tweaks (yaml 2-space) + trim trailing ws
  lazy.lua               # lazy.nvim bootstrap + setup
lua/plugins/             # one file per plugin, each returns a lazy spec
  colorscheme.lua        # moonfly (transparent bg)
  telescope.lua          # fuzzy finder (+ plenary)
  treesitter.lua         # highlighting/indent (main branch — needs tree-sitter CLI)
  harpoon.lua            # harpoon2 — pin & jump between files
  lsp.lua                # mason + native vim.lsp + blink capabilities
  completion.lua         # blink.cmp
  undotree.lua
  fugitive.lua
  which-key.lua          # popup that surfaces keymaps after a prefix (learning aid)
lazy-lock.json           # pinned plugin commits (committed for reproducibility)
```

Adding a plugin = drop a new file in `lua/plugins/` that returns a spec. lazy
imports the whole directory automatically.

## Key bindings

Leader is `<space>`.

### Editor
| Key | Action |
|-----|--------|
| `<leader>pv` | File explorer (netrw) |
| `J` / `K` (visual) | Move selection down/up |
| `<C-d>` / `<C-u>` | Half-page scroll, centered |
| `<leader>p` (visual) | Paste over selection, keep register |
| `<leader>y` / `<leader>Y` | Yank to system clipboard |
| `<leader>s` | Replace word under cursor (file-wide) |
| `<leader>x` | `chmod +x` the current file |
| `<C-k>` / `<C-j>` | Quickfix next / prev |
| `<leader>` (then wait) | which-key popup shows what comes next |
| `<leader>?` | List buffer-local keymaps (which-key) |

### Telescope
| Key | Action |
|-----|--------|
| `<leader>pf` | Find files |
| `<C-p>` | Find git files |
| `<leader>ps` | Grep for a string |

### Harpoon
| Key | Action |
|-----|--------|
| `<leader>a` | Add file |
| `<C-e>` | Toggle quick menu |
| `<C-h>` `<C-t>` `<C-n>` `<C-s>` | Jump to file 1–4 |

### LSP (active when a server attaches)
| Key | Action |
|-----|--------|
| `<leader>gd` | Go to definition |
| `K` | Hover docs |
| `<leader>vca` | Code action |
| `<leader>vrn` | Rename |
| `<leader>vrr` | References |
| `]d` / `[d` | Next / prev diagnostic |
| `<leader>vd` | Show diagnostic float |

### Git / Undo
| Key | Action |
|-----|--------|
| `<leader>gs` | Git status (fugitive) |
| `<leader>u` | Undotree toggle |

## Managing it

- `:Lazy` — plugin manager UI (install/update/clean)
- `:Mason` — LSP server installer
- `:checkhealth` — diagnose problems
