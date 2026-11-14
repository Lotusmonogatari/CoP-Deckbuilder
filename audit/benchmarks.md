# Phase 1: Benchmarks

Status: **FROZEN 2026-11-14.** Cameron reviewed the draft and said to proceed with my recommendations for the open decisions; those are recorded in section D. The targets were written before any analysis and do not change from here: later phases only report pass, fail or not measurable against them.

**How to read the tables**

- **Source** is the design document line the target comes from. **Proposed** means no design document states it, and I am suggesting a number for Cameron to accept, change or strike. I did not invent design intent: every proposed row says what it is based on.
- **Tolerance** is how far a measurement may sit from the target and still pass.
- **Method** names the tool and the sample size. "Greedy" is the best-card heuristic and "random" the shuffled-hand policy; both already exist in `tools/playtest_optimal.gd:15`, and my harness under `audit/tests/` will add its own seeded pair.
- Bot win rates are **relative**, not what a person will see (`design/BALANCE_AUDIT_PROCESS.md:40`).

## A. Balance

| ID | Benchmark | Target | Tolerance | Method | Source |
|---|---|---|---|---|---|
| BAL-01 | Starter-kit win rate, every combat room (first-time player) | 15% to 95% per room | ±5 points at n=100 per room | Greedy policy, opening deck only, no backings or items, 100 seeded fights per room across the 4 protagonists | `tools/balance_audit.py:24-25`; `design/BALANCE_AUDIT_PROCESS.md:47` (Media Ambush is the one allowed wall) |
| BAL-02 | Full-kit win rate, every combat room (late player) | 50% to 98% per room | ±5 points at n=50 per room | Greedy policy, all cards, backings and items | `tools/balance_audit.py:26-27` |
| BAL-03 | Kit gain per room family (full minus starter) | at least 10 points | none | BAL-01 and BAL-02 grouped by family | `tools/balance_audit.py:28`; `design/BALANCE_AUDIT_PROCESS.md:48` |
| BAL-04 | "Fair room" band for a new or changed room | won "roughly half to most of the time": 50% to 90% | ±5 points at n=40 | `PLAYTEST_STAGE_TRIAL` style trial as PC02 | `design/CONTENT_GUIDE.md:293` (the 90% upper edge is my reading of "most": **proposed**) |
| BAL-05 | Random policy must do clearly worse than greedy (skill matters) | random win rate at least 20 points below greedy, per family | ±5 points | Both policies, same seeds | **Proposed.** Based on `design/GAME_DESIGN.md:25` ("every hand is played against a known threat") |
| BAL-06 | Turns used per won combat stage | 40% to 85% of the stage's turn limit (limits are 5 to 17, median 10, in `data/stages.json`) | ±10 points | Greedy, full sweep; record turns at win | **Proposed.** No document states pacing. The loss-on-timeout rule is `design/GAME_SYSTEMS.md:194` |
| BAL-07 | Losses by cause (gaffes, turn limit, support to zero) | no single cause above 80% of all losses in a family | none | Loss reasons from the sweep | **Proposed.** `design/GAME_SYSTEMS.md:194` lists three ways to lose |
| BAL-08 | Card play rate | no card played more than 3x the mean; no card never played | none | Card tally over full greedy runs (4 protagonists x 80 level attempts) | `design/BALANCE_AUDIT_PROCESS.md:51`; `tools/balance_audit.py:29-30` |
| BAL-09 | Suit share of plays | each of the 6 suits between 8% and 28% | none | Same tally | `design/BALANCE_AUDIT_PROCESS.md:52` |
| BAL-10 | Card power per energy (static) | no card beyond z = ±2.0; best suit mean at most 1.35x the worst; 0 strictly dominated cards | none | Static calculation on `data/cards.json` with the audit's own weights | `tools/balance_audit.py:23`, `:33`; dominated cards flagged at `:93` |
| BAL-11 | Card pick rate in Rhetoric Training | **not measurable as a target** | n/a | Record learn-versus-pass by card for the greedy deck builder | **Gap.** No document states an intended pick rate. I will report the numbers without a pass or fail |
| BAL-12 | Meta values at their ceiling | no meta value (Constituency support, Reputation, Party support) at 100 for more than 50% of a run's level-ends | none | 30-week seeded runs, per protagonist | `design/BALANCE_AUDIT_PROCESS.md:50` |
| BAL-13 | Organizations at ceiling or unreachable | no organization at its ceiling for 90% or more of a run; none permanently unreachable | none | Standing at every level-end in the same runs | `tools/balance_audit.py:31`; `design/BALANCE_AUDIT_PROCESS.md:50` |
| BAL-14 | Rewards follow difficulty | harder rooms pay at least as much as easier ones; no family's reward-per-difficulty beyond 3x the median | none | Static reward index against the measured win rate | `design/BALANCE_AUDIT_PROCESS.md:49`; `tools/balance_audit.py:32` |
| BAL-15 | Reward per hour by level tier | Funds and XP per hour do not fall as tier rises (Tier 0 ≤ Tier 1 ≤ Tier 2) | 5% | Static, from `data/levels.json` and `data/stages.json` | **Proposed.** Follows BAL-14; the earlier audit found the reverse (`audit/gameplay/00-summary.md:30`) |
| BAL-16 | Dominant-strategy ceiling | the best named strategy scores at most 1.25x the median strategy; no single-suit deck strategy in the top 3 | none | `tools/strategy_playtest.gd` strategies, 30 weeks, seeds 1 to 3 | **Proposed.** Based on `design/GAME_DESIGN.md:35` ("so no approach dominates by weight of numbers") |
| BAL-17 | Resource curve: Funds against dues | at Standard, a greedy run can pay each week's dues in at least 80% of weeks from week 4 on | ±10 points | 30-week runs; dues formula from `design/GAME_SYSTEMS.md:164` | **Proposed.** No document states how often dues should be payable |
| BAL-18 | Resource curve: XP | spendable XP neither stuck at 0 nor growing without a sink: median XP at week 30 below 10x the dearest single XP price | none | Same runs | **Proposed** |
| BAL-19 | Influence flips | a full-strength player flips between 10% and 60% of yes/no votes | none | Rubric line C4 method (`tools/rubric_playtest.gd`) | `tools/balance_audit.py:34` |
| BAL-20 | Political Pressure ordering | greedy win rate Relaxed ≥ Standard ≥ Harder, in every family | 3 points | Sweep at each pressure | `design/GAME_SYSTEMS.md:196` (levers listed; ordering is implied, so **partly proposed**) |
| BAL-21 | Run length | **not measurable as a target** | n/a | Report levels, stages and hours per game week and real seconds per stage for the bot | **Gap.** `design/GAME_SYSTEMS.md:58`: "the player stops when they like"; no session or run length is stated |

## B. Technical

No design document states a technical budget (`audit/phase0_orientation.md` section 5), so **every target in this section is proposed**. Each is set from the project's own measured baseline (`design/bench/after_phase1.json`, 2026-10-11) with headroom for a mid-range phone, which I assume is 3 to 5 times slower than this desktop on script work. That factor is **Assumed**, not measured.

Nothing here can be measured on a phone (`audit/phase0_orientation.md` section 3). The Method column gives the desktop proxy, and results will be marked "proxy".

| ID | Benchmark | Target (proposed) | Tolerance | Method | Basis |
|---|---|---|---|---|---|
| TEC-01 | Frame time on a mid-range phone | 16.7 ms (60 fps), p95 under 33 ms | n/a | **Not measurable here.** Needs a device build | Standard 60 fps budget |
| TEC-02 | Screen redraw after a card (desktop proxy for TEC-01) | median ≤ 16 ms headless; worst ≤ 33 ms | +30% (timing noise, `design/bench/README.md:9`) | `tools/benchmark.gd`, 9 runs, median | Baseline 10.1 ms median, 21.8 ms worst (headless) |
| TEC-03 | Screen redraw after a turn | median ≤ 33 ms headless | +30% | Same | Baseline 24.2 ms |
| TEC-04 | Rules cost per card play and per end of turn | ≤ 1.0 ms each | +30% | `engine_play_card_ms`, `engine_end_turn_ms`, and my harness over at least 10,000 plays | Baseline 0.12 ms and 0.08 ms |
| TEC-05 | Whole simulated stage, rules only | ≤ 20 ms per stage median | +30% | Harness, seeded, at least 2,000 stages | New measure |
| TEC-06 | Data load at boot | ≤ 250 ms on desktop | +30% | `data_load_ms` | Baseline 60 to 63 ms |
| TEC-07 | Scene load | cold ≤ 1,000 ms; warm ≤ 150 ms (desktop) | +30% | `scenes.*.cold_ms` / `warm_ms` | Baseline worst cold 470 ms (Office), worst warm 106 ms (Battle) |
| TEC-08 | Office panel open | ≤ 100 ms each | +30% | `office_panels_ms.*` | Baseline worst 55 ms |
| TEC-09 | Memory: engine static | ≤ 200 MB after all scenes (display mode) | +5% | `memory_end_mb.static_mb` | Baseline 106 MB |
| TEC-10 | Memory: textures | ≤ 128 MB after all scenes (display mode) | +5% | `memory_end_mb.texture_mb` | Baseline 54.7 MB; art is mostly undrawn, so this will grow |
| TEC-11 | Memory growth over play | objects and static memory grow less than 2% across 50 stage loops; 0 orphan nodes | none | `tools/stress.sh` or the harness with `Performance` monitors | New measure |
| TEC-12 | Draw calls per frame | ≤ 150 in the battle screen; ≤ 200 in the Office | none | `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` under Xvfb | New measure; counts do not depend on the software renderer |
| TEC-13 | Node count | battle screen ≤ 250 nodes | none | `nodes_in_battle_screen` | Baseline 138 |
| TEC-14 | Per-frame work | every `_process` either stops itself when idle (`set_process(false)`) or is on a documented list; idle screens run no per-frame script work | none | Read the 7 `_process` functions (`audit/phase0_orientation.md` section 1) and count calls per second on an idle screen | New measure |
| TEC-15 | Signal churn | at most 10 `EventBus` emissions per card play; no emission with zero listeners in normal play | none | Count emissions in the harness | New measure |
| TEC-16 | Save | write ≤ 50 ms on desktop; file ≤ 1 MB after a 30-week run | +30% | Time `SaveManager` in the harness | New measure |
| TEC-17 | Download size | base package ≤ 200 MB compressed | none | **Not measurable here** (no export). Report `assets/` size (275 MB today) | External store rule, `audit/06-ship-readiness.md` finding S-03 |

## C. Correctness (invariants)

These must hold in every simulated game and every targeted test. Tolerance is zero unless a row says otherwise. Method for all: assertions inside the seeded harness after every action, plus a targeted test where named.

| ID | Invariant | Source |
|---|---|---|
| INV-01 | Every Floor Vote tallies exactly 101 seats; a bill passes at 51 Aye; abstentions count against it; a supermajority bill needs 67% | `design/GAME_SYSTEMS.md:202`; `CLAUDE.md` section 4 |
| INV-02 | Constituency support, Reputation and Party support stay in 0 to 100 | `design/GAME_SYSTEMS.md:98-101` |
| INV-03 | Funds stay in 0 to the cap; the cap is 100,000 plus petitions and never above 1,000,000 | `design/GAME_SYSTEMS.md:100` |
| INV-04 | Organization standing stays in 0 to 100; question answers move one organization by at most ±10 net per stage | `design/GAME_SYSTEMS.md:110` |
| INV-05 | Guard never exceeds 5 and carries between turns | `design/GAME_SYSTEMS.md:188`; `data/rules.json` `guard_cap` |
| INV-06 | Energy refills each turn and is never carried; a pass costs 1 energy next turn | `design/GAME_DESIGN.md:25`; `design/GAME_SYSTEMS.md:186` |
| INV-07 | The gaffe meter is checked first: a card that fills it loses the stage even if it also crosses the threshold | `design/GAME_SYSTEMS.md:186` |
| INV-08 | Crossing the threshold ends the stage at once; the opponent's queued move does not resolve | `design/GAME_SYSTEMS.md:186` |
| INV-09 | Affinity and question multipliers never change guard, draw or gaffe numbers | `design/GAME_SYSTEMS.md:188` |
| INV-10 | Conversion costs: undecided 1 point; opposed 1, 2 or 3 points at 60%, 30%, 10% (tolerance ±3 points over 10,000 rolls) | `design/GAME_SYSTEMS.md:190` |
| INV-11 | Floor Votes and Office Hours cannot be lost; a lost press conference or media ambush does not end the level | `design/GAME_SYSTEMS.md:194` |
| INV-12 | Every stage ends: win, or loss by gaffes, turn limit or support at zero. No stage runs past its turn limit | `design/GAME_SYSTEMS.md:194` |
| INV-13 | The deck is exactly 15 plus bought slots, of owned cards only | `design/GAME_SYSTEMS.md:122-123` |
| INV-14 | The opening deck has 15 cards, suits within one card of even, at most half gaffe cards, at most one tier-3 card (25% chance, tolerance ±3 points over 2,000 deals) | `design/GAME_SYSTEMS.md:69` |
| INV-15 | Whipping: at most 3 per vote; Party support never falls below 30 by whipping | `design/GAME_SYSTEMS.md:203` |
| INV-16 | The influence gate is an AND: one unmet enabled row keeps it shut; no party gives up more seats than its resistance | `design/GAME_SYSTEMS.md:203`; `design/PLAYTEST_RUBRIC.md` lines C2, C4 |
| INV-17 | A level starts only if it ends within the hours left; no level is longer than 35 hours | `design/GAME_SYSTEMS.md:85` |
| INV-18 | Each crisis trigger fires once on crossing in, and again only after coming back out | `design/GAME_SYSTEMS.md:172` |
| INV-19 | A bill voted Aye or Nay never returns; an absent or abstained bill returns only after 7,488 hours | `design/GAME_SYSTEMS.md:182` |
| INV-20 | Week end: dues equal the stated formula; decay runs once, in the stated order, times the decay multiplier | `design/GAME_SYSTEMS.md:164-167` |
| INV-21 | Election strength moves at most +2.5 or −1.5 per week | `design/GAME_SYSTEMS.md:114` |
| INV-22 | The survival line rises by 0 to 3 each turn | `design/GAME_SYSTEMS.md:192` |
| INV-23 | Political Pressure never changes card values, energy, hand size or turn limits | `design/GAME_SYSTEMS.md:196` |
| INV-24 | Save then load returns every saved field unchanged; a stage result shown on screen survives closing the app | `design/GAME_SYSTEMS.md:56`, `:212`, `:323` |
| INV-25 | A law's "once" effects apply once; recording the same bill twice changes nothing | `design/PLAYTEST_RUBRIC.md` lines D1, D4 |
| INV-26 | Same seed and same policy give the same battle, move for move | **Proposed.** `scripts/rules/BattleEngine.gd:148` accepts a seed, but no document promises determinism, and several generators are unseeded (`audit/phase0_orientation.md` section 4) |
| INV-27 | `scripts/rules/` uses no UI, autoload or file access | `CLAUDE.md` section 5 |
| INV-29 | Every design value is read from the workbook. A value held only in a hand-written JSON file or typed into a script is a deviation unless it is a documented rare exception | Cameron, 2026-11-14 (review of `audit/phase0_orientation.md`); `CLAUDE.md` section 3 ("Data-driven") and section 6 ("No design number lives in a script") |
| INV-28 | No value becomes NaN, infinite or negative where the data type is a count (hand, deck, energy, seats) | **Proposed.** General safety |

## D. Decisions recorded at the freeze

Cameron's instruction was to proceed with my recommendations. These are the recommendations I applied.

| # | Decision | Recommendation applied | Why |
|---|---|---|---|
| 1 | The proposed rows (BAL-04 upper edge, BAL-05 to BAL-07, BAL-15 to BAL-18, BAL-20, all of section B, INV-26, INV-28) | **Accepted as written.** They stay marked proposed, so a fail against one is a prompt for a design decision, not proof of a defect | Without them several things the audit brief asks for (turns per encounter, resource curve, dominant-strategy ceiling, all technical budgets) would have no target at all |
| 2 | BAL-11 (card pick rate) and BAL-21 (run length) | **Report numbers only, no pass or fail** | No document states an intent, and inventing one would be a design decision |
| 3 | The phone assumption in section B | **Keep "3 to 5 times slower than this desktop on script work"**, and mark every section B result as a desktop proxy | No device is named anywhere in the project; the real answer needs milestone M6 |
| 4 | Political Pressure | **Balance bands apply at Standard only.** Relaxed and Harder are held only to the ordering in BAL-20 | The documents describe Standard values (`design/GAME_SYSTEMS.md:3`) |
| 5 | Conflicts between design documents | **`design/GAME_SYSTEMS.md` is the source**; the conflicts are listed as findings | It says it was written from the code and that the data wins (`design/GAME_SYSTEMS.md:3`) |
| 6 | New at review: where values live | **Added INV-29** from Cameron's stated intent that values come from the workbook | Stated in review, before the freeze |
