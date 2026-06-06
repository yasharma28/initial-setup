# Setup guide

## Prerequisites

- **An SSH key registered with GitHub** to clone the repo.
- **macOS:** [Homebrew](https://brew.sh). Any prefix works — it's auto-detected.
- **Linux:** `sudo` for system package installs.
- **Windows:** winget ("App Installer" from the Microsoft Store) + PowerShell.

## macOS / Linux

```sh
git clone git@github.com:yasharma28/initial-setup.git
cd initial-setup

make mac_setup                    # macOS, core stack
make mac_setup PROFILE=personal   # + personal apps   (or PROFILE=work)

make                              # Linux: auto-detect distro
make debian_setup                 # or explicitly
make rhel_setup
```

`make setup` snapshots existing dotfiles to dated `.BAK` copies first, then:
installs packages → symlinks dotfiles with Stow → bootstraps oh-my-zsh, the
gpakosz tmux framework, tpm + plugins, and warms up Neovim.

On Linux, the system package *update* needs root and is **not** run
automatically: `sudo ./scripts/debian_utils.sh -u` (or `rhel_utils.sh`).

## Windows

```powershell
make windows_setup                       # or:
powershell -File scripts\windows_utils.ps1 -Profile personal
```

Imports the committed winget manifests and deploys the PowerShell profile +
oh-my-posh theme. See [`powershell_config/README.md`](../powershell_config/README.md).

## Manual steps (can't be automated)

1. **Machine-private shell config** — copy `stow/zsh/secrets.example.sh` to
   `~/.secrets.sh` and fill in `VAULT_ADDR`, the IAM injector path, `DOTFILES`,
   and your private role aliases. `.zshrc` sources it if present.
2. **Work git identity** — create `~/.gitconfig-work` with your work name/email.
   It's pulled in for repos under `~/work/` (adjust the `gitdir` in
   `stow/git/.gitconfig` if your work checkouts live elsewhere). Linux users who
   want a non-keychain credential helper set it in `~/.gitconfig.local`.
3. **iTerm font / profile** — import `iterm/iterm_yash_personal.json`
   (iTerm → Settings → Profiles → Other Actions → Import JSON Profiles). The font
   is already `MesloLGS Nerd Font Mono`, so glyphs render with no tofu.
4. **First nvim launch** — the warmup is best-effort; the first real `nvim`
   launch finishes installing plugins and compiling treesitter parsers.
