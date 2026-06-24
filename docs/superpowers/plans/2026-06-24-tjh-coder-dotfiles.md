# tjh-coder-dotfiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Linux dotfiles repo (`tjh-coder-dotfiles`) that Coder workspaces clone and auto-run to install a curated CLI toolset, symlink terminal configs via GNU Stow, and set zsh as the default shell.

**Architecture:** A root `install.sh` (bash) is Coder's auto-run entrypoint. It sources `lib/common.sh` for logging / dry-run / package-manager detection, installs tools (apt-native tier + official-installer fallback tier), clones LazyVim starter, stows config packages from `stow/` into `$HOME`, and sets zsh as the login shell. Configs are vendored from `mac-setup` and adapted to strip macOS-isms.

**Tech Stack:** bash, GNU Stow, apt/dnf/apk, official install scripts (starship, mise), GitHub via `gh`.

## Global Constraints

- Target repo: **`tjhanley-snt/tjh-coder-dotfiles`** (personal namespace of the Sonatus account `tjhanley-snt`), private. `gh auth switch --user tjhanley-snt` before any `gh` command (NOT the personal `tjhanley` account this `mac-setup` repo uses). Coder is wired to this Sonatus account.
- No Jira-key push ruleset applies to a personal namespace: work directly on `main`, no feature branch, no PR. Commit messages use plain Conventional Commits (`feat:`, `docs:`, `chore:`) with no ticket prefix.
- `install.sh` and `lib/common.sh` are **bash** (zsh may be absent at first run). Both start with `set -euo pipefail`.
- Every function honors `DRY_RUN=1`: print the action with `warn`-style `dry-run:` prefix, do not execute.
- Every install/link step is idempotent — skip if already done.
- No emojis in code. Catppuccin Mocha theming preserved in configs.
- Local working clone lives at `~/Workspace/tjh-coder-dotfiles`.

---

### Task 1: Create the GitHub repo

**Files:**
- Local clone: `~/Workspace/tjh-coder-dotfiles/`

**Interfaces:**
- Produces: a cloned local repo on `main` with the remote established.

- [ ] **Step 1: Switch gh to the Sonatus account**

```bash
gh auth switch --user tjhanley-snt && gh auth status
```
Expected: active account is `tjhanley-snt`.

- [ ] **Step 2: Create the repo and clone it**

```bash
gh repo create tjhanley-snt/tjh-coder-dotfiles --private --clone \
  --description "Coder workspace dotfiles (Linux): stow configs + curated CLI toolset"
mv tjh-coder-dotfiles ~/Workspace/tjh-coder-dotfiles 2>/dev/null || true
cd ~/Workspace/tjh-coder-dotfiles
```
Expected: empty private repo created and cloned. Work happens directly on `main` (no push ruleset on a personal namespace).

- [ ] **Step 3: Confirm clone location**

```bash
cd ~/Workspace/tjh-coder-dotfiles && git remote -v
```
Expected: `origin` points to `tjhanley-snt/tjh-coder-dotfiles`.

> All remaining tasks operate inside `~/Workspace/tjh-coder-dotfiles`. Source configs are read from `~/Workspace/mac-setup/stow/<pkg>/`.

---

### Task 2: `lib/common.sh` — shared helpers

**Files:**
- Create: `lib/common.sh`
- Test: `lib/common.test.sh`

**Interfaces:**
- Produces: `log(msg)`, `ok(msg)`, `warn(msg)` (stderr, colorized); `DRY_RUN` (default 0); `run_cmd "<cmd...>"` (echo+skip when dry-run, else eval); `detect_pkg_mgr()` → echoes one of `apt|dnf|apk|none`; `SUDO` (set to `sudo` if non-root and available, else empty); `have(cmd)` → returns 0 if on PATH.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# lib/common.test.sh — run: bash lib/common.test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source lib/common.sh

fail() { echo "FAIL: $1"; exit 1; }

# have() detects an obviously-present binary and rejects a fake one
have sh        || fail "have sh should succeed"
! have __nope_binary__ || fail "have should reject missing binary"

# run_cmd in dry-run does NOT execute (no file created), prints a dry-run line
rm -f /tmp/ccdf_marker
DRY_RUN=1 run_cmd "touch /tmp/ccdf_marker" 2>&1 | grep -q "dry-run:" || fail "dry-run should print dry-run:"
[[ ! -e /tmp/ccdf_marker ]] || fail "dry-run must not execute the command"

# run_cmd with DRY_RUN=0 DOES execute
DRY_RUN=0 run_cmd "touch /tmp/ccdf_marker"
[[ -e /tmp/ccdf_marker ]] || fail "non-dry-run must execute"
rm -f /tmp/ccdf_marker

# detect_pkg_mgr returns a known token
case "$(detect_pkg_mgr)" in apt|dnf|apk|none) ;; *) fail "unknown pkg mgr token";; esac

echo "PASS"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash lib/common.test.sh`
Expected: FAIL — `lib/common.sh` does not exist yet (source error).

- [ ] **Step 3: Implement `lib/common.sh`**

```bash
#!/usr/bin/env bash
# Shared helpers for the Coder dotfiles installer.
# Safe to source from a script already running set -euo pipefail.

: "${DRY_RUN:=0}"

if [[ -t 2 ]]; then
  _C_BLUE=$'\033[34m'; _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_RESET=$'\033[0m'
else
  _C_BLUE=""; _C_GREEN=""; _C_YELLOW=""; _C_RESET=""
fi

log()  { printf '%s\n' "${_C_BLUE}==>${_C_RESET} $*" >&2; }
ok()   { printf '%s\n' "${_C_GREEN}ok:${_C_RESET} $*" >&2; }
warn() { printf '%s\n' "${_C_YELLOW}warn:${_C_RESET} $*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# run_cmd "<command string>" — eval it, or just print it under DRY_RUN.
run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s\n' "${_C_YELLOW}dry-run:${_C_RESET} $*" >&2
    return 0
  fi
  eval "$@"
}

detect_pkg_mgr() {
  if   have apt-get; then echo apt
  elif have dnf;     then echo dnf
  elif have apk;     then echo apk
  else echo none
  fi
}

# SUDO is empty when root or when sudo is unavailable.
if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
elif have sudo; then
  SUDO="sudo"
else
  SUDO=""
fi
export SUDO
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash lib/common.test.sh`
Expected: `PASS`

- [ ] **Step 5: Shellcheck**

Run: `shellcheck lib/common.sh` (install via `brew install shellcheck` if missing)
Expected: no errors (warnings about `eval` are acceptable for `run_cmd`).

- [ ] **Step 6: Commit**

```bash
git add lib/common.sh lib/common.test.sh
git commit -m "add shared installer helpers"
```

---

### Task 3: `install.sh` skeleton — guard, detect, orchestration stub

**Files:**
- Create: `install.sh` (chmod +x)
- Test: manual dry-run

**Interfaces:**
- Consumes: everything in `lib/common.sh`.
- Produces: `REPO_DIR` (absolute path to repo root), `STOW_DIR="$REPO_DIR/stow"`, `PKG_MGR`. Defines empty stubs `install_tools`, `stow_packages`, `install_nvim`, `set_default_shell` filled by later tasks. `main()` calls them in order.

- [ ] **Step 1: Implement the skeleton**

```bash
#!/usr/bin/env bash
# Coder dotfiles installer. Auto-run by `coder dotfiles`.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$REPO_DIR/stow"
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    warn "This installer targets Linux Coder workspaces. On macOS use the mac-setup repo."
    exit 1
  fi
}

install_tools()     { :; }   # Task 4
stow_packages()     { :; }   # Task 5
install_nvim()      { :; }   # Task 6 (nvim) / configs in Task 7-9
set_default_shell() { :; }   # Task 6 (shell)

main() {
  require_linux
  PKG_MGR="$(detect_pkg_mgr)"
  if [[ "$PKG_MGR" == "none" ]]; then
    warn "No supported package manager (apt/dnf/apk) found; cannot install tools."
    exit 1
  fi
  log "Package manager: $PKG_MGR"
  install_tools
  install_nvim
  stow_packages
  set_default_shell
  ok "Dotfiles install complete."
}

main "$@"
```

- [ ] **Step 2: Make executable + dry-run on this Mac to confirm the guard fires**

```bash
chmod +x install.sh
./install.sh; echo "exit=$?"
```
Expected: prints `warn: This installer targets Linux ...` and `exit=1` (proves the guard works; full run is tested in Docker in Task 10).

- [ ] **Step 3: Shellcheck + commit**

```bash
shellcheck install.sh
git add install.sh
git commit -m "add install.sh skeleton with Linux guard"
```

---

### Task 4: Tool installation

**Files:**
- Modify: `install.sh` (replace `install_tools` stub)

**Interfaces:**
- Consumes: `have`, `run_cmd`, `log`, `ok`, `warn`, `SUDO`, `PKG_MGR` from earlier.
- Produces: after this runs, `git zsh stow rg bat fzf starship eza lazygit yazi zoxide nvim mise` are on PATH (best effort).

- [ ] **Step 1: Replace the `install_tools` stub**

```bash
# apt package name -> the binary it provides (to skip if already present)
_apt_install() {
  local pkgs=() pkg bin
  for spec in "$@"; do
    pkg="${spec%%:*}"; bin="${spec##*:}"
    have "$bin" || pkgs+=("$pkg")
  done
  [[ ${#pkgs[@]} -eq 0 ]] && { ok "apt tools already present"; return 0; }
  run_cmd "$SUDO apt-get update -y"
  run_cmd "$SUDO apt-get install -y ${pkgs[*]}"
}

install_tools() {
  log "Installing CLI tools"

  if [[ "$PKG_MGR" == "apt" ]]; then
    # spec format: aptpackage:binary
    _apt_install git:git zsh:zsh stow:stow ripgrep:rg bat:batcat fzf:fzf curl:curl unzip:unzip
    # Ubuntu ships bat as `batcat`; expose it as `bat`.
    # DRY_RUN fires the branch too, so the preview shows the symlink even on a fresh box
    # (where `have batcat` is still false because the apt install above was a no-op).
    if [[ "$DRY_RUN" == "1" ]] || { have batcat && ! have bat; }; then
      run_cmd "mkdir -p \"\$HOME/.local/bin\""
      run_cmd "ln -sf \"\$(command -v batcat)\" \"\$HOME/.local/bin/bat\""
    fi
  else
    warn "Non-apt package manager ($PKG_MGR): install git zsh stow ripgrep bat fzf curl unzip manually if missing"
  fi

  # mise (official installer) — manages runtimes; also provides a fallback for other tools
  if ! have mise; then
    run_cmd "curl -fsSL https://mise.run | sh"
  fi

  # starship (official installer)
  if ! have starship; then
    run_cmd "curl -fsSL https://starship.rs/install.sh | sh -s -- --yes"
  fi

  # eza, lazygit, yazi, zoxide, neovim via mise (consistent, no apt-version skew).
  # DRY_RUN-aware: on a fresh box mise was just installed by a no-op above, so the
  # preview must still show these steps.
  if have mise || [[ "$DRY_RUN" == "1" ]]; then
    local mise_bin
    mise_bin="$(command -v mise || true)"     # || true: don't trip set -e when absent
    [[ -z "$mise_bin" ]] && mise_bin="mise"   # dry-run on a box without mise yet
    for tool in eza lazygit yazi zoxide neovim; do
      local check="$tool"; [[ "$tool" == "neovim" ]] && check="nvim"
      if [[ "$DRY_RUN" == "1" ]] || ! have "$check"; then
        run_cmd "$mise_bin use -g ${tool}@latest"
      fi
    done
  else
    warn "mise unavailable; skipping eza/lazygit/yazi/zoxide/neovim"
  fi

  ok "Tool installation finished"
}
```

- [ ] **Step 2: Shellcheck**

Run: `shellcheck install.sh`
Expected: no errors.

- [ ] **Step 3: Dry-run the function in isolation (on Mac, bypassing the Linux guard)**

```bash
DRY_RUN=1 bash -c 'source lib/common.sh; PKG_MGR=apt; SUDO=sudo
  '"$(sed -n "/^_apt_install()/,/^}/p;/^install_tools()/,/^}/p" install.sh)"'
  install_tools'
```
Expected: prints `dry-run:` lines for `apt-get update`, `apt-get install -y git zsh stow ripgrep bat fzf curl unzip`, mise/starship installers, and `mise use -g` for each tool — and runs nothing.

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "install curated CLI toolset (apt + mise + installers)"
```

---

### Task 5: Stow packages

**Files:**
- Modify: `install.sh` (replace `stow_packages` stub)

**Interfaces:**
- Consumes: `STOW_DIR`, `have`, `run_cmd`, `warn`, `log`, `ok`.
- Produces: each package in `STOW_PKGS` symlinked into `$HOME`. Reads packages present under `stow/`.

- [ ] **Step 1: Replace the `stow_packages` stub**

```bash
# nvim is handled by install_nvim (LazyVim base + overlay), not here.
STOW_PKGS=(zsh git starship zellij bat eza ripgrep yazi lazygit mise)

stow_packages() {
  log "Stowing config packages"
  if ! have stow; then
    warn "stow not installed; skipping config symlinks"
    return 0
  fi
  local pkg
  for pkg in "${STOW_PKGS[@]}"; do
    if [[ ! -d "$STOW_DIR/$pkg" ]]; then
      warn "stow package missing, skipping: $pkg"
      continue
    fi
    run_cmd "stow --restow --target=\"\$HOME\" --dir=\"$STOW_DIR\" $pkg"
  done
  ok "Config packages stowed"
}
```

- [ ] **Step 2: Shellcheck + commit**

```bash
shellcheck install.sh
git add install.sh
git commit -m "stow config packages into HOME"
```

---

### Task 6: nvim (LazyVim base) + default shell

**Files:**
- Modify: `install.sh` (replace `install_nvim` and `set_default_shell` stubs)

**Interfaces:**
- Consumes: `STOW_DIR`, `have`, `run_cmd`, `log`, `ok`, `warn`.
- Produces: `~/.config/nvim` populated with LazyVim starter + the `nvim` stow overlay; zsh set as login shell (or bashrc fallback).

- [ ] **Step 1: Replace the `install_nvim` stub**

```bash
install_nvim() {
  log "Installing Neovim config (LazyVim + overlay)"
  local nvim_dir="$HOME/.config/nvim"

  # Idempotency marker: the LazyVim starter ships init.lua; the overlay never does.
  # (Do NOT test `-L lua` — stow links at the file level, so lua/ stays a real dir.)
  if [[ -e "$nvim_dir" && ! -d "$nvim_dir" ]]; then
    warn "$nvim_dir exists and is not a directory; leaving it alone"
    return 0
  fi
  if [[ -f "$nvim_dir/init.lua" ]]; then
    ok "nvim config already present"
  else
    run_cmd "git clone --depth 1 https://github.com/LazyVim/starter \"$nvim_dir\""
    run_cmd "rm -rf \"$nvim_dir/.git\""
  fi

  # The overlay replaces starter's keymaps.lua; remove the conflicting file so stow can link ours.
  if [[ -d "$STOW_DIR/nvim" ]] && have stow; then
    run_cmd "rm -f \"$nvim_dir/lua/config/keymaps.lua\""
    run_cmd "stow --restow --target=\"\$HOME\" --dir=\"$STOW_DIR\" nvim"
  fi
  ok "Neovim config ready"
}
```

- [ ] **Step 2: Replace the `set_default_shell` stub**

```bash
set_default_shell() {
  log "Setting zsh as default shell"
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    warn "zsh not installed; cannot set default shell"
    return 0
  fi
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    ok "zsh already the default shell"
    return 0
  fi
  if run_cmd "chsh -s \"$zsh_path\""; then
    ok "Default shell set to zsh (re-login to take effect)"
  else
    warn "chsh failed; adding exec-zsh guard to ~/.bashrc as fallback"
    run_cmd "grep -q 'exec zsh' \"\$HOME/.bashrc\" 2>/dev/null || printf '%s\n' '[ -t 1 ] && [ -z \"\$ZSH_VERSION\" ] && command -v zsh >/dev/null && exec zsh' >> \"\$HOME/.bashrc\""
  fi
}
```

- [ ] **Step 3: Shellcheck + commit**

```bash
shellcheck install.sh
git add install.sh
git commit -m "install LazyVim nvim config and set zsh default shell"
```

---

### Task 7: Vendor verbatim configs (git untouched here)

**Files:**
- Create: `stow/starship/.config/starship.toml`, `stow/bat/.config/bat/config`, `stow/eza/.config/eza/theme.yml`, `stow/ripgrep/.ripgreprc`, `stow/yazi/.config/yazi/theme.toml`, `stow/yazi/.config/yazi/Catppuccin-mocha.tmTheme`, `stow/lazygit/.config/lazygit/config.yml`, `stow/mise/.config/mise/config.toml`, `stow/zellij/...` (all files), `stow/nvim/.config/nvim/lua/...`

**Interfaces:**
- Produces: stow packages that link cleanly into `$HOME` on Linux. These files are platform-neutral and copied as-is.

- [ ] **Step 1: Copy the verbatim packages from mac-setup**

```bash
cd ~/Workspace/tjh-coder-dotfiles
SRC=~/Workspace/mac-setup/stow
for p in starship bat eza ripgrep yazi lazygit mise zellij; do
  mkdir -p "stow/$p"
  cp -R "$SRC/$p/." "stow/$p/"
done
# nvim overlay: only the lua overrides, and DROP the Ghostty-specific plugin (no Ghostty in Coder)
mkdir -p stow/nvim/.config/nvim/lua
cp -R "$SRC/nvim/.config/nvim/lua/." stow/nvim/.config/nvim/lua/
rm -f stow/nvim/.config/nvim/lua/plugins/ghostty.lua
```

- [ ] **Step 2: Verify no macOS-only paths leaked into copied configs**

```bash
grep -rn "/opt/homebrew\|/Users/\|pmset\|caffeinate" stow/ || echo "clean"
```
Expected: review any hits. Zellij status scripts (`battery.sh`, `mem.sh`) may use macOS commands — these only affect the status bar cosmetically; leave them (they degrade silently). Note any finding in the commit message. Everything else should print `clean`.

- [ ] **Step 3: Commit**

```bash
git add stow/
git commit -m "vendor platform-neutral configs (starship, bat, eza, ripgrep, yazi, lazygit, mise, zellij, nvim overlay)"
```

---

### Task 8: Vendor and adapt `.zshrc` for Linux

**Files:**
- Create: `stow/zsh/.zshrc`

**Interfaces:**
- Produces: a Linux-adapted `.zshrc`. The mac-setup `.zshrc` already guards Homebrew/`path_helper`/fzf-tab/plugin paths behind existence checks, so those are safe to keep. This task strips the parts that are macOS-only commands or wrong paths.

- [ ] **Step 1: Copy the base file**

```bash
cd ~/Workspace/tjh-coder-dotfiles
mkdir -p stow/zsh
cp ~/Workspace/mac-setup/stow/zsh/.zshrc stow/zsh/.zshrc
```

- [ ] **Step 2: Add Linux plugin/fzf-tab paths** (so apt-installed zsh plugins load)

In `stow/zsh/.zshrc`, the three `for` loops sourcing `fzf-tab`, `zsh-autosuggestions`, and `zsh-syntax-highlighting` list only Homebrew paths. Add the Ubuntu apt path as the first candidate in each loop:

- fzf-tab loop — add line before `/opt/homebrew/share/fzf-tab/...`:
```
  /usr/share/zsh-fzf-tab/fzf-tab.plugin.zsh \
```
- autosuggestions loop — add before `/opt/homebrew/share/zsh-autosuggestions/...`:
```
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
```
- syntax-highlighting loop — add before `/opt/homebrew/share/zsh-syntax-highlighting/...`:
```
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
```

- [ ] **Step 3: Replace the macOS-only `caffeinate` helpers with a no-op note**

Delete the four-line block:
```
single()  { caffeinate -dis -t 3600  & ... }
double()  { caffeinate -dis -t 10800 & ... }
redbull() { caffeinate -dis -t 86400 & ... }
decaf()   { pkill caffeinate ... }
```
(They depend on macOS `caffeinate`; irrelevant in a container.)

- [ ] **Step 4: Remove the Spotify alias and the macOS `ssh`/Keychain override**

Delete:
```
if [[ -d "/Applications/Spotify.app" ]]; then
  alias spotify='open -a Spotify'
fi
```
and the entire `ssh() { ... security find-generic-password ... }` function (it calls the macOS-only `security` binary). The per-repo `_gh_set_token` chpwd hook below it stays.

- [ ] **Step 5: Fix the `restow` helper path**

Replace:
```
restow() { stow -R "$1" -d ~/Workspace/mac-setup/stow -t ~; }
```
with:
```
restow() { stow -R "$1" -d ~/.dotfiles/stow -t ~; }
```
(Coder clones this repo to `~/.dotfiles`.)

- [ ] **Step 6: Verify the adapted file is valid zsh syntax**

Run: `zsh -n stow/zsh/.zshrc`
Expected: no output (syntax OK). If zsh isn't on the Mac, defer this check to the Docker run in Task 10.

- [ ] **Step 7: Confirm macOS-only commands are gone**

```bash
grep -n "caffeinate\|/Applications/\|security find-generic-password\|mac-setup" stow/zsh/.zshrc || echo "clean"
```
Expected: `clean`.

- [ ] **Step 8: Commit**

```bash
git add stow/zsh/.zshrc
git commit -m "vendor Linux-adapted .zshrc"
```

---

### Task 9: Vendor and adapt `.gitconfig`

**Files:**
- Create: `stow/git/.gitconfig`

**Interfaces:**
- Produces: a `.gitconfig` whose gh credential helper resolves on Linux.

- [ ] **Step 1: Copy the base file**

```bash
cd ~/Workspace/tjh-coder-dotfiles
mkdir -p stow/git
cp ~/Workspace/mac-setup/stow/git/.gitconfig stow/git/.gitconfig
```

- [ ] **Step 2: Replace the hardcoded Homebrew `gh` path with a PATH lookup**

Both `[credential "https://github.com"]` and `[credential "https://gist.github.com"]` blocks reference `/opt/homebrew/bin/gh`. Replace every `!/opt/homebrew/bin/gh auth git-credential` with:
```
	helper = !gh auth git-credential
```
(relies on `gh` being on PATH; if gh is absent in the workspace the helper is simply unused.)

- [ ] **Step 3: Confirm no Homebrew path remains**

```bash
grep -n "/opt/homebrew" stow/git/.gitconfig || echo "clean"
```
Expected: `clean`.

- [ ] **Step 4: Commit**

```bash
git add stow/git/.gitconfig
git commit -m "vendor Linux-adapted .gitconfig"
```

---

### Task 10: End-to-end Docker smoke test

**Files:**
- None (verification task)

**Interfaces:**
- Consumes: the full repo.
- Produces: evidence the installer runs clean on Ubuntu.

- [ ] **Step 1: Dry-run inside Ubuntu (no mutations)**

```bash
cd ~/Workspace/tjh-coder-dotfiles
docker run --rm -it -v "$PWD":/dotfiles -w /dotfiles ubuntu:24.04 \
  bash -c "apt-get update -y >/dev/null && DRY_RUN=1 ./install.sh"
```
Expected: passes the Linux guard, prints `Package manager: apt`, and emits `dry-run:` lines for every install/stow/chsh step. Exit 0.

- [ ] **Step 2: Real run inside Ubuntu (full install)**

```bash
docker run --rm -it -v "$PWD":/dotfiles -w /dotfiles ubuntu:24.04 \
  bash -c "apt-get update -y >/dev/null && ./install.sh && \
    echo '--- verify ---' && \
    command -v zsh stow rg starship && \
    ls -la ~/.zshrc ~/.gitconfig ~/.config/starship.toml ~/.config/nvim/lua && \
    zsh -n ~/.zshrc && echo 'ZSHRC OK'"
```
Expected: tools resolve, symlinks point into `/dotfiles/stow/...`, `~/.config/nvim/lua` exists, and `ZSHRC OK` prints. Fix any failure before proceeding (use systematic-debugging skill if needed).

- [ ] **Step 3: Idempotency check — run install twice**

```bash
docker run --rm -it -v "$PWD":/dotfiles -w /dotfiles ubuntu:24.04 \
  bash -c "apt-get update -y >/dev/null && ./install.sh >/dev/null 2>&1 && ./install.sh 2>&1 | tail -20"
```
Expected: second run prints `already present` / `already the default shell` style messages and exits 0 with no errors.

---

### Task 11: README and push

**Files:**
- Create: `README.md`

**Interfaces:**
- Produces: usage docs committed and pushed to `main`.

- [ ] **Step 1: Write `README.md`**

```markdown
# tjh-coder-dotfiles

Linux dotfiles for [Coder](https://coder.com) workspaces. Coder clones this repo to
`~/.dotfiles` and auto-runs `install.sh`, which:

1. Installs a curated CLI toolset (git, zsh, stow, ripgrep, bat, fzf, starship, eza,
   lazygit, yazi, zoxide, neovim, mise) via apt + official installers + mise.
2. Installs LazyVim and overlays custom nvim config.
3. Symlinks terminal configs into `$HOME` with GNU Stow.
4. Sets zsh as the default shell.

## Use with Coder

Coder dashboard → Settings → Dotfiles → set repo URL to this repo. Or:

    coder dotfiles git@github.com:tjhanley-snt/tjh-coder-dotfiles.git

## Preview without changing anything

    DRY_RUN=1 ./install.sh

## Test locally

    docker run --rm -it -v "$PWD":/dotfiles -w /dotfiles ubuntu:24.04 \
      bash -c "apt-get update -y >/dev/null && ./install.sh"

## Scope

Terminal configs only. macOS desktop packages (ghostty, karabiner, skhd, obsidian,
zed) and host-specific AI-tool auth (claude, pi, opencode) are intentionally excluded.
Source of truth for config content is the `mac-setup` repo; files here are adapted
for Linux.
```

- [ ] **Step 2: Commit and push to main**

```bash
git add README.md
git commit -m "docs: document install flow and local testing"
git push -u origin main
```
Expected: push succeeds (personal namespace, no ruleset).

---

## Self-Review

**Spec coverage:**
- Repo structure (install.sh, lib/, stow/) → Tasks 2,3,7,8,9 ✓
- Coder entrypoint = install.sh, bash → Task 3 ✓
- Linux guard → Task 3 ✓
- pkg-mgr detection → Task 2 ✓
- two-tier tool install (apt + installers) → Task 4 ✓
- stow packages → Task 5 ✓
- nvim LazyVim base + overlay → Task 6 ✓
- zsh default shell + bashrc fallback → Task 6 ✓
- config adaptation (zshrc/gitconfig mac-isms) → Tasks 8,9 ✓
- skipped packages excluded → Task 7 (only neutral pkgs copied) ✓
- DRY_RUN preview → Tasks 2,4,10 ✓
- Docker testing → Task 10 ✓
- Repo creation + push to main (personal namespace, no ruleset) → Tasks 1,11 ✓
- `tjhanley-snt` account + gh auth switch → Task 1, Global Constraints ✓

**Placeholder scan:** No `<org>`/`<username>`/ticket placeholders remain — target is `tjhanley-snt/tjh-coder-dotfiles`. No "TODO"/"handle edge cases"/"similar to Task N" placeholders.

**Type consistency:** helper names (`have`, `run_cmd`, `log`, `ok`, `warn`, `detect_pkg_mgr`, `SUDO`) used consistently across Tasks 2-6. `STOW_DIR`/`STOW_PKGS` consistent between Tasks 3,5,6.
