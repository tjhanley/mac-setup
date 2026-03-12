# mac-setup

Opinionated macOS bootstrap using:
- Homebrew + Brewfile
- GNU Stow for dotfiles
- `mise` for runtimes (node, python, ruby, go)
- Rust + Cargo (Homebrew `rust`, with `rustup` toolchain management)
- Catppuccin Mocha theming across Ghostty, Zellij, Starship, Zed, Yazi, bat, lazygit, eza, and FZF

## Disclaimer

This project is provided as-is with no warranty. It modifies system settings,
installs software, and overwrites configuration files. Review the scripts before
running them and use at your own risk. See [LICENSE](LICENSE) for details.

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

Hard reset (repo wins — backs up and overwrites local configs):

```sh
./setup.sh --hard-reset
```

## Documentation

Practical usage guides live in [`docs/guides/`](docs/guides/):

- [Zellij](docs/guides/zellij.md) -- keybinds, launcher, zjstatus bar, scripts
- [Shell](docs/guides/shell.md) -- aliases, completions, fzf, navigation, plugins
- [Git](docs/guides/git.md) -- delta pager, 1Password signing, config split
- [Theming](docs/guides/theming.md) -- Catppuccin Mocha setup, re-theming with Claude Code
- [Customization](docs/guides/customization.md) -- adding packages, stow modules, runtimes
- [Bootstrap](docs/guides/bootstrap.md) -- understanding and troubleshooting setup.sh

See also: `man mac-setup` for the full system reference.

## What It Does

1. Installs Xcode Command Line Tools and accepts license (if needed)
2. Installs Homebrew (if missing)
3. Installs packages/apps from `brew/Brewfile` (except `gcloud-cli` and `docker-desktop` in initial pass)
4. Ensures `~/.config` exists
5. Creates `.env` from `.env.example` if missing
6. Stows dotfiles from `stow/` into `$HOME` using merge-first mode: adopts any local drift into the repo and commits it, then symlinks (nvim stowed separately — see step 13); use `--hard-reset` to get the old pave behavior (backup + overwrite)
7. Installs private fonts from iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/fonts/`)
8. Prompts for `git user.name` and `user.email` only if missing from effective git config (stores entries in `~/.gitconfig.local`)
9. Generates SSH key (ed25519) if missing and uploads to GitHub via `gh`
10. Verifies git commit signing (1Password SSH agent, signing key)
11. Clones Ghostty shaders to `~/.local/share/ghostty/shaders/` (avoids writing into stow-managed repo paths)
12. Links macOS app configs (Zed settings + keymap, Obsidian) to stow-managed paths
13. Installs LazyVim starter (if no existing `~/.config/nvim`)
14. Ensures LazyVim loads repo-managed local options (`pcall(require, "config.local")`)
15. Stows Neovim plugin configs (Ghostty plugins) into LazyVim, moving known plugin-file conflicts to backup first
16. Downloads zjstatus Zellij status-bar plugin (`zjstatus.wasm`)
17. Installs runtimes via `mise` from stow-managed `~/.config/mise/config.toml` only (with extended remote-fetch timeout + one retry)
18. Installs `gcloud-cli` using `mise` Python
19. Installs `docker-desktop` (pre-creates `/usr/local/cli-plugins` for docker-compose)
20. Installs App Store apps (CopyLess 2, Magnet) via `mas`
21. Installs Rust via `rustup-init`
22. Installs Cargo tools (`basalt-tui`) via `cargo-binstall`
23. Configures keyboard repeat speed (`InitialKeyRepeat=10`, `KeyRepeat=1`, `ApplePressAndHoldEnabled=false`)
24. Prunes old backups in `~/config-backups/`, keeping the 3 most recent

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
    .config/zellij/scripts/cpu.sh            # CPU usage for zjstatus
    .config/zellij/scripts/mem.sh            # memory usage for zjstatus
    .config/zellij/scripts/launcher.sh       # fzf app picker for Super+Shift+l
  mise/
    .config/mise/config.toml
  zed/
    .config/zed/settings.json
    .config/zed/keymap.json                    # arrow keys disabled in vim modes
  nvim/
    .config/nvim/lua/config/local.lua      # repo-managed local options (loaded by LazyVim options.lua)
    .config/nvim/lua/config/keymaps.lua   # arrow keys disabled in n/i/v modes
    .config/nvim/lua/plugins/ghostty.lua  # stowed after LazyVim install
  obsidian/
    .config/obsidian/obsidian.json
    necronomicon/.obsidian/          # vault config (symlinked into ~/necronomicon)
      app.json, appearance.json, hotkeys.json, ...
      plugins/*/data.json            # plugin settings (not code)
      themes/Catppuccin/, themes/AnuPpuccin/
      snippets/settings-nav-contrast.css
  claude/
    .claude/CLAUDE.md                    # global Claude Code instructions
    .claude/skills/commit/SKILL.md       # imperative commit with co-author
    .claude/skills/pr/SKILL.md           # PR with summary + test plan
    .claude/skills/fix-issue/SKILL.md    # read issue, fix, test, commit
    .claude/skills/simplify/SKILL.md     # review changed code, simplify, fix issues
    .claude/skills/test/SKILL.md         # run tests, diagnose and fix failures
    .claude/statusline.sh                # Catppuccin Mocha powerline status line for Claude Code
  eza/
    .config/eza/theme.yml                # Catppuccin Mocha theme
  yazi/
    .config/yazi/theme.toml
    .config/yazi/Catppuccin-mocha.tmTheme
```

## CLI Tools

Installed via Homebrew: awscli, bat, bats-core, btop, cargo-binstall, duf, dust, eza,
fastfetch, fd, fzf, fzf-tab, gh, git, git-delta, git-lfs, glow, imagemagick, jq, k9s,
kubectl, lazydocker, lazygit, mas, mise, neovim, ripgrep, rust, rustup-init, starship,
stern, stow, tldr, trash, tree-sitter-cli, typescript, wget, yazi, zellij, zoxide,
zsh-autosuggestions, zsh-syntax-highlighting

Casks: 1password, brave-browser, codex, docker-desktop, gcloud-cli, ghostty, obsidian,
raycast, spotify, zed, font-blex-mono-nerd-font, font-jetbrains-mono-nerd-font

Cargo tools: basalt-tui (Obsidian vault TUI)

Claude Code: installed via the official standalone installer (`~/.local/bin/claude`), not Homebrew.

Shell completions: kubectl, docker, mise, gh, stern, rustup, cargo, gcloud, fzf, yazi

## Man Page

A full system reference is available as a man page:

```sh
man mac-setup
```

Covers bootstrap steps, stow packages, git/tool/shell aliases, completions,
shell options, git config, runtimes, theme, files, and common tasks.

## License

[MIT](LICENSE)

## Notes

- Re-running the script is safe and idempotent.
- Backups live in `~/config-backups/` (timestamped).
- Open Ghostty, Raycast, Zed once after install if you use them.

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
- Re-apply all stow packages after a pull:
  `./scripts/restow.sh`
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
