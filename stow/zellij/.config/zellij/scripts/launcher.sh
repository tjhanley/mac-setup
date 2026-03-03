#!/usr/bin/env bash
set -euo pipefail

# label|command — fzf shows the label, we extract the command after |
entries=(
  "🌋 basalt|basalt"
  "📊 btop|btop"
  "🤖 claude|claude"
  "🌳 claude --worktree|claude --worktree"
  "📦 codex|codex"
  "☸️  k9s|k9s"
  "🐳 lazydocker|lazydocker"
  "🔀 lazygit|lazygit"
  "✏️  nvim|nvim"
  "🏎️  sidecar|sidecar"
  "📁 yazi|yazi"
)

selected=$(printf '%s\n' "${entries[@]}" | fzf --prompt="🚀 Launch > " --reverse --border=rounded --with-nth=1 --delimiter='|') || true

if [[ -n "$selected" ]]; then
  # Word-splitting on $cmd is intentional (handles "claude --worktree")
  cmd="${selected#*|}"
  zellij run -- $cmd
fi
