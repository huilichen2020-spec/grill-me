# Waves — Skill-iteration mode

Question templates for **Mode 3: Skill-iteration**. The goal here is
specific: surface the gap between what the skill SAYS it does and
what the user actually wants it to do.

Run `scripts/skill_inventory.py` first — every question below should
reference specific lines/files in the inventory output.

---

## Wave 1 — Basics (3-5 questions)

What problem is the skill solving, and is it actually solving it?

### Problem definition
- "What's the original pain that made you build this skill?"
  ○ {past frustration with a recurring task}
  ○ {wanted to standardize an ad-hoc workflow}
  ○ {teaching Claude something it kept getting wrong}
  ○ Other

- "When this skill works perfectly, what does the output look like?"
  ○ {paste a "this is what success looks like" example}
  ○ a polished version of {input}
  ○ a structured report covering {topics}
  ○ Other

### User identification
- "Who's the actual user reading the SKILL.md — the human invoking,
  or Claude executing?"
  ○ Mostly Claude — the SKILL.md is operator instructions
  ○ Mostly the human — the SKILL.md is documentation
  ○ Both equally
  ○ I'm not sure

This matters because a SKILL.md written for Claude (imperative,
high-information-density) reads differently from one written for a
human (explanatory, with rationale).

### Success criterion
- "How do you know when the skill is doing its job correctly vs
  poorly? What's the test?"
  ○ Subjective: "feels right"
  ○ Specific output features (e.g., "tracked changes used", "yellow
    highlights present")
  ○ User-acceptance: "I would have written it this way myself"
  ○ Other

---

## Wave 2 — Ambiguity (2-4 questions)

Probe the boundaries surfaced from inventory. Each question should
reference a specific line/section of the SKILL.md.

### Command boundaries
- "Looking at the {prefix/mode} table — when should command X NOT
  fire? Are the trigger phrases too broad / too narrow?"
- "If a comment / request is ambiguous between command X and
  command Y, which wins? Is that documented?"

### Trigger edge cases
- "Are there phrasings you'd want this skill to fire on that aren't
  in the description?"
- "Are there phrasings in the description that misfire?"

### Hard rules vs strong preferences
- "Line N says {rule with MUST/NEVER/ALWAYS}. Is this actually a
  hard rule, or a strong preference Claude should follow?"
- "Line N has {soft phrasing like 'should' or 'try to'}. Should
  that be hardened to MUST?"

### Cross-skill dependencies
- "This skill calls into {other skill}. Is that dependency right?
  Should it be looser/tighter?"
- "If {other skill} changes, does this skill need to update? How?"

---

## Wave 3 — Blind spots (1-3 questions)

The most valuable wave. Apply lenses from `lens-library.md`:

### Negative space
- "You didn't mention {edge case / scenario} in the spec. Deliberate
  or oversight?"
- "Most failure modes I've seen for skills like this involve {known
  pitfall}. Is that in scope here?"

### Confidence level
- "Of the rules in this skill, which are based on actual past
  experience vs which are 'this seems right'?"
- "What rule have you written that you're not sure about?"

### Past feedback that didn't change the spec
- "Have you given Claude feedback like 'don't do X' or 'always do Y'
  on this skill's output? Is that feedback actually IN the spec?"
- This is the goldmine question. Most skill drift comes from feedback
  that lived in chat but never made it into SKILL.md.

### Feedback loops
- "When this skill produces something you didn't want, how do you
  course-correct? Is that path documented or is it tribal?"

### Failure mode
- "What's the first thing that goes wrong when this skill runs on a
  task it shouldn't fire on at all?"
- "What edge case in the input would expose the worst output?"

---

## Live-test mode (optional, after Wave 3)

If user opts in, after spec-grilling:

1. **Get sample input** from user.
2. **Run the skill** on that input as designed.
3. **Spawn fresh-context subagent** via the Agent tool. Prompt:
   ```
   Below are: (a) the SKILL.md spec, (b) the input, (c) the output.
   Independently assess: does the output match the spec's promises?
   Where's the gap?
   
   Return: list of gaps with line references to the spec.
   ```
4. **Read subagent's gap list** + cross-reference with user's Wave
   1-3 answers.
5. **Synthesize**: which gaps are real vs subagent misreading the
   spec? Which gaps need spec edits vs implementation fixes?

Why fresh-context: the original Claude generation has blind spots it
can't self-detect. A clean-context grader catches them.

---

## Domain-specific question additions

### Comment-processing skills (e.g., ra-draft-editor)
- "When the prefix and content disagree, what wins?"
- "How aggressively should Claude execute the directive vs preserve
  user phrasing?"
- "What 3+ word phrases from the user's comment must be preserved
  verbatim?"

### Search/lookup skills (e.g., ra-idea-incubator)
- "When the user's terms don't match academic vocabulary, how much
  translation is appropriate?"
- "What ranking signal matters most — recency, citation count,
  topical fit, recommendation by author network?"

### Generation skills (e.g., ra-paper-finalize, outreach-email)
- "How much should the output preserve the input's voice vs apply
  conventions?"
- "When in doubt about voice, default to conservative or
  expressive?"

### Workflow / orchestrator skills (e.g., ra-workspace, comms-hub)
- "When two member skills could handle a request, who decides?"
- "Should the workspace skill ever execute itself, or only delegate?"

---

## Stop conditions

Stop grilling when:
- You have specific line-reference recommendations to make
- The user has answered 8-12 questions and signal is converging
- Live-test grader's gap list aligns with user's stated dissatisfaction

The output is **a list of specific edits**, not "the skill is
generally fine." If you can't propose specific edits, you haven't
grilled deep enough.

---

## Output guidance for the grill report

See `output-formats.md` Skill-iteration template. Critical fields:

- **User-stated intent** — verbatim from grilling answers, not your
  paraphrase
- **Spec promises** — line references to SKILL.md / references
- **Live-test observations** — only if live-test ran
- **Specific edit recommendations** — line numbers + before/after
- **Apply method** — install.sh + UI re-register, or manual edit
  only (depends on skill location per `skill-locations.md`)
