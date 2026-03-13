# Varlock + Dashlane CLI Secrets Integration

**Date:** 2026-03-13
**Status:** Approved — implementation in progress

---

## Context

`~/.secrets` is currently a manually maintained plaintext file with no source-of-truth backing. It drifts across machines and requires manual updates when secrets rotate. Dashlane CLI (`dcli`) is already installed via Brewfile but unused for secret management.

**Varlock** (varlock.dev) is a declarative secrets schema tool. It provides an `exec()` escape hatch that runs any shell command to resolve a secret value, making integration with any CLI-based vault provider possible without native plugin support.

---

## Goals

1. **Global shell secrets**: A `refresh-secrets` zsh function regenerates `~/.secrets` from Dashlane on demand via a `~/.secrets-config` mapping file
2. **Per-project env**: Replace `.env.example` with `.env.schema` (varlock format), with sensitive vars backed by `exec('dcli secret get "..."')`

Varlock does not natively support Dashlane — `exec()` is intentional.

---

## Components

### ~/.secrets-config (new, gitignored)

A simple KEY=path mapping file:

```
# Maps env var names to Dashlane secret paths
ANTHROPIC_API_KEY=Personal/mac-setup/anthropic-api-key
GITHUB_TOKEN=Personal/mac-setup/github-token
```

Ignored by git (added to `.gitignore`). A `.secrets-config.example` template is committed to the repo for bootstrapping new machines.

### refresh-secrets (zsh function)

Added to `stow/zsh/.zshrc`. On invocation:
1. Reads `~/.secrets-config` line by line
2. Calls `dcli secret get "$path"` for each key
3. Writes `export KEY="value"` lines to a tempfile (chmod 600)
4. Moves tempfile to `~/.secrets` atomically
5. Sources `~/.secrets` in current shell

Error handling: missing config file, missing `dcli` binary, failed `dcli` fetch (aborts entire run).

### .env.schema (new, replaces .env.example)

Varlock schema format at repo root. Sensitive vars use `exec()` to shell out to dcli:

```
# @sensitive @required @type=string(startsWith=sk-ant-)
ANTHROPIC_API_KEY=exec('dcli secret get "Personal/mac-setup/anthropic-api-key"')

# @type=string
AWS_PROFILE=
```

Usage: `varlock run -- <command>` injects resolved vars into a subprocess.

### ensure_env_schema() (bootstrap update)

Replaces `ensure_local_env_file()` in `bootstrap/bootstrap-mac.zsh`. New behavior:
- `.env` exists → `ok ".env already exists"` (no-op)
- `.env.schema` exists, no `.env` → log that project uses varlock; hint `varlock run -- <command>`
- Neither exists → `warn "No .env.schema found"` and return

---

## Implementation Commits

| # | File(s) | Change |
|---|---------|--------|
| 1 | `brew/Brewfile` | Add varlock tap + formula |
| 2 | `.gitignore` | Add `.secrets-config` |
| 3 | `.secrets-config.example` | New template file |
| 4 | `stow/zsh/.zshrc` | Add `refresh-secrets` function |
| 5 | `.env.schema` / `.env.example` | Replace with varlock schema |
| 6 | `bootstrap/bootstrap-mac.zsh` | Rename + update `ensure_env_schema()` |
| 7 | docs | Update customization.md, README.md, mac-setup-log.md |
| 8 | `man/man7/mac-setup.7` | Man page sync via /update-man |

---

## Trade-offs

**exec() vs native integration:** No native Dashlane varlock plugin exists. `exec()` adds a subprocess per secret at eval time — acceptable for dev tooling, not suitable for hot paths. Anyone without `dcli` authenticated gets a clear error at `varlock run` time, not at shell startup.

**refresh-secrets vs direct sourcing:** `~/.secrets` stays as the shell-startup mechanism (fast, no dcli call on every new shell). `refresh-secrets` is an on-demand refresh — run it after vault changes or on new machine setup.

**Atomic tempfile write:** Writing to a tempfile then `mv` prevents a corrupted `~/.secrets` if `dcli` fails mid-run.

---

## Verification

1. `brew bundle --file=brew/Brewfile` — varlock installs cleanly
2. Copy `.secrets-config.example` → `~/.secrets-config`, fill in one real path → run `refresh-secrets` → verify `~/.secrets` written and var exported
3. `varlock run -- env | grep ANTHROPIC_API_KEY` — secret resolves via `.env.schema`
4. `./setup.sh --dry-run` — bootstrap runs cleanly with `ensure_env_schema()`
