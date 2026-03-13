# Mac Setup Log

## Scope
This note captures all setup work completed in the `mac-setup` repo so far.

## Core setup created
- Bootstrap entrypoint: `setup.sh`
- Main bootstrap script: `bootstrap/bootstrap-mac.zsh`
- Package management: `brew/Brewfile`
- Dotfiles layout via GNU Stow under `stow/`

## Bootstrap behavior
- Installs Xcode Command Line Tools if missing (waits for GUI installer, checks license status first, and only requests sudo license acceptance when needed).
- Installs Homebrew if missing.
- Runs `brew update` and `brew upgrade` on each run.
- Installs Brewfile dependencies.
- Supports `--dry-run` mode.
- `brew` verbosity is controlled by `DEBUG=true|1`.
- Default stow mode is **merge-first**: uses `stow --adopt --restow` to pull any local drift (real files at stow targets) into the repo, then commits the adoption and symlinks. Keeps app configs intact on re-runs.
- `--hard-reset` flag enables pave mode: backs up existing configs to timestamped `~/config-backups/...`, moves stow conflicts into backup, then stows without `--adopt` (repo wins).
- `link_managed_file` also adopts real-file targets in default mode: copies target content back to source before symlinking (handles Zed/Obsidian app-support paths where apps may have replaced symlinks with real files).
- Prunes old backups at the end of each run, keeping the 3 most recent.
- Handles known binary conflicts (Docker kubectl, codex cask).
- Installs LazyVim starter only when safe.
- Runs `mise install` for runtime tools using explicit `tool@version` values from `~/.config/mise/config.toml` (stow-managed), with explicit timeout env and a one-time retry using a longer remote-version fetch timeout.
- Installs `gcloud-cli` after mise python is available.
- Installs `docker-desktop` separately (ensures `/usr/local/cli-plugins` exists for docker-compose linking).
- Installs App Store apps (CopyLess 2, Magnet) via `mas`.
- Installs Rust via `rustup-init` when needed.
- Installs Cargo tools (`basalt-tui`) via `cargo-binstall` (falls back to `cargo install`).
- Installs npm global tools (`@mariozechner/pi-coding-agent`) via `npm install -g`; skips if `npm` not found.
- Configures keyboard repeat speed via macOS defaults (`InitialKeyRepeat=10`, `KeyRepeat=1`, `ApplePressAndHoldEnabled=false`).
- Starts skhd as a launchd service (`skhd --start-service`) after `configure_keyboard_repeat`; idempotent (checks `launchctl print gui/<uid>/com.asmvik.skhd` before acting).
- Clones Ghostty shaders (`hackr-sh/ghostty-shaders`) to `~/.local/share/ghostty/shaders/` to avoid writing into stow-managed repo paths; migrates legacy non-repo installs from `~/.config/ghostty/shaders/`.
- Downloads `zjstatus.wasm` Zellij status-bar plugin from GitHub releases.
- Ensures LazyVim `lua/config/options.lua` includes `pcall(require, "config.local")` to load repo-managed local options.
- Stows `nvim` package separately after LazyVim install (moves known plugin-file conflicts into backup first).
- Ensures LazyVim extras (claudecode) are present in `lazyvim.json`.
- Installs private fonts from iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/fonts/`) into `~/Library/Fonts/`. Skips already-installed fonts.
- Prompts for `git user.name` and `user.email` after stowing only if missing from effective git config; writes to `~/.gitconfig.local` (included via `[include]` in stow-managed `.gitconfig`).
- Generates SSH key (ed25519) if `~/.ssh/id_ed25519` is missing; uses git email as comment. Uploads public key to GitHub via `gh ssh-key add` (authenticates with `gh auth login` if needed, checks fingerprint to avoid duplicates).
- Verifies git commit signing: checks `op-ssh-sign` binary, 1Password SSH agent socket, and signing key in gitconfig. Warns with setup instructions if anything is missing.

## Installed/managed tools and apps
### CLI/dev tools
- git, git-delta, git-lfs, gh, stow, neovim, tree-sitter-cli, typescript
- starship, lazygit, ripgrep, fd, fzf, fzf-tab, bat, jq
- zoxide, eza, yazi
- kubectl, k9s, stern, awscli
- zellij
- mise, rust, rustup-init, cargo-binstall, mas
- lazydocker
- skhd (via koekeishiya/formulae tap) — hotkey daemon
- imagemagick (used by Snacks.image in Neovim)
- tldr, btop, wget, trash, dust, duf, fastfetch

### Casks/apps/fonts
- 1password, ghostty, raycast, karabiner-elements, zed, obsidian
- brave-browser, spotify
- docker-desktop, codex
- gcloud-cli
- font-blex-mono-nerd-font, font-jetbrains-mono-nerd-font

### App Store (via mas)
- CopyLess 2
- Magnet

## Runtime management strategy
- Selected manager: `mise` (instead of `asdf`) for Node/Python/Ruby/Go.
- Rust managed via `rustup`.
- Cargo tools installed via `cargo-binstall`: basalt-tui.
- npm global tools installed via `npm install -g`: @mariozechner/pi-coding-agent.
- opencode: installed via Homebrew tap (opencode-ai/tap). TUI coding agent with built-in Catppuccin theme. Alias: `oc`.
- Shell activation for `mise` is in `.zshrc`.

## Shell config (`stow/zsh/.zshrc`)
- Homebrew shellenv loading (Apple Silicon + Intel).
- zsh completion core with fzf-tab integration.
- `mise` activation.
- Rust `~/.cargo/bin` path export.
- Starship init.
- zoxide init.
- fzf init with Catppuccin Mocha color scheme (`FZF_DEFAULT_OPTS`).
- CLI completions cached to `~/.cache/zsh/completions/` and added to fpath before `compinit` (lazy-loaded): kubectl, docker, mise, gh, stern, rustup, cargo.
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
- AI + cloud aliases: `cx` (codex), `cc` (claude), `oc` (opencode), `k` (kubectl), `gal` (gcloud auth login).
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
- Zed: `Catppuccin Mocha` dark theme with catppuccin extensions and icon theme. Dank Mono buffer font (private, from iCloud), BlexMono Nerd Font for terminal. Auto-installs terraform, dockerfile, toml, make, env extensions. Claude (Anthropic) as default assistant model. Format on save, inlay hints enabled. Arrow keys disabled in vim normal/insert/visual modes (`keymap.json`).
- Yazi: `catppuccin-mocha-blue` theme + Mocha tmTheme for syntax highlighting.

### Starship
- Dense/powerline-style with stronger segment backgrounds.
- Apple logo () + directory + git + runtime languages + cmd_duration (no user@host or time — shown in zjstatus).
- Explicit git state symbols.

### Ghostty
- BlexMono Nerd Font (IBM Plex Mono) at size 17.
- Fullscreen by default (`fullscreen = true`).
- Vim-like alt+hjkl keybinds.
- Shaders available (cloned from `hackr-sh/ghostty-shaders` into `~/.local/share/ghostty/shaders`); commented-out examples in config.
- Neovim integration: `ghostty.nvim` (config validation), `ghostty-theme-sync.nvim` (`:GhosttyTheme`), `tree-sitter-ghostty` (treesitter grammar).
- Neovim arrow keys disabled in normal/insert/visual modes (`lua/config/keymaps.lua`, auto-loaded by LazyVim).
- Zed extension auto-installed for Ghostty config syntax highlighting.

### Zellij
- Pane frames enabled with rounded corners; `simplified_ui true` to hide the built-in hint bar (zjstatus replaces it); session name hidden from frames; `session_serialization false`.
- Scrollback editor set to nvim; mouse mode enabled.
- Custom keybind: pane mode `r` remapped to rename pane (consistent with tab mode `r` for rename tab).
- Custom keybind: `Alt l` opens a floating fzf launcher (`scripts/launcher.sh`) to launch apps (lazygit, lazydocker, k9s, btop, yazi, fastfetch) in new floating panes.
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
- `zed/` — `.config/zed/settings.json`, `.config/zed/keymap.json` (arrow keys disabled in vim normal/insert/visual modes)
- `nvim/` — `.config/nvim/lua/config/local.lua` (disable unused providers; loaded from LazyVim `options.lua` hook), `.config/nvim/lua/config/keymaps.lua` (arrow keys disabled in n/i/v modes), `.config/nvim/lua/plugins/ghostty.lua` (stowed separately after LazyVim install)
- `obsidian/` — `.config/obsidian/obsidian.json` (vault registry); `necronomicon/.obsidian/` (vault config symlinked into `~/necronomicon`): all settings JSONs, `plugins/*/data.json` (plugin settings, not code), `themes/Catppuccin/` + `themes/AnuPpuccin/`, `snippets/settings-nav-contrast.css`. Plugin code (`main.js`, `manifest.json`, `styles.css`) is gitignored and re-downloaded by Obsidian.
- `claude/` — `.claude/CLAUDE.md` (global instructions), `.claude/skills/{commit,pr,fix-issue,simplify,test}/SKILL.md` (global skills: commit, PR, fix-issue, simplify, test), `.claude/statusline.sh` (Catppuccin Mocha powerline status line for Claude Code)
- `eza/` — `.config/eza/theme.yml` (Catppuccin Mocha theme)
- `yazi/` — `.config/yazi/theme.toml`, `.config/yazi/Catppuccin-mocha.tmTheme`
- `skhd/` — `.config/skhd/skhdrc` (Hyper key app launchers: t=Ghostty, b=Brave, o=Obsidian, s=Spotify)
- `karabiner/` — `.config/karabiner/assets/complex_modifications/hyper.json` (Caps Lock → Hyper held / Escape tap; `karabiner.json` is intentionally unmanaged — Karabiner atomically rewrites it)
- `pi/` — `.pi/agent/themes/catppuccin-mocha.json` (Catppuccin Mocha theme for pi-agent UI); `.pi/agent/extensions/powerline/` (TypeScript powerline extension: Catppuccin Mocha footer showing model name, git branch + dirty state, active tool, active subagent, cost/context bar + session duration); `.pi/agent/agents/explore.md`, `planner.md`, `worker.md`, `reviewer.md` (declarative subagents with YAML frontmatter)
- `opencode/` — `.config/opencode/opencode.json` (model: anthropic/claude-sonnet-4-6, autoupdate: false); `.config/opencode/tui.json` (built-in catppuccin theme)

### Claude Code status line
- File: `stow/claude/.claude/statusline.sh` (stowed to `~/.claude/statusline.sh`).
- Activated via the `statusLine` key in `~/.claude/settings.json`.
- Single powerline-style line with four segments: model name, git branch + dirty indicator, context usage bar + session cost, vim mode pill.
- Colors: Catppuccin Mocha truecolor — Blue for model name, Green for clean git branch and INSERT mode pill, Yellow for dirty git branch and NORMAL mode pill, Mauve for context % bar and session cost. Vim mode pill is omitted when vim mode is not active.
- Git status is cached per directory at `/tmp/statusline-git-cache-<dir>` with a 5-second TTL to avoid repeated subprocess calls on every render.

### Pi-agent (`stow/pi/`)
- Theme: `~/.pi/agent/themes/catppuccin-mocha.json` — 51-token Catppuccin Mocha theme for pi-agent TUI; activated via `theme: "catppuccin-mocha"` in `~/.pi/agent/settings.json`.
- Powerline extension: `~/.pi/agent/extensions/powerline/` — TypeScript extension (no build step) with five segments: model name (blue), git branch + dirty indicator (green/yellow), active tool name (teal, hidden when idle), active subagent name (peach, hidden when idle), cost + context bar + duration (mauve). All hooks wrapped in try/catch; extension errors never propagate to the session.
- Subagents: four declarative markdown agents with YAML frontmatter; invoked manually in sequence:
  - `explore.md` — claude-haiku-4-5, tools: read/grep/find/ls, read-only codebase navigator
  - `planner.md` — claude-sonnet-4-6, tools: read/grep/find/ls/bash, produces structured implementation plans
  - `worker.md` — claude-sonnet-4-6, full tools, executes plans produced by planner
  - `reviewer.md` — claude-sonnet-4-6, tools: read/grep/find/ls, read-only code reviewer; returns structured verdict

## macOS app config linking
- Zed settings symlinked from `~/.config/zed/settings.json` to `~/Library/Application Support/Zed/settings.json`. Zed keymap similarly linked (`keymap.json`).
- Obsidian settings symlinked similarly. Config is seeded with `{}` if missing (required by basalt-tui).

## Repo hygiene
- `.gitignore` covers macOS files, editor dirs, `.env`, `.secrets`, backups.
- `README.md` with usage, structure, and customization notes.
- `CLAUDE.md` / `AGENTS.md` — agent instructions for Claude Code and Codex to keep docs in sync.
- `scripts/export-zed-extensions.sh` for syncing installed Zed extensions.
- `scripts/restow.sh` — re-applies all stow packages after a pull (`stow --restow` on every package under `stow/`).
- `scripts/skip-worktree.sh` for managing local skip-worktree paths (stored in `.local/skip-worktree.paths`).
- `tests/` — bats-core test suite (structure, syntax, bootstrap dry-run). CI via `.github/workflows/ci.yml` on push/PR to main.
- `man/man7/mac-setup.7` — custom man page (`man mac-setup`); symlinked into Homebrew's man path during bootstrap. Includes zellij keybinds reference (resize, move, pane, custom).
- `docs/guides/` — usage guides for tools (zellij, shell, git) and workflows (theming, customization, bootstrap). Linked from README and man page.

## Commands used often
- Run setup: `./setup.sh`
- Dry run: `./setup.sh --dry-run`
- Hard reset (repo wins): `./setup.sh --hard-reset`
- Verbose brew: `DEBUG=true ./setup.sh`
- Re-apply specific stow package: `(cd stow && stow --target="$HOME" --restow <package>)`

## Notable implementation notes
- Stow conflicts happen when target files already exist and are not symlinks.
- Default mode handles this with `--adopt`: stow pulls the real file into the repo, bootstrap commits the drift, then the symlink is created. Existing configs are preserved.
- `--hard-reset` mode handles this by moving conflicts into backup before stowing (old behavior).
- Dry-run mode reports intended actions but does not perform filesystem moves.
- gcloud-cli is installed in a separate step after mise python to set CLOUDSDK_PYTHON.
- docker-desktop is skipped in `brew bundle` and installed separately; bootstrap pre-creates `/usr/local/cli-plugins` (requires sudo) for docker-compose linking.
- App Store installs prompt for authentication if not signed in.
- Git config uses `git-delta` as pager, 1Password SSH signing (`gpgSign`/`op-ssh-sign`), and Git LFS filters. `user.name`, `user.email`, and `user.signingkey` are omitted from tracked config (set per-machine in `~/.gitconfig.local`). `core.excludesfile` points to `~/.gitignore` (stow-managed global gitignore). `pull.rebase = true` (rebase on pull), `branch.autoSetupMerge = always` (auto-track remote branches).

## Current state
- Repo is pushing successfully to `origin/main`.
- Setup is idempotent and rerunnable.
- Catppuccin Mocha theme consistent across all configured tools.
- Prompt, terminal, shell, and package bootstrap are all configured.
