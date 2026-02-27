# mac-setup

Opinionated macOS bootstrap using:
- Homebrew + Brewfile
- GNU Stow for dotfiles
- `mise` for runtimes (node, python, ruby, go)
- Rust + Cargo (Homebrew `rust`, with `rustup` toolchain management)
- Catppuccin Mocha theming across Ghostty, Zellij, Starship, Zed, and Yazi
- Amethyst tiling window manager (focus-follows-mouse)

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
6. Stows dotfiles from `stow/` into `$HOME` (nvim stowed separately — see step 10)
7. Clones Ghostty shaders to `~/.config/ghostty/shaders/`
8. Links macOS app configs (Zed, Obsidian) to stow-managed paths
9. Installs LazyVim starter (if no existing `~/.config/nvim`)
10. Stows Neovim plugin configs (Ghostty plugins) into LazyVim
11. Downloads zjstatus Zellij status-bar plugin (`zjstatus.wasm`)
12. Installs runtimes via `mise`
13. Installs `gcloud-cli` using `mise` Python
14. Installs App Store apps (CopyLess 2, Magnet) via `mas`
15. Installs Rust via `rustup-init`
16. Installs `spotify_player` (TUI) via Cargo with image support

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
    .config/zellij/layouts/default.kdl   # zjstatus bar with clock
  mise/
    .config/mise/config.toml
  zed/
    .config/zed/settings.json
  nvim/
    .config/nvim/lua/plugins/ghostty.lua  # stowed after LazyVim install
  obsidian/
    .config/obsidian/obsidian.json
  amethyst/
    .config/amethyst/amethyst.yml
  yazi/
    .config/yazi/theme.toml
    .config/yazi/Catppuccin-mocha.tmTheme
```

## CLI Tools

Installed via Homebrew: git, stow, neovim, tree-sitter-cli, typescript,
starship, lazygit, ripgrep, fd, fzf, fzf-tab, bat, jq, zoxide, eza, yazi,
kubectl, awscli, lazydocker, zellij, mise, rust, rustup-init, cargo-binstall, mas

Casks: ghostty, raycast, zed, obsidian, brave-browser, spotify,
docker-desktop, codex, claude-code, gcloud-cli, font-jetbrains-mono-nerd-font,
amethyst

Shell completions: kubectl, docker, mise

## Notes

- Re-running the script is safe and idempotent.
- Backups live in `~/config-backups/` (timestamped).
- Open Ghostty, Raycast, Zed once after install if you use them.
- Open Amethyst once and grant Accessibility permissions when prompted.
- Open Spotify and complete login before using `spotify_player`.

## Customize

- Add/remove packages in `brew/Brewfile`
- Add stow packages under `stow/`
- Update runtime versions in `stow/mise/.config/mise/config.toml`
- Export installed Zed extensions into `stow/zed/.config/zed/settings.json`:
  `./scripts/export-zed-extensions.sh`
- Manage local skip-worktree paths (stored in `.local/skip-worktree.paths`):
  `./scripts/skip-worktree.sh --help`
- Add machine-specific secrets to `.env` (generated from `.env.example`)

## Local Skip-Worktree

Use this when you want local app state in tracked files without committing it.

```sh
# add one tracked file to the managed list
./scripts/skip-worktree.sh add stow/obsidian/.config/obsidian/obsidian.json

# apply skip-worktree to every path in .local/skip-worktree.paths
./scripts/skip-worktree.sh apply

# see managed paths and whether each is active (S = active)
./scripts/skip-worktree.sh status

# list every active skip-worktree path in the repo
./scripts/skip-worktree.sh list

# clear skip-worktree for managed paths
./scripts/skip-worktree.sh clear
```

## Amethyst

Amethyst is installed via Homebrew cask and configured from
`stow/amethyst/.config/amethyst/amethyst.yml`. This repo enables
`focus-follows-mouse` and leaves gaps/margins/keybindings at defaults.

First run:
- Launch Amethyst.
- Grant Accessibility permissions (System Settings → Privacy & Security).

If you want to exclude apps from tiling, add a floating list to
`stow/amethyst/.config/amethyst/amethyst.yml` and re-run `./setup.sh` or `stow`.
