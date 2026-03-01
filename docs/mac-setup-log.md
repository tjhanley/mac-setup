# Mac Setup Log

## Scope
This note captures all setup work completed in the `mac-setup` repo so far.

## Core setup created
- Bootstrap entrypoint: `setup.sh`
- Main bootstrap script: `bootstrap/bootstrap-mac.zsh`
- Package management: `brew/Brewfile`
- Dotfiles layout via GNU Stow under `stow/`

## Bootstrap behavior
- Installs Xcode Command Line Tools if missing (waits for GUI installer, then accepts license).
- Installs Homebrew if missing.
- Runs `brew update` and `brew upgrade` on each run.
- Installs Brewfile dependencies.
- Supports `--dry-run` mode.
- `brew` verbosity is controlled by `DEBUG=true|1`.
- Backs up existing target files into timestamped `~/config-backups/...`.
- Prunes old backups at the end of each run, keeping the 3 most recent.
- Moves stow conflicts into backup before stowing (avoids stow conflict aborts).
- Handles known binary conflicts (Docker kubectl, codex cask).
- Installs LazyVim starter only when safe.
- Runs `mise install` for runtime tools.
- Installs `gcloud-cli` after mise python is available.
- Installs `docker-desktop` separately (ensures `/usr/local/cli-plugins` exists for docker-compose linking).
- Installs App Store apps (CopyLess 2, Magnet) via `mas`.
- Installs Rust via `rustup-init` when needed.
- Installs Cargo tools (`basalt-tui`) via `cargo-binstall` (falls back to `cargo install`).
- Clones Ghostty shaders (`hackr-sh/ghostty-shaders`) to `~/.config/ghostty/shaders/`.
- Downloads `zjstatus.wasm` Zellij status-bar plugin from GitHub releases.
- Stows `nvim` package separately after LazyVim install (avoids directory conflicts).
- Ensures LazyVim extras (claudecode) are present in `lazyvim.json`.
- Installs private fonts from iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/fonts/`) into `~/Library/Fonts/`. Skips already-installed fonts.
- Prompts for `git user.name` and `user.email` after stowing if not already set; writes to `~/.gitconfig.local` (included via `[include]` in stow-managed `.gitconfig`).
- Generates SSH key (ed25519) if `~/.ssh/id_ed25519` is missing; uses git email as comment. Uploads public key to GitHub via `gh ssh-key add` (authenticates with `gh auth login` if needed, checks fingerprint to avoid duplicates).
- Verifies git commit signing: checks `op-ssh-sign` binary, 1Password SSH agent socket, and signing key in gitconfig. Warns with setup instructions if anything is missing.

## Installed/managed tools and apps
### CLI/dev tools
- git, git-delta, git-lfs, gh, stow, neovim, tree-sitter-cli, typescript
- starship, lazygit, ripgrep, fd, fzf, fzf-tab, bat, jq
- zoxide, eza, yazi
- kubectl, k9s, awscli
- zellij
- mise, rust, rustup-init, cargo-binstall, mas
- lazydocker
- imagemagick (used by Snacks.image in Neovim)
- tldr, htop, wget, trash, dust, duf, fastfetch

### Casks/apps/fonts
- 1password, ghostty, raycast, zed, obsidian
- brave-browser, spotify
- docker-desktop, codex
- gcloud-cli, amethyst
- font-blex-mono-nerd-font, font-jetbrains-mono-nerd-font

### App Store (via mas)
- CopyLess 2
- Magnet

## Runtime management strategy
- Selected manager: `mise` (instead of `asdf`) for Node/Python/Ruby/Go.
- Rust managed via `rustup`.
- Cargo tools installed via `cargo-binstall`: basalt-tui.
- Shell activation for `mise` is in `.zshrc`.

## Shell config (`stow/zsh/.zshrc`)
- Homebrew shellenv loading (Apple Silicon + Intel).
- zsh completion core with fzf-tab integration.
- `mise` activation.
- Rust `~/.cargo/bin` path export.
- Starship init.
- zoxide init.
- fzf init with Catppuccin Mocha color scheme (`FZF_DEFAULT_OPTS`).
- CLI completions cached to `~/.cache/zsh/completions/` and added to fpath before `compinit` (lazy-loaded): kubectl, docker, mise, gh, rustup, cargo.
- History: `HISTSIZE`/`SAVEHIST` 50k, `share_history`, `hist_ignore_dups`, `hist_ignore_space`, `hist_reduce_blanks`.
- Shell options: `auto_cd`, `extended_glob`, `correct`.
- `RIPGREP_CONFIG_PATH` set to `~/.ripgreprc`.
- `cat` alias to `bat` (when available).
- Dot-navigation aliases: `..`, `...`, `....`, `.....`.
- Editor defaults: `EDITOR`/`VISUAL` = `nvim`; `vi`/`vim` aliases.
- eza aliases: `ls`, `ll` (with `--git`, `--header`, `--time-style=relative`), `la`, `lt` (with `--git`, `--git-ignore`).
- eza Catppuccin Mocha theme via `~/.config/eza/theme.yml`.
- yazi cwd-on-exit wrapper: `y`.
- Auto-starts zellij (`exec zellij`) for interactive Ghostty shells; opt out with `NO_AUTO_ZELLIJ=1`.
- Git aliases (OMZ-style): `g`, `ga`, `gaa`, `gb`, `gba`, `gc`, `gcmsg`, `gco`, `gcb`, `gd`, `gds`, `gf`, `gl`, `gp`, `gpf`, `glog`, `gloga`, `grb`, `grbi`, `gst`, `gsw`, `gswc`.
- Tool aliases: `lg` (lazygit), `zj`/`zja` (zellij), `d` (docker), `lzd` (lazydocker).
- AI + cloud aliases: `cx` (codex), `cc` (claude), `k` (kubectl), `gal` (gcloud auth login).
- Claude Code installed via standalone installer (`~/.local/bin/claude`), not Homebrew cask.
- gcloud SDK path and completion sourcing with mise Python for CLOUDSDK_PYTHON.
- `~/.local/bin` added to PATH (mise shims, pipx, user scripts).
- Conditional `source ~/.secrets` for machine-specific tokens/keys (not tracked in git).
- zsh plugins loaded last: autosuggestions, syntax-highlighting.

## Theme + terminal work
### Catppuccin Mocha (consistent across tools)
- Starship: powerline-style with `catppuccin_mocha` palette.
- Ghostty: `theme = "Catppuccin Mocha"`, BlexMono Nerd Font (IBM Plex Mono).
- Zellij: `theme "catppuccin-mocha"` (built-in).
- Zed: `Catppuccin Mocha` dark theme with catppuccin extensions and icon theme. Dank Mono buffer font (private, from iCloud), BlexMono Nerd Font for terminal. Auto-installs terraform, dockerfile, toml, make, env extensions. Claude (Anthropic) as default assistant model. Format on save, inlay hints enabled.
- Yazi: `catppuccin-mocha-blue` theme + Mocha tmTheme for syntax highlighting.

### Starship
- Dense/powerline-style with stronger segment backgrounds.
- Apple logo () + directory + git + runtime languages + cmd_duration (no user@host or time — shown in zjstatus).
- Explicit git state symbols.

### Ghostty
- BlexMono Nerd Font (IBM Plex Mono) at size 17.
- Fullscreen by default (`fullscreen = true`).
- Vim-like alt+hjkl keybinds.
- Shaders available (cloned from `hackr-sh/ghostty-shaders`); commented-out examples in config.
- Neovim integration: `ghostty.nvim` (config validation), `ghostty-theme-sync.nvim` (`:GhosttyTheme`), `tree-sitter-ghostty` (treesitter grammar).
- Zed extension auto-installed for Ghostty config syntax highlighting.

### Zellij
- Pane frames enabled with rounded corners; `simplified_ui true` to hide the built-in hint bar (zjstatus replaces it); session name hidden from frames; `session_serialization false`.
- Scrollback editor set to nvim; mouse mode enabled.
- Custom keybind: pane mode `r` remapped to rename pane (consistent with tab mode `r` for rename tab).
- Custom keybind: `Alt l` opens a floating fzf launcher (`scripts/launcher.sh`) to launch apps (lazygit, lazydocker, k9s, htop, yazi, fastfetch) in new floating panes.
- zjstatus custom status bar (`layouts/default.kdl`) with full Catppuccin Mocha palette defined as named variables: session icon + mode indicator (left), tabs with rounded powerline chiclets (center-left), notifications (center), CPU + memory stats + dynamic battery indicator + calendar icon + datetime (right). All pills use rounded powerline caps. Clean mode labels (no keybinding hints). Active tab highlighted in peach, inactive in blue. System stats via `scripts/cpu.sh` and `scripts/mem.sh`. Battery via `scripts/battery.sh` — picks from Nerd Font battery glyphs at 10% increments plus a charging state icon, refreshes every 30 s.
- zjstatus plugin downloaded to `~/.config/zellij/plugins/zjstatus.wasm`.

## Stow packages
- `zsh/` — `.zshrc`, `.zprofile`
- `git/` — `.gitconfig`, `.gitignore` (global gitignore with macOS, AI tooling, secrets patterns)
- `bat/` — `.config/bat/config` (Catppuccin Mocha theme, line numbers, change markers)
- `lazygit/` — `.config/lazygit/config.yml` (Catppuccin Mocha theme, nerd font icons)
- `ripgrep/` — `.ripgreprc` (smart-case, search hidden files, exclude `.git/`)
- `ssh/` — `.ssh/config` (1Password SSH agent, `Include config.local` for machine-specific hosts)
- `starship/` — `.config/starship.toml`
- `ghostty/` — `.config/ghostty/config`
- `zellij/` — `.config/zellij/config.kdl`, `.config/zellij/layouts/default.kdl`, `.config/zellij/scripts/{cpu,mem,battery,launcher}.sh`
- `mise/` — `.config/mise/config.toml`
- `zed/` — `.config/zed/settings.json`
- `nvim/` — `.config/nvim/lua/config/options.lua` (disable unused providers), `.config/nvim/lua/plugins/ghostty.lua` (stowed separately after LazyVim install)
- `obsidian/` — `.config/obsidian/obsidian.json`
- `amethyst/` — `.config/amethyst/amethyst.yml`
- `eza/` — `.config/eza/theme.yml` (Catppuccin Mocha theme)
- `yazi/` — `.config/yazi/theme.toml`, `.config/yazi/Catppuccin-mocha.tmTheme`

## macOS app config linking
- Zed settings symlinked from `~/.config/zed/settings.json` to `~/Library/Application Support/Zed/settings.json`.
- Obsidian settings symlinked similarly. Config is seeded with `{}` if missing (required by basalt-tui).

## Repo hygiene
- `.gitignore` covers macOS files, editor dirs, `.env`, `.secrets`, backups.
- `README.md` with usage, structure, and customization notes.
- `CLAUDE.md` / `AGENTS.md` — agent instructions for Claude Code and Codex to keep docs in sync.
- `scripts/export-zed-extensions.sh` for syncing installed Zed extensions.
- `scripts/skip-worktree.sh` for managing local skip-worktree paths (stored in `.local/skip-worktree.paths`).
- `tests/` — bats-core test suite (structure, syntax, bootstrap dry-run). CI via `.github/workflows/ci.yml` on push/PR to main.
- `man/man7/mac-setup.7` — custom man page (`man mac-setup`); symlinked into Homebrew's man path during bootstrap. Includes zellij keybinds reference (resize, move, pane, custom).

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
- docker-desktop is skipped in `brew bundle` and installed separately; bootstrap pre-creates `/usr/local/cli-plugins` (requires sudo) for docker-compose linking.
- App Store installs prompt for authentication if not signed in.
- Git config uses `git-delta` as pager, 1Password SSH signing (`gpgSign`/`op-ssh-sign`), and Git LFS filters. `user.name`, `user.email`, and `user.signingkey` are omitted from tracked config (set per-machine in `~/.gitconfig.local`). `core.excludesfile` points to `~/.gitignore` (stow-managed global gitignore).

## Current state
- Repo is pushing successfully to `origin/main`.
- Setup is idempotent and rerunnable.
- Catppuccin Mocha theme consistent across all configured tools.
- Prompt, terminal, shell, and package bootstrap are all configured.
