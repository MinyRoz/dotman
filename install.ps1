<#
.SYNOPSIS
  dotman bootstrap for Windows. Clones your dotfiles repo and runs install.
.DESCRIPTION
  Run from PowerShell:
    irm https://raw.githubusercontent.com/MinyRoz/dotman/main/install.ps1 | iex
.NOTES
  Overridable via env vars: DOTFILES_REPO, DOTFILES_DIR, DOTFILES_BRANCH.
#>
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'

$Repo   = if ($env:DOTFILES_REPO)   { $env:DOTFILES_REPO }   else { 'https://github.com/MinyRoz/dotman.git' }
$Dir    = if ($env:DOTFILES_DIR)    { $env:DOTFILES_DIR }    else { Join-Path $HOME '.dotfiles' }
$Branch = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { 'main' }

function Say { param($m) Write-Host ":: $m" -ForegroundColor Blue }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required but not installed. Install it (e.g. 'winget install Git.Git') and retry."
}

if (Test-Path (Join-Path $Dir '.git')) {
  Say "Updating existing checkout in $Dir"
  git -C $Dir pull --ff-only
} else {
  Say "Cloning $Repo -> $Dir"
  git clone --branch $Branch $Repo $Dir
}

Say "Running dotman install"
$dotman = Join-Path $Dir 'bin\dotman.ps1'
if ($DryRun) { & $dotman install -DryRun } else { & $dotman install }

Say "All set. Add '$Dir\bin' to your PATH to use dotman anywhere."
