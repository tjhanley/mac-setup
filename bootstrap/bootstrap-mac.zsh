#!/bin/zsh
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Workspace/mac-setup}"
BREWFILE="$DOTFILES_DIR/brew/Brewfile"
STOW_DIR="$DOTFILES_DIR/stow"
BACKUP_DIR="${BACKUP_DIR:-$HOME/config-backups/dotfiles-$(date +%Y%m%d-%H%M%S)}"
DRY_RUN=0
DEBUG="${DEBUG:-false}"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log() { print -P "\n%F{cyan}==>%f $1"; }
ok()  { print -P "%F{green}✓%f $1"; }
warn(){ print -P "%F{yellow}⚠%f $1"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }
is_debug() { [[ "$DEBUG" == "true" || "$DEBUG" == "1" ]]; }

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f $*"
    return 0
  fi
  "$@"
}

backup_and_remove_path() {
  local p="$1"
  if [[ ! -e "$p" && ! -L "$p" ]]; then
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f move $p -> $BACKUP_DIR/bin-conflicts/"
    return
  fi

  run_cmd mkdir -p "$BACKUP_DIR/bin-conflicts"
  run_cmd sudo mv "$p" "$BACKUP_DIR/bin-conflicts/"
  ok "Moved conflicting path: $p -> $BACKUP_DIR/bin-conflicts/"
}

prepare_brew_binary_conflicts() {
  log "Preparing known Homebrew binary conflicts"

  # Docker Desktop often places its own kubectl symlink here.
  local kubectl_path="/usr/local/bin/kubectl"
  if [[ -L "$kubectl_path" ]]; then
    local kubectl_target
    kubectl_target="$(readlink "$kubectl_path" || true)"
    if [[ "$kubectl_target" == *"/Applications/Docker.app/"* ]]; then
      backup_and_remove_path "$kubectl_path"
    fi
  fi

  # codex cask installs /usr/local/bin/codex; move pre-existing non-cask binaries.
  local codex_path="/usr/local/bin/codex"
  if [[ -e "$codex_path" || -L "$codex_path" ]]; then
    local codex_target=""
    if [[ -L "$codex_path" ]]; then
      codex_target="$(readlink "$codex_path" || true)"
    fi
    if [[ "$codex_target" != *"/Caskroom/codex/"* ]]; then
      backup_and_remove_path "$codex_path"
    fi
  fi
}

backup_path() {
  local p="$1"
  if [[ -e "$p" || -L "$p" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f backup $p -> $BACKUP_DIR/"
    else
      mkdir -p "$BACKUP_DIR"
      cp -a "$p" "$BACKUP_DIR/" 2>/dev/null || true
      ok "Backed up: $p -> $BACKUP_DIR/"
    fi
  fi
}

resolve_existing_path() {
  local p="$1"
  if [[ -e "$p" || -L "$p" ]]; then
    (
      cd "$(dirname "$p")" 2>/dev/null || exit 1
      print -- "$(pwd -P)/$(basename "$p")"
    )
  fi
}

move_conflict_target() {
  local rel="$1"
  local target="$HOME/$rel"
  local dest="$BACKUP_DIR/$rel"
  local resolved_target=""
  local resolved_dotfiles=""

  if [[ -L "$target" || ! -e "$target" ]]; then
    return
  fi

  resolved_target="$(resolve_existing_path "$target" || true)"
  resolved_dotfiles="$(cd "$DOTFILES_DIR" 2>/dev/null && pwd -P || true)"
  if [[ -n "$resolved_target" && -n "$resolved_dotfiles" ]]; then
    if [[ "$resolved_target" == "$resolved_dotfiles" || "$resolved_target" == "$resolved_dotfiles/"* ]]; then
      warn "Skipping conflict move for repo-managed path: $target"
      return
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f move conflict $target -> $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  ok "Moved conflict: $target -> $dest"
}

link_managed_file() {
  local source="$1"
  local target="$2"
  local label="$3"
  local resolved_source=""
  local resolved_target=""

  if [[ ! -e "$source" ]]; then
    warn "$label source missing: $source"
    return
  fi

  resolved_source="$(resolve_existing_path "$source" || true)"
  resolved_target="$(resolve_existing_path "$target" || true)"
  if [[ -n "$resolved_source" && -n "$resolved_target" && "$resolved_source" == "$resolved_target" ]]; then
    ok "$label already linked"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f link $target -> $source"
    return
  fi

  run_cmd mkdir -p "$(dirname "$target")"

  if [[ -d "$target" && ! -L "$target" ]]; then
    warn "$label target is a directory; skipping: $target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
    run_cmd rm -f "$target"
  fi

  run_cmd ln -s "$source" "$target"
  ok "$label linked: $target -> $source"
}

ensure_homebrew() {
  if need_cmd brew; then
    ok "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f install Homebrew"
    return
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  ok "Homebrew installed"
}

refresh_homebrew() {
  log "Refreshing Homebrew"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f brew update"
    print -P "%F{yellow}dry-run:%f brew upgrade"
    return
  fi

  brew update
  brew upgrade
  ok "Homebrew updated"
}

ensure_gcloud_python() {
  local mise_python=""

  if need_cmd mise; then
    mise_python="$(mise which python 2>/dev/null || true)"
    if [[ -n "$mise_python" && -x "$mise_python" ]]; then
      export CLOUDSDK_PYTHON="$mise_python"
      ok "Using CLOUDSDK_PYTHON from mise: $CLOUDSDK_PYTHON"
      return
    fi
  fi
  warn "mise Python not found for gcloud"
  warn "Install with: mise use -g python@3.12 && mise install"
}

install_brew_bundle() {
  log "Installing packages/apps from Brewfile"
  if [[ ! -f "$BREWFILE" ]]; then
    warn "Missing Brewfile at: $BREWFILE"
    return
  fi

  local -a verbose_arg=()
  if is_debug; then
    verbose_arg=(--verbose)
  fi

  warn "gcloud-cli is installed in a later step after mise python is available"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if HOMEBREW_BUNDLE_CASK_SKIP="gcloud-cli" brew bundle check --file="$BREWFILE" "${verbose_arg[@]}"; then
      ok "Brewfile already satisfied"
    else
      warn "Brewfile has missing dependencies (run without --dry-run to install)"
    fi
  else
    HOMEBREW_BUNDLE_CASK_SKIP="gcloud-cli" brew bundle --file="$BREWFILE" "${verbose_arg[@]}"
    ok "Brew bundle complete"
  fi
}

ensure_config_dir() {
  log "Ensuring ~/.config exists"
  run_cmd mkdir -p "$HOME/.config"
  ok "~/.config ready"
}

ensure_local_env_file() {
  local env_example="$DOTFILES_DIR/.env.example"
  local env_file="$DOTFILES_DIR/.env"

  log "Ensuring local .env file exists"
  if [[ ! -f "$env_example" ]]; then
    warn "Missing template file: $env_example"
    return
  fi

  if [[ -f "$env_file" ]]; then
    ok ".env already exists"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f cp $env_example $env_file"
    return
  fi

  cp "$env_example" "$env_file"
  ok "Created .env from .env.example"
}

stow_dotfiles() {
  log "Backing up pre-existing configs"
  backup_path "$HOME/.zshrc"
  backup_path "$HOME/.zprofile"
  backup_path "$HOME/.gitconfig"
  backup_path "$HOME/.config/nvim"
  backup_path "$HOME/.config/starship.toml"
  backup_path "$HOME/.config/ghostty"
  backup_path "$HOME/.config/zellij"
  backup_path "$HOME/.config/mise"
  backup_path "$HOME/.config/zed"
  backup_path "$HOME/.config/obsidian"
  backup_path "$HOME/.config/yazi"
  backup_path "$HOME/.config/raycast"
  backup_path "$HOME/Library/Application Support/Zed/settings.json"
  backup_path "$HOME/Library/Application Support/obsidian/obsidian.json"

  log "Moving stow conflicts into backup"
  move_conflict_target ".zshrc"
  move_conflict_target ".zprofile"
  move_conflict_target ".gitconfig"
  move_conflict_target ".config/starship.toml"
  move_conflict_target ".config/ghostty/config"
  move_conflict_target ".config/zellij/config.kdl"
  move_conflict_target ".config/mise/config.toml"
  move_conflict_target ".config/zed/settings.json"
  move_conflict_target ".config/obsidian/obsidian.json"
  move_conflict_target ".config/yazi/theme.toml"
  move_conflict_target ".config/yazi/Catppuccin-mocha.tmTheme"

  log "Stowing dotfiles"
  if [[ ! -d "$STOW_DIR" ]]; then
    warn "Missing stow dir at: $STOW_DIR"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    (cd "$STOW_DIR" && stow --target="$HOME" --restow -n */)
  else
    (cd "$STOW_DIR" && stow --target="$HOME" --restow */)
  fi

  ok "Dotfiles stowed"
}

configure_macos_app_links() {
  if [[ "$OSTYPE" != darwin* ]]; then
    return
  fi

  log "Linking macOS app configs to stow-managed files"
  link_managed_file \
    "$HOME/.config/zed/settings.json" \
    "$HOME/Library/Application Support/Zed/settings.json" \
    "Zed settings"
  link_managed_file \
    "$HOME/.config/obsidian/obsidian.json" \
    "$HOME/Library/Application Support/obsidian/obsidian.json" \
    "Obsidian settings"
}

install_lazyvim() {
  log "Installing LazyVim (if not already installed)"

  local nvim_dir="$HOME/.config/nvim"
  if [[ -d "$nvim_dir/.git" ]]; then
    ok "Neovim config already looks like a git repo: $nvim_dir"
    return
  fi

  if [[ -e "$nvim_dir" && ! -L "$nvim_dir" ]]; then
    warn "$nvim_dir exists and is not a symlink. Leaving it alone."
    warn "If you want LazyVim, move it aside and re-run."
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f git clone LazyVim starter -> $nvim_dir"
  else
    git clone https://github.com/LazyVim/starter "$nvim_dir"
    rm -rf "$nvim_dir/.git"
    ok "LazyVim starter installed at ~/.config/nvim"
  fi

  warn "Open nvim once to let plugins install: nvim"
}

ensure_treesitter_parsers() {
  log "Checking Tree-sitter CLI"
  local tree_sitter_bin=""
  if need_cmd tree-sitter; then
    tree_sitter_bin="$(command -v tree-sitter)"
  elif [[ -x /opt/homebrew/opt/tree-sitter-cli/bin/tree-sitter ]]; then
    tree_sitter_bin="/opt/homebrew/opt/tree-sitter-cli/bin/tree-sitter"
  elif [[ -x /usr/local/opt/tree-sitter-cli/bin/tree-sitter ]]; then
    tree_sitter_bin="/usr/local/opt/tree-sitter-cli/bin/tree-sitter"
  fi

  if [[ -n "$tree_sitter_bin" ]]; then
    ok "Tree-sitter CLI installed"
  else
    warn "tree-sitter CLI not found; ensure brew bundle completed successfully"
  fi

  warn "Skipping headless Neovim parser updates to avoid mason async-install shutdown errors"
  warn "Run ':Lazy sync' and ':TSUpdateSync' inside Neovim when convenient"
}

install_mise_tools() {
  if ! need_cmd mise; then
    warn "mise not found in PATH; skipping tool installs"
    return
  fi

  log "Installing runtimes via mise"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f mise install"
  else
    mise install
    ok "mise install complete"
  fi
}

install_gcloud_cli() {
  log "Installing gcloud-cli (after mise python is available)"
  ensure_gcloud_python

  if [[ -z "${CLOUDSDK_PYTHON:-}" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      warn "dry-run: gcloud-cli would be skipped because CLOUDSDK_PYTHON is not set"
      warn "dry-run: run 'mise use -g python@3.12 && mise install' first"
      return
    fi
    warn "CLOUDSDK_PYTHON is not set; cannot install gcloud-cli"
    warn "Run: mise use -g python@3.12 && mise install"
    return 1
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f CLOUDSDK_PYTHON=$CLOUDSDK_PYTHON brew install --cask gcloud-cli"
    if brew list --cask gcloud-cli >/dev/null 2>&1; then
      ok "dry-run: gcloud-cli already installed"
    else
      warn "dry-run: gcloud-cli not currently installed"
    fi
    return
  fi

  if CLOUDSDK_PYTHON="$CLOUDSDK_PYTHON" brew list --cask gcloud-cli >/dev/null 2>&1; then
    ok "gcloud-cli already installed"
    return
  fi

  if CLOUDSDK_PYTHON="$CLOUDSDK_PYTHON" brew install --cask gcloud-cli; then
    ok "gcloud-cli installed"
  else
    warn "gcloud-cli install failed with CLOUDSDK_PYTHON=$CLOUDSDK_PYTHON"
    return 1
  fi
}

install_app_store_apps() {
  local copyless2_id="993841014"
  local magnet_id="441258766"
  local install_output=""

  if [[ "$OSTYPE" != darwin* ]]; then
    return
  fi

  if ! need_cmd mas; then
    warn "mas not found; skipping App Store app installs"
    return
  fi

  log "Installing App Store apps"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f mas install $copyless2_id # CopyLess 2"
    print -P "%F{yellow}dry-run:%f mas install $magnet_id # Magnet"
    return
  fi

  if mas list | awk '{print $1}' | grep -q "^${copyless2_id}$"; then
    ok "CopyLess 2 already installed"
  else
    install_output="$(mas install "$copyless2_id" 2>&1)" || true
    if [[ "$install_output" == *"Not signed in"* || "$install_output" == *"not signed in"* || "$install_output" == *"This Apple ID has not yet been used with the App Store"* ]]; then
      warn "App Store authentication required for mas install."
      warn "Please sign in using the App Store app, then press Enter to retry."
      warn "Tip: run 'open -a \"App Store\"' if needed."
      read -r
      mas install "$copyless2_id" && ok "Installed CopyLess 2"
    elif [[ "$install_output" == *"already installed"* ]]; then
      ok "CopyLess 2 already installed"
    elif [[ -n "$install_output" ]]; then
      print -- "$install_output"
      warn "Failed to install CopyLess 2"
    fi
  fi

  if mas list | awk '{print $1}' | grep -q "^${magnet_id}$"; then
    ok "Magnet already installed"
  else
    install_output="$(mas install "$magnet_id" 2>&1)" || true
    if [[ "$install_output" == *"Not signed in"* || "$install_output" == *"not signed in"* || "$install_output" == *"This Apple ID has not yet been used with the App Store"* ]]; then
      warn "App Store authentication required for mas install."
      warn "Please sign in using the App Store app, then press Enter to retry."
      warn "Tip: run 'open -a \"App Store\"' if needed."
      read -r
      mas install "$magnet_id" && ok "Installed Magnet"
    elif [[ "$install_output" == *"already installed"* ]]; then
      ok "Magnet already installed"
    elif [[ -n "$install_output" ]]; then
      print -- "$install_output"
      warn "Failed to install Magnet"
    fi
  fi
}

install_rust() {
  if need_cmd rustup; then
    if need_cmd cargo || [[ -x "$HOME/.cargo/bin/cargo" ]]; then
      export PATH="$HOME/.cargo/bin:$PATH"
      ok "rustup/cargo already installed"
      return
    fi
    log "Initializing Rust stable toolchain via rustup"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f rustup default stable"
    else
      rustup default stable
      export PATH="$HOME/.cargo/bin:$PATH"
      ok "Rust stable toolchain initialized"
    fi
    return
  fi

  if need_cmd rustup-init; then
    log "Installing Rust toolchain via rustup-init"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f rustup-init -y"
    else
      rustup-init -y
      export PATH="$HOME/.cargo/bin:$PATH"
      ok "Rust toolchain installed"
    fi
  else
    warn "rustup-init not found; skipping Rust"
  fi
}

install_spotify_tui() {
  log "Installing spotify_player TUI (with image feature)"

  local cargo_bin=""
  local cargo_binstall_bin=""
  local rustc_bin=""
  local toolchain_bin=""
  if need_cmd cargo; then
    cargo_bin="$(command -v cargo)"
  elif [[ -x "$HOME/.cargo/bin/cargo" ]]; then
    cargo_bin="$HOME/.cargo/bin/cargo"
  elif need_cmd rustup; then
    cargo_bin="$(rustup which cargo 2>/dev/null || true)"
    rustc_bin="$(rustup which rustc 2>/dev/null || true)"
  fi

  if [[ -z "$cargo_bin" || ! -x "$cargo_bin" ]]; then
    warn "cargo not found; skipping spotify_player install"
    return
  fi

  toolchain_bin="$(dirname "$cargo_bin")"
  if [[ -n "$rustc_bin" && -x "$rustc_bin" ]]; then
    toolchain_bin="$(dirname "$rustc_bin")"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if need_cmd cargo-binstall; then
      cargo_binstall_bin="$(command -v cargo-binstall)"
      print -P "%F{yellow}dry-run:%f PATH=$toolchain_bin:$PATH $cargo_binstall_bin --no-confirm spotify_player"
    else
      print -P "%F{yellow}dry-run:%f PATH=$toolchain_bin:$PATH $cargo_bin install --locked spotify_player --features image"
    fi
    return
  fi

  if PATH="$toolchain_bin:$PATH" "$cargo_bin" install --list | grep -q '^spotify_player v'; then
    ok "spotify_player already installed"
    return
  fi

  if need_cmd cargo-binstall; then
    cargo_binstall_bin="$(command -v cargo-binstall)"
    if PATH="$toolchain_bin:$PATH" "$cargo_binstall_bin" --no-confirm spotify_player; then
      ok "spotify_player installed (prebuilt via cargo-binstall)"
      return
    fi
    warn "cargo-binstall failed; falling back to cargo source build"
  fi

  if PATH="$toolchain_bin:$PATH" "$cargo_bin" install --locked spotify_player --features image; then
    ok "spotify_player installed"
  else
    warn "spotify_player install failed"
  fi
}

post_notes() {
  log "Next manual steps (optional)"
  cat <<'EOF_NOTES'

- Open Ghostty once to grant permissions and confirm settings.
- Open Raycast and Zed if you use them.
- Open Spotify and complete login before using spotify_player.

Tip:
- Re-run this script anytime after changes; it's safe and idempotent.
- Your backups are in ~/config-backups/ (timestamped).

EOF_NOTES
}

main() {
  log "Bootstrap starting"
  ok "Repo: $DOTFILES_DIR"

  ensure_homebrew
  refresh_homebrew
  ensure_config_dir
  ensure_local_env_file
  prepare_brew_binary_conflicts
  install_brew_bundle

  if ! need_cmd stow; then
    log "Installing stow"
    brew install stow
  fi

  stow_dotfiles
  configure_macos_app_links
  install_lazyvim
  ensure_treesitter_parsers
  install_mise_tools
  install_gcloud_cli
  install_app_store_apps
  install_rust
  install_spotify_tui
  post_notes

  ok "Bootstrap finished"
}

main "$@"
