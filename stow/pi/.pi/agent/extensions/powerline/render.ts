// Catppuccin Mocha truecolor ANSI
const C = {
  blue:     { bg: "\x1b[48;2;137;180;250m", fg: "\x1b[38;2;137;180;250m" },
  green:    { bg: "\x1b[48;2;166;227;161m", fg: "\x1b[38;2;166;227;161m" },
  yellow:   { bg: "\x1b[48;2;249;226;175m", fg: "\x1b[38;2;249;226;175m" },
  teal:     { bg: "\x1b[48;2;148;226;213m", fg: "\x1b[38;2;148;226;213m" },
  sky:      { bg: "\x1b[48;2;137;220;235m", fg: "\x1b[38;2;137;220;235m" },
  peach:    { bg: "\x1b[48;2;250;179;135m", fg: "\x1b[38;2;250;179;135m" },
  flamingo: { bg: "\x1b[48;2;242;205;205m", fg: "\x1b[38;2;242;205;205m" },
  mauve:    { bg: "\x1b[48;2;203;166;247m", fg: "\x1b[38;2;203;166;247m" },
  crust:    "\x1b[38;2;17;17;27m",
  reset:    "\x1b[0m",
  bold:     "\x1b[1m",
}

// Powerline Nerd Font glyphs
const CAP_L = "\uE0B6"  // left rounded cap
const SEP   = "\uE0B0"  // right arrow separator
const CAP_R = "\uE0B4"  // right rounded cap

export interface State {
  model: string
  thinking: string | null      // null = off/hidden (e.g. "medium", "high")
  branch: string | null
  staged: number
  modified: number
  activeTool: string | null    // null = segment hidden
  activeAgent: string | null   // null = segment hidden
  activeCommand: string | null // null = segment hidden (e.g. "/effort", "/chain")
  tokensIn: number
  tokensOut: number
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

function formatTokens(n: number): string {
  return n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`
}

function bar(pct: number): string {
  const filled = Math.floor(pct * 10 / 100)
  return "▓".repeat(filled) + "─".repeat(10 - filled)
}

export function render(state: State): string {
  let line = ""
  let lastFg = C.blue.fg

  // Left cap + Model
  line += `${C.reset}${C.blue.fg}${CAP_L}${C.blue.bg}${C.crust}${C.bold} π ${state.model} `

  // Git — conditional on branch being known
  if (state.branch !== null) {
    const dirty = state.staged > 0 || state.modified > 0
    const color = dirty ? C.yellow : C.green
    let text = `\uE0A0 ${state.branch}`
    if (state.staged   > 0) text += ` +${state.staged}`
    if (state.modified > 0) text += ` ~${state.modified}`
    const [s, fg] = seg(lastFg, color, text)
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

  // Thinking level — conditional, sky segment
  if (state.thinking !== null) {
    const [s, fg] = seg(lastFg, C.sky, state.thinking)
    line += s; lastFg = fg
  }

  // Active command — conditional, flamingo segment (e.g. "/effort", "/chain")
  if (state.activeCommand !== null) {
    const [s, fg] = seg(lastFg, C.flamingo, state.activeCommand)
    line += s; lastFg = fg
  }

  // Tokens + context bar + cost + duration
  const cost = `${formatTokens(state.tokensIn)}↓ ${formatTokens(state.tokensOut)}↑ ${bar(state.contextPct)} ${state.contextPct}% ${formatCost(state.cost)} ${formatDuration(state.durationMs)}`
  const [s, fg] = seg(lastFg, C.mauve, cost)
  line += s; lastFg = fg

  // Right cap
  line += `${C.reset}${lastFg}${CAP_R}${C.reset}`
  return line
}
