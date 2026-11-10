# Phase 4: Balance

All numbers come from the real data files and from the project's own strategy bot (`tools/strategy_playtest.gd`), driven with real `GameState` rules. Nothing here is a model I invented: where I extrapolate I say so.

## Executive summary

| Question | Answer | Confidence |
|---|---|---|
| Can the bot beat the game? | Yes, easily. 92 to 99 % of stages won across 56 runs of 30 weeks; no stalls | Medium: bots play better than casual humans in some ways and worse in others (see "What the bots cannot tell us") |
| Is difficulty climbing over levels? | Hardly. Win rate is 88 to 100 % for almost every stage type; the hard ones are a few Party Caucus and Steering Committee rooms (50 to 62 %) | Medium |
| Is money a pressure? | Only through party dues, and it is a cliff, not a curve: dues pass the Funds cap once Party support is about 55, so full payment is impossible without the cap petition | High (matches the earlier 2026-11-02 playtest) |
| Is XP scarce? | No. Runs earn 25,000 to 47,000 XP in 30 weeks; the one-time shop list costs 3,130 XP and all cards 635 XP | High |
| Do higher tiers pay more? | **No.** Per hour of play, Tier 0 pays more Funds and XP than Tier 1 or 2 | High |
| Is repeating a level punished? | **No.** 40 % of all level plays in the sims were the 10th or later play of the same level, at the same yield | High (for the bot) |

Scripts and raw output (all reproducible; run from the project folder):

| File | What it does |
|---|---|
| `audit/gameplay/analyze_sims.py` | Aggregates the 56 bot runs. Output: `audit/gameplay/sim/analysis_output.txt` |
| `audit/gameplay/balance_static.py` | Card power, required pace per stage, rewards and prices from `data/*.json`. Output: `audit/gameplay/sim/balance_static_output.txt` |
| `audit/gameplay/sim/strategy_runs.jsonl`, `strategy_cap.jsonl` | Raw runs: 40 (5 strategies x protagonists x seeds) and 16 (`cap_dues` and `baseline` x PC01 to PC04 x seeds 1, 2) |

How the runs were made: `tools/strategy_runs.sh` with `PLAYTEST_WEEKS=30`, difficulty `standard`, the real data and the real `GameState`. Strategies: `baseline`, `balanced_adaptive`, `hoarder`, `low_tier_grind`, `short_levels`, `cap_dues`. Sample size is small (56 runs); medians are shown.

## 1. Damage and time to kill (battle)

From `balance_static.py` (the real `cards.json` and `stages.json`):

| Tier | Cards | Mean points per energy | Min | Max |
|---|---|---|---|---|
| 0 | 6 | 2.50 | 1.00 | 5.00 |
| 1 | 16 | 4.00 | 0.00 | 11.00 |
| 2 | 37 | 2.91 | 0.00 | 7.50 |
| 3 | 10 | 3.02 | 1.00 | 4.50 |

Points = `self_plus` + `opp_minus`, ignoring guard, draw and gaffe effects. Median across all cards: 2.50 per energy.

| Measure | Value |
|---|---|
| Combat stages with a numeric threshold | 230 |
| Median "pace ratio" (points still needed / turns x energy x median points per energy) | 0.39 |
| Stages with ratio above 1.0 (not reachable with a median card even if all energy went to points) | **0 %** |
| Stages with ratio above 0.5 | 27 % |
| Highest ratio | 0.93 (ST272 Radio Call-In Hour: 35 needed, 5 turns, 3 energy) |

Reading: the thresholds are comfortably reachable on paper. The opponent's moves and the gaffe meter are what makes a stage lose, and the static table cannot see them. The sim shows the result: most stage types win 95 %+.

Tier 1 cards (4.00 mean) out-score Tier 2 (2.91) and Tier 3 (3.02) per energy. Higher tiers may buy something else (guard, draw, special effects) that this table does not count, so this is a flag for Cameron, not a defect.

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| B-01 | Medium | Card power curve | `data/cards.json` (`tier`, `self_plus`, `opp_minus`, `cost`) | Mean points per energy falls from Tier 1 (4.00) to Tier 2 (2.91) and Tier 3 (3.02), so buying the more expensive tiers does not raise raw output | `balance_static_output.txt` section 1 | Check that Tier 2 and 3 cards win on something else (guard, draw, specials); if not, rebalance | M | Medium |
| B-02 | Medium | Stage difficulty | `data/stages.json` | The static pace test finds no stage that is hard to reach and 73 % that need under half the capacity of a median hand, so difficulty comes almost entirely from opponent pressure and gaffes | Pace ratio median 0.39; sim win rates 88 to 100 % | Treat as a playtest question: do humans feel pressure? If not, tighten thresholds or turn limits per tier | M | Medium |

## 2. Difficulty over levels

Win rate by stage type, all 56 runs (from `analysis_output.txt`). The hardest stage types with at least 15 attempts:

| Stage | Name | Attempts | Win % | Threshold / bar | Turns | Gaffe limit |
|---|---|---|---|---|---|---|
| ST08 | Party Steering Committee | 208 | **50** | 43 / 100 | 5 | 5 |
| ST141 | Party Caucus on Hokkaido Shinkansen Acceleration | 27 | 52 | 49 / 100 | 10 | 5 |
| ST207 | Party Caucus on National Emergency Powers | 30 | 57 | 49 / 100 | 10 | 5 |
| ST135 | Party Caucus on Special Economic Zones | 24 | 62 | 49 / 100 | 10 | 5 |
| ST65 | Party Caucus on the Constitutional Review | 18 | 72 | 49 / 100 | 10 | 5 |
| ST16 | Committee on Finance | 582 | 84 | 84 / 100 | 10 | 3 |

Everything else the bot met is 88 to 100 %. Overall win rate by strategy: 90 to 99 %.

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| B-03 | Medium | Difficulty curve | `data/stages.json`, `data/levels.json` | Difficulty is flat after the first weeks, with a few spikes. No tier above 2 exists in `levels.json` (tier counts 33 / 46 / 35), and in 56 runs of 30 weeks nothing above Tier 2 was ever played. There is no late-game ramp unless the unlocking of tiers is the ramp | Tier counts from `levels.json`; `levels_by_tier` in every run (tiers 3 to 5: 0) | Playtest: does a human at week 20 feel challenged? | M | Medium |
| B-04 | Low | Party Steering Committee | `ST08` | A 50 % win rate over 208 attempts is the sharpest spike. It is a crisis-trigger stage (5 turns, threshold 43 of 100) and the sims lose it about half the time. It pays 90 XP on a win and 5 on a loss, so losing is cheap | `analysis_output.txt`; stage row | Likely intended as a threat; confirm the penalty for losing it is felt | S | Medium |

## 3. Currency earned versus spent

### 3a. Funds

| Fact | Value | Source |
|---|---|---|
| Starting Funds | 100,000 (median shown at week 0 is 37,500 after the first level) | `rules.json funds_starting_cap` |
| Combat win reward | median 20,000; max 100,000 | `stages.json win_delta_yen` |
| Weekly Funds earned (weeks 5 to 30, median) | 212,000 to 494,000 depending on strategy | `analysis_output.txt` |
| Weekly dues (median) | about 190,000 to 280,000 | same |
| Funds at end | 0 in 48 of 56 runs | same |
| Dues owed at end | over 1,000,000 in 47 of 56 runs; median 5.2 M (baseline) | same |
| `cap_dues` (the one strategy that buys cap petitions first) | Funds end at about 172,000, owed 0, party support 100 | same |

Timeline, median of baseline versus `cap_dues`:

| Week | baseline funds / owed | cap_dues funds / owed |
|---|---|---|
| 5 | 0 / 446,660 | 0 / 204,100 |
| 10 | 0 / 1,554,963 | 29,952 / 0 |
| 15 | 0 / 2,466,191 | 52,141 / 0 |
| 25 | 0 / 4,217,678 | 62,173 / 0 |
| 30 | 0 / 5,154,850 | 172,347 / 0 |

So the dues system is solvable but only through one path (spend XP on the cap petition SH13, 100 XP each, early). A player who does not know that falls behind by week 5 and never recovers. Cameron has seen this result before (strategy playtest, 2026-11-02) and left the design; this audit confirms it again with 56 runs and adds the unbounded overdue multiplier (G-04).

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| B-05 | High | Party dues vs Funds cap | `scripts/rules/PartyDues.gd`; `rules.json funds_starting_cap` = 100,000; `shop.json SH13` | Dues rise with Party support to about 190,000 to 280,000 a week against a 100,000 cap. Full payment is impossible until the cap is raised, and 47 of 56 runs ended owing over 1 M. One strategy (buy cap petitions first) clears it; every other does not. A new player has no way to know the order | Runs: baseline owed 5.2 M median; `cap_dues` owed 0. Earlier report: `design/bench/strategy_report_2026-11-02.md` | Either tell the player early (Information Standard 1: say what it costs before) or soften: smaller dues step, higher starting cap, or cap the overdue multiplier | S to M | High |
| B-06 | Medium | Funds vs spend | `data/shop.json` | The big Funds sinks are 200,000 (three Commission items) and 300,000 (staff office) against a 100,000 cap: they cannot be bought until the cap is raised, and dues compete for the same Funds. Cheap items (1,200 to 18,000) are pocket change | Shop price table in `balance_static_output.txt` | Playtest: does a human ever afford the 200,000 items? | S | Medium |

### 3b. XP

| Fact | Value |
|---|---|
| XP earned in 30 weeks (median by strategy) | 25,200 (hoarder) to 46,500 (low_tier_grind) |
| One-time shop prices, sum | 3,130 XP |
| Card unlocks, sum | 635 XP for 70 cards |
| Repeatable sinks | Training coupons (150), cap petitions (100 each), card unlock rolls (250 / 500 / 1,000) |
| XP held at end of run | about 139 (baseline): everything is spent |

XP is plentiful because it is spent on repeatable purchases. Whether that feels like progress depends on how the player values those repeatables. Flag only.

## 4. Drop rates and expected value

| Mechanic | Rate | EV | Note |
|---|---|---|---|
| Card unlock: random Tier 1 / 2 / 3 | 250 / 500 / 1,000 XP | At the sim XP rate (about 1,150 XP a week) a Tier 3 roll costs under a week | Not measured per roll; I did not find a duplicate-protection rule (unverified) |
| Level bonus range | `levels.json bonus_win_range_*` | Not simulated separately | Included in sim totals |
| Event outcomes | `event_options` | Summed per run in the sim | See `events` in the raw rows |

I found no rare-drop mechanics (no loot table, no gacha); the game has random draws only in the card shop rolls and in people draws for bouts (`scripts/BattleSetup.gd:351`, unseeded).

## 5. Progression pace

Medians per strategy (from `analysis_output.txt`, 30 weeks):

| Strategy | XP per week | Weeks to Party support 90 | Weeks to Constituency 70 | Weeks to 10,000 XP | Stage losses per 100 stages |
|---|---|---|---|---|---|
| balanced_adaptive | 1,355 | 5.5 | 4.0 | 11.5 | 2.8 |
| baseline | 1,164 | 5.0 | 8.5 | 11.0 | 2.3 |
| cap_dues | 1,142 | 5.5 | 7.5 | 13.0 | 3.7 |
| hoarder | 840 | 5.5 | 5.5 | 12.0 | 9.2 |
| low_tier_grind | 1,551 | 4.0 | 6.0 | 10.0 | 0.4 |
| short_levels | 1,219 | 4.0 | 5.0 | 11.5 | 0.3 |

Every strategy reaches maximum Party support by week 4 to 6 and 76 to 79 Constituency support by week 30. Meters that sit at their ceiling for 25 of 30 weeks stop being goals. This matches the project's own note that Election Strength fires nothing yet.

**Milestones versus session length.** No target session length was supplied. The game's own clock is 40 work hours a week and the sims average about 15 stages a week (445 stages in 30 weeks); a stage takes a human an unknown number of minutes. I cannot convert hours to minutes without a play test, so I do not claim a session length. Flagged for playtest.

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| B-07 | Medium | Meta meters | `data/sanban.json`; sims | Party support reaches 90 or more by week 4 to 6 and Constituency by week 4 to 8 in every strategy, then sits there. The meters stop changing, so the main progress display stops moving after the first quarter | Pace table above | Decide what the later game should chase (the unused Election Strength is the obvious candidate) | M | Medium |

## 6. Tier payoff and repeat farming

Per level play, all runs (7,733 Tier 0 plays, 1,106 Tier 1, 719 Tier 2):

| Tier | Median hours | Funds per hour | XP per hour |
|---|---|---|---|
| 0 | 2 | **7,500** | **40.0** |
| 1 | 13 | 6,000 | 27.5 |
| 2 | 16 | 5,556 | 26.5 |

And repeats: 3,833 of 9,558 level plays (40 %) were the 10th or later play of the same level in one run, paying a median 8,250 Funds and 42.5 XP per hour. That is as good as a first play. The most played levels were LV85 (800 plays across runs), LV02 (770), LV94 (673), LV01 (669), LV86 (667).

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| B-08 | High | Level rewards / grind | `data/levels.json` (`tier`, `cooldown`, `win_delta_*`); `data/stages.json` rewards | Short Tier 0 levels pay more per hour than long Tier 1 and 2 levels, and repeats do not decay. The best strategy is to replay the shortest level: `low_tier_grind` has the fewest losses (0.4 per 100), the fastest rise to Party 90 (4 weeks) and the most XP (46,500). Tier 1 and 2 exist to be harder and longer yet pay less per hour | `analysis_output.txt` "Per-level yield" and "Pace per strategy" | Raise Tier 1 and 2 rewards per hour above Tier 0, or add decay to repeated levels (the cooldown field exists; 51 of 114 levels carry it) | M | High |

## 7. What the bots cannot tell us

| Limit | Why |
|---|---|
| Human pacing | A person reads, hesitates, misplays and takes minutes per stage; the bot takes none |
| Human win rate | The bot plays a fixed heuristic; real players may be better (planning) or worse (hand management) |
| Satisfaction | Whether the Party-support ceiling at week 5 feels like victory or like a dead meter |
| Session length | No real-time clock exists in the sims |
| Seeds | 56 runs; medians are stable across seeds here but a single odd run can still sit in them |
| Patron requests | The bot reported 1,472 "could not be started" patron bills (G-06). Most likely a bot artifact; I did not isolate it |

## 8. Duplicated or contradictory balance, cross-reference

| Item | Where | Note |
|---|---|---|
| Funds cap 100,000 versus dues 190,000 to 280,000 | `rules.json`, `PartyDues.gd`, `balance.json` | The same cliff as B-05 |
| Loss pays XP and Funds on 201 of 230 combat stages (median 1 XP, 0 to 1,000 Funds) | `stages.json loss_delta_*` | Small, but a loss is never zero; see T-series in `02-tuning.md` |
