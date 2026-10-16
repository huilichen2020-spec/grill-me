# Question panel — Huili's format for every AskUserQuestion popup

Applies to every question panel, in every project and skill (her choice, 2026-10-16).
This file is the spec. Edit the settings below to change how panels look.

## Your settings (edit these)

| Setting | Value |
|---|---|
| Options per question | 2–4 |
| Questions per panel | grill-me: 1 (SKILL.md rule). Elsewhere: up to 4, only if independent |
| Label length | 1–5 words |
| Recommended option | first in the list, label ends with ` (Recommended)` |
| Description line | 1 sentence, at most 20 words, says what the option means or does |
| Pros line | starts with `Pros: `, one concrete gain, at most 12 words |
| Cons line | starts with `Cons: `, one concrete cost or risk, at most 12 words |
| Header chip | at most 12 characters |
| Register | ASD-STE100: short sentences, active voice, common words |

## Option description — exact shape

Three lines in the `description` field. Put a real newline between lines (the JSON escape `\n`
inside the string). Never type a backslash and the letter n as visible text. The app colors a
line that starts with `Pros:` green and a line that starts with `Cons:` orange (checked live
2026-10-16). Any other prefix renders plain.

```
<what this option means or does, one sentence>
Pros: <one concrete gain>
Cons: <one concrete cost or risk>
```

Example (one option):

```
label:       Upload a coded dataset (Recommended)
description: A CSV file of studies you already coded, one row per effect.
             Pros: Fastest path to a real meta-analysis; you control inclusion.
             Cons: Needs the extraction work done first.
```

## Rules

- Every option gets both a `Pros:` line and a `Cons:` line. No option is all upside.
- Pros and Cons each name a fact: a time, a count, a file, a risk, or a lost feature. Banned empty words: flexible, better, easier, robust, cleaner.
- One option clearly best: put it first and add ` (Recommended)`. Several equal: mark none, say so in the question text, and still give each option Pros/Cons.
- multiSelect questions: same three-line shape; mark no option Recommended.
- Put Pros/Cons in `description` only. Do not use the `preview` field unless Huili asks; the app does not color it.
- Exception: options that are names or values (file, date, person) with no trade-off may drop Pros/Cons. If unsure, keep them.
- Do not add "Other", "Let the agent decide" or "Skip". The app adds them.
- Pre-send scan: does every option have `Pros:` and `Cons:` at the start of their own lines?
