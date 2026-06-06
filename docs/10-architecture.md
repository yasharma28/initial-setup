# Architecture

How the repo is organized and why. The full decision record (with alternatives
considered) is in [`../plan.md`](../plan.md).

## Deployment: GNU Stow (single source of truth)

Dotfiles live in `stow/` as one package per tool. `scripts/link.sh` runs
`stow` to symlink each package's contents into `$HOME`:

```
stow/zsh/.zshrc                    -> ~/.zshrc
stow/tmux/.tmux.conf.local         -> ~/.tmux.conf.local
stow/starship/.config/starship.toml-> ~/.config/starship.toml
stow/sesh/.config/sesh/sesh.toml   -> ~/.config/sesh/sesh.toml
stow/nvim/.config/nvim/            -> ~/.config/nvim
stow/vim/.vimrc                    -> ~/.vimrc
stow/git/{.gitconfig,.gitmessage.txt,.gitignore} -> ~/...
stow/ssh/.ssh/config               -> ~/.ssh/config
stow/aws/.aws/config               -> ~/.aws/config
```

Because these are **symlinks**, editing a live file edits the repo — no more
copy-back drift. `link.sh` backs up any pre-existing real file (timestamped)
before linking, and never enumerates SSH keys or AWS credentials.

`iterm/` is **not** stowed — the iTerm profile is imported manually (see
[setup](20-setup.md)).

## Profiles: core + personal + work

`make mac_setup` installs the **core** Brewfile (terminal stack, DevOps CLIs,
fonts, dev apps). `PROFILE=personal` or `PROFILE=work` layers
`brew/Brewfile.<profile>` on top. This keeps personal apps off work machines and
vice-versa — the same repo deploys to both.

## Portability + public-safe (no internal infra committed)

The repo is public and deploys to personal *and* work laptops, so nothing
machine-specific or employer-internal is committed:

- The Homebrew prefix is auto-detected (`~/homebrew` → `/opt/homebrew` →
  `/usr/local`).
- Environment endpoints, the IAM role-injector path, and private role aliases
  live in `~/.secrets.sh` (sourced by `.zshrc` if present). Template:
  `stow/zsh/secrets.example.sh`.
- Git identity uses a personal default plus a work conditional include
  (`~/.gitconfig-work`, not committed).
- AWS uses SSO (`stow/aws/.aws/config`); there is no credentials file, and
  `.gitignore` blocks one from ever being committed.

## Accepted deviations from "pin everything"

Brew and winget packages are intentionally **unpinned** — latest is desired for
dev tooling and neither has real version-pinning. Reproducibility instead comes
from `lazy-lock.json` (nvim plugins) and the committed tool configs. GitHub
Actions are pinned by tag (not SHA) for readability; Dependabot bumps them.

## Provisioning flow

```
make mac_setup
  └─ scripts/mac_utils.sh -i [PROFILE]   # brew bundle core (+ overlay)
  └─ scripts/link.sh                     # stow symlink the packages
  └─ scripts/bootstrap_terminal.sh       # oh-my-zsh, gpakosz tmux, tpm, nvim warmup
```

Linux mirrors this (`debian_utils.sh` / `rhel_utils.sh` install the stack from
apt/dnf + official installers, then link + bootstrap). Windows is provisioned by
`scripts/windows_utils.ps1` importing the committed winget manifests.
