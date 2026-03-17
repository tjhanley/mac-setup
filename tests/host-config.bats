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
