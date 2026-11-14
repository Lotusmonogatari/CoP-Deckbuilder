# Phase 4: Testing

Every result is compared to the frozen benchmarks in `audit/benchmarks.md`. Status is **pass**, **fail** or **not measurable**. Raw results are in `audit/tests/results/`; `audit/tests/results/analysis.json` holds every number quoted here.

## 1. What I built and ran

| Tool (all under `audit/tests/`) | What it does | Sample |
|---|---|---|
| `sim_harness.gd` + `run_sims.sh` | Headless, seeded fights in every Combat room with the real `BattleEngine`, two policies (random, greedy), two kits (starter, full), invariant checks after every action, timing of every card play | 14 runs, **80,150 fights**, 1,416,979 timed card plays |
| `invariant_probe.gd` | Targeted checks: conversion costs, opening decks, multipliers, survival line, pressure, gaffe-first and threshold-stop | 10,000 rolls; 2,000 decks; 29,541 comparisons; 1,200 fights |
| `tech_probe.gd` (under Xvfb) | Draw calls, per-frame scripts, memory across 40 stage loads, save time and round trip | 1 run |
| `static_scan.py`, `build_mechanics_csv.py` | Where every variable is defined and read | 149 scripts, 64 data files |
| `run_strategy.sh` (wraps the project's `tools/strategy_playtest.gd`, unchanged) | Seeded 30-week campaign runs | **210 runs**: 60 strategies x 3 seeds (PC02); baseline and random-cards x 4 protagonists x 3 seeds; baseline at Relaxed and Harder x 3 seeds |
| Project tools run as they are | `tools/benchmark.gd` (headless and display), `tools/playtest_optimal.gd` (4 full runs, 80 level attempts each, **unseeded**), `tools/rubric_playtest.gd`, `tools/verify.sh` | as stated |
| `analyze.py` | Turns all of the above into the numbers below | n/a |

**Policies.** *Random* shuffles the affordable cards, plays until energy runs out, stops early 20% of the time, passes 10% of turns, and never plays a card that makes you discard. *Greedy* plays the affordable card with the best immediate value per energy (support, opponent support where it counts, guard only against a coming attack, draw; gaffes priced at 1.5) and refuses any card that would fill the gaffe meter.

**Kits.** *Starter*: a fresh seeded opening deck for every fight, starting meta, no backings, no items. *Full*: every card owned, the 15 cards worth most in that room, every backing owned, meta and standing at 80, **no items**. The full kit is therefore weaker than the benchmark's wording ("all cards, backings and items"), and its deck is my heuristic, not a player's.

**Limits to read with every balance number**

- Bots are not people (`design/BALANCE_AUDIT_PROCESS.md:40`). Treat rates as relative.
- Greedy never loses to gaffes, by construction. That shapes BAL-07.
- One room, ST261 (the member-visit fight), exists only inside a sponsored level and is skipped by the sweep. It was played 11 times in one baseline strategy run (11 wins).
- Who is seated is not seedable (`audit/dynamics.md` section 5), so a re-run reproduces the engine's rolls and deck but not always the same opponent.

## 2. Balance scorecard

| ID | Target | Result | n | Status |
|---|---|---|---|---|
| BAL-01 | Starter win rate 15% to 95% in every room | No room below 15%. **37 of 229 rooms above 95%** (15 at 100%). Overall 78.7%, median room 81% | 100 fights per room | **Fail** (too easy in 37 rooms; no walls) |
| BAL-02 | Full-kit win rate 50% to 98% in every room | **10 rooms below 50%** (Media Ambush ST19 2% and ST234 0%; Party Caucus ST212 0%; Candidate Selection Committee 34%; six more caucus rooms 38% to 46%). **177 rooms above 98%.** Overall 94.3% | 50 per room | **Fail** on both edges. The low rooms depend on my deck heuristic and the missing items: read as a prompt to check, not a proven wall |
| BAL-03 | Kit gain at least 10 points per family | **10 of 22 families under 10 points**: five committee families and Policy Study Session are already at 92% to 100% on the starter kit (no room to gain); Lobbyist Meeting +8.2; Special Committee +7.0; Committee of the Cabinet +9.0; **Media Ambush −26.5** | by family | **Fail** |
| BAL-04 | New-room band 50% to 90% (upper edge proposed) | 153 of 229 rooms sit inside it on the starter kit | 100 per room | Reported: 67% of rooms inside |
| BAL-05 | Random at least 20 points below greedy, per family (proposed) | Every family passes. Random 6.8% overall against greedy 78.7% | 22,900 random fights | **Pass** |
| BAL-06 | Turns to win 40% to 85% of the limit (proposed) | Median 55%. 123 of 202 rooms inside; 39 below (Lobbyist Meetings are won in about 21% of the limit); 40 above. Press conferences excluded: they run the whole limit by rule | wins in 202 rooms | **Fail** for 79 rooms (39%) |
| BAL-07 | No loss cause above 80% in a family (proposed) | Greedy losses: turn limit 3,602; press tone short 734; below the survival line 394; argued out 153; **gaffes 0**. 14 families have one cause at 82% to 100%. Random losses: gaffes 12,566; turn limit 5,674; tone short 1,406; below line 898; argued out 808 | 4,883 greedy losses; 21,352 random losses | **Fail** as written. The cause is the room type (a caucus can only be lost on time), so the benchmark is poorly framed: see Phase 5 |
| BAL-08 | No card over 3x the mean plays; none never played | Mean 1,290 plays per card. **Over 3x: C14 (4.3x), C38 (3.9x), C09 (3.0x). Never played: 9 cards** (C04, C16, C20, C24, C29, C41, C44, C46, C53) | 90,302 plays, 12 baseline runs | **Fail**. The bot owned 50 to 61 of 70 cards, so some "never played" cards were never owned |
| BAL-09 | Each suit 8% to 28% of plays | Appeal 18.9%, Data Driven 27.7%, Divisive 9.7%, Duplicitous 11.0%, Earnest 17.2%, Emotional 15.5% | same | **Pass** (Data Driven 0.3 points under the edge) |
| BAL-10 | No power outlier beyond z ±2; suit spread ≤ 1.35; no dominated card | **4 outliers** (C63, C69, C67, C65, all discard cards, z 2.4 to 3.4); **suit spread 1.84** (Appeal 2.24 to Duplicitous 4.13); **1 dominated card** (C01 by C25). Tier means 2.92 / 4.44 / 3.10 / 2.97 | 70 cards | **Fail**. The outliers' discard price is not in this measure |
| BAL-11 | Card pick rate (no target) | The deck-building bot owned 50 to 61 of 70 cards at week 30 | 12 runs | Reported |
| BAL-12 | No meta value at 100 for over 50% of level-ends | **Party support at 100 for 62% of level-ends** (76%, 78%, 62%, 33% by run). Constituency support 10%; Reputation 4%. At week ends Party support is 90 or more 86% of the time | 4 runs x 80 levels (unseeded bot); 12 seeded runs | **Fail** (Party support) |
| BAL-13 | No organization at ceiling 90% of a run; none unreachable | Highest share at 100: BO26 48%, BO06 47%, BO04 41%. None at 5 or below for half a run | 4 runs | **Pass** |
| BAL-14 | Harder rooms pay at least as much | **Hardest third of levels: 10,625 Funds and 25.0 XP an hour; easiest third: 12,667 and 30.0** | 93 levels | **Fail** |
| BAL-15 | Reward per hour does not fall with tier (proposed) | Funds 8,000 / 10,491 / 12,857; XP 25.0 / 27.2 / 31.4 | 114 levels | **Pass** |
| BAL-16 | Best strategy ≤ 1.25x the median; no single-suit deck in the top 3 (proposed) | **Best / median = 1.70** (campaigner_cap and cap_dues 0.917; median 0.54). No single-suit deck in the top 3. The top five all buy the Funds cap and pay dues | 180 runs, 60 strategies | **Fail** on the ratio; pass on single-suit |
| BAL-17 | Dues payable in 80% of weeks from week 4 (proposed) | Strategies that set dues aside paid in **100%** of weeks. The baseline bot paid in 4.6% and owed 1.41M to 1.76M at week 30 with no lasting cost | 180 + 12 runs | **Pass** (it can be paid). See F-03 in Phase 5 for what not paying costs |
| BAL-18 | XP neither stuck at 0 nor piling up (proposed) | 104 to 187 in hand at week 30; 35,029 earned; dearest price 1,000 | 12 runs | **Pass** |
| BAL-19 | Full-strength flips 10% to 60% of votes | 33, 33, 34, 36 of 60 (55% to 60%) | rubric line C4, 4 protagonists | **Pass** (PC04 exactly at the edge) |
| BAL-20 | Relaxed ≥ Standard ≥ Harder in every family | Overall 84.6% / 76.8% / 66.3%. One family of 22 out of order: Floor Debate 84 / 80 / 84 | 5,725 each; 25 for that family | **Pass overall; inconclusive for one family** (n = 25) |
| BAL-21 | Run length (no target) | 3.7 levels, 14.6 stages, 11.0 combat stages per game week; campaign stage win rate 96.9% | 12 runs | Reported |

## 3. Technical scorecard

All targets here are proposed and all results are **desktop proxies** (`audit/benchmarks.md` section B). Timings vary run to run; I show both runs where I have two.

| ID | Target | Result | Status |
|---|---|---|---|
| TEC-01 | 16.7 ms frames on a phone | No device | **Not measurable** |
| TEC-02 | Redraw after a card: median ≤ 16 ms, worst ≤ 33 ms (headless) | Median 12.4 ms and 19.5 ms; **worst 52.8 ms and 55.8 ms** (October baseline: 10.1 and 21.8) | Median pass (within tolerance); **worst fails** |
| TEC-03 | Redraw after a turn ≤ 33 ms | **71.0 ms and 85.7 ms** (baseline 24.2) | **Fail**: about three times slower than in October |
| TEC-04 | Rules ≤ 1 ms per card and per end of turn | Card play median 0.042 ms, p95 0.079 ms, max 3.2 ms; end of turn median 0.023 ms | **Pass** (n = 1,416,979 plays) |
| TEC-05 | Simulated stage ≤ 20 ms median | 4.2 ms median, 12.7 ms p95 | **Pass** (n = 2,290) |
| TEC-06 | Data load ≤ 250 ms | **817 ms and 665 ms** (baseline 62 ms) | **Fail**: more than ten times the October baseline |
| TEC-07 | Scene load: cold ≤ 1,000 ms, warm ≤ 150 ms | Cold worst 900 ms (Office), 789 ms (Battle); warm worst 134 ms (Battle), headless | **Pass**, close to the cold limit |
| TEC-08 | Office panel ≤ 100 ms | Worst 57 ms (Backing), headless | **Pass** |
| TEC-09 | Static memory ≤ 200 MB | 156.4 MB (display), 185.2 MB (headless) | **Pass** |
| TEC-10 | Texture memory ≤ 128 MB | 67.7 MB after all scenes; 83.8 MB after 40 stage loads | **Pass** today; most art is undrawn |
| TEC-11 | Growth under 2% over repeated stage loads; no orphans | Over 40 loads: objects 2,919 to 2,981 (**+2.1%**), static +0.3%, **textures +18%** (71.0 to 83.8 MB), 0 orphans | **Marginal fail** on objects; texture growth is probably cached art (Inferred) |
| TEC-12 | Draw calls ≤ 150 (battle), ≤ 200 (Office) | 69 and 38 | **Pass** |
| TEC-13 | Battle screen ≤ 250 nodes | 120 (headless), 183 (display) | **Pass** |
| TEC-14 | No per-frame script work on an idle screen | Still running every frame: `Layout._process` (both screens; compares one string and returns, `scripts/autoload/Layout.gd:130`), the background's `PlaceholderArt._process` (reads the tilt sensors each frame while Image Pan is on, `scripts/ui/PlaceholderArt.gd:300`), and `OfficeScreen._process` (the ticker, `scripts/ui/OfficeScreen.gd:280`) | **Fail** as written; the cost is small |
| TEC-15 | ≤ 10 `EventBus` emissions per card; none without listeners | The rules layer emitted 0 in 80,150 fights. The battle screen has 7 emit sites; emissions per card on screen were not counted | **Partly measured** |
| TEC-16 | Save ≤ 50 ms, ≤ 1 MB | 1.97 ms median, 2.57 ms worst; 5,382 bytes on a fresh run. Size after a 30-week run not measured | **Pass** (fresh run only) |
| TEC-17 | Download ≤ 200 MB | No export exists. `assets/` is 275 MB uncompressed | **Not measurable** |

## 4. Invariant scorecard

| ID | Result | Evidence | Status |
|---|---|---|---|
| INV-01 | 600 votes tally to 101; every bill's splits add to each party's seats | Rubric lines C1, C1b (ran today) | **Pass** |
| INV-02, INV-03 | Week-end values stayed in range in all 210 runs: Constituency 1 to 84, Reputation 0 to 87, Party 0 to 100, Funds 0 to 861,818 and never above the cap | strategy run series | **Pass** |
| INV-04 | Not checked by my tools; the project's rubric line B5 passes (please +5, annoy −3, set back −3, capped) | rubric run today | **Pass** (project tool) |
| INV-05, INV-06, INV-12, INV-28 | 0 violations in 80,150 fights: guard within 0 to 5, energy never negative, every fight ended in win, loss or retry within its limit, cards conserved, no negative or invalid bar | `sim_*.json` | **Pass** |
| INV-07 | 25 of 25 cases lost | `invariants.json` | **Pass** |
| INV-08 | 521 of 521 threshold wins left the opponent's support unmoved | `invariants.json` | **Pass** |
| INV-09 | 29,541 comparisons, 0 differences | `invariants.json` | **Pass** |
| INV-10 | 58.9% / 31.0% / 10.1% over 10,000 rolls (target 60 / 30 / 10, ±3) | `invariants.json` | **Pass** |
| INV-11 | Not exercised as a test of loss; the bot's visitor and vote stages always completed | strategy runs | Not tested directly |
| INV-13 | Every starter deck dealt was 15 cards | 2,000 decks | **Pass** for size; "owned cards only" not tested |
| INV-14 | 2,000 decks: all 15 cards, suits within one, none over half gaffe cards, 0 with two tier-3 cards, 507 with one (25.4%), 0 repeated cards | `invariants.json` | **Pass** |
| INV-15 | Project test `tests/test_vote_whip.gd` passes | verify run | **Pass** (project test) |
| INV-16 | Rubric lines C2, C3, C4 pass | rubric run today | **Pass** |
| INV-17 | The longest level in the data is 35 hours (LV19); the start gate itself was not tested | `data/levels.json`, `data/stages.json` | **Pass** for the data; gate not tested |
| INV-18, INV-19 | Not tested here; `tests/test_special_levels.gd` passes | verify run | Not tested directly |
| INV-20 | Project tests `tests/test_party_dues.gd`, `tests/test_meta_decay.gd` pass | verify run | **Pass** (project tests) |
| INV-21 | Largest weekly moves +2.5 and −1.5 at Standard over 6,120 week steps | strategy runs | **Pass** |
| INV-22 | Rises of 0, 1, 2, 3 only | `invariants.json` | **Pass** |
| INV-23 | Energy, hand size, turn limit and energy pool identical at all three pressures in every room | `invariants.json` | **Pass** (card values not separately compared) |
| INV-24 | 81 saved fields survived save then load unchanged on a fresh run. A result shown on screen surviving a close was not tested | `tech_probe.json` | **Pass** for the round trip; second half not tested |
| INV-25 | Rubric D4 passes. **Rubric D1 fails today**: law "once" amounts differ from the rubric's expectation by 1 to 2 points for some party-body organizations (for example BI01 pass: BO31 −3, expected −2). **D3 also fails.** The rubric scored 66 / 66 in October and **61 / 66 today** | rubric run today; `design/PLAYTEST_RUBRIC.md` | **Fail** against the rubric. Whether the rubric or the game is out of date is not established: see Phase 5 |
| INV-26 | Engine: the same seed gave the same fight in 14 of 14 runs. Seating: the same global seed seated different opponents in 14 of 14 runs | `sim_*.json` `determinism` | **Pass** for the engine; **fail** for a whole stage |
| INV-27 | `scripts/rules/PatronVisit.gd` calls the `DataDB` autoload (lines 23, 26, 94) and the `Text` autoload 11 times | `grep` | **Fail** (one file) |
| INV-29 | 976 values in 10 hand-written JSON files; constants and literals in scripts; 83 fallbacks that disagree with the workbook | `audit/mechanics.md` section 4.1 | **Fail** |

## 5. Efficiency

| System | Cost | Evidence | Label |
|---|---|---|---|
| Rules engine | 0.04 ms per card, 0.02 ms per end of turn, 4 ms per whole stage. Not a concern even at 5x slower | harness, n above | Verified |
| Data load | 0.67 to 0.82 s on this desktop: the largest single cost found, and it grew more than tenfold since October while the data grew | `bench_headless.json`, second run | Verified |
| Battle screen redraw | After a turn 71 to 86 ms; after a card 12 to 19 ms median with 53 to 56 ms spikes | same | Verified |
| Scene loads | Office 0.64 to 0.90 s cold; Battle 0.79 s cold | same | Verified |
| Allocations | 0 orphan nodes; objects +2.1% and textures +18% over 40 stage loads | `tech_probe.json` | Verified |
| Signals | 19 signals; the rules layer emits none; screens emit to `EventBus` | `audit/mechanics.md` M-26 | Verified |
| Per-frame work | Three `_process` functions run on idle screens (TEC-14); four others stop themselves or belong to transient nodes (Inferred, not each read) | `tech_probe.json` | Verified for the three |

## 6. Effectiveness: does each mechanic do its design job?

| Mechanic | Design job | Measured | Verdict |
|---|---|---|---|
| Card choice | "every hand is played against a known threat" (`design/GAME_DESIGN.md:25`) | Random play wins 6.8%, greedy 78.7% | Does its job: choices matter a great deal |
| Gaffe meter | A way to lose (`design/GAME_SYSTEMS.md:194`) | 59% of random-play losses; 0% of greedy losses | Works as a punishment for careless play; a careful player can ignore it |
| Turn limit | A way to lose | 74% of greedy losses | The main real pressure |
| Support at zero | A way to lose | 3% of greedy losses, concentrated in Media Ambush and Special Committee | Rare outside two families |
| Kit growth | Getting stronger changes outcomes | 78.7% to 94.3% overall; 10 of 22 families gain under 10 points | Works where rooms are not already trivial |
| Political Pressure | Three difficulty tiers | 84.6 / 76.8 / 66.3% | Does its job |
| Suits and affinity | "no approach dominates" (`design/GAME_DESIGN.md:35`) | Suit shares 9.7% to 27.7%; no single-suit strategy in the top 3; static suit power spread 1.84x | Play is spread; printed power is not |
| Cards | All usable | 3 cards over 3x the mean; 9 never played by the bot | Partly: see BAL-08 |
| Party dues | A weekly cost that matters | Skipping dues for 26 weeks left Party support at 90 and election strength at 69 to 74 | **Does not do its job** for a player who ignores it |
| Party support | A resource to manage | At 100 for 62% of level-ends | Saturates |
| Reputation | Gates and start bonuses at 80 | Ends at 11 to 44 | Its high-end reward is out of reach |
| Organization standing | Reachable, not maxed | Top organization at 100 for 48% of level-ends; none stuck at zero | Does its job |
| Awareness | A slow meter gaffes erode | National 100 by week 9 to 15, District by 18 to 24 | Saturates; the gaffe cost is too small to show |
| Election strength | Unstated | Rises at its speed cap to about 72 | Fires nothing |
| Level tiers | Higher tier pays more | Per hour: yes | Does its job |
| Reward for difficulty | Harder pays at least as much | No: the hardest third pays less | Does not |
| Influence flips | Hard but reachable | 55% to 60% of votes at full strength | Within band |
| Determinism | Unstated | Engine yes; seating no | Gap |
