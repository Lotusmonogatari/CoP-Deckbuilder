# Forced and dated things: when they fire, who can see them coming, and which office owns them

Draft for Cameron. Read-only audit: nothing here is built. File and line numbers are from `main` after P11 Parts 0 and 1.

## Executive summary

| Thing | Fires | Known in advance? | Proposed office | Fits the spec's rule? |
|---|---|---|---|---|
| **EV47** The Prime Minister's Opening Address (the only Dated event) | The first time the Office opens on or after **18.10.09**, once only | **Yes, in principle**: the date is fixed and the calendar square shows today's date. Nothing warns the player today | **Capitol** | Yes. Rule 6 fits. One conflict: its choice C is "Keep your appointments in the district instead" |
| **LV83** Constituency Town Hall (special trigger "Town Hall") | When Constituency support first falls to 15, plus a 15-hour delay on the game clock; then listed at the top of the level list and forced after the next ordinary level | **Partly**: a popup says the meter fell the moment it happens. The 15-hour wait is hidden | **District** | Gap. Spec proposes: waits at its own office, forced on arrival, no move |
| **LV84** Party Steering Committee Check-In (special trigger "Steering Committee") | When Party support first falls below 25, plus the same 15-hour delay; same listing and forcing | **Partly**: same popup | **Capitol** | Same gap |
| Floor Vote | The last room of every bill level (and of a player's drafted or sponsored bill). **No calendar date** | Yes, if you read the level: the briefing lists the vote room. It is not a scheduled day | **Capitol** (the bill levels are Capitol, `levels_location.csv`) | No forced travel needed: the vote is part of a level that already starts at the Capitol |
| Any other `special_trigger` | None. Only LV83 and LV84 carry one | n/a | n/a | n/a |

Three things to decide, from the data: (1) EV47's choice C; (2) what the player sees while a crisis level waits at the other office; (3) whether the crisis level should still wait after the meter has recovered (today it does).

## 1. Dated events

One event has the Dated trigger. The Events tab has 87 events: 65 Random, 12 Follow-up, 9 Buyable, 1 Dated.

| Event | Title | On date | Hours | Available | Speaker | Seasons |
|---|---|---|---|---|---|---|
| EV47 | The Prime Minister's Opening Address | 18.10.09 | 2 | Weekday | Prime Minister | none |

How it fires today:

- `EventEngine.due_dated()` (`scripts/rules/EventEngine.gd:108`) returns the Dated events whose date has come (or passed) and that are not in `dated_events_done`, earliest first. `GameState.due_dated_event()` (`GameState.gd:2238`) feeds it today's calendar day number.
- `OfficeScreen._show_dated_event_if_due()` (`OfficeScreen.gd:922`) opens it. It runs in `_build()` after the follow-up check and before the random-event roll (`OfficeScreen.gd:530-531`), so a Dated event always beats a random one. It is skipped inside a level and when `COP_NO_RANDOM_EVENTS` is set (tests).
- It stays due until the player has chosen (`GameState.gd:2407` adds it to `dated_events_done` when a choice is made). Its panel cannot be dismissed (`OfficeScreen.gd:596`: `dismissable = false`, no Back), so the first Office screen on or after the date is the event and the player cannot start a level first. It is already forced in that sense.
- Calendar: the game starts on 18.10.01 (`calendar_start_*` in Balance), so EV47 comes due on day 9, a Tuesday of week 2. A player who is mid-level that day sees it on returning to the Office.
- Cost: 2 hours, taken when the choice is made (`spend_hours`, `GameState.gd:2202`).

Can the player know in advance? The date is fixed in the workbook but **nothing tells the player**. The calendar square shows only today's date. The spec's rule 6 adds a staff reminder before it ("when the event is known in advance"); the data supports that because `on_date` is a plain date, so a reminder row can be keyed off the same cell.

Office: **Capitol** (the National Assembly opening; the speaker is the Prime Minister; choice A seats the player in the chamber).

What rule 6 would touch for this event:

| Piece | Where today | What changes |
|---|---|---|
| Trigger label | `Dated` in the Events tab; `OfficeScreen.gd:955` heading `event.heading_dated` | Rename in the interface to Decision! (a Text row; the workbook value can stay) |
| Moving the player to the Capitol | nothing exists | New: set location to Capitol before showing it, at `forced_travel_hours` (default 0) |
| Greying other choices | choices are built in `_present_event` (`OfficeScreen.gd:942`) with `UiKit.action_button(label, refusal, ...)` (`:1007`); a refusal string greys a button and shows why | Add a refusal ("Today you are due at the Capitol") to every choice that does not belong at the Capitol |
| "Opens the week" | the event opens on whatever Office build comes first on/after the date, not at a week start | If it must open the week, the date should fall on a Monday (18.10.08 is the Monday of week 2; 18.10.09 is the Tuesday) or the rule needs a "first build on or after" reading. **Open question** |

**Conflict inside EV47.** Choice C reads "Keep your appointments in the district instead" (Party support -1). Under rule 6 the other choices are greyed and the player is moved to the Capitol. Choice C is the one that cannot be played at the Capitol. Options: leave EV47 outside the forced rule; reword C (for example, "Skip it and send your regrets"); or let C stand as the single exception that skips the move. This is a content question for Cameron.

Save: `dated_events_done` is already saved (`GameState.gd:607`). No change needed.

## 2. Forced (crisis) levels: LV83 and LV84

The only two levels with a `special_trigger`. Both are tier 0, `weekend_ok` Yes, one stage each.

| Level | Name | Trigger | Stage | Hours | Purpose line speaker |
|---|---|---|---|---|---|
| LV83 | Constituency Town Hall | Town Hall | ST05 (Combat, `town_hall` question pool) | 2 | District Representative |
| LV84 | Party Steering Committee Check-In | Steering Committee | ST22 (Non-combat) | 2 | Policy Research Assistant |

### When they fire

1. **Arming.** `check_crisis_triggers()` (`GameState.gd:2885`) runs after every clock step (`_advance_clock`, `:2874`), at each stage end and at week end. `_check_town_hall()` (`:3694`) and `_check_steering_committee()` (`:3708`) arm the level when the meter first crosses in:
   - Town Hall: Constituency support at or below `jiban_town_hall_trigger` = **15**.
   - Steering Committee: Party support below `party_support_steering_committee` = **25**.
   - Each is an edge: it arms once on the way in and stays quiet until the meter climbs back out (`town_hall_active`, `steering_committee_active`, saved).
2. **Delay.** `_arm_special()` (`:3722`) stamps `special_levels[trigger] = {armed_at: time_units}`. The level is **due** `special_level_delay` = **15** clock units later (`due_special_levels()`, `:3728`). One clock unit is one stage hour or one hour spent in an event or skipped at a week end, so about two ordinary levels.
3. **Listing.** Once due, the level appears under its own heading at the top of the level list (`OfficeScreen._show_levels`, `:3641-3645`, via `due_special_level_rows()`, `GameState.gd:3734`). Special levels never appear in the ordinary list (`:3650`).
4. **Forcing.** If the player finishes an *ordinary* level while a special level is due, `special_forced` is set (`GameState.gd:3627-3628`). The next Office build calls `_show_forced_special_if_due()` (`OfficeScreen.gd:1238`, called last at `:533`): a panel "Something needs you" with one button, and the level starts. **The forced start does not check the hours left in the week** (`_on_forced_special_go` -> `_on_start`, `:1256`).
5. **Done.** Playing it, win or lose, erases the armed entry (`GameState.gd:3626`). It comes round again only if the meter crosses in again.
6. **Meter recovery does not cancel it.** When the meter climbs back out, only the `_active` flag and an alert change (`:3702-3703`, `:3716-3717`); `special_levels` keeps the entry. So a crisis level still comes due after the crisis is over. This is existing behavior, noted because the two-offices wait would make it much more visible.

### Can the player know in advance?

| What the player sees | Where |
|---|---|
| A popup at the next Office build after the meter crosses in: "Constituency support fell to {count}. Your district is growing restless." / "Party support fell to {count}. The Steering Committee has noticed." | `pending_trigger_alerts` (`GameState.gd:466`, `OfficeScreen.gd:1181`). **Not saved** (`:462-465`): closing the app between the stage and the Office loses the warning |
| Nothing about the 15-hour wait (the hidden clock stays hidden, Standard 7) | by design |
| The level at the top of the list once due | `OfficeScreen.gd:3641` |

So the *cause* is announced; the *timing* is not.

### Which office

| Level | Office | Basis |
|---|---|---|
| LV83 | **District** | Town hall room, District Representative speaks the purpose line, constituents ask the questions. The spec agrees |
| LV84 | **Capitol** | Party business; the Policy Research Assistant speaks. The spec agrees |

### What the spec's proposal would touch

The proposal (spec line 92): each crisis level waits at its own office with a staff warning, is forced in on arrival there, and **does not move the player**.

| Piece | File and line | Change |
|---|---|---|
| Which due levels the list shows | `GameState.due_special_level_rows()` (`GameState.gd:3734`), `OfficeScreen._show_levels` (`:3641`) | Show a due special level only at its own office (the level-list rule); at the other office it is not listed |
| When forcing is decided | `GameState.gd:3627-3628` (end of an ordinary level) | Today: force if any special level is due. New: force only if one is due **at the office the player is standing in**. A level due at the other office stays waiting |
| Forcing on arrival | `take_forced_special()` (`:3745`), `_show_forced_special_if_due()` (`OfficeScreen.gd:1238`, `:533`) | The arrival after a trip must also run the check. If the District office is the same scene and is rebuilt after a trip, `_build()` already calls it; if it is a new scene, it needs its own call |
| The staff warning | `OfficeScreen._show_trigger_alerts_if_any()` (`:1181`), Text `office.trigger.*.entered` | New wording that says where it waits ("... a town hall is being called in the district"); and, because the alert is not saved, a way to remind the player while the level waits (otherwise a crisis level the player never knew about can sit invisibly at the other office) |
| A waiting crisis the player can't see | the level list at the other office | Decide whether the other office shows a greyed "waiting at the Capitol" line. Standard 2 (a thing you can't do shows why) points to yes |
| Hours | `_on_forced_special_go` (`:1256`) | Forced starts ignore hours left today. A 2-hour level forced at hour 39 spills over. Unchanged by two offices, but travel makes it likelier |
| Weekend | `weekend_ok` Yes on both | If a weekend trip is not allowed (open question 3 in the spec), a level waiting at the other office cannot fire until Monday |
| Save | `special_levels`, `special_forced`, `town_hall_active`, `steering_committee_active` already saved (`GameState.gd:607`) | No new field for the wait. The location field (new) must be saved too |
| Tests | `tests/test_special_levels.gd`, `tests/test_trigger_alert_text.gd`, `tests/interaction/special_levels_test.gd` (+ driver) | The interaction test builds a due level and expects it forced; it needs a location setup. The alert-text test pins the two sentences |

Failure mode to design against: a player who lives at one office (say the Capitol, because levels are 77% Capitol by hours) while a District crisis waits. The level stays due, can never be forced, and is never listed. Is it acceptable that a crisis can wait indefinitely? The meter has not recovered the level (item 6 above), so it will still fire whenever the player next visits the District, however long it has been.

## 3. Floor Vote timing

| Question | Answer |
|---|---|
| Is there a date? | No. The calendar has no Floor Vote day. Nothing in `balance.json` or `rules.json` schedules one |
| When does it happen? | When the player reaches it: it is the last room of a bill level. A level's stage slot holding a `BIxx` bill id means "the Floor Voting room" (`BattleSetup._is_bill_id`; `GameState.level_hours` counts it as stage `bill_vote_stage`, ST23, 1 hour) |
| Sponsored and drafted bills | The generated bill levels (`data/bill_level_templates.json`, BT01 to BT04) all end in `VOTE`, and also run Capitol-shaped rooms (Hearing, Caucus, MP Visit, Lobbyist Trade) |
| Can the player know in advance? | Yes. The level briefing lists every shown room with its hours, and the vote room is listed. A drafted bill has a cooldown (`draft_bill_cooldown_units` = 90) and a patron request waits `patron_free_backing_units` = 90 units, both hidden clocks |
| Which office | **Capitol.** All 50 levels that hold a bill (`BIxx`) slot are tagged Capitol in `levels_location.csv`. A Floor Vote is never played alone, so no separate location is needed |
| Forced travel? | None needed. The level starts at the Capitol and the vote is inside it. A mixed level that opens with a District room (for example, a town hall) has its travel built in and free (settled rule), so the player is back at the Capitol for the vote |
| Lost Acts | A lost Act returns after a 7,488-hour replay timer (the 2026-11-12 change). That timer is on the same hidden clock; location does not affect it |

What the location rules would touch: the Floor Vote screen and room (`FloorVoteScreen`, `scenes/office_hours/FloorVoteScreen.tscn`, `StageRouting.FLOOR_VOTE_SCENE`) need no change. The level list does: bill levels are listed only at the Capitol. A District-only player would see no bills there (this is the intended design, but it should be visible in the District list as "Bills are at the Capitol").

## 4. Follow-up events (not forced by date, but they wait)

For completeness: 12 follow-up events are scheduled by a choice (kind `followup`) and fire when the clock reaches `due_at` (`GameState.take_due_followup`, `:3008`; `OfficeScreen._show_followup_if_due`, `:912`). They arrive before Dated and Random events (`:530`). The spec says they "fire at their own location; if the player is elsewhere they wait until arrival". Today there is no waiting: a follow-up opens on the next Office build after it is due. With two offices, `take_due_followup()` needs a location test, and a follow-up whose origin event is District-only would wait at the other office exactly as a crisis level would. The 12 follow-ups and their proposed offices are in `events_location.csv` (they inherit the office of the event that schedules them).

## 5. Open questions this raises

1. **EV47 choice C** (above): reword, exempt, or keep the event unforced.
2. **Does EV47 open the week?** Its date (18.10.09) is a Tuesday. Rule 6 says it "opens the week". Move the date to a Monday, or read the rule as "the first Office build on or after the date".
3. **Waiting crisis visibility.** What does the player at the wrong office see?
4. **A recovered meter.** Should a waiting crisis level cancel itself when the meter has climbed back out? Today it does not.
5. **Forced start and the hours pool.** A forced start ignores hours left (today and after).
6. **Alerts are not saved.** With a wait that can last weeks, the warning needs to persist or be repeated.
