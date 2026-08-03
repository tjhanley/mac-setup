---
name: confluence-page-properties
description: Use when creating or updating any Confluence page via the Atlassian MCP tools (createConfluencePage, updateConfluencePage). Ensures every page includes a structured Page Properties metadata panel at the top with Status, Owner, Last Updated, and other relevant fields. Triggers automatically whenever Confluence page content is being composed — even if the user doesn't mention page properties.
---

# Confluence Page Properties

Every Confluence page created or updated must include a **Page Properties** panel at the top of the page body. This ensures pages are consistently structured, scannable, and queryable across spaces.

## When This Applies

- Any call to `createConfluencePage`
- Any call to `updateConfluencePage`
- Regardless of space or content type

When composing page content, always prepend the properties panel before the main body content.

## Page Properties Format

Use the Confluence **Page Properties macro** in ADF format. This makes properties queryable by the Page Properties Report macro on index pages.

When building ADF content, wrap the properties table inside a `bodiedExtension` with `extensionKey: "details"`:

```json
{
  "type": "bodiedExtension",
  "attrs": {
    "extensionType": "com.atlassian.confluence.macro.core",
    "extensionKey": "details",
    "layout": "default"
  },
  "content": [
    {
      "type": "table",
      "content": [
        // one tableRow per property, each with two tableCells: label and value
      ]
    }
  ]
}
```

### Required Properties

Always include these fields:

| Property | Value |
|---|---|
| **Status** | One of: `Draft`, `In Review`, `Current`, `Archived` — use an ADF `status` node with appropriate color |
| **Owner** | The page author or responsible person — use a mention or plain text |
| **Last Updated** | Today's date in `YYYY-MM-DD` format |

### Optional Properties (include when relevant)

| Property | When to include |
|---|---|
| **Team** | When the page is team-specific (e.g., EngOps, OCTO, Cloud Ops) |
| **Related Tickets** | When the page relates to Jira issues — link them |
| **Confluence Space** | When cross-referencing from another space |
| **Review Date** | For pages that need periodic review |

## If Using Markdown Content Format

When creating pages with `contentFormat: "markdown"` (which doesn't support macros), include a properties table at the very top of the markdown body instead:

```markdown
| Property | Value |
|---|---|
| **Status** | Current |
| **Owner** | Tom Hanley |
| **Last Updated** | 2026-03-20 |

---

# Page Title

(rest of content)
```

This is less powerful than the ADF macro (not queryable by Page Properties Report), but ensures metadata is always visible. Prefer ADF format when possible.

## ADF Full Example

Here's a complete minimal ADF page body with page properties followed by a heading:

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "bodiedExtension",
      "attrs": {
        "extensionType": "com.atlassian.confluence.macro.core",
        "extensionKey": "details",
        "layout": "default"
      },
      "content": [
        {
          "type": "table",
          "attrs": { "isNumberColumnEnabled": false, "layout": "default" },
          "content": [
            {
              "type": "tableRow",
              "content": [
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Status", "marks": [{ "type": "strong" }] }] }]
                },
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "status", "attrs": { "text": "Current", "color": "green" } }] }]
                }
              ]
            },
            {
              "type": "tableRow",
              "content": [
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Owner", "marks": [{ "type": "strong" }] }] }]
                },
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Tom Hanley" }] }]
                }
              ]
            },
            {
              "type": "tableRow",
              "content": [
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Last Updated", "marks": [{ "type": "strong" }] }] }]
                },
                {
                  "type": "tableCell",
                  "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "2026-03-20" }] }]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "type": "text", "text": "Page Title Here" }]
    }
  ]
}
```

## Status Colors

| Status | Color | When to use |
|---|---|---|
| Draft | `yellow` | New page, not yet reviewed |
| In Review | `blue` | Shared for feedback |
| Current | `green` | Approved and up to date |
| Archived | `neutral` | No longer maintained |

Default to `Current` for new documentation pages. Use `Draft` if the content is clearly preliminary.

## Updating Existing Pages

When updating a page that already has page properties, preserve the existing properties and update:
- **Last Updated** → today's date
- **Status** → adjust if appropriate (e.g., Draft → Current)
- Other fields as needed based on the changes

If the existing page has no page properties, add them.
