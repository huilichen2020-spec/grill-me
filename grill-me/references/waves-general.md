# Waves — General mode (plans, ideas, decisions, proposals)

Question templates for **Mode 1: General**. Adapt these to the
specific topic; don't ask them verbatim if they don't fit. Each wave
is a starting library, not a script.

---

## Wave 1 — Basics (3-5 questions)

Build a working understanding of what the user actually wants.

### Goal-orientation
- "What's the actual outcome you want — finished product, sharper
  thinking, better decision, or something else?"
- "What's the single failure mode you'd most regret?"
- "If this works perfectly, what does success look like in concrete
  terms?"

### Context
- "What's the context this exists in — a larger project, a one-off,
  ongoing maintenance?"
- "Who else is involved or affected?"
- "What's the time horizon — days, weeks, months?"

### Constraints
- "What can't change about the situation? (e.g., budget, deadline,
  fixed dependencies)"
- "What constraints are real vs assumed-but-flexible?"

---

## Wave 2 — Clarifications (2-4 questions)

Probe ambiguity surfaced in Wave 1. Ambiguity often hides in:

### Edge cases
- "When {scenario} happens, what's the right behavior?"
- "What's the boundary case where {approach A} stops working?"

### Conflicts
- "I notice {thing X} and {thing Y} seem to push in opposite
  directions — how do you resolve that?"
- "Earlier you said {A}; now you're suggesting {B}. Which wins when
  they conflict?"

### Dependencies
- "What needs to be in place before this can start?"
- "What does this depend on that you don't fully control?"

### Scope
- "Is {related thing} in scope or out of scope?"
- "When you say {X}, does that include {edge case Y}?"

---

## Wave 3 — Blind spots (1-3 questions)

Apply 2-3 lenses from `lens-library.md`. Goal: surface what the user
DIDN'T say. Examples per lens:

### Negative space
- "You haven't mentioned {topic that should be relevant} — deliberate or
  oversight?"
- "I notice you skipped over {X} when I asked about it earlier. Is
  there something there?"

### Confidence level
- "How sure are you about {assumption}? — Verified, strong intuition,
  or hope?"
- "What evidence would change your mind on {key claim}?"

### Failure mode
- "What's the first thing that goes wrong if this fails?"
- "If you had to predict the most likely way this fails, what would
  it be?"

### Time horizon
- "Is this a decision you'd want to revisit in 3 months? 6 months?"
- "Does this decision look the same a year from now?"

### Rejected alternatives
- "What approach did you consider and reject? Why?"
- "Is there a simpler version of this you ruled out?"

---

## Domain-specific question additions

Layer these onto the wave structure when domain matches.

### Technical plans / architecture
- "What's the rollback path if this breaks production?"
- "What dependency could go wrong that you haven't thought about?"
- "What do you assume about the {data / scale / users} that hasn't
  been verified?"

### Trade / financial decisions
- "What's your stop loss / exit plan if the thesis is wrong?"
- "What size is right given your conviction level?"
- "What's the falsification signal — what would tell you to exit
  early?"
- "Are you long {asset} because you believe it, or because you're
  hedging something else?"

### Research direction / paper plans
- "What's the strongest counter-argument? Have you addressed it?"
- "What venue are you targeting — does the framing fit?"
- "Is this a directional claim or a more nuanced 'restructures'
  claim? Which sells better at this venue?"
- "What's already in the literature that could make this redundant?"

### Career / personal decisions
- "If you knew no one would judge the outcome, which would you
  choose?"
- "What would you have to give up to choose this?"
- "If you said no to this, what would you say yes to instead?"

### Sticky problems (recurring issues)
- "What have you tried before that didn't work?"
- "What does the persistent failure suggest about the problem
  framing?"
- "What benefit do you get from the problem staying unsolved?"

---

## Stop conditions — when to summarize

Stop asking questions when ANY of these is true:

1. You can write a clear summary without uncertainty
2. The user has answered 12+ questions and signal is converging
3. The user says "OK I think we have it"
4. New questions are getting "depends," "I don't know," or duplicate
   answers — diminishing returns

The point is alignment, not exhaustion. Stop when alignment is reached.

---

## Between-wave summary template

Between Wave 1 and Wave 2, and between Wave 2 and Wave 3:

```
**What I understood so far** (3-5 bullets — concrete facts only)
- ...

**Assumptions** (flag verified vs unverified)
- (verified) ...
- (unverified) ...

**Risks I'm now tracking** (each becomes a question for the next wave)
- ... → I'll ask about ...
- ...

Continuing with Wave {N}.
```

Keep it brief — 5-8 lines total. The user reads it as a sanity check
that you're listening.

---

## Final summary template

After Wave 3 (or earlier if you've reached alignment):

```
**What we agreed**
- {decision 1}
- {decision 2}
- {decision 3}
- ...

**Explicit assumptions**
- {assumption 1} — {verified | unverified | accepted-as-given}
- ...

**Risks identified**
- {risk 1} — {your mitigation, or "accepted"}
- ...

**Decision points** (conditions to revisit)
- If {X happens}, revisit {decision N}
- ...

Ready to execute? Or do you want to adjust any of the above?
```

---

## Common anti-patterns to avoid

- **Fishing questions** — asking just to seem thorough. If you have
  what you need, stop.
- **Closed leading questions** — "You DO want X, right?" — pre-loading
  the answer.
- **Multiple questions in one** — "What's the goal AND who's
  affected AND when's the deadline?" — pick one.
- **Abstract language** — "What are your priorities?" → use concrete:
  "If you could only ship one of (A, B, C), which?"
- **Continuing after the user signals stop** — if they say "OK that's
  enough," stop.
