# Theming

Catppuccin Mocha is applied consistently across every tool in this setup. This guide covers how each tool is themed, and how to re-theme the entire setup if you want a different palette.

## Catppuccin Mocha palette

| Name | Hex | Usage examples |
|------|-----|---------------|
| Rosewater | `#f5e0dc` | FZF spinner, pointer |
| Flamingo | `#f2cdcd` | zjstatus battery/scroll pill |
| Pink | `#f5c2e7` | Starship cmd_duration segment, zjstatus session pill |
| Mauve | `#cba6f7` | FZF info/prompt, Starship runtime segment |
| Red | `#f38ba8` | FZF highlight, lazygit unstaged, zjstatus locked mode |
| Maroon | `#eba0ac` | zjstatus datetime pill |
| Peach | `#fab387` | zjstatus active tab |
| Yellow | `#f9e2af` | lazygit search border, zjstatus resize mode |
| Green | `#a6e3a1` | lazygit active border, zjstatus normal mode, CPU pill |
| Teal | `#94e2d5` | zjstatus pane/tab mode, memory pill |
| Sky | `#89dceb` | -- |
| Sapphire | `#74c7ec` | Starship OS/directory segment, zjstatus session |
| Blue | `#89b4fa` | lazygit options text, zjstatus inactive tabs |
| Lavender | `#b4befe` | FZF marker |
| Text | `#cdd6f4` | lazygit default fg, FZF fg |
| Subtext0 | `#a6adc8` | lazygit inactive border |
| Surface1 | `#45475a` | lazygit cherry-pick bg, FZF selected-bg |
| Surface0 | `#313244` | lazygit selected line bg, zjstatus background |
| Base | `#1e1e2e` | FZF bg, zjstatus base |
| Mantle | `#181825` | -- |
| Crust | `#11111b` | zjstatus pill foreground text |

Full palette: https://github.com/catppuccin/catppuccin

## Per-tool theme config

| Tool | Config file | Method |
|------|------------|--------|
| Ghostty | `stow/ghostty/.config/ghostty/config` | Built-in theme name |
| Zellij | `stow/zellij/.config/zellij/config.kdl` | Built-in theme name |
| zjstatus | `stow/zellij/.config/zellij/layouts/default.kdl` | Hex color variables |
| Starship | `stow/starship/.config/starship.toml` | Named palette block |
| bat | `stow/bat/.config/bat/config` | Built-in theme name |
| lazygit | `stow/lazygit/.config/lazygit/config.yml` | Hex color values in YAML |
| eza | `stow/eza/.config/eza/theme.yml` | Catppuccin YAML theme file |
| yazi | `stow/yazi/.config/yazi/theme.toml` + `Catppuccin-mocha.tmTheme` | TOML theme + tmTheme for syntax |
| FZF | `stow/zsh/.zshrc` (`FZF_DEFAULT_OPTS`) | Shell color flags |
| Zed | `stow/zed/.config/zed/settings.json` | Built-in theme name + extension |

## Tool-by-tool breakdown

### Ghostty

```
theme = "Catppuccin Mocha"
```

Ghostty ships with Catppuccin built-in. Just set the theme name.

### Zellij

```kdl
theme "catppuccin-mocha";
```

Zellij ships with Catppuccin built-in for pane frames and UI chrome.

### zjstatus

The status bar layout defines the full Mocha palette as named variables (`$base`, `$surface0`, etc.) and references them throughout the format strings. This is in `layouts/default.kdl`. To change, replace all hex values in the `color_*` block.

### Starship

Uses a `[palettes.catppuccin_mocha]` block with named colors, referenced in segment styles:

```toml
palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
# ... full palette
```

### bat

```
--theme="Catppuccin Mocha"
```

bat ships with Catppuccin built-in.

### lazygit

Individual UI elements are themed with hex codes in `config.yml`:

```yaml
gui:
  theme:
    activeBorderColor:
      - "#a6e3a1"   # green
      - bold
    selectedLineBgColor:
      - "#313244"   # surface0
```

### eza

Uses the official Catppuccin theme file at `~/.config/eza/theme.yml`.

### yazi

Uses `theme.toml` (Catppuccin Mocha blue variant) for UI colors and `Catppuccin-mocha.tmTheme` for syntax highlighting in file previews.

### FZF

Colors are set via `FZF_DEFAULT_OPTS` in `.zshrc`:

```sh
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:#45475A \
  --color=border:#6C7086,label:#CDD6F4"
```

### Zed

```json
{
  "theme": { "mode": "dark", "dark": "Catppuccin Mocha" },
  "icon_theme": "Catppuccin Icons",
  "auto_install_extensions": {
    "catppuccin": true,
    "catppuccin-icons": true
  }
}
```

## Re-theming guide

To switch from Catppuccin Mocha to a different theme, you need to update these files:

| File | Format | What to change |
|------|--------|---------------|
| `stow/ghostty/.config/ghostty/config` | Plain text | `theme = "..."` |
| `stow/zellij/.config/zellij/config.kdl` | KDL | `theme "..."` |
| `stow/zellij/.config/zellij/layouts/default.kdl` | KDL | All `color_*` hex values |
| `stow/starship/.config/starship.toml` | TOML | `palette` name + `[palettes.*]` hex values |
| `stow/bat/.config/bat/config` | Plain text | `--theme="..."` |
| `stow/lazygit/.config/lazygit/config.yml` | YAML | All hex color values under `gui.theme` |
| `stow/eza/.config/eza/theme.yml` | YAML | Replace entire theme file |
| `stow/yazi/.config/yazi/theme.toml` | TOML | Replace theme file |
| `stow/yazi/.config/yazi/Catppuccin-mocha.tmTheme` | XML (tmTheme) | Replace with new syntax theme |
| `stow/zsh/.zshrc` | Shell | `FZF_DEFAULT_OPTS` color flags |
| `stow/zed/.config/zed/settings.json` | JSON | `theme.dark`, `icon_theme`, extensions |

### Claude Code prompt for re-theming

Copy and paste this prompt into Claude Code to re-theme the entire setup:

```
Re-theme my mac-setup from Catppuccin Mocha to [YOUR THEME NAME].

Files to update:

1. stow/ghostty/.config/ghostty/config -- change `theme = "Catppuccin Mocha"` to the new theme name (or add custom color settings if Ghostty doesn't ship with it)
2. stow/zellij/.config/zellij/config.kdl -- change `theme "catppuccin-mocha"` to the new theme name (or remove if using custom zjstatus colors only)
3. stow/zellij/.config/zellij/layouts/default.kdl -- replace all color_* hex values with the new palette
4. stow/starship/.config/starship.toml -- replace palette name and all hex values in [palettes.*]
5. stow/bat/.config/bat/config -- change --theme="Catppuccin Mocha" to the new theme name
6. stow/lazygit/.config/lazygit/config.yml -- replace all hex color values under gui.theme
7. stow/eza/.config/eza/theme.yml -- replace with the new theme's eza YAML
8. stow/yazi/.config/yazi/theme.toml -- replace with the new theme's yazi TOML
9. stow/yazi/.config/yazi/Catppuccin-mocha.tmTheme -- replace with the new syntax theme (rename file too)
10. stow/zsh/.zshrc -- update FZF_DEFAULT_OPTS color flags
11. stow/zed/.config/zed/settings.json -- update theme.dark, icon_theme, and auto_install_extensions

Keep the same structural layout (powerline segments, pill shapes, etc.) -- just swap the colors.
```

## Verification checklist

After re-theming, verify each tool:

- [ ] **Ghostty** -- open a new terminal window
- [ ] **Zellij** -- check pane frames and mode indicators
- [ ] **zjstatus** -- check status bar colors (may need to restart Zellij)
- [ ] **Starship** -- check prompt segments in a git repo
- [ ] **bat** -- run `bat ~/.zshrc` and check syntax colors
- [ ] **lazygit** -- open lazygit and check borders/selection colors
- [ ] **eza** -- run `ll` and check icon/permission colors
- [ ] **yazi** -- open yazi and check sidebar/preview colors
- [ ] **FZF** -- press Ctrl+r and check fuzzy finder colors
- [ ] **Zed** -- open Zed and check editor theme
