import { test } from "node:test"
import assert from "node:assert/strict"
import { render, State } from "./render.ts"

const baseState: State = {
  model: "Sonnet 4.6",
  thinking: null,
  branch: "main",
  dirty: false,
  activeTool: null,
  activeAgent: null,
  tokensIn: 2100,
  tokensOut: 800,
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

test("render includes token counts", () => {
  const result = render(baseState)
  assert.ok(result.includes("2.1k↓"))
  assert.ok(result.includes("800↑"))
})

test("render formats sub-1k tokens without suffix", () => {
  const result = render({ ...baseState, tokensIn: 500, tokensOut: 42 })
  assert.ok(result.includes("500↓"))
  assert.ok(result.includes("42↑"))
})
