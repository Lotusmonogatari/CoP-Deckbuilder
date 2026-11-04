# Plan: enough opponent bill lines to go 30 turns without a repeat (2026-11-04)

**Goal (Cameron):** in a bill level, no opponent line repeats within 30 opponent turns. The lines must also cover every opponent position (For, Against, Neutral) and every speaking style (Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous).

This is a plan only. Nothing is built until Cameron approves it.

## Executive summary

| Item | Finding / proposal |
|---|---|
| Why lines repeat today | Two reasons: (1) each pool is small once filtered by side; (2) the line is chosen from a hash of opponent, move, stage and turn, so two turns can pick the same line even when unused ones exist. |
| Fix 1 (code, small) | **No-repeat picker:** remember the lines already said in this level and pick an unused one first. When a pool runs dry, reuse the line said longest ago. About 40 lines of code plus a test. Without this, no amount of writing guarantees no repeats. |
| Fix 2 (content) | **189 new sentence frames**, filled with each bill's own phrases where a pool is short. That gives **about 2,000 new lines** across the 50 bills, all drafts. |
| Target | Enough lines that in **95% of simulated 30-turn stretches** of every bill level, no pool runs dry. The 100% worst case would roughly double the work, for a stretch almost no run reaches. |
| Coverage | Targets are set per bill × style × move × side, from the real seating, style weights (55/30/10/5) and move patterns. Both spreads are covered by construction. |
| Check | A new tool reruns the simulation and lists any short pool. A test makes the 95% target part of the build check. |

## How the numbers were found

- **Simulation:** 300 random 30-turn stretches of each of the 50 bill levels, using the real game data:
  - the stages in order, with each one's opponent count and turn limit;
  - who can be seated (the Opponents tab's Stage lists);
  - each opponent's three styles at 55/30/10% plus a 5% outside style;
  - each opponent's move pattern (journalists attack only);
  - each opponent's side from `MemberStance.gd`, including the rolled sides of split parties.
- **Pools:** every draw is counted against its pool, a (bill, style, move) whose neutral lines are shared by every side.
- **Target:** a pool is short if, in the 95th-percentile stretch, its speakers need more distinct lines than it has. For a For-side speaker that means neutral plus For lines; for an Against speaker, neutral plus Against; for a neutral-only speaker, neutral alone.
- **Busiest pool:** Earnest attack, up to 18 draws in one 30-turn stretch at the 95th percentile.

**Result:** 570 of 900 pools are short.

| Style | New Neutral | New For | New Against | Total |
|---|---|---|---|---|
| Earnest | 123 | 273 | 185 | 581 |
| Emotional | 207 | 273 | 70 | 550 |
| Appeal | 158 | 177 | 28 | 363 |
| Data Driven | 119 | 155 | 13 | 287 |
| Divisive | 24 | 41 | 32 | 97 |
| Duplicitous | 54 | 85 | 2 | 141 |
| **All** | **685** | **1,004** | **330** | **2,019** |

**Per bill:** 8 to 66 new lines (median 41). The most are needed for BI46 Workplace Equality, BI17 Partnership Registration, BI37 Carbon Levy, BI14 Constituency Grants and BI30 Local Suffrage. For lines are the biggest gap, because nearly every existing line was written to attack the player's bill.

## New frames needed (style × move × side)

| Style | Attack N/F/A | Gain N/F/A | Block N/F/A |
|---|---|---|---|
| Earnest | 4 / 9 / 6 | 5 / 6 / 6 | 4 / 6 / 5 |
| Emotional | 8 / 7 / 5 | 5 / 3 / 3 | 4 / 4 / 2 |
| Appeal | 3 / 5 / 3 | 3 / 3 / 2 | 4 / 4 / 0 |
| Data Driven | 6 / 5 / 3 | 3 / 3 / 3 | 3 / 4 / 1 |
| Divisive | 3 / 3 / 3 | 1 / 2 / 3 | 2 / 1 / 3 |
| Duplicitous | 7 / 6 / 2 | 0 / 2 / 0 | 0 / 1 / 0 |

That's 189 frames in all. Each frame is filled only into the pools that need it, which gives the ~2,000 lines. Filling every frame into every bill would give 9,450 lines: more margin, but a much larger review.

## Writing rules for the new frames

- **Side:**
  - A **For** line defends the bill or its winners ("{gain} have waited long enough").
  - An **Against** line speaks for {hurt}, the risk, the critics or the middle ground.
  - A **Neutral** line challenges without taking a side: a demand for figures, a question, a procedural push.
- **Opponent voice:** an opponent who agrees with the player still pushes them, as a demanding ally ("If you back it, defend it properly"). Never "I agree with you."
- **Style voice:** as in `design/CONTENT_GUIDE.md`, from "Earnest plain…" through "Duplicitous hedges…".
- **Slot rules** (now in the bill facets README):
  - {gain} and {hurt} are plural groups of people;
  - {cost} only after "falls on" or "who pays";
  - {local} is a noun phrase;
  - {alt} never takes "instead";
  - no verb directly after {risk}.
- **Length:** 20 words or fewer, the existing test limit.
- **No game terms:** never "level" or "stage" (`test_spoken_no_game_terms.gd`).
- **Honesty:** each side argues its strongest honest case, with no strawmen.
- **Workbook:** new Opponent Cues rows (new OC IDs), one row per (bill, style, move) with up to five lines and their Side cells.

## Phases (each its own commit and full test run)

| # | Work | Output |
|---|---|---|
| 1 | No-repeat picker in `OpponentCues.gd`, plus a GUT test (30 draws from a 30-line pool never repeat; a dry pool reuses the oldest line) | Code |
| 2 | `tools/cue_coverage.py`: the simulation above, as a reusable tool that prints short pools | Tool |
| 3 | Draft the 189 frames (style × move × side) and run them past the slot and grammar checks used in the bill review | Frames file for Cameron |
| 4 | Fill the frames into the short pools. Add the workbook rows and Side cells. Export. | ~2,000 lines |
| 5 | Rerun the coverage tool (target: zero short pools at 95%), add a GUT test of the per-pool minimums, review a sample of lines per bill, take a screenshot of one battle, run the full test run | Report |
| 6 (optional) | Bill-part pools (drafted and sponsored bills), using the same method | Estimate first |

## Decisions for Cameron

| # | Question | Recommendation |
|---|---|---|
| 1 | Target: 95% of 30-turn stretches, or the worst case seen? | 95% |
| 2 | Fill new frames only where a pool is short (~2,000 lines), or into every bill (~9,450)? | Only where short |
| 3 | Include drafted and sponsored bills (phase 6)? | Later, after phases 1-5 |
| 4 | May an opponent who agrees with the player still challenge them as a demanding ally? | Yes |
