# Bootstrap

Understanding, running, and troubleshooting `setup.sh`.

## Invocation

```sh
# Normal run
./setup.sh

# Dry run (show what would happen without changing anything)
./setup.sh --dry-run

# Verbose Homebrew output
DEBUG=true ./setup.sh
```

The script requires `sudo` early on for Xcode license acceptance and Homebrew binary conflict resolution. You will be prompted once at the start.

## Step-by-step breakdown

The bootstrap runs 24 steps in order. Each step is idempotent -- it checks whether work has already been done before acting.

### 1. Xcode Command Line Tools

Checks `xcode-select -p`. If missing, runs `xcode-select --install` and waits for the GUI installer to finish. Accepts the license with `sudo xcodebuild -license accept`.

### 2. Homebrew

Checks for `brew` in PATH. If missing, installs via the official install script. Detects Apple Silicon (`/opt/homebrew`) vs Intel (`/usr/local`) automatically.

### 3. Homebrew refresh

Runs `brew update` and `brew upgrade` on every invocation to keep packages current.

### 4. Ensure `~/.config`

Creates `~/.config` if it does not exist. Required before stowing dotfiles.

### 5. Create `.env`

Copies `.env.example` to `.env` if the `.env` file does not exist. Used for shared environment variables.

### 6. Prepare binary conflicts

Handles known conflicts before `brew bundle`:
- Docker Desktop's `/usr/local/bin/kubectl` symlink (conflicts with Homebrew kubectl)
- Pre-existing `/usr/local/bin/codex` binary (conflicts with codex cask)

Conflicting files are moved to `~/config-backups/bin-conflicts/`.

### 7. Brewfile

Runs `brew bundle --file=brew/Brewfile`. Skips `gcloud-cli` and `docker-desktop` (installed in later steps that handle their prerequisites).

### 8. Stow dotfiles

Backs up existing config files to `~/config-backups/`, moves stow conflicts, then stows all packages under `stow/` (except `nvim`) into `$HOME`. See [Conflict resolution](#conflict-resolution) for details.

### 9. Man page

Symlinks `man/man7/mac-setup.7` into Homebrew's man path so `man mac-setup` works.

### 10. Private fonts

Copies `.ttf`/`.otf` files from `~/Library/Mobile Documents/com~apple~CloudDocs/fonts/` to `~/Library/Fonts/`. Skips already-installed fonts. Warns if the iCloud fonts folder does not exist.

### 11. Git identity

Prompts for `git user.name` and `user.email` if not already configured. Stores values in `~/.gitconfig.local` (included by the tracked `.gitconfig`).

### 12. SSH key

Generates an ed25519 SSH key at `~/.ssh/id_ed25519` if missing. Uses the git email as the key comment. Uploads the public key to GitHub via `gh ssh-key add` (authenticates first if needed, checks fingerprint to avoid duplicates).

### 13. Commit signing

Verifies 1Password SSH signing is ready:
- Checks for `op-ssh-sign` binary
- Checks for the 1Password SSH agent socket
- Sets `user.signingkey` in `~/.gitconfig.local` from the public key if not already configured

### 14. Ghostty shaders

Clones `hackr-sh/ghostty-shaders` to `~/.local/share/ghostty/shaders/` (avoids writing into stow-managed repo paths). Migrates legacy installs from `~/.config/ghostty/shaders/` if found. Shader files are available but commented out in the Ghostty config by default.

### 15. macOS app config linking

Symlinks stow-managed configs into macOS app locations:
- `~/.config/zed/settings.json` -> `~/Library/Application Support/Zed/settings.json`
- `~/.config/obsidian/obsidian.json` -> `~/Library/Application Support/obsidian/obsidian.json`

Seeds the Obsidian config with `{}` if it does not exist (required by basalt-tui).

### 16. LazyVim

Clones the [LazyVim starter](https://github.com/LazyVim/starter) to `~/.config/nvim` if no existing config is found. Removes the `.git` directory so it is not a nested repo. Skips if `~/.config/nvim` already exists.

### 17. LazyVim local options

Ensures LazyVim's `lua/config/options.lua` includes `pcall(require, "config.local")` so it loads repo-managed local options from the stow package.

### 18. Neovim plugins

Stows the `nvim` package separately (after LazyVim install to avoid directory conflicts). Moves known plugin-file conflicts into backup first. Also ensures LazyVim extras like `claudecode` are present in `lazyvim.json`.

### 19. zjstatus

Downloads `zjstatus.wasm` from GitHub releases to `~/.config/zellij/plugins/`. The status bar layout in `layouts/default.kdl` references this plugin.

### 20. Runtimes (mise)

Runs `mise install` to install runtimes from `~/.config/mise/config.toml`: node 22, python 3.13, ruby 3.4, go 1.24. Uses an extended remote-fetch timeout with one retry.

### 21. gcloud CLI

Installs the `gcloud-cli` cask with `CLOUDSDK_PYTHON` set to mise's python. This step runs after mise so that a working Python is available.

### 22. Docker Desktop

Pre-creates `/usr/local/cli-plugins` (for docker-compose linking), cleans stale Docker binaries from previous installs, then installs the `docker-desktop` cask.

### 23. App Store apps

Installs CopyLess 2 and Magnet via `mas`. Prompts for App Store sign-in if not authenticated.

### 24. Rust and Cargo tools

Installs Rust via `rustup-init` if not already present. Then installs Cargo tools (`basalt-tui`) via `cargo-binstall` (falls back to `cargo install`).

### Cleanup

Prunes old backups in `~/config-backups/`, keeping the 3 most recent.

## Conflict resolution

When stowing dotfiles, existing (non-symlink) files at target paths would cause stow to abort. The bootstrap handles this by:

1. **Backing up** existing configs to `~/config-backups/dotfiles-<timestamp>/`
2. **Moving conflicts** out of the way before stowing
3. Skipping paths that already point into the repo (no double-backup)

This means your existing configs are preserved and can be recovered from the backup directory.

## Backup and restore

### Backup location

```
~/config-backups/
  dotfiles-20260301-143022/
    .zshrc
    .gitconfig
    .config/
      ...
  dotfiles-20260228-091500/
    ...
```

### What gets backed up

All config files that stow would overwrite: `.zshrc`, `.zprofile`, `.gitconfig`, `.gitignore`, `.ssh/config`, `.ripgreprc`, and everything under `.config/` for bat, lazygit, nvim, starship, ghostty, zellij, mise, zed, obsidian, yazi, raycast.

Binary conflicts (Docker kubectl, codex) go to `bin-conflicts/` within the backup.

### Manual restore

```sh
# List available backups
ls ~/config-backups/

# Restore a specific file
cp ~/config-backups/dotfiles-20260301-143022/.zshrc ~/.zshrc

# Restore everything from a backup
cp -a ~/config-backups/dotfiles-20260301-143022/. ~/
```

### Pruning

The bootstrap automatically keeps only the 3 most recent backups. Older ones are deleted at the end of each run.

## Dry-run mode

`./setup.sh --dry-run` shows what each step would do without making changes:

- File operations print `dry-run: move/copy/link ...` instead of executing
- `brew bundle check` reports missing dependencies without installing
- `stow -n` simulates stowing without creating symlinks
- Interactive prompts (git identity, SSH key) are skipped

Dry-run is useful for understanding what the script does before committing to a full run.

## Function reference

| Function | Step | Purpose |
|----------|------|---------|
| `ensure_xcode_clt` | 1 | Xcode Command Line Tools |
| `ensure_homebrew` | 2 | Install Homebrew |
| `refresh_homebrew` | 3 | Update and upgrade |
| `ensure_config_dir` | 4 | Create `~/.config` |
| `ensure_local_env_file` | 5 | Create `.env` from template |
| `prepare_brew_binary_conflicts` | 6 | Handle kubectl/codex conflicts |
| `install_brew_bundle` | 7 | Brewfile install |
| `stow_dotfiles` | 8 | Backup + stow |
| `install_man_page` | 9 | Symlink man page |
| `install_icloud_fonts` | 10 | Copy private fonts |
| `ensure_git_identity` | 11 | Prompt for name/email |
| `ensure_ssh_key` | 12 | Generate + upload SSH key |
| `ensure_commit_signing` | 13 | Verify 1Password signing |
| `install_ghostty_shaders` | 14 | Clone shader repo |
| `configure_macos_app_links` | 15 | Symlink app configs |
| `install_lazyvim` | 16 | Clone LazyVim starter |
| `ensure_lazyvim_local_options` | 17 | Inject local options loader |
| `stow_nvim_plugins` | 18 | Stow nvim package |
| `install_zjstatus` | 19 | Download zjstatus.wasm |
| `install_mise_tools` | 20 | Install runtimes |
| `install_gcloud_cli` | 21 | Install gcloud with mise python |
| `install_docker_desktop` | 22 | Install Docker Desktop |
| `install_app_store_apps` | 23 | Install App Store apps |
| `install_rust` / `install_cargo_tools` | 24 | Rust + Cargo tools |
| `prune_old_backups` | -- | Keep 3 most recent backups |

## Troubleshooting

### Xcode Command Line Tools

**"xcode-select: error: command line tools are already installed"**

This is fine -- the step is idempotent. If the tools are installed but the license has not been accepted, `sudo xcodebuild -license accept` handles it.

### Homebrew PATH

**"brew: command not found" after install**

The script evals `brew shellenv` for both Apple Silicon and Intel paths. If brew is installed somewhere else, add it to your PATH before running the script.

### Stow conflicts

**"CONFLICT: ... existing target is neither a link nor a directory"**

The bootstrap handles this automatically by moving conflicts to backup. If you see this error, it means something went wrong with the backup step. Check that `~/config-backups/` is writable.

### SSH key upload

**"gh: not authenticated"**

The script calls `gh auth login` interactively. Follow the prompts to authenticate with GitHub.

**"SSH key already uploaded to GitHub"**

The script checks fingerprints before uploading. This message is normal on re-runs.

### 1Password signing

**"1Password not found" or "SSH agent socket not found"**

1. Install 1Password from the Mac App Store or Homebrew
2. Open 1Password > Settings > Developer > enable "SSH Agent"
3. Re-run the script

### LazyVim

**"Neovim config already looks like a git repo"**

You already have a Neovim config. The script will not overwrite it. If you want LazyVim, move your existing config aside:

```sh
mv ~/.config/nvim ~/.config/nvim.bak
./setup.sh
```

### mise

**"mise not found in PATH"**

Homebrew may not be in PATH yet. Run `eval "$(brew shellenv)"` or open a new terminal and try again.

### gcloud CLI

**"CLOUDSDK_PYTHON is not set"**

mise python is not installed yet. Fix with:

```sh
mise use -g python@3.13
mise install
```

### Docker Desktop

**"Docker Desktop install failed"**

Often caused by stale Docker binaries from a previous install. The script tries to clean these up, but you may need to manually remove leftovers:

```sh
sudo rm -f /usr/local/bin/docker*
brew install --cask docker-desktop
```

### App Store

**"App Store authentication required"**

Open the App Store app, sign in with your Apple ID, then press Enter to retry.

### Rust

**"rustup-init not found"**

Install via Homebrew: `brew install rustup-init`, then re-run the script.

## Re-running safety

The entire script is designed to be re-run at any time:

- Steps check for existing state before acting (idempotent)
- Already-installed packages are skipped
- Already-stowed symlinks are refreshed with `--restow`
- Backups are created on every run (old ones pruned automatically)
- No step destructively overwrites your data without backing up first
