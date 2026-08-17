---
name: vault-tasks
description: Add, list, or update tasks in Tom's necronomicon Obsidian vault at ~/necronomicon/tasks/. Triggers on "add a task", "create a todo", "remind me to …", "what tasks do I have", "list my todos", "show open tasks", "what's on my plate", "mark X done", "close the X task", "X is blocked because …". Uses consistent frontmatter (type, status, tags, created), cross-links with [[wiki-links]], preserves vault conventions. Scope is intentionally narrow — vault files under `~/necronomicon/tasks/` only — do not pull in Jira/Slack/Daily Brief data unless the user explicitly asks for a cross-system view.
---

# Vault Tasks

Manage tasks in the necronomicon Obsidian vault at `~/necronomicon/tasks/`.

## Triggers

| Intent | Examples |
|---|---|
| **Add** | "add a task", "create a todo", "remind me to X", "new task for Y", "I need to do X" |
| **List** | "what tasks do I have", "list my todos", "show open tasks", "what's on my plate" |
| **Update** | "mark X done", "close the X task", "X is blocked because Y", "I'm working on X now" |

## Scope: vault tasks only

This skill operates on `*.md` files in `~/necronomicon/tasks/`. It does **not** merge in Daily Brief items, open Jira issues, Slack carry-overs, or calendar events. If the user asks "what's on my plate" they're asking about **this folder**. Cross-system views (Jira + vault + Slack) are a separate workflow — if the user explicitly asks for one, say "that's a different workflow than this skill" and offer to run the relevant skill (e.g. `/standup` or a daily-brief skill).

## Add a task

Create `~/necronomicon/tasks/<kebab-case-slug>.md`. Slug: 3–6 words, descriptive. Examples from vault: `ansible-lint-setup`, `meet-octo-team-neema`, `jenkins-build-counts`.

### Frontmatter (required)

```yaml
---
type: task
status: open
tags:
  - <primary-area>     # e.g. sonatus, personal, claude
  - <secondary>        # e.g. ansible, jenkins, tooling, security, devex
created: YYYY-MM-DD    # today, ISO 8601 (date -I)
---
```

Optional frontmatter fields:

- `due: YYYY-MM-DD` — deadline
- `priority: high | medium | low`
- `assignee: PersonName` — if delegating
- `project: "[[project-slug]]"` — parent project link

### Body (scale with task complexity)

**Quick task** (single action, no context needed) — frontmatter + one line:
```markdown
- [ ] Look into setting up Varlock with Dashlane CLI using Claude 📅 2026-03-13
```

**Standard task** — use these sections, omit ones with nothing to say:
```markdown
## Goal
<one-line outcome>

## Next Actions
- [ ] <step 1>
- [ ] <step 2>

## Context
<why this matters, what surfaced it, who asked>

## Links
- [[related-task-or-person]]
- <External URL>
```

Always include Goal + Next Actions for non-trivial tasks. Context helps future-you remember why.

### Tag conventions

Common tags in the vault, pick 2–4 that fit:

- **Orgs/scope:** `sonatus`, `personal`, `home`
- **Functional:** `devex`, `infra`, `security`, `tooling`, `compliance`, `onboarding`, `hiring`
- **Tech:** `ansible`, `jenkins`, `aws`, `claude`, `github`, `obsidian`, `python`, `nfs`, `pure-storage`
- **Project:** `okr-<slug>`, `jumpcloud`, `kr` (region)

Grep existing tasks for similar topics before inventing new tags:
```
grep -l 'ansible' ~/necronomicon/tasks/*.md
```

## List tasks

1. Read `~/necronomicon/tasks/*.md`
2. Parse YAML frontmatter on each
3. Filter by **non-terminal** status (default: everything except `done` and `cancelled`) and optionally by tag(s)
4. Sort: active statuses first (open → in-progress → active → pending → blocked), then terminals (done → cancelled). Within a group, prefer `due` date ascending (overdue first) then `created` desc.

### Output format

```
🟢 open         ansible-lint-setup        sonatus, ansible, tooling, devex
🟡 in-progress  meet-octo-team-neema      sonatus, onboarding
🟠 pending      qatools-nas-sync-docs     sonatus · due 2026-04-10 (overdue)
🟣 active       jenkins-aws-consolidation  sonatus, infrastructure · type:project
🔴 blocked      drata-compliance          compliance
✅ done         varlock-dashlane          tooling, security, claude
⚪ cancelled    <slug>                    <tags>
```

Include count summary: `1 open · 1 in-progress · 4 pending · 1 active · 1 blocked · 11 done`.

If filtering ("show sonatus tasks"), note the filter in the output header.

## Update a task

Read the file, edit in place. Preserve everything except the fields you're changing.

### Mark done

```yaml
# before
status: open
# after
status: done
completed: 2026-04-21
```

Tick any outstanding top-level checkboxes in the body.

### Mark blocked

```yaml
# before
status: open
# after
status: blocked
```

Add or update a `## Blocker` section at the top of the body explaining what's blocking and the expected unblock path:
```markdown
## Blocker
Waiting on IT to provision my access to the Drata portal (2026-04-21).
Unblocks when: IT ticket resolves + I can log in.
```

**Do not** invent sibling fields like `blocked_since:` / `blocked_on:` — the `## Blocker` section is the convention. The `created` date is preserved; add a date inside the Blocker section if tracking how long it's been blocked matters.

### Mark in-progress / active / pending

Flip `status:` to the new value. Add a one-line note in the body under a `## Progress` section if there's useful context (what you just did, what's next).

### Cancel

```yaml
status: cancelled
cancelled: 2026-04-21
```

Add a `## Cancellation reason` section explaining why. Don't delete the file.

## Status picklist

The vault has accumulated several status values over time. Treat them as a superset; use the one that best reflects current state.

| Value | When to use | Emoji |
|---|---|---|
| `open` | Not started, no blockers | 🟢 |
| `in-progress` | Actively working, no external dependency | 🟡 |
| `active` | Ongoing / long-lived (common on `type: project` entries) | 🟣 |
| `pending` | Waiting on something external (person, process, ticket) — softer than `blocked` | 🟠 |
| `blocked` | Hard stop; can't proceed until dependency resolves | 🔴 |
| `done` | Complete | ✅ |
| `cancelled` | Abandoned | ⚪ |

When creating a new task, default to `open`. When updating, use the value that fits — don't force a rename if the existing status is valid.

### `type: project` vs `type: task`

Some entries in `tasks/` use `type: project` (e.g. `jenkins-aws-consolidation.md`). These are longer-lived efforts living in the task folder. Treat them as first-class for listing ("what's on my plate" includes them) — note `type:project` in the list output so the user sees the distinction. Don't convert project→task or vice versa unless explicitly asked.

## Vault paths

- **Root:** `/Users/thomas.hanley/necronomicon`
- **Tasks:** `~/necronomicon/tasks/`
- **Vault `CLAUDE.md`:** `~/necronomicon/CLAUDE.md` — vault-wide conventions live here; consult before writing anything unusual.
- **Frontmatter rule:** vault-wide — every `.md` needs at minimum `type:` and `tags:`.

## Cross-linking

Use `[[wiki-links]]` in Links section to connect tasks to:
- People — `[[person-name]]` in `people/`
- Projects — `[[project-slug]]` in `projects/`
- Jira tickets — `[[ENGOPS-1234]]` (often stub notes in vault root)
- Other tasks — `[[task-slug]]`

Obsidian resolves these via basename across the vault.

## Notes

- Don't use the harness TaskCreate tool — that's for in-conversation state, not the persistent vault.
- Don't delete task files — status transitions are vault history. Cancel rather than delete.
- Do use ISO dates (`YYYY-MM-DD`).
- Do prefer existing tags over inventing new ones.
- Do not aggregate cross-system data (Jira, Slack, calendar) into list output unless the user explicitly asks for a broader view.
