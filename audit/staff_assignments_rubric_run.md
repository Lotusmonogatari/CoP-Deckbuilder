# Staff Assignments: rubric evaluation (2026-11-16)

Rubric: `design/STAFF_ASSIGNMENTS_RUBRIC.md`. Tool: `audit/tests/staff_rubric_run.tscn` (the real `GameState` and `StaffTasks`, no UI). Evaluated: **20 back-to-back days from a new game (A1, the ramp)**, **20 back-to-back days at full volume (A2)**, **10 Office visits each followed by a real level length (B)**, plus Random, Ignore, No-staff, 1-staff and 2-staff comparisons over the same 20 days. Funds are held high so wages and dues are not the story; the pools are identical across players because they are seeded by date.

## Verdict in one table

| Intent | Result | What the numbers say |
|---|---|---|
| 1. It eases in | **Partly met** | The ramp delivers exactly 0, 1, 2, 3 tasks (PASS). But the ramp weeks give almost no reward (R1.7 FAIL) and strand the staff (R5.6 FAIL, below). |
| 2. Choices matter | **Met** | Good play earns +7.8 points a day; random assignment loses 1.9; one person does 27% of a day, three do 92% (R2.2, R2.3, R2.6 PASS). Slight worry: three staff nearly clear a day. |
| 3. Neglect costs | **Met** | Ignoring or having no staff costs about 2.0 points a day, every day; no day breaks the daily cap; the worst week is -5 (R3.x PASS). |
| 4. Rewards stay small | **Not met** | Best play nets +39, +32, +23, +20 points a week after decay (R4.2 FAIL) and Funds from tasks (+17,750円) cover more than the wage bill (14,000円) (R4.4 WARN). |
| 5. People are people | **Not met at the start** | At full volume Loyalty holds (0 idle, 80% time off). In the ramp weeks it collapses to 2 to 19 (R5.6 FAIL). |
| 6. It survives the rest of the game | **Met, with a cost to note** | Skipped days changed nothing (4 of 4); projection matched the applied result 23 of 23; but levels cost 77% of the reward per elapsed day (R6.4 WARN, informational). |

## Findings that need a decision

### F1. The ramp strands the staff (R5.6, R1.7: FAIL)

In the four ramp weeks the best-managed staff fall to Loyalty 3, 2 and 19 (from 30), and earn nothing. Cause, from the week-end breakdown of one person:

| Week | Wage paid | **Ally standing** | Tasks | Total |
|---|---|---|---|---|
| 1 | +2 | **-7** | 0 | -5 |
| 2 | +2 | **-7** | -1 | -6 |
| 3 | +2 | **-9** | 0 | -7 |
| 4 | +2 | **-10** | -2 | -9 |

New hires start at Loyalty 30, and the allies' standing starts low (about 15 to 25), so the affinity rule (+/-2 per 10 points from 50) takes 7 to 10 a week off them. With only 1 to 3 tasks a day, three staff spend most days idle (-1 a day) and there is nothing to earn it back. Below 30 they are Restless, so their strong fits count as fair and the little work there is earns nothing. At full volume the task bonus (capped at +6 a week) just balances the affinity loss and leaves no slack: the same person holds at 30.

**Options**

| Option | Effect |
|---|---|
| A. Idle only counts when work was left undone (**recommended**) | A person is not "idle" on a day with no task they could have taken. Removes most of the ramp's loss and is the fairest reading of idle. |
| B. A welcome grace period | No affinity loss for the first 4 weeks after hiring. Simple, but a special case. |
| C. Start Loyalty higher | For example 50. One Balance number, but delays rather than fixes the pull. |
| D. Soften affinity | For example +/-1 per 10 points. Changes your fixed number; affects the whole system. |

### F2. Rewards are richer than the intent (R4.2 FAIL, R4.4 WARN)

Best play reaches the daily cap of +3 on Constituency support and Reputation on most days, and XP of 11 to 19 a week. That is about 7.8 points a day for three staff. By week 4 the figure falls to +20 a week as decay catches up, but it is still a large share of what a level pays.

| Option | Effect |
|---|---|
| A. Lower `Staff Tasks: Cap Meta` from 3 to 2 (**recommended first step**) | Cuts best play by about a third; Ignore and No-staff losses fall too (they use the same cap). |
| B. Cut Funds rewards (TK13, TK36, TK46, TK49, TK50) or raise the wage from 10% to 15% | Fixes R4.4 (tasks currently pay more than the staff cost). |
| C. Lower the strong-fit rank bonus or the XP caps | Finer control. |

### F3. Levels cost most of the staff's value (R6.4 WARN, informational)

Ten Office visits spread over 15 elapsed days earned 23% of the back-to-back reward per elapsed day: 4 of the 10 days were skipped (a level longer than the rest of the day) and settled nothing, as decided. If that is more punishing than you want, the lever is a partial carry-over of a confirmed plan; it was ruled out earlier, so I have only flagged it.

### F4. Observations (no action needed)

| Observation | Meaning |
|---|---|
| Random assignment loses 1.9 points a day, no better than doing nothing | Choosing well matters. |
| A well-run office has fewer tasks (10.2 a day against 13.1 for Random or Ignore) | The drivers react to meta state: success lowers the load. A good feedback loop. |
| One staff member gets 27% of the day done and earns +0.1 a day against -2.0 for nobody | A single hire mostly pays for itself by avoiding penalties. Two staff earn +3.3. |
| 60 of the 64 tasks appeared in 20 days, all 8 families, no pool repeated two days running | Variety is good. |
| Time off is taken 80% of the time offered | Players (the Best policy) like it; check that it is not too free (it costs 2 to 4 hours of a person's day). |

## Method and limits

| Item | Detail |
|---|---|
| Players | Best is a competent heuristic, not a human; real players will do worse early and may do better at spotting synergy with items (the run uses no items or gifts). |
| Levels | The interrupted run spends real level lengths (hours from the Levels tab) rather than fighting battles. |
| Isolation | One protagonist (Kenshin Sako), allies' standing and decay as in the game, Funds and dues held out of the way. |
| Not covered | Items (Reference Sets, vouchers, gifts), the Office box, events. They are covered by unit tests, not by this run. |
| Thresholds | First guesses by Claude, written in the rubric and in the script's verdict calls; changing a threshold is a design decision. |

## Results


| ID | Criterion | Value | Verdict | Note |
|---|---|---|---|---|
| R1.1 | Tasks a day, weeks 1 to 4 | [[0, 0, 0, 0, 0], [1, 1, 1, 1, 1], [2, 2, 2, 2, 2], [3, 3, 3, 3, 3]] | **PASS** |  |
| R1.2 | Mean tasks a day, full volume | 10.2 | **PASS** |  |
| R1.3 | Days with no tasks | 0% | **PASS** |  |
| R1.4 | Distinct tasks seen in 20 days | 60 of 64 | **PASS** |  |
| R1.5 | Same pool two days running | 0 | **PASS** |  |
| R1.6 | Families seen in 20 days | 8 of 8 | **PASS** |  |
| R1.7 | Best: reward a day during weeks 2 to 4 (points) | 0.0 | **FAIL** | the ramp should still feel worth doing |
| R2.1 | Task hours offered / 3 staff's 24 hours | 0.89 | **PASS** |  |
| R2.2 | Best: share of assignments that are strong fits | 97% | **PASS** |  |
| R2.3 | Reward gap, Best over Random (points a day) | 8.7 (Best 7.8, Random -0.9) | **PASS** |  |
| R2.4 | Fewest tasks any role is strong at | 16 ({ "District Representative": 18, "Policy Research Assistant": 22, "Media Spokesperson": 16 }) | **PASS** |  |
| R2.6 | Best: share of delivered tasks that get done, 1 / 2 / 3 staff | 27% / 65% / 92% | **PASS** | one person should not clear a day; three nearly can |
| R3.1 | Due tasks delivered a day | 1.8 | **PASS** |  |
| R3.2 | Cost of ignoring, Best minus Ignore (points a day) | 9.8 (Ignore -2.0) | **PASS** |  |
| R3.3 | No-staff days with a Due penalty | 100% | **PASS** |  |
| R3.4 | Worst one-day loss on a meta number (Ignore) | -2 (cap 3) | **PASS** |  |
| R3.5 | Worst weekly loss, ignoring everything | -5 | **PASS** |  |
| R4.1 | Best: biggest one-day gain on a meta number | 3 (cap 3) | **PASS** |  |
| R4.2 | Best: net points a week (after decay) | [39, 32, 23, 20] | **FAIL** |  |
| R4.3 | Best: XP a week | [15, 19, 12, 11] | **PASS** |  |
| R4.4 | Best: Funds from tasks a week | +17750円 (weekly wage bill for the three staff: 14000円) | **WARN** | tasks vs the wage they cost |
| R5.1 | Best: mean Loyalty change a week | 1.8 (start { "SF04": 30, "SF08": 30, "SF18": 30 }, end { "SF04": 30, "SF08": 31, "SF18": 51 }) | **PASS** | includes wages (+2), affinity, tasks |
| R5.2 | Best: staff below 15 Loyalty | 0 | **PASS** |  |
| R5.3 | Best: idle person-days | 0% | **PASS** |  |
| R5.4 | Best: full person-days | 35% | **PASS** |  |
| R5.6 | Best: lowest Loyalty after the 4 ramp weeks | 2 ({ "SF04": 3, "SF08": 2, "SF18": 19 }) | **FAIL** | the ramp must not drive staff out |
| R5.5 | Best: time off taken when offered | 80% (16 of 20) | **PASS** |  |
| R6.1 | Skipped days that changed nothing (interrupted run) | 4 of 4 | **PASS** |  |
| R6.2 | Projection equals what was applied | 23 of 23 | **PASS** |  |
| R6.3 | A level that ends at the day's end settles it | 2 settled one-day crossings | **PASS** | informational if no level of that length was drawn |
| R6.4 | Interrupted reward per elapsed day, share of back-to-back | 23% (1.8 vs 7.8 pts a day over 15 elapsed days) | **WARN** | informational |

## Run summaries

| Run | Visits | Elapsed days | Mean tasks | Mean points a day | Skipped days | Assigned | Strong / fair / poor |
|---|---|---|---|---|---|---|---|
| best (3 staff) | 20 | 20 | 1.5 | 0.0 | 0 | 30 | 2 / 28 / 0 |
| best (3 staff) | 20 | 20 | 10.2 | 7.8 | 0 | 187 | 182 / 5 / 0 |
| best (1 staff) | 20 | 20 | 13.1 | 0.1 | 0 | 70 | 26 / 44 / 0 |
| best (2 staff) | 20 | 20 | 10.9 | 3.3 | 0 | 142 | 80 / 62 / 0 |
| random (3 staff) | 20 | 20 | 12.6 | -0.9 | 0 | 196 | 46 / 72 / 78 |
| ignore (3 staff) | 20 | 20 | 13.1 | -2.0 | 0 | 0 | 0 / 0 / 0 |
| nostaff (0 staff) | 20 | 20 | 12.4 | -2.0 | 0 | 0 | 0 / 0 / 0 |
| best (3 staff) | 10 | 15 | 11.9 | 2.7 | 4 | 85 | 68 / 17 / 0 |
| ignore (3 staff) | 10 | 15 | 12.6 | -0.8 | 4 | 0 | 0 / 0 / 0 |

Weekly meta change (after decay), Best at full volume: [{ "Constituency support": 11, "Reputation": 10, "Funds": -46000, "Party support": 3, "XP": 15 }, { "Constituency support": 8, "Reputation": 4, "Funds": -51000, "Party support": 1, "XP": 19 }, { "Constituency support": 6, "Reputation": 5, "Funds": -39000, "Party support": 0, "XP": 12 }, { "Constituency support": 5, "Reputation": 4, "Funds": -49000, "Party support": 0, "XP": 11 }]
Weekly meta change, Ignore: [{ "Constituency support": -5, "Reputation": -2, "Funds": -64000, "Party support": -1, "XP": 0 }, { "Constituency support": -5, "Reputation": -1, "Funds": -68000, "Party support": 0, "XP": 0 }, { "Constituency support": -3, "Reputation": -1, "Funds": -64000, "Party support": -1, "XP": 0 }, { "Constituency support": -3, "Reputation": 0, "Funds": -66000, "Party support": 0, "XP": 0 }]
Weekly meta change, No staff: [{ "Constituency support": -5, "Reputation": -2, "Funds": -50000, "Party support": -1, "XP": 0 }, { "Constituency support": -5, "Reputation": -1, "Funds": -54000, "Party support": 0, "XP": 0 }, { "Constituency support": -3, "Reputation": -1, "Funds": -50000, "Party support": -1, "XP": 0 }, { "Constituency support": -3, "Reputation": 0, "Funds": -52000, "Party support": 0, "XP": 0 }]

## Day logs

Level lengths used for the interrupted run (hours): [4, 20, 3, 10, 3, 16, 20, 15, 18, 13]



**best, 20 visits**
- visit 1: 0 tasks, 0h, 0 due, best, +0 pts
- visit 2: 0 tasks, 0h, 0 due, best, +0 pts
- visit 3: 0 tasks, 0h, 0 due, best, +0 pts
- visit 4: 0 tasks, 0h, 0 due, best, +0 pts
- visit 5: 0 tasks, 0h, 0 due, best, +0 pts
- visit 6:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": 0, "total": -5 }
- visit 7:   week end: Loyalty { "SF04": 25, "SF08": 24, "SF18": 29 }; wages paid 14000; quit []
- visit 8: 1 tasks, 1h, 0 due, confirmed, +0 pts
- visit 9: 1 tasks, 1h, 0 due, confirmed, +0 pts
- visit 10: 1 tasks, 1h, 0 due, confirmed, +0 pts
- visit 11: 1 tasks, 3h, 0 due, confirmed, +0 pts
- visit 12: 1 tasks, 2h, 0 due, confirmed, +0 pts
- visit 13:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": -1, "total": -6 }
- visit 14:   week end: Loyalty { "SF04": 19, "SF08": 14, "SF18": 23 }; wages paid 14000; quit []
- visit 15: 2 tasks, 3h, 0 due, confirmed, +0 pts
- visit 16: 2 tasks, 3h, 1 due, confirmed, +0 pts
- visit 17: 2 tasks, 2h, 1 due, confirmed, +0 pts
- visit 18: 2 tasks, 3h, 0 due, confirmed, +0 pts
- visit 19: 2 tasks, 7h, 1 due, confirmed, +0 pts
- visit 20:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -9, "tenure": 0, "pride": 0, "tasks": 0, "total": -7 }
- visit 21:   week end: Loyalty { "SF04": 12, "SF08": 7, "SF18": 19 }; wages paid 14000; quit []
- visit 22: 3 tasks, 5h, 0 due, confirmed, +0 pts
- visit 23: 3 tasks, 4h, 1 due, confirmed, +0 pts
- visit 24: 3 tasks, 4h, 1 due, confirmed, +0 pts
- visit 25: 3 tasks, 8h, 0 due, confirmed, +0 pts
- visit 26: 3 tasks, 4h, 1 due, confirmed, +0 pts
- visit 27:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -10, "tenure": 1, "pride": 0, "tasks": -2, "total": -9 }
- visit 28:   week end: Loyalty { "SF04": 3, "SF08": 2, "SF18": 19 }; wages paid 14000; quit []

**best, 20 visits**
- visit 1: 12 tasks, 24h, 3 due, confirmed, +8 pts
- visit 2: 14 tasks, 27h, 2 due, confirmed, +12 pts
- visit 3: 15 tasks, 33h, 1 due, confirmed, +7 pts
- visit 4: 10 tasks, 24h, 2 due, confirmed, +10 pts
- visit 5: 15 tasks, 31h, 3 due, confirmed, +8 pts
- visit 6:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": 6, "total": 1 }
- visit 7:   week end: Loyalty { "SF04": 31, "SF08": 30, "SF18": 35 }; wages paid 14000; quit []
- visit 8: 7 tasks, 16h, 1 due, confirmed, +8 pts
- visit 9: 10 tasks, 20h, 2 due, confirmed, +11 pts
- visit 10: 6 tasks, 15h, 1 due, confirmed, +7 pts
- visit 11: 10 tasks, 23h, 3 due, confirmed, +7 pts
- visit 12: 9 tasks, 18h, 2 due, confirmed, +8 pts
- visit 13:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": 6, "total": 1 }
- visit 14:   week end: Loyalty { "SF04": 32, "SF08": 30, "SF18": 40 }; wages paid 14000; quit []
- visit 15: 10 tasks, 21h, 2 due, confirmed, +6 pts
- visit 16: 8 tasks, 15h, 2 due, confirmed, +6 pts
- visit 17: 13 tasks, 28h, 2 due, confirmed, +4 pts
- visit 18: 8 tasks, 19h, 2 due, confirmed, +9 pts
- visit 19: 9 tasks, 20h, 1 due, confirmed, +10 pts
- visit 20:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -9, "tenure": 0, "pride": 0, "tasks": 6, "total": -1 }
- visit 21:   week end: Loyalty { "SF04": 31, "SF08": 30, "SF18": 45 }; wages paid 14000; quit []
- visit 22: 13 tasks, 28h, 1 due, confirmed, +9 pts
- visit 23: 9 tasks, 18h, 2 due, confirmed, +4 pts
- visit 24: 8 tasks, 16h, 1 due, confirmed, +9 pts
- visit 25: 9 tasks, 17h, 1 due, confirmed, +6 pts
- visit 26: 8 tasks, 15h, 1 due, confirmed, +6 pts
- visit 27:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -10, "tenure": 1, "pride": 0, "tasks": 6, "total": -1 }
- visit 28:   week end: Loyalty { "SF04": 30, "SF08": 31, "SF18": 51 }; wages paid 14000; quit []

**best, 10 visits**
- visit 1: 12 tasks, 24h, 3 due, confirmed, +0 pts
- visit 2: 12 tasks, 24h, 3 due, best, +0 pts
- visit 3: 12 tasks, 24h, 3 due, confirmed, +0 pts
- visit 4: 12 tasks, 24h, 3 due, best, +11 pts
- visit 5: 15 tasks, 28h, 2 due, confirmed, +6 pts
- visit 6:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": 6, "total": 1 }
- visit 7:   week end: Loyalty { "SF04": 31, "SF08": 30, "SF18": 35 }; wages paid 14000; quit []
- visit 8: 9 tasks, 16h, 2 due, confirmed, +0 pts
- visit 9: 10 tasks, 25h, 2 due, confirmed, +0 pts
- visit 10: 11 tasks, 23h, 2 due, confirmed, +7 pts
- visit 11:   parts of the week's Loyalty change (SF04): { "paid": true, "affinity": -7, "tenure": 0, "pride": 0, "tasks": 3, "total": -2 }
- visit 12:   week end: Loyalty { "SF04": 29, "SF08": 28, "SF18": 37 }; wages paid 14000; quit []
- visit 13: 12 tasks, 20h, 3 due, confirmed, +0 pts
- visit 14: 14 tasks, 32h, 2 due, confirmed, +3 pts


## After the first changes (Cameron, 2026-11-16: "Both")

Changed: `Staff Tasks: Cap Meta` 3 to 2; `Staff Wage: Percent` 10 to 15; Funds rewards roughly halved (TK13 +4,000, TK36 +3,000, TK46 +2,000, TK49 +2,000, TK50 +3,000).

| Criterion | Before | After |
|---|---|---|
| R2.3 Best over Random (points a day) | 9.6 | 7.9 (PASS) |
| R3.2 Cost of ignoring | 9.8 | 8.6 (PASS) |
| R4.2 Best's net points a week | 39, 32, 23, 20 (FAIL) | **33, 30, 20, 18 (still FAIL)** |
| R4.4 Funds from tasks vs the wage bill | +17,750円 vs 14,000円 (WARN) | +9,750円 vs 21,000円 (PASS) |

The Funds problem is fixed; the points are not. Best play is now 6.5 points a day, but **XP is about 15 of each week's points** and has its own cap (6 a day, `Staff Tasks: Cap XP`), so lowering the meta cap does not touch it. Lowering `Cap XP` to 3 would take about 7 points off a week. The Loyalty problem in the ramp (R5.6, R1.7) is unchanged and waits on a decision.

## After fixes 1 and 3 (Cameron, 2026-11-16): idle only when work was left; Loyalty starts at 50

Changed: a person is "idle" (Loyalty -1) only when some unassigned task, not time off, that would have fitted their day was left; new hires start at Loyalty 50 (was 30).

| Criterion | Before | After |
|---|---|---|
| R1.7 Reward a day in weeks 2 to 4 | 0.0 (FAIL) | **2.2 (PASS)** |
| R5.6 Lowest Loyalty after the 4 ramp weeks | 2 (FAIL) | **33 (PASS)**: 33, 37, 60 |
| R5.1, R5.2 Loyalty at full volume | PASS | PASS (start 50; end 50, 51, 71) |
| R6.4 Reward kept when levels interrupt | 23% (WARN) | 30% (WARN, informational) |
| R4.2 Net points a week | 33, 30, 20, 18 (FAIL) | unchanged: still FAIL (XP, see the section above) |

Remaining: **R4.2** (XP is about 15 of the week's points; `Staff Tasks: Cap XP` 6 to 3 would address it) and **R6.4** (informational). Loyalty still drifts down in the ramp (50 to 33) because the allies' low starting standing costs 7 to 10 a week; that is now slow enough to leave the staff working, and full-volume days outrun it.

## After lowering the XP cap (Cameron, 2026-11-16: R4.2 recommendation; R6.4 left as is)

Changed: `Staff Tasks: Cap XP` 6 to 3.

| Criterion | Before | After |
|---|---|---|
| R4.2 Best's net points a week (after decay) | 33, 30, 20, 18 (FAIL) | **30, 25, 16, 16 (WARN)** |
| R4.3 Best's XP a week | 13, 19, 12, 11 | 10, 14, 8, 9 (PASS) |
| R2.3 Best over Random | 7.0 | 4.5 (PASS) |
| R3.2 Cost of ignoring | 8.6 | 7.8 (PASS) |

No criterion now FAILS. R4.2 is a WARN: the first two weeks are still above the target (3 to 14) because the daily meta cap of 2 is reached on most days; weeks 3 and 4 are inside the warn range. R6.4 stays a WARN by decision (no action).
