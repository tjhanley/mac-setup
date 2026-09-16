#!/usr/bin/env bats

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  TEST_HOME="$(mktemp -d)"
  mkdir -p "$TEST_HOME/Workspace/new" "$TEST_HOME/claude-spend-audit"
  awk '/^typeset -gA GH_ACCOUNT_BY_OWNER=/,/^autoload -Uz add-zsh-hook/ {
    if ($0 !~ /^autoload /) print
  }' "$REPO_ROOT/stow/zsh/.zshrc" > "$TEST_HOME/functions.zsh"
  awk '/^claudespend\(\)/,/^}/' "$REPO_ROOT/stow/zsh/.zshrc" >> "$TEST_HOME/functions.zsh"
  cat >> "$TEST_HOME/functions.zsh" <<'STUB'
git() {
  case "$*" in
    "config gh.user") [[ -n $TEST_GH_USER ]] && print -r -- "$TEST_GH_USER" ;;
    "config remote.origin.url") [[ -n $TEST_REMOTE ]] && print -r -- "$TEST_REMOTE" ;;
    *) return 1 ;;
  esac
}
gh() {
  print -r -- "$*" >> "$HOME/gh-calls"
  [[ $4 != missing ]] || return 1
  print -r -- "fixture-$4"
}
STUB
}

teardown() {
  rm -rf "$TEST_HOME"
}

run_helpers() {
  HOME="$TEST_HOME" zsh -f -c 'source "$HOME/functions.zsh"; eval "$1"' -- "$1"
}

@test "GitHub owner parser accepts HTTPS and SSH aliases" {
  run run_helpers '
    _gh_remote_owner https://github.com/sonatus/example.git
    _gh_remote_owner git@github.com-personal:tjhanley/mac-setup.git
    _gh_remote_owner ssh://git@github.com/snt-devx/example.git
  '
  [ "$status" -eq 0 ]
  [ "$output" = $'sonatus\ntjhanley\nsnt-devx' ]
}

@test "GitHub owner parser handles the actual repository remote" {
  export REAL_REMOTE
  REAL_REMOTE="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null)" || skip "no origin remote"
  [[ "$REAL_REMOTE" == *github.com* ]] || skip "origin is not hosted on GitHub"
  run run_helpers '_gh_remote_owner "$REAL_REMOTE"'
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  [[ "$output" != */* ]]
}

@test "GitHub owner parser rejects other hosts" {
  run run_helpers '_gh_remote_owner https://gitlab.com/sonatus/example.git'
  [ "$status" -ne 0 ]
}

@test "explicit GitHub account overrides remote owner and directory" {
  run run_helpers '
    cd "$HOME/Workspace/new"
    TEST_GH_USER=override
    TEST_REMOTE=git@github.com:sonatus/example.git
    _gh_account_for_pwd && print -r -- "$REPLY"
  '
  [ "$status" -eq 0 ]
  [ "$output" = override ]
}

@test "GitHub owner mapping overrides the workspace default" {
  run run_helpers '
    cd "$HOME/Workspace/new"
    TEST_REMOTE=git@github.com-personal:tjhanley/mac-setup.git
    _gh_account_for_pwd && print -r -- "$REPLY"
    TEST_REMOTE=git@github.com:snt-devx/example.git
    _gh_account_for_pwd && print -r -- "$REPLY"
  '
  [ "$status" -eq 0 ]
  [ "$output" = $'tjhanley\ntjhanley-snt' ]
}

@test "directories without a remote use the workspace account" {
  run run_helpers 'cd "$HOME/Workspace/new"; _gh_account_for_pwd && print -r -- "$REPLY"'
  [ "$status" -eq 0 ]
  [ "$output" = tjhanley-snt ]
}

@test "unmapped GitHub owners do not inherit the workspace account" {
  run run_helpers '
    cd "$HOME/Workspace/new"
    TEST_REMOTE=git@github.com:unmapped/example.git
    _gh_account_for_pwd
  '
  [ "$status" -ne 0 ]
}

@test "GitHub tokens are cached within the shell" {
  run run_helpers '_gh_token_for sample; _gh_token_for sample; print -r -- "$REPLY"'
  [ "$status" -eq 0 ]
  [ "$output" = fixture-sample ]
  [ "$(wc -l < "$TEST_HOME/gh-calls" | tr -d ' ')" = 1 ]
}

@test "missing account credentials clear a previous GH_TOKEN" {
  run run_helpers 'TEST_GH_USER=missing; GH_TOKEN=old-value; _gh_set_token; [[ -z ${GH_TOKEN+x} ]]'
  [ "$status" -eq 0 ]
}

@test "claudespend computes the selected period without changing directories" {
  cat > "$TEST_HOME/claude-spend-audit/parse_transcripts.py" <<'PY'
import csv
import datetime

today = datetime.date.today()
with open("turns.csv", "w") as stream:
    writer = csv.writer(stream)
    writer.writerow(["date", "cost_total"])
    writer.writerow([today, 2])
    writer.writerow([today - datetime.timedelta(days=1), 3])
    writer.writerow([today - datetime.timedelta(days=10), 99])
PY
  printf 'pass\n' > "$TEST_HOME/claude-spend-audit/stats.py"
  run run_helpers 'before=$PWD; claudespend 2; [[ $PWD == $before ]]'
  [ "$status" -eq 0 ]
  [[ "$output" == *'CORRECTED run rate: $75.00/30d over 2 days ($2.50/day)'* ]]
}

@test "claudespend stops when transcript parsing fails" {
  printf 'raise SystemExit(1)\n' > "$TEST_HOME/claude-spend-audit/parse_transcripts.py"
  run run_helpers 'claudespend'
  [ "$status" -ne 0 ]
  [[ "$output" != *'CORRECTED run rate'* ]]
}
