#!/bin/zsh
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "$0")/.." && pwd)"
SETTINGS_FILE="$REPO_DIR/stow/zed/.config/zed/settings.json"
INDEX_FILE="${1:-$HOME/Library/Application Support/Zed/extensions/index.json}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "error: missing Zed extension index: $INDEX_FILE" >&2
  exit 1
fi

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "error: missing settings file: $SETTINGS_FILE" >&2
  exit 1
fi

tmp="$(mktemp)"

jq '
  .auto_install_extensions =
    ((input.extensions // {})
      | with_entries(
          select((.value.dev // false) == false and (.key | startswith("zed-") | not))
        )
      | map_values(true))
' "$SETTINGS_FILE" "$INDEX_FILE" > "$tmp"

mv "$tmp" "$SETTINGS_FILE"
echo "Updated auto_install_extensions in $SETTINGS_FILE from $INDEX_FILE"
