# Strategy playtest: 168 bot runs aimed at Funds, Election Strength and Party support (2026-11-02)

Full tables: `design/bench/strategy_report_2026-11-02.md`. Raw runs: `design/bench/strategy_*.jsonl`.
Rerun: `tools/strategy_runs.sh OUT.jsonl "1 2 3" PC02 all`, then `python3 tools/strategy_report.py OUT.jsonl`.

## Executive summary

| Finding | Evidence | Why it matters |
|---|---|---|
| **Funds cannot be saved or used as a goal** | Funds cap is 100,000; Funds in hand ended at about 0 in 115 of 120 runs; the best "hoarder" ended at 15,714 | War-chest points in Election Strength (target 500,000) can never exceed about 2 of 10; "maximize Funds" has no meaning under the cap |
| **Party dues are unpayable at high Party support** | At Party support 60+ weekly dues are 197k-337k; Funds on hand at week end are at most 100k. Dues owed reached about 6.4M by week 30 (4 of 120 runs ended clear) | Every successful player is permanently overdue |
| **Paying dues earns nothing** | `dues_first` paid 3.0M in dues; `baseline` paid about 0.3M. Same Election Strength (40.8 vs 40.4), same Party support (90 vs 90) | Unpaid dues cost only Party support 10 a week, which stage wins refill. Paying means fewer items, a lower win rate, and in PC01's runs a collapse (Party 30, win rate 53%) |
| **Election Strength plateaus near 42 of 100** | Constituency 12/15, Experience 10/10, Organizations 7/15, Record 5/10, Party 4.5/10 (halved by overdue dues), Awareness 0/30, War chest 0/10 | Nearly half the points are unreachable for a normal player |
| **Gaffes silently zero out awareness** | A gaffe left on the meter at stage end costs 1 District and 1 National awareness. The bot ends stages with about 40 gaffes a week. Gaffe-averse play raised Election Strength from about 41 to 55-61 (best single run 75) | A strong, hidden lever. Players are never told it is the reason awareness stays at 0 |
| **Best strategy: "campaigner"** | Gaffe-averse cards, election-first level choice, buy events, play weekends: Election Strength 60.9, Party 90, stage win rate 88% | Everything else scored 0.43-0.44 on the three-goal score; campaigner scored 0.50 |
| **Party support has a death spiral** | 6 of 117 runs ended at Party 0-9. Week 1 overdue dues cost 10 Party support, leaving 0; Funds from stages are then frozen, so dues can never be paid | About 5% of careless starts are unrecoverable. A new player who buys items early is exposed |
| **Items are mandatory** | `no_items`: win rate 76% vs 86.5%, Party 60 vs 90, Funds earned 2.7M vs 9.0M | Funds convert to wins through items; the Funds cap forces spending anyway |

## Strategy leaderboard (three-goal score; Funds/100k + Election Strength/100 + Party/100, averaged)

| Rank | Strategy | Score | Election Strength | Party | Stage win rate |
|---|---|---|---|---|---|
| 1 | campaigner | 0.503 | 60.9 | 90 | 87.5% |
| 2 | events_buy | 0.441 | 42.2 | 90 | 87.4% |
| 3 | weekend_warrior | 0.440 | 42.1 | 90 | |
| 4 | balanced_adaptive | 0.439 | 41.6 | 90 | 85.9% |
| 5 | baseline | 0.435 | 40.4 | 90 | 86.5% |
| Worst non-random | hoarder | 0.290 | 32.7 | 39 | 64.4% |
| | data_deck | 0.308 | 32.5 | 60 | 70.2% |
| | low_tier_grind | 0.303 | 30.9 | 60 | 77.3% |
| | promise_keeper | 0.314 | 31.8 | 62 | |

## Card play

| Finding | Detail |
|---|---|
| Suit decks barely matter | Appeal, Earnest, Divisive, Duplicitous, Guard and Cheap decks all land within about 1 Election Strength point of baseline. Duplicitous has the best stage win rate (91%). |
| Data Driven deck is a trap | Election Strength 32.5, Party 60, win rate 70%; one of three seeds collapsed |
| Reckless gaffe play fails | Win rate 74% and Party 60 vs the baseline's 86.5% and 90 |
| Cheap cards dominate | C14 Document Request is 7.6% of all plays. All six cost-3 cards are under 0.3% each. |
| 17 of 70 cards were never played | Examples: C04, C55, C57, C59, C61, C63, C65, C67 (list in the full report) |
| Appeal and Earnest are overplayed | They hold 9 cards each yet make up 25% and 23% of plays; Divisive (13 cards) is 8% |

## Level choice

| Finding | Detail |
|---|---|
| Best Funds per hour | LV89 (17,277), LV02 (13,926), LV85 (13,813), LV03 (12,435) |
| Best Party support per hour | LV84 (2.45, but pays no Funds), then LV91, LV01 |
| Best awareness plus Constituency per hour | LV01 (3.26), LV93, LV92 |
| Tiers | Tier 0 pays about as much per hour as tiers 1 and 2 (5,423 vs 5,178 vs 4,524 Funds/hour) and wins 86% everywhere. Higher tiers are no better to play. |
| Weak levels | LV84, LV92, LV87, LV93, LV94, LV95 pay almost no Funds |
| Level-choice strategy | Adaptive money, party and election level choice made little difference to baseline; the weekly hour budget is the limit |

## Other trends

| Finding | Detail |
|---|---|
| Media Ambush is never won | ST19, ST30, ST194, ST203: 0% across about 2,700 fights (player starts 5, needs 30; hand 3, gaffe limit 2, 11 turns) |
| Hard committees | Committee on Finance (ST16) 28%; Party Steering Committee (ST08) 29% |
| Events | Random events give about +1 awareness each; buying events raised Election Strength by only 1.8. Awareness stays at 0 unless gaffes are controlled, so events help far more for a careful player |
| Promises | Keeping every promise did not help: two of three seeds matched baseline (Election Strength 38-40) and one collapsed to Party 9. Breaking them cost nothing measurable (Election Strength 40.7, Party 90) |
| Patron bills | Taking patron bills cost about 1M Funds earned (7 standard deviations) for no Election Strength gain; 1 of 38 accepted passed in the first baseline |
| Protagonists | PC01 and PC02 behave the same under baseline. PC01 with `dues_first` collapsed (Party 30, win rate 53%) |

## Recommendations (options for Cameron; nothing here has been changed in the game)

| # | Issue | Options | My pick |
|---|---|---|---|
| 1 | Dues exceed the Funds cap | (a) Cap dues at the Funds cap; (b) let dues be paid mid-week; (c) raise the cap | (a): cap weekly dues at 80% of the Funds cap |
| 2 | Overdue dues have no bite | Make unpaid dues cost Reputation or block one backing per week, so paying matters | Needs your call |
| 3 | War chest can never fill | Lower `election_war_chest_target` to about 100,000, or raise the cap | Lower the target to 100,000 |
| 4 | Gaffes hide the awareness lever | Show "gaffes left cost awareness" on the outcome panel | Add one line on the outcome panel |
| 5 | Party 0 death spiral | Allow one free grace week, or unfreeze Funds when Party support is 0 and dues are owed | Grace week |
| 6 | Media Ambush 0% | Confirm it is meant to be a loss; if not, retune start or energy | Ask |
| 7 | Cost-3 cards and 17 unplayed cards | Cost-3 cards need a stronger payoff or a cheaper cost | Review the list |
| 8 | Data Driven deck | Check why it underperforms | Review |

## What the bot does and does not cover

| Covered | Not covered |
|---|---|
| Real fights, rooms, floor votes, patron bills, visitor costs and promises, events, weekend levels, items, backing, staff, dues | Hosted events, district activities, event-started levels, office commission items, cosmetics, Floor Vote choice (always the party line) |

All numbers are from 3 seeds per strategy on PC02 (PC01, PC03 and PC04 on four strategies), 30 game weeks each. Small differences under about 1.5 points are noise.
