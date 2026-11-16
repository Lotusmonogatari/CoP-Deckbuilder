# Staff Assignments screen and daily tasks (draft for Cameron, nothing built)

Replaces the workload section (B to D) of Update 2 in `STAFF_LOYALTY_2026-11-16.md`. Everything else there stands, with the numbers from Cameron's latest notes (restated in section 8). All numbers are **draft**, to be set in the workbook and simulated; all names and sentences are Text rows. Player-facing names, not code words: the aptitude tiers read **Strong fit**, **Fair fit** and **Poor fit** (internally competent, neutral, incompetent).

## 1. The idea in one paragraph

Each workday the Office offers a pool of small **tasks**. The player opens **Staff Assignments**, sees each hired person with picture, role, name and an **8-block workload bar**, drags task icons into a person's box (or taps a task, then the person), watches the bar drain and the **projected outcome** update, then presses **Confirm** to lock the day. A task is done well, adequately or badly depending on whether the person's **role** is a strong, fair or poor fit for it. Tasks left undone can cost something. How each person did feeds their Loyalty (and so their wage, rank and quitting).

## 2. When assignments happen

| Question | Draft rule |
|---|---|
| Cadence | A work week is five 8-hour days. The screen belongs to **one workday**; the first Office visit of a new day opens it, and the Office shows a badge until it is confirmed |
| Several days pass at once (a 35-hour level) | The **last confirmed plan repeats** for each day that passes, using each day's own task pool where the same task type is offered and leaving the rest undone. No penalty for days you could not reach the Office; the screen simply shows what the repeat did |
| Weekend | Optional and short (two 4-hour days): the bar is 4 blocks, the pool smaller |
| Resolution | At the end of each workday, results are applied and listed in a short day report on the Office ticker; the week-end report totals them |
| Hours the player pays | None. Staff time is their own; tasks cost **blocks**, not your hours |
| New staff | A new hire joins the screen the same day with a full bar |

## 3. The screen (portrait, 1080 x 2340)

- Top: the day's date, a count "Tasks left: n", and a **tray of task icons** (the day's pool, scrolling sideways if long).
- Below, a scrolling list of **staff cards**, one per hired person (up to nine with extras): picture, name, role, rank, a **Loyalty word and bar**, and the **8-block workload bar**. Each card has a **task box** that holds the icons dropped into it.
- A task icon is dropped into a person's box with a drag or a tap-then-tap (tap-only is required for accessibility). The box frames the icon in gold (Strong fit), grey (Fair fit) or red (Poor fit) so the fit is visible at once.
- Blocks used by tasks leave the bar darker; a task that does not fit (not enough blocks left) shows why and does not drop.
- A **projection strip** under the cards lists totals: "If you confirm: Constituency support +3, Reputation -1, Funds -5,000円, 1 task left undone (Reputation -1)." Costs and penalties are shown before Confirm, as the information standards require.
- **Confirm** at the bottom (above the BASE line, 144 px, greyed with a reason when nothing is assigned and no one is on time off: "Nothing is assigned yet", and a second tap on a "Confirm with nothing assigned" option is not offered).
- Tapping an icon anywhere opens its **popup** (section 6).
- Tapping a person opens their profile (Loyalty detail, wage, raise pay, gift, fire, Make primary).

## 4. The task pool

Seventeen tasks to start, grouped into **eight icon families** so only eight icon pictures are needed (the title distinguishes tasks inside a family):

| Icon family | Tasks |
|---|---|
| **Letter** | Write constituent letters; Respond to committee staff |
| **Newspaper** | Build media relationships; Review the news |
| **Report** | Review a policy whitepaper |
| **Podium** | Attend a policy conference; Attend a(n) [organization] meeting; Listen to a [committee] meeting; Attend [official]'s press conference |
| **Handshake** | Greet constituents; Perform constituent casework; Speak with difficult constituents |
| **Stamp** | Deal with bureaucrats; Schedule upcoming meetings |
| **Broom** | Organize the office lunch; Clean the office microwave |
| **Cushion** | Time off |

Bracketed names come **only from the data files**: an organization from the Boosters tab, a committee from the committee data, and (open question 2) an official from the opponents' titles. A task with a bracket is created for a named target on the day it is offered ("Attend Hokkaido Fishers Union meeting"), seeded and saved with the day's pool.

### How many tasks a day

The pool for a day is **8 tasks** (Balance `Staff Day Task Count`) drawn by weight: always Time off, always any **Due** task that is due, then random. Organization and committee tasks only appear for organizations and committees that exist in the player's current standing and calendar. The draw is seeded and saved (new run state `staff_day_tasks`).

## 5. Fit, outcomes and penalties

Every task fixes one role as **Strong fit**, one as **Fair fit**, one as **Poor fit**, so each role has real strengths:

| Task | Blocks | Strong fit | Fair fit | Poor fit | Strong-fit reward | Poor-fit penalty | Left undone |
|---|---|---|---|---|---|---|---|
| Write constituent letters | 2 | District Rep | Media | Research | Constituency +1 | Constituency -1 | none |
| Respond to committee staff | 1 | Research | District | Media | XP +2 | Reputation -1 | **Due:** Party support -1 |
| Build media relationships | 2 | Media | District | Research | National awareness +1 | Reputation -1 | none |
| Review the news | 1 | Media | Research | District | Reputation +1 | Reputation -1 | none |
| Review a policy whitepaper | 3 | Research | District | Media | XP +3 | Reputation -1 | none |
| Attend a policy conference | 4 | Research | Media | District | XP +3, Reputation +1 | Funds -5,000円 | none |
| Attend an [organization] meeting | 3 | District Rep | Research | Media | Standing +3 with it | Standing -2 with it | none |
| Listen to a [committee] meeting | 3 | Research | District | Media | XP +2, Party support +1 | Party support -1 | none |
| Attend [official]'s press conference | 2 | Media | Research | District | National awareness +2 | Reputation -1 | none |
| Greet constituents | 2 | District Rep | Media | Research | Constituency +2 | Constituency -1 | none |
| Perform constituent casework | 3 | District Rep | Research | Media | Constituency +2, District awareness +1 | Constituency -2 | **Due:** Constituency -1 |
| Speak with difficult constituents | 3 | Media | District | Research | Constituency +3 | Constituency -3, Reputation -1 | none |
| Deal with bureaucrats | 3 | Research | District | Media | Funds +8,000円 | Funds -8,000円 | none |
| Schedule upcoming meetings | 1 | District Rep | Media | Research | Reputation +1 | Reputation -1 | **Due:** Reputation -1 |
| Organize the office lunch | 1 | District Rep | Media | Research | **All staff Loyalty +1** | All staff Loyalty -1 | none |
| Clean the office microwave | 1 | Research | District | Media | Reputation +1 | Reputation -1 | none |
| Time off | 4 | (no fit) | | | That person's Loyalty +4, bar refills | | none |

Notes on the numbers:

- **Fair fit** always means no effect, as you specified.
- Rewards are deliberately small. Even three Strong-fit tasks for nine people would swamp the meta numbers (Constituency support decays 10% a week, ranges 0 to 100), so a Balance cap limits the total each meta number can gain from tasks in a day (draft +3) and lose (draft -3). Simulation will tune this before anything ships.
- A person's **rank** raises reward size (draft +25% per rank, rounded down) but never changes the fit.
- A person whose Loyalty is Restless (15 to 29) does Strong-fit tasks as Fair fit; under 15 they do Fair-fit tasks as Poor fit. Loyalty therefore matters even before a rank is lost.
- **Undone tasks:** only **Due** tasks have a penalty, shown on the task icon as a small mark and in the projection. A Due task offered but not assigned that day applies its penalty at day end. Others simply vanish.
- Time off (4 blocks) can be combined with 4 blocks of tasks; it does not repeat the same day.

## 6. The task popup (every icon)

| Line | Content |
|---|---|
| Title | "Perform constituent casework" |
| Context | One sentence on why it is on the desk today |
| Work performed | What the person actually does |
| Time cost | "3 blocks of a person's day" (a block is one hour of their day) |
| Outcome | Three lines: **Strong fit** (Media, say): what you gain; **Fair fit**: nothing; **Poor fit**: what you lose; with the roles named and, after you place it, a highlight of the line that applies |
| Left undone | The Due penalty if any |
| Buttons | **Close**, and **Assign to...** (opens the list of eligible staff with their remaining blocks) |

All task titles, contexts and work lines are Text rows; the three outcome lines are built from the numbers so they cannot disagree with the rules.

## 7. How tasks feed Loyalty (replaces the old Workload)

| Source (per week) | Change |
|---|---|
| Strong-fit task done | +1 each, at most +3 a week |
| Poor-fit task done | -1 each, at most -3 a week |
| Days with no tasks for that person | -1 each (idle, max -3) |
| Days using 5 to 7 blocks | +1 each (healthy, max +3) |
| Three full (8-block) days in a row | -2, then -2 each further day until a lighter day or Time off |
| Time off | +4 (applied the day taken) |
| Organized lunch / microwave | as in the table above |
| Due task left undone | -1 for the person who could have done it (the first person with blocks left) |

Per-week Loyalty also keeps: wage paid +2 / missed -20, ally affinity (±2 per 10 above or below standing 50), tenure, rank pride and recognition (raise pay, public thanks, gifts). A **weekly swing cap** (draft -30 to +15) still applies.

## 8. Numbers fixed so far (Cameron's notes)

| Item | Value |
|---|---|
| Wage | 10% of total invested per person per week |
| Starting Loyalty | 30 |
| Wage paid on time | +2 |
| Wage missed | -20 |
| Ally affinity | ±2 a week per 10 standing above or below 50 (weighted average across allies) |
| Bands | 30 and up Normal; 15 to 29 **Restless**: Strong-fit becomes Fair-fit, boosts halve, upgrades refused; under 25 after a missed wage: one rank lost; under 15 About to leave; 0: quits permanently |
| Lost rank | Its buffs and rewards reversed; buy it again at the normal price |
| Quit penalty | Reputation -15; each ally **-20 per ally weight** |
| Severance | 3 x hire price, uncapped; ally -3 per weight, no Reputation penalty |

The rank-loss threshold (under 25) sits inside the Restless band (15 to 29): a missed wage while in 15 to 24 loses a rank and also leaves them Restless. Please confirm that is what you want (open question 4).

## 9. Event delegation (updated)

An event choice with a **Delegate Role** names which role is the strong fit; the choice offers "Delegate to a ..." and the player chooses one hired person. It uses **Delegate Blocks** (the second new column, replacing Delegate Fatigue) from that person's remaining blocks **today**; the screen shows their bar. The event's result follows that person's fit:

| Fit | Result |
|---|---|
| Strong fit | The stated result, and the choice's Funds cost is waived |
| Fair fit | Half the gains |
| Poor fit | No gains and the choice's penalty applies |

If the person has too few blocks left, or the role has no hired person, the choice is greyed with the reason. Delegating a choice and then confirming the day's tasks both use the same bar.

## 10. Build plan (nothing started; needs your "Go")

| Phase | What | Size | Output |
|---|---|---|---|
| 1 | Wages and Loyalty: wage at week end, Loyalty meter (without tasks), Restless states, rank loss, quit, severance 3x, report lines, staff screen additions, tests | About 450 lines | Wage and Loyalty alone work |
| 2 | Task pool: new workbook tab **Staff Tasks** (task id, family, title, blocks, role fits, reward, penalty, due penalty, target kind), about 17 tasks, Text rows, `StaffAssignments.gd` rules (pool draw, projection, resolution) with tests | About 350 lines plus data | Rules complete, no screen yet |
| 3 | The **Staff Assignments** screen: cards, bars, drag and tap, popup, Confirm, day report; eight icon families (placeholders until Cameron draws them) | About 500 lines | Playable |
| 4 | Event delegation: two columns on Event choices, delegate flow | About 200 lines | Delegation works |
| 5 | Simulation (hire 3 and 6 staff; assign by best fit; 30 weeks, 3 seeds) and number tuning with you | Sim only | Numbers fixed |

Total is over 1,500 lines, so each phase gets its own plan and "Go". Phases 1 to 3 should be done in order; Phase 4 can follow later.

## 11. Open questions

1. **Cadence:** repeat the last confirmed plan for every day that passes (recommended), or leave unassigned days as idle?
2. **[official]'s press conference:** which people does this name? Options: a **party leader** from the opponents' titles (canon-safe because it is in the data), or any opponent whose Role is a minister (if the data has one).
3. **Time off:** 4 blocks that refill the person's bar for the rest of the day (draft), or a whole day (8 blocks)?
4. **Rank-loss threshold:** keep under 25 (inside the Restless band), or move to under 15?
5. **Art:** eight icon families to draw (Letter, Newspaper, Report, Podium, Handshake, Stamp, Broom, Cushion); placeholders until then.
6. **New workbook tab** `Staff Tasks` and two Event choices columns (`Delegate Role`, `Delegate Blocks`): confirm the schema.
