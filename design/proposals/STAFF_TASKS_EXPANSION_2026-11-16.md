# Workplan: more staff tasks, family quotas, Marketplace items, and drivers (draft for Cameron)

Nothing here is built. It extends the Staff Assignments system (`GAME_SYSTEMS.md`, "Addendum 2026-11-16"). All names, numbers and sentences are drafts. Every number would be a workbook row, every sentence editable in the workbook, as before.

## 0. Where we are

| Today | Limit |
|---|---|
| 17 tasks in 8 icon families | Few tasks per family (1 to 4), so a family barely varies |
| 8 tasks a day, drawn by weight, no repeat, no family control | A day can be all Letters or no Press at all, and nothing the player does shapes it |
| Coffee and tea add hours to one person | Nothing changes which tasks appear, or how well a person does a family |
| Only a due task left undone has a penalty | Neglect has no memory: yesterday's pile does not return |

## 1. The goals, in one table

| Goal | How |
|---|---|
| More tasks | About 48 tasks, 5 to 7 per family (section 2) |
| A random range per family per day | A **family quota**: each family draws a number between its own Min and Max each day (section 3) |
| Marketplace items that act on a person | Items that change one person's day or fit (section 4a) |
| Marketplace items that skew the pool | Items that add, cut or filter a family's tasks (section 4b) |
| Penalties and variables that raise task volume | **Drivers**: the state of the game adds tasks of a family (dues owed, open promises, awareness, a bill under debate), plus a **backlog** of undone work (section 5) |

## 2. Workstream A: expand the task list

**Target:** 48 tasks (31 new), every family 5 to 7. Each task keeps today's shape (hours, Strong/Fair/Poor role, reward, penalty, optional Due penalty, context, work). Rewards stay small and capped per day; the drafts below are names only, to be rewritten by you.

| Family (icon) | Today | Proposed new tasks (strong role in brackets) |
|---|---|---|
| **Correspondence** (LL01) | Write constituent letters; Respond to committee staff | Sign thank-you cards (District); Answer a petition (District); Reply to a ministry letter (Research); Proofread the newsletter (Media) |
| **Press** (LL02) | Build media relationships; Review the news | Draft a press release (Media); Prepare a Q&A sheet (Media); Return a reporter's call (Media); Fact-check a quote (Research) |
| **Analysis** (LL03) | Review a policy whitepaper | Summarize a committee report (Research); Check a bill's costing (Research); Compare how other regions handle it (Research); Brief the member on a bill (Media) |
| **Meetings** (LL04) | Policy conference; organization meeting; committee hearing; press conference | Attend a town council session (District); Attend a trade fair (Media); Attend a ward festival (District); Sit in on a party caucus (Research) |
| **Constituents** (LL05) | Greet; casework; difficult constituents | Hold an office hour (District); Visit a local shop (District); Return a complaint call (District); Visit the elders' home (District) |
| **Administration** (LL06) | Deal with bureaucrats; Schedule meetings | File expense claims (Research); Renew a permit (Research); Book a hall (District); Update the donor list (Media) |
| **Chores** (LL07) | Office lunch; office microwave | Restock the tea (District); Fix the printer (Research); Tidy the filing cabinet (Research); Sort the mail (Media) |
| **Rest** (LL08) | Time off | Short break (2 hours); Long lunch (3 hours); Half day (4 hours) (all keep "Time off" rules) |

**Data:** only new rows on the Staff Assignments tab; no schema change. Targets (organization, committee, official) keep coming from the Boosters tab and the opponents' Title column. Tests: the existing task-table tests (three roles once each, one-word family per icon) cover every new row.

## 3. Workstream B: a random range per family per day

Today the pool is 8 tasks drawn from everything. New rule: **each family has its own quota**, drawn first, then filled with tasks from that family.

**New tab: Staff Task Families**

| Column | Meaning | Draft example |
|---|---|---|
| Family | The one-word name | Press |
| Min | Fewest tasks that day | 0 |
| Max | Most tasks that day | 2 |
| Cap | Most it can ever reach after drivers and items | 4 |
| Weekend Factor | Share of the weekday quota (a weekend day is shorter) | 50% |

Draft ranges (weekday): Correspondence 1 to 2, Press 0 to 2, Analysis 0 to 2, Meetings 0 to 2, Constituents 1 to 3, Administration 0 to 2, Chores 0 to 1, Rest 1 (always one, as now). That is about 4 to 15 tasks, averaging about 9.

**Draw order:** (1) each family's quota is rolled (Min to Max, a flat draw, seeded by date and protagonist as now); (2) drivers and items add or cut (sections 4 and 5), clamped to each family's Cap; (3) tasks are drawn inside each family by weight without repeats (a family with fewer tasks than its quota supplies what it has); (4) the whole pool is trimmed to **Pool Maximum** (draft 14) by dropping the lowest-priority extras (due tasks and backlog are never dropped).

**Why:** the day's character varies on purpose (a Press-heavy day, a quiet day), and the quota table is the one place you tune how often each family appears.

## 4. Workstream C: Marketplace items

New Shop columns (all optional, blank for non-staff items): **Staff Effect** (what it does), **Staff Value** (how much), **Staff Target** (a family, blank = any), **Staff Slot** (Person or Office), **Staff Days** (how long, 1 = today). The existing `Staff Hours` column folds into this (Effect = Hours).

### 4a. Items that act on one person (the existing drag-into-a-box row)

One item per person per day, as built for coffee and tea.

| Item (draft) | Effect | Notes |
|---|---|---|
| Coffee, Tea, Kaiju-Sized (exist) | Hours +1 or +2 | Unchanged |
| **Reference Set** (one per family: Press Kit, Policy Binder, Ward Map, Style Guide...) | The person counts as a **Strong fit** for that family today | Lets a poor role do a family well; skips a rank or Loyalty penalty (Restless still weakens it one step) |
| **Training Voucher** | Strong-fit rewards x1.5 today (rounded down) | Bigger, but still inside the daily caps |
| **Regional gift items** (the nine SH25 to SH33 you already own) | **Loyalty +N** to that person | Completes the "gift" form of recognition; the item is used up on confirm |
| **Quiet Desk Pass** | No idle or overwork Loyalty change today | Safety valve for a person you cannot use |

### 4b. Items that skew the day's pool (a separate "Office" slot above the task row; one per day)

| Item (draft) | Effect | Duration |
|---|---|---|
| **Press Subscription** | +1 to +2 Press tasks | Today (a stack lasts the week) |
| **Constituent Hotline Sign** | +1 to +2 Constituents | Today |
| **Reading Stack** | +1 to +2 Analysis | Today |
| **Do Not Disturb Sign** | -1 to -2 on any one family you pick | Today |
| **Outsourcing Contract** | Administration and Chores quotas -1 each | 3 days |
| **Task Filter Stamp** | Removes one chosen family entirely | Today |
| **Priority Tray** | Due tasks show first and cost no extra hours today | Today |

Price: XP and/or Funds, like the existing Marketplace items (XP for the strong ones). A "Recommendations" line on the Marketplace shows which family each item pushes, so the player can see what it does *before* buying (information standard 1).

### 4c. Where the player sees it

The Staff Assignments screen gets one line at the top of the tasks, **"Why these tasks today"**: each driver and item that moved a quota, with its amount ("Dues owed: +2 Administration. Press Subscription: +1 Press."). A skew item is placed in its own **Office box** just above the task tray, like a person's box.

## 5. Workstream D: drivers and a backlog (penalties and variables that raise volume)

### 5a. Drivers (new tab: Staff Task Drivers)

A driver is a game-state condition that **adds** to (or cuts) one family's quota that day.

| Column | Meaning |
|---|---|
| Driver ID, Note | The name and why it exists |
| Variable | What is read: a meta number, awareness, dues owed, open promises, a level in progress, the weekday |
| Test | At least, At most, or Is true |
| Threshold | The number |
| Family | Which quota it moves (or All) |
| Add Min, Add Max | The random amount it adds (negative cuts) |
| Cap | The most it can add in one day |

Draft drivers:

| Condition | Effect |
|---|---|
| Party dues owed | +1 to 2 Administration |
| Each 2 open promises | +1 Correspondence (up to +2) |
| District awareness at most 25 | +1 to 2 Constituents (the district notices you are gone) |
| District awareness at least 65 | +1 Constituents, +1 Press (more eyes on you) |
| National awareness at least 65 | +1 to 2 Press |
| Reputation at most 30 | +1 to 2 Press (clean-up work) |
| Reputation at least 60 | +1 Meetings (invitations arrive) |
| Constituency support at most 15 | +1 to 2 Constituents |
| A bill level in progress | +1 to 2 Analysis |
| Average staff Loyalty at most 29 (Restless) | +1 Chores (a sour office) |
| Monday / Friday | +1 Correspondence / +1 Administration |
| An event arrived today (an optional Event column) | +1 in that event's family |

### 5b. The backlog (penalty with memory)

Due tasks left undone on a *confirmed* day no longer simply cost their penalty and vanish: they come back **next day as Backlog**, the same task with a mark and a growing price.

| Rule (draft) | Value |
|---|---|
| A Due task left undone on a confirmed day | Costs its penalty now, **and returns tomorrow as Backlog** |
| Backlog undone a second day | Penalty x1.5, then it is dropped |
| Backlog cap | At most 3 carried tasks, so a bad week cannot bury the player |
| Backlog never carries across a skipped (long-level) day | A skipped day goes out of effect, as decided |
| Backlog tasks always appear (never trimmed) | They count toward Pool Maximum |

## 6. How it fits the code

| Piece | Where | Size (estimate) |
|---|---|---|
| Family quota and pool draw v2 | `StaffTasks.draw_pool` (pure), `Staff Task Families` tab, exporter mapping | About 180 lines |
| Drivers and item effects as modifiers | New pure `StaffPoolModifiers.gd` reads a state dictionary; `GameState` builds it; `Staff Task Drivers` tab | About 200 lines |
| Marketplace effects (Staff Effect columns, fit/reward/Loyalty/pool items) | `GameState` staff item functions, `StaffTasks.evaluate`, Shop tab | About 250 lines |
| Backlog state and carry-over | `GameState` (new saved fields), `StaffTasks` | About 120 lines |
| Screen: Office box, "Why these tasks today", item popups | `StaffAssignmentsView` + `Overlay` flows | About 250 lines |
| Content: 31 tasks, 8 families rows, about 12 drivers, about 15 items | Workbook only | Data |

Total over 1,000 lines, so it is split into phases with a "Go" each (section 8).

## 7. Risks and how they are handled

| Risk | Handling |
|---|---|
| Too many tasks overwhelm a small staff | Pool Maximum, family Caps, and a simulation (sim) of 1, 3 and 6 staff against average and worst days before the numbers are fixed |
| Rewards inflate (more tasks means more points) | The existing daily caps stay; the sim checks weekly totals against the meta numbers' decay |
| Players cannot tell why the day is full | "Why these tasks today" shows every driver and item that moved a quota |
| Skew items make the system trivially controllable | One Office item a day, modest ranges, XP prices, and drivers that can raise the same family |
| Save compatibility | New fields default to empty; backlog starts empty |
| Canon | Targets stay data-driven; no invented people, committees or places |

## 8. Phases

| Phase | What | Output |
|---|---|---|
| 1. Content | The 31 new tasks (draft text), family names stay as chosen | More variety; nothing else changes |
| 2. Quotas | Family tab and the quota draw | The random range per family per day, with a sim |
| 3. Drivers and backlog | Driver tab, backlog carry-over, "Why these tasks today" | Neglect and state raise volume, with the reason shown |
| 4. Person items | Reference Sets, Training Voucher, regional gifts, Quiet Desk Pass | Items that act on a person |
| 5. Pool items | Office box and the skew items | Items that shape the pool |
| 6. Tuning | Simulation across staff sizes and protagonists, then number review with you | Final numbers |

## 9. Decisions for Cameron

1. **Task count:** 48 (proposed), or a bigger or smaller target?
2. **Backlog:** carry undone Due tasks forward with a rising price (proposed), or keep the one-day penalty only?
3. **Skew items:** one Office slot a day (proposed), or several at once?
4. **Reference Sets:** one per family (8 items), or a single general "Strong fit for any one family" item you pick the family for?
5. **Regional gifts as Loyalty:** use the nine existing SH25 to SH33 gifts (proposed), or new gift items?
6. **Pool Maximum:** 14 (proposed), or lower?
