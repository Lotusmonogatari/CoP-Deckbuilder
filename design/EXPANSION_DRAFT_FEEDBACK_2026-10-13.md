# Feedback on CoP_Content_Consolidated_Draft_2026-10-13.xlsx (revised)

For the assistant that drafted it. Read with `design/WORKBOOK_EXPANSION_GUIDE.md` (§2.7, §3.0 and §10 are new or changed). Revised after Cameron's reply on 2026-10-13: **the new geography and people are approved; the new rooms must follow the game's current norms; the expansion adds content and changes no mechanics; every room draws on the base (generic) content and adds stage-specific content only where it applies.**

## Executive summary

| | |
|---|---|
| **Overall** | The structure, bills, laws, levels, themes, affinity and seating are good and stay. What changes is how the new rooms are shaped and what is attached to them: build each room from an existing family, lean on the generic content, and drop anything that alters how existing rooms play. |
| **Approved, do not re-ask** | The Aomori, Hokkaido and Chishima assemblies, the Strait Commission and Joint Zone hearings, and the people seated in them (existing MPs and organisation members, OP106–OP108 and OP125 at the rallies). |
| **Do first** | Fix the OP30 edit and the four text-typed levels. Then rebuild the room rows from their family, remove what changes existing rooms, and rework the question grading. |

## Keep (as drafted)

| Part | Why |
|---|---|
| Layout and headers | All 12 tab headers match the master. No ID collisions. |
| Bills BI31–BI36, Party Positions, Vote Influence Cues | 101 seats each, correct party totals, dispositions agree with votes, three pass and three fail by default, every flip cue points the right way. |
| Law Effects LW64–LW75 | Valid organisations, both outcomes, same scale as the master, every organisation still pleased and annoyed somewhere. |
| Levels LV61–LV70 (after the type fix) and the ten level edits | The ten "Current" values match the master; slots valid; each bill in one level. |
| Level Intro Thoughts, Question Themes (19), Affinity (21 columns), background Assets rows | Clean and in house style. |
| Seating of existing characters | Approved. Every new room seats more people than it needs. |
| Leader party-voice cues (OC55–OC72) | Correct for each leader. |
| Cue tone | No line over 9 words; replace the one "until" in PL222. The two "Finally" fixes are right. |
| Change Log, Decisions, Bill Notes | Keep the habit. |

## Change

| # | What | How |
|---|---|---|
| 1 | **Stale OP30 edit** (master reads "ST10; ST03; ST08"). | Propose "ST10; ST03; ST08; ST29; ST30; ST31; ST32". Re-read every Current value from today's master. |
| 2 | **Levels LV61, LV68, LV69, LV70** store tier, cooldown and XP costs as text. | Make them numbers, here and on any other tab. |
| 3 | **Build each room from its family** (guide §3.0): hearings (ST25–27, 30–32, 34–36, 39–43) from the committee row; assembly visits, rallies and the town meeting (ST24, 29, 33, 37, 38, 44) from the Town Hall row; the Student Seminar (ST28) from the Policy Study row. | Keep the family's bar unit and value, sequence mode, opponent count and question source, and keep every number inside the family's range. The draft's bar units already match; check turns (Town Hall is 17), gaffe limit and starting numbers, and vary them by difficulty inside the range. |
| 4 | **Show Transition is Yes on every room, and the three Transition tabs are filled.** Today it is blank on all 23 stages. | Leave Show Transition and Transition Speaker Count blank everywhere and hold the Transition tabs back as a separate optional file. Remove the 20 Stages edits for existing rooms. |
| 5 | **Existing rooms are changed** by Stage Questions on ST02, ST03, ST06 and ST08 (69 rows), Player Cue rows on all 20 existing rooms (240 rows), stage-scoped Opponent Cue rows on them, and extra Stage Questions on ST04, ST05 and ST19–ST21. | Remove all of these. An expansion leaves existing rooms exactly as they are, apart from the listed seating and level-slot edits. |
| 6 | **Player Cues for new rooms.** Stage-scoped rows replace the card's Flavor Text in that room. | For committee-style new rooms, append the STxx to the Stage ID cells of PL01–PL18 (the norm for committees, listed under Edits). Stage rows with the same verbs may supplement them. Non-committee new rooms get no Player Cue rows and play the card's Flavor Text, like the Town Hall. |
| 7 | **Opponent Cues for new rooms.** Stage-scoped general pools of 5 lines replace the 10 universal lines. | Remove them. Rooms use the universal pool. Keep the opponent-scoped rows that carry a Stage ID (the seated MPs' party voice), since those add voice without removing the generic pool for everyone else. |
| 8 | **Stage Questions for new rooms.** | Committee-style rooms: 3 per room is the norm, more (up to turn_limit) only if needed. Town Hall-like and Policy Study-like rooms use their family's question pool and add at most a third of turn_limit as Stage Questions. |
| 9 | **Grading skew.** Strong share per suit: Earnest 90%, Emotional 44%, Appeal 41%, Data Driven 64%, Divisive 41%, Duplicitous 5%. Weak: Earnest 0%, Divisive 52%, Duplicitous 73%. | Regrade the kept questions to within about 15 points of the room-tab spread (Earnest 54 / 14, Emotional 38 / 27, Appeal 29 / 20, Data Driven 42 / 19, Divisive 35 / 38, Duplicitous 35 / 24, Strong / Weak). Report the table. |
| 10 | **Rooms no level reaches**: ST37 is in no level. | Add it to a level or drop it and its seating edits. |
| 11 | **Favored suit and Segment check** are pasted as values and the master formulas stop at Affinity column V. | Paste formulas and extend the range to the new Affinity columns. |
| 12 | **Visitor Questions:** the correct answer is the longest choice in 33 of 35. | Vary lengths and spread the right answer across A to D. |

## What to send back

1. The corrected workbook plus one change log (what moved from the first draft and why).
2. The audit table from guide §8.
3. Bot win rates for the new rooms (guide §8 item 10).
4. A separate optional file for anything held back (the transitions).
