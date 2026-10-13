# Batch 1 draft: what was written, and how well it fits the scheme

Draft workbook: `design/drafts/CoP_Batch1_Draft_2026-10-13.xlsx` (a full copy of the master with the batch applied; the master workbook is unchanged). Everything in it is a draft for Cameron to rewrite. Revised 2026-10-13 to meet the three-times rule (guide section 2.9).

## Executive summary

| | |
|---|---|
| **What it is** | The transition pools, two topic levels of four new rooms each (**Rail Fares and Timetables**, **Fishing Quotas and Harbours**), and the depth every room needs to hold three times what a run meets. |
| **Does it fit the scheme?** | **Yes.** The data exports clean, all 1,035 game tests and `tools/verify.sh` pass, the new rooms play like their families, and the new text meets the Tone Guide checks. |
| **Three-times rule** | With the batch, every combat room clears 3x on questions, player cues, opponent cues and transitions. The one measure still short is **people**: 9 rooms need 8 new characters between them (listed below), which is yours to cast. |
| **Real bug found and fixed** | A blank Stage ID in a transition table (the "any room" wildcard) was read as "<null>", so no transition could ever appear. Fixed in `PoolPicker.gd` with tests, and a new click test now walks the transition screen. |
| **LV61 and LV14** | Not an overlap: each room carries its own content on top of the general content. Removed from the open questions. |

## What was drafted

| Part | Count |
|---|---|
| New rooms | 8 (ST24-ST31), built from existing families |
| New levels | 2 (LV61, LV62): Office Hours, then four topic rooms |
| Stage Questions | 76 (S34-S109): 36 topic questions, 28 general committee questions shared by all 13 committee-style rooms, 12 more press questions for ST26 |
| General Media Ambush questions | 6 (A28-A33) |
| Question Themes | 11 new rows |
| Player Cues | 150 rows (750 lines): topic sets for each level; a Town Hall family set (ST05, ST24, ST29); a Caucus set (ST03); a TV Debate set (ST06); two more rows per committee cell |
| Opponent Cues | 24 rows (room-scoped, general) |
| Transitions | 6 cast, 9 backgrounds, 34 exchanges; Show Transition on for 20 existing combat rooms and the 8 new ones |
| Seating | existing people listed on the new rooms (no new people) |
| Art tracker | 8 Assets rows (new room backgrounds, not drawn) |

## The three-times rule: before and after

`python3 tools/content_depth.py` measures it (figures: asked per run against what the room can draw). Master first, with the batch second.

| Room | Questions | Player cues | People |
|---|---|---|---|
| Committees (ST01, ST09-ST18) | 10 asked / 3 can draw (0.3x) -> 31 (3.1x) | long committees (ST09, 11, 12, 14-17) at 1.2-2.5x -> all 3.4x or more | unchanged |
| ST03 Party Caucus | asks none | 2.4x -> 8.0x | 5.0x |
| ST05 Town Hall | 6.1x | 1.8x -> 3.0x | 2.7x (short) |
| ST06 TV Debate | asks none | 2.6x -> 3.1x | 9.0x |
| ST19 Media Ambush | 2.5x -> 3.0x | 6.5x | 2.7x (short) |
| ST24-ST31 (new) | 3.0x to 11.3x | 4.2x to 12.9x | 2.3x to 8.0x |

Short on **people** (needs 3x the people it seats), all because canon limits who may sit there:

| Rooms | New characters needed |
|---|---|
| ST05, ST24, ST29 (Town Halls) | 1 more constituent |
| ST19, ST30 (Media Ambush) | 1 more journalist |
| ST11 Committee on War | 1 more member |
| ST15 and ST27 (Construction and Development) | 2 more members |
| ST16 Finance | 3 more members |

## Fit against the scheme

| Check | Result |
|---|---|
| Export ends "No errors" | Pass (only the four older OP15/22/35/40 warnings) |
| Game tests and `tools/verify.sh` | Pass: GUT 1035 / 1035, all verify.sh checks including the new transition click test |
| Each level validates and expands | Pass |
| Affinity two up, two down, two neutral | Pass for all 8 |
| Numbers inside the family's range | Pass |
| Question grading near the room-tab spread (Strong / Weak) | Pass: the 40 new general and press questions are Earnest 50/15, Emotional 35/27, Appeal 35/22, Data Driven 42/20, Divisive 40/27, Duplicitous 35/35; the 36 topic questions are within about 15 points. Every question has at least 2 Strong |
| Cue lines: 9 words or fewer, no time words, no digits, not a reply | Pass (checked in code, then read by hand) |
| Transition lines: 18 words or fewer, reply 8 or fewer | Pass; longest line 74 characters |

### Bot win rates (160 fights per room, a well-equipped player)

| Room | Wins | Family baseline | Reading |
|---|---|---|---|
| ST24 Town Hall (fares) | 141 | ST05 155 | In family |
| ST25 Policy Study | 159 | ST21 160 | In family |
| ST26 Press Conference | 155 | ST04 160 | In family |
| ST27 Rail Safety hearing | 160 | ST15 159 | In family |
| ST28 Lobbyist | 126 | ST20 143 | In family, slightly harder |
| ST29 Town Hall (harbour) | 137 | ST05 155 | In family |
| ST30 Media Ambush | 0 | ST19 0 | Matches the family, see below |
| ST31 Fishery hearing | 160 | ST13 160 | In family |

Existing committees now ask 10 questions instead of 3 and stay at 159-160 of 160 (ST01, ST09, ST11, ST16); ST18, tuned to 45-50%, is 111 of 160 (one protagonist's deck wins 1 of 40, so it varies by deck).

## What writing it showed

| # | Finding | Action |
|---|---|---|
| 1 | **Bug.** `PoolPicker.eligible()` read a blank Stage ID as "<null>", so wildcard transition rows never matched. | Fixed, with a GUT test and `tests/interaction/stage_transition_test.tscn` (fails without the fix). |
| 2 | Room-scoped transition lines are heard about 1 transition in 8. | Guide: write a room-scoped line for every cast member. |
| 3 | Switching transitions on changes test flows. | Office Hours click test updated; guide says to re-run `verify.sh`. |
| 4 | **Stage Questions are always asked first.** A room with fewer Stage Questions than it asks repeats them every run; with more, a random subset plays. | Guide section 2.9: share a general set across rooms and make topic-pure rooms hold 3x their own. |
| 5 | The bot plays 50-80 cards in the longer committees, which is generous for a person. | The rule measures against the bot, so it is safe for people. |

## Needs your call

| Question | Why it matters |
|---|---|
| **Media Ambush wins 0 of 160** for the bot, on ST19 and on the new ST30. | The new room follows the family exactly, so it inherits this. Is the ambush meant to be nearly unwinnable? |
| **Eight new characters** to bring nine rooms to 3x on people. | Names and parties are yours. |
| **Names, including the Japanese ones**, are my drafts. | Check the Japanese especially. |
| **ST29's threshold** (58 against ST05's 60) | Match it at 60, or keep the gentler harbour room. |

## Not covered

No test plays the new levels through the whole Office-to-level flow with real clicks. No art exists for the 8 new backgrounds (labelled placeholders show). Cues were checked by rule and by reading, not played.
