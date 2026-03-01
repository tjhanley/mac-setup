# Git

Git configuration with delta pager, 1Password SSH signing, config split, and custom aliases.

## Config split

Git config is split between a tracked file and a local override:

| File | Managed by | Contains |
|------|-----------|----------|
| `~/.gitconfig` | Stow (`stow/git/.gitconfig`) | Editor, pager, aliases, signing program, LFS, merge/diff settings |
| `~/.gitconfig.local` | Bootstrap / manual | `user.name`, `user.email`, `user.signingkey`, credential helpers |

The tracked config includes the local file via:

```ini
[include]
  path = ~/.gitconfig.local
```

This lets you share the same repo across machines while keeping identity and signing keys separate.

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

## 1Password SSH signing

All commits are signed using your SSH key via 1Password's `op-ssh-sign` binary. This is configured in the tracked `.gitconfig`:

```ini
[commit]
  gpgSign = true
[gpg]
  format = ssh
[gpg "ssh"]
  program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

The signing key itself is stored in `~/.gitconfig.local`:

```ini
[user]
  signingkey = ssh-ed25519 AAAA... you@example.com
```

### How it works

1. When you commit, git calls `op-ssh-sign` instead of `gpg`
2. 1Password's SSH agent presents the key for signing
3. 1Password prompts for biometric/PIN approval
4. The commit is signed with your SSH key

### Setup

1. Install 1Password and enable the SSH agent: Settings > Developer > SSH Agent
2. Make sure `~/.ssh/config` has the 1Password agent socket (handled by stow):
   ```
   Host *
     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```
3. Set your signing key in `~/.gitconfig.local`:
   ```sh
   git config --file ~/.gitconfig.local user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
   ```

### Verifying signing works

```sh
echo "test" | git commit-tree HEAD^{tree} -m "test signing"
# 1Password should prompt for approval
```

Or just make a commit -- if it succeeds without errors, signing is working.

### Troubleshooting

**"error: gpg failed to sign the data"**
- Check that 1Password is running and the SSH agent is enabled
- Verify the socket exists: `ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- Make sure `op-ssh-sign` is present: `ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign`

**Commits succeed but are not marked as verified on GitHub**
- Upload your SSH key as a "Signing Key" (not just "Authentication Key") in GitHub settings
- Go to github.com > Settings > SSH and GPG keys > New SSH key > Key type: Signing key

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
