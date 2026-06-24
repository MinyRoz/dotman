#!/usr/bin/env bash
#
# dotman bootstrap (Linux / macOS / WSL / Git Bash).
# Clones your dotfiles repo and runs `dotman install`.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/MinyRoz/dotman/main/install.sh | bash
#
# Environment overrides:
#   DOTFILES_REPO   git URL to clone   (default: this repo)
#   DOTFILES_DIR    where to clone it  (default: ~/.dotfiles)
#   DOTFILES_BRANCH branch to checkout (default: main)

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/MinyRoz/dotman.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

command -v git >/dev/null 2>&1 || { echo "git is required but not installed." >&2; exit 1; }

if [ -d "$DOTFILES_DIR/.git" ]; then
  say "Updating existing checkout in $DOTFILES_DIR"
  git -C "$DOTFILES_DIR" pull --ff-only
else
  say "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
  git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

chmod +x "$DOTFILES_DIR/bin/dotman" 2>/dev/null || true

say "Running dotman install"
"$DOTFILES_DIR/bin/dotman" install "$@"

say "All set. Add '$DOTFILES_DIR/bin' to your PATH to use 'dotman' anywhere."
