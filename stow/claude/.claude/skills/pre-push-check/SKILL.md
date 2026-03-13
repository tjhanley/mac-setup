---
name: pre-push-check
description: Use when about to push commits or create a PR - scans changes for secrets, API keys, tokens, credentials, or other sensitive information before they reach remote
---

# Pre-Push Sensitive Info Check

Scan commits about to be pushed for sensitive information. Run this before any `git push` or PR creation.

## Steps

1. **Get the diff to scan**
   ```bash
   # All commits not yet on remote (most common case)
   git diff origin/$(git branch --show-current)...HEAD

   # Or for initial push / no remote tracking:
   git diff HEAD~$(git rev-list --count HEAD)..HEAD 2>/dev/null || git show HEAD
   ```

2. **Scan with gitleaks if available** (preferred — comprehensive ruleset)
   ```bash
   which gitleaks && gitleaks detect --source . --no-git 2>/dev/null || echo "gitleaks not installed"
   # Or scan staged/committed: gitleaks git --commits 5
   ```

3. **Fallback grep scan** — run against the diff from step 1:
   ```bash
   git diff origin/$(git branch --show-current)...HEAD | grep -iE \
     '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-ant-[A-Za-z0-9]{90,}|sk-[A-Za-z0-9]{48}|xox[bpsa]-[A-Za-z0-9-]+|-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY|password\s*=\s*["\x27][^"\x27]{4,}|secret\s*=\s*["\x27][^"\x27]{4,}|api[_-]?key\s*=\s*["\x27][^"\x27]{4,}|token\s*=\s*["\x27][^"\x27]{8,})'
   ```

4. **Check for .env or credential files accidentally staged**
   ```bash
   git diff --name-only origin/$(git branch --show-current)...HEAD | grep -iE '(\.env$|\.pem$|id_rsa|id_ed25519|credentials|\.secret)'
   ```

5. **Report findings**
   - If anything matches: stop, report exact file/line, ask user whether to proceed
   - If clean: confirm "No sensitive patterns found" and proceed with push

## Common False Positives
- Example/placeholder values (`your-api-key-here`, `changeme`, `example.com`)
- References to env var names without values (`export API_KEY=` with no value)
- Documentation explaining what a secret looks like

## Red Flags — Always Stop
- Any match for `AKIA` (AWS key ID)
- Any match for `ghp_`, `github_pat_` (GitHub PAT)
- Any `-----BEGIN ... PRIVATE KEY-----` block
- Real-looking base64 strings (40+ chars) assigned to `secret`, `password`, `token`
