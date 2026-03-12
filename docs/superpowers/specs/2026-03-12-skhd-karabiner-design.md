# skhd + Karabiner-Elements Integration

**Date:** 2026-03-12
**Status:** Approved

## Goal

Add system-wide app-launching hotkeys using Caps Lock as a Hyper key (cmd+ctrl+alt+shift). All config is version-controlled via stow dotfiles and wired into the bootstrap script.

## Components

### Homebrew

- `tap "asmvik/formulae"` — required for skhd
- `brew "asmvik/formulae/skhd"` — hotkey daemon
- `cask "karabiner-elements"` — key remapper

### Stow packages

**`stow/karabiner/`** — mirrors `~/.config/karabiner/`

- `karabiner.json` — Karabiner complex modification:
  - Caps Lock held → sends `cmd+ctrl+alt+shift` (Hyper)
  - Caps Lock tapped alone → sends `Escape`

**`stow/skhd/`** — mirrors `~/.config/skhd/`

- `skhdrc` — app launcher bindings:
  - `cmd + ctrl + alt + shift - g` → `open -a Ghostty`
  - `cmd + ctrl + alt + shift - b` → `open -a "Brave Browser"`
  - `cmd + ctrl + alt + shift - o` → `open -a Obsidian`
  - `cmd + ctrl + alt + shift - s` → `open -a Spotify`

### Bootstrap function

`install_skhd_service()` added to `bootstrap/bootstrap-mac.zsh`:

- Checks if `skhd` is in PATH; warns and returns if not
- Checks if service is already running (`skhd --check-service` or pid-file check)
- Runs `skhd --start-service` to register launchd agent
- Supports `DRY_RUN`
- Wired into `main()` after `stow_dotfiles`

### Hard-reset handling

`stow_dotfiles()` gains backup + conflict-move entries for:
- `.config/karabiner/karabiner.json`
- `.config/skhd/skhdrc`

### Post-notes

A warning is added to `post_notes()`:

> Karabiner-Elements and skhd require Accessibility access. Grant it in:
> System Settings → Privacy & Security → Accessibility

### Documentation

- `README.md` — add karabiner-elements and skhd to the Casks/CLI tools lists
- `docs/mac-setup-log.md` — add entries under "Installed/managed tools" and "Bootstrap behavior"

## What is not included

- yabai integration (not needed now; skhd is ready to extend later)
- Raycast hotkey migration (Raycast hotkeys remain independent)
- Additional Karabiner rules beyond Caps Lock → Hyper
