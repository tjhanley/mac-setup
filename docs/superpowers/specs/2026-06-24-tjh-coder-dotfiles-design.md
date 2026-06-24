# tjh-coder-dotfiles — Design

Date: 2026-06-24
Status: Approved (pending spec review)

## Purpose

A standalone dotfiles repository for [Coder](https://coder.com) workspaces.
Coder's dotfiles feature clones a git repo into `~/.dotfiles` and auto-runs the
first install script it finds. This repo provides a Linux-focused install that
installs a curated CLI toolset, symlinks terminal configs via GNU Stow, and sets
zsh as the default shell.

It is deliberately separate from the `mac-setup` repo: Coder workspaces are Linux
containers, while `mac-setup` is macOS-specific (Homebrew, `bootstrap-mac.zsh`).
Config *content* is reused (adapted for Linux); the bootstrap logic is not.

## Coder dotfiles contract

`coder dotfiles <git-url>` clones to `~/.dotfiles`, then runs the first script in
this lookup order: `install.sh` → `install` → `bootstrap.sh` → `bootstrap` →
`setup.sh` → `setup` → `script/{bootstrap,install,setup}`. If none exist, it
symlinks every top-level dotfile into `$HOME`.

This repo uses **`install.sh`** at the root (first in the order). It is written in
**bash** (not zsh) because zsh may not be installed at first run.

## Repo structure

```
tjh-coder-dotfiles/
├── install.sh            # Coder entrypoint (bash, set -euo pipefail)
├── README.md
├── lib/
│   └── common.sh         # log/ok/warn helpers, DRY_RUN, pkg-manager detection
└── stow/
    ├── zsh/.zshrc
    ├── git/.gitconfig
    ├── starship/.config/starship.toml
    ├── nvim/.config/nvim/…
    ├── zellij/.config/zellij/…
    ├── bat/.config/bat/…
    ├── eza/.config/eza/…
    ├── ripgrep/.ripgreprc
    ├── yazi/.config/yazi/…
    ├── lazygit/.config/lazygit/…
    └── mise/.config/mise/…
```

## install.sh flow

Bash, `set -euo pipefail`, idempotent, honors `DRY_RUN=1` (print actions, do not
execute). Mirrors `mac-setup` conventions: `log()` step headers, `ok()` success,
`warn()` warnings, `run_cmd` wrapper for skippable commands.

1. **Guard** — confirm Linux (`uname -s` == Linux). On macOS, exit with a message
   pointing to `mac-setup`.
2. **Detect package manager** — `apt-get` / `dnf` / `apk` (Coder images are
   usually Ubuntu). Detect `sudo` availability; degrade gracefully if absent.
3. **Install tools** — two tiers because Ubuntu apt has gaps and binary renames:
   - **apt-native:** `git`, `zsh`, `stow`, `ripgrep`, `bat` (binary is `batcat`
     on Ubuntu → symlink `bat`), `fzf`.
   - **installer/binary fallback** (not reliably in apt): `starship` (official
     install script), `eza`, `lazygit`, `yazi`, `zoxide`, `neovim`, `mise`
     (official install script).
   - Every install is skipped if the tool is already on `PATH` (idempotent).
4. **Stow** — `stow --restow -t "$HOME" -d stow <pkg>` for each package.
   `--restow` keeps it idempotent across re-runs.
5. **Default shell** — if zsh isn't the current shell, `chsh -s "$(command -v zsh)"`.
   If `chsh` fails (no sudo / locked container), fall back to appending an
   `exec zsh` guard to `~/.bashrc`.

## Config adaptation

Configs are **vendored copies adapted for Linux**, not blind copies of the
`mac-setup` stow packages. Before committing, scan `.zshrc` and `.gitconfig` for
mac-isms and guard-with-OS-check or drop them:

- Homebrew `/opt/homebrew` paths
- `pbcopy` / `pbpaste`
- macOS-only aliases
- references to `skhd`, `ghostty`, `karabiner`

Packages explicitly **not** brought over: `ghostty`, `karabiner`, `skhd`,
`obsidian`, `zed`, `ssh`, `jiratui`, and the AI-tool configs `claude`, `pi`,
`opencode` (host-specific / contain auth).

## Error handling & testing

- Each step logs and continues where safe; hard-fail only on missing package
  manager.
- `DRY_RUN=1 ./install.sh` previews every action without executing.
- README documents testing in a throwaway container:
  `docker run -it ubuntu` → clone → `./install.sh`.

## Deployment: new-repo Jira-push bootstrapping

The target GitHub org enforces a push ruleset requiring a Jira key (e.g.
`ENGOPS-\d+`) on pushes. A brand-new empty repo hits a chicken-and-egg: the first
push to create `main` is gated.

**Workaround:** create the repo with the default branch initialized server-side so
no client push is needed for the first commit:

```
gh repo create <org>/tjh-coder-dotfiles --private --add-readme
```

GitHub writes the initial commit via the API, establishing `main` outside the push
ruleset. All subsequent work flows through a `ENGOPS-XXXX-<topic>` branch + PR with
the Jira key in the branch name / commit message, satisfying the rule normally.

Per repo policy, an ENGOPS Jira ticket must exist and be referenced in the PR title.

## Target org + auth account

**Resolved:** the repo lives in the **Sonatus org** (Coder is wired to the Sonatus
account only). The Jira-push ruleset applies — use the `--add-readme` bootstrap and
the `ENGOPS-XXXX-<topic>` branch + PR flow. `gh auth switch` to the
Sonatus-authorized account before any `gh` operation (note: differs from this
`mac-setup` repo, which uses the personal `tjhanley` account).

## Open items (resolve at implementation)

- Confirm the Coder workspace base image (Ubuntu assumed) to finalize the apt vs
  fallback tool split.
```

