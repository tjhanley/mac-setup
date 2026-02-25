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
- Installs LazyVim starter only when safe.
- Runs `mise install` for runtime tools.
- Installs Rust via `rustup-init` when needed.

## Installed/managed tools and apps
### CLI/dev tools
- git
- stow
- neovim
- starship
- lazygit
- ripgrep
- fd
- fzf
- bat
- jq
- zoxide
- eza
- zellij
- mise
- rustup-init

### Casks/apps/fonts
- ghostty
- raycast
- zed
- obsidian
- brave-browser
- font-jetbrains-mono-nerd-font

## Runtime management strategy
- Selected manager: `mise` (instead of `asdf`) for Node/Python/Ruby/Go.
- Rust managed via `rustup`.
- Shell activation for `mise` is in `.zshrc`.

## Shell config (`stow/zsh/.zshrc`)
- Homebrew shellenv loading.
- `mise` activation.
- Rust `~/.cargo/bin` path export.
- Starship init.
- zoxide init.
- fzf init.
- `cat` alias to `bat` (when available).
- Dot-navigation aliases: `..`, `...`, `....`, `.....`.
- Editor defaults: `EDITOR`/`VISUAL` = `nvim`; `vi`/`vim` aliases.
- eza aliases: `ls`, `ll`, `la`, `lt`.
- Tool aliases: `lg` for lazygit, `zj`/`zja` for zellij.

## Theme + terminal work
### Starship
- Added themed Starship config at `stow/starship/.config/starship.toml`.
- Updated to dense/powerline-style with:
  - stronger segment backgrounds
  - tighter spacing
  - explicit git state symbols
  - right-side time and duration

### Ghostty
- Restored/added `stow/ghostty/.config/ghostty/config`.
- Configured Nerd Font:
  - `font-family = "JetBrainsMono Nerd Font"`
- Catppuccin theme and basic window defaults included.

### Zellij
- Fixed KDL syntax in `stow/zellij/.config/zellij/config.kdl`.
- Replaced invalid `#` comments with valid `//` comments.
- Added `;` statement terminators.

## Repo hygiene added
- `.gitignore` added.
- `README.md` added with usage and structure.

## Commands used often
- Run setup:
  - `./setup.sh`
- Dry run:
  - `./setup.sh --dry-run`
- Verbose brew bundle checks/install:
  - `DEBUG=true ./setup.sh`
- Re-apply specific stow package:
  - `(cd stow && stow --target="$HOME" --restow <package>)`

## Notable implementation notes
- Stow conflicts happen when target files already exist and are not symlinks.
- Bootstrap now handles this by moving conflicts into backup before stowing.
- Dry-run mode reports intended actions but does not perform filesystem moves.

## Commit trail (high-level)
- Initial setup scaffolding and bootstrap.
- Added `.gitignore`.
- Added `README.md`.
- Improved bootstrap flow + shell defaults.
- Fixed zellij config syntax + added Brave.
- Tuned Starship prompt + restored Ghostty Nerd Font config.

## Current state
- Repo is pushing successfully to `origin/main`.
- Setup is idempotent and rerunnable.
- Prompt, terminal, shell, and package bootstrap are all configured.
