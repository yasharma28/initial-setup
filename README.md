# initial-setup

Configuration files and scripts to stand up a consistent development environment
on a fresh machine (macOS, Debian, RHEL, Windows). One `make` target installs the
packages, deploys the dotfiles, and bootstraps the shell/editor frameworks.

## Table of Contents

- [What gets set up](#what-gets-set-up)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Remaining manual steps](#remaining-manual-steps)
  - [Targets](#targets)
- [Configuration Details](#configuration-details)
- [Scripts](#scripts)
- [License / Contributing / Contact](#license)

## What gets set up

The macOS path (`make mac_setup`) provisions a full terminal stack:

| Layer | Tool |
|-------|------|
| Shell | zsh + oh-my-zsh (`zsh-autosuggestions`) |
| Prompt | [Starship](https://starship.rs) (migrated off powerlevel10k) |
| Multiplexer | tmux + the [gpakosz](https://github.com/gpakosz/.tmux) framework, with `tmux-resurrect` + `tmux-continuum` for session persistence |
| Sessions | [sesh](https://github.com/joshmedeski/sesh) + fzf + zoxide — jump across repos |
| Editor | Neovim with a [lazy.nvim](https://lazy.folke.io) config (native LSP, blink.cmp, treesitter, which-key) |
| Font | MesloLGS Nerd Font (complete) |

## Repository Structure

```sh
.
├── .github/                     # CODEOWNERS, dependabot, release workflow
├── aws/                         # ~/.aws config + credentials TEMPLATE (placeholders)
├── brew/Brewfile                # `brew bundle` package list
├── nvim/                        # lazy.nvim config → ~/.config/nvim (see nvim/README.md)
├── powershell_config/           # Windows profile
├── scripts/
│   ├── bootstrap_terminal.sh    # installs oh-my-zsh, gpakosz tmux, tpm, nvim warmup
│   ├── mac_utils.sh             # Homebrew install/update/cleanup helpers
│   ├── debian_utils.sh
│   ├── rhel_utils.sh
│   └── windows_utils.ps1
├── ssh/config                   # ~/.ssh/config
├── vim/                         # legacy vim config + .vimrc
├── zsh_config/
│   ├── .zshrc
│   ├── starship.toml            # → ~/.config/starship.toml
│   ├── sesh.toml                # → ~/.config/sesh/sesh.toml
│   ├── tmux.conf.local          # → ~/.tmux.conf.local (gpakosz user config)
│   ├── iterm_yash_personal.json # iTerm profile (font already set to the Nerd Font)
│   └── install.txt              # manual-install reference (now automated)
├── .gitconfig
├── Makefile
└── README.md
```

## Getting Started

### Prerequisites

- **Homebrew** installed (macOS). The `.zshrc` expects Homebrew at `~/homebrew`
  (a non-standard, no-sudo prefix). If yours is at `/opt/homebrew` or
  `/usr/local`, adjust the `PATH`/`HOMEBREW_PREFIX` lines in `zsh_config/.zshrc`
  before running, or the tmux auto-attach and brew lookups won't resolve.
- **An SSH key registered with GitHub** — needed to clone this repo in the first
  place (`git@github.com:yasharma28/initial-setup.git`).

### Setup

```sh
git clone git@github.com:yasharma28/initial-setup.git
cd initial-setup
make mac_setup
```

`mac_setup` runs `backup` first (snapshots existing `~/.zshrc`, `~/.aws`,
`~/.ssh/config`, etc. with a dated `.BAK` suffix), then installs Homebrew
packages, deploys the dotfiles, and runs `bootstrap_terminal.sh` to install
oh-my-zsh, the gpakosz tmux framework, tpm + its plugins, and warm up Neovim.

### Remaining manual steps

Two things can't be fully automated:

1. **iTerm font / profile** — import `zsh_config/iterm_yash_personal.json`
   (iTerm → Settings → Profiles → Other Actions → Import JSON Profiles). Its
   font is already set to `MesloLGS Nerd Font Mono`, so icons render with no
   tofu. If you skip the import, set the profile font to that family manually.
2. **First nvim launch** — the warmup is best-effort; if it was skipped (e.g.
   `nvim` wasn't on `PATH` yet), the first `nvim` launch finishes installing
   plugins and compiling treesitter parsers automatically.

### Targets

```sh
make              # detect OS and run the matching *_setup
make mac_setup    # macOS
make debian_setup # Debian
make rhel_setup   # RHEL
make windows_setup
make help
```

## Configuration Details

- **Git** — `.gitconfig` / `.gitignore`.
- **AWS** — `aws/` holds a `config` + a `credentials` **template** with
  placeholders; fill them in after setup. `backup` snapshots any existing
  `~/.aws` before overwriting.
- **Editors** — Neovim (`nvim/`, the active config — see `nvim/README.md`) and
  legacy Vim (`vim/`).
- **Shell** — `zsh_config/` holds the zsh, Starship, sesh, and tmux configs.

## Scripts

- **bootstrap_terminal.sh** — idempotent installer for oh-my-zsh, gpakosz tmux,
  tpm + plugins, and the Neovim warmup. Safe to re-run.
- **mac_utils.sh** — Homebrew install (`-i`), update/cleanup/save (`-a`), and
  AWS profile env helpers.
- **debian_utils.sh / rhel_utils.sh / windows_utils.ps1** — per-OS helpers.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Fork and open a PR. The release workflow tags a new version when a PR whose
title contains `major`/`minor`/`patch` is merged.

## Contact

[Yash Sharma](mailto:yasharma28@gmail.com) · [Issues](https://github.com/yasharma28/initial-setup/issues)
