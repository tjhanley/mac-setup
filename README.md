# mac-setup

Opinionated macOS bootstrap using:
- Homebrew + Brewfile
- GNU Stow for dotfiles
- `mise` for runtimes (node, python, ruby, go)
- `rustup` for Rust
- Catppuccin theming for Ghostty and Zellij

## Requirements
- macOS
- git

## Quick Start

```sh
./setup.sh
```

Dry run:

```sh
./setup.sh --dry-run
```

## What It Does

1. Installs Homebrew (if missing)
2. Installs packages/apps from `brew/Brewfile`
3. Ensures `~/.config` exists
4. Creates `.env` from `.env.example` if missing
5. Backs up existing configs to `~/config-backups/`
6. Stows dotfiles from `stow/` into `$HOME`
7. Installs LazyVim starter (if no existing `~/.config/nvim`)
8. Installs runtimes via `mise`
9. Installs Rust via `rustup-init`

## Dotfiles Structure

```
stow/
  zsh/
    .zshrc
    .zprofile
  git/
    .gitconfig
  starship/
    .config/starship.toml
  ghostty/
    .config/ghostty/config
  zellij/
    .config/zellij/config.kdl
    .config/zellij/themes/
  mise/
    .config/mise/config.toml
```

## Notes

- Re-running the script is safe and idempotent.
- Backups live in `~/config-backups/` (timestamped).
- Open Ghostty, Raycast, Zed once after install if you use them.

## Customize

- Add/remove packages in `brew/Brewfile`
- Add stow packages under `stow/`
- Update runtime versions in `stow/mise/.config/mise/config.toml`
- Export installed Zed extensions into `stow/zed/.config/zed/settings.json`:
  `./scripts/export-zed-extensions.sh`
- Add machine-specific secrets to `.env` (generated from `.env.example`)
