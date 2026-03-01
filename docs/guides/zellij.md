# Zellij

Terminal multiplexer with a custom zjstatus bar, launcher, and Catppuccin Mocha theming.

## Auto-start

Interactive shells in Ghostty automatically launch Zellij via `.zshrc`:

```sh
exec zellij
```

This only triggers when all of these are true:
- Interactive shell (`$-` contains `i`)
- Running in Ghostty (`$TERM_PROGRAM == ghostty`)
- Not already inside Zellij or tmux
- `NO_AUTO_ZELLIJ` is not set

To opt out for a single shell:

```sh
NO_AUTO_ZELLIJ=1 zsh
```

To disable permanently, comment out the auto-start block in `stow/zsh/.zshrc`.

## Keybinds

### Mode switching

| Keys | Mode |
|------|------|
| Ctrl+p | Pane |
| Ctrl+t | Tab |
| Ctrl+n | Resize |
| Ctrl+h | Move |
| Ctrl+s | Scroll |
| Ctrl+o | Session |

### Pane mode (Ctrl+p)

| Keys | Action |
|------|--------|
| h / Left | Focus pane left |
| j / Down | Focus pane down |
| k / Up | Focus pane up |
| l / Right | Focus pane right |
| p | Focus previous pane |
| n | New pane |
| d | New pane (down) |
| r | Rename pane (custom -- matches tab mode `r`) |
| s | New stacked pane |
| x | Close pane |
| f | Toggle fullscreen |
| w | Toggle floating |
| e | Embed floating pane |
| z | Toggle pane frames |

### Resize mode (Ctrl+n)

| Keys | Action |
|------|--------|
| h / Left | Resize left |
| j / Down | Resize down |
| k / Up | Resize up |
| l / Right | Resize right |
| + | Increase size |
| - | Decrease size |

### Move mode (Ctrl+h)

| Keys | Action |
|------|--------|
| h / Left | Move pane left |
| j / Down | Move pane down |
| k / Up | Move pane up |
| l / Right | Move pane right |
| Tab | Swap with next pane |

### Custom keybinds

| Keys | Action |
|------|--------|
| Super+k | Clear scrollback |
| Super+Shift+l | Open launcher (fzf app picker) |
| Alt+arrows | Resize pane (no mode switch needed) |

These are defined in `stow/zellij/.config/zellij/config.kdl`.

## Launcher

`Super+Shift+l` opens an fzf picker in a floating pane. Selecting an app launches it in a new floating Zellij pane via `zellij run`.

Current launcher apps:
- basalt
- claude
- claude --worktree
- codex
- htop
- k9s
- lazydocker
- lazygit
- nvim
- sidecar
- yazi

### Adding apps to the launcher

Edit `stow/zellij/.config/zellij/scripts/launcher.sh` and add entries to the `commands` array:

```bash
commands=(
  "basalt"
  "claude"
  # ...
  "your-app"
)
```

Then re-stow: `(cd stow && stow --target="$HOME" --restow zellij)`

## zjstatus bar

The status bar uses the [zjstatus](https://github.com/dj95/zjstatus) plugin, loaded from `~/.config/zellij/plugins/zjstatus.wasm`. The layout is defined in `stow/zellij/.config/zellij/layouts/default.kdl`.

### Layout sections

```
[session] [mode] [tabs]        [notifications]        [cpu] [mem] [battery] [date time]
```

- **Left:** session name (sapphire pill) + mode indicator (color changes per mode) + tab chiclets
- **Center:** notification messages (yellow pill, auto-hides after 10s)
- **Right:** CPU %, memory usage, battery with dynamic icon, date/time

### Mode indicator colors

| Mode | Color |
|------|-------|
| Normal | Green |
| Tmux | Mauve |
| Locked | Red |
| Pane / Tab | Teal |
| Scroll / Search | Flamingo |
| Resize / Rename / Move | Yellow |
| Session / Prompt | Pink |

### Tab styling

- Active tab: peach background with rounded powerline caps
- Inactive tab: blue background with rounded powerline caps
- Indicators: floating (&#xf0779;), fullscreen (&#xf04d3;), sync ()

## Custom scripts

The zjstatus bar runs shell scripts for live system stats. All scripts live in `stow/zellij/.config/zellij/scripts/`.

| Script | Output | Refresh interval |
|--------|--------|-----------------|
| `cpu.sh` | CPU usage % (averaged across cores) | 5 seconds |
| `mem.sh` | Active+wired memory in GB | 10 seconds |
| `battery.sh` | Battery icon + percentage | 30 seconds |

### cpu.sh

Uses `ps` and `sysctl` to compute average CPU load across all cores. Output format: `  7%`.

### mem.sh

Parses `vm_stat` for active and wired pages, converts to GB. Output format: `  8.2G`.

### battery.sh

Reads `pmset -g batt` for charge level and AC/battery state. Picks a Nerd Font battery glyph at 10% increments, with a separate charging icon when on AC power. Output format: `&#xf0079; 85%`.

### Adjusting refresh rates

Edit the `command_*_interval` values in `stow/zellij/.config/zellij/layouts/default.kdl`:

```kdl
command_cpu_interval   "5"    // seconds between CPU updates
command_mem_interval   "10"   // seconds between memory updates
command_battery_interval "30" // seconds between battery updates
```

## UI preferences

Set in `stow/zellij/.config/zellij/config.kdl`:

| Setting | Value | Effect |
|---------|-------|--------|
| `simplified_ui` | true | Hides built-in hint bar (zjstatus replaces it) |
| `pane_frames` | true | Borders around panes |
| `rounded_corners` | true | Rounded pane frame corners |
| `hide_session_name` | true | Removes session name from frame titles |
| `scrollback_editor` | nvim | Opens scrollback in Neovim |
| `mouse_mode` | true | Mouse support for pane focus and scrolling |
| `session_serialization` | true | Persists session layout on exit |

## Shell aliases

```sh
zj     # zellij
zja    # zellij attach -c main (create-or-attach to "main" session)
```

## Troubleshooting

### zjstatus not loading

The plugin must exist at `~/.config/zellij/plugins/zjstatus.wasm`. If missing, re-run `./setup.sh` or download manually:

```sh
mkdir -p ~/.config/zellij/plugins
curl -fsSL -o ~/.config/zellij/plugins/zjstatus.wasm \
  https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
```

### Scripts not updating in the status bar

1. Check that the scripts are executable: `ls -la ~/.config/zellij/scripts/`
2. Verify they run standalone: `~/.config/zellij/scripts/cpu.sh`
3. The layout references absolute paths -- if your home directory differs from `/Users/tom`, update the `command_*_command` paths in `layouts/default.kdl`

### Zellij starts but looks wrong

Make sure you have a Nerd Font installed (BlexMono Nerd Font is installed by the bootstrap). The powerline glyphs and icons require Nerd Font support in your terminal.
