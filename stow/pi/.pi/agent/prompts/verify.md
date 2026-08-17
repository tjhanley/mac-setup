---
description: Run the adversarial review gate on the current draft
---

Run the adversarial review gate.

Target: $ARGUMENTS
If no target was given, review your own most recent substantive response.

## Step 1 — Extract claims

Build this table from the target. Do not editorialise; extract what was
actually asserted, including things asserted by implication.

| # | Claim | Source given | Load-bearing? | My confidence |
|---|-------|--------------|---------------|---------------|

Load-bearing means: if this claim is false, the conclusion changes.

## Step 2 — Attack

Pi has no subagent tool, so the adversary is a separate cold pi process.

1. Write the full draft followed by the claims table to `/tmp/pi-verify-draft.md`.
   Verbatim — no summarising, no pre-defending, no marking which claims you
   believe are solid.
2. Run it:

```bash
pi -p --no-session \
  --model claude-sonnet-5 \
  --append-system-prompt ~/.claude/agents/red-team.md \
  --append-system-prompt "Your tools are pi's: read, write, edit, bash, grep, find, ls. There is no WebFetch or WebSearch tool - open URLs with curl through bash, and use gh for GitHub. Ignore the tool list in the frontmatter above." \
  "Attack this draft. $(cat /tmp/pi-verify-draft.md)"
```

Notes on that command:

- `--model claude-sonnet-5` — a different model from the one drafting, per the
  known limits in `~/.claude/CLAUDE.md`. Only the `anthropic` provider is
  authenticated in pi (`~/.pi/agent/auth.json`), so the adversary shares a
  training lineage with the author. It catches citation drift, arithmetic,
  staleness, and overreach; it catches shared misconceptions poorly. Say so
  when the stakes warrant it.
- `--no-session` — the adversary must meet the draft cold and leave no session
  behind.
- `~/.claude/agents/red-team.md` is the shared adversary definition. Its YAML
  frontmatter names Claude Code tools; the second `--append-system-prompt`
  overrides that.

## Step 3 — Report

Present, in this order:

1. **Verdict summary** — counts by verdict.
2. **Blockers** — load-bearing claims that did not survive. For each: what the
   claim was, why it failed, and what the conclusion becomes without it.
3. **Corrections** — claims you are now weakening or cutting, with the revised
   wording.
4. **Unresolved** — what neither of you could check, stated plainly.

Then give the corrected draft.

## Rules

- Repair means finding a real source, weakening the claim to fit the evidence,
  or cutting it. It does not mean asserting it again more confidently.
- One re-review after substantive edits. Past that, report the remaining
  disagreement rather than looping.
- If the review found nothing, say so — but report what the reviewer checked,
  so "nothing found" is distinguishable from "nothing looked at".
- Close with the standing caveat: this produces sourced and challenged output,
  not proven output.
