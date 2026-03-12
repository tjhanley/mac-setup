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

**Implementation note:** Exact `package.json` fields, module format, and hook registration API must be confirmed against pi-agent source/docs during implementation. ANSI support in `setStatus` footer must be verified. Git subprocess method (Node `child_process` vs pi-agent shell utility) must be confirmed in extension context.

**Stow collisions:** If `~/.pi/agent/extensions/powerline/` or `~/.pi/agent/agents/` already exist as non-symlinks, stow will skip them (default no-adopt behavior). The bootstrap stow call uses standard conflict detection — pre-existing files must be manually removed or stow run with `--adopt`.

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

`durationMs` is computed by recording a `turnStartedAt` timestamp on `turn_start` and diffing against `Date.now()` on `turn_end`. Accumulated across all turns in the session.

`activeTool` is set to the tool name on `tool_call` and explicitly reset to `null` on `tool_result`.
`activeAgent` is set to the agent name on `before_agent_start` and explicitly reset to `null` on `agent_end`.

### Rendering

`render()` iterates segments, tracks previous segment color for powerline arrow transitions, and skips null/conditional segments — identical logic to `statusline.sh` but in TypeScript. Catppuccin Mocha hex values are top-level constants.

Uses `setStatus` (footer), not `setWidget` — keeps UI lightweight.

### Git Updates

Read on `session_start` via shell (`git branch --show-current`, `git status --porcelain`). Refreshed on `turn_end`. No polling. Fails silently if not a git repo (git segment hidden).

### Error Handling

All hooks wrapped in try/catch. Extension errors are logged silently and never propagate — a crashed extension must not break the agent session.

## Subagents

Four declarative markdown agents. YAML frontmatter specifies name, model, and tools. System prompt is the markdown body. Exact frontmatter field names and valid values must be confirmed against pi-agent's agent schema during implementation.

Example structure (field names to be verified):
```yaml
---
name: explore
description: Read-only codebase navigator
model: claude-haiku-4-5
tools: [read, glob, grep]
---
System prompt body here...
```

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

The chain is **manually orchestrated by the user** — invoke each agent in sequence, passing the previous agent's output as context for the next. There is no automatic pipeline. The powerline subagent segment shows which is active at any moment.

## What This Is Not

- No `setWidget` multi-line dashboard (approach C, rejected — too noisy)
- No TypeScript orchestration runtime (declarative markdown chosen over programmatic)
- No external npm dependencies in the extension
- No polling for git state
