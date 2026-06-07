# initial-setup

Dotfiles + provisioning to stand up a consistent development environment on a
fresh machine (macOS, Debian/Ubuntu, RHEL/Fedora, Windows). Dotfiles are
symlinked with [GNU Stow](https://www.gnu.org/software/stow/) so the repo is the
single source of truth — edits to live files write straight back.

## Quick start

```sh
git clone git@github.com:yasharma28/initial-setup.git
cd initial-setup
make mac_setup                    # core stack only
make mac_setup PROFILE=personal   # + personal apps  (or PROFILE=work)
```

`make` with no target prints the available targets. On Linux use `make` (it
auto-detects the distro) or `make debian_setup` / `make rhel_setup`.

## What gets set up

| Layer | Tool |
|-------|------|
| Shell | zsh + oh-my-zsh (`zsh-autosuggestions`) |
| Prompt | [Starship](https://starship.rs) |
| Multiplexer | tmux + [gpakosz](https://github.com/gpakosz/.tmux) + resurrect/continuum |
| Sessions | [sesh](https://github.com/joshmedeski/sesh) + fzf + zoxide |
| Editor | Neovim ([lazy.nvim](https://lazy.folke.io): native LSP, blink.cmp, treesitter, which-key) — see [`stow/nvim/.config/nvim/README.md`](stow/nvim/.config/nvim/README.md) |
| DevOps CLIs | kubectl, terraform, awscli, gcloud, vault, direnv, ripgrep, jq |

## Documentation

- [`docs/`](docs/00-index.md) — index
- [Architecture](docs/10-architecture.md) — how it fits together (Stow, profiles, the why)
- [Setup guide](docs/20-setup.md) — fresh-machine setup + manual steps
- [Reference](docs/30-reference.md) — targets, scripts, layout
- [Troubleshooting](docs/99-troubleshooting.md)
- [`plan.md`](plan.md) — the modernization audit + decision record

## License

MIT — see [LICENSE](LICENSE). Issues/PRs welcome:
[Yash Sharma](mailto:yasharma28@gmail.com) · [Issues](https://github.com/yasharma28/initial-setup/issues)
