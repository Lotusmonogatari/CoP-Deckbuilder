# Staff task pools: tuning report (2026-11-16, expansion phase 6)

Tool: `audit/tests/staff_pool_sim.tscn` (3,000 days per row, the real draw `StaffTasks.draw_pool`, the real Staff Task Families, Ramp and Drivers tabs). **Calm** = an ordinary state (nothing owed, middling awareness and Reputation, no bill, a Wednesday). **Stressed** = dues owed, 6 open promises, low district awareness, high national awareness, low Reputation and Constituency support, a bill in progress, a sour office, a Friday.

| State | Week | Tasks a day | Task hours a day | Due tasks a day | Hours beyond 1 staff (8h) | beyond 3 (24h) | beyond 6 (48h) |
|---|---|---|---|---|---|---|---|
| calm | 2 (max 1) | 1.0 | 2.1 | 0.2 | 0% | 0% | 0% |
| stressed | 2 | 1.0 | 2.0 | 0.2 | 0% | 0% | 0% |
| calm | 3 (max 2) | 2.0 | 4.3 | 0.4 | 0% | 0% | 0% |
| stressed | 3 | 2.0 | 4.0 | 0.5 | 0% | 0% | 0% |
| calm | 4 (max 3) | 3.0 | 6.4 | 0.6 | 7% | 0% | 0% |
| stressed | 4 | 3.0 | 6.0 | 0.7 | 3% | 0% | 0% |
| calm | 5 and after (max 15) | 9.0 | 19.3 | 1.7 | 99% | 13% | 0% |
| stressed | 5 and after | 15.0 | 29.9 | 3.1 | 100% | 98% | 0% |

## What this says

| Finding | Meaning |
|---|---|
| The ramp works as specified | Weeks 2 to 4 deliver exactly 1, 2 and 3 tasks (the maximum, since the families always roll more). Week 1 delivers none. |
| A calm day (week 5 on) is about 9 tasks and 19 hours | Three staff (24 hours) can do about 80% of it; six staff (48 hours) have room to spare. One staff member (8 hours) can do under half. This is the intended tension: staff size matters. |
| A stressed day hits the 15-task maximum and about 30 hours | Even three staff cannot cover it (98% of stressed days exceed 24 hours). Drivers are strong enough to matter; the maximum stops them running away. |
| **The week 4 to week 5 step is a cliff** | The pool jumps from 3 tasks (6 hours) to 9 (19 hours) on an ordinary day. This follows your ramp (0, 1, 2, 3, then 15), but a gentler tail, for example week 5: 6, week 6: 9, week 7: 12, week 8: 15, is one workbook edit on the Staff Task Ramp tab. |
| Due tasks | A calm day has about 1.7 Due tasks, a stressed one about 3.1. A player with no staff pays each one's penalty (capped at 3 a day on each meta number). Over a week that is a noticeable but not ruinous drain, because of the daily cap. If it feels harsh in play, lower the Due weights or the penalties on the Staff Assignments tab. |

## Knobs, all in the workbook

| To change | Edit |
|---|---|
| How fast the load ramps | Staff Task Ramp tab |
| Typical size of each family | Staff Task Families tab (Min, Max, Cap) |
| How often a state adds work | Staff Task Drivers tab |
| How harsh neglect is | Due Penalty cells on the Staff Assignments tab; the daily caps (`Staff Tasks: Cap ...`) on the Balance tab |

No numbers were changed by this pass.
