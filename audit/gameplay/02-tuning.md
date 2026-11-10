# Phase 2: Tuning values

Every gameplay number I could find, where it lives, and where it is inconsistent. The full Balance tab (248 rows with the scripts that read each) is in `tuning_balance.md`; the extraction script is `tuning_extract.py` (both in this folder). Finding format:
ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

## Where numbers live

| Home | How many | Edited by | Notes |
|---|---|---|---|
| Balance tab, `data/balance.json` | 248 rows (54 prefix groups: patron 31, difficulty 26, trade 22, election 14, party 12, dues 12, hosted 9, mp 8, awareness 8, research 8, starter 7, stance 7, whip 7, ...) | Cameron, in the workbook | Read as `DataDB.balance.get("key", default)` or `Levers.whole(...)`. Not "exported" in the Godot sense: every value is data, none is an `@export` or a `.tres`. |
| `data/rules.json` | 13 switches (`turn_limit_outcome` loss, `pass_energy_penalty` 1, `guard_cap` 5, `funds_starting_cap` 100,000, `card_training_looks` 3, ...) | Hand-written, validated at startup | Each carries its question and allowed options. |
| `data/sanban.json` | the four meta numbers' range, start, decay (Constituency support decay 10%, Reputation 6%, Funds cap 1,000,000) | Workbook | |
| `data/booster_standing.json`, `party_standing.json`, `vote_influence_triggers.json`, `awareness_effects.json`, `standing_links.json` | standing bands, influence gates, awareness effects | Hand-written / workbook | |
| Per-row tabs | 289 stages x about 50 columns, 114 levels, 70 cards, 53 backings, 35 shop items, 21 staff, 56 events | Workbook | Rewards, hours, energy, hand size, gaffe limit, turn limit, prices, cooldowns live here. |
| Hard-coded in scripts | about 225 numeric literals in rules and state code (many are clamps, 0/100 bounds and calendar math) | A programmer | See T-01, T-07. |

## Core battle numbers (all 230 combat stages)

| Value | Home | Min | Median | Mean | Max | Note |
|---|---|---|---|---|---|---|
| Energy per turn | Stages tab `energy_per_turn` | 3 | 3 | 3.7 | 26 | 26 is the Committee of the Cabinet (ST18), a one-time energy *pool*; 21 stages use pool energy (8 to 26 total) |
| Hand size | Stages tab | 3 | 5 | 5.0 | 6 | |
| Gaffe limit | Stages tab (+/-1 by Campaign Pressure) | 2 | 5 | 5.3 | 10 | |
| Turn limit | Stages tab | 5 | 10 | 9.6 | 17 | A turn-limit expiry is a loss (`rules.json`) |
| Bar maximum / win threshold | Stages tab | 35 / 20 | 100 / 55 | 91.7 / 57.8 | 101 / 90 | Win % 0.43 to 0.90 |
| Player start / opponent start | Stages tab | 1 / 10 | 20 / 40 | 22.2 / 33.0 | 60 / 55 | Pressure shifts opponent start by -6 / +6 |
| Guard cap | `rules.json` | 5 | | | | One value for both sides |
| Opponent default intent | `rules.json` | attack 1-6, gain 1-6, block 0-2 | | | | Used when an opponent has no pattern |
| Win-over cost | Balance `win_over_*` | undecided 1; opposed 1 (60%), 2 (30%), 3 (10%) | | | | Seeded per battle |
| Question multipliers | Balance | strong 1.3, weak 0.7 | | | | |
| Pass penalty | `rules.json` | 1 energy | | | | Plus a declined question |
| Hours per stage | Stages tab `time_units` | 1 | 4 | 3.2 | 4 | |

## Cards (70)

| Tier | Cards | Mean cost | Mean support (self + opponent) | Support per energy | Notes |
|---|---|---|---|---|---|
| 0 | 6 | 1.50 | 3.8 | 2.6 | Opening deck draws 4 of these |
| 1 | 17 | 1.06 | 4.0 | 3.8 | Includes the discard cards C63, C65, C67, C69 (9 to 11 support for 1 energy) |
| 2 | 37 | 1.76 | 5.3 | 3.0 | |
| 3 | 10 | 2.70 | 8.4 | 3.1 | Cost 3 for 6 to 11 support |

Costs: 1 card at 0, 28 at 1, 32 at 2, 9 at 3. Types: Gain 30, Attack 27, Defend 9, Buff 4. Suits: 13 each of Emotional, Data Driven, Divisive, Duplicitous; 9 each of Earnest and Appeal. Cameron has decided to leave the discard cards strong (change log 2026-11-03).

## Economy

| System | Value | Home |
|---|---|---|
| Win reward per combat stage | XP median 70 (mean 64); Funds median 20,000円 (mean 29,542); Constituency support median 1; Reputation median 1; Party support median 2 | Stages tab `win_delta_*` |
| Loss charge per combat stage | Constituency support -5 to 0, Reputation -3 to 0, Party support -10 to 0; **XP +0 to +20 (positive)**; **Funds +1,000 on 6 stages** | Stages tab `loss_delta_*` (see T-06) |
| Level rewards | bonus ranges and per-organization deltas on the level row | Levels tab |
| Campaign Pressure | win Funds and XP x1.15 / 1.0 / 0.85; opponent start -6 / 0 / +6; gaffe limit +1 / 0 / -1; decay x2 / 2.5 / 3; dues share 10 / 15 / 20% | Balance `difficulty_*` (26 rows) |
| Rhetoric Training | Tier 1 / 2 / 3: 250 / 500 / 1,000 XP | Shop SH09-SH11 `cost_xp` |
| Stage consumables | coffee 10,000円 (+1 energy), tea (+1 gaffe cap), Paperwork (+1 draw), Wristwatch (+1 turn), Dear Colleague Letter (+1 guard); XP versions 50 to 100 XP, capped 2 to 5 | Shop SH04-SH08, SH14-SH18 |
| Staff, deck, cap | Staff Training Session 250 XP; Funds Cap Petition 100 XP (+100,000 cap); Binder 200 XP; Expanded Staff Office 150 XP + 300,000円 + 15 Reputation | Shop, Balance |
| Level unlock (XP, by researcher rank vacant / 0 / 1 / 2) | Tier 0 about 11 / 8 / 6 / 1; Tier 1 about 110 / 82 / 54 / 30; Tier 2 about 215 / 170 / 125 / 66 | Levels tab |
| Cooldown (hidden clock units) | Tier 0 median 24; Tier 1 and 2: **5,994** on most rows (see T-04, and the one-time loss rule in Phase 5) | Levels tab |
| Party dues (weekly) | 50,000円 base + 50,000円 per full 15 Party support above 40 + 15% of the week's Funds earned; 3 holiday weeks at Relaxed only | Balance `dues_*` |
| Dues shortfall | Party support -10, Party HQ standing -20, other parties -5, Selection Committee -5, x1.5 per 100,000円 owed | Balance `dues_overdue_*` |
| Funds cap | 100,000円 + 100,000円 per petition; ceiling 1,000,000円 | `rules.json`, `sanban.json` |
| Weekly decay | x2.5 at Standard on neglect drift, per-organization 5%, Constituency support 10% of the distance to start, Reputation 6% | `week_decay_multiplier`, `sanban.json`, `booster_standing.json` |
| Promises | deadline 48 hours (x1.5 / 1 / 0.75), kept +2 standing, broken -5 standing and -2 Reputation | Balance `promise_*` |
| Drafting a bill | 350 XP + 300,000円 (200,000 / 400,000 by pressure); cooldown 90 hours; extra visit 50 XP | Balance `draft_bill_*` |
| Research briefing | 2 hours, 50 XP; passive 1/2/3 points, active 1/2/3% | Balance `research_assistant_*` |

## Time

| Value | Home |
|---|---|
| Workday 8 hours; work week 5 days pooled as 40 hours; weekend two 4-hour days (8 hours) | Balance `workday_hours`, `weekend_*` |
| Start date 2018-10-01 | Balance `calendar_start_*` |
| Stage hours 1 to 4; longest level 35 hours | Stages tab; `GameState.level_hours` |

## Votes and standing

| Value | Home |
|---|---|
| 101 seats, 51 needed, supermajority 67% | Data (party positions sum to 101); `FloorVoteEngine.gd:204` default 67; Balance `supermajority_percent_of_house` |
| Whip: 10 Party support each, x3 against party, max 3, floor 30, backer discount 1 at standing 65, never under 5 | Balance `whip_*` |
| Influence gate default threshold 85, swing resistance default 85 | Balance `vote_influence_default_threshold`, `vote_swing_resistance_default`; gate rows in `vote_influence_triggers.json` |
| Organization standing: start 30; +5 please, -3 displease, -3 opposed; per-stage cap +/-10; gain factors 1.0 / 0.6 / 0.4 below 40 / 60 / above; loss factors 1.0 / 1.5 below / above 60; neglect drift 1; decay 5% | `data/booster_standing.json` |
| Party opinion blend 50 / 50 direct and stakeholder; bands at 20 / 40 / 60 / 80 | Balance `party_opinion_*` |
| Lean: standing drift 2 per win, vote 2, flip penalty 5 with 25% recovery, Party support +1 / -3 | Balance `stance_*`, `lean_*` |
| Unknown vote share 10 to 25% | Balance `vote_projection_unknown_*` (new) |

## Findings

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| T-01 | Medium | Generated bill votes (drafted and sponsored bills) | `scripts/rules/BillPositions.gd:78-96` | The formula that turns a bill's tags into each party's Aye / Nay / Abstain split is made of hard-coded constants (`0.66 + 0.30 * strength`, `0.31 + 0.22 * t`, `0.10 * (1 - strength / 0.25)`, a 0.25 cut-off). This decides whether a self-drafted bill can pass, yet none of it is in the Balance tab, so it cannot be retuned without code. | `var for_side := 0.66 + 0.30 * strength`; `yes_share = 0.31 + 0.22 * t`; `abstain_share = 0.10 * (1.0 - strength / 0.25)` | Move the six constants to Balance rows (`bill_position_*`). | S | High |
| T-02 | Low | Election strength | `scripts/rules/ElectionStrength.gd:49` | `party_share *= 0.5` is a hard-coded halving inside the score. | Line 49 | Balance row. | S | High |
| T-03 | Low | Conditional card effects | `scripts/rules/SpecialEffects.gd:96,114,170` | Audience thresholds (`>= 0.5`, step size `0.2`) are literals, so what a card "needs" cannot be tuned per card in the data. | `share / 0.2`; `if share >= 0.5` | Move to the card's `special_value` column or a Balance row. | S | Medium |
| T-04 | Low | Level availability | `data/levels.json` `cooldown` and `one_time` | 5,994 is a magic "never again" cooldown on 51 of 114 levels, and 50 of those are also marked One-Time, which already hides them for good (`Ledger.level_is_hidden`, L447). The cooldown is redundant for those 50; the 51st is worth checking. The cooldown column therefore carries two meanings (a real wait, and a stand-in for one-time). | 51 levels with `cooldown` 5994, 50 with `one_time` Yes (all bill levels, LV30 onward); `Ledger.level_cooldown_remaining` L423 | Set bill levels' cooldown to 0 and rely on One-Time, or document the sentinel. | S | High |
| T-05 | Low | Code defaults that disagree with data | 74 `balance.get("key", default)` calls | When the row is present the default never runs, but 27 rows have a default of 0 or 1 while the data holds a real value (for example `vote_swing_resistance_default` 85 in data, 70 in code in 3 places; `draft_bill_cooldown_units` 90 vs 30; `decay_interval` 0 vs 6; `image_pan_tilt_strength` -1.5 vs 2.5). A deleted or misspelled row would silently change a rule. `tests/test_balance_keys.gd` catches a missing key, not a wrong default. | `FloorVoteEngine.gd:76` `_default_resistance := 70`; `DraftBill.gd:87` default 30 | Make the default match the data, or read without a default and let the key test fail. | S | High |
| T-06 | Medium | Stage loss | `data/stages.json` `loss_delta_xp`, `loss_delta_yen`; `GameState.gd:2701` | A **lost** stage pays XP (+1 to +20, positive on 201 of 230 combat stages) and Funds (+1,000円 on 6 stages), because loss columns are added, not subtracted. Constituency support, Reputation and Party support correctly go down. If the XP is meant as consolation, it is undocumented in the briefing code comments ("a loss charges its loss_delta_* columns"); if the sign is a data-entry slip (`loss_delta_yen` +1000 beside -5 to -10 elsewhere), it is a bug. **Unverified which is intended.** Abandon Level uses the same columns. | `_apply_stage_rewards`: `last_xp_gained = MetaRules.stage_delta(paid_stage, side + "_delta_xp"); _move_xp(...)`; abandoned LV01 showed "-5 Constituency support, -3 Reputation, and 10 XP" | Confirm intent. If consolation, rename the column "Loss Consolation XP"; if not, flip the sign or zero them. | S | Medium |
| T-07 | Low | Cards | `data/cards.json` `xp_to_unlock` | Card prices exist twice: 5 / 5 / 10 / 15 XP in the card rows (Tier 0 to 3) and 250 / 500 / 1,000 XP for Training in the shop. The card column is only read when `open_card_collection` is on, which is off. The two sets are 50x apart. | `Ledger.gd:62` reads `xp_to_unlock`; `rules.json` `open_card_collection: false` | Delete or clearly label the card column; it will mislead anyone who tunes it. | S | High |
| T-08 | Low | Balance tab | `data/balance.json` `xp_tiers` | An empty object `{}` sits among numeric rows and is read by nothing. | `xp_tiers: {}`; no script names it | Remove the row. | S | High |
| T-09 | Low | Difficulty rows | Balance `difficulty_*` | Standard values are the base rows, so Relaxed and Harder rows are "deltas" for some levers (`opponent_start` -6 / +6, `gaffe_limit` +1 / -1) but absolute values for others (`reward_percent` 115 / 85, `dues_reward_percent` 10 / 20, `decay` 2 / 3). The same prefix mixes meanings. | See the dump above | Document in the workbook, or normalize. | S | Medium |
| T-10 | Low | Starting standing | `data/booster_standing.json` | The standing start is 30 for "all" organizations unless each row overrides; the Stakeholders screen on a new run showed most at 15 to 35. Fine, but the design doc says "most start 20-50" so the three sources should agree. | `start: 30` | Verify per-organization starts against the doc. | S | Low |

**Not flagged:** the ~150 clamps at 0 and 100, the calendar arithmetic (`WeekCalendar.gd`, a standard civil-date algorithm), and layout numbers.
