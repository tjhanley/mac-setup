# Customization

How to extend and adapt this setup for your own use.

## Adding Homebrew packages

1. Edit `brew/Brewfile` and add your package:
   ```ruby
   brew "your-package"
   # or for GUI apps:
   cask "your-app"
   ```
2. Install it:
   ```sh
   brew bundle --file=brew/Brewfile
   ```

The bootstrap runs `brew bundle` on every invocation, so new entries are picked up automatically on the next run.

## Adding stow packages

Each stow package is a directory under `stow/` that mirrors `$HOME`. For example, to manage `~/.config/mytool/config.toml`:

1. Create the directory structure:
   ```sh
   mkdir -p stow/mytool/.config/mytool
   ```
2. Move or create your config file:
   ```sh
   mv ~/.config/mytool/config.toml stow/mytool/.config/mytool/config.toml
   ```
3. Stow it:
   ```sh
   cd stow && stow --target="$HOME" --restow mytool
   ```

The bootstrap stows all packages under `stow/` (except `nvim`, which is handled separately). New packages are picked up automatically.

### Re-stowing after changes

```sh
cd stow && stow --target="$HOME" --restow <package>
```

Or re-run `./setup.sh` to stow everything.

## Adding runtimes

Runtimes are managed by [mise](https://mise.jdx.dev/). The config lives at `stow/mise/.config/mise/config.toml`.

1. Add or update a version:
   ```toml
   [tools]
   node = "22"
   python = "3.13"
   your-tool = "latest"
   ```
2. Install:
   ```sh
   mise install
   ```

Current runtimes: node 22, python 3.13, ruby 3.4, go 1.24, lazydocker 0.24.4.

## Adding shell aliases

Edit `stow/zsh/.zshrc`. Follow the existing pattern of guarding aliases behind command existence checks:

```zsh
if command -v mytool >/dev/null 2>&1; then
  alias mt='mytool'
fi
```

Then re-stow: `cd stow && stow --target="$HOME" --restow zsh`

Or just `source ~/.zshrc` in your current shell.

## Adding Zellij launcher apps

Edit `stow/zellij/.config/zellij/scripts/launcher.sh` and add entries to the `commands` array:

```bash
commands=(
  "basalt"
  "claude"
  # ... existing entries ...
  "your-app"
  "your-app --some-flag"
)
```

Re-stow: `cd stow && stow --target="$HOME" --restow zellij`

The launcher opens selected apps in floating Zellij panes via `zellij run`.

## Exporting Zed extensions

To sync your locally installed Zed extensions into the tracked config:

```sh
./scripts/export-zed-extensions.sh
```

This updates `stow/zed/.config/zed/settings.json` with your current `auto_install_extensions` list. Commit the result to share extensions across machines.

## Managing local app state (skip-worktree)

Some tracked files contain local app state that you do not want to commit (e.g., Obsidian writes to its config file). Use `skip-worktree` to tell git to ignore local changes:

```sh
# Add a file to the managed list
./scripts/skip-worktree.sh add stow/obsidian/.config/obsidian/obsidian.json

# Apply skip-worktree to all managed paths
./scripts/skip-worktree.sh apply

# Check status (S = active)
./scripts/skip-worktree.sh status

# List all active skip-worktree paths
./scripts/skip-worktree.sh list

# Clear skip-worktree for managed paths
./scripts/skip-worktree.sh clear
```

Managed paths are stored in `.local/skip-worktree.paths`.

## Machine-specific secrets

Create `~/.secrets` for tokens, API keys, or machine-specific environment variables:

```sh
# ~/.secrets (not tracked in git)
export GITHUB_TOKEN="ghp_..."
export AWS_PROFILE="work"
export ANTHROPIC_API_KEY="sk-ant-..."
```

This file is sourced at the end of `.zshrc` if it exists. It is covered by `.gitignore` and will never be committed.

## Git config overrides

Machine-specific git settings go in `~/.gitconfig.local`:

```ini
[user]
  name = Your Name
  email = you@example.com
  signingkey = ssh-ed25519 AAAA...
```

This file is included by the tracked `.gitconfig` via `[include] path = ~/.gitconfig.local`.

## SSH config overrides

Machine-specific SSH hosts go in `~/.ssh/config.local`:

```
Host work-server
  HostName 10.0.0.50
  User deploy
  IdentityFile ~/.ssh/work_key

Host staging
  HostName staging.example.com
  User admin
```

This file is included by the stow-managed `~/.ssh/config` via `Include config.local`.

## Adding private fonts

Place `.ttf` or `.otf` files in iCloud Drive under `fonts/`:

```
~/Library/Mobile Documents/com~apple~CloudDocs/fonts/
  DankMono-Regular.ttf
  DankMono-Italic.ttf
```

The bootstrap copies them to `~/Library/Fonts/` on each run, skipping fonts that are already installed. This is useful for licensed fonts you cannot commit to a public repo.

## Shared environment variables

For non-secret environment variables shared across machines, edit `.env` (generated from `.env.example` by the bootstrap):

```sh
# .env
MY_VAR=value
```

This file is in `.gitignore`. The `.env.example` template is tracked and can serve as documentation for expected variables.
