---
name: jira-sync
description: Sync Jira issues for the team roster into a local cache. Fully paginates and refuses to emit truncated counts.
---

# jira-sync

## 0. Preflight

Required servers: `atlassian`. Run the shared MCP preflight block.
This skill has no useful degraded mode — if `atlassian` is DOWN, print the
BLOCKED line and stop.

## 1. Load roster

Read the people roster. Every downstream count is per-person, so a missing
roster entry silently drops a person from the report — assert the roster
parsed to a non-empty list before continuing.

## 2. Query with full pagination

**The MCP JQL tool caps at 100 issues per response.** Any count derived from a
single call is wrong whenever `total > 100`. Loop.

```
startAt = 0
collected = []
total = null

loop:
  page = searchJiraIssuesUsingJql(jql, startAt=startAt, maxResults=100,
                                  fields=["key","assignee","status","priority","updated"])
  if total is null: total = page.total
  collected += page.issues
  startAt += len(page.issues)
  if len(page.issues) == 0: break        # guard against a non-advancing loop
  if startAt >= total: break
  if startAt > 5000: break               # runaway guard, treat as failure below
```

Always request `fields` explicitly. Fetching full issue bodies is what blew the
tool output limit on previous runs.

## 3. Project fields with jq

Project immediately, before anything else reads the payload:

```bash
jq -c '[.issues[] | {
  key,
  assignee: (.fields.assignee.emailAddress // "unassigned"),
  status:   .fields.status.name,
  priority: (.fields.priority.name // "none"),
  updated:  .fields.updated
}]' page.json
```

Note `// "unassigned"` and `// "none"` — unassigned issues and issues with no
priority are both real and both previously broke the filter. If a `jq` filter
errors, print one sample record's structure before retrying. Do not retry
blindly.

## 4. Assert completeness — this is the whole point

Before writing anything:

```
if len(collected) != total:
    emit: "WARNING: collected {len(collected)} of {total} issues — counts below are INCOMPLETE"
    do NOT write the cache block
    stop
```

Never write a cache block from a partial result set. A missing report is
recoverable; a report that looks authoritative and is 14% of reality is not.

Also assert every roster member appears in the per-person breakdown, even with
a count of zero. A person absent from the output reads as "no tickets" when it
may mean "dropped during pagination."

## 5. Write cache

Emit the harness-cache block with a provenance header:

```yaml
# jira-sync
# generated: 2026-08-03T14:59Z
# jql: <the exact query>
# total: 735
# collected: 735
```

`total` and `collected` go in the file. If someone later reads a stale cache,
they can see at a glance whether it was complete.

## 6. Summary

```
Synced 735/735 issues across 9 people · cache written
```

---

## Same fix for /team-status

`/team-status` consumes these counts. Apply the identical pagination loop and
the `collected == total` assertion there, or have it read only from a cache
whose header shows `total == collected` and refuse to render otherwise:

```
if cache.total != cache.collected:
    print "STALE/PARTIAL cache — run /jira-sync first"; stop
```
