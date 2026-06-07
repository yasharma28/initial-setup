# Reference

## Make targets

| Target | Does |
|--------|------|
| `help` | List targets (default) |
| `setup` | Detect OS, back up, run the matching `*_setup` |
| `backup` | Snapshot existing dotfiles to dated `.BAK` copies |
| `mac_setup` | macOS: brew install → stow → bootstrap (`PROFILE=personal\|work`) |
| `debian_setup` / `rhel_setup` | Linux: install stack → stow → bootstrap |
| `windows_setup` | Windows: run `windows_utils.ps1` |
| `lint` | `shellcheck` + `stylua --check` + `yamllint` |
| `unlink` | `stow -D` — remove the symlinks |
| `clean` | Remove dated `.BAK` / pre-stow backups from `$HOME` |

## Scripts

| Script | Role |
|--------|------|
| `link.sh` | Stow wrapper; backs up conflicts, never touches keys/creds |
| `bootstrap_terminal.sh` | Installs oh-my-zsh, gpakosz tmux, tpm + plugins, nvim warmup |
| `mac_utils.sh` | `brew bundle` (split Brewfiles), update/upgrade/cleanup, snapshot |
| `debian_utils.sh` / `rhel_utils.sh` | Install terminal stack (`-i`); system update (`-u`, root) |
| `windows_utils.ps1` | Import winget manifests + deploy PowerShell profile/theme |

## Layout

```
.
├── brew/Brewfile{,.personal,.work}   # core + profile overlays
├── docs/                             # this documentation (Divio)
├── iterm/                            # iTerm profile (imported manually, not stowed)
├── powershell_config/                # Windows profile, theme, winget manifests
├── scripts/                          # provisioning + link.sh
├── stow/                             # per-tool dotfile packages (symlinked to $HOME)
│   ├── zsh tmux starship sesh        # shell/terminal
│   ├── nvim vim                      # editors
│   └── git ssh aws                   # git identity, ssh config, aws SSO config
├── .yamllint  Makefile  plan.md  README.md
```

## Brewfiles

- `brew/Brewfile` — core: terminal stack, DevOps CLIs, fonts, dev apps, VS Code extensions.
- `brew/Brewfile.personal` — comms/media/office/personal-account apps.
- `brew/Brewfile.work` — stub for work-only tools.
- `brew/Brewfile.dump` — scratch snapshot from `mac_utils.sh -s` (gitignored).
