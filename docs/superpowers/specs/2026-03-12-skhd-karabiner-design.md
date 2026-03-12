# skhd + Karabiner-Elements Integration

**Date:** 2026-03-12
**Status:** Approved

## Goal

Add system-wide app-launching hotkeys using Caps Lock as a Hyper key (cmd+ctrl+alt+shift). All config is version-controlled via stow dotfiles and wired into the bootstrap script.

## Components

### Homebrew (`brew/Brewfile`)

```
tap "koekeishiya/formulae"           # must appear before the brew line that uses it
brew "koekeishiya/formulae/skhd"
cask "karabiner-elements"
```

Note: `asmvik` is the current GitHub username of the skhd author; `koekeishiya` is the Homebrew tap name. Both refer to the same project.

### Stow packages

**`stow/skhd/`** — mirrors `~/.config/skhd/`

- `skhdrc` — app launcher bindings:
  ```
  cmd + ctrl + alt + shift - g : open -a Ghostty
  cmd + ctrl + alt + shift - b : open -a "Brave Browser"
  cmd + ctrl + alt + shift - o : open -a Obsidian
  cmd + ctrl + alt + shift - s : open -a Spotify
  ```

**`stow/karabiner/`** — mirrors `~/.config/karabiner/`

- `assets/complex_modifications/hyper.json` — the Caps Lock → Hyper rule only.

  Karabiner-Elements atomically rewrites `karabiner.json` which would destroy a stow symlink. Only the rule file is stow-managed; `karabiner.json` stays under Karabiner's own control.

  `hyper.json` defines:
  - Caps Lock held → `cmd+ctrl+alt+shift` (Hyper)
  - Caps Lock tapped alone → `Escape`

  **Stow folding prevention:** stow folds a directory into a symlink only if the target doesn't exist. `~/.config/karabiner/` must exist as a real directory before `stow_dotfiles()` runs, so that stow creates symlinks inside it rather than replacing it. The bootstrap function below handles this.

  The user enables the rule once via Karabiner's UI: Complex Modifications → Add rule → Hyper. Documented in post_notes.

### Bootstrap function: `install_skhd_service()`

Added to `bootstrap/bootstrap-mac.zsh` before `post_notes()`, wired into `main()` after `configure_keyboard_repeat` and before `prune_old_backups`.

```zsh
install_skhd_service() {
  log "Installing skhd service"

  # Ensure ~/.config/karabiner/ exists as a real dir to prevent stow folding.
  # Must run before stow_dotfiles(), but this function runs after — so we also
  # add this mkdir to ensure_config_dir() (see below).

  local skhd_bin=""
  if need_cmd skhd; then
    skhd_bin="$(command -v skhd)"
  elif [[ -x /opt/homebrew/bin/skhd ]]; then
    skhd_bin="/opt/homebrew/bin/skhd"
  elif [[ -x /usr/local/bin/skhd ]]; then
    skhd_bin="/usr/local/bin/skhd"
  fi

  if [[ -z "$skhd_bin" ]]; then
    warn "skhd not found; skipping service install"
    return
  fi

  # Check if service is already bootstrapped (launchctl returns 0 if loaded).
  local service_target="gui/$(id -u)/com.asmvik.skhd"
  if /bin/launchctl print "$service_target" >/dev/null 2>&1; then
    ok "skhd service already running"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f $skhd_bin --start-service"
    return
  fi

  # --start-service auto-installs the plist (com.asmvik.skhd.plist) if missing,
  # then bootstraps the launchd agent.
  if "$skhd_bin" --start-service; then
    ok "skhd service started"
  else
    warn "skhd --start-service failed; grant Accessibility permission and re-run"
  fi
}
```

### `ensure_config_dir()` update

Add before `stow_dotfiles()` is called, to prevent stow from folding `~/.config/karabiner/` into a symlink:

```zsh
run_cmd mkdir -p "$HOME/.config/karabiner/assets/complex_modifications"
run_cmd mkdir -p "$HOME/.config/skhd"
```

This ensures stow places symlinks inside real directories rather than replacing them.

### Hard-reset handling in `stow_dotfiles()`

Inside the `if [[ "$HARD_RESET" -eq 1 ]]; then` block, add backup entries (consistent with existing pattern — full dir backup then specific file conflict-move):

```zsh
backup_path "$HOME/.config/karabiner"
backup_path "$HOME/.config/skhd"
```

In the `move_conflict_target` section:

```zsh
move_conflict_target ".config/karabiner/assets/complex_modifications/hyper.json"
move_conflict_target ".config/skhd/skhdrc"
```

Note: `backup_path` copies but does not remove, so `~/.config/karabiner/` persists through the hard-reset block — stow folding is not a risk in that path. `ensure_config_dir()` handles only the fresh-machine (non-hard-reset) case.

### Post-notes (`post_notes()`)

Add to the heredoc:

```
- Karabiner-Elements: grant Input Monitoring + Accessibility in
  System Settings > Privacy & Security, then enable the Hyper rule:
  Complex Modifications > Add rule > Hyper.
- skhd: grant Accessibility in System Settings > Privacy & Security.
```

### Documentation

- `README.md`:
  - Add `karabiner-elements` to Casks list
  - Add `skhd` to CLI tools list with note: "installed via `koekeishiya/formulae` tap"
- `docs/mac-setup-log.md`:
  - Add entries under "Installed/managed tools" and "Bootstrap behavior"

## What is not included

- yabai integration (not needed now; skhd is ready to extend later)
- Raycast hotkey migration (Raycast hotkeys remain independent)
- Additional Karabiner rules beyond Caps Lock → Hyper
- XDG_CONFIG_HOME customization (this repo does not override it; `~/.config/skhd/skhdrc` is correct)
