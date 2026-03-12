---
name: necronomicon-format
description: Use when asked to format a note in the necronomicon Obsidian vault, or when a file has tags containing "clippings" and no structured type frontmatter. Detects note type from frontmatter and applies vault formatting conventions.
---

# Necronomicon Note Formatter

Format vault notes by reading frontmatter `type` and applying the matching template.

## Process

1. Read the file
2. Check `type` in frontmatter
3. If no `type` but tag is `clippings`, infer type from content (D&D Beyond character sheet → `character`; D&D Beyond magic item → `item`; wiki page → `npc` or `faction`)
4. Also check Party.md for additional context on player characters
5. Rewrite the file in the correct format

---

## Frontmatter by Type

**character** (player character)
```yaml
type: character
campaign: "[[Campaign Name]]"
player: PlayerName
class: Class Level / Class Level
race: Race
deity: "[[Deity]]"        # if applicable
source: https://dndbeyond.com/...
tags: [dnd, campaign-slug, character, player-character]
```

**npc**
```yaml
type: npc
campaign: "[[Campaign Name]]"
faction: "[[Faction]]"    # if applicable
role: Ally / Antagonist / Neutral
source: https://...
tags: [dnd, campaign-slug, npc, role]
```

**item**
```yaml
type: item
campaign: "[[Campaign Name]]"
owner: "[[Character]]"
rarity: common/uncommon/rare/very rare/legendary
attunement: true/false
source: https://dndbeyond.com/...
tags: [dnd, campaign-slug, item, magic-item]
```

**faction**
```yaml
type: faction
campaign: "[[Campaign Name]]"
role: Antagonist / Allied / Neutral
source: https://...
tags: [dnd, campaign-slug, faction]
```

---

## Format per Type

### character
```
# Name
*Race — Class Levels* — **Level N**
---
## Core Stats
| AC | HP | Speed | Initiative | Prof Bonus |
## Ability Scores
| STR | DEX | CON | INT | WIS | CHA |
## Saving Throws (if available)
## Senses
## Proficiencies (Armor, Weapons, Tools, Languages)
## Skills *(✓ proficient, ✓✓ Expertise)*
## Weapons table (Hit, Damage, Range, Notes)
## Actions / Bonus Actions / Reactions  ← use callouts
## Passive Features  ← use callouts
> [!note] Combat Role  ← from Party.md context
**Campaign:** [[X]] | **Party:** [[Party]] | **Sheet:** [D&D Beyond](url)
```

### npc
```
# Name
*Race/Type — Role*
> italic quote if notable
---
## Campaign Status  ← [!warning] if threat
## Description
## Personality
> [!tip] DM Note
## Combat
## Key Items table
## Background
## Relationships table
**Related:** [[X]] | **Source:** [Wiki](url)
```

### item
```
# Item Name
*Item Type, Rarity (requires attunement)*
Flavour description. Italic quote if present.
---
## Benefits  ← one callout per ability
## Attunement (if applicable)
**Owner:** [[X]] | **Loot source:** [[Y]]
```

### faction
```
# Faction Name
*(pronunciation if needed)*
One-line description.
---
## Campaign Status  ← [!warning] if active threat
## What They Do
## Leadership table
## Membership
## Surface Operations / Locations
## Relationships table
**Key NPC:** [[X]] | **Related:** [[Y]]
```

---

## Callout Types

| Type | Use for |
|---|---|
| `[!sword]` | Attack abilities, offensive features |
| `[!shield]` | Defensive abilities, AC bonuses |
| `[!magic]` | Magical effects, spell-like abilities |
| `[!divine]` | Cleric/Paladin features, deity-linked abilities |
| `[!action]` | Action economy features (Action Surge, Second Wind) |
| `[!spell]` | Spells and spell slots |
| `[!passive]` | Always-on features |
| `[!artificer]` | Artificer-specific features |
| `[!warning]` | Threats, dangers, DM alerts |
| `[!tip]` | DM notes, tactical suggestions |
| `[!note]` | General notes, combat role |
| `[!gear]` | Key equipment |

---

## Vault Conventions

- **Vault root:** `/Users/tom/necronomicon`
- **Campaign files:** `Atlas/D&D/[Campaign Name]/`
- **New notes** create in same folder as current note (Obsidian setting)
- Cross-reference Party.md for HP, AC, gear, and combat role notes on PCs
- Jarlaxle = the correct spelling (not Jarjaxon, not Jarjaxle)
- Elminster = the correct spelling (not Eleminster)
- Strip all D&D Beyond / wiki navigation noise from clipped content
