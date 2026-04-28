# grill-me

Socratic interrogation skill for Claude. Three auto-detected modes:

| Mode | When | Output |
|---|---|---|
| **General** | "grill the plan", "grill before I start", "grill my idea" | In-chat summary of agreed-upon plan with assumptions/risks/decision points |
| **Decision-grill** | "should I A or B", "compare X vs Y" | In-chat decision report with surfaced dimensions, tradeoffs, recommendation |
| **Skill-iteration** | "grill ra-draft-editor", "iterate on outreach-email" | Markdown report with line-level edit recommendations for the targeted skill |

Premise: **misalignment is the #1 collaboration failure mode**. A 5-minute pre-task interrogation prevents 30+ minutes of "that's not what I asked for."

The skill works across every skill collection — `ra-*` (research-workspace-skills), comms-hub-skills, Claude Code plugins (vix-trading, uoft-inbox-sync, etc.), and Anthropic-managed skills (read-only recommendations only).

## Install

```bash
./install.sh
```

Then restart your Claude session. To register permanently in Claude's backend, package as `.skill` via skill-creator and drag into Claude UI.

## Triggers (selected)

```
"grill me"                       → General mode
"grill the plan"                 → General mode
"grill A vs B"                   → Decision-grill
"should I X or Y"                → Decision-grill
"grill ra-draft-editor"          → Skill-iteration
"iterate on outreach-email"      → Skill-iteration
"audit my ra-* skills"           → Skill-iteration (batch)
```

## Mechanics (universal across modes)

- One question at a time via `AskUserQuestion` popup
- 2-4 multiple-choice options + Other
- Wave 1 (basics) → Wave 2 (ambiguity) → Wave 3 (blind spots)
- Apply 2-3 lenses per session (see `references/lens-library.md`)
- **Tension-following overrides script** — if an answer reveals a contradiction, drop the planned wave and follow the thread

## Skill structure

```
grill-me/
├── SKILL.md
├── references/
│   ├── waves-general.md       # General mode question library
│   ├── waves-skill.md         # Skill-iteration question library
│   ├── lens-library.md        # Strategic / Systems / Psychological lenses
│   ├── skill-locations.md     # Registry of skill collections
│   └── output-formats.md      # Per-mode output templates
└── scripts/
    ├── locate_skill.py        # Find a skill by name across all locations
    └── skill_inventory.py     # Parse a skill's structure → context packet
```

## Inspired by

- Matt Pocock's [grill-me](https://github.com/mattpocock/skills) (the lean original)
- Jekudy's [grillme-skill](https://github.com/Jekudy/grillme-skill) (wave + lens framework)

## License

MIT
