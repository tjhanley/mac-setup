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

ensure_xcode_clt() {
  log "Ensuring Xcode Command Line Tools"

  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode CLT already installed"
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f xcode-select --install"
    else
      xcode-select --install
      warn "Waiting for Xcode CLT installer — press Enter when done"
      read -r
    fi
  fi

  ok "Xcode CLT ready"
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
  warn "docker-desktop is installed separately to avoid brew bundle conflicts"

  local skip_casks="gcloud-cli docker-desktop"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if HOMEBREW_BUNDLE_CASK_SKIP="$skip_casks" brew bundle check --file="$BREWFILE" "${verbose_arg[@]}"; then
      ok "Brewfile already satisfied"
    else
      warn "Brewfile has missing dependencies (run without --dry-run to install)"
    fi
  else
    HOMEBREW_BUNDLE_CASK_SKIP="$skip_casks" brew bundle --file="$BREWFILE" "${verbose_arg[@]}"
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
  backup_path "$HOME/.gitignore"
  backup_path "$HOME/.ssh/config"
  backup_path "$HOME/.ripgreprc"
  backup_path "$HOME/.config/bat"
  backup_path "$HOME/.config/lazygit"
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
  backup_path "$HOME/Library/Application Support/Zed/keymap.json"
  backup_path "$HOME/Library/Application Support/obsidian/obsidian.json"

  log "Moving stow conflicts into backup"
  move_conflict_target ".zshrc"
  move_conflict_target ".zprofile"
  move_conflict_target ".gitconfig"
  move_conflict_target ".gitignore"
  move_conflict_target ".ssh/config"
  move_conflict_target ".ripgreprc"
  move_conflict_target ".config/bat/config"
  move_conflict_target ".config/lazygit/config.yml"
  move_conflict_target ".config/starship.toml"
  move_conflict_target ".config/ghostty/config"
  move_conflict_target ".config/zellij/config.kdl"
  move_conflict_target ".config/mise/config.toml"
  move_conflict_target ".config/zed/settings.json"
  move_conflict_target ".config/zed/keymap.json"
  move_conflict_target ".config/obsidian/obsidian.json"
  move_conflict_target ".config/yazi/theme.toml"
  move_conflict_target ".config/yazi/Catppuccin-mocha.tmTheme"

  log "Stowing dotfiles"
  if [[ ! -d "$STOW_DIR" ]]; then
    warn "Missing stow dir at: $STOW_DIR"
    return
  fi

  # nvim is stowed separately after LazyVim install (see stow_nvim_plugins)
  local -a stow_args=(--target="$HOME" --restow)
  [[ "$DRY_RUN" -eq 1 ]] && stow_args+=(-n)

  (cd "$STOW_DIR" && for pkg in */; do
    [[ "$pkg" == "nvim/" ]] && continue
    stow "${stow_args[@]}" "$pkg" || true
  done)

  ok "Dotfiles stowed"
}

configure_claude_settings() {
  log "Configuring Claude Code settings"

  local settings="$HOME/.claude/settings.json"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f merge statusLine into $settings"
    return
  fi

  mkdir -p "$HOME/.claude"
  [[ -f "$settings" ]] || echo '{}' > "$settings"

  local tmp
  tmp=$(mktemp)
  jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' "$settings" > "$tmp" \
    && mv "$tmp" "$settings"

  ok "Claude Code statusLine configured"
}

stow_nvim_plugins() {
  log "Stowing Neovim plugin configs"

  if [[ ! -d "$STOW_DIR/nvim" ]]; then
    warn "No nvim stow package found; skipping"
    return
  fi

  # Move known file-level conflicts into backup before stowing.
  move_conflict_target ".config/nvim/lua/config/keymaps.lua"
  move_conflict_target ".config/nvim/lua/plugins/ghostty.lua"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if ! (cd "$STOW_DIR" && stow --target="$HOME" --restow -n nvim); then
      warn "Neovim stow check found unresolved conflicts"
      warn "Review ~/.config/nvim and re-run after resolving conflicts"
      return
    fi
  else
    if ! (cd "$STOW_DIR" && stow --target="$HOME" --restow nvim); then
      warn "Neovim plugin stow failed due to unresolved conflicts"
      warn "Review ~/.config/nvim and re-run after resolving conflicts"
      return
    fi
  fi

  ok "Neovim plugins stowed"
}

ensure_lazyvim_local_options_hook() {
  log "Ensuring LazyVim local options hook"

  local options_file="$HOME/.config/nvim/lua/config/options.lua"
  local hook='pcall(require, "config.local")'

  if [[ ! -f "$options_file" ]]; then
    warn "LazyVim options file not found; skipping local options hook: $options_file"
    return
  fi

  if grep -Fq "$hook" "$options_file"; then
    ok "LazyVim local options hook already configured"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f append local options hook to $options_file"
    return
  fi

  cat >> "$options_file" <<'EOF_NVIM_LOCAL_OPTIONS'

-- Load local/repo-managed options if present.
pcall(require, "config.local")
EOF_NVIM_LOCAL_OPTIONS

  ok "Added LazyVim local options hook"
}

ensure_lazyvim_extras() {
  local lazyvim_json="$HOME/.config/nvim/lazyvim.json"
  if [[ ! -f "$lazyvim_json" ]]; then
    return
  fi

  log "Ensuring LazyVim extras"

  local -a desired_extras=(
    "lazyvim.plugins.extras.ai.claudecode"
  )

  local changed=0
  for extra in "${desired_extras[@]}"; do
    if ! grep -q "\"$extra\"" "$lazyvim_json"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        print -P "%F{yellow}dry-run:%f add $extra to lazyvim.json"
      else
        # Insert after the opening of the extras array
        sed -i '' "s|\"extras\": \[|\"extras\": [\n    \"$extra\",|" "$lazyvim_json"
        changed=1
      fi
    fi
  done

  if [[ "$changed" -eq 1 ]]; then
    ok "LazyVim extras updated"
  else
    ok "LazyVim extras already configured"
  fi
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
    "$HOME/.config/zed/keymap.json" \
    "$HOME/Library/Application Support/Zed/keymap.json" \
    "Zed keymap"
  # Seed Obsidian config if it doesn't exist yet (basalt-tui needs it)
  local obsidian_cfg="$HOME/.config/obsidian/obsidian.json"
  if [[ ! -f "$obsidian_cfg" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f seed $obsidian_cfg"
    else
      mkdir -p "$(dirname "$obsidian_cfg")"
      print '{}' > "$obsidian_cfg"
      ok "Seeded Obsidian config: $obsidian_cfg"
    fi
  fi
  link_managed_file \
    "$obsidian_cfg" \
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

  local mise_config="$HOME/.config/mise/config.toml"
  local tools_block=""
  local line=""
  local tool=""
  local version=""
  local -a tool_specs=()

  if [[ ! -f "$mise_config" ]]; then
    warn "mise config not found at $mise_config; skipping tool installs"
    return
  fi

  tools_block="$(mise config get -f "$mise_config" tools 2>/dev/null || true)"
  if [[ -z "$tools_block" ]]; then
    warn "No [tools] entries found in $mise_config; skipping tool installs"
    return
  fi

  while IFS= read -r line; do
    [[ "$line" == *"="* ]] || continue
    tool="${line%%=*}"
    version="${line#*=}"
    tool="${tool//[[:space:]]/}"
    version="${version//\"/}"
    version="${version//[[:space:]]/}"

    if [[ -n "$tool" && -n "$version" ]]; then
      tool_specs+=("${tool}@${version}")
    fi
  done <<< "$tools_block"

  if [[ "${#tool_specs[@]}" -eq 0 ]]; then
    warn "Unable to parse runtime tools from $mise_config; skipping tool installs"
    return
  fi

  log "Installing runtimes via mise (stow-managed config only)"
  local http_timeout="${MISE_HTTP_TIMEOUT:-120}"
  local fetch_timeout="${MISE_FETCH_REMOTE_VERSIONS_TIMEOUT:-60}"
  local retry_fetch_timeout="${MISE_FETCH_REMOTE_VERSIONS_TIMEOUT_RETRY:-120}"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f MISE_HTTP_TIMEOUT=$http_timeout MISE_FETCH_REMOTE_VERSIONS_TIMEOUT=$fetch_timeout mise install ${tool_specs[*]}"
  else
    if MISE_HTTP_TIMEOUT="$http_timeout" MISE_FETCH_REMOTE_VERSIONS_TIMEOUT="$fetch_timeout" mise install "${tool_specs[@]}"; then
      ok "mise install complete"
      return
    fi

    warn "mise install failed; retrying once with extended remote fetch timeout"
    if MISE_HTTP_TIMEOUT="$http_timeout" MISE_FETCH_REMOTE_VERSIONS_TIMEOUT="$retry_fetch_timeout" mise install "${tool_specs[@]}"; then
      ok "mise install complete (after retry)"
    else
      warn "mise install failed after retry"
      return 1
    fi
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

install_cargo_tools() {
  log "Installing Cargo tools"

  local -a cargo_tools=(basalt-tui)

  for tool in "${cargo_tools[@]}"; do
    local bin_name="${tool%-*}"
    [[ "$tool" == "basalt-tui" ]] && bin_name="basalt"

    if need_cmd "$bin_name"; then
      ok "$bin_name already installed"
      continue
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f cargo binstall -y $tool"
      continue
    fi

    if need_cmd cargo-binstall; then
      run_cmd cargo binstall -y "$tool" && ok "Installed $tool via cargo-binstall"
    elif need_cmd cargo; then
      run_cmd cargo install "$tool" && ok "Installed $tool via cargo install"
    else
      warn "cargo not found; skipping $tool"
    fi
  done
}

configure_keyboard_repeat() {
  if [[ "$OSTYPE" != darwin* ]]; then
    return
  fi

  log "Configuring keyboard repeat speed"

  local desired_initial="15"
  local desired_repeat="2"
  local desired_press_hold="0"

  local current_initial=""
  local current_repeat=""
  local current_press_hold=""

  current_initial="$(defaults read -g InitialKeyRepeat 2>/dev/null || true)"
  current_repeat="$(defaults read -g KeyRepeat 2>/dev/null || true)"
  current_press_hold="$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || true)"

  if [[ "$current_initial" == "$desired_initial" \
    && "$current_repeat" == "$desired_repeat" \
    && "$current_press_hold" == "$desired_press_hold" ]]; then
    ok "Keyboard repeat already configured"
    return
  fi

  run_cmd defaults write -g InitialKeyRepeat -int "$desired_initial"
  run_cmd defaults write -g KeyRepeat -int "$desired_repeat"
  run_cmd defaults write -g ApplePressAndHoldEnabled -bool false

  ok "Keyboard repeat configured (InitialKeyRepeat=$desired_initial, KeyRepeat=$desired_repeat)"
  warn "Reopen terminal apps to pick up keyboard repeat changes"
}

install_ghostty_shaders() {
  log "Installing Ghostty shaders"

  local shaders_dir="$HOME/.local/share/ghostty/shaders"
  local legacy_dir="$HOME/.config/ghostty/shaders"
  local resolved_legacy=""
  local resolved_dotfiles=""

  if [[ -d "$shaders_dir" ]]; then
    ok "Ghostty shaders already present"
    return
  fi

  if [[ -d "$legacy_dir" ]]; then
    resolved_legacy="$(resolve_existing_path "$legacy_dir" || true)"
    resolved_dotfiles="$(cd "$DOTFILES_DIR" 2>/dev/null && pwd -P || true)"

    if [[ -n "$resolved_legacy" && -n "$resolved_dotfiles" && "$resolved_legacy" == "$resolved_dotfiles/"* ]]; then
      warn "Found legacy Ghostty shaders under repo-managed path: $legacy_dir"
      warn "Skipping migration from repo path; cloning to $shaders_dir instead"
    else
      if [[ "$DRY_RUN" -eq 1 ]]; then
        print -P "%F{yellow}dry-run:%f move $legacy_dir -> $shaders_dir"
      else
        run_cmd mkdir -p "$(dirname "$shaders_dir")"
        run_cmd mv "$legacy_dir" "$shaders_dir"
        ok "Migrated Ghostty shaders to $shaders_dir"
      fi
      return
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f git clone hackr-sh/ghostty-shaders -> $shaders_dir"
    return
  fi

  run_cmd mkdir -p "$(dirname "$shaders_dir")"
  if git clone https://github.com/hackr-sh/ghostty-shaders.git "$shaders_dir"; then
    ok "Ghostty shaders installed at $shaders_dir"
  else
    warn "Failed to clone ghostty-shaders"
  fi
}

install_zjstatus() {
  log "Installing zjstatus (Zellij status bar plugin)"

  local plugins_dir="$HOME/.config/zellij/plugins"
  local wasm_path="$plugins_dir/zjstatus.wasm"

  if [[ -f "$wasm_path" ]]; then
    ok "zjstatus already installed"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f download zjstatus.wasm -> $wasm_path"
    return
  fi

  run_cmd mkdir -p "$plugins_dir"
  if curl -fsSL -o "$wasm_path" \
    "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"; then
    ok "zjstatus installed at $wasm_path"
  else
    warn "Failed to download zjstatus.wasm"
  fi
}

install_docker_desktop() {
  log "Installing Docker Desktop"

  if brew list --cask docker-desktop >/dev/null 2>&1; then
    ok "Docker Desktop already installed"
    return
  fi

  # Docker cask links docker-compose into /usr/local/cli-plugins
  if [[ ! -d /usr/local/cli-plugins ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f sudo mkdir -p /usr/local/cli-plugins"
    else
      run_cmd sudo mkdir -p /usr/local/cli-plugins
    fi
  fi

  # Remove stale Docker binaries from previous installs that block cask linking
  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f clean stale Docker binaries in /usr/local/bin"
  else
    sudo find /usr/local/bin -maxdepth 1 -name '*docker*' ! -type d -delete 2>/dev/null || true
    sudo rm -f /usr/local/bin/hub-tool /usr/local/bin/kubectl.docker 2>/dev/null || true
    # Stale completion symlinks from previous Docker installs
    rm -f /opt/homebrew/etc/bash_completion.d/docker-compose 2>/dev/null || true
    rm -f /opt/homebrew/etc/bash_completion.d/docker 2>/dev/null || true
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f brew install --cask docker-desktop"
    return
  fi

  if brew install --cask docker-desktop; then
    ok "Docker Desktop installed"
  else
    warn "Docker Desktop install failed"
    warn "Install manually: brew install --cask docker-desktop"
  fi
}

ensure_git_identity() {
  log "Checking git user identity"

  local local_config="$HOME/.gitconfig.local"
  local current_name=""
  local current_email=""
  current_name="$(git config user.name 2>/dev/null || true)"
  current_email="$(git config user.email 2>/dev/null || true)"

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    ok "git identity already set: $current_name <$current_email>"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    [[ -z "$current_name" ]]  && print -P "%F{yellow}dry-run:%f would prompt for git user.name"
    [[ -z "$current_email" ]] && print -P "%F{yellow}dry-run:%f would prompt for git user.email"
    return
  fi

  if [[ -z "$current_name" ]]; then
    print -P "%F{cyan}No git user.name configured.%f"
    print -n "Enter your git name (or press Enter to skip): "
    local name=""
    read -r name
    if [[ -n "$name" ]]; then
      if [[ ! -f "$local_config" ]]; then
        printf '[user]\n  name = %s\n' "$name" > "$local_config"
      else
        git config --file "$local_config" user.name "$name"
      fi
      ok "git user.name set to $name (in ~/.gitconfig.local)"
    else
      warn "Skipped git user.name — set it later: git config --global user.name 'Your Name'"
    fi
  fi

  if [[ -z "$current_email" ]]; then
    print -P "%F{cyan}No git user.email configured.%f"
    print -n "Enter your git email (or press Enter to skip): "
    local email=""
    read -r email
    if [[ -n "$email" ]]; then
      if [[ ! -f "$local_config" ]]; then
        printf '[user]\n  email = %s\n' "$email" > "$local_config"
      else
        git config --file "$local_config" user.email "$email"
      fi
      ok "git user.email set to $email (in ~/.gitconfig.local)"
    else
      warn "Skipped git user.email — set it later: git config --global user.email 'you@example.com'"
    fi
  fi
}

ensure_ssh_key() {
  log "Ensuring SSH key exists"

  local key_path="$HOME/.ssh/id_ed25519"
  local pub_path="${key_path}.pub"

  if [[ -f "$key_path" ]]; then
    ok "SSH key already exists: $key_path"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f ssh-keygen -t ed25519 -> $key_path"
    print -P "%F{yellow}dry-run:%f gh ssh-key add $pub_path"
    return
  fi

  run_cmd mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  local email=""
  email="$(git config --global user.email 2>/dev/null || true)"

  print -P "%F{cyan}Generating SSH key (ed25519)...%f"
  if [[ -n "$email" ]]; then
    ssh-keygen -t ed25519 -C "$email" -f "$key_path"
  else
    ssh-keygen -t ed25519 -f "$key_path"
  fi
  ok "SSH key generated: $key_path"

  # Upload the newly created key to GitHub
  if ! need_cmd gh; then
    warn "gh not found — upload manually: gh ssh-key add $pub_path"
    return
  fi

  if ! gh auth status >/dev/null 2>&1; then
    print -P "%F{cyan}Authenticate with GitHub to upload your SSH key:%f"
    gh auth login
  fi

  local hostname=""
  hostname="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
  local key_title="mac-setup ${hostname} $(date +%Y-%m-%d)"

  if gh ssh-key add "$pub_path" --title "$key_title"; then
    ok "SSH key uploaded to GitHub as: $key_title"
  else
    warn "Failed to upload SSH key — run manually: gh ssh-key add $pub_path --title \"$key_title\""
  fi
}


install_icloud_fonts() {
  log "Installing fonts from iCloud Drive"

  local icloud_fonts="$HOME/Library/Mobile Documents/com~apple~CloudDocs/fonts"
  local user_fonts="$HOME/Library/Fonts"

  if [[ ! -d "$icloud_fonts" ]]; then
    warn "iCloud fonts folder not found: $icloud_fonts"
    warn "Place .ttf/.otf files in iCloud Drive > fonts/ to auto-install"
    return
  fi

  local count=0
  for font in "$icloud_fonts"/*.{ttf,otf}(N); do
    local name="${font:t}"
    if [[ -f "$user_fonts/$name" ]]; then
      continue
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f cp $font -> $user_fonts/$name"
    else
      run_cmd cp "$font" "$user_fonts/$name"
      ok "Installed font: $name"
    fi
    ((count++))
  done

  if [[ "$count" -eq 0 ]]; then
    ok "All iCloud fonts already installed"
  fi
}

install_man_page() {
  log "Installing mac-setup man page"
  local brew_man=""
  if [[ -d /opt/homebrew/share/man/man7 ]]; then
    brew_man="/opt/homebrew/share/man/man7"
  elif [[ -d /usr/local/share/man/man7 ]]; then
    brew_man="/usr/local/share/man/man7"
  fi

  if [[ -z "$brew_man" ]]; then
    warn "No Homebrew man7 directory found; skipping man page install"
    return
  fi

  link_managed_file \
    "$DOTFILES_DIR/man/man7/mac-setup.7" \
    "$brew_man/mac-setup.7" \
    "mac-setup man page"
}

prune_old_backups() {
  local backup_parent="$HOME/config-backups"
  local keep=3

  [[ -d "$backup_parent" ]] || return 0

  local -a all_backups=("$backup_parent"/dotfiles-*(N/On))
  (( ${#all_backups[@]} <= keep )) && return 0

  local -a stale=("${all_backups[@]:$keep}")
  log "Pruning old backups (keeping $keep most recent)"

  for dir in "${stale[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      print -P "%F{yellow}dry-run:%f rm -rf $dir"
    else
      rm -rf "$dir"
      ok "Removed $dir"
    fi
  done
}

post_notes() {
  log "Next manual steps (optional)"
  cat <<'EOF_NOTES'

- Open Ghostty once to grant permissions and confirm settings.
- Open Raycast and Zed if you use them.
Tip:
- Re-run this script anytime after changes; it's safe and idempotent.
- Your backups are in ~/config-backups/ (timestamped).

EOF_NOTES
}

main() {
  log "Bootstrap starting"
  ok "Repo: $DOTFILES_DIR"

  ensure_xcode_clt
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
  configure_claude_settings
  install_man_page
  install_icloud_fonts
  ensure_git_identity
  ensure_ssh_key
  install_ghostty_shaders
  configure_macos_app_links
  install_lazyvim
  ensure_lazyvim_local_options_hook
  stow_nvim_plugins
  ensure_lazyvim_extras
  install_zjstatus
  ensure_treesitter_parsers
  install_mise_tools
  install_gcloud_cli
  install_docker_desktop
  install_app_store_apps
  install_rust
  install_cargo_tools
  configure_keyboard_repeat
  prune_old_backups
  post_notes

  ok "Bootstrap finished"
}

main "$@"
