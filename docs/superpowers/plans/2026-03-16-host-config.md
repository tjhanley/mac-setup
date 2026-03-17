# Host Config Feature Flags Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-machine feature flags via `~/.mac-setup.local` so optional bootstrap functions can be toggled per host.

**Architecture:** A `load_host_config()` function sources `~/.mac-setup.local` (plain shell vars) early in bootstrap. A `feature_enabled()` helper checks if a named flag is `1`/`true` (enabled) or anything else (disabled), defaulting to enabled when unset (opt-out semantics). No existing functions are gated yet — the mechanism is built and tested for the yabai milestone to consume.

**Tech Stack:** zsh, bats-core

**Spec:** `docs/superpowers/specs/2026-03-16-host-config-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `bootstrap/bootstrap-mac.zsh` | Modify | Add `load_host_config()`, `feature_enabled()`, wire into `main()` |
| `.mac-setup.local.example` | Create | Documents all supported flags with defaults |
| `.gitignore` | Modify | Add `.mac-setup.local` to prevent accidental tracking |
| `tests/host-config.bats` | Create | Test coverage for both new functions |
| `README.md` | Modify | Add host config to "What It Does" and "Customize" sections |
| `docs/mac-setup-log.md` | Modify | Add host config to "Bootstrap behavior" section |
| `man/man7/mac-setup.7` | Modify | Add host config to FILES and BOOTSTRAP STEPS |

---

## Chunk 1: Core functions, tests, example file, and docs

### Task 1: Write failing tests for feature_enabled

**Files:**
- Create: `tests/host-config.bats`

- [ ] **Step 1: Create test file with all tests**

Note: `setup()`/`teardown()` are defined once at top level. The `run_zsh_fn` helper hardcodes `DRY_RUN=1` after eval, so load_host_config tests that need `DRY_RUN=0` must override it inside the snippet.

```bash
#!/usr/bin/env bats

# Test host config functions.
# The bootstrap script is zsh, so we shell out to zsh for each test.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/bootstrap/bootstrap-mac.zsh"

# Helper: run a zsh snippet that sources the bootstrap (minus main) then calls a function.
run_zsh_fn() {
  run zsh -c "
    set -euo pipefail
    DOTFILES_DIR='$REPO_ROOT'
    BACKUP_DIR='${BACKUP_DIR:-/tmp/bats-backup-$$}'
    DEBUG=false
    eval \"\$(sed '/^main \"\\\$@\"/d' '$BOOTSTRAP')\"
    DRY_RUN=1
    $*
  "
}

setup() {
  export BACKUP_DIR="$(mktemp -d)"
  export TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$BACKUP_DIR" "$TEST_TMPDIR"
}

# --- feature_enabled ---------------------------------------------------------

@test "feature_enabled returns 0 when flag is 1" {
  run_zsh_fn 'FEATURE_X=1; feature_enabled FEATURE_X'
  [[ "$status" -eq 0 ]]
}

@test "feature_enabled returns 0 when flag is true" {
  run_zsh_fn 'FEATURE_X=true; feature_enabled FEATURE_X'
  [[ "$status" -eq 0 ]]
}

@test "feature_enabled returns 1 when flag is 0" {
  run_zsh_fn 'FEATURE_X=0; feature_enabled FEATURE_X'
  [[ "$status" -eq 1 ]]
}

@test "feature_enabled returns 1 when flag is false" {
  run_zsh_fn 'FEATURE_X=false; feature_enabled FEATURE_X'
  [[ "$status" -eq 1 ]]
}

@test "feature_enabled returns 1 when flag is yes (strict)" {
  run_zsh_fn 'FEATURE_X=yes; feature_enabled FEATURE_X'
  [[ "$status" -eq 1 ]]
}

@test "feature_enabled returns 1 when flag is empty string" {
  run_zsh_fn 'FEATURE_X=""; feature_enabled FEATURE_X'
  [[ "$status" -eq 1 ]]
}

@test "feature_enabled returns 0 when flag is unset (opt-out default)" {
  run_zsh_fn 'unset FEATURE_X; feature_enabled FEATURE_X'
  [[ "$status" -eq 0 ]]
}

# --- load_host_config --------------------------------------------------------

@test "load_host_config sources config file and sets vars" {
  echo 'FEATURE_TEST_VAR=1' > "$TEST_TMPDIR/.mac-setup.local"
  run_zsh_fn "HOME='$TEST_TMPDIR'; DRY_RUN=0; load_host_config; feature_enabled FEATURE_TEST_VAR"
  [[ "$status" -eq 0 ]]
}

@test "load_host_config is no-op when config file absent" {
  run_zsh_fn "HOME='$TEST_TMPDIR'; DRY_RUN=0; load_host_config"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"No host config found"* ]]
}

@test "load_host_config prints dry-run message and does not source" {
  echo 'FEATURE_DRY_CHECK=0' > "$TEST_TMPDIR/.mac-setup.local"
  run_zsh_fn "HOME='$TEST_TMPDIR'; DRY_RUN=1; load_host_config; feature_enabled FEATURE_DRY_CHECK"
  [[ "$output" == *"dry-run:"* ]]
  # Flag should still be enabled (unset default) because source was skipped
  [[ "$status" -eq 0 ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/host-config.bats`
Expected: All 10 tests FAIL (feature_enabled and load_host_config not defined)

### Task 2: Implement feature_enabled and load_host_config

**Files:**
- Modify: `bootstrap/bootstrap-mac.zsh` (after `is_debug()`, line 24; and in `main()`)

- [ ] **Step 1: Add feature_enabled function**

Add after the `is_debug()` line (line 24):

```zsh
feature_enabled() {
  local val="${(P)1-1}"
  [[ "$val" == "1" || "$val" == "true" ]]
}
```

Note: `${(P)1-1}` (dash, not colon-dash) uses zsh parameter indirection. If the variable named by `$1` is unset, it defaults to `1` (enabled — opt-out). If set to empty string, it stays empty (disabled). Safe under `set -u`.

- [ ] **Step 2: Add load_host_config function**

Add after `feature_enabled()`, before `backup_and_remove_path()`:

```zsh
load_host_config() {
  local config="$HOME/.mac-setup.local"
  if [[ -f "$config" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f source $config"
      return
    fi
    source "$config"
    ok "Host config loaded: $config"
  else
    ok "No host config found; using defaults"
  fi
}
```

- [ ] **Step 3: Wire load_host_config into main()**

In the `main()` function, add `load_host_config` after `ensure_env_schema` and before `prepare_brew_binary_conflicts`:

```zsh
  ensure_env_schema
  load_host_config
  prepare_brew_binary_conflicts
```

- [ ] **Step 4: Run host-config tests to verify all pass**

Run: `bats tests/host-config.bats`
Expected: All 10 tests PASS

- [ ] **Step 5: Run full test suite**

Run: `bats tests/`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add bootstrap/bootstrap-mac.zsh tests/host-config.bats
git commit -m "feat: add host config feature flags to bootstrap

Add feature_enabled() helper (strict truthy: 1/true only, unset
defaults to enabled for opt-out semantics) and load_host_config()
which sources ~/.mac-setup.local if present. Wired into main()
after ensure_env_schema. Includes bats test coverage."
```

### Task 3: Create example file, update gitignore, and update all docs

**Files:**
- Create: `.mac-setup.local.example`
- Modify: `.gitignore`
- Modify: `README.md`
- Modify: `docs/mac-setup-log.md`
- Modify: `man/man7/mac-setup.7`

- [ ] **Step 1: Create .mac-setup.local.example**

```bash
# Host feature flags for mac-setup bootstrap
# Copy to ~/.mac-setup.local and uncomment to override defaults.
# Unset flags default to enabled (opt-out).
# Valid values: 1, true (enabled) / anything else (disabled)

# Tiling window manager (yabai)
# FEATURE_YABAI=1

# Hotkey daemon service (skhd)
# FEATURE_SKHD=1

# App Store installs (CopyLess 2, Magnet)
# FEATURE_APP_STORE=1
```

- [ ] **Step 2: Add .mac-setup.local to .gitignore**

In `.gitignore`, add after the `.secrets-config` line in the "Local overrides" section:

```
.mac-setup.local
```

- [ ] **Step 3: Update README.md "What It Does" list**

After step 5 (Check for `.env.schema`), insert:

```
6. Loads host feature flags from `~/.mac-setup.local` (if present); unset flags default to enabled
```

Renumber all subsequent steps (current 6 becomes 7, up through current 26 becoming 27).

- [ ] **Step 4: Update README.md "Customize" section**

Append after the secrets line:

```
- Toggle per-machine features in `~/.mac-setup.local` (copy from `.mac-setup.local.example`)
```

- [ ] **Step 5: Update docs/mac-setup-log.md "Bootstrap behavior" section**

After the `ensure_env_schema` bullet (line 17), add:

```
- Loads per-machine feature flags from `~/.mac-setup.local` via `load_host_config()`. File is plain shell vars sourced directly. Absent file means all features enabled (opt-out). `feature_enabled()` checks strict truthy (`1`/`true`); unset defaults to enabled.
```

- [ ] **Step 6: Update man page BOOTSTRAP STEPS**

After step 4 (Check for .env.schema), insert:

```troff
.IP 5. 4
Load host feature flags from ~/.mac-setup.local (if present); unset flags default to enabled
```

Renumber subsequent steps (current 5 becomes 6, through current 17 becoming 18).

- [ ] **Step 7: Add ~/.mac-setup.local to man page FILES section**

After the `~/.secrets-config` entry, add:

```troff
.TP
.B ~/.mac-setup.local
Per-machine feature flags (not tracked); copy from .mac-setup.local.example
```

- [ ] **Step 8: Commit**

```bash
git add .mac-setup.local.example .gitignore README.md docs/mac-setup-log.md man/man7/mac-setup.7
git commit -m "docs: add host config example file and update all docs

Add .mac-setup.local.example with supported feature flags.
Add .mac-setup.local to .gitignore. Update README, setup log,
and man page with host config documentation."
```
