---
name: organize
description: Classify loose project notes and file them into per-project folders. Auto-applies unambiguous moves; only asks about genuinely ambiguous files.
---

# organize

File loose Markdown notes into `projects/<project-name>/`.

**Default is to act, not to propose.** Do not present a full move table and
wait. Execute the confident moves, then ask about the leftovers.

## 1. Inventory

```bash
cd "$VAULT_ROOT"
ls projects/*.md 2>/dev/null
```

If zero loose files, print `Nothing to file.` and stop.

## 2. Classify into confidence tiers

For each loose file, gather signals in this order and stop at the first that
resolves:

**Tier A — HIGH confidence (auto-apply, no prompt).** Any one of:

- Filename carries a known project prefix matching an existing
  `projects/<project>/` directory (case-insensitive, hyphen/underscore
  equivalent).
- Front-matter has a `project:` key naming an existing project directory.
- Every inbound wiki link to this file comes from notes already inside one
  single project directory.
- The file's body contains three or more references to exactly one project's
  Jira key prefix and none to any other.

**Tier B — AMBIGUOUS (ask).** Everything else, including:

- Signals point at two or more projects.
- The implied project directory does not exist yet.
- No signal at all (no prefix, no front-matter, no inbound links).

Never invent a new project directory in Tier A. Creating a directory is always
a Tier B decision.

## 3. Apply Tier A immediately

For each Tier A file:

```bash
git mv "projects/<file>.md" "projects/<project>/<file>.md"
```

Use `git mv`, never `mv` — history preservation is the point.

Then rewrite inbound links. For each note that links to the moved file:

```bash
grep -rl "\[\[<old-name>\]\]" --include="*.md" . \
  | xargs -r sed -i '' "s|\[\[<old-name>\]\]|[[<project>/<old-name>]]|g"
```

(Drop the `''` after `-i` if you're on GNU sed rather than macOS.)

If a `git mv` fails, log the reason and demote that file to Tier B. Do not
abort the run.

## 4. Log to MOVES.md

Append one block per run to `projects/MOVES.md`, so every automatic move is
reversible without reading git history:

```markdown
## 2026-08-03T14:59Z

| From | To |
|---|---|
| projects/foo.md | projects/kariba/foo.md |

Revert: `git mv projects/kariba/foo.md projects/foo.md`
```

Commit the moves and the log together:

```bash
git add -A && git commit -m "organize: file N loose notes"
```

## 5. Ask only about Tier B

Print a short table — **only ambiguous files**, never the ones already moved:

```
Needs your call (3):

| File | Candidates | Why ambiguous |
|---|---|---|
| retro-notes.md | kariba, devx | links from both |
| ideas.md | — | no signal |
| q3-plan.md | q3-planning (new) | directory doesn't exist |
```

Then stop and wait. Do not guess.

## 6. Summary

One line, always:

```
Filed 29 · ambiguous 3 · failed 0 · logged to projects/MOVES.md
```

## Guardrails

- Never move a file out of a project directory, only into one.
- Never touch files outside `projects/`.
- Never move more than 50 files in one run without asking first — if the
  inventory exceeds 50, present the count and confirm before proceeding.
- If the working tree is dirty before you start, say so and stop. Auto-applied
  moves need a clean baseline to be revertible.
