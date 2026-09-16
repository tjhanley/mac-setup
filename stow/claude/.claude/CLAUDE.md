- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
- Never add "🤖 Generated with Claude Code" or any similar footer to PR descriptions or commit messages.
- When generating documentation in Confluence or Jira, focus on the details in a concise manner to not overwhelm the reader.

## Reasoning & Planning

Before taking any action (tool calls or responses), proactively plan and reason about:

1. **Logical dependencies** — Resolve conflicts in order: policy rules > order of operations > prerequisites > user preferences.
2. **Risk assessment** — What are the consequences? For exploratory tasks, prefer acting with available info over asking.
3. **Abductive reasoning** — Identify the most likely root cause. Look beyond obvious causes. Hypotheses may take multiple steps to test.
4. **Adaptability** — If initial hypotheses are disproven, generate new ones from gathered information.
5. **Information sources** — Use tools, policies, conversation history, and ask the user only when necessary.
6. **Precision** — Be exact and grounded. Quote applicable policies/constraints when referring to them.
7. **Completeness** — Exhaust all requirements and options. Don't make premature conclusions.
8. **Persistence** — Don't give up. Retry transient errors. On other errors, change strategy — don't repeat the same failed call.
9. **Inhibit** — Only act after reasoning is complete.

## Workflow Execution

When executing multi-step skills or commands, always complete the full workflow before stopping. If a step fails, attempt recovery before reporting. Never spend excessive time reading/exploring without producing output. A partial result is always better than no result.

## Code Quality (Universal)

These principles apply to ALL codebases, not just Go:

- **Test coverage must not regress.** Every new feature ships with tests in the same commit. Code and tests are never committed separately.
- **Never skip pre-commit hooks** (`--no-verify`). Fix the issue instead.
- **Test-Driven Development:** Write failing test → implement → verify → lint → commit.
- **Test against real data, not just curated fixtures.** Add smoke tests that validate against actual production-like data.
- **Run the quality gate before committing.** If the project has `make check`, use it.

## Pull Requests

All PRs across Sonatus repos require a Jira ticket. When creating a PR:

1. Create (or identify) the relevant ENGOPS Jira ticket first
2. Include the ticket key (e.g. `ENGOPS-1234`) in the PR title: `ENGOPS-1234: <description>`
3. Link the PR URL in the Jira ticket description

## Git Operations

- Always check for `index.lock` files before committing — if found, `rm -f .git/index.lock` and retry
- Handle large untracked directories gracefully (never use `git add -A` blindly)
- Verify git remote auth before pushing. If a push fails, diagnose root cause (missing scope, wrong remote) — don't just retry
- If a git operation fails, diagnose the root cause. Don't retry the identical command.

## Platform Notes

On macOS: use Python or `/bin/zsh` for scripting when advanced features are needed. macOS ships bash 3 which lacks associative arrays, `${var,,}` lowercase syntax, `mapfile`, and other bash 4+ features. Do not write bash scripts that depend on these.

## MCP & Integrations

When MCP tools return empty or limited results (Slack message bodies hidden, Jira API limitations, Calendar auth expired), report the limitation clearly and continue with other data sources. Never silently retry the same failing query. Never abort a multi-step workflow because one integration failed — skip it, note what was skipped, and deliver what you can.

## MCP Server Health Checks

- Before running any command that depends on an MCP server (Granola, Atlassian, Slack), verify the server is connected first; if it fails, report the diagnosis and remediation steps immediately rather than retrying repeatedly.

## Factual claims

Every factual claim must be traceable to something a reader can open and check.

- Cite inline: `claim [^src]`, where the source is a URL, a `path/to/file.py:42`
  reference, a command and its output, or a named query.
- No source available? Write `[UNVERIFIED]` on that sentence. Do not drop the
  claim silently and do not assert it as if sourced.
- These are not sources: "I recall", "typically", "it is well known",
  "generally", "as of my training data", a plausible-looking URL you did not
  open.
- Numbers, dates, versions, prices, names, and quotes require a source every
  time, with no exceptions for how obvious they seem.
- If a source is behind a paywall or otherwise unreadable, say so. An
  uncheckable citation is `[UNVERIFIED]`, not support.
- Distinguish what the source _says_ from what you _infer_ from it. Inference
  is fine; labelling inference as citation is not.

## Adversarial review gate

Before presenting any research output, comparison, recommendation, migration
plan, root-cause analysis, or number-bearing summary:

1. **Extract.** Build a claims table from the draft:
   `claim | source | load-bearing? | confidence`.
   Load-bearing means the conclusion changes if the claim is false.
2. **Attack.** Launch the `red-team` agent with the draft and the table.
   Give it the draft as-is; do not pre-defend it or tell it which claims you
   are confident about.
3. **Resolve.** Address every CONTRADICTED and UNSUPPORTED verdict before you
   respond. Fixing means finding a real source, weakening the claim to what
   the evidence supports, or cutting it. It does not mean re-asserting it.
4. **Disclose.** Report the surviving unresolved items to the user in the
   response body — not in a footnote, not omitted. If a load-bearing claim
   survives as UNSUPPORTED, say plainly that the conclusion is unsafe.

Rules for the gate itself:

- Do not skip it because the answer seems obvious. Obvious is where errors hide.
- Do not skip it because you are short on context or time. Say you are skipping
  it and why, so the user can decide.
- Do not act as your own adversary in the main thread. The point of a separate
  agent is that it has not spent the last hour becoming attached to this draft.
- One re-review after substantive edits. Beyond that, report remaining
  disagreement rather than looping.

### Known limits of this gate

State these to the user when the stakes warrant it:

- A reviewer sharing your training data shares your blind spots. It catches
  citation drift, arithmetic, staleness, and overreach well; it catches
  _shared misconceptions_ poorly. Run the reviewer on a different model where
  the answer matters.
- This produces **sourced and challenged**, not **proven**. Do not describe
  reviewed output as verified, confirmed, or proven fact.
