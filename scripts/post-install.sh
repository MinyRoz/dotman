#!/usr/bin/env bash
#
# Example post-install hook. Runs after links + packages.
# dotman exports DOTFILES_ROOT and OS into the environment.
set -euo pipefail

echo ":: post-install hook running (os=${OS:-unknown})"

# Example: ensure a directory for machine-local secrets exists.
mkdir -p "$HOME/.config/shell"

# Example: set git identity only if it is not already configured.
if command -v git >/dev/null 2>&1 && [ -z "$(git config --global user.email || true)" ]; then
  echo ":: tip: set your git identity with"
  echo "     git config --global user.name  'Your Name'"
  echo "     git config --global user.email 'you@example.com'"
fi

echo ":: post-install hook complete"
