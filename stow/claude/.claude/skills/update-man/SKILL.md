---
name: update-man
description: Update man/man7/mac-setup.7 to reflect changes to stow packages, bootstrap steps, tools, or aliases
disable-model-invocation: true
---

Keep `man/man7/mac-setup.7` in sync with the repo after changes. Follow these steps:

1. Read `man/man7/mac-setup.7` in full
2. Read `README.md` and `docs/mac-setup-log.md` to understand current state
3. Check what changed with `git diff HEAD~1 -- brew/Brewfile bootstrap/bootstrap-mac.zsh stow/ README.md` (or `git diff` if uncommitted)
4. Update the man page for any of the following that changed:

   **Date header** (line 1): update to today's date if content changed

   **BOOTSTRAP STEPS**: the man page uses a condensed summary (not every step) — update if a meaningfully new capability was added or removed

   **STOW PACKAGES table**: add a row for every new `stow/<package>/` directory; remove rows for deleted packages. Format: `package\tkey files or description`

   **GIT ALIASES / TOOL ALIASES / SHELL ALIASES**: update if `.zshrc` aliases changed

   **RUNTIMES**: update if `mise/config.toml` versions changed

   **THEME**: update if new tools were themed

   **FILES**: update if new important config file paths were added

   **COMMON TASKS**: update if new scripts or workflows were added

5. Verify the man page renders without errors:
   ```
   man ./man/man7/mac-setup.7
   ```
6. Commit:
   ```
   git add man/man7/mac-setup.7
   git commit -m "docs(man): update mac-setup.7 for <brief description of changes>"
   ```

Do NOT rewrite sections that didn't change. Do NOT convert between formats (the man page uses troff `.TS`/`.TE` tables — keep them).
