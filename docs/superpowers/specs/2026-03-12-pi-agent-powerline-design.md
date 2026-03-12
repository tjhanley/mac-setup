# Pi-Agent Powerline + Subagents — Design Spec

**Date:** 2026-03-12
**Status:** Approved

## Overview

Add a `stow/pi/` package to mac-setup providing two things for pi-coding-agent:

1. A Catppuccin Mocha powerline status bar (TypeScript extension) that leans into pi-agent's real-time lifecycle events — showing active tool and active subagent name as they happen.
2. Four declarative markdown subagents (`explore`, `planner`, `worker`, `reviewer`) that form a natural chain.

## Architecture

New stow package mirroring `~/.pi/agent/`:

```
stow/pi/
  .pi/
    agent/
      extensions/
        powerline/
          index.ts       — TypeScript extension, single file, no build step
          package.json   — marks as ES module, no external deps
      agents/
        explore.md
        planner.md
        worker.md
        reviewer.md
```

Pi-agent loads TypeScript extensions directly — no compile step required. The stow target is `$HOME`, so `stow/pi/.pi/agent/` symlinks to `~/.pi/agent/`.

## Powerline Extension

### Segments

| Segment | Color | Hook(s) | Content | Conditional |
|---|---|---|---|---|
| Model | blue | `session_start` | model display name | always |
| Git | green (clean) / yellow (dirty) | `session_start`, `turn_end` | `branch +N ~N` | hidden if not a git repo |
| Tool | teal | `tool_call` → `tool_result` | active tool name | hidden when idle |
| Subagent | peach | `before_agent_start` → `agent_end` | agent name | hidden when idle |
| Cost + context | mauve | `turn_end` | `$0.04 ▓▓▓── 42% 3m` | always |

Tool and subagent segments appear only while active — same conditional pill pattern as `stow/claude/.claude/statusline.sh`.

### State Model

```typescript
interface State {
  model: string
  branch: string | null
  dirty: boolean
  activeTool: string | null      // null = hidden
  activeAgent: string | null     // null = hidden
  cost: number
  contextPct: number
  durationMs: number
}
```

Single state object mutated by hooks. Every mutation calls `render(state)` → `ctx.ui.setStatus("powerline", ansiString)`.

### Rendering

`render()` iterates segments, tracks previous segment color for powerline arrow transitions, and skips null/conditional segments — identical logic to `statusline.sh` but in TypeScript. Catppuccin Mocha hex values are top-level constants.

Uses `setStatus` (footer), not `setWidget` — keeps UI lightweight.

### Git Updates

Read on `session_start` via shell (`git branch --show-current`, `git status --porcelain`). Refreshed on `turn_end`. No polling. Fails silently if not a git repo (git segment hidden).

### Error Handling

All hooks wrapped in try/catch. Extension errors are logged silently and never propagate — a crashed extension must not break the agent session.

## Subagents

Four declarative markdown agents. YAML frontmatter specifies name, model, and tools. System prompt is the markdown body.

### `explore.md`
- **Tools:** `read`, `glob`, `grep` (no write, no bash)
- **Model:** haiku (speed over depth)
- **Purpose:** rapid read-only codebase reconnaissance; feeds context to planner

### `planner.md`
- **Tools:** `read`, `glob`, `grep`, web search
- **Model:** default with thinking enabled
- **Purpose:** produces a structured implementation plan; writes no code

### `worker.md`
- **Tools:** full set
- **Model:** default
- **Purpose:** implements a plan produced by planner

### `reviewer.md`
- **Tools:** `read`, `glob`, `grep` (no write)
- **Model:** default
- **Purpose:** critical review of a diff or file set; returns structured feedback

### Natural Chain

```
explore → planner → worker → reviewer
```

Each agent's output feeds the next. The powerline subagent segment shows which is active at any moment.

## What This Is Not

- No `setWidget` multi-line dashboard (approach C, rejected — too noisy)
- No TypeScript orchestration runtime (declarative markdown chosen over programmatic)
- No external npm dependencies in the extension
- No polling for git state
