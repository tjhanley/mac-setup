import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { render as powerline, State } from "./render.ts"
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
    thinking: null,
    branch: null,
    dirty: false,
    activeTool: null,
    activeAgent: null,
    tokensIn: 0,
    tokensOut: 0,
    cost: 0,
    contextPct: 0,
    durationMs: 0,
  }

  // Captured from setFooter factory — used to trigger re-renders from event handlers
  let tui: { requestRender: () => void } | null = null
  // Not part of render State — used only for duration accumulation
  let turnStartedAt: number | null = null

  function requestRender() {
    tui?.requestRender()
  }

  pi.on("session_start", async (_event, ctx) => {
    try {
      state.model    = ctx.model?.id ?? "pi"
      const level    = (ctx as any).session?.state?.thinkingLevel
      state.thinking = (level && level !== "off") ? String(level) : null
      const dir      = (ctx as any).session?.directory ?? process.cwd()
      const git      = gitInfo(dir)
      state.branch   = git.branch
      state.dirty    = git.dirty

      // Replace the native footer entirely
      ctx.ui.setFooter((tuiArg, _theme, _footerData) => {
        tui = tuiArg
        return {
          dispose: () => { tui = null },
          invalidate() {},
          render(_width: number): string[] {
            // Context usage — always fresh from TUI render cycle
            const usage = ctx.getContextUsage()
            if (usage?.percent != null) state.contextPct = Math.round(usage.percent)
            // Cost — accumulate from session branch messages
            try {
              let cost = 0, tokensIn = 0, tokensOut = 0
              for (const entry of (ctx as any).sessionManager.getBranch()) {
                if (entry.type === "message" && entry.message?.role === "assistant") {
                  cost      += entry.message.usage?.cost?.total ?? 0
                  tokensIn  += entry.message.usage?.input       ?? 0
                  tokensOut += entry.message.usage?.output      ?? 0
                }
              }
              state.cost      = cost
              state.tokensIn  = tokensIn
              state.tokensOut = tokensOut
            } catch { /* ignore if branch not available */ }
            return [powerline(state)]
          },
        }
      })
    } catch { /* never crash the session */ }
  })

  pi.on("turn_start", async (event, ctx) => {
    try {
      turnStartedAt  = (event as any).timestamp ?? Date.now()
      // Refresh thinking — user may have toggled it with Ctrl+T
      const level    = (ctx as any).session?.state?.thinkingLevel
      state.thinking = (level && level !== "off") ? String(level) : null
      requestRender()
    } catch { /* never crash the session */ }
  })

  pi.on("turn_end", async (_event, ctx) => {
    try {
      if (turnStartedAt !== null) {
        state.durationMs += Date.now() - turnStartedAt
        turnStartedAt = null
      }
      const dir  = (ctx as any).session?.directory ?? process.cwd()
      const git  = gitInfo(dir)
      state.branch = git.branch
      state.dirty  = git.dirty
      requestRender()
    } catch { /* never crash the session */ }
  })

  pi.on("tool_execution_start", async (event, _ctx) => {
    try {
      state.activeTool = (event as any).toolName ?? null
      requestRender()
    } catch { /* never crash the session */ }
  })

  pi.on("tool_execution_end", async (_event, _ctx) => {
    try {
      state.activeTool = null
      requestRender()
    } catch { /* never crash the session */ }
  })

  pi.on("before_agent_start", async (event, _ctx) => {
    try {
      state.activeAgent = (event as any).agentName ?? null
      requestRender()
    } catch { /* never crash the session */ }
  })

  pi.on("agent_end", async (_event, _ctx) => {
    try {
      state.activeAgent = null
      requestRender()
    } catch { /* never crash the session */ }
  })
}
