# Phase 3: Outcome dynamics

What each mechanic and key combination produces over time. Labels: **Verified** (measured in Phase 4, numbers in `audit/testing.md`), **Inferred** (read from code or data), **Assumed**. Simulation samples: 80,150 seeded fights with the audit harness; 210 seeded 30-week runs with the project's strategy bot; 4 unseeded 80-level runs with the project's playtest bot.

## 1. Feedback loops

| # | Loop | Kind | How it works | Evidence | Label |
|---|---|---|---|---|---|
| L-01 | Win -> rewards -> stronger kit -> win | Reinforcing | Stage and level wins pay Funds and XP; XP buys cards (Rhetoric Training), Funds buy backings and items; backings and items raise stage starts | `design/GAME_SYSTEMS.md:98-102`, `:124-125`; `scripts/BattleSetup.gd:666-680` | Inferred; kit gain measured: starter 78.7% to full 94.3% overall |
| L-02 | Party support -> dues | Balancing | Dues rise 10,000 per 15 points of Party support above 40, and by 10% of the week's earnings | `data/balance.json` `dues_*`; `scripts/rules/PartyDues.gd:34-47` | Inferred |
| L-03 | **Unpaid dues -> Party support** | Meant to balance; **does not bind** | A short week costs 10 Party support. In all 12 baseline runs Party support stood at 90 at 86% of week ends while dues went unpaid for 24 to 26 of 30 weeks and 1.41M to 1.76M was owed | `design/GAME_SYSTEMS.md:170`; `audit/tests/results/strategy_protagonists.jsonl` | **Verified** |
| L-04 | Party support > 75 -> free backing M09 -> easier wins -> more Party support | Reinforcing | The free backing switches on above 75 and wins add Party support | `design/GAME_SYSTEMS.md:179` | Inferred. Party support reached 90 by week 2 to 10 in every baseline run (Verified) |
| L-05 | Standing -> smaller gains | Balancing | Gains are multiplied by 1.0 below 40, 0.6 below 60, 0.4 above; penalties by 1.5 above 60 | `data/booster_standing.json` `gain_bands`, `loss_bands`; `scripts/rules/BoosterStanding.gd:44` | Inferred. No organization sat at its ceiling for 90% of a run; the highest was 48% of level-ends (Verified, 4 runs) |
| L-06 | Decay toward the start | Balancing | Each week end, organizations settle toward their start by 5% x 2.5 = 12.5% of the distance (plus 1 point x 2.5 if untouched); Constituency support by 10% x 2.5 = 25%; Reputation by 6% x 2.5 = 15% | `data/sanban.json`; `data/balance.json` `week_decay_multiplier`; `design/GAME_SYSTEMS.md:167` | Inferred |
| L-07 | Reputation decays faster than it is earned | Balancing, strong | Reputation ended a 30-week baseline run between 11 and 44 (start 5 to 25); it never reached the 80 that gives a press-room head start | `strategy_protagonists.jsonl` final `rep` | **Verified** |
| L-08 | Low Constituency support -> forced Town Hall -> win restores it | Balancing (rescue) | At 15 or below a Town Hall is forced in after a countdown of 15 units | `design/GAME_SYSTEMS.md:176` | Inferred; the lowest Constituency support seen at a week end across all 210 runs was 1 |
| L-09 | Party support 0 -> funding freeze -> cannot buy -> lose more | Reinforcing downward | Stage and level Funds stop at Party support 0 | `design/GAME_SYSTEMS.md:178` | Inferred. The random-card bot sits here: Party support 0 to 1, 146 to 175 wins of about 470 stages (Verified) |
| L-10 | Gaffes -> awareness loss -> weaker starts and week-end penalties | Reinforcing downward, slow | Every 65 leftover gaffes cost 1 District point, every 35 cost 1 National point | `design/GAME_SYSTEMS.md:113`, `:116` | Inferred. In baseline runs National awareness still reached 100 by week 9 to 15 and District by week 18 to 24 (Verified), so the loss is far smaller than the gain |
| L-11 | Awareness -> dues relief and start bonuses | Reinforcing | National ≥ 80 takes 50,000 off base dues; ≥ 65 starts press rooms +5 | `design/GAME_SYSTEMS.md:116` | Inferred |
| L-12 | Standing -> sponsored bill -> law -> standing | Reinforcing | At 50 and 70 an organization asks for a bill; passing it pays standing and law effects | `design/GAME_SYSTEMS.md:206` | Inferred. Baseline run example: 13 accepted, 4 passed, 9 failed (Verified, one run) |
| L-13 | Election strength follows everything, feeds nothing | Open loop | Moves at most +2.5 a week; reached 69 to 74 at week 30 (the cap on speed, 2.5 x 30 = 75, is what limits it) | `scripts/rules/ElectionStrength.gd:77`; baseline runs | **Verified** |
| L-14 | Deck fixed at 15 -> every new card displaces one | Balancing | New cards do not grow the deck | `design/GAME_SYSTEMS.md:122` | Inferred |

## 2. Resource flows

| Resource | Sources | Sinks | Measured behavior (baseline bot, 30 weeks, 12 runs) | Label |
|---|---|---|---|---|
| Funds | Stage and level wins, events, laws | Purchases, dues, drafting | Held Funds are 0 at most week ends: the bot spends everything, then owes dues. Earnings of 180,000 to 280,000 a week against a 100,000 cap | Verified |
| Dues | n/a | Funds each week end | About 108,000 to 115,000 a week by week 4 at these earnings, above the 100,000 starting cap. At least eight strategies that set dues aside paid in 100% of weeks; the baseline paid in 4.6% | Verified |
| XP | Wins, laws | Training, unlocks, staff, items | 35,029 earned in total (median); 104 to 187 in hand at week 30. Spent as fast as earned | Verified |
| Party support | Wins, laws, votes | Dues penalty, whipping, votes against party | At 100 for 62% of level-ends (playtest bot, 4 runs); snaps to 90 after each unpaid week | Verified |
| Constituency support | Wins, events | Losses, decay 25% of distance a week | Ends at 61 to 84 | Verified |
| Reputation | Wins, kept promises | Losses, broken promises, decay 15% a week | Ends at 11 to 44 | Verified |
| Organization standing | Answers, visitors, laws, promises | Decay 12.5% a week, neglect, weak answers | 15 to 21 organizations "on side" by mid-run | Verified |
| Hours | 40 a week (+8 weekend) | Stages (1 to 4 each), events, promises | 3.7 levels and 14.6 stages a week | Verified |
| Awareness | Wins, bills, hosting | Leftover gaffes | National 100 by week 9 to 15; District 100 by week 18 to 24 | Verified |

## 3. Scaling curves

| Curve | Shape | Numbers | Evidence | Label |
|---|---|---|---|---|
| Card power per energy by tier | **Not monotonic** | Tier 0: 2.92; Tier 1: 4.44; Tier 2: 3.10; Tier 3: 2.97 (support + guard + 1.5 draw − 1.5 gaffe, per energy) | `audit/tests/results/analysis.json` `BAL-10` | Verified (static). Tier 1 includes the discard cards, whose discard price this measure ignores |
| Suit power | Uneven | Appeal 2.24 to Duplicitous 4.13 per energy, a spread of 1.84x | same | Verified (static) |
| Level reward per hour by tier | Rising | Funds per hour: Tier 0 8,000, Tier 1 10,491, Tier 2 12,857; XP per hour 25.0, 27.2, 31.4 (medians) | `analysis.json` `BAL-15` | Verified (static) |
| Reward against difficulty | **Inverted** | The hardest third of levels (starter clear chance 0.18) pays 10,625 Funds and 25.0 XP an hour; the easiest third (0.70) pays 12,667 and 30.0 | `analysis.json` `BAL-14` | Verified |
| Dues against Party support | Step, linear | +10,000 per 15 points above 40: at most +40,000 at 100 | `data/balance.json` | Inferred |
| Overdue dues penalty | Exponential in debt, on standing only | Standing penalties x 1.5 per full 100,000 owed; no ceiling in the data | `dues_overdue_scale_factor` 1.5, `dues_overdue_scale_per` 100000; `scripts/rules/PartyDues.gd:55` | Inferred |
| Standing gain | Diminishing | x1.0, x0.6, x0.4 by band | `data/booster_standing.json` | Inferred |
| Election strength | Linear, speed-capped | +2.5 a week at Standard (measured max +2.5, min −1.5 over 6,120 week steps) | strategy runs | Verified |
| Stage difficulty by Political Pressure | Monotonic | Greedy starter win rate: Relaxed 84.6%, Standard 76.8%, Harder 66.3% (same seeds, n = 5,725 each) | `analysis.json` `BAL-20` | Verified |
| Skill | Very steep | Random policy 6.8% against greedy 78.7% on the starter kit | `analysis.json` `BAL-05` | Verified |
| Survival line | Random walk up | Rises 0, 1, 2 or 3 a turn (295 / 61 / 72 / 72 of 500 turn ends; the zeros include capped and final turns) | `audit/tests/results/invariants.json` `INV-22` | Verified |

## 4. Turn order and trigger resolution

**Inside a turn** (`scripts/rules/BattleEngine.gd`):

1. Intent shown; energy refills; hand draws to size (`:558-665`, the end-of-turn tail prepares the next turn).
2. Each card: cost paid, effect resolved (`CardResolver.resolve`, `:42` of that file), question answered (`:1337`), then **the outcome check runs after every card** (`:865`).
3. In that check the gaffe meter comes first (`:871`), then the threshold (`:947`). **Verified:** in 25 of 25 seeded cases where one card both filled the meter and crossed the threshold, the stage was lost. In 521 of 521 threshold wins by a card, the opponent's support did not move afterwards.
4. End of turn: the hand is discarded (not in a press conference), the opponent's intent resolves against banked guard, an unanswered question counts as declined, a lobbyist's interest cools, the survival line may rise, then the turn limit is checked (`:558-665`, `:1010`).

**After a stage** (`scripts/autoload/GameState.gd:2460`, order from `design/GAME_SYSTEMS.md:158`): clock and calendar advance; win or loss deltas; question tallies move organizations (capped); instant-win penalties; overdue promises break (not during a level); timed backings expire; crisis triggers are checked.

**After a level** (`GameState.gd:4435`; `design/GAME_SYSTEMS.md:160`): level rewards; "every level" laws pay; purchase limits reset; level buffs end; cooldown starts; a due special level is forced in.

**At the week end** (`GameState.gd:2046`; `design/GAME_SYSTEMS.md:162-168`): dues; awareness effects; election strength; decay (neglect, organization percent, meta); new week; random event roll.

**Interactions worth knowing**

| # | Interaction | Result | Evidence | Label |
|---|---|---|---|---|
| T-01 | Gaffe and threshold on the same card | Loss | above | Verified |
| T-02 | Decay runs after dues and awareness effects in the same week end | A week-end awareness penalty to standing is then also decayed toward the start in the same step | order in `design/GAME_SYSTEMS.md:162-168` | Inferred |
| T-03 | Promise deadlines pause during a level, crisis countdowns do not | A long level can let a crisis level fall due while promises wait | `design/GAME_SYSTEMS.md:90`, `:176` | Inferred |
| T-04 | A forced crisis stage adds hours mid-level | A level can run past Friday; those hours spill away | `design/GAME_SYSTEMS.md:86` | Inferred |
| T-05 | Whip floor 30 and the Steering Committee trigger below 25 (on blended party opinion) | Whipping alone cannot trip the trigger through Party support, but the blend with organization standing can sit lower | `design/GAME_SYSTEMS.md:101`, `:177` | Inferred |
| T-06 | Unpaid dues penalty (−10) against weekly Party support gains | Gains win: Party support returns to 100 inside the next week | L-03 | Verified |
| T-07 | Reputation start bonus needs 80; Reputation decays 15% of its distance a week | The bonus is effectively out of reach for the baseline bot | L-07 | Verified |

## 5. Randomness and seeding

| Source | Used for | Seeded? | Evidence | Label |
|---|---|---|---|---|
| `BattleEngine._rng` | Shuffles, draws, intent rolls, conversion costs, survival line, question order | Yes, from `config["seed"]`; otherwise `randi()` | `scripts/rules/BattleEngine.gd:51`, `:148` | **Verified:** the same config and seed gave the same fight move for move in 14 of 14 harness runs, under different global seeds; a different seed gave a different fight |
| `BattleSetup` people draw | Which opponents are seated | **No** (`randomize()` each call) | `scripts/BattleSetup.gd:352-355` | **Verified:** two set-ups under the same global seed seated different opponents in 14 of 14 harness runs |
| `Ledger.opening_deck` | The 15-card opening deck | Optional seed; the game passes none | `scripts/rules/Ledger.gd:464-493`; `scripts/autoload/GameState.gd:773` (calls it with no seed) | Inferred |
| `BarModel._roll_percent` fallback | Conversion cost when no roller is handed in | No | `scripts/rules/BarModel.gd:229-239` | Inferred (the engine hands in its own roller) |
| `GameState` local generator | A roll at `:1613` | No | `scripts/autoload/GameState.gd:1613-1614` | Inferred |
| `PatronLevel` | Sponsored-level composition | No by default | `scripts/PatronLevel.gd:115-116` | Inferred |
| Global `randi()` / `randf()` | Events, level bonus ranges, visitor draws and others | Only if something calls `seed()`; the game never does | `tools/strategy_playtest.gd:146-148` is the only caller found | Inferred |
| Presentation (`TickerPresenter`, `TradeScreen` flavor, `StageTransitionScreen`) | Which line is shown | No | `scripts/ui/TickerPresenter.gd:47`; `scripts/ui/TradeScreen.gd:147-148`; `scripts/ui/StageTransitionScreen.gd:57` | Inferred |

**Consequence:** a battle can be replayed exactly from its config and seed, but a whole run cannot, and the save stores no seed. Whether a reloaded stage keeps the same seated opponents and shuffle was **not tested** (the saved level snapshot may carry the seating). No design document says whether replays should be reproducible (a gap).
