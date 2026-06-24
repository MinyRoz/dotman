<#
.SYNOPSIS
  dotman - a portable, dependency-free dotfiles manager (Windows / PowerShell).
.DESCRIPTION
  Reads dotman.conf and symlinks (or copies) dotfiles into place, installs
  packages, and runs hooks. Mirrors the behaviour of the bash `dotman` CLI.
.EXAMPLE
  ./bin/dotman.ps1 install -DryRun
  ./bin/dotman.ps1 status
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Command = 'help',

  [Alias('n')][switch]$DryRun,
  [Alias('f')][switch]$Force,
  [Alias('c')][string]$Config
)

$ErrorActionPreference = 'Stop'
$DotmanVersion = '1.0.0'

# --- Paths -----------------------------------------------------------------
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesRoot = if ($env:DOTFILES_ROOT) { $env:DOTFILES_ROOT } else { Split-Path -Parent $ScriptDir }
$ConfigFile  = if ($Config) { $Config }
               elseif ($env:DOTMAN_CONFIG) { $env:DOTMAN_CONFIG }
               else { Join-Path $DotfilesRoot 'dotman.conf' }
$Stamp       = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir   = if ($env:DOTMAN_BACKUP_DIR) { $env:DOTMAN_BACKUP_DIR }
               else { Join-Path $HOME ".dotman-backups\$Stamp" }
$OS = 'windows'

# --- Output ----------------------------------------------------------------
function Write-Info  { param($m) Write-Host "[*] $m" -ForegroundColor Blue }
function Write-Ok    { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn  { param($m) Write-Host "[!] $m" -ForegroundColor Yellow }
function Write-Err   { param($m) Write-Host "[x] $m" -ForegroundColor Red }
function Write-Header{ param($m) Write-Host "`n$m" -ForegroundColor White }

# --- Path expansion --------------------------------------------------------
function Expand-DestPath {
  param([string]$Path)
  # Map common cross-platform tokens onto Windows equivalents.
  $p = $Path
  $p = $p -replace '^~', $HOME
  $p = $p -replace '\$\{?HOME\}?', $HOME
  $p = $p -replace '\$\{?XDG_CONFIG_HOME\}?', (Join-Path $HOME '.config')
  if ($p -match '\$PROFILE') { $p = $p -replace '\$PROFILE', $PROFILE }
  # Expand %VAR% and remaining $env references.
  $p = [System.Environment]::ExpandEnvironmentVariables($p)
  return $p
}

# --- Manifest parser -------------------------------------------------------
function Get-Section {
  param([string]$Want)
  if (-not (Test-Path $ConfigFile)) { throw "Config not found: $ConfigFile" }
  $active = $false
  $result = @()
  foreach ($raw in Get-Content -LiteralPath $ConfigFile) {
    $line = $raw.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    if ($line -match '^\[(.+)\]$') {
      $sec = $Matches[1].Trim()
      $active = ($sec -eq $Want -or $sec -eq "$Want.$OS")
      continue
    }
    if ($active) { $result += $raw.Trim() }
  }
  return $result
}

# --- Linking ---------------------------------------------------------------
function Backup-Existing {
  param([string]$Dest)
  if (Test-Path -LiteralPath $Dest) {
    if ($DryRun) { Write-Info "would back up $Dest"; return }
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }
    $name = ($Dest -replace '[\\/:]', '_')
    Move-Item -LiteralPath $Dest -Destination (Join-Path $BackupDir $name) -Force
    Write-Warn "backed up existing $Dest"
  }
}

function New-DotLink {
  param([string]$Src, [string]$Dest)
  if (-not (Test-Path -LiteralPath $Src)) { Write-Warn "source missing, skipping: $Src"; return }

  $parent = Split-Path -Parent $Dest
  if ($parent -and -not (Test-Path $parent)) {
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  }

  # Already linked correctly?
  $existing = Get-Item -LiteralPath $Dest -ErrorAction SilentlyContinue
  if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $Src) {
    Write-Ok "linked (unchanged) $Dest"; return
  }

  if (Test-Path -LiteralPath $Dest) {
    if ($Force) { if (-not $DryRun) { Remove-Item -LiteralPath $Dest -Recurse -Force } }
    else { Backup-Existing $Dest }
  }

  if ($DryRun) { Write-Info "would link $Dest -> $Src"; return }

  try {
    New-Item -ItemType SymbolicLink -Path $Dest -Target $Src -Force | Out-Null
    Write-Ok "linked $Dest -> $Src"
  } catch {
    # Symlinks need admin or Developer Mode on Windows; fall back to a copy.
    Copy-Item -LiteralPath $Src -Destination $Dest -Recurse -Force
    Write-Warn "copied (symlink needs admin/Developer Mode) $Dest"
  }
}

function Invoke-Install {
  Write-Header "dotman install ($OS)"
  Invoke-Hooks 'hooks.pre'

  $count = 0
  foreach ($line in (Get-Section 'link')) {
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { continue }
    $src  = Join-Path $DotfilesRoot $parts[0]
    $dest = Expand-DestPath $parts[1]
    New-DotLink $src $dest
    $count++
  }
  if ($count -eq 0) { Write-Warn "no [link] entries found in $ConfigFile" }

  Install-Packages
  Invoke-Hooks 'hooks.post'
  Write-Header "Done. Backups (if any) in $BackupDir"
}

function Invoke-Status {
  Write-Header "dotman status ($OS)"
  foreach ($line in (Get-Section 'link')) {
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { continue }
    $src  = Join-Path $DotfilesRoot $parts[0]
    $dest = Expand-DestPath $parts[1]
    $item = Get-Item -LiteralPath $dest -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $src) {
      Write-Ok $dest
    } elseif (Test-Path -LiteralPath $dest) {
      Write-Warn "$dest (exists, not managed)"
    } else {
      Write-Err "$dest (missing)"
    }
  }
}

function Invoke-Unlink {
  Write-Header "dotman unlink ($OS)"
  foreach ($line in (Get-Section 'link')) {
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { continue }
    $src  = Join-Path $DotfilesRoot $parts[0]
    $dest = Expand-DestPath $parts[1]
    $item = Get-Item -LiteralPath $dest -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $src) {
      if ($DryRun) { Write-Info "would remove $dest"; continue }
      Remove-Item -LiteralPath $dest -Force
      Write-Ok "removed $dest"
    }
  }
}

# --- Packages --------------------------------------------------------------
function Test-Have { param($cmd) [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Install-Packages {
  foreach ($line in (Get-Section 'packages')) {
    $mgr, $rest = $line -split ':', 2
    $mgr = $mgr.Trim()
    if (-not $rest) { continue }
    $pkgs = $rest.Trim() -split '\s+'
    if (-not (Test-Have $mgr)) { Write-Warn "package manager '$mgr' not found, skipping: $($pkgs -join ' ')"; continue }
    Write-Info "installing via ${mgr}: $($pkgs -join ' ')"
    if ($DryRun) { continue }
    switch ($mgr) {
      'winget' { foreach ($p in $pkgs) { winget install --silent --accept-package-agreements --accept-source-agreements -e --id $p } }
      'choco'  { choco install -y @pkgs }
      'scoop'  { scoop install @pkgs }
      default  { & $mgr install @pkgs }
    }
  }
}

# --- Hooks -----------------------------------------------------------------
function Invoke-Hooks {
  param([string]$Section)
  foreach ($line in (Get-Section $Section)) {
    $script = Join-Path $DotfilesRoot $line
    if (-not (Test-Path $script)) { Write-Warn "hook not found: $line"; continue }
    Write-Info "hook: $line"
    if ($DryRun) { continue }
    $env:DOTFILES_ROOT = $DotfilesRoot; $env:OS_NAME = $OS
    if ($script -match '\.ps1$') { & $script }
    elseif (Test-Have 'bash')    { bash $script }
    else { Write-Warn "no interpreter for hook: $line" }
  }
}

# --- Doctor ----------------------------------------------------------------
function Invoke-Doctor {
  Write-Header "dotman doctor"
  Write-Info "version:     $DotmanVersion"
  Write-Info "os:          windows ($([System.Environment]::OSVersion.VersionString))"
  Write-Info "powershell:  $($PSVersionTable.PSVersion)"
  Write-Info "repo root:   $DotfilesRoot"
  Write-Info "config:      $ConfigFile"
  if (Test-Path $ConfigFile) { Write-Ok "config found" } else { Write-Err "config missing" }
  Write-Info "home:        $HOME"
  # Developer Mode controls symlink creation without admin.
  $dev = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
  if ($dev -and $dev.AllowDevelopmentWithoutDevLicense -eq 1) { Write-Ok "Developer Mode on (symlinks allowed)" }
  else { Write-Warn "Developer Mode off - symlinks need admin; dotman will copy instead" }
  foreach ($m in 'winget','scoop','choco','git') {
    if (Test-Have $m) { Write-Ok "$m available" } else { Write-Warn "$m not found" }
  }
}

function Show-Help {
  @"
dotman v$DotmanVersion - portable dotfiles manager (Windows)

USAGE
  ./bin/dotman.ps1 <command> [-DryRun] [-Force] [-Config <path>]

COMMANDS
  install     Symlink dotfiles, install packages, run hooks
  status      Show which managed files are linked / missing / unmanaged
  unlink      Remove symlinks created by dotman
  doctor      Print environment diagnostics
  version     Print version
  help        Show this help

OPTIONS
  -DryRun, -n   Show what would happen without changing anything
  -Force,  -f   Replace existing files instead of backing them up
  -Config, -c   Use an alternate manifest (default: dotman.conf)

EXAMPLES
  ./bin/dotman.ps1 install -DryRun
  ./bin/dotman.ps1 install
  ./bin/dotman.ps1 status
"@ | Write-Host
}

# --- Dispatch --------------------------------------------------------------
switch ($Command.ToLower()) {
  'install' { Invoke-Install }
  'link'    { Invoke-Install }
  'status'  { Invoke-Status }
  'ls'      { Invoke-Status }
  'unlink'  { Invoke-Unlink }
  'remove'  { Invoke-Unlink }
  'doctor'  { Invoke-Doctor }
  'version' { Write-Host "dotman $DotmanVersion" }
  default   { Show-Help }
}
