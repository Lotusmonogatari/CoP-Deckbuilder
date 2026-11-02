# Strategy playtest: 168 bot runs aimed at Funds, Election Strength and Party support (2026-11-02)

Full tables: `design/bench/strategy_report_2026-11-02.md`. Raw runs: `design/bench/strategy_*.jsonl`.
Rerun: `tools/strategy_runs.sh OUT.jsonl "1 2 3" PC02 all`, then `python3 tools/strategy_report.py OUT.jsonl`.

## Executive summary

| Finding | Evidence | Why it matters |
|---|---|---|
| **Correction: the bots never bought the Funds-cap petition (SH13)** | The Funds cap starts at 100,000 and SH13 raises it by 100,000 for 100 XP, up to 1,000,000. Neither bot bought it, so the first-batch findings on Funds and dues describe a player who never raises the cap | See the addendum: with the cap raised and dues reserved, dues are payable |
| Funds stayed near 0 in the first batch | The bots spend everything on items (buffer 5,000) and the cap stayed at 100,000 | War-chest points (target 500,000) were unreachable for these bots |
| Dues were unpayable at Party support 60+ at the 100,000 cap | Weekly dues 197k-337k vs at most 100k in hand at week end | True only without cap purchases |
| Paying dues earned nothing at the default cap | `dues_first`: 3.0M paid, same Election Strength (40.8 vs 40.4) and Party support (90) as baseline | See the addendum: with the cap raised, paying keeps Party at 100 |
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

## Addendum (same day): the cap, gaffe rules and lighter dues

Three seeds each, PC02, 30 weeks. "Simulated" means the bot applied a proposed rule to itself; no game rule has changed.

### 1. The Funds-cap petition (SH13)

| Strategy | Election Str. | Awareness (District / National) | Party | Funds kept | Dues owed at end | Weeks overdue (of 30) | Stage win rate |
|---|---|---|---|---|---|---|---|
| baseline (never buys it) | 40.4 | 0 / 1 | 90 | 0 | 8.1M | 29 | 87% |
| cap only (still spends everything) | 31.4 | 0 / 1 | 60 (one run collapsed) | 0 | 6.9M | 29 | 74% |
| cap plus dues reserve | 47.0 | 0 / 0 | 100 | 67,508 | 0 | 9 | 78% |
| campaigner (careful cards, events, weekends) | 60.9 | 43 / 66 | 90 | 0 | 5.8M | 29 | 88% |
| **campaigner plus cap** | **74.6** | **100 / 99** | 90 | 0 | 2.3M | 29 | 88% |

Buying the cap alone does nothing for a bot that still spends every yen. It works when Funds are held for dues. Nine purchases (900 XP) reach the 1,000,000 ceiling.

### 2. Awareness penalty for leftover gaffes (simulated)

Each stage win gives about +1 awareness, so any penalty of one point a stage cancels it for a player who ends stages with gaffes on the meter.

| Rule | Election Str. | Awareness (D / N) | Party | Win rate | Reading |
|---|---|---|---|---|---|
| Today: 1 per leftover gaffe | 40.4 | 0 / 1 | 90 | 87% | Careful players reach 55-61 |
| First 3 leftover gaffes free | 40.2 | 0 / 4 | 89 | 81% | No change |
| 1 per 5 leftover gaffes | 41.6 | 2 / 4 | 90 | 85% | No change |
| 1 per 5, at most 3 a stage | 40.6 | 1 / 2 | 90 | 85% | No change |
| At most 2 a stage | 37.5 | 0 / 0 | 77 | 77% | No change (noise) |
| 1 per 100 gaffes in total | 73.7 | 99 / 100 | 90 | 82% | Awareness maxed by week 30 |
| No penalty | 75.0 | 100 / 100 | 90 | 86% | Awareness maxed |

Gentle per-stage softening changes nothing, because the gain per stage is also about 1. Only a total-count rule such as your 100-gaffe idea removes the pressure, and it pushes awareness to its ceiling. If you want awareness to stay a skill lever, keep the rule and show it to the player. If you want it easy, use the per-100 rule.

### 3. Lighter dues (the cap is bought and Funds are reserved in every row)

| Rule | Election Str. | Party | Funds kept | Dues owed at end | Weeks overdue | Dues paid in 30 weeks | Win rate |
|---|---|---|---|---|---|---|---|
| Today (base 50k, step 50k, 30% of earnings) | 47.0 | 100 | 67,508 | 0 | 9.3 | 8.7M | 78% |
| Earnings share 15% | 46.7 | 100 | 71,115 | 0 | 5.3 | 7.0M | 78% |
| Step 25k, share 20% | 45.8 | 99 | 52,089 | 0 | 8.0 | 5.6M | 76% |
| Base 25k, step 10k | 45.9 | 99 | 44,338 | 0 | 1.0 | 4.4M | 76% |

Once the cap is raised, even today's dues are payable for a careful bot, and the lighter structures only change how many weeks run late. A grace period or arrears forgiveness needs code, so it was not simulated.

### Updated recommendations

| # | Issue | Pick |
|---|---|---|
| 1 | Players may never learn that SH13 exists, and the spend-everything habit hides it | Point the dues box and the Marketplace at SH13 when dues are overdue |
| 2 | Awareness | Keep the per-stage rule and show it on the outcome panel; use per-100 if you want it easy |
| 3 | Dues | A 3-week no-dues start for new runs (removes the Party 0 spiral); optionally 1 week of grace before penalties; lighten the earnings share to 15% |
| 4 | The earlier "cap dues at the Funds cap" idea | Withdrawn; the cap is already adjustable by the player |
