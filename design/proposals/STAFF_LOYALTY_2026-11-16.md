# Staff wages with Loyalty: design v2 (draft for Cameron, nothing built)

Builds on Method B in `STAFF_WAGES_2026-11-16.md`. Cameron's fixed rules: the wage is 10% of everything invested in that person (hire plus every upgrade paid), charged per person; quitting is permanent; a lost rank loses that rank's buff and rewards but can be bought again; a quit costs Reputation and standing with the person's allied organization. Every number below is a Balance row and every sentence a Text row; the numbers are **draft**.

## 1. Wage

| Rule | Detail |
|---|---|
| Amount | 10% of total invested, per person, per week (Balance `Staff Wage Share`). Invested = hire price + each upgrade price paid. Buying a lost rank again adds its price again |
| Examples | Hana Takahashi 4,000円; Yui Kobayashi hired and upgraded 9,000円; Marcus O'Connor fully upgraded 13,000円. All 21 staff at top rank would cost about 204,000円 a week; a realistic team of 3 to 6 costs 12,000 to 60,000円 |
| When | Week end, after party dues, from Funds. The week-end report lists each wage |
| Order if Funds run short | Highest Loyalty paid last (a loyal person forgives a late week), primary staff first. Players choose nothing automatically; the Staff screen choices in section 3 override this |
| Funds cap | The starting cap is 100,000円, so wages are a real share of income. Simulate before the share is fixed (see section 8) |

## 2. Loyalty (0 to 100, one number per person, hidden numbers shown as a word and a bar)

Starts at **60** when hired. Words shown: Devoted 80+, Steady 50 to 79, Restless 25 to 49, About to leave under 25.

### What moves it each week end

| Source | Change | Why |
|---|---|---|
| Paid in full and on time | +4 | Reliability |
| Unpaid or partly paid | −20 | Missed wage |
| **Allied organization affinity** (new variable, section 4) | −6 to +6 | The person's heart is with that organization |
| **Workload** (new variable, section 5) | −4 to +3 | Staff burn out or feel useful |
| **Recognition** (new variable, section 6) | decays by 2 a week, adds up to +6 | Praise and gifts keep them |
| Time with you (tenure) | +1 per 4 full weeks, cap +10 total | Familiarity |

All adds are summed, then Loyalty is clamped 0 to 100. Weekly swing is capped (−30 to +15) so one bad week never ends a career alone.

### One-off moves

| Event | Change |
|---|---|
| Player's promise broken | −5 for staff in the role it concerns (media: press promises; district: constituent promises; research: bill promises) |
| A level won with the person's primary role speaking the purpose line | +2 |
| A level lost | −3 |
| Pay raise week (section 3) | +10 once |
| Gift or bonus (section 6) | +5 to +15 |

## 3. Consequences of low Loyalty

| Loyalty | State | Effect |
|---|---|---|
| 50 and up | Normal | Full rank effects |
| 25 to 49 | Restless | Item boosts from this person halve; transition lines turn curt (an alternate Text row); they will not take a new upgrade until Loyalty is back to 50 |
| Under 25 | About to leave | **Lose one rank** at the next week end if wages were missed that week (the rule you set); the rank's buff and standing rewards are reversed |
| 0 | Quits | Permanent. Removed from the candidate list (new `staff_quit` list like `staff_fired`) |

**Losing a rank** reverses that rank's one-time standing rewards (the same deltas, negated) and removes its buffs. Buying the rank again costs the normal upgrade price and pays the rewards again. Loyalty after a drop resets to 35 so a person does not fall two ranks in consecutive weeks.

**Quitting costs** (draft): Reputation −8 and standing with the allied organization −10. Firing someone is still available at severance (10% of hire cost) with **no** Reputation penalty and a −3 standing hit to the ally, so the player can choose to part cleanly.

## 4. New variable 1: Allied organization (affinity)

Each staff member has one **allied organization**. Default is automatic: the organization named most often in their rank rewards (for example Yui Kobayashi: BO23, BO24 or BO16 tie, so the first listed; Marcus O'Connor: BO16). An optional Staff-tab column `Allied Organization` lets Cameron override it per person (needs his approval, since it adds a column).

The weekly **affinity** swing uses the player's current standing with that organization:

| Standing with the ally | Loyalty change |
|---|---|
| 80 and up | +6 |
| 60 to 79 | +3 |
| 40 to 59 | 0 |
| 20 to 39 | −3 |
| Under 20 | −6 |

This links two existing systems: neglecting an organization makes its allied staff restless, and treating it well steadies them. The ally also pays the price when the staff member leaves (section 3), so the same variable carries both reward and risk.

## 5. New variable 2: Workload (staff duty per week)

Workload counts how many times the person was **used** since the last week end:
- The primary researcher: Level Intros they spoke in, member visits briefed, vote research run.
- The primary spokesperson: press conferences, TV debates and ambushes played.
- The primary district representative: town halls, district visits and Office Hours cases answered.
- Extras count 1 per scene they spoke in.

| Uses this week | Loyalty change |
|---|---|
| 0 | −4 (idle and undervalued) |
| 1 to 3 | +3 (the useful zone) |
| 4 to 6 | 0 |
| 7 and up | −4 (burned out) |

This rewards a spread of playstyles and makes a second hire (extras) a real choice: more hands, more wages, less per-person burnout.

## 6. New variable 3: Recognition (a short-memory meter, 0 to 10)

Recognition is the player's chosen way to say thanks. It decays 2 a week and adds to the weekly Loyalty sum (up to +6 at 10).

| Action | Cost | Recognition | Loyalty one-off |
|---|---|---|---|
| **Raise pay** for the week (wage x1.5) | Extra wage | +3 | +10 |
| **Thank in public** (a press mention; needs Reputation 40+) | 3 hours | +4 | +5 |
| **Give a gift** (a Marketplace regional gift such as Haskap Yoitomake) | The item | +5 | +10 |
| **Skip this week's pay** (a deliberate miss, shown with its cost before pressing) | None | 0 | −20 (the missed-pay hit) |

Gifts reuse existing items (SH25 to SH33), giving them a second use. A person's taste could later vary by their ally's organization tastes (`organization_tastes`), as hosted events already do.

## 6b. Optional fourth variable: Rank pride

A person at a higher rank than their hire rank gets +2 Loyalty a week (they were promoted). This stops a fully upgraded person from feeling no different to a fresh hire. Drop it if three variables are enough.

## 7. Player-facing screens (information standards)

- **Staff list row:** name, rank, wage this week, a Loyalty word and a bar, an arrow for the trend (this week's expected change).
- **Staff profile:** "Why Loyalty is moving" with the six sources and their numbers; buttons **Raise pay**, **Thank in public**, **Give a gift**, **Fire**, **Make primary**. Greyed buttons say why.
- **Week-end report:** every wage, every Loyalty change, any rank lost, and any quit, with the Reputation and standing penalties named before and after.
- The week-end screen warns **before** "Pay Party Dues and Go Home" when Funds cannot cover dues plus wages.

## 8. Costs, simulation and build

| Item | Estimate |
|---|---|
| New run state | `staff_loyalty` and `staff_recognition` (per person), `staff_weeks_employed`, `staff_use_this_week`, `staff_quit` |
| Rules file | A new `StaffLoyalty.gd` in `scripts/rules/` (pure): wage, weekly update, drops and quits, with unit tests for every row above |
| Screens | Staff profile and list additions, week-end report lines, one popup for a quit |
| Workbook | About 20 Balance rows, about 25 Text rows, optional `Allied Organization` Staff column |
| Size | About 350 to 450 lines plus tests. **Needs your "Go" before building** |
| Simulation first | Extend the dues-first bot to hire 3 and 6 staff and report Funds, Loyalty and quits at wage shares of 5%, 10% and 15% over 30 weeks and 3 seeds |

## 9. Questions for Cameron

1. Keep all three new variables (ally affinity, workload, recognition), or drop workload or recognition?
2. Ally: derived automatically (recommended) or a new Staff-tab column you fill in?
3. Quit penalty: Reputation −8 and ally standing −10 as drafted?
4. Should firing carry a smaller penalty (ally −3, no Reputation) as drafted, or none?
5. Rank pride (6b) in or out?
