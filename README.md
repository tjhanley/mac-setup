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

1. Installs Xcode Command Line Tools and accepts license (if needed)
2. Installs Homebrew (if missing)
3. Installs packages/apps from `brew/Brewfile` (except `gcloud-cli` and `docker-desktop` in initial pass)
4. Ensures `~/.config` exists
5. Creates `.env` from `.env.example` if missing
6. Backs up existing configs to `~/config-backups/`
7. Stows dotfiles from `stow/` into `$HOME` (nvim stowed separately — see step 13)
8. Installs private fonts from iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/fonts/`)
9. Prompts for `git user.email` if not set (stored in `~/.gitconfig.local`)
10. Generates SSH key (ed25519) if missing and uploads to GitHub via `gh`
11. Verifies git commit signing (1Password SSH agent, signing key)
12. Clones Ghostty shaders to `~/.config/ghostty/shaders/`
13. Links macOS app configs (Zed, Obsidian) to stow-managed paths
14. Installs LazyVim starter (if no existing `~/.config/nvim`)
15. Stows Neovim plugin configs (Ghostty plugins) into LazyVim
16. Downloads zjstatus Zellij status-bar plugin (`zjstatus.wasm`)
17. Installs runtimes via `mise`
18. Installs `gcloud-cli` using `mise` Python
19. Installs `docker-desktop` (pre-creates `/usr/local/cli-plugins` for docker-compose)
20. Installs App Store apps (CopyLess 2, Magnet) via `mas`
21. Installs Rust via `rustup-init`
22. Installs Cargo tools (`basalt-tui`) via `cargo-binstall`

## Dotfiles Structure

```
stow/
  zsh/
    .zshrc
    .zprofile
  git/
    .gitconfig
    .gitignore
  bat/
    .config/bat/config                       # Catppuccin Mocha theme
  lazygit/
    .config/lazygit/config.yml               # Catppuccin Mocha theme
  ripgrep/
    .ripgreprc                               # smart-case, search hidden
  ssh/
    .ssh/config                              # 1Password agent, Include config.local
  starship/
    .config/starship.toml
  ghostty/
    .config/ghostty/config
  zellij/
    .config/zellij/config.kdl                # pane-mode r = rename (matches tab-mode r)
    .config/zellij/layouts/default.kdl       # zjstatus Catppuccin Mocha status bar
    .config/zellij/scripts/battery.sh        # dynamic battery glyph for zjstatus
  mise/
    .config/mise/config.toml
  zed/
    .config/zed/settings.json
  nvim/
    .config/nvim/lua/config/options.lua    # disable unused providers
    .config/nvim/lua/plugins/ghostty.lua  # stowed after LazyVim install
  obsidian/
    .config/obsidian/obsidian.json
  amethyst/
    .config/amethyst/amethyst.yml
  eza/
    .config/eza/theme.yml                # Catppuccin Mocha theme
  yazi/
    .config/yazi/theme.toml
    .config/yazi/Catppuccin-mocha.tmTheme
```

## CLI Tools

Installed via Homebrew: git, git-delta, git-lfs, gh, stow, neovim,
tree-sitter-cli, typescript, starship, lazygit, ripgrep, fd, fzf, fzf-tab,
bat, jq, zoxide, eza, yazi, kubectl, k9s, awscli, lazydocker, zellij, mise, rust,
rustup-init, cargo-binstall, imagemagick, mas, tldr, htop, wget, trash, dust,
duf, fastfetch

Casks: 1password, ghostty, raycast, zed, obsidian, brave-browser, spotify,
docker-desktop, codex, gcloud-cli, font-blex-mono-nerd-font,
font-jetbrains-mono-nerd-font, amethyst

Cargo tools: basalt-tui (Obsidian vault TUI)

Claude Code: installed via the official standalone installer (`~/.local/bin/claude`), not Homebrew.

Shell completions: kubectl, docker, mise, gh, rustup, cargo

## Man Page

A full system reference is available as a man page:

```sh
man mac-setup
```

Covers bootstrap steps, stow packages, git/tool/shell aliases, completions,
shell options, git config, runtimes, theme, files, and common tasks.

## Notes

- Re-running the script is safe and idempotent.
- Backups live in `~/config-backups/` (timestamped).
- Open Ghostty, Raycast, Zed once after install if you use them.
- Open Amethyst once and grant Accessibility permissions when prompted.

## Tests

Tests use [bats-core](https://github.com/bats-core/bats-core) and run on every push via GitHub Actions.

```sh
bats tests/
```

## Customize

- Add/remove packages in `brew/Brewfile`
- Add stow packages under `stow/`
- Update runtime versions in `stow/mise/.config/mise/config.toml`
- Export installed Zed extensions into `stow/zed/.config/zed/settings.json`:
  `./scripts/export-zed-extensions.sh`
- Manage local skip-worktree paths (stored in `.local/skip-worktree.paths`):
  `./scripts/skip-worktree.sh --help`
- Add machine-specific secrets to `~/.secrets` (sourced conditionally if present)
- Add shared env vars to `.env` (generated from `.env.example`)

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
