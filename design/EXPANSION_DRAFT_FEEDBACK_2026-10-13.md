# Feedback on CoP_Content_Consolidated_Draft_2026-10-13.xlsx (reissued)

For the assistant that drafted it. Read with `design/WORKBOOK_EXPANSION_GUIDE.md` (§2.7, §3.0 and §10 changed). **Cameron's directions (2026-10-13):** the new geography and people are approved; new rooms follow the game's current norm; the expansion changes no mechanics; **every room, existing and new, may draw on the base (generic) content and on stage-specific content where it applies.** An earlier version of this feedback wrongly told you to strip stage-specific content from existing rooms and to keep transitions off. That was incorrect and is withdrawn: the draft's intent (stage-specific content on all rooms) stands.

## Executive summary

| | |
|---|---|
| **Overall** | The draft's intent is right and most of it stays. What needs fixing is data quality and sizing, not scope: a stale edit, text-typed numbers, question counts that crowd out generic pools, thin cue pools, skewed grading, over-long transitions, and new-room numbers that should follow their family. |
| **Approved** | The Aomori, Hokkaido and Chishima assemblies and hearings, and the people seated in them. |
| **Do first** | Fix the OP30 edit and the four text-typed levels, then work down the table. |

## Keep (as drafted)

| Part | Note |
|---|---|
| Layout and headers | All 12 tab headers match the master. No ID collisions. |
| Bills BI31–BI36, Party Positions, Vote Influence Cues, Law Effects LW64–LW75 | 101 seats, correct totals, correct cue directions, valid organisations. |
| Levels LV61–LV70 (after the type fix) and the ten level edits | "Current" values match the master. |
| Level Intro Thoughts, Question Themes, Affinity, background Assets rows, seating | Clean and in house style. |
| **Stage-specific content on every room**, existing and new: Stage Questions, Player Cues, Opponent Cues, Show Transition and the Transition tabs, and the Edits that enable them | This is the intent. Keep it, with the sizing fixes below. |
| Leader party-voice cues, cue tone, Change Log, Decisions, Bill Notes | Good. |

## Change

| # | What | How |
|---|---|---|
| 1 | **Stale OP30 edit** (master reads "ST10; ST03; ST08"). | Propose "ST10; ST03; ST08; ST29; ST30; ST31; ST32". Re-read every Current value from today's master. |
| 2 | **Levels LV61, LV68, LV69, LV70** store tier, cooldown and XP costs as text. | Make them numbers, everywhere. |
| 3 | **Stage Questions crowd out the generic pools.** A stage asks only turn_limit questions in total and Stage Questions are dealt first: ST04 has 6 of 6, ST20 6 of 7, ST21 6 of 10, ST19 5 of 11, ST05 6 of 17. | For rooms with a Question Pool, cut to at most a third of turn_limit (ST04: 2) so the pool still plays. Rooms with no pool keep their Stage Questions (3 to turn_limit). |
| 4 | **Questions on ST02, ST03, ST06, ST08** switch on a difficulty mechanic those rooms do not have today (ST18 went from 40% to 100% bot wins when it gained questions). | Keep them if intended, and run `PLAYTEST_STAGE_TRIAL` before and after; report the win rates (ST06 is the survival bar, so check it first). |
| 5 | **Grading skew.** Strong share per suit: Earnest 90%, Emotional 44%, Appeal 41%, Data Driven 64%, Divisive 41%, Duplicitous 5%. Weak: Earnest 0%, Divisive 52%, Duplicitous 73%. | Regrade to within about 15 points of the room-tab spread (Strong / Weak: Earnest 54 / 14, Emotional 38 / 27, Appeal 29 / 20, Data Driven 42 / 19, Divisive 35 / 38, Duplicitous 35 / 24). Report the table. |
| 6 | **Cue pools of 5 lines** per suit and verb, thinner than the 10-line universal Opponent Cue pool and than the card's own Flavor Text, which a stage row replaces in that room. | Write at least two rows (10 lines) for every suit and verb you cover, cover attack, gain and block, and leave a cell empty if you do not want to replace the generic one. For committee-style rooms, also append the STxx to PL01–PL18's Stage ID cells so they pool. |
| 7 | **Transitions are too long and too repetitive.** Lines run 27–52 words but the banner holds a line at most 4 seconds (about 110 characters). One fixed line per room fires 302 times across the levels (ST03 alone 45). | Character line 18 words or fewer, reply 8 or fewer, at least 3 variants for frequently reached rooms, no numbers. ST24, ST29, ST33 and ST38 are only ever first slots, so their transitions never show: move them to a later slot or accept that. |
| 8 | **New-room numbers should follow their family** (guide §3.0): hearings from the committee row, visits, rallies and the town meeting from the Town Hall row, the Student Seminar from the Policy Study row. | Keep each family's bar unit, sequence mode, opponent count and question source; vary the numbers only inside its range, and vary by difficulty (the draft uses almost identical hand, energy and gaffe numbers). |
| 9 | **ST37 Booster Rally** is in no level. | Add it to a level or drop it and its seating. |
| 10 | **Favored suit and Segment check** are pasted as values, and the master formulas stop at Affinity column V. | Paste formulas and extend the range. |
| 11 | **Visitor Questions:** the correct answer is the longest choice in 33 of 35. | Vary lengths and spread the right answer across A to D. |

## What to send back

1. The corrected workbook with one change log.
2. The audit table from guide §8.
3. Bot win rates for every new room and for ST02, ST03, ST06 and ST08.
