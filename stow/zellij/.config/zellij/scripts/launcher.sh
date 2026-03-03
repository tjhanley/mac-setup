#!/usr/bin/env bash
set -euo pipefail

commands=(
  basalt
  btop
  claude
  "claude --worktree"
  codex
  k9s
  lazydocker
  lazygit
  nvim
  sidecar
  yazi
)

declare -A icons=(
  [basalt]="🌋"
  [btop]="📊"
  [claude]="🤖"
  [claude --worktree]="🌳"
  [codex]="📦"
  [k9s]="☸️"
  [lazydocker]="🐳"
  [lazygit]="🔀"
  [nvim]="✏️"
  [sidecar]="🏎️"
  [yazi]="📁"
)

selected=$(
  for c in "${commands[@]}"; do
    printf '%s %s\n' "${icons[$c]:-${icons[${c%% *}]:-}}" "$c"
  done | fzf --prompt="🚀 Launch > " --reverse --border=rounded
) || true

if [[ -n "$selected" ]]; then
  # Strip emoji prefix; word-splitting on $cmd is intentional (handles "claude --worktree")
  cmd="${selected#* }"
  zellij run -- $cmd
fi
