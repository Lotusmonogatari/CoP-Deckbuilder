# Feedback on CoP_Content_Consolidated_Draft_2026-10-13.xlsx

For the assistant that drafted it. Read with `design/WORKBOOK_EXPANSION_GUIDE.md` (revised 2026-10-13: §2.7, §2.3 spread targets, §8 and §10 are new). Nothing here is canon until Cameron accepts it.

## Executive summary

| | |
|---|---|
| **Overall** | The structure and the bill, law and level content are good and should be kept. The question grading, cue scope, transitions and one edit need rework before anything is pasted. About 70% of the draft is paste-ready. |
| **Why the problems happened** | The earlier guide described tabs and tone but not how the engine reads them: tiers shadow each other, Stage Questions are dealt ahead of room pools, transitions auto-advance in 4 seconds. The guide now says so. |
| **Do first** | Fix the OP30 edit and the four text-typed levels. Then rework questions, cues and transitions. Then run the audit and bot trials in the guide's §8. |

## Keep (as drafted)

| Tab or part | Why it is good |
|---|---|
| Headers and paste-ready layout | All 12 tab headers match the master exactly and in order. No ID collisions. |
| Bills BI31–BI36 and Party Positions | Every bill totals 101 seats, every party's split equals its seat count, dispositions agree with each party's vote lean, and three bills pass and three fail by default under the 51-of-101 rule. |
| Vote Influence Cues | All six point the right way for their default outcome. |
| Law Effects LW64–LW75 | Valid organisations, both outcomes for every bill, the same size scale as the master, and every organisation is still pleased and annoyed by some bill outcome. |
| Levels LV61–LV70 (after the type fix) and the ten level edits | The ten "Current" values match the master for levels. Slots are valid and each bill is placed in exactly one level. |
| Level Intro Thoughts LV61–LV67 | Short, in tone, every level exists. |
| Question Themes (19 new) | Unique, valid organisations, drafted with Why notes. |
| Affinity for ST24–ST44 | Every column is exactly two up, two down, two neutral. |
| Assets rows for the new backgrounds | Present for every new room. |
| Seating of existing characters | No new characters, which respects the canon rule. Every new room has more eligible opponents than its Opponent Count. |
| Party-voice cues for the six leaders (OC55–OC72) | Correct for each leader. OP10 is Prime Minister Aki Rono, so "my government's course" is in canon. |
| Cue tone | No line over 9 words and only one time word ("until" in PL222, replace it). The two "Finally" fixes in Edits are right. |
| Party-limited questions | Every one has a seated asker. |
| Change Log, Decisions and Bill Notes | Useful. Keep this habit and add the checks below. |

## Change

| # | What to change | How |
|---|---|---|
| 1 | **OP30 edit** is stale. The master reads "ST10; ST03; ST08", not "ST10; ST03". | Propose "ST10; ST03; ST08; ST29; ST30; ST31; ST32". Re-read every other Current value from today's master before sending. |
| 2 | **Levels LV61, LV68, LV69, LV70** store Level Tier, Cooldown and the unlock XP costs as text. | Make them numbers. Check every tab for text-typed numbers. |
| 3 | **Stage Questions on rooms that already have a Question Pool** (ST04 6, ST20 6, ST21 6, ST19 5, ST05 6). They are dealt first, and a stage asks only turn_limit questions in total, so ST04's 34 press questions would never appear. | Remove them, or reduce each room to one third of its turn_limit (ST04 at most 2). Put the rest into the room's own question tab if Cameron wants them. |
| 4 | **Questions switched on for ST02, ST03, ST06 and ST08**, which ask none today. This changes their difficulty and ST06 was tuned without questions. | Remove those 69 rows, or move them to a "Proposed, needs Cameron" tab. Re-add only with his yes and a bot trial before and after. |
| 5 | **Grading skew.** Strong share per suit: Earnest 90%, Emotional 44%, Appeal 41%, Data Driven 64%, Divisive 41%, Duplicitous 5%. Weak share: Earnest 0%, Divisive 52%, Duplicitous 73%. | Regrade to within about 15 points of the master's room-tab spread (Earnest 54 / 14, Emotional 38 / 27, Appeal 29 / 20, Data Driven 42 / 19, Divisive 35 / 38, Duplicitous 35 / 24, Strong / Weak). Vary which suit is best by question and make the room's favoured suits best on some questions and worst on others. Report the table. |
| 6 | **Player Cue rows on all 20 existing rooms** (240 rows) replace the card Flavor Text there. | Keep rows for the committees (extend the existing PL01–PL18 pattern) and for new or unique rooms. Remove rows for ST02–ST06, ST08 and ST19–ST21 unless Cameron asks. Report lines per (suit, verb), and give every shadowed cell at least two rows. |
| 7 | **Opponent Cue stage pools of 5 lines** in the base rooms replace the 10 universal lines. | In a room, write 10 lines per suit and verb or none. Remove stage rows for the base rooms. |
| 8 | **Transitions are too long and too repetitive.** Lines run 27–52 words, the banner holds 4 seconds at most, there is one fixed line per stage, and Show Transition on all existing rooms makes 302 transitions fire across the levels (ST03 alone 45). | Limit lines to 18 words and replies to 8. Write at least 3 variants per stage. Set Show Transition only on the new rooms and remove the 20 edits for existing rooms. Describe each room's feel in plain words, with no numbers. |
| 9 | **Transitions that can never play.** A transition fires only before a non-first stage, so ST24, ST29, ST33 and ST38 never show theirs. ST37 (Booster Rally) is used by no level. | Move the stage to a later slot, or drop its transition. Add ST37 to a level or remove it and its seating edits. |
| 10 | **Stage economy is uniform** (hand 5, energy 3–4, gaffe limit 4–5, player start 15–20, opponent start 20–30, threshold 55–60 on a 100 bar). | Vary by room difficulty, then run `PLAYTEST_STAGE_TRIAL` on each of the 21 rooms and report the win rates. |
| 11 | **Favored suit and Segment check are pasted as values.** The master formulas read Affinity only up to column V. | Paste formulas, extend the range to the new Affinity columns, and say so in the notes. |
| 12 | **Visitor Questions:** the correct answer is the longest choice in 33 of 35, and "D" is right only 6 times. | Shorten or lengthen the right answer and spread it across A to D. |
| 13 | **Transition speakers** are SF01, SF08 and SF15 whether or not the player hired them. | Keep them as defaults, but state it as a decision for Cameron (Decision 5), because the screen does not check hiring. |
| 14 | **Decision 1 (do rows pool?)** is answered: rows at the same tier pool, and a more specific tier replaces less specific ones. Staff IDs are accepted in Transition Cast. | Delete the doubt from the notes and add the shadowing rule. |

## Decisions that are Cameron's, not yours

| Decision | Options |
|---|---|
| New geography and institutions: Aomori, Hokkaido and Chishima Prefectural Assemblies, the Strait Commission, the Joint Zone, and real-world analogues for the bills | Accept, rename, or drop. List them in a Decisions tab. |
| Commuters at the Station Rally played by OP106–OP108, and OP125 as the only Society member | Accept, or ask him to cast real BO14 and BO15 characters. |
| Whether ST02, ST03, ST06 and ST08 should ask questions at all | Yes, with a bot trial first, or no. |
| Whether base rooms should keep card Flavor Text or move to room-specific lines | Keep (recommended), or replace in named rooms. |

## What to send back

1. A corrected workbook with one change log (what moved from the first draft and why).
2. The §8 audit table from the guide, filled in.
3. Bot win rates for the 21 new rooms.
4. A short list of the decisions above, with your recommendation for each.
