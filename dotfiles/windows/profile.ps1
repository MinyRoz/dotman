# Sample PowerShell profile managed by dotman.
# Linked to $PROFILE on Windows.

Set-Alias ll Get-ChildItem
Set-Alias g  git

function gs { git status -sb }
function gd { git diff }
function .. { Set-Location .. }

# Friendlier defaults.
$PSDefaultParameterValues['Out-Default:OutVariable'] = 'LastOutput'
if (Get-Module -ListAvailable PSReadLine) {
  Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
}

# Per-machine overrides (not tracked).
$local = Join-Path (Split-Path $PROFILE) 'profile.local.ps1'
if (Test-Path $local) { . $local }
