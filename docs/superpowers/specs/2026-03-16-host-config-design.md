# Host Config: Per-Machine Feature Flags

**Date:** 2026-03-16
**Issues:** #6, #7, #8
**Milestone:** host-feature-flags

## Problem

No mechanism to toggle optional bootstrap features per machine. Features like yabai, work-specific tooling, or App Store installs are either hardcoded on or commented out. Downstream milestones (yabai-tiling, work-profile) depend on a clean gating mechanism.

## Design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Flag type | Boolean only (`1`/`true`) | Matches existing `DRY_RUN`/`HARD_RESET` patterns |
| Default behavior | Opt-out (everything runs if no config) | Backwards compatible; existing machines keep working |
| Truthy values | Strict: only `1` and `true` | Simple, consistent with bootstrap conventions |
| Config format | Sourced shell vars | Same pattern as `~/.secrets`; zero parsing code |

## Config file

`~/.mac-setup.local` -- plain shell variables, sourced by the bootstrap. Not tracked in git.

`.mac-setup.local.example` in repo root documents all supported flags:

```bash
# Host feature flags for mac-setup bootstrap
# Copy to ~/.mac-setup.local and uncomment to override defaults.
# Unset flags default to enabled (opt-out).
# Valid values: 1, true (enabled) / anything else (disabled)

# FEATURE_YABAI=1
# FEATURE_SKHD=1
# FEATURE_APP_STORE=1
```

## Bootstrap functions

### load_host_config()

Sources `~/.mac-setup.local` if present. No-op if absent. Supports `DRY_RUN` (prints what would be loaded, does not source). Wired into `main()` after `ensure_env_schema`, before `prepare_brew_binary_conflicts`.

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

### feature_enabled()

Returns 0 if flag is `1` or `true`, 1 otherwise. Unset variables default to `1` (enabled) for opt-out semantics. Empty strings are treated as disabled.

```zsh
feature_enabled() {
  local val="${(P)1}"
  [[ -z "$val" && -z "${(P)1+x}" ]] && val="1"
  [[ "$val" == "1" || "$val" == "true" ]]
}
```

`(P)` is zsh parameter indirection -- expands the variable whose name is in `$1`. The unset check uses `${(P)1+x}` which expands to `x` only if the variable is set (even to empty), distinguishing unset (default enabled) from `FEATURE_X=""` (disabled).

## Gating

No existing functions are gated in this milestone. The first consumer will be `install_yabai_service()` in the yabai-tiling milestone (#9-11), using:

```zsh
if ! feature_enabled FEATURE_YABAI; then
  log "Skipping yabai service (FEATURE_YABAI not enabled)"
  return
fi
```

The mechanism is ready for future gating of `FEATURE_SKHD`, `FEATURE_APP_STORE`, or any new optional feature.

## Tests

`tests/host-config.bats` -- reuses the `run_zsh_fn` helper pattern from `bootstrap.bats`.

### load_host_config tests

| Test | Expectation |
|------|-------------|
| Config file present | Sources file, vars available |
| Config file absent | No error, no-op |
| Dry-run with config present | Prints dry-run message |

### feature_enabled tests

| Input | Expected |
|-------|----------|
| `FEATURE_X=1` | Enabled (return 0) |
| `FEATURE_X=true` | Enabled |
| `FEATURE_X=0` | Disabled (return 1) |
| `FEATURE_X=false` | Disabled |
| `FEATURE_X=yes` | Disabled (strict) |
| `FEATURE_X=""` | Disabled (empty string) |
| Unset | Enabled (opt-out default) |

All tests use temp files. No side effects on `~/.mac-setup.local`.

## Files changed

| File | Change |
|------|--------|
| `bootstrap/bootstrap-mac.zsh` | Add `load_host_config()`, `feature_enabled()`, wire into `main()` |
| `.mac-setup.local.example` | New -- documents all supported flags |
| `tests/host-config.bats` | New -- test coverage for both functions |
| `README.md` | Document host config in "Customize" section |
| `docs/mac-setup-log.md` | Add host config to bootstrap behavior section |
| `man/man7/mac-setup.7` | Add host config reference |

## Out of scope

- Gating existing functions (no current need)
- Value-based config (boolean only)
- Remote config or syncing local files between machines
- Work-profile overlays (separate milestone #12-14)
