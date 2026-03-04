#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
STOW_DIR="$DOTFILES_DIR/stow"

if [[ ! -d "$STOW_DIR" ]]; then
  print -u2 -- "error: stow directory not found: $STOW_DIR"
  exit 1
fi

cd "$STOW_DIR"
for pkg in */; do
  stow --target="$HOME" --restow "$pkg"
  print -- "stowed: ${pkg%/}"
done
