# Pi-Agent Powerline + Subagents Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `stow/pi/` package with a Catppuccin Mocha powerline status bar extension and four declarative subagents for pi-coding-agent.

**Architecture:** Single TypeScript extension split across `render.ts` (pure state→ANSI function, unit testable) and `index.ts` (hooks + state management). Four markdown agent files with YAML frontmatter. All live in `stow/pi/.pi/agent/` mirroring `~/.pi/agent/`.

**Tech Stack:** TypeScript (loaded directly by pi-agent, no build step), Node.js built-in test runner via `tsx --test`, Catppuccin Mocha palette hardcoded as constants.

**Spec:** `docs/superpowers/specs/2026-03-12-pi-agent-powerline-design.md`

---

## Chunk 1: Scaffold + Subagents

### Task 1: Create stow/pi scaffold

**Files:**
- Create: `stow/pi/.pi/agent/extensions/powerline/package.json`
- Create: `stow/pi/.pi/agent/extensions/powerline/index.ts` (empty stub)
- Create: `stow/pi/.pi/agent/extensions/powerline/render.ts` (empty stub)
- Create: `stow/pi/.pi/agent/extensions/powerline/render.test.ts` (empty stub)
- Create: `stow/pi/.pi/agent/agents/` (directory only)

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p stow/pi/.pi/agent/extensions/powerline
mkdir -p stow/pi/.pi/agent/agents
```

- [ ] **Step 2: Create package.json**

```json
{
  "name": "powerline",
  "type": "module"
}
```

Save to `stow/pi/.pi/agent/extensions/powerline/package.json`.

- [ ] **Step 3: Create empty stubs**

`stow/pi/.pi/agent/extensions/powerline/render.ts`:
```typescript
// Powerline render — pure function, state → ANSI string
// Tested independently; no pi-agent runtime dependency
export {}
```

`stow/pi/.pi/agent/extensions/powerline/index.ts`:
```typescript
// Pi-agent powerline extension entry point
export {}
```

`stow/pi/.pi/agent/extensions/powerline/render.test.ts`:
```typescript
// Tests for render() — filled in Task 3
```

- [ ] **Step 4: Pre-check for stow collisions**

```bash
stow --simulate --dir=stow --target="$HOME" pi 2>&1
```

If any "existing target" warnings appear for `~/.pi/agent/extensions/powerline/` or `~/.pi/agent/agents/`, remove those paths manually before proceeding.

- [ ] **Step 5: Commit scaffold**

```bash
git add stow/pi/
git commit -m "feat(pi): scaffold stow/pi package with powerline extension dirs"
```

---

### Task 2: Verify pi is auto-stowed

`stow_dotfiles()` in `bootstrap/bootstrap-mac.zsh` uses `for pkg in */` — it globs all directories in `stow/` automatically, skipping only `nvim/`. Creating `stow/pi/` in Task 1 is sufficient; no code change is needed.

- [ ] **Step 1: Confirm no manual exclusion of `pi` is needed**

```bash
grep -n 'nvim\|continue' bootstrap/bootstrap-mac.zsh | head -10
```

Expected: only `nvim/` is excluded. `pi` will be stowed automatically.

- [ ] **Step 2: Dry-run stow to confirm no conflicts**

```bash
stow --simulate --dir=stow --target="$HOME" pi 2>&1
```

Expected: no output (or "BUG" messages only — those are harmless). If conflicts appear, resolve them before proceeding.

---

### Task 3: Write subagent markdown files

**Files:**
- Create: `stow/pi/.pi/agent/agents/explore.md`
- Create: `stow/pi/.pi/agent/agents/planner.md`
- Create: `stow/pi/.pi/agent/agents/worker.md`
- Create: `stow/pi/.pi/agent/agents/reviewer.md`

> **Verify frontmatter schema first:** Check `~/.pi/agent/agents/` for any examples shipped with pi-agent, or read the pi-agent agents docs. Exact field names and valid values for `model` and `tools` may differ from what's shown here. The model IDs below use short-form (`claude-haiku-4-5`) — if pi-agent requires the full versioned ID (`claude-haiku-4-5-20251001`) adjust accordingly.

- [ ] **Step 1: Write explore.md**

```markdown
---
name: explore
description: Read-only codebase navigator. Fast reconnaissance before planning or coding.
model: claude-haiku-4-5
tools:
  - read
  - glob
  - grep
---

You are a read-only codebase navigator. Your job is to rapidly understand the structure, patterns, and relevant code in a repository.

- Read files, search for patterns, map dependencies
- Never write, edit, or execute code
- Return a concise structured summary: relevant files, key patterns, potential gotchas
- Be fast — prefer breadth over depth unless asked to go deep on a specific area
```

- [ ] **Step 2: Write planner.md**

```markdown
---
name: planner
description: Architecture and implementation planner. Produces structured plans, writes no code.
model: claude-sonnet-4-6
tools:
  - read
  - glob
  - grep
  - web_search  # verify exact tool name against pi-agent schema
---

You are an implementation planner. Given a task and codebase context, produce a clear, step-by-step implementation plan.

- Read and search the codebase to understand existing patterns
- Produce a numbered plan with exact file paths and what to change in each
- Note risks, edge cases, and dependencies between steps
- Write no implementation code — plans only
- Your output will be handed to a worker agent for implementation
```

> **Note on thinking:** If pi-agent's agent frontmatter supports a `thinking: true` flag (or similar), add it to planner's frontmatter. Check existing pi-agent docs or `~/.pi/agent/agents/` examples for the correct key name.

- [ ] **Step 3: Write worker.md**

```markdown
---
name: worker
description: Full-access implementation agent. Executes plans produced by the planner.
model: claude-sonnet-4-6
---

You are an implementation agent. You receive a plan and execute it precisely.

- Follow the plan step by step
- Write clean, idiomatic code that matches existing patterns in the codebase
- Run tests after each significant change
- Commit completed work with clear commit messages
- Flag blockers immediately rather than working around them silently
```

- [ ] **Step 4: Write reviewer.md**

```markdown
---
name: reviewer
description: Read-only code reviewer. Returns structured feedback on diffs or file sets.
model: claude-sonnet-4-6
tools:
  - read
  - glob
  - grep
---

You are a code reviewer. Review the provided diff, file, or set of files critically.

Structure your output as:
1. **Summary** — what changed and why (1-2 sentences)
2. **Issues** — bugs, security problems, or correctness failures (numbered, must-fix)
3. **Suggestions** — style, clarity, performance improvements (optional)
4. **Verdict** — APPROVED / NEEDS CHANGES / BLOCKED

Be direct. Don't soften criticism. Don't praise for its own sake.
```

- [ ] **Step 5: Commit**

```bash
git add stow/pi/.pi/agent/agents/
git commit -m "feat(pi): add explore/planner/worker/reviewer subagents"
```

---

## Chunk 2: Powerline Render Function (TDD)

### Task 4: Write failing render tests

**Files:**
- Modify: `stow/pi/.pi/agent/extensions/powerline/render.test.ts`

- [ ] **Step 1: Write test file**

`stow/pi/.pi/agent/extensions/powerline/render.test.ts`:
```typescript
import { test } from "node:test"
import assert from "node:assert/strict"
import { render, State } from "./render.ts"

const baseState: State = {
  model: "Sonnet 4.6",
  branch: "main",
  dirty: false,
  activeTool: null,
  activeAgent: null,
  cost: 0.04,
  contextPct: 42,
  durationMs: 183000,  // 3m 3s → formats as "3m"
}

test("render returns a non-empty string", () => {
  const result = render(baseState)
  assert.ok(result.length > 0)
})

test("render includes model name", () => {
  const result = render(baseState)
  assert.ok(result.includes("Sonnet 4.6"))
})

test("render includes branch name", () => {
  const result = render(baseState)
  assert.ok(result.includes("main"))
})

test("render includes formatted cost", () => {
  const result = render(baseState)
  assert.ok(result.includes("$0.04"))
})

test("render includes formatted duration", () => {
  const result = render(baseState)
  // Match " 3m" with leading space to avoid false matches on model names etc.
  assert.match(result, / 3m/)
})

test("render hides tool segment when activeTool is null", () => {
  const withTool    = render({ ...baseState, activeTool: "read" })
  const withoutTool = render({ ...baseState, activeTool: null })
  assert.ok(withTool.includes("read"))
  assert.ok(!withoutTool.includes(" read "))
})

test("render shows tool segment when activeTool is set", () => {
  const result = render({ ...baseState, activeTool: "bash" })
  assert.ok(result.includes("bash"))
})

test("render hides agent segment when activeAgent is null", () => {
  const result = render({ ...baseState, activeAgent: null })
  assert.ok(!result.includes("reviewer"))
})

test("render shows agent segment when activeAgent is set", () => {
  const result = render({ ...baseState, activeAgent: "reviewer" })
  assert.ok(result.includes("reviewer"))
})

test("render hides git segment when branch is null", () => {
  const withBranch    = render(baseState)
  const withoutBranch = render({ ...baseState, branch: null })
  assert.ok(withBranch.includes("main"))
  assert.ok(!withoutBranch.includes("main"))
})

test("render produces different output when dirty", () => {
  const clean = render(baseState)
  const dirty = render({ ...baseState, dirty: true })
  assert.notEqual(clean, dirty)
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
REPO_ROOT=$(git -C . rev-parse --show-toplevel)
cd "$REPO_ROOT/stow/pi/.pi/agent/extensions/powerline"
npx tsx --test render.test.ts 2>&1 | head -20
```

Expected: import errors — `render` not exported yet.

- [ ] **Step 3: Commit failing tests**

```bash
git add stow/pi/.pi/agent/extensions/powerline/render.test.ts
git commit -m "test(pi): add failing render() tests"
```

---

### Task 5: Implement render()

**Files:**
- Modify: `stow/pi/.pi/agent/extensions/powerline/render.ts`

> **Verify ANSI support before writing:** Check if any existing extension in `~/.pi/agent/extensions/` uses `ctx.ui.setStatus()` with ANSI escape codes. If none exist, start pi-agent and call `ctx.ui.setStatus("test", "\x1b[31mred\x1b[0m")` from a temporary extension. If colors render, proceed. If raw escape codes appear as text, the pi-agent TUI strips ANSI — in that case use plain text only and remove all `\x1b[...]` sequences from render.ts.

- [ ] **Step 1: Implement render.ts**

Note: `turnStartedAt` is internal to the hook layer (`index.ts`), not part of the `State` passed to `render()`.

```typescript
// Catppuccin Mocha truecolor ANSI
const C = {
  blue:    { bg: "\x1b[48;2;137;180;250m", fg: "\x1b[38;2;137;180;250m" },
  green:   { bg: "\x1b[48;2;166;227;161m", fg: "\x1b[38;2;166;227;161m" },
  yellow:  { bg: "\x1b[48;2;249;226;175m", fg: "\x1b[38;2;249;226;175m" },
  teal:    { bg: "\x1b[48;2;148;226;213m", fg: "\x1b[38;2;148;226;213m" },
  peach:   { bg: "\x1b[48;2;250;179;135m", fg: "\x1b[38;2;250;179;135m" },
  mauve:   { bg: "\x1b[48;2;203;166;247m", fg: "\x1b[38;2;203;166;247m" },
  crust:   "\x1b[38;2;17;17;27m",
  reset:   "\x1b[0m",
  bold:    "\x1b[1m",
}

// Powerline Nerd Font glyphs
const CAP_L = "\uE0B6"  // left rounded cap
const SEP   = "\uE0B0"  // right arrow separator
const CAP_R = "\uE0B4"  // right rounded cap

export interface State {
  model: string
  branch: string | null
  dirty: boolean
  activeTool: string | null   // null = segment hidden
  activeAgent: string | null  // null = segment hidden
  cost: number
  contextPct: number
  durationMs: number
}

type Color = { bg: string; fg: string }

function seg(lastFg: string, color: Color, text: string): [string, string] {
  return [`${lastFg}${color.bg}${SEP}${C.crust}${C.bold} ${text} `, color.fg]
}

function formatCost(usd: number): string {
  return `$${usd.toFixed(2)}`
}

function formatDuration(ms: number): string {
  const s = Math.floor(ms / 1000)
  const m = Math.floor(s / 60)
  const h = Math.floor(m / 60)
  if (h > 0) return `${h}h${m % 60}m`
  return `${m}m`
}

function bar(pct: number): string {
  const filled = Math.floor(pct * 10 / 100)
  return "▓".repeat(filled) + "─".repeat(10 - filled)
}

export function render(state: State): string {
  let line = ""
  let lastFg = C.blue.fg

  // Left cap + Model
  line += `${C.reset}${C.blue.fg}${CAP_L}${C.blue.bg}${C.crust}${C.bold} ${state.model} `

  // Git — conditional on branch being known
  if (state.branch !== null) {
    const color   = state.dirty ? C.yellow : C.green
    const text    = state.dirty ? `${state.branch} ~` : state.branch
    const [s, fg] = seg(C.blue.fg, color, text)
    line += s; lastFg = fg
  }

  // Active tool — conditional
  if (state.activeTool !== null) {
    const [s, fg] = seg(lastFg, C.teal, state.activeTool)
    line += s; lastFg = fg
  }

  // Active subagent — conditional
  if (state.activeAgent !== null) {
    const [s, fg] = seg(lastFg, C.peach, state.activeAgent)
    line += s; lastFg = fg
  }

  // Cost + context bar + duration
  const cost = `${bar(state.contextPct)} ${state.contextPct}% ${formatCost(state.cost)} ${formatDuration(state.durationMs)}`
  const [s, fg] = seg(lastFg, C.mauve, cost)
  line += s; lastFg = fg

  // Right cap
  line += `${C.reset}${lastFg}${CAP_R}${C.reset}`
  return line
}
```

- [ ] **Step 2: Run tests — all must pass**

```bash
REPO_ROOT=$(git -C . rev-parse --show-toplevel)
cd "$REPO_ROOT/stow/pi/.pi/agent/extensions/powerline"
npx tsx --test render.test.ts 2>&1
```

Expected: all tests pass. Fix any failures before continuing.

- [ ] **Step 3: Commit**

```bash
git add stow/pi/.pi/agent/extensions/powerline/render.ts
git commit -m "feat(pi): implement powerline render() with Catppuccin Mocha theme"
```

---

## Chunk 3: Extension Hooks

### Task 6: Implement index.ts (hooks + state)

**Files:**
- Modify: `stow/pi/.pi/agent/extensions/powerline/index.ts`

> **Before writing — verify two things:**
>
> 1. **ANSI in footer:** confirmed in Task 5 Step 1 above.
>
> 2. **Cost + context fields on TurnEndEvent:** Check if `event.message.usage` exists and has `contextWindowUsedPercentage` and `totalCostUsd` (or similar). Add a temporary debug line in `turn_end`: `ctx.ui.notify(JSON.stringify(Object.keys(event.message ?? {})), "info")` to inspect. Adjust field paths below to match. If no cost/context data is available, set `state.cost` and `state.contextPct` to 0 and omit until the API exposes them.
>
> 3. **`before_agent_start` event shape:** Inspect `event` in `before_agent_start` the same way to find the agent name field. Adjust `state.activeAgent` assignment accordingly.

- [ ] **Step 1: Implement index.ts**

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { render, State } from "./render.ts"
import { execSync } from "node:child_process"

function gitInfo(dir: string): { branch: string | null; dirty: boolean } {
  try {
    const branch = execSync("git branch --show-current", { cwd: dir, encoding: "utf8" }).trim()
    const status = execSync("git status --porcelain",    { cwd: dir, encoding: "utf8" }).trim()
    return { branch: branch || null, dirty: status.length > 0 }
  } catch {
    return { branch: null, dirty: false }
  }
}

export default function (pi: ExtensionAPI) {
  const state: State = {
    model: "",
    branch: null,
    dirty: false,
    activeTool: null,
    activeAgent: null,
    cost: 0,
    contextPct: 0,
    durationMs: 0,
  }

  // Not part of render State — used only for duration accumulation
  let turnStartedAt: number | null = null

  function update(ctx: any) {
    ctx.ui.setStatus("powerline", render(state))
  }

  pi.on("session_start", async (_event, ctx) => {
    try {
      state.model = (ctx as any).session?.model?.displayName ?? "pi"
      const dir   = (ctx as any).session?.directory ?? process.cwd()
      const git   = gitInfo(dir)
      state.branch = git.branch
      state.dirty  = git.dirty
      update(ctx)
    } catch { /* never crash the session */ }
  })

  pi.on("turn_start", async (event, ctx) => {
    try {
      // TurnStartEvent.timestamp is a Unix ms timestamp
      turnStartedAt = (event as any).timestamp ?? Date.now()
      update(ctx)
    } catch { /* silent */ }
  })

  pi.on("turn_end", async (event, ctx) => {
    try {
      if (turnStartedAt !== null) {
        state.durationMs += Date.now() - turnStartedAt
        turnStartedAt = null
      }
      // Adjust these field paths after inspecting the event shape (see task note above)
      const usage = (event as any).message?.usage
      if (usage) {
        state.contextPct = usage.contextWindowUsedPercentage ?? state.contextPct
        state.cost       = usage.totalCostUsd               ?? state.cost
      }
      const dir  = (ctx as any).session?.directory ?? process.cwd()
      const git  = gitInfo(dir)
      state.branch = git.branch
      state.dirty  = git.dirty
      update(ctx)
    } catch { /* silent */ }
  })

  pi.on("tool_execution_start", async (event, ctx) => {
    try {
      state.activeTool = (event as any).toolName ?? null
      update(ctx)
    } catch { /* silent */ }
  })

  pi.on("tool_execution_end", async (_event, ctx) => {
    try {
      state.activeTool = null
      update(ctx)
    } catch { /* silent */ }
  })

  pi.on("before_agent_start", async (event, ctx) => {
    try {
      // Inspect event shape first (see task note above) — adjust field path as needed
      // Fall back to null (hide segment) rather than a generic placeholder
      state.activeAgent = (event as any).agentName ?? null
      update(ctx)
    } catch { /* silent */ }
  })

  pi.on("agent_end", async (_event, ctx) => {
    try {
      state.activeAgent = null
      update(ctx)
    } catch { /* silent */ }
  })
}
```

- [ ] **Step 2: Smoke test — load extension in pi-agent**

Start a pi-agent session. Verify:
- Footer shows model name
- Git segment shows current branch
- Tool segment lights up during a file read, clears after

If anything looks wrong:
- Raw ANSI visible → remove ANSI codes from render.ts constants (replace with empty strings), re-run render tests
- Model shows "pi" (fallback) → inspect `ctx` keys and adjust `session_start` handler field path
- Commit the working version before moving to cost/context verification

- [ ] **Step 3: Verify cost and context**

Run a medium-length session with several turns. Check whether `$X.XX` and context % update. If they stay at `$0.00 0%`:
- Temporarily add `ctx.ui.notify(JSON.stringify(Object.keys((event as any).message ?? {})), "info")` to `turn_end` handler
- Identify the correct field names from the notification
- Update the `usage` field path in `turn_end` handler
- Remove the debug notify line

- [ ] **Step 4: Commit**

```bash
git add stow/pi/.pi/agent/extensions/powerline/index.ts
git commit -m "feat(pi): add powerline extension hooks and state management"
```

---

## Chunk 4: Docs

### Task 7: Update docs

**Files:**
- Modify: `README.md`
- Modify: `docs/mac-setup-log.md`
- Modify: `man/man7/mac-setup.7` (generated via `/update-man` skill)

- [ ] **Step 1: Update README.md**

In the dotfiles structure tree, add `pi` alongside the other stow packages.

In the "CLI Tools" or "npm global tools" section add:
```
pi-agent stow package (stow/pi/):
  - powerline extension: Catppuccin Mocha status bar with real-time tool and subagent segments
  - subagents: explore (haiku, read-only), planner (sonnet), worker (sonnet, full tools), reviewer (sonnet, read-only)
```

- [ ] **Step 2: Update docs/mac-setup-log.md**

In the "Installed/managed tools" section add a pi-agent subsection:
```markdown
### Pi-agent (`stow/pi/`)
- Powerline extension: `~/.pi/agent/extensions/powerline/` — Catppuccin Mocha footer showing model, git branch, active tool, active subagent, cost/context
- Subagents: explore (haiku, read-only), planner (sonnet), worker (sonnet, full tools), reviewer (sonnet, read-only)
- Stowed via `stow/pi/` → `~/.pi/agent/`
```

- [ ] **Step 3: Update man page via /update-man**

Run the `/update-man` skill — it reads README.md and mac-setup-log.md as source of truth and regenerates the man page. Verify the `pi` entry appears in the STOW PACKAGES table in the generated output. Do not manually edit `man/man7/mac-setup.7`.

- [ ] **Step 4: Commit**

```bash
git add README.md docs/mac-setup-log.md man/man7/mac-setup.7
git commit -m "docs: add pi-agent powerline and subagents to README, log, and man page"
```
