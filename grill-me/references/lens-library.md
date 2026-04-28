# Lens Library — for Wave 3 (blind-spot) questions

Pick **2-3 lenses per session** based on the domain. Each lens is a
way of seeing what would otherwise stay invisible. Use them to
generate Wave 3 questions.

Each lens entry:
- **What it surfaces** — the kind of insight it tends to produce
- **How it becomes a question** — concrete phrasing template
- **Best for** — domain types where it's most useful

---

## Strategic lenses

### Negative space
**Surfaces:** what the user didn't say, glossed over, or answered briefly
**Question form:** "You didn't mention {topic} — is that deliberate or didn't think of it?"
**Best for:** plan grilling, decision grilling, skill spec review

### Stakeholders
**Surfaces:** people affected by the decision who weren't considered
**Question form:** "Who else is affected by this? Are they aware? Do their interests align?"
**Best for:** team decisions, organization-affecting plans, public-facing changes

### Rejected alternatives
**Surfaces:** options the user dropped — consciously vs by inertia
**Question form:** "Did you consider {alternative}? Why did you drop it?"
**Best for:** decision grilling especially; surfaces underweighted options

### Opportunity cost
**Surfaces:** what's NOT happening because resources go here
**Question form:** "What are you NOT doing while doing this?"
**Best for:** time-bounded plans, large projects, mid-career decisions

### Confidence level
**Surfaces:** what's verified vs assumed vs hoped
**Question form:** "Is this a verified fact or a feeling?"
**Best for:** trade ideas, research claims, skill design choices

### Reversibility
**Surfaces:** whether the decision is one-way or two-way door
**Question form:** "If this is wrong, how hard is it to undo?"
**Best for:** product launches, public commitments, irreversible code changes

---

## Systems lenses

### Dependencies
**Surfaces:** single points of failure, cascade risks
**Question form:** "If {component} fails, what else breaks?"
**Best for:** technical plans, complex projects, infrastructure changes

### Cascading effects
**Surfaces:** second-order consequences
**Question form:** "This causes B. What does B then cause?"
**Best for:** policy changes, market trades, system design

### Time horizon conflict
**Surfaces:** good now vs bad later (or vice versa)
**Question form:** "Will this decision still be right in 3 months? 1 year?"
**Best for:** trades, hiring, technical debt decisions

### Feedback loops
**Surfaces:** reinforcing or balancing cycles without bounds
**Question form:** "I see a loop here: {description}. What constrains it?"
**Best for:** systems with adoption dynamics, citation incentives, skill iteration

### Failure mode
**Surfaces:** what specifically goes wrong when this fails
**Question form:** "When this fails, what's the first thing that goes wrong?"
**Best for:** robustness-focused designs, trades with stop-losses

---

## Psychological lenses

### Whose desire?
**Surfaces:** internal motivation vs external pressure ("should")
**Question form:** "If no one would know the result, would you still do this?"
**Best for:** career decisions, project choice, personal commitments

### Avoidance
**Surfaces:** what the user is sidestepping
**Question form:** "I noticed you answered {topic} briefly. What's uncomfortable about it?"
**Best for:** any session where one question got a thin response

### Secondary gain
**Surfaces:** benefits of NOT solving the problem
**Question form:** "What do you LOSE by solving this problem?"
**Best for:** persistent issues that don't get fixed despite obvious cost

### Sunk cost
**Surfaces:** rationalization based on past investment
**Question form:** "If you were starting today with no prior commitment, would you choose this?"
**Best for:** decisions to continue an existing project, partnership, or approach

### Identity stake
**Surfaces:** when a decision is wrapped up in self-image
**Question form:** "What would you have to admit about yourself if you chose differently?"
**Best for:** career pivots, methodological shifts, personal-brand decisions

---

## Domain → recommended lens picks

| Domain | Suggested lenses (pick 2-3) |
|---|---|
| Technical plan / architecture | Dependencies, Cascading effects, Failure mode, Reversibility |
| Trade / financial decision | Confidence level, Time horizon conflict, Failure mode, Reversibility |
| Research direction / paper plan | Confidence level, Rejected alternatives, Opportunity cost, Time horizon conflict |
| Career / personal decision | Whose desire?, Sunk cost, Identity stake, Opportunity cost |
| Skill design / iteration | Negative space, Confidence level, Feedback loops, Failure mode |
| Decision (A vs B) | Rejected alternatives, Confidence level, Reversibility, Opportunity cost |
| Team / org change | Stakeholders, Cascading effects, Time horizon conflict |
| Sticky problem (won't go away) | Avoidance, Secondary gain, Whose desire? |

If unsure: default to **Negative space + Confidence level + one domain-specific lens**. These three cover the most common blind spots.

---

## Tension-following overrides lens choice

If an answer reveals a tension, drop your planned lens questions and
follow that thread. The structure is a tool, not a constraint. Real
insight comes from following surprise.

Example: you're applying the **Dependencies** lens to a deployment
plan. User mentions in passing "well, we won't really know until prod
hits real traffic." That throw-away phrase is more important than the
next dependency question. Switch to: "What specifically about your
test environment differs from prod?" Stay on the thread until it's
exhausted, then resume the lens script.
