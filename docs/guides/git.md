# Git

Git configuration with delta pager, config split, and custom aliases.

## Config split

Git config is split between a tracked file and a local override:

| File | Managed by | Contains |
|------|-----------|----------|
| `~/.gitconfig` | Stow (`stow/git/.gitconfig`) | Editor, pager, aliases, LFS, merge/diff settings |
| `~/.gitconfig.local` | Bootstrap / manual | `user.name`, `user.email`, credential helpers |

The tracked config includes the local file via:

```ini
[include]
  path = ~/.gitconfig.local
```

This lets you share the same repo across machines while keeping identity separate.

### Setting up `.gitconfig.local`

The bootstrap prompts for `user.name` and `user.email` if not already set. To set them manually:

```sh
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

## Delta pager

[delta](https://github.com/dandavella/delta) provides syntax-highlighted diffs with line numbers.

Key settings in `.gitconfig`:

```ini
[core]
  pager = delta
[interactive]
  diffFilter = delta --color-only
[delta]
  navigate = true
[merge]
  conflictstyle = diff3
[diff]
  colorMoved = default
```

### Navigate mode

With `navigate = true`, you can jump between diff sections in the pager using `n` (next) and `N` (previous).

## SSH key management

### Bootstrap generation

The bootstrap generates an ed25519 SSH key at `~/.ssh/id_ed25519` if one does not exist. It uses your git email as the key comment.

### GitHub upload

After generating the key, the bootstrap uploads it to GitHub via `gh ssh-key add`. It:
1. Authenticates with `gh auth login` if needed
2. Checks the key fingerprint to avoid uploading duplicates
3. Names the key `mac-setup <hostname> <date>`

### SSH config

The stow-managed `~/.ssh/config` configures the 1Password agent and includes a local override file:

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Include config.local
```

Add machine-specific hosts to `~/.ssh/config.local` (not tracked):

```
Host myserver
  HostName 192.168.1.100
  User deploy
```

## Custom aliases

Defined in the tracked `.gitconfig`:

| Alias | Command | What it does |
|-------|---------|-------------|
| `delete-local-merged` | `git fetch && git branch --merged \| egrep -v 'master\|dev\|main\|staging' \| xargs git branch -d` | Deletes local branches already merged into the current branch |
| `branches` | `git for-each-ref --sort=-committerdate ...` | Lists remote branches by most recent commit, with author and relative date |
| `praise` | `git blame` | Alias for `blame` with a friendlier name |

Usage:

```sh
git delete-local-merged   # clean up after merging PRs
git branches              # see who's been working on what
git praise README.md      # who wrote this line?
```

## Global gitignore

The tracked `~/.gitignore` (via `stow/git/.gitignore`) covers:

- **macOS:** `.DS_Store`, `._*`
- **Environment/secrets:** `.env`, `**/svcacct.json`
- **AI tooling:** `.claude/`, `CLAUDE.md`, `*.plan.md`, `.specstory/`, cursor dirs, `.todos/`
- **Sidecar:** `.sidecar/`, `.sidecar-*`, `.td-root`
- **Misc:** `.overcommit*`, `Pipfile`

Referenced via:

```ini
[core]
  excludesfile = ~/.gitignore
```

## Git LFS

Git LFS is configured in `.gitconfig`:

```ini
[filter "lfs"]
  required = true
  clean = git-lfs clean -- %f
  smudge = git-lfs smudge -- %f
  process = git-lfs filter-process
```

Track large files with:

```sh
git lfs track "*.psd"
git add .gitattributes
```

## Other settings

| Setting | Value | Effect |
|---------|-------|--------|
| `init.defaultBranch` | `main` | New repos use `main` instead of `master` |
| `pull.rebase` | `true` | Pull uses rebase instead of merge |
| `branch.autoSetupMerge` | `always` | New branches auto-track their remote |
| `push.autoSetupRemote` | `true` | First push auto-tracks the upstream branch |
| `fetch.prune` | `true` | Removes stale remote-tracking branches on fetch |
