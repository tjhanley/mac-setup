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

# Git status — cached to avoid lag on large repos
# Key cache by directory so switching projects gets fresh git info
CACHE_DIR_KEY=$(printf '%s' "$DIR" | md5 2>/dev/null || printf '%s' "$DIR" | md5sum 2>/dev/null | cut -d' ' -f1)
CACHE_FILE="/tmp/statusline-git-cache-${CACHE_DIR_KEY}"
CACHE_MAX_AGE=5  # seconds

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] && return 0
    local age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [ "$age" -gt "$CACHE_MAX_AGE" ]
}

if cache_is_stale; then
    if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
        STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        printf '1|%s|%s|%s\n' "$BRANCH" "$STAGED" "$MODIFIED" > "$CACHE_FILE"
    else
        printf '0|||\n' > "$CACHE_FILE"
    fi
fi

IFS='|' read -r IS_GIT BRANCH STAGED MODIFIED < "$CACHE_FILE"

# Context bar (10 chars wide)
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY"  -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Cost formatting
COST_FMT=$(awk -v c="$COST" 'BEGIN { printf "$%.2f\n", c+0 }')

# Separator — reset colors then half-block
SEP="${RESET}▌"

# --- Model segment (always shown) ---
LINE="${BG_BLUE}${FG_BASE}${BOLD} ${MODEL} "

# --- Git segment (only in git repos) ---
if [ "${IS_GIT:-0}" = "1" ]; then
    GIT_BG="$BG_GREEN"
    GIT_DIRTY=0
    [ "${STAGED:-0}" -gt 0 ] || [ "${MODIFIED:-0}" -gt 0 ] && GIT_DIRTY=1
    [ "$GIT_DIRTY" = "1" ] && GIT_BG="$BG_YELLOW"

    GIT_TEXT=" ${BRANCH}"
    [ "${STAGED:-0}"   -gt 0 ] && GIT_TEXT="${GIT_TEXT} +${STAGED}"
    [ "${MODIFIED:-0}" -gt 0 ] && GIT_TEXT="${GIT_TEXT} ~${MODIFIED}"

    LINE="${LINE}${SEP}${GIT_BG}${FG_BASE}${BOLD}${GIT_TEXT} "
fi

# --- Context + cost segment (always shown) ---
LINE="${LINE}${SEP}${BG_MAUVE}${FG_BASE}${BOLD} ${BAR} ${PCT}% ${COST_FMT} "

# --- Vim mode segment (only when vim mode enabled) ---
if [ -n "$VIM_MODE" ]; then
    VIM_BG="$BG_GREEN"
    [ "$VIM_MODE" = "NORMAL" ] && VIM_BG="$BG_YELLOW"
    LINE="${LINE}${SEP}${VIM_BG}${FG_BASE}${BOLD} ${VIM_MODE} "
fi

LINE="${LINE}${RESET}"
printf '%b\n' "$LINE"
