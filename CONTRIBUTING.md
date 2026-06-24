# Contributing to dotman

Thanks for your interest! dotman aims to stay small, readable, and dependency-free.

## Ground rules

- **No runtime dependencies.** The bash CLI must run on a stock `bash` + coreutils;
  the PowerShell CLI must run on Windows PowerShell 5.1 and PowerShell 7+.
- **Keep the two CLIs in sync.** A feature added to `bin/dotman` should behave the
  same in `bin/dotman.ps1`, and vice versa.
- **Backups before destruction.** Never delete a user's file without a backup unless
  `--force` was explicitly passed.

## Local checks

Before opening a PR, run the same linters CI uses:

```bash
shellcheck bin/dotman install.sh scripts/*.sh
```

```powershell
Invoke-ScriptAnalyzer -Path bin/dotman.ps1, install.ps1 -Recurse
```

## Testing changes safely

Always test with `--dry-run` / `-DryRun` first, and consider pointing dotman at a
throwaway home directory:

```bash
DOTMAN_BACKUP_DIR=/tmp/bak ./bin/dotman install --dry-run
```

## Commit messages

Use clear, imperative subject lines (e.g. "Add scoop package support"). Reference
issues where relevant.

## Adding a package manager

Extend the `case`/`switch` in `install_packages` (bash) and `Install-Packages`
(PowerShell), update the supported-managers list in the README, and add an example
to `dotman.conf` if useful.
