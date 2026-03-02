# mac-setup — Agent Guidelines

## Repo overview

Opinionated macOS bootstrap: Homebrew + GNU Stow dotfiles + mise runtimes + Catppuccin Mocha theming. Entrypoint is `./setup.sh` which calls `bootstrap/bootstrap-mac.zsh`.

## Documentation maintenance

**Every change that adds, removes, or modifies a feature must update docs in the same commit.**

Files to keep in sync:

| File | Purpose |
|------|---------|
| `README.md` | User-facing quick-start, "What It Does" steps, dotfiles structure, CLI tool lists, notes |
| `docs/mac-setup-log.md` | Detailed implementation log — bootstrap behavior, stow packages, theme/terminal config, shell config, repo hygiene |

When changing:
- **bootstrap functions** — update the numbered "What It Does" list in README and the "Bootstrap behavior" section in the log
- **stow packages** (add/remove/rename) — update the `stow/` tree in README and the "Stow packages" section in the log
- **Brewfile** — update the "CLI Tools" / "Casks" lists in README and the "Installed/managed tools" section in the log
- **theme/terminal config** — update "Theme + terminal work" in the log
- **shell config (.zshrc/.zprofile)** — update "Shell config" in the log
- **scripts/** — update "Customize" in README and "Repo hygiene" in the log
- **new tooling or plugins** — add to relevant sections in both files

## Code conventions

### Bootstrap script (`bootstrap/bootstrap-mac.zsh`)
- Every function supports `DRY_RUN` — print what would happen with `print -P "%F{yellow}dry-run:%f ..."` and return early
- Use `run_cmd` for commands that should be skipped in dry-run
- Use `log()` for step headers, `ok()` for success, `warn()` for warnings
- Functions are idempotent — check if work is already done before acting
- New install functions go before `post_notes()` in file order
- Wire new functions into `main()` in logical dependency order

### Stow packages
- Each package lives under `stow/<name>/` mirroring `$HOME` structure
- Stow target is always `$HOME`
- The `nvim` package is excluded from main `stow_dotfiles()` and stowed separately via `stow_nvim_plugins()` after LazyVim install

### General
- Shell: zsh with `set -euo pipefail`
- Theme: Catppuccin Mocha everywhere
- No emojis in code or docs (unicode symbols like checkmarks in log output are fine)
