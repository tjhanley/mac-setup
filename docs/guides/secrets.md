# Secrets

Managing API keys, tokens, and environment variables — both machine-local and per-project.

## Overview

| Mechanism | Scope | Backed by |
|---|---|---|
| `~/.secrets` | shell (all projects) | Dashlane via `refresh-secrets` |
| `.env.schema` | per-project process | Dashlane via `varlock run` |

---

## Machine-local secrets (`~/.secrets`)

`~/.secrets` is sourced at the end of `.zshrc` if it exists. It holds tokens and API keys that should be available in every shell session. It is gitignored and never committed.

### Populating from Dashlane

**First-time setup on a new machine:**

1. Copy the example config and fill in your Dashlane vault paths:
   ```sh
   cp .secrets-config.example ~/.secrets-config
   nvim ~/.secrets-config
   ```

2. Authenticate with Dashlane CLI:
   ```sh
   dcli accounts whoami
   ```

3. Pull secrets from the vault:
   ```sh
   refresh-secrets
   ```

`~/.secrets` is now written and sourced in the current shell. Future shells source it automatically at startup.

### Refreshing after vault changes

```sh
refresh-secrets
```

Re-runs the full fetch — reads `~/.secrets-config`, calls `dcli read` for each path, writes `~/.secrets` atomically (tempfile → mv), and sources it in the current shell.

### How `~/.secrets-config` works

```sh
# ~/.secrets-config — maps env var names to Dashlane item paths
ANTHROPIC_API_KEY=dl://anthropic-api-key/password
GITHUB_TOKEN=dl://github-token/password
OPENAI_API_KEY=dl://openai-api-key/password
```

Each line is `KEY=dl://<item-title>/<field>`. The field is `password` for password items, `note` for secure notes. Blank lines and `#` comments are ignored.

To find the right title and fields for an item:
```sh
dcli secret -o json
```

The example template is at `.secrets-config.example` in the repo root — copy it and update the paths to match your vault structure.

### Adding a new secret

1. Add the secret to your Dashlane vault
2. Add the mapping to `~/.secrets-config`:
   ```sh
   NEW_TOKEN=dl://new-token/password
   ```
3. Run `refresh-secrets`

---

## Per-project secrets (`.env.schema`)

For project-level environment variables, this repo uses [varlock](https://varlock.dev) — a declarative schema format. Sensitive vars are resolved from Dashlane at process-spawn time rather than written to disk.

The repo root `.env.schema` is the template:

```sh
# @sensitive @required @type=string(startsWith=sk-ant-)
ANTHROPIC_API_KEY=exec('dcli read "dl://anthropic-api-key/password"')

# @sensitive @required
GITHUB_TOKEN=exec('dcli read "dl://github-token/password"')

# @type=string
AWS_PROFILE=
```

`exec('...')` values are resolved by varlock at runtime — dcli is called per-var when you run a command through varlock.

### Running a command with secrets injected

```sh
varlock run -- <command>
```

Examples:
```sh
varlock run -- env | grep ANTHROPIC       # verify resolution
varlock run -- node server.js             # inject into a process
varlock run -- python script.py
```

### Copying `.env.schema` to a project

Copy the repo root `.env.schema` to any project that needs the same vars, then adjust the Dashlane paths and annotations as needed.

For vars that don't need Dashlane (non-sensitive, machine-independent), set them as plain values:
```sh
AWS_REGION=us-east-1
```

---

## Bootstrapping Dashlane (first machine setup)

If you're setting up Dashlane for the first time or populating a new vault, use the bootstrap script to bulk-create secrets from your existing `~/.secrets`:

```sh
# Preview what would be created
./scripts/bootstrap-dashlane.sh --dry-run

# Upload from current ~/.secrets values
./scripts/bootstrap-dashlane.sh --from-file

# Or enter values interactively (hidden input)
./scripts/bootstrap-dashlane.sh
```

The script reads `~/.secrets-config` for paths, authenticates via dcli, and creates/updates each secret in the vault.

---

## Reference

| File | Purpose |
|---|---|
| `~/.secrets` | Live secrets, sourced by `.zshrc` — do not edit manually if using Dashlane |
| `~/.secrets-config` | Key→vault-path mappings — gitignored, machine-local |
| `.secrets-config.example` | Template checked into repo — copy to `~/.secrets-config` |
| `.env.schema` | Per-project varlock schema — committed, safe (no values) |
| `scripts/bootstrap-dashlane.sh` | One-time vault population script |

| Command | What it does |
|---|---|
| `refresh-secrets` | Regenerate `~/.secrets` from Dashlane |
| `varlock run -- <cmd>` | Run command with per-project secrets injected |
| `dcli accounts whoami` | Authenticate / show current account |
| `dcli secret -o json` | List all secrets with fields (useful for finding paths) |
| `dcli read "dl://<title>/<field>"` | Read a single secret value |
