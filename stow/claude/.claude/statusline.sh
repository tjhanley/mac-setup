#!/bin/bash
# Claude Code status line — Catppuccin Mocha powerline style
# Receives JSON session data on stdin, prints a single colored line

input=$(cat)

# Catppuccin Mocha — truecolor ANSI
BG_BLUE='\033[48;2;137;180;250m'
BG_GREEN='\033[48;2;166;227;161m'
BG_YELLOW='\033[48;2;249;226;175m'
BG_MAUVE='\033[48;2;203;166;247m'
FG_BASE='\033[38;2;30;30;46m'
BOLD='\033[1m'
RESET='\033[0m'

# Extract all fields in one jq call
IFS=$'\t' read -r MODEL DIR PCT COST VIM_MODE < <(
  echo "$input" | jq -r '[
    (.model.display_name // "claude"),
    (.workspace.current_dir // ""),
    ((.context_window.used_percentage // 0) | floor | tostring),
    (.cost.total_cost_usd // 0 | tostring),
    (.vim.mode // "")
  ] | @tsv'
)
