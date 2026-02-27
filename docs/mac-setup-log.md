# Mac Setup Log

## Scope
This note captures all setup work completed in the `mac-setup` repo so far.

## Core setup created
- Bootstrap entrypoint: `setup.sh`
- Main bootstrap script: `bootstrap/bootstrap-mac.zsh`
- Package management: `brew/Brewfile`
- Dotfiles layout via GNU Stow under `stow/`

## Bootstrap behavior
- Installs Homebrew if missing.
- Runs `brew update` and `brew upgrade` on each run.
- Installs Brewfile dependencies.
- Supports `--dry-run` mode.
- `brew` verbosity is controlled by `DEBUG=true|1`.
- Backs up existing target files into timestamped `~/config-backups/...`.
- Moves stow conflicts into backup before stowing (avoids stow conflict aborts).
- Handles known binary conflicts (Docker kubectl, codex cask).
- Installs LazyVim starter only when safe.
- Runs `mise install` for runtime tools.
- Installs `gcloud-cli` after mise python is available.
- Installs App Store apps (CopyLess 2, Magnet) via `mas`.
- Installs Rust via `rustup-init` when needed.
- Installs `spotify_player` via Cargo with image feature.
- Clones Ghostty shaders (`hackr-sh/ghostty-shaders`) to `~/.config/ghostty/shaders/`.
- Downloads `zjstatus.wasm` Zellij status-bar plugin from GitHub releases.
- Stows `nvim` package separately after LazyVim install (avoids directory conflicts).

## Installed/managed tools and apps
### CLI/dev tools
- git, stow, neovim, tree-sitter-cli, typescript
- starship, lazygit, ripgrep, fd, fzf, fzf-tab, bat, jq
- zoxide, eza, yazi
- kubectl, awscli
- zellij
- mise, rust, rustup-init, cargo-binstall, mas
- lazydocker

### Casks/apps/fonts
- ghostty, raycast, zed, obsidian
- brave-browser, spotify
- docker-desktop, codex, claude-code
- gcloud-cli, amethyst
- font-jetbrains-mono-nerd-font

### App Store (via mas)
- CopyLess 2
- Magnet

### Cargo-installed
- spotify_player (with image feature)

## Runtime management strategy
- Selected manager: `mise` (instead of `asdf`) for Node/Python/Ruby/Go.
- Rust managed via `rustup`.
- Shell activation for `mise` is in `.zshrc`.

## Shell config (`stow/zsh/.zshrc`)
- Homebrew shellenv loading (Apple Silicon + Intel).
- zsh completion core with fzf-tab integration.
- `mise` activation.
- Rust `~/.cargo/bin` path export.
- Starship init.
- zoxide init.
- fzf init.
- CLI-specific completions: kubectl, docker, mise.
- `cat` alias to `bat` (when available).
- Dot-navigation aliases: `..`, `...`, `....`, `.....`.
- Editor defaults: `EDITOR`/`VISUAL` = `nvim`; `vi`/`vim` aliases.
- eza aliases: `ls`, `ll`, `la`, `lt`.
- yazi cwd-on-exit wrapper: `y`.
- Tool aliases: `lg` (lazygit), `zj`/`zja` (zellij), `d` (docker), `lzd` (lazydocker), `spt` (spotify_player).
- AI + cloud aliases: `cx` (codex), `cc` (claude), `k` (kubectl), `gal` (gcloud auth login).
- gcloud SDK path and completion sourcing with mise Python for CLOUDSDK_PYTHON.
- zsh plugins loaded last: autosuggestions, syntax-highlighting.

## Theme + terminal work
### Catppuccin Mocha (consistent across tools)
- Starship: powerline-style with `catppuccin_mocha` palette.
- Ghostty: `theme = "Catppuccin Mocha"`, JetBrainsMono Nerd Font.
- Zellij: `theme "catppuccin-mocha"` (built-in).
- Zed: `Catppuccin Mocha` dark theme with catppuccin extensions.
- Yazi: `catppuccin-mocha-blue` theme + Mocha tmTheme for syntax highlighting.

### Starship
- Dense/powerline-style with stronger segment backgrounds.
- Explicit git state symbols.
- Right-side time and duration.

### Ghostty
- JetBrainsMono Nerd Font at size 13.
- Fullscreen by default (`fullscreen = true`).
- Vim-like alt+hjkl keybinds.
- Shaders available (cloned from `hackr-sh/ghostty-shaders`); commented-out examples in config.
- Neovim integration: `ghostty.nvim` (config validation), `ghostty-theme-sync.nvim` (`:GhosttyTheme`), `tree-sitter-ghostty` (treesitter grammar).
- Zed extension auto-installed for Ghostty config syntax highlighting.

### Zellij
- Pane frames disabled, scrollback editor set to nvim.
- Mouse mode enabled.
- zjstatus custom status bar (`layouts/default.kdl`): mode indicator + session name (left), tabs (center), datetime clock (right).
- zjstatus plugin downloaded to `~/.config/zellij/plugins/zjstatus.wasm`.

## Stow packages
- `zsh/` — `.zshrc`, `.zprofile`
- `git/` — `.gitconfig`
- `starship/` — `.config/starship.toml`
- `ghostty/` — `.config/ghostty/config`
- `zellij/` — `.config/zellij/config.kdl`, `.config/zellij/layouts/default.kdl`
- `mise/` — `.config/mise/config.toml`
- `zed/` — `.config/zed/settings.json`
- `nvim/` — `.config/nvim/lua/plugins/ghostty.lua` (stowed separately after LazyVim install)
- `obsidian/` — `.config/obsidian/obsidian.json`
- `amethyst/` — `.config/amethyst/amethyst.yml`
- `yazi/` — `.config/yazi/theme.toml`, `.config/yazi/Catppuccin-mocha.tmTheme`

## macOS app config linking
- Zed settings symlinked from `~/.config/zed/settings.json` to `~/Library/Application Support/Zed/settings.json`.
- Obsidian settings symlinked similarly.

## Repo hygiene
- `.gitignore` covers macOS files, editor dirs, `.env`, backups.
- `README.md` with usage, structure, and customization notes.
- `CLAUDE.md` / `AGENTS.md` — agent instructions for Claude Code and Codex to keep docs in sync.
- `scripts/export-zed-extensions.sh` for syncing installed Zed extensions.
- `scripts/skip-worktree.sh` for managing local skip-worktree paths (stored in `.local/skip-worktree.paths`).

## Commands used often
- Run setup: `./setup.sh`
- Dry run: `./setup.sh --dry-run`
- Verbose brew: `DEBUG=true ./setup.sh`
- Re-apply specific stow package: `(cd stow && stow --target="$HOME" --restow <package>)`

## Notable implementation notes
- Stow conflicts happen when target files already exist and are not symlinks.
- Bootstrap handles this by moving conflicts into backup before stowing.
- Dry-run mode reports intended actions but does not perform filesystem moves.
- gcloud-cli is installed in a separate step after mise python to set CLOUDSDK_PYTHON.
- App Store installs prompt for authentication if not signed in.
- Rust install precedes spotify_player cargo build.

## Current state
- Repo is pushing successfully to `origin/main`.
- Setup is idempotent and rerunnable.
- Catppuccin Mocha theme consistent across all configured tools.
- Prompt, terminal, shell, and package bootstrap are all configured.
