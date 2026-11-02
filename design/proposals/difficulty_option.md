# Player-chosen difficulty: "Campaign Pressure" (proposal, 2026-11-02)

Status: a draft for Cameron. Nothing here is built. Every number is a first draft to calibrate with the strategy bot.

## Executive summary

| Question | Proposal |
|---|---|
| What is it? | A setting chosen at New Game: Relaxed, Standard (today), Hard, Brutal. It is separate from the protagonist's opening difficulty, which stays as it is. |
| What does it change? | Eight levers, each a Balance-style row: fight margins, gaffe room, income, dues, standing decay, promises, item prices and the weekly Election Strength gain. Card values, energy and hand size never change, so cards feel the same. |
| Why those levers? | The 168-run strategy playtest showed what actually pressures a player: items (worth about 10 win-rate points), Funds and dues, gaffes, and standing decay. |
| What does the player get? | Hard and Brutal give an XP bonus and a record line. Nothing is locked behind difficulty. |
| Can it change mid-run? | It can be raised at any time and not lowered. |
| How do we tune it? | Calibrate to bot stage win rates of about 93%, 86% (today), 72% and 58%, using the existing strategy runner. |

## Where it sits

The four protagonists already carry a difficulty tag (PC01 Easy to PC04 Very Hard) that only changes opening Constituency support, Reputation, Funds, Party support and XP. Campaign Pressure sits on top of that, so PC04 on Brutal is the hardest possible run and PC01 on Relaxed the gentlest. The New Game screen would show both ("Very Hard start, Hard pressure").

## What each level adjusts (first-draft numbers)

| # | Lever (existing Balance row or stage column) | Relaxed | Standard | Hard | Brutal | What it does and why |
|---|---|---|---|---|---|---|
| 1 | Opponent starting support, as a share of the win threshold (`opp_start`, `win_threshold`) | -3 points | 0 | +3 | +6 | Each fight is closer. The direct, visible difficulty. |
| 2 | Gaffe room (`gaffe_limit`, minimum 2) | +1 | 0 | -1 | -1 | A single slip ends a stage sooner. |
| 3 | Leftover-gaffe awareness penalty | 0.5x | 1x | 1.5x | 2x | Awareness is the hidden skill lever. Careful play reached 61 Election Strength against about 40 for careless play. |
| 4 | Funds from stage wins (`win_delta_yen`) | 1.15x | 1x | 0.85x | 0.7x | Tighter money. Items are the main Funds sink and removing them cost about 10 win-rate points. |
| 5 | Party dues: earnings share (`dues_reward_percent`) and holiday | 15%, 3-week holiday | 30%, 3-week holiday | 35%, no holiday | 40%, no holiday | Dues bite harder. The holiday also fixes the Party-0 spiral that hit about 5% of careless runs. |
| 6 | Standing decay (`week_decay_multiplier`) | 2.0 | 2.5 | 3.0 | 3.5 | Organizations drift away faster, so backing needs upkeep. |
| 7 | Promises: deadline hours and broken penalty (`promise_default_deadline_hours`, `promise_broken_standing`) | 1.5x time | 48 h, -5 | 0.75x time, -7 | 0.5x time, -10 | Promises become real commitments. |
| 8 | Item and training prices (`cost_yen`, `cost_xp`, `card_training_looks`) | 0.85x, 3 looks | 1x, 3 looks | 1.15x, 3 looks | 1.3x, 2 looks | Fewer cheap fixes for a bad fight. |
| 9 | Election Strength weekly gain and fall (`election_gain_per_week`, `election_fall_per_week`) | 3.0 / 1.0 | 2.5 / 1.5 | 2.0 / 2.0 | 1.5 / 2.5 | The long-term score grows more slowly. |

Deliberately not touched: card numbers, energy, hand size, deck size, turn limits, opponent intent patterns, canon (party seats, the 51-seat majority) and all text. That keeps the game recognizably the same game.

## Rewards for choosing harder

| Tier | XP from stages | Record |
|---|---|---|
| Hard | +10% | "Hard" shown in Your Record and on the New Game save slot |
| Brutal | +25% | "Brutal" shown, plus a line when a level is cleared on it |

No unlocks or cosmetics are gated by difficulty.

## Rules of the setting

| Rule | Proposal |
|---|---|
| Choosing | New Game screen, below the protagonist. Default Standard. |
| Changing during a run | Raise it any time in Administration; never lower it. This stops a player picking Brutal for the XP and dropping it before a hard stage. |
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

## Open choices for Cameron

| # | Choice | Options | My pick |
|---|---|---|---|
| 1 | How many tiers | Three (Standard, Hard, Brutal) or four with Relaxed | Four |
| 2 | Change during a run | Locked; raise only; free | Raise only |
| 3 | Reward for harder play | None; XP bonus and record line; also cosmetics | XP bonus and record line |
