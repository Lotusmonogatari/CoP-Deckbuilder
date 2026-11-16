# Staff Assignments: testing rubric (draft for Cameron)

**Purpose.** A repeatable way to judge whether the staff mechanic does what it was designed to do, and what the numbers look like when it does. It is applied by `audit/tests/staff_rubric_run.tscn` (the measurable criteria) plus inspection and the unit tests (the rest). Results of a run: `audit/staff_assignments_rubric_run.md`.

## 1. The intent, in six sentences

1. **It eases in.** Week 1 has no tasks, then 1, 2 and 3 a day, then the full pool, so a new player learns it before it matters.
2. **Choices matter.** Each role is better at some work; a day's tasks are more than the staff's hours, so the player must decide who does what and what to leave.
3. **Neglect costs, with or without staff.** A Due task nobody takes costs a penalty; having no staff, or ignoring the screen, is a choice with a price.
4. **Rewards stay small.** The daily caps and Loyalty effects keep the mechanic a supplement to levels, events and Office Hours, not a replacement for them.
5. **People are people.** Good management keeps staff steady; idleness and overwork wear on them; time off is worth taking.
6. **It survives the rest of the game.** A long level can swallow a day with no reward or penalty; what the screen projects is what happens; saving and loading change nothing.

## 2. How to read the rubric

Each criterion has an **ID**, the **intent** it protects, a **metric**, how it is **measured** (S = by the simulation, T = by a unit test, I = by inspection of the screen or data), and thresholds. A result is **PASS** (inside the target), **WARN** (outside the target but not harmful: look at it) or **FAIL** (the intent is not met). Thresholds are first guesses by Claude, for Cameron to change; they are written below and in the verdict calls of `audit/tests/staff_rubric_run.gd`.

Players compared in the simulation (same dates, so the same pools):

| Player | What they do |
|---|---|
| **Best** | Three staff (one per role). Due tasks first, then strong fits, time off to the least loyal, then fair fits to fill the day; never gives a poor fit unless a Due task has no better home. Confirms every day. |
| **Random** | Three staff. Gives tasks to random people with room. Confirms every day. |
| **Ignore** | Three staff, never confirms. |
| **No staff** | Hires nobody. |

Runs: **A1** 20 back-to-back days from a new game (the ramp), **A2** 20 back-to-back days at full volume, **B** 10 Office visits each followed by a real level length (days interrupted by levels). Funds are kept high so wages and dues are never the story; allies' standing and decay behave as in the game.

## 3. Criteria

### D1. Ramp and volume (intent 1)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R1.1 | Tasks delivered a day in weeks 1 to 4 | exactly 0, 1, 2, 3 | one week off by 1 | more than that | S (A1), T |
| R1.2 | Mean tasks a day at full volume (calm) | 7 to 11 | 5 to 7 or 11 to 13 | under 5 or over 13 | S (A2) |
| R1.3 | Days with no tasks at full volume | 0% | under 5% | 5% or more | S |
| R1.4 | Variety: distinct tasks seen in 20 days | 30 or more of 64 | 20 to 29 | under 20 | S |
| R1.5 | Variety: days with the same pool twice running | 0 | 1 | 2 or more | S |
| R1.6 | Every family appears in 20 days | all 8 | 7 | fewer | S |
| R1.7 | Best player's reward a day during weeks 2 to 4 (points) | 0.5 or more | 0.2 to 0.5 | under 0.2 | S (A1) |

### D2. Meaningful choice (intent 2)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R2.1 | Task hours offered / staff hours (3 staff, 24 h) | 0.8 to 1.6 | 0.5 to 0.8 or 1.6 to 2.2 | outside that | S |
| R2.2 | Share of Best's assignments that are strong fits | 60% or more | 40% to 60% | under 40% | S |
| R2.3 | Reward gap, Best over Random (meta + XP points a day) | 1.5 or more | 0.5 to 1.5 | under 0.5 | S |
| R2.4 | Every role is the strong fit for at least 15 tasks | yes | 10 to 14 | fewer | I (data) |
| R2.5 | A poor fit never produces a gain | true | | false | T |
| R2.6 | Share of delivered tasks Best gets done with 1 / 2 / 3 staff | 1 staff 20% to 60%, 3 staff above 1 staff and at most 95% | one bound missed | both | S |

### D3. Consequences of neglect (intent 3)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R3.1 | Due tasks delivered a day at full volume | 1 to 3 | 0.5 to 1 or 3 to 4 | under 0.5 or over 4 | S |
| R3.2 | Cost of ignoring, Ignore vs Best (points a day) | 1.5 or more | 0.5 to 1.5 | under 0.5 | S |
| R3.3 | No-staff players pay a Due penalty on how many days | 60% or more | 30% to 60% | under 30% | S |
| R3.4 | Worst single-day loss on any meta number | at most the daily cap | | above it | S |
| R3.5 | Worst weekly loss from ignoring everything, any one meta number | 8 or less | 8 to 14 | over 14 | S |

### D4. Reward scale (intent 4)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R4.1 | Daily gain on any meta number from Best | at most the daily cap | | above it | S |
| R4.2 | Best's net meta + XP points a week | 3 to 14 | 14 to 22 or 1 to 3 | over 22 or under 1 | S |
| R4.3 | Best's XP a week | at most 20 | 20 to 35 | over 35 | S |
| R4.4 | Best's Funds change a week | within +/- 15,000円 | to 30,000 | beyond | S |

### D5. Staff wellbeing (intent 5)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R5.1 | Best: mean Loyalty change a week from tasks | 0 to +6 | -2 to 0 or +6 to +9 | below -2 or above +9 | S |
| R5.2 | Best: anyone below 15 Loyalty in 20 days | nobody | one person | more | S |
| R5.3 | Best: idle person-days | 15% or less | 15% to 30% | over 30% | S |
| R5.4 | Best: full (overworked) person-days | 40% or less | 40% to 60% | over 60% | S |
| R5.5 | Time off taken when offered | 30% or more | 10% to 30% | under 10% | S |
| R5.6 | Lowest Loyalty after the 4 ramp weeks (Best) | 25 or more | 15 to 24 | under 15 | S (A1) |

### D6. Integrity and interruption (intent 6)

| ID | Metric | Pass | Warn | Fail | Measured |
|---|---|---|---|---|---|
| R6.1 | A day skipped by a long level changes nothing | all skipped days exact | | any change | S, T |
| R6.2 | Projection equals what is applied (confirmed days) | 100% | 95% to 99% | under 95% | S, T |
| R6.3 | A level that ends exactly at the day's end settles the day | yes | | no | S |
| R6.4 | Interrupted play keeps this share of back-to-back reward per elapsed day | 35% or more | 15% to 35% | under 15% | S (informational) |
| R6.5 | Save and load keep the day (pool, plan, items) | yes | | no | T |

### D7. Clarity and editability (inspected, not simulated)

| ID | Check | How |
|---|---|---|
| R7.1 | The popup names outcomes (positive, neutral, negative) and no role | `test_staff_assignments_view.gd`, screenshot |
| R7.2 | Every confirm, refusal and penalty is shown before it happens | screen inspection (projection strip, greyed buttons with reasons) |
| R7.3 | Every word and number is editable in the workbook | `design/proposals/STAFF_TASKS_EXPANSION_2026-11-16.md` section 14, exporter checks |
| R7.4 | Text is body size or larger; touch targets 90 px or more | screenshots, `UiKit` defaults |

## 4. How to use it

Re-run `audit/tests/staff_rubric_run.tscn` after any change to the Staff Assignments, Families, Ramp, Drivers or Shop tabs, or to `StaffTasks.gd`, `StaffLoyalty.gd` or the staff functions in `GameState.gd`. A FAIL is a design question for Cameron; a WARN is something to watch in play.
