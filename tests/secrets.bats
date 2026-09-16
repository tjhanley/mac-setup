#!/usr/bin/env bats

# Verify refresh-secrets regenerates ~/.secrets correctly: vault lookups, alias
# entries, secure-note extraction, file mode, and failure atomicity.
# The function is extracted from .zshrc and run against a stubbed dcli so the
# tests never touch the real vault or the real ~/.secrets.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  TEST_HOME="$(mktemp -d)"
  mkdir -p "$TEST_HOME/bin"

  # Stub dcli: `dcli read dl://<title>/<field>` returns a canned response per title.
  cat > "$TEST_HOME/bin/dcli" <<'STUB'
#!/bin/sh
case "$2" in
  *plain-item*)         printf 'plain-value' ;;
  *json-password-item*) printf '{"password":"pw-value","note":""}' ;;
  *json-note-item*)     printf '{"note":"note-value"}' ;;
  *broken-item*)        exit 1 ;;
  *)                    printf '' ;;
esac
STUB
  chmod +x "$TEST_HOME/bin/dcli"

  awk '/^function refresh-secrets\(\) \{/,/^\}/' \
    "$REPO_ROOT/stow/zsh/.zshrc" > "$TEST_HOME/fn.zsh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

run_refresh() {
  HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$PATH" \
    zsh -c "source '$TEST_HOME/fn.zsh'; refresh-secrets"
}

# --- Preflight ---------------------------------------------------------------

@test "refresh-secrets fails when ~/.secrets-config is missing" {
  run run_refresh
  [ "$status" -eq 1 ]
  [[ "$output" == *".secrets-config not found"* ]]
}

# --- Vault lookups -----------------------------------------------------------

@test "refresh-secrets writes plain vault values" {
  printf 'PLAIN_KEY=dl://plain-item/password\n' > "$TEST_HOME/.secrets-config"
  run run_refresh
  [ "$status" -eq 0 ]
  grep -q 'export PLAIN_KEY="plain-value"' "$TEST_HOME/.secrets"
}

@test "refresh-secrets extracts the password field from a JSON response" {
  printf 'PW_KEY=dl://json-password-item/password\n' > "$TEST_HOME/.secrets-config"
  run run_refresh
  [ "$status" -eq 0 ]
  grep -q 'export PW_KEY="pw-value"' "$TEST_HOME/.secrets"
}

@test "refresh-secrets falls back to the note field for secure notes" {
  printf 'NOTE_KEY=dl://json-note-item/note\n' > "$TEST_HOME/.secrets-config"
  run run_refresh
  [ "$status" -eq 0 ]
  grep -q 'export NOTE_KEY="note-value"' "$TEST_HOME/.secrets"
}

# --- Alias entries -----------------------------------------------------------

@test "refresh-secrets emits an alias entry verbatim without a vault lookup" {
  printf 'SRC_KEY=dl://plain-item/password\nALIAS_KEY=$SRC_KEY\n' \
    > "$TEST_HOME/.secrets-config"
  run run_refresh
  [ "$status" -eq 0 ]
  grep -q 'export ALIAS_KEY="$SRC_KEY"' "$TEST_HOME/.secrets"
}

@test "an alias resolves to its source value when ~/.secrets is sourced" {
  printf 'SRC_KEY=dl://plain-item/password\nALIAS_KEY=$SRC_KEY\n' \
    > "$TEST_HOME/.secrets-config"
  run_refresh
  run zsh -c "source '$TEST_HOME/.secrets'; printf '%s' \"\$ALIAS_KEY\""
  [ "$output" = "plain-value" ]
}

# --- Safety ------------------------------------------------------------------

@test "refresh-secrets leaves an existing ~/.secrets intact when a lookup fails" {
  printf 'export SENTINEL="keep-me"\n' > "$TEST_HOME/.secrets"
  printf 'BAD_KEY=dl://broken-item/password\n' > "$TEST_HOME/.secrets-config"
  run run_refresh
  [ "$status" -eq 1 ]
  grep -q 'export SENTINEL="keep-me"' "$TEST_HOME/.secrets"
}

@test "regenerated ~/.secrets is not group- or world-readable" {
  printf 'PLAIN_KEY=dl://plain-item/password\n' > "$TEST_HOME/.secrets-config"
  run_refresh
  [ "$(stat -f '%Lp' "$TEST_HOME/.secrets")" = "600" ]
}

# --- Leak guards -------------------------------------------------------------

@test "tracked files contain no Anthropic API keys" {
  cd "$REPO_ROOT"
  ! git grep -I -qE 'sk-ant-[A-Za-z0-9_-]{10}' -- .
}

@test ".secrets-config.example maps vault paths only, never values" {
  ! grep -qE '^[A-Za-z_][A-Za-z0-9_]*=(sk-|ghp_|eyJ)' \
    "$REPO_ROOT/.secrets-config.example"
}
