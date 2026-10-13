# Batch 1 draft: what was written, and how well it fits the scheme

Draft workbook: `design/drafts/CoP_Batch1_Draft_2026-10-13.xlsx` (a full copy of the master with the batch applied; the master workbook is unchanged). Everything in it is a draft for Cameron to rewrite. Written 2026-10-13 against guide section 2.8.

## Executive summary

| | |
|---|---|
| **What it is** | The transition pools (the biggest gap), plus two topic levels of four new rooms each: **Rail Fares and Timetables** and **Fishing Quotas and Harbours**. |
| **Does it fit the scheme?** | **Yes, with four adjustments.** The data exports clean, every game test passes, the new rooms play like their families, and the new text meets the Tone Guide checks. Writing it exposed one real code bug, one scheme gap and two guidance changes (below). |
| **Real bug found and fixed** | A blank Stage ID in any transition table (the "any room" wildcard) was read as the text "<null>", so no transition could ever appear. Fixed in `PoolPicker.gd` with a test, and a new real-click test now walks the transition screen. |
| **Needs your call** | Bot win rate on both Media Ambush rooms is 0% (the existing one too); LV61 overlaps the existing LV14; Japanese stage names are my drafts. |

## What was drafted

| Part | Count | Notes |
|---|---|---|
| New rooms | 8 | ST24-ST31, each built from an existing family (table below) |
| New levels | 2 | LV61 Rail Fares and Timetables, LV62 Fishing Quotas and Harbours: Office Hours first, then four topic rooms |
| Stage Questions | 36 (S34-S69) | 11 new Question Themes rows; every theme pleases existing organisations |
| Player Cues | 24 rows (120 lines) | Scoped to each level's four rooms; two suits per level, attack/gain/block, 10 lines per cell |
| Opponent Cues (room-scoped, general) | 24 rows (120 lines) | Same shape |
| Transitions | 6 cast, 9 backgrounds, 34 exchanges | 12 any-room, 6 for the busiest existing rooms (Floor Debate, Caucus, Press Conference), 16 for the new rooms |
| Show Transition | on for 20 existing combat rooms and the 8 new ones | Office Hours, Steering Check-in and Floor Vote stay off |
| Seating | 26 existing opponent rows gained a new room ID | No new people |
| Art tracker | 8 Assets rows | New room backgrounds, marked not drawn |

| Room | Built from | Questions | Topic-pure? |
|---|---|---|---|
| ST24 Town Hall on Commuter Fares | Town Hall | 5 stage + 104 pool | No (pool kept) |
| ST25 Policy Study on Rail Timetables | Policy Study | 3 stage + 30 pool | No |
| ST26 Press Conference on Raising Train Fares | Press Conference | 6 stage, pool blank | Yes (asks exactly its 6) |
| ST27 Hearing on Rail Safety | Committee | 6 stage | Yes |
| ST28 Lobbyist Meeting on Fishing Quotas | Lobbyist Meeting | 2 stage + 77 pool | No |
| ST29 Town Hall at the Harbour | Town Hall | 5 stage + 104 pool | No |
| ST30 Media Ambush on Seafood Labelling | Media Ambush | 3 stage + 27 pool | No |
| ST31 Hearing on Fishery Quotas | Committee | 6 stage | Yes |

## Fit against the scheme (guide section 8 checks)

| Check | Result |
|---|---|
| Export ends "No errors" | Pass (only the four older OP15/22/35/40 warnings) |
| Full game test suite and `tools/verify.sh` | Pass: GUT 1035 / 1035, and all verify.sh checks (including the new transition click test) |
| Each level validates and expands | Pass; every room seats its opponents and stage questions |
| Affinity: two up, two down, two neutral | Pass for all 8 (checked in code) |
| Numbers inside the family's range | Pass; thresholds 55-60 and 58 for Town Hall/Press, energy and gaffe limits copied or varied within range |
| Question grading near the room-tab spread | Pass. Strong / Weak: Earnest 47/16 (target 54/14), Emotional 36/27 (38/27), Appeal 25/19 (29/20), Data 44/19 (42/19), Divisive 36/38 (35/38), Duplicitous 38/30 (35/24). Every question has at least 2 Strong |
| Cue cells hold at least 10 lines, all three verbs | Pass |
| Cue lines: 9 words or fewer, no time words, no digits, no reply-dependence | Pass (word and time-word check run in code; reply-dependence read by hand) |
| Transition lines: 18 words or fewer, reply 8 or fewer, short enough for the banner | Pass; longest line is 74 characters, against about 110 that fit in 4 seconds |
| Numbers stored as numbers; current values re-read from the master | Pass; level rows copy LV14's value types, edits are appends only |
| Bot win rates against family baseline (40 fights x 4 protagonists) | See below |

### Bot win rates (160 fights per room, a well-equipped player)

| New room | Wins | Family baseline | Reading |
|---|---|---|---|
| ST24 Town Hall (fares) | 147 / 160 | ST05 138 / 160 | In family |
| ST25 Policy Study | 160 / 160 | ST21 160 / 160 | In family |
| ST26 Press Conference | 154 / 160 | ST04 160 / 160 | In family |
| ST27 Rail Safety hearing | 160 / 160 | ST15 160 / 160 | In family (committees are easy for the bot) |
| ST28 Lobbyist | 127 / 160 | ST20 142 / 160 | In family, slightly harder |
| ST29 Town Hall (harbour) | 160 / 160 | ST05 138 / 160 | Easier than ST05 (threshold 58 vs 60 and the topic questions); raise the threshold to 60 to match |
| ST30 Media Ambush | 0 / 160 | ST19 0 / 160 | In family, but see "Needs your call" |
| ST31 Fishery hearing | 160 / 160 | ST13 160 / 160 | In family |

Also run for reference: Floor Debate ST02 160 / 160 and Caucus ST03 132 / 160, neither changed.

## What writing it showed (changes to the scheme)

| # | Finding | Action |
|---|---|---|
| 1 | **Bug.** `PoolPicker.eligible()` read a blank Stage ID (JSON null) as "<null>", so wildcard rows in Transition Cast, Backgrounds and Dialogue never matched and every transition resolved to nothing. The pools had been empty, so nobody saw it. | Fixed (`scripts/rules/PoolPicker.gd`), GUT test added, and a new real-click test (`tests/interaction/stage_transition_test.tscn`, added to `verify.sh`) fails without the fix. |
| 2 | **Topic lines are rare.** A room's cast is the any-room cast plus any room-scoped cast, and each character picks among their own lines, so a topic-scoped line is heard only about 1 transition in 8 (measured 22-42 of 300 per room). | Guide: for each topic room write at least one room-scoped line for every cast member (6 per room), or keep any-room lines to one per character. Not done in this batch so the effect could be measured. |
| 3 | **Switching transitions on changes test flows.** The Office Hours click test expected the next stage straight after the last visitor; with a transition now in between it failed. | Test updated to tap Continue. Guide: after switching Show Transition on, re-run `verify.sh`. |
| 4 | Stage Questions for the committee-style rooms: 6 questions for 10 turns. | Allowed (existing committees have 3). Guide: floor 3, aim for at least half the turn limit. |

## Needs your call

| Question | Why it matters |
|---|---|
| **Media Ambush wins 0 of 160** for the bot, on both the existing ST19 and the new ST30 (11 turns, 2 gaffes allowed, 3 opponents). | The new room follows the family exactly, so it inherits this. Whether the ambush is meant to be near-unwinnable is yours to say. |
| **LV61 overlaps LV14 "Fixing the Daily Commute".** | I kept both; rename or drop one if you want a single commute level. |
| **Stage and level names, including the Japanese names**, are my drafts. | Check the Japanese especially. |
| **ST29's threshold** (58) makes it easier than ST05. | Set to 60 to match, or keep it as the gentler harbour room. |
| **Ambush and hearing question counts** | The two hearings and the press conference are topic-pure (they ask only their own questions); the other five also draw on the generic pools. |

## Not covered

No test plays the new levels through the whole Office-to-level flow with real clicks (the bot trials fight each room; the transition test walks the transition screen). No art exists for the 8 new backgrounds (labelled placeholders show). Cues were checked by rule and by reading, not played.
