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

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if brew bundle check --file="$BREWFILE" "${verbose_arg[@]}"; then
      ok "Brewfile already satisfied"
    else
      warn "Brewfile has missing dependencies (run without --dry-run to install)"
    fi
  else
    brew bundle --file="$BREWFILE" "${verbose_arg[@]}"
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
  move_conflict_target ".config/zellij/themes/catppuccin.kdl"
  move_conflict_target ".config/mise/config.toml"
  move_conflict_target ".config/zed/settings.json"
  move_conflict_target ".config/obsidian/obsidian.json"

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
  if need_cmd tree-sitter; then
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

install_rust() {
  if need_cmd rustup; then
    ok "rustup already installed"
    return
  fi

  if need_cmd rustup-init; then
    log "Installing Rust toolchain via rustup-init"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f rustup-init -y"
    else
      rustup-init -y
      ok "Rust toolchain installed"
    fi
  else
    warn "rustup-init not found; skipping Rust"
  fi
}

post_notes() {
  log "Next manual steps (optional)"
  cat <<'EOF_NOTES'

- Open Ghostty once to grant permissions and confirm settings.
- Open Raycast and Zed if you use them.
- If you want Magnet, install it from the App Store (or add mas later).

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
  install_rust
  post_notes

  ok "Bootstrap finished"
}

main "$@"
