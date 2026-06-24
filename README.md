# dotman

> A portable, dependency-free dotfiles manager with automated cross-platform setup.

`dotman` keeps your configuration files (`.gitconfig`, `.bashrc`, your PowerShell
profile, editor settings, …) in one git repository and links them into place on
any machine with a single command. It runs on **Linux, macOS, WSL, and Windows**
with no runtime dependencies beyond `git` and a shell that already ships with the OS.

[![CI](https://github.com/MinyRoz/dotman/actions/workflows/ci.yml/badge.svg)](https://github.com/MinyRoz/dotman/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Why dotman?

- **One repo, every machine.** Clone it anywhere and run one command.
- **Truly cross-platform.** A POSIX `bash` CLI for Unix and a native PowerShell
  CLI for Windows — same manifest, same behaviour.
- **No dependencies.** No Python, Ruby, or Node. Just `git` + your shell.
- **Safe by default.** Existing files are backed up (timestamped) before linking;
  `--dry-run` shows exactly what will happen first.
- **Idempotent.** Run it as many times as you like; already-correct links are left alone.
- **Declarative.** A single readable `dotman.conf` describes links, packages, and hooks,
  with per-OS overrides.

## Quick start

### Linux / macOS / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/MinyRoz/dotman/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/MinyRoz/dotman/main/install.ps1 | iex
```

Or clone and run manually:

```bash
git clone https://github.com/MinyRoz/dotman.git ~/.dotfiles
cd ~/.dotfiles
./bin/dotman install --dry-run   # preview
./bin/dotman install             # apply
```

```powershell
git clone https://github.com/MinyRoz/dotman.git $HOME\.dotfiles
cd $HOME\.dotfiles
./bin/dotman.ps1 install -DryRun  # preview
./bin/dotman.ps1 install          # apply
```

## Making it *your* dotfiles

This repo ships with working example configs so you can try it immediately.
To turn it into your own:

1. **Fork** this repository (or use it as a template).
2. Replace the files under [`dotfiles/`](dotfiles/) with your real configs.
3. Edit [`dotman.conf`](dotman.conf) to map each file to its destination.
4. Commit and push. On any new machine, run the one-liner above.

## Commands

| Command            | Description                                                      |
| ------------------ | ---------------------------------------------------------------- |
| `install`          | Symlink dotfiles, install packages, run hooks                    |
| `status`           | Show which managed files are linked / missing / unmanaged        |
| `unlink`           | Remove the symlinks dotman created                               |
| `doctor`           | Print environment diagnostics                                    |
| `version`          | Print the version                                                |
| `help`             | Show usage                                                       |

### Options

| Option              | Bash             | PowerShell  | Effect                                       |
| ------------------- | ---------------- | ----------- | -------------------------------------------- |
| Dry run             | `-n`/`--dry-run` | `-DryRun`   | Preview changes without touching the disk    |
| Force               | `-f`/`--force`   | `-Force`    | Overwrite existing files instead of backing up |
| Alternate manifest  | `-c FILE`        | `-Config F` | Use a different `.conf` (e.g. work vs. home) |

## The manifest (`dotman.conf`)

A plain-text file. Sections are declared with `[name]`, and any section can be
specialised per OS with a suffix: `.linux`, `.macos`, `.windows`, `.wsl`.

```ini
[link]
dotfiles/gitconfig        ~/.gitconfig
dotfiles/vimrc            ~/.vimrc

[link.windows]
dotfiles/windows/profile.ps1   $PROFILE

[packages.macos]
brew: git neovim ripgrep fzf

[packages.windows]
winget: Git.Git Neovim.Neovim

[hooks.post]
scripts/post-install.sh
```

- **`[link]`** — `<source-in-repo>  <destination>`. Destinations expand
  `~`, `$HOME`, `${XDG_CONFIG_HOME}`, `$PROFILE`, and `%VAR%`.
- **`[packages]`** — `<manager>: <pkg> <pkg> …`. dotman silently skips any
  manager that isn't installed, so one manifest works across machines. Supported:
  `brew`, `apt`, `dnf`, `pacman`, `apk`, `pkg`, `winget`, `scoop`, `choco`.
- **`[hooks.pre]` / `[hooks.post]`** — scripts to run before / after linking.
  `DOTFILES_ROOT` and the detected `OS` are exported into their environment.

## How linking works

- Each managed file becomes a **symlink** pointing back into the repo, so editing
  `~/.gitconfig` edits the tracked file — keep configs versioned effortlessly.
- If the destination already exists, it is **moved to a backup** under
  `~/.dotman-backups/<timestamp>/` (unless you pass `--force`).
- On Windows, symlinks require **Developer Mode** or an elevated shell. If neither
  is available, dotman transparently falls back to copying and tells you. Run
  `dotman doctor` to check.

## Uninstall

```bash
./bin/dotman unlink      # removes dotman-created symlinks (backups are left intact)
```

## Project layout

```
dotman/
├── bin/
│   ├── dotman          # Bash CLI  (Linux / macOS / WSL / Git Bash)
│   └── dotman.ps1      # PowerShell CLI (Windows)
├── dotfiles/           # the actual config files you manage
├── scripts/            # hook scripts
├── dotman.conf         # the manifest
├── install.sh          # remote bootstrap (Unix)
└── install.ps1         # remote bootstrap (Windows)
```

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). CI runs
`shellcheck` and `PSScriptAnalyzer` on every push.

## License

[MIT](LICENSE) © contributors
