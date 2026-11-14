# Phase 8: Improvements and compatible mechanics

Separate from bug fixes. Every item is tied to a finding or to a hook in the current design. These are proposals for Cameron: content and design decisions are his, and nothing here has been built or tested.

## A. Improvements to existing mechanics

| # | Improvement | Tied to | What changes | Hooks into | New data fields | Cost | Balance risk |
|---|---|---|---|---|---|---|---|
| I-1 | **Make dues bite.** Unpaid dues lock one thing at a time: first backings, then new level starts above Tier 0, then Office purchases | F-03 (`audit/conformance.md`) | A visible consequence that grows with debt, instead of a Party support hit the player recovers in a week | `PartyDues.gd`, `GameState.go_home`, Office buttons | Balance rows: lock thresholds in debt | M | High: reshapes the economy; re-run strategy sweeps |
| I-2 | **Let Reputation matter below 80.** Add smaller steps (for example +2 start at 50, +5 at 80) | F-12 | The press-room bonus is reachable | `MetaRules.press_start_adjustment`, `Sanban` | A bands table replacing the single 80 / 20 rule | S | Low |
| I-3 | **Scale rewards with difficulty.** Pay by the room's measured clear chance, not a flat delta | F-05 | Hard rooms pay more per hour | `Stages` win deltas | A `Reward Tier` column | M | Medium |
| I-4 | **Give Media Ambush and caucus rooms a kit gain.** More room-specific starts or an item that helps there | F-09, F-10 | Fixes the one family where the full kit does worse | Items, `Modifiers` | none (rows) | S | Medium |
| I-5 | **Show seeds in bug reports.** Put the battle seed and seated opponents on the result panel (debug build) and in a log | F-17 | Reproducible reports | `BattleSetup`, `OutcomePresenter` | none | S | None |
| I-6 | **A validation pass for hand-written files** until W-1 moves them to the workbook | F-01 | Same checks the workbook gets | `DataDB.gd` | none | S | None |
| I-7 | **Fix the benchmark itself.** Judge loss causes per room type, not per family | F-27 | BAL-07 stops failing for the wrong reason | audit tools only | none | S | None |
| I-8 | **Rebuild `tools/rubric_playtest.gd` D1/D3** to expect the party-tier lean | F-15 | The rubric returns to 66 of 66 | tools | none | S | None |

## B. New mechanics compatible with the current architecture

### B1. Current phase (data rows or a small code change on existing hooks)

| # | Mechanic | What it adds | Existing systems it hooks into | New data fields | Cost | Balance risk |
|---|---|---|---|---|---|---|
| N-1 | **Election strength unlocks** (already an open decision, `CLAUDE.md` section 9). Thresholds at 25, 50, 75 unlock a free Town Hall, a campaign event, a free backing slot | Gives the one meter that currently fires nothing a job | `ElectionStrength.gd`, `EventEngine`, `SpecialLevels`, the Office | an `Election Unlocks` tab: threshold, effect type, target | M | Medium |
| N-2 | **Opponent weaknesses.** A per-opponent suit multiplier on top of room affinity | Makes the draw of who is seated matter; counters the "greedy plays the same cards" pattern | `Opponents`, `BattleEngine.affinity_for` | `weak_suit`, `strong_suit` columns | M | Medium |
| N-3 | **Card training.** Spend Training Sessions to improve an owned card by one point (an existing `card_training_looks` setting counts looks) | A way to use the nine never-played cards and the 50 to 61 owned cards beyond the first 15 | Rhetoric Training, `Ledger`, deck builder | `train_cost`, `train_bonus` per card tier | M | Medium |
| N-4 | **Room modifiers.** A daily condition on a room ("an engaged audience": +1 strong grade; "a long day": −1 energy) | Variety without new rooms; helps the 37 rooms at 100% | `BattleSetup`, `Stages`, `Affinity` | a `Room Modifiers` tab | M | Medium |
| N-5 | **A per-turn save in battle** | Mobile resilience (E-04); not a mechanic the player sees | `BattleEngine.checkpoint`, `SaveManager` | none | M | Low |

### B2. Future phases

| # | Mechanic | What it adds | Hooks into | New data | Cost | Balance risk |
|---|---|---|---|---|---|---|
| N-6 | **Coalition building.** Party Allies (a stakeholder system that already exists) can lend a seat or a card for one vote | A use for parties other than your own beyond the influence gate | `PartyAllies.gd`, `VoteInfluence`, Floor Vote | ally rows with cost and cap | L | High |
| N-7 | **Seasonal campaigns.** Election strength drives a once-a-year campaign level chain | Gives the 30-week horizon an arc; fits the existing season data | `Seasons.gd`, `SpecialLevels`, N-1 | campaign level rows | L | Medium |
| N-8 | **Daily or weekly challenge seeds** | Replayable runs once seating can be seeded (C-8) | `BattleSetup` seed | a seed table | M | Low |
| N-9 | **Press-cycle meter.** National awareness reacts to a rolling window of results, not a running total | Makes awareness a live meter instead of one that saturates (F-13) | `AwarenessEffects`, ticker | window length Balance row | M | Medium |
| N-10 | **Staff delegation to battles.** A hired staff member plays one card a turn under a rule | A late-game convenience that spends staff rank | `StaffDelegation.gd` | per-role delegation table | L | High |

Every new data field above would be a new workbook tab or column, which needs Cameron's approval first (`CLAUDE.md` section 12).
