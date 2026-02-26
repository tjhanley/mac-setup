# mac-setup

Opinionated macOS bootstrap using:
- Homebrew + Brewfile
- GNU Stow for dotfiles
- `mise` for runtimes (node, python, ruby, go)
- `rustup` for Rust
- Catppuccin Mocha theming across Ghostty, Zellij, Starship, Zed, and Yazi

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
2. Installs packages/apps from `brew/Brewfile` (except `gcloud-cli` in initial pass)
3. Ensures `~/.config` exists
4. Creates `.env` from `.env.example` if missing
5. Backs up existing configs to `~/config-backups/`
6. Stows dotfiles from `stow/` into `$HOME`
7. Links macOS app configs (Zed, Obsidian) to stow-managed paths
8. Installs LazyVim starter (if no existing `~/.config/nvim`)
9. Installs runtimes via `mise`
10. Installs `gcloud-cli` using `mise` Python
11. Installs App Store apps (CopyLess 2, Magnet) via `mas`
12. Installs Rust via `rustup-init`
13. Installs `spotify_player` (TUI) via Cargo with image support

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
  mise/
    .config/mise/config.toml
  zed/
    .config/zed/settings.json
  obsidian/
    .config/obsidian/obsidian.json
  yazi/
    .config/yazi/theme.toml
    .config/yazi/Catppuccin-mocha.tmTheme
```

## CLI Tools

Installed via Homebrew: git, stow, neovim, tree-sitter-cli, typescript,
starship, lazygit, ripgrep, fd, fzf, fzf-tab, bat, jq, zoxide, eza, yazi,
kubectl, awscli, lazydocker, zellij, mise, mas

Casks: ghostty, raycast, zed, obsidian, brave-browser, spotify,
docker-desktop, codex, claude-code, gcloud-cli, font-jetbrains-mono-nerd-font

Shell completions: kubectl, docker, mise

## Notes

- Re-running the script is safe and idempotent.
- Backups live in `~/config-backups/` (timestamped).
- Open Ghostty, Raycast, Zed once after install if you use them.
- Open Spotify and complete login before using `spotify_player`.

## Customize

- Add/remove packages in `brew/Brewfile`
- Add stow packages under `stow/`
- Update runtime versions in `stow/mise/.config/mise/config.toml`
- Export installed Zed extensions into `stow/zed/.config/zed/settings.json`:
  `./scripts/export-zed-extensions.sh`
- Add machine-specific secrets to `.env` (generated from `.env.example`)
