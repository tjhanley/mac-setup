---
name: simplify
description: Review changed code for reuse, quality, and efficiency, then fix any issues found
disable-model-invocation: true
---

Review recently changed code and simplify it. Follow these steps:

1. Run `git diff HEAD~1` (or `git diff` if uncommitted) to identify changed code
2. Read the changed files in full for context
3. Look for:
   - Unnecessary complexity or nesting
   - Redundant code, dead code, or unused variables
   - Premature abstractions or over-engineering
   - Opportunities to reuse existing functions or patterns in the codebase
   - Inconsistency with surrounding code style
   - Missing error handling at system boundaries
4. Apply fixes directly -- preserve all existing behavior
5. Do NOT:
   - Add docstrings, comments, or type annotations to unchanged code
   - Refactor code that wasn't recently changed
   - Create abstractions for one-time operations
   - Prioritize fewer lines over readability
6. Summarize what was changed and why
