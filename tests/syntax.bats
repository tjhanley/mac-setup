#!/usr/bin/env bats

# Verify config files are syntactically valid.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# --- Shell syntax -------------------------------------------------------------

@test "bootstrap script has valid zsh syntax" {
  zsh -n "$REPO_ROOT/bootstrap/bootstrap-mac.zsh"
}

@test ".zshrc has valid zsh syntax" {
  zsh -n "$REPO_ROOT/stow/zsh/.zshrc"
}

@test ".zprofile has valid zsh syntax" {
  zsh -n "$REPO_ROOT/stow/zsh/.zprofile"
}

# --- Git config ---------------------------------------------------------------

@test ".gitconfig parses without errors" {
  git config --file "$REPO_ROOT/stow/git/.gitconfig" --list >/dev/null
}

@test ".gitconfig sets core.pager to delta" {
  local pager
  pager="$(git config --file "$REPO_ROOT/stow/git/.gitconfig" core.pager)"
  [[ "$pager" == "delta" ]]
}

@test ".gitconfig sets core.excludesfile" {
  local ef
  ef="$(git config --file "$REPO_ROOT/stow/git/.gitconfig" core.excludesfile)"
  [[ "$ef" == "~/.gitignore" ]]
}

@test ".gitconfig sets init.defaultBranch to main" {
  local branch
  branch="$(git config --file "$REPO_ROOT/stow/git/.gitconfig" init.defaultBranch)"
  [[ "$branch" == "main" ]]
}

@test ".gitconfig includes ~/.gitconfig.local" {
  local inc
  inc="$(git config --file "$REPO_ROOT/stow/git/.gitconfig" include.path)"
  [[ "$inc" == "~/.gitconfig.local" ]]
}

# --- Global gitignore ---------------------------------------------------------

@test ".gitignore contains .DS_Store" {
  grep -q '\.DS_Store' "$REPO_ROOT/stow/git/.gitignore"
}

@test ".gitignore contains .env" {
  grep -q '^\.env$' "$REPO_ROOT/stow/git/.gitignore"
}

# --- Brewfile -----------------------------------------------------------------

@test "Brewfile contains no syntax errors (valid brew lines)" {
  # Every non-blank, non-comment line should start with brew, cask, tap, or mas
  local bad
  bad="$(grep -vE '^\s*$|^\s*#|^(brew|cask|tap|mas) ' "$REPO_ROOT/brew/Brewfile" || true)"
  [[ -z "$bad" ]]
}

@test "Brewfile includes git-delta" {
  grep -q 'brew "git-delta"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes git-lfs" {
  grep -q 'brew "git-lfs"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes gh" {
  grep -q 'brew "gh"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes bats-core" {
  grep -q 'brew "bats-core"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes koekeishiya/formulae tap" {
  grep -q 'tap "koekeishiya/formulae"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes skhd" {
  grep -q 'brew "koekeishiya/formulae/skhd"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes karabiner-elements" {
  grep -q 'cask "karabiner-elements"' "$REPO_ROOT/brew/Brewfile"
}

# --- JSON configs -------------------------------------------------------------

@test "zed settings.json is valid JSON" {
  python3 -m json.tool "$REPO_ROOT/stow/zed/.config/zed/settings.json" >/dev/null
}

@test "obsidian.json is valid JSON" {
  local f="$REPO_ROOT/stow/obsidian/.config/obsidian/obsidian.json"
  # File may be skip-worktree'd locally; validate only if present
  if [[ -f "$f" ]]; then
    python3 -m json.tool "$f" >/dev/null
  else
    skip "obsidian.json not in working tree (skip-worktree)"
  fi
}

# --- bat config ---------------------------------------------------------------

@test "bat config sets Catppuccin Mocha theme" {
  grep -q 'Catppuccin Mocha' "$REPO_ROOT/stow/bat/.config/bat/config"
}

# --- ripgrep config -----------------------------------------------------------

@test "ripgreprc enables smart-case" {
  grep -q '\-\-smart-case' "$REPO_ROOT/stow/ripgrep/.ripgreprc"
}

# --- mise config --------------------------------------------------------------

@test "mise config defines node runtime" {
  grep -q 'node' "$REPO_ROOT/stow/mise/.config/mise/config.toml"
}

@test "mise config defines python runtime" {
  grep -q 'python' "$REPO_ROOT/stow/mise/.config/mise/config.toml"
}

@test "hyper.json is valid JSON" {
  python3 -m json.tool \
    "$REPO_ROOT/stow/karabiner/.config/karabiner/assets/complex_modifications/hyper.json" \
    >/dev/null
}
