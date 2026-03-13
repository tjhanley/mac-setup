---
name: pr
description: Create a pull request
disable-model-invocation: true
allowed-tools: Bash(git *, gh *)
---

Create a pull request for the current branch. Follow these steps:

1. Run `git status`, `git log --oneline main..HEAD`, and `git diff main...HEAD --stat` to understand all changes
2. **Run the `pre-push-check` skill** to scan for sensitive info before pushing. Stop if anything is flagged.
3. Check if the branch tracks a remote and is pushed; push with `-u` if needed
4. Write a PR title:
   - Under 70 chars, imperative voice
   - Details go in the body, not the title
5. Create the PR with `gh pr create` using this format:

```
gh pr create --title "title" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Test plan
- [ ] test steps...

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

6. Return the PR URL when done
