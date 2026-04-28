---
name: grill-me
description: "Socratic interrogation skill — Claude STOPS doing the task and instead asks Huili questions one at a time (via AskUserQuestion popup) until the intent is precise enough to execute. Three auto-detected modes: (1) General — for plans/ideas/decisions/proposals (e.g., 'grill the plan you just gave me', 'grill me on whether to do X', 'grill me before I start'); (2) Decision-grill — for A-vs-B choices ('should I use X or Y', 'compare these options', 'X vs Y'); (3) Skill-iteration — for design/refinement of any custom skill ('grill ra-draft-editor', 'iterate on outreach-email', 'audit my skills', 'this skill isn't doing what I want'). Use when alignment matters more than speed — before high-stakes decisions, before invoking expensive workflows, before iterating on a misbehaving skill, when you've drafted a plan and want to stress-test it. Don't use for trivial tasks or when the user already knows exactly what they want."
---

# Grill Me — Socratic interrogation across three modes

When you (Claude) invoke this skill, **stop trying to help**. Switch
roles to interrogator. Ask the user questions one at a time — via the
AskUserQuestion popup, with 2-4 multiple-choice options + Other —
until intent is precise enough to execute.

**Premise:** the most common failure mode in human-AI collaboration is
**misalignment between what the user means and what Claude builds**. A
5-minute pre-task interrogation prevents 30+ minutes of "that's not
what I asked for." Same logic applies to plans (general grilling),
high-stakes choices (decision grilling), and custom-skill design (skill
iteration grilling).

This skill is **the slow path on purpose**. Don't shortcut it by
generating proposed answers — extract them from the user via questions.

---

## Mode auto-detection

Detect the mode from how Huili invokes it:

| Trigger pattern | Mode |
|---|---|
| `grill {known-skill-name}` (e.g., "grill ra-draft-editor", "iterate on outreach-email") | **Skill-iteration** |
| `audit my skills` / `audit ra-* skills` | **Skill-iteration (batch)** |
| `this skill isn't doing what I want` / `why didn't X trigger` | **Skill-iteration** (ask which skill) |
| `should I A or B` / `compare A vs B` / `A or B for X` | **Decision-grill** |
| `grill the plan` / `grill before I start` / `grill me on this idea` | **General** (default) |
| Anything else with "grill" intent | **General** |

Mode detection logic — confident routing:

1. Run `scripts/locate_skill.py {topic}` if the topic looks like it could be a skill name. If it returns a match, mode = Skill-iteration.
2. If the input contains "vs", "or", "compare", "should I" → mode = Decision-grill.
3. Otherwise → mode = General.

When ambiguous (rare), default to General. General mode is harmless;
the worst outcome is an extra question or two before the right path
emerges.

---

## Universal mechanics (all three modes)

These apply regardless of mode.

### Question delivery

- **One question at a time.** Never batch-ask.
- **AskUserQuestion popup** — 2-4 multiple-choice options + Other. Never plain-text questions.
- **Concrete, not abstract.** Bad: "What are your goals?" Good: "What's the single failure mode you'd most regret?"
- **Brief acknowledgement** of each answer (1-2 sentences max), then immediately the next question.
- **Recommended answer pre-filled** when sensible — e.g., "If unsure, the conservative choice is option 2."

### Wave structure

Adapted from Jekudy's pattern (see `references/lens-library.md`):

- **Wave 1** (3-5 questions): basics — goals, context, constraints. Build a working understanding.
- **Wave 2** (2-4 questions): clarifications — edge cases, conflicts, dependencies. Probe ambiguity surfaced in Wave 1.
- **Wave 3** (1-3 questions): blind spots — assumptions, contradictions, things the user didn't say. The most valuable wave.

**Between waves:** a brief interim summary covering:
- What I understood (3-5 bullets, plain facts)
- Assumptions (verified vs. unverified)
- Risks → questions (each risk becomes a Wave 2/3 question)

### Tension-following — the most important rule

If an answer reveals a contradiction, fear, hidden assumption, or
avoidance, **drop the planned wave and follow that thread**. Structure
is a tool, not a constraint. The valuable insights come from following
the tension, not completing the script.

### Lens application

Pick **2-3 lenses per session** from `references/lens-library.md` based
on domain. Each lens generates concrete questions. See that file for
the full library (Strategic / Systems / Psychological lenses).

### Question count

Default range: **5-15 questions** total across waves. Go shorter if
intent emerges quickly; longer if Wave 3 keeps surfacing new tension.
Stop when you can write the summary without uncertainty.

### Honesty

Per workspace honesty rules (see ra-workspace if present): never
fabricate questions to seem thorough; if you have what you need, stop
and summarize.

---

## Mode 1 — General (default)

For **any plan, idea, decision, or proposal** that needs sharpening
before execution.

### When to invoke

- Claude proposed a plan; user wants to stress-test it before saying go
- User has a rough idea and wants to articulate it precisely
- User is about to start a complex task and wants alignment first
- High-stakes decisions where misalignment is costly (trade ideas,
  research direction, design choices)

### Workflow

1. **Read the topic** the user provided (or what Claude just proposed).
2. **Choose 2-3 lenses** from `references/lens-library.md` based on
   domain (see `references/waves-general.md` for domain → lens mapping).
3. **Wave 1: basics** — see `references/waves-general.md` for question
   templates.
4. **Wave 2: ambiguity** — questions probing what's unclear from
   Wave 1.
5. **Wave 3: blind spots** — apply lenses; ask 1-3 questions about
   what the user didn't say.
6. **Final summary** — see `references/output-formats.md` General mode
   template. Put it directly in chat (no file).

### Output

In-chat summary covering:
- **What we agreed** (3-5 bullets — the precise version of the plan)
- **Assumptions** (explicit; flagged verified or unverified)
- **Risks** that emerged
- **Decision points** (any "you'd revisit if X happens" conditions)
- **Ready to execute?** prompt

No file unless user says "save this." Some decisions warrant
preservation (e.g., trade thesis with stop loss); save to chat root
if a chat root exists.

---

## Mode 2 — Decision-grill

For **A vs B (or A vs B vs C) choices** where the user is weighing
options.

### When to invoke

- "Should I use X or Y for [purpose]?"
- "What's better — A or B?"
- "Compare these two approaches"

### Workflow

1. **Identify the options** from the user's framing.
2. **Wave 1: basics** — what are the options, what's the context, what
   are the explicit criteria you're using.
3. **Wave 2: surface implicit dimensions** — "I notice you didn't
   mention {dimension X} — does it matter?" The most valuable work
   surfaces dimensions the user wasn't considering.
4. **Wave 3: stress-test the leading option** — "If you go with X,
   what's the failure mode you'd most regret?"
5. **Recommend** based on what you learned. Show the reasoning,
   including the tradeoffs you couldn't fully resolve.

### Output

In-chat decision report:
- **Options** (the 2+ choices, briefly)
- **Dimensions you implicitly cared about** (surfaced via grilling)
- **Tradeoffs** per dimension
- **Recommended choice** with rationale
- **Conditions to revisit** ("if X happens, switch to B")

Save to file only if user says "save this" — typically high-stakes
decisions (career, large purchase, research direction).

---

## Mode 3 — Skill-iteration

For **designing or refining a custom skill**. Heavier mode with
inventory + optional live-test.

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

Markdown file at:
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

---

## When NOT to use grill-me

- User already knows exactly what they want — grilling adds friction
- Task is mechanical (rename files, run a known command) — no design
  space
- User is under time pressure on routine work
- The user has explicitly said "just do it"

If you suspect grill-me would help but the user hasn't asked, you can
suggest it once: "Want me to grill you on this before I start?" If
they say no, just proceed.

---

## Reference files

| File | Read when... |
|---|---|
| `references/waves-general.md` | Mode 1 — question templates for plans/ideas/decisions |
| `references/waves-skill.md` | Mode 3 — question templates for skill design |
| `references/lens-library.md` | All modes — strategic/systems/psychological lenses for Wave 3 questions |
| `references/skill-locations.md` | Mode 3 — registry of Huili's skill repos + deploy methods |
| `references/output-formats.md` | All modes — output templates per mode |

---

## Honesty rules

- Don't generate questions to look thorough — if you have enough,
  stop and summarize.
- Don't propose an answer the user didn't give.
- Don't capitulate when the user pushes back; if you have a real
  reason, restate it. Only revise if they provide new information.
- For Mode 3 live-test: never claim "the skill works correctly" beyond
  what the fresh-context grader actually verified.

## Dependencies

- `AskUserQuestion` tool (for question popups)
- `Agent` tool (for fresh-context grader in Mode 3 live-test)
- Python 3 with stdlib (for the two scripts in `scripts/`)
- Skill repos discovered via `scripts/locate_skill.py` (no fixed
  dependency; works with whatever's on disk)
