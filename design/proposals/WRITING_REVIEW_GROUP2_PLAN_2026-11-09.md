# Writing review, group 2: outlines for approval (2026-11-09)

Draft by Claude for Cameron. These are the items from the writing review decisions (`design/review/WRITING_REVIEW_DECISIONS_2026-11-09.md`) that need code, structural moves or new writing. Nothing here is built yet. "Go" on an item approves it.

## Summary

| # | Item | Kind | Size | Needs from Cameron |
|---|---|---|---|---|
| A | Follow-up events fire only after a kept promise (#20) | Code | about 40 lines and a test | Go |
| B | BI26 rebalance; BI35 proponent; dependent lines (#12, #15) | Data and writing | about 30 cells and 20-40 lines | Approve the numbers below |
| C | Room-pool questions that name a policy area move to the generic rooms (#31) | Data move | about 200 rows | Go |
| D | S573-S582 move out of the Party Caucus (#32) | Data move | 10 rows | Pick the room (no candidate-selection room exists) |
| E | T32 and T33 to the generic Town Hall only (#33) | Data move | 2 rows | Go |
| F | Journalist lines become attack lines (#55) | Data and writing | about 240 lines | Go |
| G | More templates so three-part bills don't repeat (#56) | Writing, then regenerate | 12-18 new frames per style | Go |
| H | Topic-room player lines: stance tags, then mixed into bill levels (#58) | Data and code | 360 tags, about 40 lines of code and a test, and one Balance row | Go, and the share of turns |
| I | Per-bill visitor replies, VQ135-VQ156 (#37) | Writing | about 44 replies | Go |
| J | A short decline line for each event (#49) | Data schema and writing | one new column, about 56 lines | Approve the new column |
| K | Drafts for you to edit: renamed backings, bill facts, ambush hints, critic variants, the Backers segment, the EV16 B dues column (#14, #17, #24, #30, #42, #48) | Writing and data | small | Review the drafts |

## A. Follow-ups only after a kept promise

Today a follow-up event is queued (`GameState.scheduled_events`) as soon as the choice is made, and `take_due_followup()` releases it when its time comes, kept promise or not. The change:

- When a choice queues a follow-up, also record which choice it came from.
- When a promise from that same choice is broken, drop the queued follow-up.
- A follow-up whose choice made no promise ("follow up later") still fires.
- A test in `tests/` covers kept, broken and no-promise cases.

## B. BI26 and BI35

**BI26 Civil Service Merit Act.** Butsutou stays the proponent and becomes Supportive. Each party keeps its seat count, and the bill keeps its overall totals (26 Aye, 73 Nay, 2 Abstain), so the vote result is unchanged:

| Party | Now (Aye / Nay / Abstain) | Proposed | Disposition |
|---|---|---|---|
| Butsutou | 7 / 12 / 0 | 16 / 2 / 1 | Supportive (was Opposed) |
| Yezo Heritage Party | 3 / 9 / 2 | 1 / 12 / 1 | Opposed |
| Frontier Party | 10 / 17 / 0 | 5 / 22 / 0 | Opposed |
| Five Point Independents | 0 / 5 / 0 | 0 / 5 / 0 | Opposed |
| Keizaijiyuutou | 2 / 23 / 0 | 1 / 24 / 0 | Opposed |
| Country Initiative | 4 / 7 / 0 | 3 / 8 / 0 | Opposed |
| **Total** | **26 / 73 / 2** | **26 / 73 / 2** | |

**BI35 Political Donation Transparency Act.** The proponent becomes the Yezo Heritage Party, which stays Neutral. No vote changes.

**Dependent content** (checked and rewritten where needed): Butsutou's party cue for BI26; opponent bill lines for Butsutou members on BI26 (their side flips to For); the party-leader lines before the Floor Vote; the bill card's "proposed by" text; the Vote Tally & Swing tab, re-checked against the new numbers.

## C, D, E. Moving room questions

- **C.** About 200 questions in the five generic room pools name a policy area. Each moves to the Stage Questions of the matching generic room (Press Conference ST04, Town Hall ST05, Lobbyist Meeting ST20, Policy Study ST21; the Media Ambush room is also generic). They then never come up in a bill's room. No wording changes.
- **D.** No candidate-selection room exists. Options: (1) only the generic Party Caucus (ST03), worded as a caucus talking about candidate selection; (2) the Party Steering Committee (ST08); (3) a new Candidate Selection room (a new stage, larger). Recommended: (1).
- **E.** T32 and T33 move to the generic Town Hall's (ST05) Stage Questions.

## F. Journalist lines

Reporters only attack, so about 240 of their gain and block lines never play. Lines that already read as a challenge get their move changed to attack. The rest are reworded as challenges in the reporter's voice. Duplicates of existing attack lines are left out.

## G. Templates for three-part bills

A three-part bill draws three component rows built from the same six frames per style, so the player can say "Think of the people who need us to ..." three times in one level. The fix is to write two more frame sets per style (12 more frames per style) and regenerate the component rows so the parts of one bill use different sets. Data only; the generator script is brought up to date first, so the hand edits of 2026-10-25 are kept.

## H. Topic-room player lines

The 360 lines PL169-PL528 fit their bill's topic but carry no stance, and some take a side. Each line gets a Stance tag (For, Against, or blank for either). The code then lets a share of the player's turns in a bill level draw a matching room line instead of a bill line. The share is a Balance row; 25% is suggested.

## I. Per-bill visitor replies

Eleven bill visitors (VQ135-VQ156) share word-for-word choices and replies. Each gets replies written for its own bill (about 44), keeping the same costs and effects.

## J. A decline line for each event

Today every random event offers the same one-word "Decline". A per-event line, such as "Let it pass this time.", needs a new column on the Events tab (a schema change). With your approval: add the column, fall back to "Decline" when it is blank, and write about 56 lines.

## K. Drafts for you to edit

- New names for one of each duplicate backing: M25 (Agricultural Cooperatives) and M24 (Labor Federation).
- Bill facts: BI09 "Who Pays", the BI08 middle ground, and the BI01 co-official status wording.
- Several varied, vague Media Ambush hints for purpose lines ("Reporters are sniffing around the halls.").
- Critic-clause variants.
- The audience segment "Boosters" renamed to "Backers" (the segment's ID stays the same).
- EV16 B "small advance": add a Dues change to its column so the advance reduces the dues owed.
