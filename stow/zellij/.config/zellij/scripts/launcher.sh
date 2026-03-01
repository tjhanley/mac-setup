#!/usr/bin/env bash
set -euo pipefail

commands=(
  "lazygit"
  "lazydocker"
  "k9s"
  "htop"
  "yazi"
  "fastfetch"
)

selected=$(printf '%s\n' "${commands[@]}" | fzf --prompt="Launch > " --reverse --border=rounded)
if [[ -n "$selected" ]]; then
  zellij run -- $selected
fi
