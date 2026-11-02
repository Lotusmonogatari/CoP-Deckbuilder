# Player-chosen difficulty: "Campaign Pressure" (proposal, 2026-11-02)

Status: a draft for Cameron. Nothing here is built. Every number is a first draft to calibrate with the strategy bot.

## Executive summary

| Question | Proposal |
|---|---|
| What is it? | A setting chosen at New Game: Relaxed, Standard (today) and Harder (Cameron's choice, 2026-11-02). It is separate from the protagonist's opening difficulty, which stays as it is. |
| What does it change? | Nine levers, each a Balance-style row: fight margins, gaffe room, income, dues, standing decay, promises, item prices and the weekly Election Strength gain. Card values, energy and hand size never change, so cards feel the same. |
| Why those levers? | The 168-run strategy playtest showed what actually pressures a player: items (worth about 10 win-rate points), Funds and dues, gaffes, and standing decay. |
| What does the player get? | Harder pays 15% less reward (Funds and XP from stage wins) and shows in the record. Nothing is locked behind difficulty. |
| Can it change mid-run? | It can be raised at any time and not lowered. |
| How do we tune it? | Calibrate to bot stage win rates of about 93%, 86% (today) and 72%, using the existing strategy runner. |

## Where it sits

The four protagonists already carry a difficulty tag (PC01 Easy to PC04 Very Hard) that only changes opening Constituency support, Reputation, Funds, Party support and XP. Campaign Pressure sits on top of that, so PC04 on Harder is the hardest possible run and PC01 on Relaxed the gentlest. The New Game screen would show both ("Very Hard start, Harder pressure").

## What each level adjusts (first-draft numbers)

| # | Lever (existing Balance row or stage column) | Relaxed | Standard | Harder | What it does and why |
|---|---|---|---|---|---|
| 1 | Opponent starting support, as a share of the win threshold (`opp_start`, `win_threshold`) | -3 points | 0 | +3 | Each fight is closer. The direct, visible difficulty. |
| 2 | Gaffe room (`gaffe_limit`, minimum 2) | +1 | 0 | -1 | A single slip ends a stage sooner. |
| 3 | Leftover-gaffe awareness penalty | 0.5x | 1x | 1.5x | Awareness is the hidden skill lever. Careful play reached 61 Election Strength against about 40 for careless play. |
| 4 | Reward payout: Funds and XP from stage wins (`win_delta_yen`, `win_delta_xp`) | 1.15x | 1x | 0.85x | Tighter money. Items are the main Funds sink and removing them cost about 10 win-rate points. |
| 5 | Party dues: earnings share (`dues_reward_percent`) and holiday | 15%, 3-week holiday | 30%, 3-week holiday | 35%, no holiday | Dues bite harder. The holiday also fixes the Party-0 spiral that hit about 5% of careless runs. |
| 6 | Standing decay (`week_decay_multiplier`) | 2.0 | 2.5 | 3.0 | Organizations drift away faster, so backing needs upkeep. |
| 7 | Promises: deadline hours and broken penalty (`promise_default_deadline_hours`, `promise_broken_standing`) | 1.5x time | 48 h, -5 | 0.75x time, -7 | Promises become real commitments. |
| 8 | Item and training prices (`cost_yen`, `cost_xp`, `card_training_looks`) | 0.85x, 3 looks | 1x, 3 looks | 1.15x, 3 looks | Fewer cheap fixes for a bad fight. |
| 9 | Election Strength weekly gain and fall (`election_gain_per_week`, `election_fall_per_week`) | 3.0 / 1.0 | 2.5 / 1.5 | 2.0 / 2.0 | The long-term score grows more slowly. |

Deliberately not touched: card numbers, energy, hand size, deck size, turn limits, opponent intent patterns, canon (party seats, the 51-seat majority) and all text. That keeps the game recognizably the same game.

## Reward payout

Cameron's answer (2026-11-02): "They get 15% less reward payout" on the harder tier. I read this as the Harder tier paying out 15% less (Funds and XP from stage wins, which is lever 4 above), not as an extra bonus. There is no XP bonus. The tier is shown in Your Record. **Please confirm that reading**: it means Harder has no upside beyond the challenge itself.

## Rules of the setting

| Rule | Proposal |
|---|---|
| Choosing | New Game screen, below the protagonist. Default Standard. |
| Changing during a run | Raise only (Cameron's choice): Relaxed to Standard to Harder, never lowered. |
| Saved | One value in the save file. An old save loads as Standard. |
| Shown | A one-line label in Your Record, and in the level briefing next to "If you lose". |
| Data | A new Difficulty workbook tab: one row per lever, one column per tier. The code reads multipliers, so no number lives in a script. |

## How it would be built

| Step | Work | Size |
|---|---|---|
| 1 | Difficulty tab in the workbook, exported to `data/difficulty.json`, with header notes | small |
| 2 | `scripts/rules/Difficulty.gd`, pure and UI-free: look up a lever for the current tier, with tests | about 80 lines |
| 3 | Apply it at about nine places: stage setup, gaffe-to-awareness, stage rewards, dues, week decay, promises, item and training prices, Election Strength step | about 100 lines |
| 4 | New Game selector, Administration raise, Your Record line, Text rows | about 80 lines |
| 5 | Strategy bot reads `PLAYTEST_DIFFICULTY`; calibrate the four tiers to the target win rates | small |
| 6 | Full `tools/verify.sh`, then merge | |

This is more than 150 lines, so I would build it only after you approve the plan.

## Decisions made and still open

| # | Choice | Answer |
|---|---|---|
| 1 | Tiers | Relaxed, Standard, Harder |
| 2 | Change during a run | Raise only |
| 3 | Reward for harder play | 15% less payout on Harder; confirm this is meant as the difficulty itself and not a bonus |
| 4 | Still open | Whether Relaxed should also pay 15% more, as the table assumes |
