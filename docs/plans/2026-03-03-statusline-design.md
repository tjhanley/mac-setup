# Claude Code Status Line Design

## Overview

A Catppuccin Mocha-themed powerline-style status line for Claude Code, managed via the `stow/claude` stow package.

## Layout

Single line, powerline segments separated by `▌`:

```
▌ claude-sonnet-4-6 ▌  main +2 ~1 ▌ ▓▓▓░░░░░░░ 14% $0.04 ▌ INSERT ▌
```

## Segments

| Segment | Color | Content | Visibility |
|---------|-------|---------|------------|
| Model | Blue bg + dark fg | `claude-sonnet-4-6` | Always |
| Git | Green bg (clean) / Yellow bg (dirty) + dark fg | ` main +2 ~1` | Git repos only |
| Context | Mauve bg + dark fg | `▓▓▓░░░░░░░ 14% $0.04` | Always |
| Vim mode | Green bg (INSERT) / Yellow bg (NORMAL) + dark fg | `INSERT` or `NORMAL` | Vim mode only |

## Colors (Catppuccin Mocha)

| Name | Hex | Usage |
|------|-----|-------|
| Blue | `#89b4fa` | Model segment bg |
| Green | `#a6e3a1` | Git clean segment bg, INSERT vim pill bg |
| Yellow | `#f9e2af` | Git dirty segment bg, NORMAL vim pill bg |
| Mauve | `#cba6f7` | Context segment bg |
| Base | `#1e1e2e` | All segment foreground text |

ANSI truecolor escape sequences (`\033[38;2;R;G;Bm` fg, `\033[48;2;R;G;Bm` bg).

## Implementation

**File**: `stow/claude/.claude/statusline.sh` (stows to `~/.claude/statusline.sh`)

**Language**: bash with `jq` (already in Brewfile)

**Settings**: `~/.claude/settings.json` — add `statusLine` key pointing to the script

**Git caching**: cache git branch/staged/modified counts to `/tmp/statusline-git-cache`, refresh every 5 seconds to avoid lag on large repos

**JSON fields used**:
- `model.display_name`
- `workspace.current_dir`
- `context_window.used_percentage`
- `cost.total_cost_usd`
- `vim.mode` (absent when vim mode disabled)

## Files Changed

- `stow/claude/.claude/statusline.sh` — new script
- `~/.claude/settings.json` — add `statusLine` config (not stowed, edited directly)
