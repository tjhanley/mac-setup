---
name: verify-references
description: Use when composing or updating documentation that includes external URLs — Confluence pages, README files, wiki pages, or any content with reference links. Ensures every cited URL resolves before publishing. Triggers on WebFetch of documentation pages with link tables, creation of reference sections, or any content containing external hyperlinks.
---

# Verify References

## Overview

Every external URL included in documentation must be verified before publishing. Broken links erode trust and waste readers' time.

## When to Use

- Writing or updating Confluence pages with reference/link tables
- Composing any documentation that cites external URLs
- Migrating documentation between systems (URLs may have changed)
- Reviewing existing pages for link rot

## Core Rule

**Never publish a URL you haven't fetched.** If it redirects, follow the redirect chain to the final destination and use that URL instead.

## Process

1. **Collect** all external URLs from the content being written or updated
2. **Fetch** each URL with WebFetch (parallel when possible)
3. **Follow redirects** — if a URL returns 301/302, follow to the final destination
4. **Replace** any URL that 404s or redirects to a different page:
   - Search for the correct current URL (WebSearch with `site:` filter on the same domain)
   - Verify the replacement URL resolves to the expected content
5. **Update** the content with verified URLs before publishing

## Handling Common Failures

| Failure | Action |
|---|---|
| **404** | Search the same domain for the topic. Use the best match. |
| **301/302 redirect** | Follow the chain. Use the final URL. |
| **Redirect to wrong page** (e.g., generic homepage) | The old URL structure is dead. Search for the correct page. |
| **JavaScript SPA** (content loads but can't verify) | Check the HTTP status code. If 200, accept. If the page title/content doesn't match the topic, search for correct URL. |
| **Domain migration** (e.g., `foo.com/docs` → `docs.foo.com`) | Search the new domain for equivalent content. |

## Red Flags

- Copying URLs from an old document without checking them
- Assuming a URL works because "it worked last time"
- Skipping verification because "it's just a reference section"
- Using URLs from memory or training data without fetching

## Common Mistakes

- **Only checking the first link** — check ALL of them
- **Accepting a redirect without verifying the destination** — a 301 to a generic homepage is not "working"
- **Using old URL formats** — vendors migrate docs frequently (e.g., JFrog `jfrog.com/help/r/` → `docs.jfrog.com/`)
