---
name: commit
description: Create a git commit
disable-model-invocation: true
allowed-tools: Bash(git *)
---

Create a commit for the staged and unstaged changes. Follow these rules exactly:

1. Run `git status` and `git diff` (staged + unstaged) to understand all changes
2. Run `git log --oneline -5` to match the repo's commit message style
3. Stage relevant files by name (never `git add -A` or `git add .`)
4. Do not commit files that contain secrets (.env, credentials, tokens)
5. Write the commit message:
   - Imperative subject line, concise (under 72 chars)
   - Optional short body explaining "why", not "what"
   - End with: `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
6. If the project has doc-update conventions (CLAUDE.md, README, changelogs), check whether docs need updating and flag it before committing
7. Use a HEREDOC to pass the message to `git commit -m`
8. Run `git status` after to verify success
