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

**Quitting costs** [DECIDED]: Reputation −8 and −10 standing per ally weight (section 4). **Firing** has no Reputation penalty and −3 per ally weight, but **severance rises to 3 x the hire price** (Cameron, was 10%: Balance `Staff Severance Share` 0.1 to 3.0, and the Staff tab's Firing Cost column recalculated to match, which needs `Ledger.gd` and the exporter's checks re-run). Example: Hana Takahashi 120,000円 to fire, against 4,000円 a week to keep her.

## 4. New variable 1: Allied organizations (affinity)  [DECIDED: from the rewards, several allowed, repeats multiply]

A person's **allies** are every organization named in the rewards of the ranks they currently hold, and an organization named several times counts that many times (its **weight**). No new column. Examples: Marcus O'Connor at top rank: BO16 x3, BO21 x2, BO17 x1; Hana Takahashi: BO21 x1; Yui Kobayashi at rank 0: BO23, BO24, BO16, each x1... (rank 0 rewards only until she is upgraded). Losing a rank removes that rank's rewards from the list.

The weekly **affinity** swing is the **weighted average** of the table below over the person's allies (so BO16 x3 pulls three times as hard as BO17 x1, and the total stays between -6 and +6):

| Standing with the ally | Loyalty change |
|---|---|
| 80 and up | +6 |
| 60 to 79 | +3 |
| 40 to 59 | 0 |
| 20 to 39 | −3 |
| Under 20 | −6 |

This links two existing systems: neglecting an organization makes its allied staff restless, and treating it well steadies them. The allies also pay when the staff member leaves: **each ally loses the quit penalty multiplied by its weight** (Marcus: BO16 -30, BO21 -20, BO17 -10), so a person tied heavily to one organization is costly to lose. Needs your confirmation that "multiplies" means this.

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

## 6b. Fourth variable: Rank pride  [DECIDED: in]

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

Decided 2026-11-16: all four variables in; allies come from the rewards (several, repeats multiply); quit penalty Reputation −8 and ally −10; severance 3 x hire price.

Still open:
1. "Repeats multiply" for the quit penalty: per ally weight as written (Marcus loses 30 with BO16), or only the affinity average, with one flat −10 split by weight?
2. A 3x severance (120,000円 for Hana) is more than the starting Funds cap of 100,000円: acceptable (firing becomes a late-game choice), or cap severance at the Funds cap?

---

# Update 2 (Cameron's notes): numbers fixed, workload redesigned

## A. Numbers now fixed (replace the drafts above)

| Item | Value |
|---|---|
| Starting Loyalty | **30** |
| Paid in full and on time | **+2** a week |
| Missed wage | −20 (unchanged; still draft) |
| Ally affinity | **±2 a week per 10 points of standing above or below 50**, using the weighted average of the person's allies. Standing 70 gives +4, 100 gives +10, 20 gives −6, 0 gives −10 |
| Quit penalty | **Reputation −15**; each ally **−20** (per ally weight, as first drafted: see open question) |
| Lost rank | Under 25 after a missed wage: one rank lost, its buffs and rewards reversed. 0: permanent quit |
| Severance (firing) | 3 x hire price; −3 ally standing per weight; no Reputation penalty |

Two consequences to know about:

1. **A new hire is Restless on day one** (Loyalty 30 sits in the 25 to 49 band, where boosts halve and upgrades are refused). On pay alone they reach 50 in 10 weeks, but a well-liked ally (standing 70) adds +4 a week and gets them there in about 4 weeks. Options: (a) keep it, so hiring is an investment that matures; (b) move the Restless band to 15 to 29 so new hires work at full strength; (c) new hires get a one-off +20 welcome bonus that fades. **Recommended: (b).**
2. **Affinity now outweighs pay.** +2 for paying against up to ±10 from affinity means a person whose ally you ignore (standing 30) loses 4 net a week even when paid, and one whose ally you love gains 12. This is intended (the organization relationship is the main lever), but it means wages mostly stop quits only for staff whose allies are at about 40 or above.

## B. Workload, rethought

Why the first version fails: counting **appearances** lets one long level (many transitions, many rooms) pile up uses, burn out one person in a week and punish having a single long bill. It also ignores that the three roles do different work, and gives events no way to say who did the work.

Fixes that apply to **all** options below:
- **Count assignments, not appearances.** Transitions, cues and Level Intro lines are cosmetic and count for nothing.
- **A level counts once per person**, however many rooms it has, with a longer level adding at most +1 extra (levels over a set number of hours).
- **Extras share load.** Each task goes to a named person; with extras hired the player (or the default order) spreads it.
- **Roles use different measures** (table in section C).

### Option W1: Assignments (counting tasks, capped)

Each role has a short list of **countable tasks**. A task adds 1 to that person's load for the week; each person's load is capped per task type so no single thing can burn them. Zones: 0 idle (−4), 1 to 3 healthy (+3), 4 to 5 busy (0), 6 or more strained (−4). Simple to explain, easy to test; a long level is one task.

### Option W2: Hours in your field

Workload is the **hours** the player spent that week on work in the person's field, as a share of the week's 40. The share bands, not raw counts, set the Loyalty change: well under the role's target share is idle, around it is healthy, well over is strained. A long level takes hours, but only the matching role feels it, and the bands are set per role so a 10-hour bill level is normal for a researcher and heavy for a district rep. Fair, but harder for the player to read ("why is Hana busy?") and weaker as a choice.

### Option W3: Assigned tasks with fatigue (player chooses who works)

Work only counts when the player **assigns** a named person. Each assignment adds Fatigue (1 for ordinary work, 2 for heavy work). Fatigue recovers 2 a week; Loyalty moves with the **peak fatigue** that week: 0 means idle, 1 to 3 healthy, 4 or more strained. Assignment points: the Level Briefing (choose who briefs the bill), a Member Visit (who prepares you), and event **Delegate** choices (below). With extras, the player rotates people. Most agency and the best fit for "delegating in events"; needs the most interface.

### Comparison

| | W1 Assignments | W2 Hours in field | W3 Assigned with fatigue |
|---|---|---|---|
| Long level burns one person? | No (counts once, +1 at most) | Only the matching role, and its bands allow for it | No (one assignment, fatigue 1 or 2) |
| Easy to read | Yes | Harder | Yes |
| Player agency | Low | Low | High (who to assign, rotation) |
| Helps extras matter | Somewhat | No | Strongly |
| New interface | Small | Small | Medium (assign buttons, a Delegate choice) |
| Build size | About 100 lines | About 120 lines | About 220 lines |

**Recommended: W3 for the three assignable tasks, with W1 counting the rest.** Staff you never assign are idle; assigning is how you keep them useful, and it is how events can delegate.

## C. Role differences (what each role's work is)

| Role | Assignable tasks (W3 / countable tasks (W1) | Weight | What "heavy" looks like |
|---|---|---|---|
| **Policy Research Assistant** | Brief a bill level; prepare a member visit; Vote Intention Research (existing item); a delegated policy event | Bill level 1 (2 if over the long-level limit); visit 1; research 1; event 1 | Several bill levels and visits in one week |
| **Media Spokesperson** | Press conference, TV debate and ambush stages; a delegated media event; the Press Coverage item (if added) | Each stage type 1 per **stage**, but a maximum of 2 per level | A week of three press-heavy levels |
| **District Representative** | Town hall levels; Office Hours cases (1 per **visitor met**, capped at 3 a week); a delegated constituency event | Town hall 1; cases cap 3; event 1 | A week with many visitors and town halls |

Idle is also role-specific: a spokesperson with no press work for the week is idle even if the researcher is busy. This is the point of the three roles, so a player who never does press stages will see the Media Spokesperson restless and must either use them (events, items) or let them go.

## D. Event delegation (new)

An event choice can carry an optional **Delegate** marker naming a role. In the choice list it reads "Delegate to <role>" with the cost and gain shown before pressing (information standards 1 and 2).

| Piece | Rule |
|---|---|
| Who | The player taps the choice, then picks one of the hired people of that role (primary or extras), shown with name, Loyalty word and fatigue. One person only |
| What it changes | A delegated choice saves player time (draft: hours cost halved) and avoids the Funds cost, but the result is **good or normal** depending on the person's Loyalty (Loyalty 50 and above: the stated result; 25 to 49: half the gains; under 25: none) |
| Workload | Adds Fatigue 1 (2 for a heavy event) to the assigned person |
| No suitable staff | The choice is greyed with "Needs a <role>: none hired" |
| Data | Event choices tab gets an optional `Delegate Role` column and an optional `Delegate Fatigue` (needs your OK, since it adds columns); Text rows for the labels and result lines |
| Loyalty effect | Being trusted with a case you can do well: +1 Loyalty the week they were delegated to; a person whose ally is the event's organization feels extra pride (+1 more) |

## E. Open questions

1. Workload option: W3 plus W1 (recommended), W1 alone (smallest), or W2?
2. Restless band: keep at 25 to 49 (new hires start half effective), move to 15 to 29 (recommended), or a welcome bonus?
3. Quit penalty multiplier: Reputation −15 flat, and **−20 per ally weight** as written (Marcus loses 60 with BO16), or −20 split by weight?
4. Severance of 3 x hire price is above the starting Funds cap (100,000円 for 120,000円): keep, or cap at the Funds cap?
5. Delegation columns on the Event choices tab: approve the two new columns?
