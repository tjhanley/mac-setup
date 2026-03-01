# Shell

Zsh configuration with history, completions, fzf, navigation, aliases, and plugins.

All shell config lives in `stow/zsh/.zshrc` and `stow/zsh/.zprofile`.

## History

| Setting | Value | Effect |
|---------|-------|--------|
| `HISTFILE` | `~/.local/state/zsh/history` | XDG-compliant location |
| `HISTSIZE` | 50000 | Lines kept in memory |
| `SAVEHIST` | 50000 | Lines saved to disk |
| `share_history` | on | All open shells share the same history |
| `hist_ignore_dups` | on | Skip consecutive duplicate entries |
| `hist_ignore_space` | on | Commands starting with a space are not recorded |
| `hist_reduce_blanks` | on | Remove extra whitespace from history entries |
| `append_history` | on | Append rather than overwrite the history file |

Prefix a command with a space to keep it out of history (useful for commands containing tokens).

## Shell options

| Option | What it does |
|--------|-------------|
| `auto_cd` | Type a directory name to cd into it (`../foo` instead of `cd ../foo`) |
| `extended_glob` | Advanced glob patterns (`#`, `~`, `^`) |
| `correct` | Suggests corrections for mistyped commands |

## Completion system

Completions are initialized with `compinit` using a cached dump file at `~/.cache/zsh/zcompdump-$ZSH_VERSION`.

### CLI completions

Tool-specific completions are generated once and cached to `~/.cache/zsh/completions/`:

- kubectl, docker, mise, gh, rustup, cargo

Completions for gcloud, fzf, and yazi are sourced at shell startup from their respective SDK/plugin paths.

### Completion styling

```zsh
zstyle ':completion:*' menu select             # interactive menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # colorized candidates
```

### fzf-tab

The [fzf-tab](https://github.com/Aloxaf/fzf-tab) plugin replaces the default completion menu with an fzf-powered fuzzy selector. It is loaded from Homebrew after `compinit`.

## Navigation

### zoxide

[zoxide](https://github.com/ajeetdsouza/zoxide) provides smart `cd` by tracking visited directories. Initialized in `.zshrc` via `zoxide init zsh`.

```sh
z foo       # jump to most-visited directory matching "foo"
zi foo      # interactive selection with fzf
```

### Dot aliases

```sh
..          # cd ..
...         # cd ../..
....        # cd ../../..
.....       # cd ../../../..
```

Combined with `auto_cd`, you can also type bare paths like `../foo` to navigate.

## File listing (eza)

[eza](https://github.com/eza-community/eza) replaces `ls` with Nerd Font icons and git integration, themed with Catppuccin Mocha via `~/.config/eza/theme.yml`.

| Alias | Command | Shows |
|-------|---------|-------|
| `ls` | `eza --group-directories-first --icons=auto` | Simple listing, dirs first |
| `ll` | `eza -la --group-directories-first --icons=auto --git --header --time-style=relative` | Long format with git status, relative timestamps |
| `la` | `eza -a --group-directories-first --icons=auto` | All files including hidden |
| `lt` | `eza --tree --level=2 --icons=auto --git --git-ignore` | Tree view (2 levels, respects .gitignore) |
| `l` | `ls -lah` | Fallback long listing |

## yazi

[yazi](https://github.com/sxyazi/yazi) is a terminal file manager. The `y` wrapper function launches yazi and changes your shell's working directory to wherever you navigated when you quit:

```sh
y            # open yazi; cd to last location on exit
y ~/Projects # open yazi in a specific directory
```

## FZF

[fzf](https://github.com/junegunn/fzf) provides fuzzy finding for files, history, and completions.

Initialized via `fzf --zsh` which enables:
- `Ctrl+r` -- fuzzy history search
- `Ctrl+t` -- fuzzy file finder (inserts path)
- `Alt+c` -- fuzzy cd into subdirectory

Colors use the Catppuccin Mocha palette via `FZF_DEFAULT_OPTS`.

## Aliases

### Git (OMZ-style)

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gb` | `git branch` |
| `gba` | `git branch --all` |
| `gc` | `git commit` |
| `gcmsg` | `git commit -m` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gf` | `git fetch` |
| `gl` | `git pull` |
| `gp` | `git push` |
| `gpf` | `git push --force-with-lease` |
| `glog` | `git log --oneline --graph --decorate` |
| `gloga` | `git log --oneline --graph --decorate --all` |
| `grb` | `git rebase` |
| `grbi` | `git rebase -i` |
| `gst` | `git status` |
| `gsw` | `git switch` |
| `gswc` | `git switch -c` |

### Tools

| Alias | Expands to |
|-------|-----------|
| `lg` | `lazygit` |
| `zj` | `zellij` |
| `zja` | `zellij attach -c main` |
| `d` | `docker` |
| `lzd` | `lazydocker` |
| `y` | yazi (cwd-on-exit wrapper) |
| `cc` | `claude` |
| `cx` | `codex` |
| `k` | `kubectl` |
| `gal` | `gcloud auth login` |
| `spotify` | `open -a Spotify` |

### Shell

| Alias | Expands to |
|-------|-----------|
| `cat` | `bat` (when installed) |
| `vim`, `vi` | `nvim` |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `.....` | `cd ../../../..` |

## Plugins

Loaded last in `.zshrc` to avoid conflicts:

| Plugin | Source | What it does |
|--------|--------|-------------|
| zsh-autosuggestions | Homebrew | Fish-like inline suggestions based on history |
| zsh-syntax-highlighting | Homebrew | Real-time syntax coloring at the prompt |
| fzf-tab | Homebrew | Replaces default completion menu with fzf |

## PATH management

PATH entries are added with a `path_prepend_unique` helper that avoids duplicates:

1. Homebrew (`/opt/homebrew/bin` or `/usr/local/bin`) -- via `brew shellenv`
2. `~/.cargo/bin` -- Rust toolchain
3. `~/.local/bin` -- mise shims, pipx, user scripts

## Environment variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `EDITOR` | `nvim` | Default editor |
| `VISUAL` | `nvim` | Visual editor |
| `ZELLIJ_CONFIG_DIR` | `~/.config/zellij` | Zellij config location |
| `RIPGREP_CONFIG_PATH` | `~/.ripgreprc` | ripgrep config |
| `FZF_DEFAULT_OPTS` | Catppuccin colors | FZF color scheme |
| `CLOUDSDK_PYTHON` | mise python path | Python for gcloud SDK |

## Machine-specific config

Create `~/.secrets` for tokens, API keys, or machine-specific overrides. It is sourced at the end of `.zshrc` if it exists:

```sh
# ~/.secrets (not tracked in git)
export GITHUB_TOKEN="ghp_..."
export AWS_PROFILE="work"
```

This file is in `.gitignore` and will never be committed.
