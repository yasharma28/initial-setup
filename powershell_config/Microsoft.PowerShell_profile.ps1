# == PowerShell profile ==
# Initializes oh-my-posh with the repo's committed theme. Falls back to the
# bundled jandedobbeleer theme if the committed one isn't deployed yet.

$theme = "$env:USERPROFILE\powershell_config\oh-my-posh_default.yaml"
if (-not (Test-Path $theme)) {
    $theme = "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"
}
oh-my-posh init pwsh --config $theme | Invoke-Expression
