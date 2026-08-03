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

## Obsidian Vault Conventions

All vault `.md` files must have valid YAML frontmatter with at minimum a `type:` field and `tags:`. When creating or editing markdown files in the Obsidian vault, always include frontmatter. Use the path to determine type:

- `people/` → `type: person`
- `projects/` → `type: project`
- `tasks/` → `type: task`
- `ideas/` → `type: idea`
- `Atlas/Sonatus/DailyBrief/` → `type: daily-brief`
- `Atlas/Sonatus/DailySummary/` → `type: daily-summary`
- `Clippings/` → `type: clipping`

## Platform Notes

On macOS: use Python or `/bin/zsh` for scripting when advanced features are needed. macOS ships bash 3 which lacks associative arrays, `${var,,}` lowercase syntax, `mapfile`, and other bash 4+ features. Do not write bash scripts that depend on these.

## MCP & Integrations

When MCP tools return empty or limited results (Slack message bodies hidden, Jira API limitations, Calendar auth expired), report the limitation clearly and continue with other data sources. Never silently retry the same failing query. Never abort a multi-step workflow because one integration failed — skip it, note what was skipped, and deliver what you can.

## Jira Sync Conventions

- When running jira-sync, paginate all results (Jira caps at 100 issues per query); never report counts from a single unpaginated query.
- Extract fields with jq using defensive access for differently nested fields (e.g., check both `.fields.assignee.emailAddress` and nested variants).

## MCP Server Health Checks

- Before running any command that depends on an MCP server (Granola, Atlassian, Slack), verify the server is connected first; if it fails, report the diagnosis and remediation steps immediately rather than retrying repeatedly.

## Note Editing

- When merging generated content into daily/notes files, check for and avoid creating duplicate section headers (e.g., '## Notes') before writing.
