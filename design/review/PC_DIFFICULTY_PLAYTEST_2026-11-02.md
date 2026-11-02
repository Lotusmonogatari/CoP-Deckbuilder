# Four protagonists, three difficulties: 144 bot runs (2026-11-02)

Full tables: `design/bench/pc_difficulty_report_2026-11-02.md`. Raw runs: `design/bench/pc_difficulty.jsonl`.
Setup: PC01-PC04 x Relaxed/Standard/Harder x three strategies (baseline spends everything; cap_dues buys the Funds cap and reserves dues; campaigner_cap plays carefully with events and weekends) x 4 seeds, 30 game weeks each. No bug or stall was logged.

## Executive summary

| # | Finding | Evidence |
|---|---|---|
| 1 | **Election Strength is now a speed limit, not a skill score** | 104 of 144 runs end exactly on weekly gain x 30 weeks: Relaxed 90, Standard 75, Harder 60. The potential (about 76 to 78) is above the stock all game, so only the gain-per-week lever matters |
| 2 | **Careful play no longer pays** | At Standard the careless baseline reaches Election Strength 75; campaigner_cap reaches 67-71 with a lower win rate (71-80% vs 87-94%) and lower Party support. The new cumulative gaffe rule removed the reason to play carefully |
| 3 | **Awareness is saturated** | District and National sit at 90-100 on every tier, so the Harder 150% gaffe lever does almost nothing |
| 4 | **The dues holiday only delays the Party-0 spiral** | All 5 Standard collapses were campaigner_cap, and Party support falls to 0 in weeks 4-5, just after the 3-week holiday ends. On Harder (no holiday) collapses start in weeks 1-3 |
| 5 | **Harder hits the weaker starts harder** | Win rate vs Standard: PC01 -4, PC02 -2, PC03 -9, PC04 -9 points. Party support at week 10 on Harder: PC01 74, PC02 54, PC03 34, PC04 37 |
| 6 | **Some rooms fall off a cliff on Harder** | Committee on Finance (ST16) 31% to 8%; Finance: Hokkaido Shinkansen (ST137) 72% to 42%; Construction (ST15) 42% to 25%; Lobbyist (ST20) 68% to 59% |
| 7 | **Relaxed is a much richer game, not just an easier one** | 66-67 of 70 cards owned by week 30 (Standard 50-54, Harder 40-45); 50 backings (Standard 37-42); Funds earned +15% to +41% |
| 8 | **Dues are overdue most of the game on every tier** | Mean weeks overdue of 30: Relaxed 12-18, Standard 18-20, Harder 20-26 |
| 9 | **Protagonist differences wash out** | By week 30 the four starts are within 3 Election Strength points on every tier; the gap shows in the first 10 weeks only |
| 10 | **Card mix does not move with difficulty** | Appeal 27-28% and Earnest 21-25% of plays on every tier; Divisive and Duplicitous 7-10% |

## Win rate, Election Strength and Party support (mean of all strategies and seeds)

| Protagonist | Win: Relaxed / Standard / Harder | Election Strength | Party support | Collapsed runs (of 12 per tier; Relaxed / Standard / Harder) |
|---|---|---|---|---|
| PC01 | 88% / 80% / 77% | 85.7 / 70.8 / 58.7 | 97 / 88 / 87 | 0 / 1 / 1 |
| PC02 | 89% / 79% / 78% | 86.2 / 70.5 / 58.5 | 97 / 78 / 87 | 0 / 2 / 1 |
| PC03 | 91% / 84% / 76% | 86.5 / 73.3 / 56.9 | 97 / 88 / 72 | 0 / 1 / 3 |
| PC04 | 90% / 84% / 76% | 84.4 / 73.1 / 58.4 | 97 / 87 / 78 | 0 / 1 / 2 |

## Early game (Party support / Funds, mean of all strategies)

| Protagonist | Tier | Week 2 | Week 5 | Week 10 |
|---|---|---|---|---|
| PC01 | Standard / Harder | 86 / 68k and 52 / 2k | 75 and 50 | 70 and 74 |
| PC02 | Standard / Harder | 49 / 69k and 28 / 9k | 53 and 36 | 54 and 54 |
| PC03 | Standard / Harder | 52 / 68k and 24 / 5k | 57 and 26 | 70 and 34 |
| PC04 | Standard / Harder | 36 / 89k and 14 / 13k | 58 and 19 | 73 and 37 |

## Patterns worth knowing

| Pattern | Reading |
|---|---|
| The tiers differ mostly through the weekly gain rate, dues share and the win-rate nudge, not through awareness | Harder is felt as slower progress and a poorer start, not as tougher fights, except in a few committees |
| Spend-everything is not punished by the tiers | The baseline bot ties or beats the careful bot on Election Strength on all three tiers |
| The first 4 weeks decide a Harder run | Every Harder collapse starts in weeks 1-3, before any dues can be paid from a standing start |

## Options for Cameron (nothing has been changed)

| # | Issue | Options |
|---|---|---|
| 1 | Election Strength is time-gated | (a) Leave: it is a long-game clock; (b) raise the weekly gain on all tiers so skill matters; (c) let the potential, not the clock, decide by lowering the war-chest target or raising the gain |
| 2 | Careful play no longer helps | (a) Accept; (b) tighten the gaffe thresholds (65 / 35) so awareness is not always full; (c) give careful play its own reward |
| 3 | Dues holiday ends in a cliff | (a) Phase dues in over weeks 4-6; (b) a one-week grace before penalties; (c) leave |
| 4 | Harder is too sharp for PC03 and PC04 | (a) Give Harder a 1-week holiday; (b) scale the fight-margin lever by protagonist; (c) leave, since those starts are already Hard and Very Hard |
| 5 | Cliff rooms on Harder (ST16, ST137, ST15) | (a) Apply the +6 margin as a percentage of the threshold; (b) cap it at +3 in committees; (c) leave |
| 6 | Awareness lever is inert | Fold lever 3 into the gaffe thresholds, or drop it from the tiers |
