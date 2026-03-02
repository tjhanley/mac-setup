---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
argument-hint: "[issue-number]"
---

Fix GitHub issue $ARGUMENTS. Follow these steps:

1. Read the issue with `gh issue view $ARGUMENTS`
2. Explore the codebase to understand the relevant code
3. Implement the fix:
   - Keep changes minimal and focused
   - Don't refactor surrounding code unless directly related
   - Follow existing code conventions
4. Run existing tests if available; add tests if the project has them
5. Check if docs need updating per project conventions
6. Summarize what was changed and why, then ask if I should commit
