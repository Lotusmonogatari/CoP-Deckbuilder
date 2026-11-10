# Gameplay mechanics review: summary

Coliseum of Parliament, Godot 4.5.1, GDScript. Reviewed 2026-11-10. **Read-only**: nothing outside `audit/gameplay/` was changed, and nothing has been committed. No target session length or intended feel was supplied (the Context section of the brief was blank), so I judged against `design/GAME_DESIGN.md` and `design/GAME_SYSTEMS.md`.

Evidence base: 56 simulated 30-week runs with the project's own strategy bot (6 strategies, 4 protagonists, seeds 1 and 2), the real data files, and targeted reading of `BattleEngine`, `GameState`, `PartyDues`, `SaveManager`, `CardView` and `BattleScreen`. **Nothing was run on a device.** Anything about feel, timing on phones, or what a human does is unverified.

## Verdict on the core loop

The battle loop is sound and well-tested but easy: the bot wins 92 to 99 % of stages, no combat threshold is out of reach on paper, and I found no crash, softlock or infinite loop. The meta loop is where the design leaks: Party support and Constituency support hit their ceilings by week 4 to 8 and then stop moving; replaying the shortest Tier 0 level pays more per hour than the longer Tier 1 and 2 levels and never decays, so grinding is the optimal strategy; and party dues outrun the Funds cap, so 47 of 56 runs ended owing over 1,000,000 with only one counter-strategy (buy cap petitions first) that a new player has no way to discover. A stage's loss is also only applied when the result panel is closed, and nothing inside a stage is saved, so on a phone a loss can be avoided by closing the app. Whether the game *feels* good is something only a human playtest can say.

## Count by severity

| Severity | Count |
|---|---|
| Blocker | 0 |
| High | 4 |
| Medium | 14 |
| Low | 17 |
| **Total (unique)** | **35** |

Five findings appear in more than one phase file and are counted once: X-01 is B-08, X-02 is G-01, X-03 is T-06, X-04 is B-05, X-06 is G-08. G-02 and G-09 also restate C-02 and C-05 of the project audit (`audit/02-code.md`) with extra detail, and F-01 restates A-04; they are counted here but not added to the project audit's totals.

## All findings, by severity

Effort: S under a day, M a few days, L a week or more. Detail is in the phase file named in the last column.

| ID | Severity | Mechanic | What's wrong | Effort | Confidence | File |
|---|---|---|---|---|---|---|
| G-01 (X-02) | High | Stage loss / save | A loss is only applied when the result panel is closed, and nothing mid-stage is saved; force-closing on "Lost" gives a free retry and keeps one-time levels | M | Medium | 03, 05 |
| B-05 (X-04) | High | Party dues vs Funds cap | Dues (190k to 280k a week) exceed the 100k Funds cap; 47 of 56 runs end owing over 1M; only "cap petitions first" works | S to M | High | 04, 05 |
| B-08 (X-01) | High | Level rewards / grind | Tier 0 pays more per hour than Tier 1 and 2 (7,500 vs 6,000 and 5,556 Funds; 40 vs 27.5 and 26.5 XP) and repeats do not decay; grinding is dominant | M | High | 04, 05 |
| F-01 | High | Audio feedback | No sound at all; card plays, gaffes and results are silent | L | High | 06 |
| G-02 | Medium | Mid-stage progress | Stage progress is lost on app kill; the battle RNG is unseeded, so a retry also re-rolls luck | M | Medium | 03 |
| G-03 | Medium | Gaffe vs threshold | A card that fills the gaffe meter and crosses the threshold together is a loss; not documented for the player | S | High | 03 |
| G-04 | Medium | Party dues | Overdue multiplier `1.5^(owed/100000)` has no ceiling | S | High | 03 |
| G-05 | Medium | One-time levels | A lost one-time bill level is gone for the run | S | Medium | 03 |
| G-06 | Medium | Patron request start | 1,472 "could not be started" reports from the bot (likely work-week limit plus a bot that declines); cause not isolated | S | Low | 03 |
| B-01 | Medium | Card power curve | Mean points per energy falls from Tier 1 (4.00) to Tier 2 (2.91) and Tier 3 (3.02) | M | Medium | 04 |
| B-02 | Medium | Stage difficulty | No stage is hard to reach on paper (median pace ratio 0.39); difficulty comes from opponents and gaffes only | M | Medium | 04 |
| B-03 | Medium | Difficulty curve | Flat after the first weeks; no tier above 2 exists; nothing above Tier 2 was played | M | Medium | 04 |
| B-06 | Medium | Funds sinks | The 200,000 and 300,000 items cannot be bought under a 100,000 cap | S | Medium | 04 |
| B-07 | Medium | Meta meters | Party and Constituency support reach their ceilings by week 4 to 8 and stop moving | M | Medium | 04 |
| T-01 | Medium | Generated bill votes | The vote-split formula for drafted bills is all hard-coded constants | M | High | 02 |
| T-06 (X-03) | Medium | Stage loss | A lost stage pays a little XP and Funds (201 of 230 combat stages); losing is nearly free | S | High | 02 |
| F-02 | Medium | Haptics | No haptic feedback anywhere | S | High | 06 |
| F-04 | Medium | Card drag distances | 30 px lift and 220 px play are literals in `CardView.gd`, not Balance rows | S | Medium | 06 |
| G-07 | Low | Press conference end | A boundary case (last card answers the last question with an empty deck) lacks a test I could find | S | Low | 03 |
| G-08 (X-06) | Low | Abandon patron level | An abandoned un-drafted patron level returns to OPEN; whether it costs standing was not traced | S | Low | 03, 05 |
| G-09 | Low | Quit fallback | Result panel quits the app if no level is in progress (same as project audit C-05) | S | High | 03 |
| B-04 | Low | Party Steering Committee | ST08 is won only 50 % of the time (208 attempts) | S | Medium | 04 |
| X-05 | Low | Stacking | Caps look correct; no way found to exceed them | - | Medium | 05 |
| T-02 | Low | Election strength | `party_share *= 0.5` hard-coded | S | High | 02 |
| T-03 | Low | Conditional card effects | Audience thresholds (0.5, 0.2) hard-coded | S | Medium | 02 |
| T-04 | Low | Level cooldown | 5,994 is a magic "never again" on 51 of 114 levels, redundant with One-Time on 50 | S | High | 02 |
| T-05 | Low | Code defaults | 27 Balance defaults in code disagree with the data row | S | High | 02 |
| T-07 | Low | Card prices | Card `xp_to_unlock` (5 to 15) is 50x the shop prices and unused while `open_card_collection` is off | S | High | 02 |
| T-08 | Low | Balance tab | Empty `xp_tiers` row read by nothing | S | High | 02 |
| T-09 | Low | Difficulty rows | Mix deltas and absolute values under one prefix | S | Medium | 02 |
| T-10 | Low | Starting standing | Starting standing may disagree with the design doc | S | Low | 02 |
| F-03 | Low | Gaffe warning | Only a red label one gaffe before a stage-ending loss; no sound or pulse | S | Medium | 06 |
| F-05 | Low | Diagonal drags | Lift vs hand scroll ambiguity on diagonal flicks | S | Low | 06 |
| F-06 | Low | Controller parity | No controller or keyboard play (S-08 in project audit) | L | High | 06 |
| F-07 | Low | Hit pause / shake | Only the cue banner animates; little other impact feedback | S | Low | 06 |

Notes carried from `01-mechanics-map.md` (not scored): Election Strength is built and shown but fires nothing; segment favorability appears dead; the resource loop feeds battles only through the deck, backings and items.

## Playtest checklist

What a human should try. "Watch for" is what to look for; none of it can be settled from code.

| # | Try this | Watch for | Settles |
|---|---|---|---|
| 1 | Play weeks 1 to 8 with no advice, buying whatever looks useful | Does the player notice dues growing? Do they find the cap petition (SH13)? Do they fall behind by week 5? | B-05, G-04, B-06 |
| 2 | Play only the shortest level for an hour, then play a Tier 1 or 2 level | Does grinding feel boring or does it feel like winning? Does the longer level feel worth 5 to 8 times the time? | B-08, X-01 |
| 3 | Lose a stage on purpose, then lose one by accident | Is a loss felt (XP, Funds, standing, a lost one-time level)? Is it avoidable by quitting? | T-06, G-05, G-01 |
| 4 | Lose a stage, then force-close the app on the result panel and reopen | Is the stage lost, retried, or is the loss still counted? | G-01 |
| 5 | Take a phone call (background) in the middle of a stage near the end, then return, and again with the app killed | Resume state; lost progress | G-02 |
| 6 | Play a whole level on a real phone one-handed | Is the 220 px throw comfortable? Dropped cards? Hand scrolling by accident? | F-04, F-05 |
| 7 | Reach 3 gaffes in a stage with a 3-gaffe limit | Does the red label and the loss feel fair or sudden? | F-03, G-03 |
| 8 | Win a stage with a card that crosses the threshold on the same card as the last gaffe | Win or loss? Does the result match what the player expects? | G-03 |
| 9 | Play to week 12 | Do Party and Constituency support still feel like goals? What does the player chase? | B-07, B-03 |
| 10 | Play a Press Conference with an almost-empty hand | Does it end at the right moment? | G-07 |
| 11 | Accept a patron request when few work hours are left in the week | Is the refusal reason clear? | G-06 |
| 12 | Play with sound off and on, on a real device (once there is sound) | Does a card play feel weighty? | F-01, F-02 |
| 13 | Play Tier 2 cards against Tier 1 cards in the same stages | Is the more expensive card actually stronger? | B-01 |
| 14 | Time a typical stage and a typical week with a stopwatch | Real minutes per stage; supplies the session length this review could not give | all pacing |

## Suggested fix order

Small batches, each approvable alone. **Nothing here has been done.**

| Batch | What | Findings | Why now |
|---|---|---|---|
| 1. Make a loss real | Apply `finish_stage` the moment the outcome is decided (show the panel afterward) | G-01, G-05 | The one possible progress exploit; a small change in one place plus a test |
| 2. Dues | Cap the overdue multiplier (new Balance row); tell the player early what dues cost and how the cap works | G-04, B-05, B-06 | Fixes the economy cliff without redesign; needs Cameron's decision on how soft to make it |
| 3. Repeat and tier payoff | Raise Tier 1 and 2 rewards per hour above Tier 0, or decay repeated levels using the existing cooldown column | B-08, X-01 | Removes the dominant strategy; needs Cameron's decision on numbers |
| 4. Hard-coded numbers to the Balance tab | Card drag distances, the bill-vote formula, election strength halving, audience thresholds; reconcile code defaults | F-04, T-01, T-02, T-03, T-05 | Matches the project's own rule (no design numbers in scripts); mechanical and testable |
| 5. Small clarity items | Document gaffe-vs-threshold order; trace the Abandon patron penalty; add the missing press-conference test; log patron refusals in the bot | G-03, G-08, G-07, G-06 | Cheap and removes uncertainty |
| 6. Meter ceilings | Decide what Election Strength should unlock, or let meters decay at the ceiling | B-07, B-03 | A design decision, so ask first; the unlock question is already open in CLAUDE.md |
| 7. Feedback | Haptics behind a setting; a pulse or banner at the gaffe critical edge; first sounds | F-02, F-03, F-01 | Biggest "feel" payoff; sound is the largest effort |
| 8. Content and tuning review | Card tier power, difficulty curve, Steering Committee | B-01, B-02, B-04 | Needs the playtest results first |
| 9. Tidy-ups | Low items: duplicates, empty Balance row, difficulty row naming, card price column | T-04, T-07 to T-10 | Any time; never delete without Cameron's say-so |

## What I could not check

| Not checked | Why |
|---|---|
| Any behaviour on a device | No build exists |
| Real-time pacing and session length | The sims have no human timing; no target was supplied |
| Whether G-01 really works | Read from code only; needs a kill test |
| The vote resolution and rounding | Read, not simulated |
| Dues behaviour under Relaxed and Harder difficulty | Only `standard` was simulated |
| Why the bot could not start patron bills | The refusal reason was not logged |

## Files

| File | Contents |
|---|---|
| `01-mechanics-map.md` | Every mechanic, core and meta loop, code versus intent |
| `02-tuning.md`, `tuning_balance.md`, `tuning_extract.py` | Every number, where it lives, magic numbers |
| `03-correctness.md` | State machines, timing, boundaries, persistence |
| `04-balance.md`, `balance_static.py`, `analyze_sims.py`, `sim/*` | Simulation scripts, raw runs and output |
| `05-exploits.md` | Exploits and dominant strategies |
| `06-input-feel.md` | Input and feedback |
