# P17 economy report (2026-11-24)

Branch `feature/p17-economy`. Brief: `P17_ECONOMY_PROMPT.md`. Every number below was recomputed from the data as it now stands.

## Executive summary

| | |
|---|---|
| The standard | 8,000円 and 20 XP per hour at standard difficulty, applied to 284 of 290 rooms and 122 levels. |
| Level pay (rooms + completion bonus) | **13,318,000円 and 34,593 XP** (brief expected about 14.4 million円 and 37,200 XP; before the pass 17.4 million円 and 43,600 XP). |
| Funds per hour, middle 80% of the 115 levels that pay Funds | **4,571 to 9,733円** (brief: about 5,000 to 11,000円). |
| Why it is lower than the brief's estimate | The fresh sweep moved several room types to easier bands than October's (below), and 13 non-combat levels keep a blank Funds bonus by the "no Funds where none are paid" rule. |
| Needs Cameron | The bands (they differ a lot from October); whether the relaxed (5%) and harder (20%) dues shares should move; the staff-wage rubric R4.4 (below). |

## Steps

| Step | What changed | Rows |
|---|---|---|
| 0. Check | Every "now" value in the brief matched the data except the loss-pay note (below). | |
| 1. Bands | `tools/balance_audit.sh`, `balance_audit.py`; starter-kit win rate averaged over each room type's stages; bands in the table below, saved in `design/bench/p17_bands.json`. | 21 combat room types |
| 2. Room pay | `tools/economy_apply.py` (Stages: Win ΔYen and Win ΔXP). 144 rooms paid more Funds, 130 less, 16 unchanged. Total Win Funds over all rooms 7,440,000円 to 6,847,000円; Win XP 18,375 to 17,492. | 284 of 290 stages |
| 3. Level bonus | Levels tab bonus ΔYen and ΔXP: tier 0 cleared (33 levels); tier 1 10% and tier 2 25% of the rooms (min = max): 89 levels get an XP bonus, 76 a Funds bonus. | 122 levels |
| 4. Dues and wages | Balance: Dues Reward Percent 15, Dues Step Amount 5,000, Staff Wage Percent 10, new Dues: Max Per Week 90,000. Code: `PartyDues`, `MetaRules` (`requested`), `GameState._record_meta_change`, the week-cost screen. | 3 changed + 1 new row |
| 5. Prices | Shop SH01 12,000円, SH02 and SH03 24,000円; SH42 grants BO14 +1 only; Events EV03, EV05, EV06, EV31, EV35 costs; EV04 choices A, B, C gains x4. | 4 + 5 + 3 rows |
| 6. Verify | New tests (`tests/test_economy_p17.gd`, 11); the briefing record's pay figures refreshed; tests that pinned old numbers updated; audit rerun (logs `design/bench/balance_p17_after`). | |

## Difficulty bands (starter-kit win rate, fresh sweep)

| Room type | Starter win rate | Stages measured | Band | Factor | October band | |
|---|---|---|---|---|---|---|
| Whipped into Line | 100% | 1 | Easy | 0.8 | (not in October's list) |  |
| TV Debate | 100% | 10 | Easy | 0.8 | Easy |  |
| Radio Debate | 99% | 1 | Easy | 0.8 | (not in October's list) |  |
| Policy Study | 98% | 7 | Easy | 0.8 | Easy |  |
| Policy Study Session | 96% | 7 | Easy | 0.8 | Easy |  |
| Radio Call-In Hour | 96% | 1 | Easy | 0.8 | (not in October's list) |  |
| Press Conference | 95% | 26 | Easy | 0.8 | Hard | moved |
| Committee of the Cabinet | 95% | 1 | Easy | 0.8 | Standard | moved |
| Media Ambush | 94% | 6 | Easy | 0.8 | Very hard | moved |
| Lobbyist Meeting | 93% | 13 | Easy | 0.8 | Hard | moved |
| Special Committee | 92% | 4 | Easy | 0.8 | Standard | moved |
| Hearing | 92% | 17 | Easy | 0.8 | Easy |  |
| Town Hall at the Harbor | 87% | 1 | Easy | 0.8 | (not in October's list) |  |
| Campus Q&A | 86% | 1 | Easy | 0.8 | (not in October's list) |  |
| Town Hall | 82% | 17 | Standard | 1.0 | Very hard | moved |
| Committee | 74% | 63 | Standard | 1.0 | Easy | moved |
| Floor Debate | 73% | 1 | Standard | 1.0 | Standard |  |
| Party Caucus | 36% | 51 | Hard | 1.25 | Very hard | moved |
| Party Steering Committee | 25% | 1 | Very hard | 1.5 | Very hard |  |
| Candidate Selection Committee | 21% | 1 | Very hard | 1.5 | (not in October's list) |  |
| Convince Your Colleague | 0% | 1 | Very hard | 1.5 | (not in October's list) |  |

Moved from October: Committee (Easy to Standard), Special Committee (Standard to Easy), Lobbyist Meeting (Hard to Easy), Press Conference (Hard to Easy), Town Hall (Very hard to Standard), Media Ambush (Very hard to Easy), Party Caucus (Very hard to Hard). Hearing, Policy Study, Policy Study Session and TV Debate stay Easy; Floor Debate stays Standard; Committee of the Cabinet moved Standard to Easy; Party Steering Committee stays Very hard. The starter-kit win rates are much higher than in the 2026-10-18 sweep (the bots and the starter deck have both changed since, e.g. Town Hall 82% now against 1%). Rooms that pay neither Funds nor XP (Floor Vote, Member Visit, Lobbyist Trade, Patron Visit, Convince Your Colleague, Whipped into Line) are unchanged whatever their band; the combat type not covered by the sweep gets 1.0 (none were).

Median room pay now (hours x rate x factor): Committee 32,000円 / 80 XP; Party Caucus 40,000円 / 100 XP; Office Hours 13,000円 / 32 XP; Press Conference 13,000円 / 32 XP; Town Hall 16,000円 / 40 XP; Lobbyist Meeting 13,000円 / 32 XP; Media Ambush 6,000円 / 16 XP. (The brief's expected figures assumed October's bands, so Committee, Press Conference, Town Hall, Lobbyist Meeting and Media Ambush differ.)

## Weekly dues and wage examples (new settings)

| Week | Dues | Wages | Share of the 260,000円 earned |
|---|---|---|---|
| Early: Party support 40, two 40,000円 hires | 89,000円 (50,000 + 15% of 260,000) | 8,000円 | 37% |
| Middle: Party support 70, three staff with 130,000円 each invested | 90,000円 (99,000 held at the limit) | 39,000円 | 50% |

With National awareness at 80 or more the 50,000円 relief comes off after the limit (the middle week would owe 40,000円).

## Text and description edits (drafts for Cameron)

| Where | Now |
|---|---|
| Shop SH42 description | "A paid seat on the express, used for a trip or a mixed level's travel instead of the rail pass. The hours are the same. The Commuter Committee notices when a member pays their own fare: +1 standing with it on every use." |
| Text `office.week_cost_limit` (new) | "The party never asks for more than {yen}円 in dues in a week." (shown on the week-cost screen only when the limit is holding the dues down) |
| Balance notes | Dues: Reward Percent, Dues: Step Amount, Staff Wage: Percent and the new Dues: Max Per Week carry a dated note. |
| EV04 `result_text` | No number is stated in any of the three results; none rewritten. |

No other Text row named the old 10%, the old step or the three organizations (`--accept-wording` showed only the one new row).

## Differences from the brief and open points

- **Loss pay.** The brief says loss pay is "0円 and 1 XP". The data has 0円 for most rooms with XP from 0 to 10, and 16 rooms that give back 1,000円 on a loss. Loss columns are untouched, as briefed.
- **Funds bonus where a level had none.** Step 3 says a level whose rooms pay no Funds keeps a blank Funds bonus; the "fixed by decision" rule is stronger (no Funds where none are paid). 13 non-combat levels (7 tier 1, 6 tier 2) have rooms that pay Funds but never had a Funds bonus, so they keep a blank Funds bonus. A first run gave them one; a test caught it and it was undone. This is the main reason the totals are below the brief's estimate.
- **Relaxed and harder dues.** Relaxed (5%) and harder (20%) no longer sat symmetrically around the new 15%. Cameron chose to move them: **Relaxed is now 10%, Harder stays 20%** (five either side of Standard).
- **Staff wage rubric.** Wages went from 15% to 10% (the 2026-11-16 change "so staff cost more than the Funds their tasks bring", rubric R4.4). `design/STAFF_ASSIGNMENTS_RUBRIC.md` may need R4.4 reviewed.
- **Shrine gifts count as earned.** The 150th-respect gift (100,000円) and the other Funds gifts go through the same path, so they add to that week's dues share; only weekday positive amounts count.
- **Generated bill levels** (Bill Level Templates tab) are not in the Levels tab and were not touched.
- **Bots.** The bots do not buy the Funds cap petition or use items well, so their Funds in section 7 of `design/BALANCE_AUDIT.md` are not evidence.

## Audit sections after the change

`design/BALANCE_AUDIT.md` was regenerated from the new logs (`design/bench/balance_p17_after`). Its section 5 (Stages) now shows Win XP on the new standard (for example Town Hall 40 XP, Party Steering Committee 120 XP) and its section 8 (Rewards and costs) the new prices: SH01 12,000円, SH02 and SH03 24,000円. One pass of every level now pays about 30,156 XP from stage wins (rooms only, without the completion bonuses).
