#!/bin/zsh
set -euo pipefail

# Wrapper entrypoint for the mac setup bootstrap
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
export DOTFILES_DIR

if [[ "${1:-}" == "--dry-run" ]]; then
  exec "$SCRIPT_DIR/bootstrap/bootstrap-mac.zsh" --dry-run
fi

exec "$SCRIPT_DIR/bootstrap/bootstrap-mac.zsh"
