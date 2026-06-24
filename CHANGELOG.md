# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-24

### Added
- Bash CLI (`bin/dotman`) for Linux, macOS, WSL, and Git Bash.
- PowerShell CLI (`bin/dotman.ps1`) for Windows with symlink/copy fallback.
- Declarative manifest (`dotman.conf`) with per-OS sections (`.linux`, `.macos`,
  `.windows`, `.wsl`).
- Commands: `install`, `status`, `unlink`, `doctor`, `version`, `help`.
- `--dry-run` and `--force` options.
- Timestamped backups of replaced files.
- Package installation across `brew`, `apt`, `dnf`, `pacman`, `apk`, `pkg`,
  `winget`, `scoop`, `choco`.
- Pre/post hook scripts.
- Remote bootstrap installers (`install.sh`, `install.ps1`).
- CI linting via shellcheck and PSScriptAnalyzer.
