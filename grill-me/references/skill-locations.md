# Skill Locations Registry

Used by `scripts/locate_skill.py` to find a skill by name and
determine the canonical repo + deploy method.

When grill-me operates in **Skill-iteration mode**, it needs to know
where to apply edits. Different skill collections have different
deploy paths.

---

## The three layers where skills live

### Layer 1 — Cowork session (live, currently-running version)

Path: `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/{session-id}/{plugin-id}/skills/{skill-name}/`

- This is what Claude is actually using right now
- Gets wiped/restored by sync from manifest.json
- Don't edit here as the canonical location — edits get reverted

### Layer 2 — Claude Code plugins

Path: `~/.claude/plugins/{plugin-name}/skills/{skill-name}/`

- Hand-installed plugins (vix-trading, uoft-inbox-sync, download-research-articles)
- Persistent across sessions
- Editing here is fine; install.sh-based plugins work as the canonical source

### Layer 3 — Canonical repos (the source of truth)

Path: `~/Documents/Claude/Skills/{repo-name}/`

- Git-tracked source of truth for custom skills
- Has install.sh + pull.sh + .skill packaging
- Edits here propagate to Layer 1 via install.sh + .skill UI install
- This is where grill-me applies fixes

---

## Known canonical repos (Huili's collections)

| Repo | Path | Skills | Deploy method |
|---|---|---|---|
| **research-workspace-skills** | `~/Documents/Claude/Skills/research-workspace-skills/` | ra-workspace, ra-idea-incubator, ra-draft-editor, ra-paper-diagnose, ra-annotations-extractor, ra-paper-finalize, ra-paper-diagram, humanizer, innovation-diagnosis, download-research-articles | install.sh + .skill UI register |
| **comms-hub-skills** | `~/Documents/Claude/Skills/comms-hub-skills/` | comms-hub, outreach-email, outreach-followup, calendar-invite, uoft-admin, signature-stamp, inbox-triage | install.sh + .skill UI register |
| **grill-me** (this skill) | `~/Documents/Claude/Skills/grill-me/` | grill-me | install.sh + .skill UI register |

## Known Claude Code plugins

| Plugin | Path | Skills | Deploy method |
|---|---|---|---|
| **vix-trading** | `~/.claude/plugins/vix-trading/` | vix-trading-assistant | manual edit at this path |
| **uoft-inbox-sync** | `~/.claude/plugins/uoft-inbox-sync/` | uoft-inbox-sync | manual edit at this path |
| **download-research-articles** | `~/.claude/plugins/download-research-articles/` | download-research-articles | manual edit; also vendored in research-workspace-skills repo |

## Anthropic-managed skills (read-only)

These have permanent `skill_XXX` IDs in the manifest, but their source
is Anthropic-controlled. grill-me can produce **recommendations**, but
edits have to be applied as a fork or wrapper.

Examples: skill-creator, skill-refinement, docx, pptx, xlsx, pdf,
canvas-design, mcp-builder, web-artifacts-builder, theme-factory,
schedule, internal-comms, calendar-invite (the Anthropic version),
outreach-email (the Anthropic version), market-etf-briefing,
opportunities-briefing, essay-assessor, utoronto-admin, etc.

When `locate_skill.py` finds an Anthropic-managed skill, it returns
`is_anthropic_managed=true` and grill-me's output mode shifts to
read-only recommendations only.

---

## How `locate_skill.py` resolves a skill name

Search order:

1. **Match against canonical repos.** Walk `~/Documents/Claude/Skills/*/`
   and look for a directory matching the skill name (or a subdirectory
   per repo's structure).
2. **Match against Claude Code plugins.** Walk `~/.claude/plugins/*/skills/*/`
   for a matching skill.
3. **Match against active cowork session.** Walk
   `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/*/*/skills/*/`
   for a matching skill.
4. **Cross-reference manifest.** Read the cowork session's manifest.json
   to determine if the skill is Anthropic-managed (skillId starts with
   `skill_` and creatorType is anthropic) or user-created.

Returns:

```json
{
  "skill_name": "ra-draft-editor",
  "active_path": "~/Library/.../skills/ra-draft-editor",
  "canonical_repo": "research-workspace-skills",
  "canonical_path": "~/Documents/Claude/Skills/research-workspace-skills/ra-draft-editor",
  "deploy_method": "install.sh + .skill UI",
  "is_anthropic_managed": false,
  "skill_id": "skill_01BrDSkMWLFHiSgu3Gk7Gw24"
}
```

---

## Adding a new repo to the registry

When you add a new skill collection, append a row to the table above.
The script reads this file at startup to know where to look.

If a skill exists in multiple places (e.g., vendored in a repo AND
installed in a plugin), the canonical version is the one in the
repo with active development — grill-me applies edits there.
