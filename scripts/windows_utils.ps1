# == windows_utils.ps1 ==
# Provisions Windows from the committed winget manifests and deploys the
# PowerShell profile + oh-my-posh theme. It IMPORTS the curated package lists
# (never exports over them, as the old version did).

[CmdletBinding()]
param(
    [ValidateSet('core', 'personal')]
    [string]$Profile = 'core'
)
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PoshDir = Join-Path $RepoRoot 'powershell_config'

function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found — install "App Installer" from the Microsoft Store first.'
    }
}

function Import-Manifest {
    param([string]$Path)
    Write-Host "Importing packages from $Path"
    winget import -i $Path `
        --accept-package-agreements --accept-source-agreements --ignore-unavailable
}

function Deploy-Profile {
    $dest = Join-Path $env:USERPROFILE 'powershell_config'
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item (Join-Path $PoshDir 'oh-my-posh_default.yaml') $dest -Force
    Copy-Item (Join-Path $PoshDir 'Microsoft.PowerShell_profile.ps1') $dest -Force

    # Point the live PowerShell profile at our profile script.
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
    Copy-Item (Join-Path $PoshDir 'Microsoft.PowerShell_profile.ps1') $PROFILE -Force
    Write-Host "Deployed PowerShell profile to $PROFILE"
}

Assert-Winget
Import-Manifest (Join-Path $PoshDir 'packages_windows.json')
if ($Profile -eq 'personal') {
    Import-Manifest (Join-Path $PoshDir 'packages_windows.personal.json')
}
Deploy-Profile
Write-Host 'Windows provisioning complete.'
