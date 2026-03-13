#!/usr/bin/env bash
set -euo pipefail

commands=(
  "🌋 basalt"
  "📊 btop"
  "🤖 claude"
  "🌳 claude --worktree"
  "📦 codex"
  "🐕 k9s"
  "🐳 lazydocker"
  "🔀 lazygit"
  "🌿 nvim"
  "⚡ opencode"
  "🥧 pi"
  "🏎️  sidecar"
  "📁 yazi"
)

selected=$(printf '%s\n' "${commands[@]}" | fzf --prompt="🚀 Launch > " --reverse --border=rounded) || true

if [[ -n "$selected" ]]; then
  # Strip emoji prefix; second strip catches multi-codepoint emojis with extra spacing
  cmd="${selected#* }"
  cmd="${cmd# }"
  # Word-splitting is intentional (handles "claude --worktree")
  zellij run -- $cmd
fi
