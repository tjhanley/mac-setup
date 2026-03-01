#!/usr/bin/env bats

# Verify stow package layout and required files exist.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# --- Stow packages -----------------------------------------------------------

@test "stow/zsh contains .zshrc and .zprofile" {
  [[ -f "$REPO_ROOT/stow/zsh/.zshrc" ]]
  [[ -f "$REPO_ROOT/stow/zsh/.zprofile" ]]
}

@test "stow/git contains .gitconfig and .gitignore" {
  [[ -f "$REPO_ROOT/stow/git/.gitconfig" ]]
  [[ -f "$REPO_ROOT/stow/git/.gitignore" ]]
}

@test "stow/starship contains config" {
  [[ -f "$REPO_ROOT/stow/starship/.config/starship.toml" ]]
}

@test "stow/ghostty contains config" {
  [[ -f "$REPO_ROOT/stow/ghostty/.config/ghostty/config" ]]
}

@test "stow/zellij contains config and layout" {
  [[ -f "$REPO_ROOT/stow/zellij/.config/zellij/config.kdl" ]]
  [[ -f "$REPO_ROOT/stow/zellij/.config/zellij/layouts/default.kdl" ]]
}

@test "stow/mise contains config" {
  [[ -f "$REPO_ROOT/stow/mise/.config/mise/config.toml" ]]
}

@test "stow/zed contains settings" {
  [[ -f "$REPO_ROOT/stow/zed/.config/zed/settings.json" ]]
}

@test "stow/nvim contains local options and plugin configs" {
  [[ -f "$REPO_ROOT/stow/nvim/.config/nvim/lua/config/local.lua" ]]
  [[ -f "$REPO_ROOT/stow/nvim/.config/nvim/lua/plugins/ghostty.lua" ]]
}

@test "stow/obsidian config is tracked in git" {
  # File may be skip-worktree'd locally, so check git index
  cd "$REPO_ROOT"
  git ls-files --error-unmatch stow/obsidian/.config/obsidian/obsidian.json >/dev/null 2>&1
}

@test "stow/amethyst contains config" {
  [[ -f "$REPO_ROOT/stow/amethyst/.config/amethyst/amethyst.yml" ]]
}

@test "stow/yazi theme files are tracked in git" {
  # Files may be skip-worktree'd locally, so check git index
  cd "$REPO_ROOT"
  git ls-files --error-unmatch stow/yazi/.config/yazi/theme.toml >/dev/null 2>&1
  git ls-files --error-unmatch stow/yazi/.config/yazi/Catppuccin-mocha.tmTheme >/dev/null 2>&1
}

@test "stow/bat contains config" {
  [[ -f "$REPO_ROOT/stow/bat/.config/bat/config" ]]
}

@test "stow/lazygit contains config" {
  [[ -f "$REPO_ROOT/stow/lazygit/.config/lazygit/config.yml" ]]
}

@test "stow/ripgrep contains .ripgreprc" {
  [[ -f "$REPO_ROOT/stow/ripgrep/.ripgreprc" ]]
}

# --- Top-level files ----------------------------------------------------------

@test "Brewfile exists" {
  [[ -f "$REPO_ROOT/brew/Brewfile" ]]
}

@test "bootstrap script exists and is executable" {
  [[ -x "$REPO_ROOT/bootstrap/bootstrap-mac.zsh" ]]
}

@test "setup.sh exists and is executable" {
  [[ -x "$REPO_ROOT/setup.sh" ]]
}

# --- Stow package mirrors $HOME structure ------------------------------------

@test "no stow package contains absolute paths" {
  local bad=""
  for pkg in "$REPO_ROOT"/stow/*/; do
    # Only top-level entries should be dotfiles or .config — never /usr, /etc
    for entry in "$pkg"/*; do
      name="$(basename "$entry")"
      if [[ "$name" == /* ]]; then
        bad="$bad $entry"
      fi
    done
  done
  [[ -z "$bad" ]]
}
