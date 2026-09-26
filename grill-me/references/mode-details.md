# Mode details — when to invoke + output checklists (Modes 1-2)

Templates for each output live in `output-formats.md`; this file holds the
per-mode invocation cues and what each output must cover.

## Mode 1 — General (default)

### When to invoke

- Claude proposed a plan; user wants to stress-test it before saying go
- User has a rough idea and wants to articulate it precisely
- User is about to start a complex task and wants alignment first
- High-stakes decisions where misalignment is costly (trade ideas,
  research direction, design choices)

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

## Mode 2 — Decision-grill

### When to invoke

- "Should I use X or Y for [purpose]?"
- "What's better — A or B?"
- "Compare these two approaches"

### Output

In-chat decision report:
- **Options** (the 2+ choices, briefly)
- **Dimensions you implicitly cared about** (surfaced via grilling)
- **Tradeoffs** per dimension
- **Recommended choice** with rationale
- **Conditions to revisit** ("if X happens, switch to B")

Save to file only if user says "save this" — typically high-stakes
decisions (career, large purchase, research direction).
