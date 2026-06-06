# Windows config

Best-effort Windows setup — the primary, maintained flow is macOS/Linux. Driven
by `scripts/windows_utils.ps1` (invoked by `make windows_setup`).

## Files

| File | Purpose |
|------|---------|
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile — inits oh-my-posh with the committed theme |
| `oh-my-posh_default.yaml` | The committed oh-my-posh theme |
| `packages_windows.json` | winget manifest — core dev/system + DevOps tooling |
| `packages_windows.personal.json` | winget manifest — personal/gaming extras |

## Refreshing the manifests

`winget export` writes the *current machine's* package list. To update a manifest
deliberately (don't let the installer overwrite the curated lists):

```powershell
winget export -o packages_windows.json          # then prune to the curated set
```

`scripts/windows_utils.ps1` **imports** these manifests to provision; it never
exports over them.
