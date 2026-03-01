#!/usr/bin/env bash
set -euo pipefail

commands=(
  "basalt"
  "fastfetch"
  "htop"
  "k9s"
  "lazydocker"
  "lazygit"
  "nvim"
  "yazi"
)

selected=$(printf '%s\n' "${commands[@]}" | fzf --prompt="Launch > " --reverse --border=rounded)
if [[ -n "$selected" ]]; then
  zellij run -- $selected
fi
