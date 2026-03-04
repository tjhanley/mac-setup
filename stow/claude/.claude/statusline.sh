#!/bin/bash
# Claude Code status line — Catppuccin Mocha powerline style
# Receives JSON session data on stdin, prints a single colored line
# Requires a Nerd Font (BlexMono Nerd Font configured in Ghostty)

input=$(cat)

# Catppuccin Mocha — truecolor ANSI
BG_BLUE='\033[48;2;137;180;250m'
BG_GREEN='\033[48;2;166;227;161m'
BG_YELLOW='\033[48;2;249;226;175m'
BG_MAUVE='\033[48;2;203;166;247m'
FG_BASE='\033[38;2;30;30;46m'
FG_DIM='\033[38;2;108;112;134m'   # Catppuccin Mocha overlay0 — for empty bar portion

# Foreground versions of segment bg colors — used for powerline arrow transitions
FG_BLUE='\033[38;2;137;180;250m'
FG_GREEN='\033[38;2;166;227;161m'
FG_YELLOW='\033[38;2;249;226;175m'
FG_MAUVE='\033[38;2;203;166;247m'

BOLD='\033[1m'
RESET='\033[0m'

# Nerd Font powerline glyphs (requires BlexMono Nerd Font)
SEP=''   # U+E0B0 right-arrow: fg=prev_bg, bg=next_bg → seamless segment join
CAP_L='' # U+E0B6 left rounded cap: fg=first_seg_bg, bg=terminal
CAP_R='' # U+E0B4 right rounded cap: fg=last_seg_bg, bg=terminal
CHIP=''   # U+F2DB fa-microchip — model glyph
BRANCH='' # U+E0A0 Powerline VCS branch glyph

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
        BRANCH_NAME=$(git -C "$DIR" branch --show-current 2>/dev/null)
        STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        printf '1|%s|%s|%s\n' "$BRANCH_NAME" "$STAGED" "$MODIFIED" > "$CACHE_FILE"
    else
        printf '0|||\n' > "$CACHE_FILE"
    fi
fi

IFS='|' read -r IS_GIT BRANCH_NAME STAGED MODIFIED < "$CACHE_FILE"

# Context bar — ━ (heavy) for filled, ─ (light) for empty — clear contrast, no shading artifacts
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR="${FG_BASE}$(printf "%${FILLED}s" | tr ' ' '━')"
[ "$EMPTY"  -gt 0 ] && BAR="${BAR}${FG_DIM}$(printf "%${EMPTY}s" | tr ' ' '─')"
BAR="${BAR}${FG_BASE}"  # restore fg after bar

# Cost formatting
COST_FMT=$(awk -v c="$COST" 'BEGIN { printf "$%.2f\n", c+0 }')

# Determine git bg/fg colors based on dirty state
GIT_BG="$BG_GREEN"; GIT_FG="$FG_GREEN"
if [ "${IS_GIT:-0}" = "1" ]; then
    GIT_DIRTY=0
    [ "${STAGED:-0}" -gt 0 ] || [ "${MODIFIED:-0}" -gt 0 ] && GIT_DIRTY=1
    [ "$GIT_DIRTY" = "1" ] && GIT_BG="$BG_YELLOW" && GIT_FG="$FG_YELLOW"
fi

# Determine vim bg/fg colors
VIM_BG="$BG_GREEN"; VIM_FG="$FG_GREEN"
[ "$VIM_MODE" = "NORMAL" ] && VIM_BG="$BG_YELLOW" && VIM_FG="$FG_YELLOW"

# Build line — each transition uses: fg=prev_bg, bg=next_bg, then SEP char
# This creates seamless Nerd Font powerline arrows between colored segments

# — Left rounded cap + Model segment —
LINE="${RESET}${FG_BLUE}${CAP_L}${BG_BLUE}${FG_BASE}${BOLD} ${CHIP} ${MODEL} "

if [ "${IS_GIT:-0}" = "1" ]; then
    GIT_TEXT="${BRANCH} ${BRANCH_NAME}"
    [ "${STAGED:-0}"   -gt 0 ] && GIT_TEXT="${GIT_TEXT} +${STAGED}"
    [ "${MODIFIED:-0}" -gt 0 ] && GIT_TEXT="${GIT_TEXT} ~${MODIFIED}"

    # Model → Git
    LINE="${LINE}${FG_BLUE}${GIT_BG}${SEP}${FG_BASE}${BOLD} ${GIT_TEXT} "
    # Git → Context
    LINE="${LINE}${GIT_FG}${BG_MAUVE}${SEP}${FG_BASE}${BOLD} ${BAR} ${PCT}% ${COST_FMT} "
else
    # Model → Context
    LINE="${LINE}${FG_BLUE}${BG_MAUVE}${SEP}${FG_BASE}${BOLD} ${BAR} ${PCT}% ${COST_FMT} "
fi

if [ -n "$VIM_MODE" ]; then
    # Context → Vim
    LINE="${LINE}${FG_MAUVE}${VIM_BG}${SEP}${FG_BASE}${BOLD} ${VIM_MODE} "
    # Vim → right rounded cap
    LINE="${LINE}${RESET}${VIM_FG}${CAP_R}${RESET}"
else
    # Context → right rounded cap
    LINE="${LINE}${RESET}${FG_MAUVE}${CAP_R}${RESET}"
fi

printf '%b\n' "$LINE"
