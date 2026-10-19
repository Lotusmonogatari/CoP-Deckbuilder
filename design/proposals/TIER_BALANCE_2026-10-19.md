# Balance evaluation: new content, patron levels and the three level tiers (2026-10-19)

## Executive summary

| Question | Answer |
|---|---|
| Does the new content (components, committee, caucus and topic questions) break any room? | **No.** The bot, with every card, the best deck, backing and items, wins 19 of 21 rooms 100% of the time. Nothing became unwinnable. |
| What changed for the better? | **ST08 Party Steering Committee** was 0% for the bot before the Stage Questions arrived and is now **100%**. |
| What is still extreme? | **ST19 Media Ambush** 0-15% (you chose to leave it), **ST20 Lobbyist Meeting** 85-95%, and **ST18 Cabinet** 100% (you chose to leave it). |
| Content numbers changed? | **None.** No room needs a content-side fix. The trials show the opposite problem: everything is easy for a fully equipped bot. |
| Biggest problem in the tiers? | **Bill levels do not pay more in higher tiers.** A Tier 2 bill level pays 278 XP; a Tier 0 bill level pays 300. Its unlock cost is 4x higher (200 vs 50 XP). Free-form levels do scale (346 / 398 / 560 XP). |
| Second problem | Tier 0 holds the hardest-feeling room kinds (TV Debate, Media Ambush) while Tier 2 holds many short, cheap bill levels (4-5 stages). Length and difficulty do not rise with tier for bill levels. |
| Recommendation | Scale **bill-level rewards by tier** (workbook edit, about 60 cells) and re-sort 8 levels (tables below). Nothing applied yet. |

## 1. Stage trials (bot upper bound, 20 fights, PC01 and PC04)

| Stage | Room | PC01 | PC04 | Notes |
|---|---|---|---|---|
| ST01, 09, 10, 11, 12, 13, 14, 15, 16, 17 | Committees | 100% | 100% | 5-19 turns, 17-92 cards: long but safe |
| ST18 | Cabinet committee | 100% | 100% | Decided earlier to leave as is. It pays 200 XP / 100,000円 for about 1-2 turns of play (25-29 cards). |
| ST02, ST03 | Floor Debate, Caucus | 100% | 100% | Short (2-6 turns) |
| ST04 | Press Conference | 100% | 100% | |
| ST05 | Town Hall | 100% | 100% | |
| ST06 | TV Debate | 100% | 100% | Rising threshold did not stop the bot |
| ST08 | Steering Committee | 100% | 100% | **Was 0%** before committee-style questions were added. Wins in about 3 cards. |
| ST21 | Policy Study | 100% | 100% | |
| ST20 | Lobbyist Meeting | 85% | 95% | The only room besides Media Ambush that is not a lock |
| ST19 | Media Ambush | 15% | 0% | Left alone by design (may be lost, does not end the level) |
| ST261 | Win Over a Member | n/a | n/a | The trial harness cannot start it (needs a visiting member). Earlier full-run logs show every visit fight won in 2-3 turns. |

Reading: the bot is an upper bound (all cards, best deck, backing, items). A person with a fresh deck will win far less often. The useful signal is the *shape*: the same rooms are hard for everyone (Media Ambush, Lobbyist), and no room is impossible.

**Adjustments incorporated: none.** I found no content that makes a room worse. The open balance items are the ones you already ruled on (Media Ambush, Cabinet), plus the tier rewards below, which are your design call.

## 2. Tier summary

| Tier | Kind | Levels | Stages | Combat stages | XP | Funds (000円) | Reputation | Constit. | Party | Difficulty index | Unlock XP | Cooldown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | free | 10 | 5.2 | 5.1 | 346 | 150 | 5.8 | 7.4 | 4.7 | 0.33 | 17.5 (many are 0) | 49 |
| 0 | bill | 6 | 5.7 | 4.3 | 300 | 134 | 7.2 | 6.7 | 7.7 | 0.46 | 50 | one-time |
| 1 | free | 12 | 6.0 | 5.4 | 398 | 195 | 11.3 | 10.8 | 10.3 | 0.36 | 150 | 56 |
| 1 | bill | 22 | 5.6 | 4.0 | 291 | 125 | 7.0 | 8.0 | 7.4 | 0.43 | 100 | one-time |
| 2 | free | 10 | 7.6 | 7.3 | 560 | 251 | 17.9 | 9.0 | 19.4 | 0.36 | 300 | 96 |
| 2 | bill | 22 | 5.5 | 3.9 | 278 | 118 | 6.6 | 7.2 | 7.6 | 0.43 | 200 | one-time |

Difficulty index = (threshold - player start) / (energy x turns x 2.4), averaged over combat stages. Higher is harder; ST08 is 1.2, ST04 0.81, most rooms 0.3-0.4. It is a crude static measure, not a win rate.

## 3. Findings

| # | Finding | Evidence | Severity |
|---|---|---|---|
| T1 | Bill levels do not reward more in higher tiers | 300 / 291 / 278 XP; 134 / 125 / 118 thousand 円 | High |
| T2 | A Tier 2 bill level is roughly XP-neutral: 278 XP earned against a 200 XP unlock | Unlock 50 / 100 / 200 XP | High |
| T3 | Bill levels get no longer or harder with tier | Stages 5.7 / 5.6 / 5.5, combat 4.3 / 4.0 / 3.9, difficulty 0.46 / 0.43 / 0.43 | Medium |
| T4 | Free levels do scale (stages 5 / 6 / 7.6, XP 346 / 398 / 560) | | Fine |
| T5 | Tier 0 free levels include the heaviest rooms | LV05-LV10 are 6-10 stages; LV10 has 10 stages and pays 665 XP, more than most Tier 1 levels | Medium |
| T6 | Some Tier 2 bill levels are the shortest, cheapest levels in the game | LV53 (4 stages, 180 XP, 50k), LV60 (190 XP), LV56/LV58 (205 XP) | Medium |
| T7 | The level list mixes a "free" and a "bill" ladder with different costs | Free T1 unlock 150 vs bill T1 unlock 100 | Low (looks intentional) |
| T8 | Several Tier 0 / Tier 1 bill levels are harder than Tier 2 ones | LV35 (0.62), LV72 (0.60), LV42 (0.57) vs LV55 (0.29), LV65 (0.28), LV79 (0.29) | Medium |

## 4. Suggested adjustments

### 4a. Rewards by tier (workbook, Levels and Stages rewards)

The stage win deltas add up to a level's reward, so the cleanest lever is a **per-tier multiplier on bill levels** applied by raising the level's own bonus-win columns (`Bonus Win Range` XP / Funds, which exist on the Levels tab) rather than editing 140 stage rows.

| Tier (bill levels) | Now (XP / Funds) | Suggested bonus on top | Result (XP / Funds) | Net XP after unlock |
|---|---|---|---|---|
| 0 | 300 / 134k | +0 | 300 / 134k | +250 |
| 1 | 291 / 125k | +100 XP, +40k | about 390 / 165k | +290 |
| 2 | 278 / 118k | +250 XP, +100k | about 530 / 218k | +330 |

This puts Tier 2 bill levels near the Tier 2 free levels (560 XP / 251k) and keeps the unlock cost meaningful. The numbers are a first draft; the workbook column names are exact in the Levels tab header notes.

### 4b. Resorting (difficulty and length against tier)

| Level | Now | Suggest | Why |
|---|---|---|---|
| LV35 Chishima Coastal Defense | T0 | T1 | Difficulty 0.62 is the highest of any bill level in Tier 0, only 4 stages and 170 XP |
| LV72 Constitutional Review | T1 | keep, raise reward | 0.60 but only 215 XP |
| LV42 Judicial Appointments | T1 | keep, raise reward | 0.57, 240 XP |
| LV55 Integrated Resort | T2 | **keep, the model** | 8 stages, 515 XP |
| LV65 Digital Identity Card | T2 | T1 | 0.28, 3 combat stages |
| LV79 Parental Leave | T2 | T1 | 0.29, 4 combat stages |
| LV53 Chishima Joint Economic Activity | T2 | T1 | 4 stages, 180 XP, 50k |
| LV60 Foreign Resident Suffrage | T2 | keep, add one stage | 4 stages, 190 XP, so a bill of this weight should be longer |
| LV82 Party Leadership Selection | T0 | keep | Tier 0 intro bill |
| LV10 Advancing a Bill to Protect Hometown | T0 | T1 | 10 stages, 665 XP, hardest Tier 0 level by reward |
| LV17 / LV18 / LV19 | T1 | keep | 9-10 stages, consistent with Tier 1's longest |

Effect of the moves (LV35, LV65, LV79, LV53, LV10): Tier 0 bill levels become easier on average, Tier 2 keeps only bills that are longer or harder, and the ladder reads as intended: harder and richer as you climb.

### 4c. Stage mix (types and difficulty) per tier

| Tier | Now | Suggestion |
|---|---|---|
| 0 | Floor, Caucus, committees, Press, TV Debate, Media Ambush all appear | Move TV Debate out of Tier 0 free levels if wanted. **Media Ambush stays in Tier 0 (Cameron: it can be lost freely).** |
| 1 | Mix of everything, 5.4 combat stages | Fine; add one Lobbyist Meeting stage to bill levels that have none, since it is the one non-trivial room |
| 2 | Free levels are long (7.3 combat); bill levels are short (3.9) | Raise bill levels to 5 combat stages by adding a second committee or hearing stage on the 12 shortest |

### 4d. Left for your decision

| Item | Option |
|---|---|
| ST18 Cabinet overpays | **Done 2026-10-19: win XP cut 200 to 120** (Funds payout unchanged at 100,000円) |
| Media Ambush at 0-15% for the bot | Keep (you chose to leave it) |
| ST08 is now easy | Optionally raise its threshold; the static index (1.2) was never a real win rate |
| ST260-ST262 (patron stages) pay nothing and use 0 time | By design: the patron vote carries the reward. Worth reviewing once real play data exists. |

## 5. How this was measured

`PLAYTEST_STAGE_TRIAL="STxx:20"` for PC01 and PC04 (one run after another), plus a static pass over `data/levels.json` and `data/stages.json` for stage counts, rewards, unlock costs and the difficulty index above. All numbers are drafts for the designer to correct; nothing in the workbook or game data was changed by this evaluation.

## 6. Applied 2026-10-19 (Cameron: "proceed with recommendations"; 4d needs no action)

| Change | Detail |
|---|---|
| Bill-level bonus rewards | Levels tab "Bonus Win Range": Tier 1 bill levels XP 80-120 and 30,000-50,000円; Tier 2 bill levels XP 200-300 and 80,000-120,000円 (45 levels, rolled each win; averages match the table in 4a). Tier 0 unchanged. |
| Re-sorted | LV35, LV65, LV79, LV53 moved to Tier 1 (unlock costs copied from Tier 1 bill levels: 100 / 80 / 60 / 40 XP by assistant rank); LV10 moved to Tier 1 (unlock costs copied from Tier 1 free levels: 150 / 100 / 50 / 10). |
| Not applied | LV60 extra stage, shorter-Tier-2 fifth combat stage and the Lobbyist stage additions need new stage rows and room content (a content batch); TV Debate stays in Tier 0 (optional). Media Ambush stays in Tier 0. |
