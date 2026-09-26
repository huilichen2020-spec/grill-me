# Mode 3 — Skill-iteration: full workflow

Read before step 1 of Mode 3 (SKILL.md holds the skeleton and the hard rules).

### When to invoke

- User says "grill {skill-name}" or "iterate on {skill-name}"
- User says "this skill isn't doing what I want"
- User wants to audit a collection of skills

### Workflow

1. **Locate the skill.** Run `scripts/locate_skill.py {skill-name}`
   to find:
   - Active path (where the skill is currently running)
   - Canonical repo path (where to apply fixes)
   - Deploy method (install.sh + UI, manual edit, or read-only)

2. **Inventory the skill.** Run `scripts/skill_inventory.py
   {canonical-path}` to get:
   - SKILL.md frontmatter + description length
   - Reference files (titles + line counts + first-paragraph summary)
   - Scripts (function signatures + docstrings)
   - Cross-references to other skills
   - Trigger phrases extracted from description
   - Modes / commands / prefixes documented

   This is the context packet for grilling.

3. **Spec-grill (Waves 1-3).** Use `references/waves-skill.md` for
   question templates:
   - Wave 1 — basics: what problem, who's the user (Claude or human),
     success criterion
   - Wave 2 — ambiguity: command boundaries, trigger edge cases,
     hard-rule vs strong-preference
   - Wave 3 — blind spots: unstated assumptions, deliberate omissions,
     past feedback that didn't change the spec

4. **(Optional) Live-test grill.** Offer: "Want me to run this skill
   on a real input and grill the output vs the spec?" If yes:
   - User provides sample input
   - Run the skill as designed
   - **Spawn a fresh-context subagent via the Agent tool** — give it
     the spec + the output, ask "where's the gap?"
   - Fresh-context grader is critical: avoids the original generation's
     blind spots
   - Some skills have side effects (calendar-invite, signature-stamp);
     warn before running and skip if user prefers spec-only grill

5. **Gap synthesis.** Combine spec-grill answers + live-test
   observations → produce structured grill report (see
   `references/output-formats.md` Skill-iteration template).

6. **Apply (or save report).** Manual review — present
   recommendations; user accepts all / cherry-picks / saves report
   only. **No auto-apply in v1** — too much trust required. After
   accept, the workflow:
   - Apply edits to the canonical repo
   - Re-package as `.skill` (if applicable)
   - Run `install.sh` to deploy
   - Tell user to re-install via Claude UI (so the manifest registered
     version updates)

### Output

The grill report goes in chat (SOUL: no unasked .md files summarizing a task). Write the file only when Huili picks "save report" in step 6, at:
- `{chat-root}/REPORTS/REPORT-SKILL-GRILL_{date}_{skill-name}.md` if
  in cowork with a chat root
- `~/Downloads/skill-grill-reports/{date}-{skill-name}.md` otherwise

Format: see `references/output-formats.md`.

### Multi-skill batch (audit mode)

When user says "audit my ra-* skills" or "audit all skills":
1. List skills in scope (ask user to narrow if too many)
2. For each: brief Wave-1-only spec-grill (3 questions max per skill)
3. Aggregate: which skills feel right, which need iteration
4. Output: workspace-level audit report identifying which skills to
   deep-grill next


## Exit criteria — Skill-iteration

Don't stop grilling until ALL apply (SKILL.md "Per-mode exit criteria").

- [ ] One specific failure case that triggered the iteration is named
      with verbatim user input + verbatim Claude output
- [ ] The trigger keywords / signals the new behavior would activate
      on are listed (or "no new triggers" with reason)
- [ ] A 1-line success test: "after this change, when I do X, the
      skill will Y"
- [ ] Whether this is a description fix, a workflow fix, or a new
      reference is decided
