# Claude Code Status Line Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Catppuccin Mocha powerline-style status line for Claude Code showing model, git status, context usage, session cost, and vim mode pill.

**Architecture:** A single bash script at `stow/claude/.claude/statusline.sh` that reads JSON from stdin and prints a colored single-line status bar. Git info is cached to `/tmp/statusline-git-cache` and refreshed every 5 seconds. The script is wired into `~/.claude/settings.json` (not stowed).

**Tech Stack:** bash, jq (already in Brewfile), ANSI truecolor escape codes, Catppuccin Mocha palette

---

## Color Reference

Catppuccin Mocha ANSI truecolor values used throughout:

| Name   | Hex       | RGB            | Usage                           |
|--------|-----------|----------------|---------------------------------|
| Blue   | `#89b4fa` | 137, 180, 250  | Model segment bg                |
| Green  | `#a6e3a1` | 166, 227, 161  | Git clean bg, INSERT vim pill   |
| Yellow | `#f9e2af` | 249, 226, 175  | Git dirty bg, NORMAL vim pill   |
| Mauve  | `#cba6f7` | 203, 166, 247  | Context + cost segment bg       |
| Base   | `#1e1e2e` | 30, 30, 46     | All segment foreground text     |

ANSI truecolor syntax:
- Foreground: `\033[38;2;R;G;Bm`
- Background: `\033[48;2;R;G;Bm`
- Reset: `\033[0m`

---

### Task 1: Create script skeleton with color constants and data extraction

**Files:**
- Create: `stow/claude/.claude/statusline.sh`

**Step 1: Create the file with shebang, color constants, and JSON parsing**

```bash
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
```

**Step 2: Test extraction with mock input**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":14},"cost":{"total_cost_usd":0.04},"vim":{"mode":"INSERT"}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: Script exits without error (no output yet — segment building comes next)

**Step 3: Commit**

```bash
git add stow/claude/.claude/statusline.sh
git commit -m "feat(statusline): add script skeleton with color constants and JSON parsing"
```

---

### Task 2: Add git caching logic

**Files:**
- Modify: `stow/claude/.claude/statusline.sh`

**Step 1: Append git caching block after the variable extraction**

```bash
# Git status — cached to avoid lag on large repos
CACHE_FILE="/tmp/statusline-git-cache"
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
```

**Step 2: Test in a git repo**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"'"$(pwd)"'"},"context_window":{"used_percentage":14},"cost":{"total_cost_usd":0.04}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: No error; `/tmp/statusline-git-cache` created with `1|main|0|1` (or similar)

```bash
cat /tmp/statusline-git-cache
```

Expected: `1|main|<staged>|<modified>`

**Step 3: Commit**

```bash
git add stow/claude/.claude/statusline.sh
git commit -m "feat(statusline): add 5s cached git branch and dirty status"
```

---

### Task 3: Build and print the powerline segments

**Files:**
- Modify: `stow/claude/.claude/statusline.sh`

**Step 1: Append segment-building and output block**

```bash
# Context bar (10 chars wide)
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY"  -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Cost formatting
COST_FMT=$(printf '$%.2f' "$COST")

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
```

**Step 2: Make executable**

```bash
chmod +x stow/claude/.claude/statusline.sh
```

**Step 3: Test — no vim mode (field absent)**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"'"$(pwd)"'"},"context_window":{"used_percentage":14},"cost":{"total_cost_usd":0.04}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: Colored single line with model + git + context segments; no vim pill

**Step 4: Test — INSERT mode**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"'"$(pwd)"'"},"context_window":{"used_percentage":14},"cost":{"total_cost_usd":0.04},"vim":{"mode":"INSERT"}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: Same line plus green `INSERT` pill on the right

**Step 5: Test — NORMAL mode**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"'"$(pwd)"'"},"context_window":{"used_percentage":14},"cost":{"total_cost_usd":0.04},"vim":{"mode":"NORMAL"}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: Same line plus yellow `NORMAL` pill on the right

**Step 6: Test — outside git repo**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":0},"cost":{"total_cost_usd":0}}' \
  | bash stow/claude/.claude/statusline.sh
```

Expected: Model + context segments only; no git segment

**Step 7: Commit**

```bash
git add stow/claude/.claude/statusline.sh
git commit -m "feat(statusline): add powerline segments with Catppuccin Mocha colors"
```

---

### Task 4: Wire into settings.json

**Files:**
- Modify: `~/.claude/settings.json`

**Step 1: Read current settings**

```bash
cat ~/.claude/settings.json
```

**Step 2: Add `statusLine` key**

Add to `~/.claude/settings.json` (merge with existing content, do not overwrite other keys):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

The final file should still contain the existing `enabledPlugins` key alongside the new `statusLine` key.

**Step 3: Verify JSON is valid**

```bash
jq . ~/.claude/settings.json
```

Expected: Pretty-printed JSON with no errors

**Step 4: Re-stow claude package to ensure symlink is in place**

```bash
stow -d stow -t "$HOME" claude
```

Expected: No conflicts; `~/.claude/statusline.sh` symlinked to the repo file

**Step 5: Verify symlink**

```bash
ls -la ~/.claude/statusline.sh
```

Expected: symlink pointing to `~/Workspace/mac-setup/stow/claude/.claude/statusline.sh`

**Step 6: Commit**

```bash
git add stow/claude/.claude/statusline.sh
git commit -m "feat(statusline): wire script into Claude Code settings"
```

---

### Task 5: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/mac-setup-log.md`

**Step 1: Add status line entry to README**

In the "What It Does" / dotfiles section, add a note that `stow/claude` includes a Catppuccin Mocha status line script for Claude Code.

**Step 2: Add entry to docs/mac-setup-log.md**

Add a section describing the status line: file location, what it shows, how colors are chosen, and the git caching approach.

**Step 3: Commit**

```bash
git add README.md docs/mac-setup-log.md
git commit -m "docs: document Claude Code Catppuccin Mocha status line"
```
