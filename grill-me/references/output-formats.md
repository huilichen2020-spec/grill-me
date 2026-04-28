# Output Formats — per mode

Three output templates, one per mode.

---

## Mode 1 — General (in-chat summary)

After Wave 3 (or earlier if alignment reached). Put directly in chat,
no file. Compact, scannable.

```markdown
## Grill summary — {topic}

**What we agreed**
- {decision 1}
- {decision 2}
- {decision 3}

**Explicit assumptions**
- (verified) {assumption 1}
- (unverified) {assumption 2 — flag for tracking}

**Risks identified**
- {risk 1} → {mitigation, or "accepted"}
- {risk 2} → {...}

**Decision points** (revisit conditions)
- If {X happens}, revisit {decision N}

**Lenses applied:** {lens 1}, {lens 2}, {lens 3}
**Question count:** {N}

Ready to execute? Or adjust any of the above?
```

If the user says "save this," save to `{chat-root}/REPORTS/REPORT-GRILL_{date}_{topic-slug}.md`.

---

## Mode 2 — Decision-grill (in-chat decision report)

```markdown
## Decision grill — {options}

**Options weighed**
- {Option A} — {1-line description}
- {Option B} — {1-line description}
- (and any C, D...)

**Dimensions you actually cared about** (surfaced via grilling)
| Dimension | Weight | Notes |
|---|---|---|
| {dimension 1} | high/medium/low | {why} |
| {dimension 2} | ... | ... |

**Tradeoff matrix**
| Dimension | Option A | Option B |
|---|---|---|
| {dimension 1} | {strength/weakness} | {...} |
| {dimension 2} | {...} | {...} |

**Recommendation: {chosen option}**

Reasoning:
- {primary reason}
- {secondary reason}
- {explicit acknowledgement of A's weakness on dimension X}

**Conditions to revisit**
- If {X happens}, switch to {other option}
- If your conviction on {assumption} drops, re-grill

**Lenses applied:** {lens 1}, {lens 2}
**Question count:** {N}
```

Save to `{chat-root}/REPORTS/REPORT-DECISION_{date}_{topic}.md` only
if user says "save this" or the decision is clearly high-stakes
(career, large purchase, public commitment).

---

## Mode 3 — Skill-iteration (markdown file deliverable)

Always saved to file. Path:
- `{chat-root}/REPORTS/REPORT-SKILL-GRILL_{date}_{skill-name}.md` if
  in cowork with a chat root
- `~/Downloads/skill-grill-reports/{date}-{skill-name}.md` otherwise

```markdown
# Skill grill: {skill-name}

**Date:** {YYYY-MM-DD}
**Canonical repo:** {repo-path}
**Live-test ran:** yes/no
**Anthropic-managed (read-only):** yes/no

---

## User-stated intent (verbatim from grilling)

(Quote the user's answers from Wave 1-3 directly. Don't paraphrase.)

- "I want REVISE: to preserve my specific multi-word phrases verbatim"
- "Currently it paraphrases key phrases AND adds new claims"
- "When grammar conflicts with phrase preservation, preserve the phrase"
- ...

---

## Spec promises (current state)

(Direct quotes from SKILL.md / references with line numbers.)

- `references/comment-types.md` lines 14-18: "less latitude for Claude's
  own judgment"
- `references/comment-types.md` line 22: "Claude weaves it in faithfully"
- `references/comment-types.md` line 6-9: "preserve Huili's exact phrasing"
- `SKILL.md` line 79: "REVISE: — edit the anchored text in place per
  Huili's directive"

---

## Live-test observations (only if live-test ran)

**Sample input:** {short description, e.g., "draft.docx with REVISE: tighten this"}
**Output:** {short description}

Fresh-context grader's gap analysis:
- Spec promise: preserve phrases → Output observation: paraphrased "the
  tradeoff between X and Y" → "the X-Y tension"
- Spec promise: less latitude → Output observation: added 2 new claims
  (specific phrases the original didn't contain)
- ...

---

## Gaps identified

(Concrete gaps between user intent and current behavior.)

| # | Gap | Severity |
|---|---|---|
| 1 | Spec uses soft language ("less latitude") where intent is hard rule (preserve 3+ word phrases) | HIGH |
| 2 | No negative example showing what NOT to do | MEDIUM |
| 3 | No verification step — Claude can't self-detect when it broke the rule | MEDIUM |

---

## Recommended edits

(Specific line-level changes, ready to apply.)

### Edit 1 — `references/comment-types.md` lines 14-18

**Before:**
```
- **REVISE:** — Huili's comment IS the intellectual content; Claude weaves
  it in faithfully with less latitude for its own judgment. Claude's job
  is execution, not re-interpretation.
```

**After:**
```
- **REVISE:** — Huili's comment IS the intellectual content; Claude weaves
  it in faithfully. Hard rule: any 3+ word phrase from Huili's comment
  must be preserved verbatim in the output. Smooth surrounding prose to
  fit, but never modify the preserved phrase. Never add claims that
  weren't in Huili's comment OR the original passage.
```

### Edit 2 — `references/comment-types.md` after line 38 (add negative example)

(...etc.)

### Edit 3 — Add verification step to skill workflow

(...etc.)

---

## Apply method

- **Canonical repo:** {path}
- **Apply path:** edit canonical repo → re-package as `.skill` → run
  install.sh → re-install via Claude UI
- **Auto-apply available:** no (manual review required for v1)

---

## Decision log

- **Accepted edits:** {list, after user confirms}
- **Cherry-picked edits:** {if user accepted only some}
- **Rejected edits:** {with rationale if given}
- **Saved for later:** {if user said "not now"}

---

## Re-grill plan

After edits applied, recommend re-grilling on the same skill in {time
period} or after {N} real uses, to verify the v2 closed the gaps.
```

---

## File-naming convention (for saved reports)

- General: `REPORT-GRILL_{YYYY-MM-DD}_{topic-slug}.md`
- Decision: `REPORT-DECISION_{YYYY-MM-DD}_{decision-slug}.md`
- Skill-iteration: `REPORT-SKILL-GRILL_{YYYY-MM-DD}_{skill-name}.md`

Topic slug: lowercase, hyphens, ~30-50 chars.

In cowork with chat root: save to `{chat-root}/REPORTS/`. Otherwise: 
`~/Downloads/skill-grill-reports/{date}-{slug}.md`.

---

## Length guidance

- General mode: aim for ~10-20 lines of summary
- Decision mode: ~25-40 lines
- Skill-iteration mode: 50-200 lines depending on number of recommended edits

A grill report shouldn't try to be a manual — it's the precise crystallization of what the grilling surfaced.
