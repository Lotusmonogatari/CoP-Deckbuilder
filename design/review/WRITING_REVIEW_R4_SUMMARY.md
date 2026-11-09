# Writing review R4: questions and visits (2026-11-09)

Draft by Claude (reviewer R4) for Cameron. Every proposed rewrite is a draft. Nothing in the workbook, `data/`, code or tests was changed. The ledger is `design/review/WRITING_REVIEW_R4_2026-11-09.csv` (284 rows).

## Executive summary

| | |
|---|---|
| Scope | `questions` (5 room pools and 2,539 Stage Questions), `visitor_questions` (423), `visit_questions` (30), `visit_answers` (216), `trade_questions` (20), `lobbyist_lines` (20), `reaction_lines` (15) |
| Read in full | All 378 room-pool questions; all 423 visitor question texts; 160 random visitor questions with all four choices, replies, reactions and promise texts, plus about 80 more from sweep hits; all 53 Stage Questions in generic rooms (ST01-ST23) and the 171 shared with them; 300 random Stage Questions; every visit, trade, lobbyist and reaction line |
| Biggest problems | (1) **C2 in generic rooms**: the Media Ambush, Policy Study and Lobbyist pools and the generic committee and Floor Debate Stage Questions say "this bill" in rooms with no bill. (2) **C9 in the November casework**: about 20 Office Hours choices where the visitor's reply says "That would help" or "Good idea" but the column costs -3 to -5. (3) **C4 replies that answer a different choice** (VQ46, VQ59, VQ97, VQ305, VQ330) and British terms (lift, pram, rota, taxi rank, nursery, childcare "places") |
| Sweep candidates | 132 for R4; about 25 confirmed. The 54 "turn"/"Turns away" hits, the "finally"/"at last" hits in visitor replies and Stage Questions, "stage" in "a first stage", and "level the field" are ordinary English and true in context |

## Counts by code

| Code | Rows | High | What it mostly is |
|---|---|---|---|
| C2 Unanchored | 57 | 15 | "this bill", "this", "it" in generic rooms (press, lobbyist, policy study, media ambush, generic committees, Floor Debate, Party Caucus) |
| C3 Assumed history | 12 | 1 | Ambush accusations stated as fact; "Your last answer had no numbers"; trade and visit lines that claim a record |
| C4 Wrong speaker or listener | 14 | 3 | Replies that answer a different choice; candidate-selection questions in every Party Caucus; "your aides" or "my staff" with no staff |
| C5 Machinery | 1 | 0 | "raise party support" spoken by the Steering Committee |
| C6 Off-term | 4 | 0 | "rectors" for university president; "yen" written out in two visitor questions |
| C7 Not American | 44 | 17 | lift(s), pram, pavements, shopfront(s), rota, taxi rank, councillors, nursery, childminder, onside, "the head", childcare "places", "agree something", "Tuts", "Ticks" |
| C8 Grammar and style | 105 | 8 | 70 missing serial commas (mostly from bill phrases); garbled replies; frame "Who bears the cost: {cost}?" |
| C9 Lopsided or dishonest choice | 42 | 6 | Positive reply on a -3 to -5 choice; "Say ..." stage-direction choices beside one spoken plan |
| C10 Repetition | 5 | 1 | Bill-visitor template repeated across 11 visitors; near-copy visit answers |
| C1, C11, C12 | 0 | | None confirmed (see notes) |

## Defect rate by file (from sampling)

| File | Sample | Rate (95% range) | Notes |
|---|---|---|---|
| Room pools (`questions`, 5 pools) | all 378 read | C2 28/378 = 7.4%; C3 4; C4 1 | C2 is in the Media Ambush (11/33), Policy Study (9/60), Lobbyist (3/107), Press (4/34), Town Hall (1/144) pools |
| Stage Questions, generic rooms | all 224 read | C2 29/224 = 12.9% | committee "accountability" set S70-S97, Floor Debate S223-S252, caucus S253-S282 |
| Stage Questions, bill rooms | 300 random | C1-C4: 1/300 = 0.3% (0-1.0%); C8: 16/300 = 5.3% (2.8-7.9%) | Bill rooms are anchored by the room name; defects are frame grammar and serial commas |
| `visitor_questions` | 160 random questions | any finding 36/160 = 22.5%; C9 14/160 = 8.8% (4.4-13.1%); C4 5/160 = 3.1% (0.4-5.8%); C7 9/160 = 5.6%; C8 12/160 = 7.5%; C1/C3 0/160 (0-2.3%) | C9 and C4 cluster in the 2026-11-08 casework batch (VQ222+) |
| `visit_answers` | all 216 | 11 rows (C10 4, C3 2, C8 4, C7 1) | |
| `visit_questions`, `trade_questions` | all 50 | 4 rows | |
| `lobbyist_lines`, `reaction_lines` | all 35 | 0 | Clean |

`response_right`, `response_wrong`, `reaction_right` and `reaction_wrong` in `visitor_questions` are never shown (every question has per-choice replies, `OfficeHoursEngine.gd` lines 126-131 only fall back to them when blank), so I did not review them. They hold some British words (licence, rota, shopfront); a candidate for `CLEANUP_CANDIDATES.md`.

## The ten worst findings

| # | Row | Problem | Proposed |
|---|---|---|---|
| 1 | Media Ambush A04, A07, A11, A12, A17, A32 | "this bill" in ST19, which levels LV02, LV05, LV07, LV08 and others use with no bill | "your bills" / "your own bill" |
| 2 | Policy Study B01-B05, B09 | "How will this be implemented", "the bill", in ST21 with no bill | "your proposal" |
| 3 | VQ46 C | "Better transport between the towns." gets "Everything is fine? Then why do I keep coming here?" and -3 | Choice: "Honestly, the district is fine as it is." |
| 4 | VQ59 C | "Not yet; things are tight this month." gets "Optional? The roof does not agree." | "Tight for everyone. The roof still leaks." |
| 5 | VQ97 C, VQ305 D, VQ330 C | The reply answers another choice | New replies that answer the choice |
| 6 | VQ201 D, VQ335 C, VQ373 D, VQ376 D | Reply says "That is fair" / "That would help" / "Good idea", column gives -4 or -5 | Replies that match the cost |
| 7 | S225 "Which part of this bill is not negotiable?" (ST02 only) | Floor Debate with no bill | "your proposal" |
| 8 | S287 "Your last answer had no numbers." | False after a Data Driven play | "Give us one number that backs your last answer." |
| 9 | VQ311 C "Say I should have chosen day shifts." and VQ283 C "Tell me chain stores..." | Wrong person; and the "Say ..." form marks the dismissive choices | Direct speech for all "Say ..." choices (8 questions) |
| 10 | T84 prams, T100 lift, VQ299 taxi rank (4 fields), VQ228 rota, S2025-S2031 lifts | British terms | strollers, elevator, taxi stand, roster, elevators |

## Frames to fix (for the applier)

| Frame | Script | Rows | Fix |
|---|---|---|---|
| "Who bears the cost: {cost}?" | `tools/workbook/archive/b8/clone_questions.py` line 52 | S601, S703, S752, S792 | "Will {cost} bear the cost?" |
| "Who bears the cost of {what} in this town?" | same, line 35 | S681, S723 | "Who in this town bears the cost of {what}?" |
| Bill phrases with lists ("Sapporo, Tomakomai and Hakodate", "Korea, Taiwan and Southeast Asia", "Hokkaido, Aomori and Chishima", "dairy, wine, machinery and cars", "ports, water and defense sites", "farming, fishing, construction and tourism") | bill phrase source (R6's files) feeding `clone_questions.py` | about 30 Stage Questions | Add the serial comma at the source and re-run, rather than row by row |
| Bill-visitor template (VQ135-VQ156) | `tools/workbook/archive/batch9_bill_stages_2026-10-18.py` lines 201-211 (since hand-edited) | 22 questions, 11 identical sets | Per-bill replies |
| Candidate-selection questions | `tools/workbook/archive/batch5b_party_body_content_2026-10-18.py` | S573-S582 | Re-scope (question 2) or reword for a caucus |

## Notes on false alarms (sweep hits marked true in context)

- C1 "finally", "at last", "for the first time" in visitor replies and Stage Questions (VQ03, VQ12, VQ31, VQ96, VQ160, VQ229, VQ246, VQ310, VQ343, VQ357; S1117, S1165, S1193, S1197, S1293, S1445, S1589, S1693, S1805, S1869; MA161): each is about the speaker's own wait, true every time the line appears.
- C3 VQ401 "last week" and LL11 "the last reform" are the speaker's own history, not the player's. LL10 is fine.
- C6 "turn(s)", "stage" (MA102, MA107, S1395 "a stage for grandstanding"), "level" (VQ76, VQ214, S2230, S2383), "points", "card" (identity card, stamp card), "standing" (a standing commission), "yen" as currency (L22, B54, S137): ordinary English.
- C7 "surgery" (VQ97, S985) is medical; "realistic" is not "realise"; "tax holiday" and "lifts" for ski lifts (VQ237) are American too; car park, queue, timetable, flat are accepted words. "backbench(er)" (S260, VQ94) is a parliamentary term kept under section 3b.
- C2 T96 "They are building towers" is the natural unspecified "they"; T38 "carry the bill" is an idiom.

## Questions for Cameron

1. **Room pools that name policy areas.** `CONTENT_GUIDE.md` section 6 says room-pool questions "must name no specific policy area", but Press Q21-Q34, Town Hall T24-T144 (about 110), Lobbyist L21-L108 and Policy Study B21-B60 do (Ainu rights, nuclear principles, fares, care, crafts). They are dealt in every room of that kind, so "Should imported seafood face tougher labeling rules?" can come up in "Policy Study on Rail Timetables". Options: (a) leave them, the rooms feel lively; (b) move each to Stage Questions for the generic room only (ST04, ST05, ST20, ST21); (c) tag them with a Theme the room must match (needs code). I recommend (b). I did not log these as rows.
2. **S573-S582** were written for the candidate selection committee (party body BO32) but are listed for every Party Caucus (ST03 and all 50 bill caucuses). Should they move to a candidate-selection room, or be reworded for a caucus as drafted in the ledger?
3. **Town Hall T32 (aliens) and T33 (children's noise)** read as deliberate comic cranks. They can appear in serious bill town halls (Rural Hospitals, Ainu Heritage). Keep, or limit them to the generic Town Hall (ST05)?
4. **The "Say ..." choices** (VQ283, VQ288, VQ303, VQ311, VQ330, VQ331, VQ366, VQ393). Rewriting them as speech changes how the dismissive options feel; the effects stay as they are. Is that what you want, or is the stage-direction style deliberate?
5. **C9 replies vs columns** (about 20 rows). I changed the reply text to match the cost, as the data rules say. In several (VQ355 D "Hire more teachers", VQ289 D donated playground, VQ309 D coffee cart) the choice itself is a sincere idea; you may prefer to change the column instead, which is your call, not mine.
6. **Ambush accusations** (A23-A26, A28, A30) are a reporter's charges; ambush reporters do level unproven charges. Rewording them as questions softens the room. Keep the accusing tone (and accept that they can be false) or reword?
7. **Sapporo as the capital.** LL03 "Do not decide for us from Sapporo" and S1725 "waiting on Sapporo" treat Sapporo as the seat of national government; VQ06 says "the capital". Is Sapporo Yezo's capital in canon?
8. **T27** "When will Parliament restore long-term working visas..." assumes such visas once existed and were removed. True in Yezo's history?
9. **VQ229 C and VQ405 D** ("Then who is left to elect you?", "She voted for you") assume Imabetsu and Hirosaki are in the player's district, though the casework places were kept out of it. Fine as loose talk, or reword (VQ405 is in the ledger)?
10. **Bill-visitor template (VQ135-VQ156).** Eleven visitors use word-for-word identical choices and replies. Write per-bill replies (I can draft 44), or keep the template?
11. **Money in speech.** VQ223 and VQ260 write "a hundred and twenty thousand yen" in words. The standard says 120,000円; in a visitor's spoken line the words may read more naturally. Which do you prefer?
