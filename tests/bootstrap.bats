#!/usr/bin/env bats

# Test bootstrap functions in dry-run mode.
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
}

teardown() {
  rm -rf "$BACKUP_DIR"
}

# --- Helpers ------------------------------------------------------------------

@test "log() outputs arrow prefix" {
  run_zsh_fn 'log "test message"'
  [[ "$output" == *"==>"* ]]
  [[ "$output" == *"test message"* ]]
}

@test "ok() outputs success text" {
  run_zsh_fn 'ok "success"'
  [[ "$output" == *"success"* ]]
}

@test "warn() outputs warning text" {
  run_zsh_fn 'warn "caution"'
  [[ "$output" == *"caution"* ]]
}

# --- Dry-run ------------------------------------------------------------------

@test "run_cmd prints command in dry-run mode" {
  run_zsh_fn 'run_cmd echo hello'
  [[ "$output" == *"dry-run:"* ]]
  [[ "$output" == *"echo hello"* ]]
}

@test "run_cmd does not execute in dry-run mode" {
  local marker="/tmp/bats-run-cmd-test-$$"
  run_zsh_fn "run_cmd touch '$marker'"
  [[ ! -f "$marker" ]]
}

@test "backup_path prints dry-run message for existing path" {
  local tmpfile="$(mktemp)"
  run_zsh_fn "backup_path '$tmpfile'"
  [[ "$output" == *"dry-run:"* ]]
  [[ "$output" == *"backup"* ]]
  rm -f "$tmpfile"
}

@test "backup_path is silent for missing path" {
  run_zsh_fn "backup_path '/nonexistent/path/$$'"
  [[ -z "$output" ]]
}

@test "move_conflict_target skips symlinks" {
  local tmpdir="$(mktemp -d)"
  ln -s /dev/null "$tmpdir/.testlink"
  run_zsh_fn "HOME='$tmpdir' move_conflict_target '.testlink'"
  [[ -z "$output" ]]
  rm -rf "$tmpdir"
}

@test "move_conflict_target prints dry-run for real files" {
  local tmpdir="$(mktemp -d)"
  echo "test" > "$tmpdir/.testfile"
  run_zsh_fn "HOME='$tmpdir' move_conflict_target '.testfile'"
  [[ "$output" == *"dry-run:"* ]]
  [[ "$output" == *"move conflict"* ]]
  rm -rf "$tmpdir"
}

# --- Function idempotency checks ---------------------------------------------

@test "stow_dotfiles runs in dry-run without error" {
  run_zsh_fn 'stow_dotfiles'
  [[ "$status" -eq 0 ]]
}

@test "ensure_config_dir runs in dry-run without error" {
  run_zsh_fn 'ensure_config_dir'
  [[ "$status" -eq 0 ]]
}

@test "ensure_git_email prints dry-run message when email unset" {
  local tmpdir="$(mktemp -d)"
  run_zsh_fn "HOME='$tmpdir' ensure_git_email"
  [[ "$output" == *"dry-run:"* ]]
  [[ "$output" == *"user.email"* ]]
  rm -rf "$tmpdir"
}
