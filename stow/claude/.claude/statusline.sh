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

# Extract fields; "// fallback" handles null
MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
VIM_MODE=$(echo "$input" | jq -r '.vim.mode // ""')
