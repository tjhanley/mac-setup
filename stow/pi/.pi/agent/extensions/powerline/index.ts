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

export default function powerlineExtension(pi: ExtensionAPI) {
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

  function update(ctx: { ui: { setStatus: (key: string, value: string) => void } }) {
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

  pi.on("turn_start", async (event, _ctx) => {
    try {
      // TurnStartEvent.timestamp is a Unix ms timestamp
      // No visible state changes here — turnStartedAt is not rendered
      turnStartedAt = (event as any).timestamp ?? Date.now()
    } catch { /* never crash the session */ }
  })

  pi.on("turn_end", async (event, ctx) => {
    try {
      if (turnStartedAt !== null) {
        state.durationMs += Date.now() - turnStartedAt
        turnStartedAt = null
      }
      // Adjust these field paths if cost/context don't update in practice
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
    } catch { /* never crash the session */ }
  })

  pi.on("tool_execution_start", async (event, ctx) => {
    try {
      state.activeTool = (event as any).toolName ?? null
      update(ctx)
    } catch { /* never crash the session */ }
  })

  pi.on("tool_execution_end", async (_event, ctx) => {
    try {
      state.activeTool = null
      update(ctx)
    } catch { /* never crash the session */ }
  })

  pi.on("before_agent_start", async (event, ctx) => {
    try {
      // Fall back to null (hides segment) rather than a generic placeholder
      state.activeAgent = (event as any).agentName ?? null
      update(ctx)
    } catch { /* never crash the session */ }
  })

  pi.on("agent_end", async (_event, ctx) => {
    try {
      state.activeAgent = null
      update(ctx)
    } catch { /* never crash the session */ }
  })
}
