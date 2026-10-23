# Plan: reviewing every content draft (2026-10-23), waiting for approval

Nothing here is started. Review means reading and flagging; nothing is changed until you have seen the findings.

## Executive summary

| Question | Answer |
|---|---|
| What is in scope | Every sentence written by Claude: about 11,000 content rows across 18 kinds (table below) |
| How | Four passes: **(1)** automated checks for the mechanical problems, **(2)** a reading review of each content kind against a written rubric, **(3)** a cross-content coherence pass, **(4)** a "does it work on screen" pass in the real game |
| What you get | One findings report per content kind (a table: ID, problem, severity, suggested fix), then a single fix batch applied only for the items you approve |
| Never done without you | Canon (names, parties, positions), political stance, and anything where a rewrite changes what the content means |
| Cost | Pass 1 is cheap. Pass 2 is the big one: about 10 review batches. Pass 3 and 4 are small |

## What is in scope

| Kind | Rows | Where it is used | Main risk |
|---|---|---|---|
| Opponent cues | 3,108 | Spoken lines in battle, by style | Repeats, wrong tone for the stage, a line that contradicts the opponent's party |
| Player cues | 3,516 | The player's own lines by style and room | Same, plus the player sounding out of character for their party |
| Transition dialogue | 2,083 | Paired line and reply between two stages | Reply does not answer the line |
| Visitor questions and answers (visitors 166, questions 393) | 393 | Office Hours and local activities: four choices, responses, reactions | Responses that do not match the choice they follow; the "best" answer not obviously best; stock lines |
| Level intros | 246 | Staff speak before a level | Staff voice (role) wrong; mentions things the level does not contain |
| Room questions | 6 groups | Press, town hall and similar rooms | Graded answers (strong, medium, weak) that do not match the grade |
| Events and choices | 38 and 109 | Event screens, hosted events, the dated events | Result text that contradicts the stated reward, hours and cost |
| Hosted events (options 53, tastes 32, reaction lines 15) | 100 | Walking tour and dinner | Tag logic that gives a silly reaction (for example a vegetarian group praising a steak) |
| Bills, law effects, components | 50, 103, 180 | Floor votes, patron bills, drafting | Names and phrases that read badly when joined into "A bill to ..." |
| Office ticker and notices | 149, 20 | The scrolling strip and Office text | Stale lines; a line shown when its condition makes it false |
| Text tab (UI sentences) | 772 | Every button and message | Placeholders, tone, terminology (money, Jiban, awareness wording) |
| How to Play | 34 | Guide | Out of date with the changes made this week |

## The rubric (the same five questions for everything)

| Check | Question |
|---|---|
| **Phrasing** | Does it read as a person speaking, in the voice of its role? Free of repeats, filler and clichés |
| **Internal logic** | Does the response answer the line before it? Does the result text agree with the numbers (rewards, costs, hours, who is pleased)? Is the best choice actually the best? |
| **Grammar** | Spelling (American, per the terminology pass), punctuation, tense, placeholders that fill cleanly (no "the the", no "<null>") |
| **Thematic coherence** | Fits Yezo, the party's position, the stage type and the other lines in its group. No canon invented; no real-world politician or party implied |
| **Fitness for use** | Fits the space (length on a phone at the large text size), the moment (spoken on the cue banner or shown in a panel) and the rule it feeds (content budget, grading, tags) |

Severity: **A** wrong or misleading (contradicts the numbers, breaks canon, unreadable); **B** reads badly or repeats; **C** polish.

## The passes

| Pass | What | Output |
|---|---|---|
| **1. Automated checks** | A new script (`tools/content_lint.py`) over the exported data: spelling against a word list built from the Text tab; double spaces, doubled words, stray punctuation, unfilled placeholders; length limits for the cue banner and buttons; duplicate or near-duplicate lines inside a group; a response identical to its question; reactions reused more than a set number of times; every effect in a result text matched to its number columns; empty cells in groups that should be full | A list of mechanical defects with row IDs, fixed in bulk. Also becomes a permanent test so drafts cannot regress |
| **2. Reading review** | Reviewers (subagents) each take a slice, read every row against the rubric, and write findings into a table. Slices below | One findings table per slice |
| **3. Cross-content coherence** | The same character, organization or party read across every place it speaks (cues, intros, transitions, questions, bills). Terminology and tone compared across kinds | A short report: contradictions and drift, by character |
| **4. In-game check** | Play-through screenshots of each content kind at the large text size, plus the click tests, to see overflow, clipped text and wrong conditions | A screenshot set and a defect list |
| **5. Fix and verify** | Apply approved fixes in batches, rerun the exporter and the full check, merge | One changelog entry per batch |

## Slices for pass 2

| # | Slice | Rows | Reviewers |
|---|---|---|---|
| 1 | Text tab and How to Play | 806 | 1 |
| 2 | Opponent cues, first half by party | about 1,550 | 2 |
| 3 | Opponent cues, second half | about 1,550 | 2 |
| 4 | Player cues | 3,516 | 3 |
| 5 | Transition dialogue | 2,083 | 2 |
| 6 | Visitors and questions (original, festival, district) | 559 | 3 |
| 7 | Level intros, ticker, notices | 415 | 1 |
| 8 | Events, hosted events, tastes, reaction lines | about 250 | 1 |
| 9 | Bills, law effects, components, patron bills | about 390 | 2 |
| 10 | Room questions and Player Thoughts | small | 1 |

Because the cue banks are large and repetitive, pass 1 does most of the work there. Pass 2 reads a **full** pass of the smaller, more consequential kinds (visitors, events, bills, intros) and a **sample of 25 percent** of the very large cue banks plus every row pass 1 flagged. If the sample finds problems at more than 5 percent, I widen it to a full read.

## What I need from you

| # | Decision | My default |
|---|---|---|
| 1 | Scope: everything above, or a priority order? | Order: visitors and events (players read every word), then bills and intros, then the cue banks |
| 2 | Sampling for the three biggest banks (25 percent, then widen if needed), or read all 8,700 rows? | Sample |
| 3 | Do fixes that only affect grammar and spelling go in without your review? | Yes, shown in the report, not individually asked |
| 4 | Anything that changes meaning (a different choice, a different reward, a character's stance) | Always listed for you, never applied |
| 5 | Spelling standard and terminology list | American spelling, and the 2026-10-16 terminology pass as the glossary |
| 6 | Run it as a workflow with reviewers in parallel, or in my own session one slice at a time? | Parallel reviewers, since this is a large read. This is your call because it uses many agents |
