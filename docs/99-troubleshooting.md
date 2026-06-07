# Troubleshooting

## Icons show as `?` or tofu boxes (which-key, Starship, tmux)

The terminal font isn't a complete Nerd Font. Set the iTerm profile font to
**MesloLGS Nerd Font Mono** (installed by the `font-meslo-lg-nerd-font` cask —
NOT the minimal "MesloLGS NF"). In iTerm, also disable "Use a different font for
non-ASCII text" unless that font is a Nerd Font too.

## nvim: `tree-sitter` not found / parsers won't compile

The treesitter `main` branch compiles parsers from source and needs the
tree-sitter **CLI**. The `tree-sitter` Homebrew formula ships only the library;
install the CLI: `brew install tree-sitter-cli` (it's in the core Brewfile).

## nvim: errors on first launch / `attempt to call ... (a nil value)`

Plugins/parsers may still be installing. Re-launch `nvim`, then run `:Lazy sync`
and `:checkhealth`. The treesitter `main` branch requires Neovim **0.11+** —
older builds (often the distro's apt/dnf package) won't work, which is why the
Linux scripts install nvim from the official release tarball.

## stow: "existing target is not owned by stow"

A real file already exists where stow wants a symlink. `link.sh` backs these up
automatically (`*.pre-stow.<timestamp>.bak`); if you ran `stow` directly,
move/remove the conflicting file and re-run `make <os>_setup` (or `./scripts/link.sh`).

## tmux: status bar / plugins missing

Plugins install on first launch via tpm. Inside tmux press `prefix + I` to force
install. The gpakosz framework lives at `~/.tmux/`; your edits are in
`~/.tmux.conf.local` (symlinked from `stow/tmux/`).

## Shell references a tool that isn't installed

The core Brewfile installs the DevOps CLIs the shell assumes. If something's
missing, re-run `./scripts/mac_utils.sh -i`. Environment-specific values
(`VAULT_ADDR`, role aliases) come from `~/.secrets.sh` — see
[setup](20-setup.md).

## Undo the symlinks

`make unlink` removes all Stow symlinks; `make clean` removes the dated backups.
