# Writing review R5 (Scenes): summary, 2026-11-09

Draft by Claude (reviewer R5) for Cameron. Ledger: `design/review/WRITING_REVIEW_R5_2026-11-09.csv` (740 rows, one per field changed; nothing has been applied). Scope: `transition_dialogue` (2,461 rows), `level_intros` (250), `levels` purpose lines (113), `vote_influence_cues` (100).

## Executive summary

| | |
|---|---|
| Biggest true-in-context problem | 21 staff lines are written in the staff member's own backstory (fishers, Ainu elders, shop owners, temple groups) but are **wildcard**: they play before every room, including committees and the Floor Vote. "There is a temple group and a shrine group in the room" is false almost everywhere. |
| Canon risk | TD2161 "I covered the Kushiro recall" reads as a recall election, which Yezo does not have (the staff bio says *food* recall). |
| Machinery | The Speaker says "I will count every card the same" before the Floor Vote; "Stay above the line" (TV debate thought and LV91 purpose) points at the threshold. |
| Most rows | Mechanical frame fixes: room topics capitalized mid-sentence ("questions on War"), "backs your lean", "Some wanted a yes", "Mayors' Network's members", and bill thoughts of 25 to 35 words (the limit is about 18). |
| Clean | No C1 or C3 defects in transitions: no line assumes the previous stage was won or lost. The opponents' transition lines never contradict their party's bill position (no opponent row carries a bill). |

## Counts by code

| Code | Rows | Of which in frames | Files |
|---|---|---|---|
| C1 once-only | 1 | 0 | levels (LV26 "A first try") |
| C2 unanchored | 37 | 35 (wildcard staff bio lines) | transition_dialogue |
| C3 assumed history | 1 | 0 | vote_influence_cues (BI41 says "withdrawn", it was voted down) |
| C4 wrong speaker / context | 5 | 0 | transition_dialogue 2, levels 3 (purpose hints at a hidden Media Ambush) |
| C5 machinery | 9 | 0 | transition_dialogue 8, levels 1 |
| C6 off-term | 102 | 100 | "your lean" (50), "a yes" (50), "Assembly Members" (1), "floor vote" for a floor debate (1) |
| C7 not American | 3 | 0 | "ring in", "carers", "waffle" |
| C8 grammar and style | 577 | about 540 | topic capitals (263), bill-thought length and "I owe ... a better answer" (100), stacked possessives (46), component length (71), party-room "They" (31), "stand carefully" pun (20), serial commas (31), others |
| C10 echo | 1 | 0 | TD297 / TD251 |
| C11 tone | 4 | 0 | LV47/LV59 "cost and fairness"; BI03/BI04 narrator states one side's view as fact |
| C9, C12 | 0 | | none in scope |

Confidence: 58 high, 533 medium, 149 low.

## Sampling and coverage

| Set | Read | Defect rate (95% range) |
|---|---|---|
| Wildcard general rows (no stage, no bill; play before any room) | all 432 | C1-C4 6.7% (4.7-9.5%), almost all the staff bio lines; any code 8% |
| Generic rooms ST01-ST23 | all 127 | C1-C4 0.8% (0.1-4.3%); C8 15% (the committee topic frame) |
| Topic-room frame rows TD326-TD560 | all 235 | frame defects only (C8 capitals, C2 "She") |
| Random sample of the remaining 1,692 (topic and bill-room copies, bill rows, component rows) | 420 | C1-C4 0/420 (0-0.9%); C8 23.3% (19.5-27.6%); C6 6.9% (4.9-9.7%), all from the two bill frames |
| level_intros, purpose lines, vote_influence_cues | all | listed row by row |

Sweep candidates (32 for R5): confirmed in context: TD13 (and its 30 copies), TD250 (low), TD2237, TD611 and the 49 other "a yes" rows, and LV101 (grammar only); false alarms with reasons: TD274 "voice level", TD309-TD325 "They are within reach" (antecedent is "every figure"), TD606-TD613/TD1489-1490/BI07 "Energy" (bill name), TD2099 "turn it over", TD2142 "after you do" (= after you remember names), TD2266/2267/2278 replies (antecedent present), TD2436 "last time" (a journalist's general habit, true anywhere), LV101 record (true in context; only the grammar is fixed). My own sweeps added: once-only and history words (none), time words, machinery words, single quotes, line and reply length, serial commas, British terms.

## The ten worst findings

| # | Row | Problem | Proposed |
|---|---|---|---|
| 1 | TD2197 (SF14, wildcard) | "There is a temple group and a shrine group in the room." said before any room | "If a temple group and a shrine group share a room, favor neither." |
| 2 | TD2205-TD2215 (SF17, wildcard) | Ten lines assume fishers, the co-op and the captain are present | Reworded as lessons from the docks ("On the boats, nobody trusted a promise without a number.") |
| 3 | TD2161 (SF11) | "the Kushiro recall" reads as a recall election | "the Kushiro food-recall scandal" |
| 4 | TD2270 (Speaker, Floor Vote) | "I will count every card the same." | "every ballot" |
| 5 | TD2255, TD2258, TD2262 (SF21) | "Buy something. They will talk more" before a committee | "At a shop, buy something. Owners talk more if you do." |
| 6 | Bill frame SF15 Oppose, 50 rows | "Some wanted a yes." (vote term) | "Some hoped you would back it." |
| 7 | Bill frame SF01 Support, 50 rows | "backs your lean" (internal word) | "backs your position" |
| 8 | Bill thoughts, 100 rows | 25-35 words; "I owe pensioners and the families who rely on elder care a better answer" | "If I oppose this bill, I must answer to pensioners and the families who rely on elder care." |
| 9 | LV26 purpose (repeats) | "A first try at coalition building" | "Practice in coalition building" |
| 10 | LV72 purpose | "voters wary of amendments are wary" | "voters who distrust amendments are wary" |

## Frames to fix (so regenerated rows stay fixed)

| Frame | Script | Fix |
|---|---|---|
| Topic-room staff lines `{t}` | `tools/workbook/archive/b6/content2.py` TOPIC_TRANS (and the per-bill copies of the committee rows) | Fill `{t}` in lowercase (keep proper nouns: China, Chishima, National Assembly); caucus reply "Then I will choose my words carefully." |
| Bill staff lines | `batch4_bill_content_2026-10-18.py` STAFF | "backs your position"; "Some hoped you would back it." |
| Bill thoughts | `b8/thoughts.py` | "{If/Since} I back this bill, I must answer for {risk}." and "... I oppose this bill, I must answer to {gain}." |
| Component thoughts and staff lines | `b11/component_frames.py` | "speak for the members of {the Org}"; "Research on a plan to {p} is thin."; "If we {p}, I must answer for every part of it." |
| Serial comma in gain/risk lists | `design/reference/bill_facets.json` | Add the serial comma at the source; it also feeds purpose lines, R3's and R6's text |

## Questions for Cameron

1. **Wildcard staff lines in backstory voice** (SF03-SF07, SF10-SF14, SF17-SF21). I reworded 35 to be true in any room. The alternative is to keep the vivid originals and give those rows a Stage ID (harbor rooms for Grant, Ainu and land rooms for Kanima, and so on). That changes a structured column, so it is your call. TD2215 ("I know most of them by their boats") only works that way.
2. **Kushiro "recall"** (TD2161): is "food-recall scandal" right, or another wording? (Canon says no recall elections.)
3. **Purpose lines that hint at a hidden Media Ambush** (LV02 "reporters will catch you on the way out", LV05 "an ambush or two", LV62 "handle the press"). Intro cues must not hint at a stage whose Reveal In Briefing is No. Should purpose lines follow the same rule? Low-confidence rewrites are in the ledger.
4. **Spoken vote words:** may a character say "a yes" in speech, or must spoken lines also avoid Yes/No? I proposed avoiding the vote word entirely.
5. **Name order:** the cues say "Prime Minister Rono" (Aki Rono, surname last) and "Speaker Namu" (Ichizaki Namu). Is Namu the surname?
6. **"Members of Parliament" as an organization** in component thoughts ("I wonder what Members of Parliament will say if we ...", TD1957, TD1966): it reads as if the player were not an MP. Reword to "my colleagues"?
7. **LV103** "compare it with the last candidate's": whose tour is meant? (Left unchanged.)
8. **BI03/BI04 vote cues** state one side's argument as fact; I made them "Members decided ...". OK?
9. **LV25** says "three committees" but the level has four (including the Committee of the Cabinet); left unchanged pending your count rule.
10. **Out of my scope, for R1:** SF14's biography has "after the a recent earthquake"; SF09's has "it called" after a period.
