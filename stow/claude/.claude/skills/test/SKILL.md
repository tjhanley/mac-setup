---
name: test
description: Run tests and fix failures
disable-model-invocation: true
argument-hint: "[test-file-or-pattern]"
---

Run tests and fix any failures. Follow these steps:

1. Detect the test framework (look for package.json scripts, Makefile targets, bats, pytest, go test, etc.)
2. Run the tests:
   - If $ARGUMENTS is provided, run only those tests
   - Otherwise run the full suite
3. If tests pass, report success and stop
4. If tests fail:
   - Read the failing test and the code it exercises
   - Diagnose the root cause
   - Fix the code (not the test) unless the test itself is wrong
   - Re-run to confirm the fix
   - Repeat until green
5. Summarize what failed and what was fixed
