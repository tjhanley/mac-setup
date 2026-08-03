---
name: mcp-preflight
description: Shared preflight block for skills that depend on an MCP server. Reference this from any MCP-dependent skill before it runs.
---

# MCP Preflight (shared block)

Paste this as **step 0** of every skill that depends on an MCP server.
Nothing else in the skill runs until preflight passes or explicitly degrades.

---

## Preflight

Before any other work, check each MCP server this skill depends on.

**Required servers for this skill:** `<atlassian|slack|granola|gcal|...>`

For each required server, make exactly **one cheap call** with a short timeout:

| Server      | Probe call                                          | Cheap because                |
|-------------|-----------------------------------------------------|------------------------------|
| `atlassian` | `atlassianUserInfo`                                   | No search, no pagination     |
| `slack`     | `slack_search_users` with the caller's own email      | Single-record lookup         |
| `granola`   | `get_account_info`                                    | No transcript fetch          |
| `gcal`      | list today only, `maxResults: 1`                      | One-day window               |
| `github`    | `get_me`                                              | No repo traversal            |

Record each as **UP** or **DOWN**. Do **not** retry more than once.

### Hard rules

1. **Never go spelunking.** If a server probe fails, you are forbidden from
   inspecting local SQLite files, unix sockets, config paths, process lists, or
   log directories to diagnose it. Report and move on.
2. **Budget: 10 seconds total** for the whole preflight. If you're still
   probing after that, treat remaining unknowns as DOWN.
3. **One line per DOWN server**, in exactly this format:

   ```
   BLOCKED: <server> not connected — run `claude mcp list`, then re-auth <server>
   ```

### On DOWN

Consult the fallback table below.

| Server      | Fallback                                                                 | If fallback also unavailable |
|-------------|--------------------------------------------------------------------------|------------------------------|
| `atlassian` | `acli` or REST via Bash using `$ATLASSIAN_API_TOKEN`                      | Skip section, note it        |
| `granola`   | Read local cache if present; otherwise skip                               | Skip section, note it        |
| `slack`     | None — Slack data is not reconstructible                                  | Skip section, note it        |
| `gcal`      | None                                                                      | Skip section, note it        |
| `github`    | `gh` CLI via Bash                                                         | Skip section, note it        |

**Degrade, don't halt.** If a section's data source is DOWN and has no
fallback, omit that section from the output and add its BLOCKED line to a
`## Preflight failures` heading at the top of the result. A partial brief with
a visible gap is more useful than no brief.

**Exception:** if a server is DOWN and this skill's *entire* purpose depends on
it (e.g. `granola` for `/granola-sync`), stop immediately after printing the
BLOCKED line. Do not produce an empty deliverable.

### On all UP

Print nothing. Proceed silently to step 1.

---

## Per-skill server map

Fill this in once and keep it accurate — it's what makes the preflight cheap.

```yaml
morning-pipeline: [atlassian, slack, gcal, granola]
jira-sync:        [atlassian]
team-status:      [atlassian]
interrupts:       [slack, atlassian]
recruiting-scan:  [gmail]
granola-sync:     [granola]        # hard-fails: no fallback, sole purpose
gcal-sync:        [gcal]           # hard-fails
organize:         []               # no MCP dependency — skip preflight entirely
```
