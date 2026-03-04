---
name: powerline-unicode-writes
description: Use when writing Nerd Font glyphs, powerline separators, or any non-ASCII Unicode characters to files. Use when the Edit tool silently drops characters like U+E0B0, U+E0B6, U+F544, or other glyphs above U+007F. Use when statusline.sh, terminal config, or prompt scripts need raw Unicode bytes embedded.
---

# Powerline Unicode Writes

## Overview

The Edit tool silently drops non-ASCII Unicode codepoints (anything above U+007F). Use Python writes or shell escape sequences instead.

## When to Use

- Writing Nerd Font icons or powerline glyphs (U+E000–U+F8FF range) to any file
- After noticing a file ends up with empty strings where glyphs should be
- Any file that needs raw UTF-8 bytes for characters the Edit tool would strip

## Solutions

### Shell scripts — prefer ANSI-C quoting (no raw bytes needed)

```bash
# All ASCII in the file; shell expands at runtime
SEP=$'\ue0b0'
CAP_L=$'\ue0b6'
CAP_R=$'\ue0b4'
CHIP=$'\uf2db'
BRANCH=$'\ue0a0'
ROBOT=$'\uf544'
```

This is the cleanest approach for bash/zsh scripts — no raw Unicode bytes in the file at all.

### Any file type — use Python to write raw bytes

```python
# Use when the target format doesn't support $'\uXXXX' expansion
with open('/path/to/file', 'w', encoding='utf-8') as f:
    f.write('SEP=\u2019\ue0b0\u2018\n')   # glyphs preserved
```

Run via Bash tool:
```bash
python3 -c "
with open('/path/to/file', 'w', encoding='utf-8') as f:
    f.write('content with \ue0b0 glyphs\n')
"
```

## Common Mistakes

| Mistake | Result | Fix |
|---------|--------|-----|
| Using Edit tool with raw Unicode | Glyphs silently stripped, empty strings | Use Python write or `$'\uXXXX'` |
| Using echo with Unicode | Shell-dependent, often broken | Use Python write |
| Forgetting `encoding='utf-8'` in Python | May fail on non-UTF-8 systems | Always specify encoding |

## Verification

After writing, verify glyphs are present:
```bash
python3 -c "
content = open('/path/to/file', encoding='utf-8').read()
for ch in content:
    if ord(ch) > 0x7F:
        print(f'  U+{ord(ch):04X} {ch!r}')
"
```
