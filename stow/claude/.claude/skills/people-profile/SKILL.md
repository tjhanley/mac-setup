---
name: people-profile
description: Use when creating or updating a people profile note in the necronomicon Obsidian vault. Triggers on "create a profile for", "add a person", "people note", "who is [name]" when the intent is to persist a note.
---

# People Profile

Create or update people profile notes in the necronomicon vault at `/Users/thomas.hanley/necronomicon/people/`.

## File Naming

`firstname-lastname.md` (all lowercase, hyphen-separated). Never single-name files.

## Frontmatter

Required fields (all must be present, leave blank if unknown):

```yaml
type: person
# Identity
name:
title:
company:
email:
phone:
slack-handle:            # Slack member ID (e.g. U0123ABCD)
linkedin:
# Relationship
last-contact:            # YYYY-MM-DD
relationship:            # report | peer | stakeholder | external | candidate
how-we-met:
# Org
reports-to:              # firstname-lastname slug
team:
location:                # City, Country
timezone:                # e.g. America/Los_Angeles
# Context
jira-handle:             # Jira account email
tags: []
created: YYYY-MM-DD
custom-width: 100
```

## Sections

```markdown
## Context
<Full Name> (<pronunciation + language if tonal>; <anglicized name if known>). <Role summary>.

## Org
| Field | Value |
|-------|-------|
| Title | |
| Team | |
| Reports to | |
| Location | |
| Timezone | |

## Signals
**Slack signals:** ...
**Email threads:** ...
**Key signals from Atlassian:** ...

## OKR & Project Assignments
<!-- Populated for directs. Leave blank for externals. -->

## Talking Points
<!-- Pre-meeting prep: what to cover, open questions, what they care about -->

## Follow-ups
- [ ]

## Notes
<!-- Tone, working style, personal context, pronunciation -->
```

## Pronunciation Guide for Tonal Language Names

**REQUIRED** for names from: Mandarin, Cantonese, Vietnamese, Thai, Korean, Japanese.

Format in the first line of Context:

```
Yixiang Chen (pronunciation: "Ee-shyang Chen"; Mandarin).
Xuanran Zong (pronunciation: "Shwen-rahn Dzong"; Mandarin).
Min-Hsiu Cheng (pronunciation: "Min-Shyo Chung"; Mandarin).
Dawei Huang (pronunciation: "Dah-way Hwahng"; Mandarin).
Gunhee Han (pronunciation: "Goon-hee Hahn"; Korean).
```

Rules:
- Use English phonetic approximation in quotes, not IPA
- State the language after semicolon
- If an anglicized/Western name is known, add it: `Qiqi Zhao (pronunciation: "Chee-chee Jow"; Mandarin; goes by "Kiki").`
- If unsure of pronunciation, omit rather than guess wrong — flag it as a follow-up
- Non-tonal names (Indian, European, etc.) do NOT need a pronunciation guide

## Slack Enrichment

Run after you have the person's email. Writes to frontmatter and Signals section.

1. **Look up Slack member ID** via `slack:slack-search` skill — search `"<email>"` or `"<Full Name>"` in Slack
2. **Extract from Slack profile:**
   - Member ID (format: `U` followed by 8 alphanumeric characters, 11 chars total, e.g. `U0123ABCD`) → write to `slack-handle` frontmatter
   - Display title → write to `title` frontmatter if blank
   - Timezone → write to `timezone` frontmatter if blank
3. **Recent signals** — search Slack for `"<Full Name>"` or `from:<slack-handle>`, last 30 days:
   - Note active channels, recent topics, tone
   - Add to **Signals** section under `**Slack signals:**`

If Slack returns no results or auth fails, skip and note in Signals section.

## Apple Mail Enrichment

Run after you have the person's email. Surfaces recent communication history.

```bash
mdfind -onlyin ~/Library/Mail "kMDItemTextContent == '*email@example.com*'c" | head -20
```

The `c` flag makes the search case-insensitive. Results are `.emlx` file paths. Extract the subject from the Spotlight metadata:

```bash
mdls -name kMDItemSubject -name kMDItemAuthors -name kMDItemLastUsedDate <path-to-emlx>
```

Add recent thread subjects to **Signals** section under `**Email threads:**`.

If no results, skip silently.

## Atlassian Research Workflow

Search in this order to build the profile:

1. **Rovo Search** (`searchAtlassian`): `"<Full Name>"` — broadest signal
2. **Rovo Search** with role keywords: `"<Name> role team lead director manager"`
3. **Jira projects cheat sheet** (page ID `1604780127`): check if they lead any projects
4. **JQL assigned issues**: `assignee = "<email>" ORDER BY updated DESC` — shows current work
5. **SDLC Implementation Plan** (page ID `3262775298`): check for gate ownership

Synthesize into:
- **Role / title** (look for "VP", "Director", "Lead", "Manager" in ticket text)
- **Jira project ownership** (from cheat sheet)
- **Domain coverage** (from assigned issues and mentions)
- **Key collaborators** (use `[[firstname-lastname]]` wikilinks for people already in vault)
- **Key Atlassian signals** (cite ticket keys)

## Wikilinks

- Always check `ls /Users/thomas.hanley/necronomicon/people/` before writing collaborator links
- Use `[[firstname-lastname]]` format for people with existing profiles
- Use plain text for people without profiles

## Updating Existing Profiles

When updating, preserve:
- All existing follow-ups (especially incomplete ones)
- Personal notes and observations (tone, relationship context)
- `last-contact` dates
- Merge new Atlassian findings under `**Key signals from Atlassian:**`
