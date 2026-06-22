# Graphite Getting Started Guide
## Sonatus Cloud AI — `gen_ai` & `ai-technician-frontend`

**Pilot scope:** ~12 seats · DevX contact: Tom Hanley, Miguel (questions → #devx-support)  
**Reference:** [RFC-006](https://sonatus.atlassian.net/wiki/spaces/ENGOPS/pages/3629678594) · [Graphite docs](https://graphite.com/docs) · [graphite.com/app](https://app.graphite.com)

---

## Why Graphite?

Claude-assisted development produces feature work as a sequence of dependent PRs. Without tooling, landing them means manually rebasing every PR above an ancestor every time it merges — one feature in `gen_ai` cost ~19 rebases and 10+ days. Graphite solves this: one command (`gt submit --stack`) opens all PRs in dependency order; one command (`gt sync`) keeps the whole stack rebased after any merge.

PRs stay plain GitHub PRs. Your existing branch protection rules, the PR size CI check, and PR→Jira enforcement all continue to apply.

---

## Step 1: Install the CLI

```bash
brew install withgraphite/tap/graphite
```

Verify:

```bash
gt --version
```

Requires `gt` ≥ v0.21.0 to authenticate.

---

## Step 2: Authenticate

1. Go to [app.graphite.com/settings/cli](https://app.graphite.com/settings/cli)
2. Name a token (e.g. "Work laptop") and click **Create new token**
3. In your terminal, run the command Graphite shows you:

```bash
gt auth --token <your-token>
```

---

## Step 3: Initialize each repo (one-time per machine)

**Yes — every developer must do this**, once per repo per machine. The config Graphite writes is stored at `.git/.graphite_repo_config`, which lives inside your local `.git` folder and is never committed to the repo. Every clone on every machine needs its own initialization.

What `gt init` does: it asks which branch is your trunk (the branch PRs merge into). Graphite uses this to know where to sync from and how to order PR base branches. For both Sonatus repos, the answer is `main`.

```bash
cd ~/path/to/gen_ai
gt init
# → Select "main" when prompted

cd ~/path/to/ai-technician-frontend
gt init
# → Select "main" when prompted
```

**You don't have to run `gt init` explicitly upfront.** If you skip it, the first `gt` command you run will auto-prompt you to pick a trunk branch. But running it first avoids the interruption mid-flow.

**If you re-clone a repo**, you'll need to run `gt init` again in the new clone — the config doesn't transfer with the code.

---

## Daily Workflow

### The mental model

A **stack** is a chain of branches, each built on the previous one. You work from the bottom up; Graphite keeps everything rebased automatically.

```
main
 └── feat/api-endpoint          ← PR 1
      └── feat/frontend-page    ← PR 2 (stacked on PR 1)
           └── feat/e2e-tests   ← PR 3 (stacked on PR 2)
```

### Creating your first PR

```bash
# Start from main
gt checkout main

# Make changes
echo "new code" >> src/api.py

# Create a branch + commit in one step
# Branch name is derived from the message
gt create --all --message "feat(api): add user fetch endpoint"

# Push and open a PR
gt submit
```

`gt create` stages, commits, and checks out the new branch. `--all` is the equivalent of `git add -A`.

### Adding a second PR on top

```bash
# Open interactive branch picker — select the PR you want to stack on
gt checkout

# Make changes
echo "frontend code" >> src/frontend/page.tsx

# Stack a new branch on top
gt create --all --message "feat(frontend): display user list"

# Submit the whole stack (opens both PRs, sets correct base branches)
gt submit --stack
```

### See your stack

```bash
gt log short   # compact view (alias: gt ls)
gt log         # full view with PR status, CI, reviewers
```

### Assign reviewers

```bash
# At submit time
gt submit --stack --reviewers alice,bob

# Or open the PR in the Graphite UI
gt pr
```

---

## Addressing Reviewer Feedback

When a reviewer asks for changes on a PR in the middle of your stack:

```bash
# Check out the branch that needs changes
gt checkout feat/api-endpoint

# Edit the file
vim src/api.py

# Amend the commit AND auto-restack all branches above
gt modify --all
```

That's it. Graphite rebases every branch above yours onto the new commit. To add a new commit instead of amending:

```bash
gt modify --commit --all --message "address review: rename parameter"
# shorthand: gt m -cam "address review: rename parameter"
```

Push the updates:

```bash
gt submit --stack
```

---

## Staying In Sync with `main`

Run this frequently — especially before starting new work or after any upstream merge:

```bash
gt sync
```

This pulls the latest `main`, rebases all your open stacks on top, and prompts you to delete any branches that have already merged. If a rebase hits a conflict, `gt sync` will tell you which branch to check out and run `gt restack` on.

---

## Merging Your Stack

Once a PR is approved and CI is green:

1. Go to the top PR of the stack: `gt top && gt pr`
2. Click **Merge** in the Graphite UI

Graphite merges in bottom-up order automatically. To merge only part of a stack, navigate to the PR you want to merge from and click **Merge** from there.

After merging, run `gt sync` locally to clean up merged branches.

---

## Sonatus-Specific Notes

### PR size check
`gen_ai` enforces PR size via CI labeling (`pr_size.yml`). Thresholds are based on **added lines only** (deletions don't count):

- **≥1000 added lines** → "L" label, soft nudge to split the PR
- **≥2000 added lines** → "XL" label, **hard fail**

The following file types are excluded from the count: `*.md`, `*.rst`, `*.txt`, lockfiles, `*.ipynb`, `*.csv`, `*.parquet`, `*.jsonl`, `*.sql`, `*.drawio`. If your PR is incorrectly flagged, ping DevX.

### PR → Jira enforcement
All PRs must include a Jira ticket reference in the title or description (format: `ENGOPS-XXXX`). This applies to every PR in a stack. Graphite does not add this for you — make sure each `gt create` message or PR description includes the ticket.

### Branch protection
Both repos have branch protection on `main`. `gt submit` respects this — it creates PRs targeting the correct base branch rather than pushing directly to `main`.

### CI hazard: workflows using `github.base_ref`
When you stack PRs, `gt create` sets a PR's base to a synthetic `graphite-base/<PR#>` ref. A later `gt submit`/restack rewrites the base to `main` and **deletes** that ref. Any CI step that does `git diff "origin/${{ github.base_ref }}...HEAD"` then fails with `fatal: bad revision`, and `gh run rerun` replays the stale event payload so reruns keep failing. Fixes:

- **Workflow author:** diff against the immutable SHA — `${{ github.event.pull_request.base.sha }}` — not the ref name. The `gen_ai` test workflows (`ait_solutions-tests.yml`, `ait_platform-tests.yml`) were fixed this way.
- **Hitting it on another repo's workflow:** push an empty commit (`git commit --allow-empty`) to fire a fresh event, and flag the workflow to its owner.

### VS Code extension (optional)
The Graphite VS Code extension makes stacking visual. Install it from the Extensions sidebar (search "Graphite") or via [graphite.com/docs/vscode-extension](https://graphite.com/docs/vscode-extension).

### Slack notifications
Install the Graphite Slack app at [app.graphite.com/settings/notifications](https://app.graphite.com/settings/notifications) to get notified when PRs in your stacks are reviewed or merged.

---

## Agent (Claude) Usage

Claude can drive the Graphite workflow directly via the Graphite MCP. When working in an agentic session:

- Claude will use `gt create`, `gt modify`, and `gt submit --stack` to create and submit feature stacks
- Claude will use `gt sync` to keep branches rebased
- Each PR Claude creates still needs a Jira ticket reference in the description — include the ticket in your prompt to Claude

To enable the Graphite MCP in your Claude session, follow the setup at [graphite.com/docs/gt-mcp](https://graphite.com/docs/gt-mcp).

---

## Quick Reference

| Task | Command | Short form |
|------|----------|-----------|
| Create branch + commit + stage all | `gt create --all --message "..."` | `gt c -am "..."` |
| Amend + restack above | `gt modify --all` | `gt m -a` |
| New commit + restack above | `gt modify --commit --all --message "..."` | `gt m -cam "..."` |
| Submit current branch + all below | `gt submit` | |
| Submit whole stack | `gt submit --stack` | `gt ss` |
| Sync from main, clean up merged | `gt sync` | |
| View stack (compact) | `gt log short` | `gt ls` |
| Switch branch (interactive) | `gt checkout` | `gt co` |
| Go up one branch | `gt up` | `gt u` |
| Go down one branch | `gt down` | `gt d` |
| Go to top of stack | `gt top` | `gt t` |
| Open PR in browser | `gt pr` | |
| Undo last Graphite action | `gt undo` | |

---

## Getting Help

- **DevX support:** ping Tom or Miguel in #devx-support, or drop into office hours (2×/week during pilot)
- **Full docs:** [graphite.com/docs](https://graphite.com/docs)
- **Command reference:** [graphite.com/docs/command-reference](https://graphite.com/docs/command-reference)
- **Graphite community Slack:** [community.graphite.com](https://community.graphite.com)
