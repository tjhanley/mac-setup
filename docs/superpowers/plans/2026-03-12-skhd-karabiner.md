# skhd + Karabiner-Elements Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Caps Lock → Hyper key (via Karabiner) and app-launching hotkeys (via skhd) as version-controlled dotfiles wired into the bootstrap script.

**Architecture:** Two new stow packages (`skhd/`, `karabiner/`) plus Brewfile + bootstrap changes. Karabiner's `karabiner.json` is intentionally unmanaged (it atomically rewrites itself); only the complex_modifications rule file is stow-managed. stow folding is prevented by pre-creating the target directories in `ensure_config_dir()`.

**Tech Stack:** GNU Stow, zsh, bats-core (tests), Karabiner-Elements complex modifications JSON, skhd config DSL.

**Spec:** `docs/superpowers/specs/2026-03-12-skhd-karabiner-design.md`

---

## Chunk 1: Dotfiles — stow packages and tests

### Task 1: Add failing structure tests for new stow packages

**Files:**
- Modify: `tests/structure.bats`

- [ ] **Step 1: Add failing tests**

Append to `tests/structure.bats`:

```bash
@test "stow/skhd contains skhdrc" {
  [[ -f "$REPO_ROOT/stow/skhd/.config/skhd/skhdrc" ]]
}

@test "stow/karabiner contains hyper complex modification" {
  [[ -f "$REPO_ROOT/stow/karabiner/.config/karabiner/assets/complex_modifications/hyper.json" ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bats tests/structure.bats
```

Expected: both new tests FAIL with "No such file or directory".

---

### Task 2: Create stow/skhd package

**Files:**
- Create: `stow/skhd/.config/skhd/skhdrc`

- [ ] **Step 1: Create the skhdrc**

```
# Hyper key app launchers
# Hyper = cmd + ctrl + alt + shift (mapped from Caps Lock via Karabiner-Elements)
cmd + ctrl + alt + shift - t : open -a Ghostty
cmd + ctrl + alt + shift - b : open -a "Brave Browser"
cmd + ctrl + alt + shift - o : open -a Obsidian
cmd + ctrl + alt + shift - s : open -a Spotify
```

- [ ] **Step 2: Run structure test to verify it passes**

```bash
bats tests/structure.bats --filter "stow/skhd"
```

Expected: PASS.

---

### Task 3: Create stow/karabiner package

**Files:**
- Create: `stow/karabiner/.config/karabiner/assets/complex_modifications/hyper.json`

- [ ] **Step 1: Add failing JSON syntax test**

Append to `tests/syntax.bats`:

```bash
@test "hyper.json is valid JSON" {
  python3 -m json.tool \
    "$REPO_ROOT/stow/karabiner/.config/karabiner/assets/complex_modifications/hyper.json" \
    >/dev/null
}
```

Run it to verify it fails:

```bash
bats tests/syntax.bats --filter "hyper.json"
```

Expected: FAIL (file missing).

- [ ] **Step 2: Create hyper.json**

```json
{
  "title": "Hyper Key (Caps Lock)",
  "rules": [
    {
      "description": "Caps Lock → Hyper (held) / Escape (tap)",
      "manipulators": [
        {
          "from": {
            "key_code": "caps_lock",
            "modifiers": {
              "optional": ["any"]
            }
          },
          "to": [
            {
              "key_code": "left_shift",
              "modifiers": ["left_command", "left_control", "left_option"]
            }
          ],
          "to_if_alone": [
            {
              "key_code": "escape"
            }
          ],
          "type": "basic"
        }
      ]
    }
  ]
}
```

- [ ] **Step 3: Run all tests to verify they pass**

```bash
bats tests/
```

Expected: all tests PASS including both new structure tests and the hyper.json syntax test.

- [ ] **Step 4: Commit**

```bash
git add stow/skhd/ stow/karabiner/ tests/structure.bats tests/syntax.bats
git commit -m "feat(dotfiles): add skhd and karabiner stow packages"
```

---

## Chunk 2: Brewfile and Bootstrap

### Task 4: Update Brewfile

**Files:**
- Modify: `brew/Brewfile`

- [ ] **Step 1: Add failing Brewfile tests**

Append to `tests/syntax.bats`:

```bash
@test "Brewfile includes koekeishiya/formulae tap" {
  grep -q 'tap "koekeishiya/formulae"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes skhd" {
  grep -q 'brew "koekeishiya/formulae/skhd"' "$REPO_ROOT/brew/Brewfile"
}

@test "Brewfile includes karabiner-elements" {
  grep -q 'cask "karabiner-elements"' "$REPO_ROOT/brew/Brewfile"
}
```

Run to verify they fail:

```bash
bats tests/syntax.bats --filter "koekeishiya|skhd|karabiner"
```

Expected: all three FAIL.

- [ ] **Step 2: Add tap and formulae to Brewfile**

In `brew/Brewfile`, add the tap as the first line (before all `brew` lines), and add the two new entries. The tap must appear before the `brew` line that uses it.

Add at the top of the file (before `brew "git"`):

```
tap "koekeishiya/formulae"
```

Add in the `# Terminal + multiplexer` section (after `brew "zellij"`):

```
brew "koekeishiya/formulae/skhd"
```

Add in the `# Apps (optional)` cask section (after `cask "raycast"`):

```
cask "karabiner-elements"
```

- [ ] **Step 3: Run Brewfile tests**

```bash
bats tests/syntax.bats --filter "koekeishiya|skhd|karabiner"
```

Expected: all three PASS.

- [ ] **Step 4: Run full test suite**

```bash
bats tests/
```

Expected: all tests PASS.

---

### Task 5: Update bootstrap — ensure_config_dir

**Files:**
- Modify: `bootstrap/bootstrap-mac.zsh` (lines ~276–280)

- [ ] **Step 1: Add karabiner and skhd dirs to ensure_config_dir()**

The current `ensure_config_dir()` only creates `~/.config`. Add two more lines to prevent stow from folding these dirs into symlinks on a fresh machine.

Find the function (around line 276):

```zsh
ensure_config_dir() {
  log "Ensuring ~/.config exists"
  run_cmd mkdir -p "$HOME/.config"
  ok "~/.config ready"
}
```

Replace with:

```zsh
ensure_config_dir() {
  log "Ensuring ~/.config exists"
  run_cmd mkdir -p "$HOME/.config"
  run_cmd mkdir -p "$HOME/.config/karabiner/assets/complex_modifications"
  run_cmd mkdir -p "$HOME/.config/skhd"
  ok "~/.config ready"
}
```

- [ ] **Step 2: Verify bootstrap syntax**

```bash
bats tests/syntax.bats --filter "bootstrap"
```

Expected: PASS.

---

### Task 6: Update bootstrap — stow_dotfiles hard-reset block

**Files:**
- Modify: `bootstrap/bootstrap-mac.zsh` (lines ~321–363)

- [ ] **Step 1: Add karabiner and skhd to hard-reset backup entries**

In `stow_dotfiles()`, inside the `if [[ "$HARD_RESET" -eq 1 ]]; then` block, add after `backup_path "$HOME/.config/yazi"` (around line 339):

```zsh
    backup_path "$HOME/.config/karabiner"
    backup_path "$HOME/.config/skhd"
```

- [ ] **Step 2: Add karabiner and skhd to move_conflict_target section**

In the same block, add after `move_conflict_target ".config/yazi/Catppuccin-mocha.tmTheme"` (around line 362):

```zsh
    move_conflict_target ".config/karabiner/assets/complex_modifications/hyper.json"
    move_conflict_target ".config/skhd/skhdrc"
```

- [ ] **Step 3: Verify bootstrap syntax**

```bash
bats tests/syntax.bats --filter "bootstrap"
```

Expected: PASS.

---

### Task 7: Add install_skhd_service() and wire into main()

**Files:**
- Modify: `bootstrap/bootstrap-mac.zsh`

- [ ] **Step 1: Add install_skhd_service() before post_notes()**

Insert this function immediately before the `post_notes()` function (around line 1135):

```zsh
install_skhd_service() {
  log "Installing skhd service"

  local skhd_bin=""
  if need_cmd skhd; then
    skhd_bin="$(command -v skhd)"
  elif [[ -x /opt/homebrew/bin/skhd ]]; then
    skhd_bin="/opt/homebrew/bin/skhd"
  elif [[ -x /usr/local/bin/skhd ]]; then
    skhd_bin="/usr/local/bin/skhd"
  fi

  if [[ -z "$skhd_bin" ]]; then
    warn "skhd not found; skipping service install"
    return
  fi

  local service_target="gui/$(id -u)/com.asmvik.skhd"
  if /bin/launchctl print "$service_target" >/dev/null 2>&1; then
    ok "skhd service already running"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print -P "%F{yellow}dry-run:%f $skhd_bin --start-service"
    return
  fi

  # --start-service auto-installs the plist if missing, then bootstraps via launchd.
  if "$skhd_bin" --start-service; then
    ok "skhd service started"
  else
    warn "skhd --start-service failed; grant Accessibility permission and re-run"
  fi
}
```

- [ ] **Step 2: Wire into main() after configure_keyboard_repeat**

In `main()`, add `install_skhd_service` after `configure_keyboard_repeat` and before `prune_old_backups`:

```zsh
  configure_keyboard_repeat
  install_skhd_service
  prune_old_backups
```

- [ ] **Step 3: Update post_notes() with permission instructions**

In `post_notes()`, add the Karabiner and skhd notes. Find the heredoc content:

```
- Open Ghostty once to grant permissions and confirm settings.
- Open Raycast and Zed if you use them.
```

Add after "Open Raycast and Zed if you use them.":

```
- Karabiner-Elements: grant Input Monitoring + Accessibility in
  System Settings > Privacy & Security, then enable the Hyper rule:
  Complex Modifications > Add rule > Hyper.
- skhd: grant Accessibility in System Settings > Privacy & Security.
```

- [ ] **Step 4: Verify bootstrap syntax and dry-run output**

```bash
bats tests/syntax.bats --filter "bootstrap"
```

Expected: PASS.

Smoke-test the new function appears in dry-run:

```bash
./bootstrap/bootstrap-mac.zsh --dry-run 2>&1 | grep -i "skhd\|karabiner"
```

Expected: lines showing `dry-run: mkdir -p ~/.config/karabiner/...` and `dry-run: skhd --start-service`.

- [ ] **Step 5: Run full test suite**

```bash
bats tests/
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add brew/Brewfile bootstrap/bootstrap-mac.zsh tests/syntax.bats
git commit -m "feat(bootstrap): add skhd service + karabiner dirs; update Brewfile"
```

---

## Chunk 3: Documentation

### Task 8: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add skhd to the CLI Tools list**

Find the CLI Tools paragraph (around line 140):

```
Installed via Homebrew: git, git-delta, ...
```

Add `skhd` (installed via `koekeishiya/formulae` tap) after `zellij`:

```
..., zellij, skhd (koekeishiya/formulae tap), mise, rust, ...
```

- [ ] **Step 2: Add karabiner-elements to the Casks list**

Find the Casks line (around line 146):

```
Casks: 1password, ghostty, raycast, zed, ...
```

Add `karabiner-elements` after `raycast`:

```
Casks: 1password, ghostty, raycast, karabiner-elements, zed, ...
```

- [ ] **Step 3: Add step to "What It Does" list**

The list currently ends at step 23 (keyboard repeat) and 24 (prune backups). Add a new step 23 for skhd service (keyboard repeat is now step 23, skhd becomes 24, prune becomes 25):

Find step 23 (around line 75):

```
23. Configures keyboard repeat speed ...
24. Prunes old backups ...
```

Add between them:

```
24. Starts skhd hotkey service via launchd (`skhd --start-service`); skips if already running
```

And renumber "Prunes" to 25.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): add skhd and karabiner-elements to tools and What It Does"
```

---

### Task 9: Update docs/mac-setup-log.md

**Files:**
- Modify: `docs/mac-setup-log.md`

- [ ] **Step 1: Add tools to "Installed/managed tools" section**

Under `### CLI/dev tools`, find the line:
```
- zellij
```
Add after it:
```
- skhd (via koekeishiya/formulae tap) — hotkey daemon
```

Under `### Casks/apps/fonts`, find the line:
```
- 1password, ghostty, raycast, zed, obsidian
```
Replace with:
```
- 1password, ghostty, raycast, karabiner-elements, zed, obsidian
```

- [ ] **Step 2: Add bootstrap behavior entry**

In the `## Bootstrap behavior` section, add after the keyboard repeat entry:

```
- Starts skhd as a launchd service (`skhd --start-service`) after `configure_keyboard_repeat`; idempotent (checks `launchctl print gui/<uid>/com.asmvik.skhd` before acting).
```

- [ ] **Step 3: Add stow package entries**

In `## Stow packages`, add:

```
- `skhd/` — `.config/skhd/skhdrc` (Hyper key app launchers: t=Ghostty, b=Brave, o=Obsidian, s=Spotify)
- `karabiner/` — `.config/karabiner/assets/complex_modifications/hyper.json` (Caps Lock → Hyper held / Escape tap; `karabiner.json` is intentionally unmanaged — Karabiner atomically rewrites it)
```

- [ ] **Step 4: Run full test suite one final time**

```bash
bats tests/
```

Expected: all tests PASS.

- [ ] **Step 5: Final commit**

```bash
git add docs/mac-setup-log.md
git commit -m "docs(log): add skhd + karabiner-elements to mac-setup log"
```
