# Touchpoints: what a player location would reach

Draft for Cameron. Read-only audit: nothing here is built. File and line numbers are from `main` after P11 Parts 0 and 1 (line numbers drift; the function names are the stable handle). "New" means a thing that does not exist today.

## Executive summary

| Area | How much it touches | The one fact that matters most |
|---|---|---|
| Run state and save | Small, but one trap | `GameState.calendar` is rebuilt by `WeekCalendar.normalized()` with only week, phase and hours, so a location stored inside it would be **dropped on load**. Give location its own field in `_SAVED_FIELDS` |
| Weekend and week end | Small | `go_home()` and `end_work_week()` never reset anything position-like, so "each week starts where the weekend ended" is free once location is its own field |
| Office screen (one scene, 5,000+ lines) | Large | One `_build()` serves everything. It decides which popups open and in what order. Every location rule lands here or in the functions it calls |
| Level list and briefing | Medium | One loop (`_show_levels`) already filters for hidden, settled, cooldown, discovery, season and event-only. A location test is one more filter, plus a refusal row |
| Events, follow-ups, promises | Medium | Three separate engines (`EventEngine`, `take_due_followup`, `Promises`) each need a location argument. Promise data has no location field to read from |
| Visits, trade, staff, notices, ticker | Small to medium | Mostly display filters. Notices are resolved in one function; the ticker in one |
| Three UI styles | Medium to large | Living Office is a picture with pin positions in `art.json`; Broadcast and Woodblock are tile grids. A District office needs all three, plus the pin sets |
| Tests | About 45 files named below | Nothing today can place the player anywhere, so the real-click suite needs a starting-location helper |

## 1. Run state, save and load

| What | File and line | Note |
|---|---|---|
| The saved-field list | `scripts/autoload/GameState.gd:598-617` (`_SAVED_FIELDS`) | Add one field (for example `office_location`). A save lacking it keeps the fresh-run value (`load_save`, `:630`), so old saves load at the Capitol with no migration code |
| `to_save()` / `load_save()` | `GameState.gd:619`, `:630` | Generic over `_SAVED_FIELDS`; no change beyond the list |
| Fresh run | `start_new_run()` `:570`; `reset_*` helpers `:813-913`; `calendar = WeekCalendar.fresh()` `:834` | The new field's start value goes here (Capitol, or the district for some protagonists: open question) |
| **The trap** | `WeekCalendar.normalized()` `scripts/rules/WeekCalendar.gd:41`; called at `GameState.gd:656` | Returns a new dictionary with only `week`, `phase`, `hours`. Anything else stored in `calendar` is lost on load. Also, `WeekCalendar.go_home()` (`:116`) returns a new state, so a location kept in `calendar` would need to be copied through it |
| Save format version | `scripts/autoload/SaveManager.gd:31` (`VERSION := 1`), written `:177`, read `:231` | Not forced to change: the field is additive. Bump only if a migration is wanted |
| Save-slot summary | `SaveManager.summary_of()` `:155`; `tests/test_save_summary.gd` | Optional: show the office on the load screen |
| Problem report | `scripts/autoload/Reporter.gd:369` (`gather_facts`), `:386` (`_run_facts`) | Add the player's office to the report's "run" labels; the save block already carries the new field |
| Mid-level saves | `stage_checkpoint`, `level_runner.snapshot()` (`GameState.to_save`) | A level in progress keeps the office it started at. A mixed level's built-in travel never changes the saved location (settled rule: the player ends where they started) |
| Tests | `tests/test_save_load.gd`, `tests/test_save_points.gd`, `tests/test_save_summary.gd`, `tests/test_week_calendar.gd`, `tests/test_week_end_preview.gd`, `tests/test_week_payments.gd`, `tests/test_weekend_levels.gd` | Each round-trip needs the new field; a test that location survives the weekend is new |

## 2. Week end and weekend

| What | File and line | Note |
|---|---|---|
| The week-over popup | `OfficeScreen._show_week_over_if_due()` `:753`, `_check_week_over()` `:683` | Offers "work the weekend" or "go home". Open spec question: may the player travel at the weekend? |
| Work the weekend | `OfficeScreen._on_work_weekend()` `:814` -> `GameState.end_work_week()` `GameState.gd:3049` | Phase changes to weekend; location untouched |
| Go home | `OfficeScreen._go_home()` `:822` -> `GameState.go_home()` `GameState.gd:3060` | Settles dues, staff, awareness, decay, then `WeekCalendar.go_home()`. Nothing here moves the player, so "week starts where the weekend ended" holds by default. If the spec ever wants a different rule (a "return home" at the week end), this is the place |
| Hours pool | `WeekCalendar` (`scripts/rules/WeekCalendar.gd`): `advance()` `:100`, `hours_left()` `:64`, `level_refusal()` `:127` | Travel hours spend from the same pool through `GameState.spend_hours()` (`GameState.gd:2202`). **`spend_hours` also advances the hidden game clock** (`_advance_clock`, `:2873`), so travel time would also run down promise deadlines, backing lapses, special-level countdowns and cooldowns. The spec says this is intended ("hours are hours") |
| The "fits in the week" check | `GameState.level_calendar_refusal()` `:2846`, `work_week_level_refusal()` `:2861` | No travel term needed: only levels at the player's office are listed |
| Calendar square | `OfficeScreen._refresh_calendar()`, `GameState.calendar_hours_text()` `:2802`; `scripts/rules/CalendarStyles.gd`, `tests/test_calendar_styles.gd` | Optionally show the office name |

## 3. The Office screen

`scripts/ui/OfficeScreen.gd` is one scene serving every Office function. Its `_build()` (`:488-535`) ends with this fixed popup order:

| Order | Call | Line |
|---|---|---|
| 1 | `_show_trigger_alerts_if_any()` | `:1181` |
| 2 | `_show_broken_promises_if_any()` | `:1159` |
| 3 | `_show_resume_choice_if_in_level()` | `:1213` |
| 4 | `_show_followup_if_due()` else `_show_dated_event_if_due()` else `_show_random_event_if_due()` | `:912`, `:922`, `:933` |
| 5 | `_show_week_over_if_due()` | `:753` |
| 6 | `_show_forced_special_if_due()` | `:1238` |
| 7 | `_install_room_objects()` | `:391` |

Where a location would go:

| Need | Where | Note |
|---|---|---|
| Which office is showing | `_ready()` `:189` (`BaseImage.install(self, "OFFICE")`, `_background.art_id = "OFFICE"`); `_build()` | The background and portrait are set here. The District office needs its own picture, per protagonist (spec: four district offices). `art.json` has `outdoor_background_fallback` = ST05 and no district-office entry |
| Travel control and the transition | new; `SceneChange` (`scripts/autoload/`), `Layout.flash` | New swipe control; the fade can reuse `SceneChange` (disabled in tests) |
| Same scene or two scenes | design choice | One scene rebuilt with a different background keeps `_build()`'s popup order and the forced-special check intact. A second scene would need its own copy of steps 1 to 6 |
| Buttons reachable from both | `_build_week_controls()` `:544`; pins `events`, `results`, `promises`, `staff`, `marketplace`, `admin` | The spec makes Marketplace, Administration, Reputation and Results, How to Play reachable from both |
| Promises button position | `_pin_promises_above_dues()` `:375`, `_fit_portrait()` `:332`, `_set_compact()` `:360` | Fragile (fixed twice in this stretch). A second office layout must keep it; `tests/interaction/promises_placement_test.gd` guards it |
| Resume after quitting mid-level | `_show_resume_choice_if_in_level()` `:1213` | Resume must return to the office the level started in |

## 4. Level list and briefing

| What | File and line | Note |
|---|---|---|
| The list | `OfficeScreen._show_levels()` `:3620`; `_level_row()` `:3959`, `_level_row_plain()` `:3963` | The loop starting `:3647` skips special, hidden, settled-Act, on-cooldown, undiscovered, out-of-season and event-only levels (`Ledger.level_is_hidden`, `GameState.act_is_settled` `:5267`, `Ledger.level_cooldown_remaining`, `GameState.is_level_discovered` `:2574`, `GameState.in_season` `:2225`, `GameState.is_event_only` `:2521`). **One more filter, one more refusal row**: a level at the other office is not listed (settled rule) |
| Due special levels | `GameState.due_special_level_rows()` `:3734` | See `forced_and_dated.md` |
| Level data | `data/levels.json`; exporter `tools/export_data.py` Levels tab around `:1653-1664` (`"optional": ["Seasons", "Event Only (Yes/No)", "Level Purpose", "Purpose Speaker"]`) | A **Location** column goes here as an optional column, like Seasons |
| Choosing and the briefing | `_on_level_chosen()` `:4028`, `_show_briefing()` `:4034`, `BriefingSummary` | A level starts only at its office (settled), so the briefing needs no travel line. A mixed level should say, in the briefing, that its travel is included (Standard 1) |
| Starting | `_on_start_pressed()` `:4131`, `_on_start()` `:4159` -> `GameState.begin_level()` `:3428` | A guard that location matches is cheap insurance |
| Level hours | `GameState.level_hours()` `:2827` | Mixed levels add no travel hours (settled) |
| Generated bill levels | `data/bill_level_templates.json` (BT01 to BT04); `BattleSetup` | Four templates need a Location in their own table (see `levels_location.csv`, rows `GEN-BT01..04`; all Capitol) |
| Tests | `tests/test_ledger.gd`, `tests/test_event_levels.gd`, `tests/test_weekend_levels.gd`, `tests/test_seasons.gd`, `tests/interaction/loop_test.gd`, `click_test.gd`, `office_menus_test.gd`, `week_test.gd`, `level_intro_test.gd` | Any test that starts a level from the Office needs the start location to match. All 114 levels are Capitol, District or Either after tagging; the default test player must start where the chosen level is |

## 5. Events, follow-ups, dated events

| What | File and line | Note |
|---|---|---|
| Random draw | `GameState.roll_random_event()` `:2292`, `event_context()` `:2209`, `EventEngine.eligible_random()` `scripts/rules/EventEngine.gd:80` | Add `location` to the context and one more filter. This is the same pattern as the season filter (`:90`). Spec: each office gets its own share of slots so neither goes quiet. 65 Random events: 37 District, 14 Capitol, 14 Either (`events_location.csv`), so the District has the majority of the pool and the Capitol is short |
| Needs Place | new column; see `place_types.md` | The draw skips events whose place type the protagonist lacks |
| Buyable | `GameState.buyable_events()` `:2251`, `event_refusal()` `:2260`, `OfficeScreen._show_events_list()` `:844`, `_on_arrange_event()` `:865` | Spec: buyable from the office the item is used in |
| Hosted | `HostedEvent.gd`, `HostedEventPanel.gd`, `data/hosted_events.json`; `tests/test_hosted_event.gd`, `tests/interaction/hosted_test.gd` | Walking Tour (SH20) is District; Dinner (SH19) Either |
| Follow-ups | `GameState.take_due_followup()` `:3008`; `scheduled_events` (saved); `OfficeScreen._show_followup_if_due()` `:912` | Needs a location test and a "waits until arrival" rule. 12 follow-ups, offices in `events_location.csv` |
| Dated | `GameState.due_dated_event()` `:2238`; `EventEngine.due_dated()` `EventEngine.gd:108` | See `forced_and_dated.md` |
| Present and apply | `OfficeScreen._present_event()` `:942`, `_on_event_choice()` `:1060`; `GameState.apply_event_choice()` `:2309` | Choice buttons grey through `UiKit.action_button(label, refusal, ...)` (`:1007`): a location refusal is one more string |
| Data | `data/events.json`, `event_choices.json`, `event_options.json`; exporter Events tab (`Seasons` optional column at `tools/export_data.py:1260-1263`) | **Location** and **Needs Place** become optional columns |
| Tests | `tests/test_events.gd`, `tests/test_event_picture.gd`, `tests/test_battle_events.gd`, `tests/interaction/event_test.gd`, `event_level_test.gd`, `hosted_test.gd` | The random-event tests set a context; they need a location in it |

## 6. Promises

| What | File and line | Note |
|---|---|---|
| Where promises are made | `GameState.gd:4950-4990` (the commitment loop in the choice-apply path: `Promises.make(entry, ...)` at `:4971`) | A promise takes its location from the choice's event or visit, unless the entry sets one |
| The promise record | `scripts/rules/Promises.gd`: `make()` `:23`, `terms_of()` `:42`, `keep_refusal()` `:85` | `make()` builds the saved dictionary; add `location` here. Promises already in old saves have none and read as Either |
| Commitment parsing | `tools/export_data.py` `Commitment` -> `commitment_list` (`:1288`, `:1344`), `check_commitments()` `:3647`; `scripts/rules/Commitments.gd` | **The data has no place to put a promise location.** Promise entries are `kind amount within` (for example `promise_hours`). A location needs either a new optional element in that mini-language or a column on Event Choices and Visitor Questions. The audit proposes locations in `event_promises_location.csv` (239 rows: 20 event choices, 219 visitor questions) |
| Keeping | `GameState.promise_keep_refusal()` `:2964`, `keep_promise()` `:2980`; `OfficeScreen._show_promises()` `:1120`, `_on_keep_promise()` `:1134` | The Keep button is already an `action_button` with a refusal; "Keep it in the District" is one more refusal. Spec adds a badge on each row |
| Deadlines | `Promises.resume_after_level()` `:63`, `GameState._break_overdue_promises()` | Hours are hours (travel counts toward deadlines); promises pause during levels. No change |
| Broken-promise popup | `_show_broken_promises_if_any()` `:1159` | No change |
| Data size | `data/visitor_questions.json`: 429 questions, 217 with an hours promise | 215 of those are District by nature (constituents' casework); only 4 are Capitol |
| Tests | `tests/test_promises.gd`, `tests/interaction/promises_test.gd`, `promises_driver.gd`, `promises_placement_test.gd` | Existing promises must keep loading with no location |

## 7. Visits, Office Hours, trade

| What | File and line | Note |
|---|---|---|
| Routing | `scripts/ui/StageRouting.gd:12-40` | Office Hours = `VisitorScreen`, MP visit = `VisitScreen`, trade = `TradeScreen`, vote = `FloorVoteScreen` |
| Visitor draw | `scripts/ui/VisitorScreen.gd:138` (`OfficeHoursEngine.new()`), `scripts/rules/OfficeHoursEngine.gd`, `tests/test_visitor_selection.gd`, `test_office_hours_engine.gd` | Spec: fellow members visit the Capitol; constituents' Office Hours belong to the District. **Today's data makes Office Hours an Either level (LV86, LV106)**, so the visitor draw would filter by location *inside* an Either level. 167 visitors in `data/visitors.json` have no location |
| Layout | `VisitLayout.gd`, `VisitorPresenter.gd`, BASE background | The room picture today is the Capitol-looking `OFFICE` or ST07 (`backgrounds_either.csv`) |
| Visit and trade questions | `data/visit_questions.json`, `visit_answers.json`, `trade_questions.json`, `lobbyist_lines.json` | Place text lives here; see `place_references.csv` |

## 8. Staff, notices, ticker

| What | File and line | Note |
|---|---|---|
| Staff screens | `OfficeScreen._show_staff()` `:3231`, `_show_staff_assignments()` `:3453`, `StaffAssignmentsView.gd`, `StaffTasks.gd` | Spec: staff tasks run as today wherever the player is. 13 staff-task rows name a place (`place_references.csv`). The District Representative "appears" in the District |
| Notices | `OfficeScreen._refresh_notices()` `:1297` -> `OfficeNotices.resolve()` `scripts/rules/OfficeNotices.gd:14`, `condition_met()` `:41`; `data/office_notices.json` (20 rows) | Add an `office` argument and an optional Location column. Proposed: District 6, Capitol 10, Either 4 (`notices_ticker_location.csv`). ON01, ON02 and ON13 to ON16 move to the District |
| Ticker | `TickerPresenter.gd`, `OfficeScreen.gd:264` and `:385` (`_ticker.advance`), `OfficeTicker.eligible_lines()` `:99`, `calendar_met()` `:51`, `GameState.ticker_facts()` `:5868`; `tests/test_office_ticker.gd`, `test_ticker_calendar.gd` | `facts` already carries calendar gates; location is one more gate. Proposed: 151 of 155 lines stay Either; 4 are flagged (TK38, TK39, TK40, TK144) |
| Existing token precedent | `OfficeTicker.fill_tokens()` `:38` (`{player}`) and `OfficeNotices._fill_staff_token()` `:93` | Each table fills its own tokens; there is no shared place-token resolver |

## 9. Floor Vote, dated events, crisis levels

See `forced_and_dated.md`. In short: `GameState.gd:3627-3628` and `:3745`, `OfficeScreen.gd:1238`, `tests/test_special_levels.gd`, `tests/interaction/special_levels_test.gd`.

## 10. The three UI styles (P9)

| What | File and line | Note |
|---|---|---|
| Style selection | `scripts/ui/UiStyle.gd`, `UiStyles.gd`, `UiStyleTheme.gd`, `StyleMarks.gd`; `data` UI Styles tab (`tools/export_data.py:~4342`) | A District office has to exist in all three styles |
| Living Office picture and pins | `scripts/ui/RoomObjects.gd`: `hotspots()` `:20`, `_upgraded()` `:29`, `install()` `:38`; `data/art.json` key `office_hotspots` with sets `OFFICE` and `OFFICE_UPGRADED` | Pin fractions are tied to one picture each. A District picture needs its own set (`DISTRICT_OFFICE`, per protagonist if the pictures differ). The `_upgraded()` test reads the equipped background cosmetic, so a District background needs a cosmetic variant rule too |
| Broadcast and Woodblock tiles | `scripts/ui/OfficeLayouts.gd:20` (`install`), `:61` (`_into`), `:97` (`_style_start`); tile order `events, promises, staff, marketplace` (Broadcast) or plus `results, admin` | Grid layout, no per-office picture; mostly a heading and a background change |
| Background images | `BaseImage.install(self, "OFFICE")` `OfficeScreen.gd:192`; `assets/backgrounds/` | `OUT_NEIGHBORHOOD` is named by three stages and has **no picture file** (`backgrounds_either.csv`) |
| Cosmetic packages | `data/cosmetic_packages.json`, `GameState.active_cosmetics`, `CosmeticPieces` | The Office background package would need a District counterpart |
| Tests | `tests/interaction/ui_style_parity_test.gd`, `style_elements_test.gd`, `aspect_matrix_test.gd`, `office_menus_test.gd`; `tools/text_sweep.gd` (run three times in verify, one per style) | The spec's own test list asks for style parity on the District office |

## 11. Text and the place-token question

See `feasibility.md` section 4. In short: a token touches `Phrase.say()` (`scripts/rules/Phrase.gd:36`, `_fill()` `:84`), the exporter's placeholder checks (`tools/export_data.py:3576-3590`), the wording snapshot (`check_wording_snapshot`, `:4581`) and every table that shows data text without going through `Text.say`.

## 12. The interaction and unit tests a location would reach

| Group | Files |
|---|---|
| Real-click (`tests/interaction/`) | `loop_test`, `click_test`, `office_menus_test`, `week_test`, `promises_test`, `promises_placement_test`, `event_test`, `event_level_test`, `hosted_test`, `special_levels_test`, `office_hours_test`, `visit_test`, `trade_test`, `staff_profile_test`, `requests_test`, `draft_test`, `level_intro_test`, `stage_transition_test`, `floor_vote_test`, `ui_style_parity_test`, `style_elements_test`, `aspect_matrix_test`, `report_test`, `new_game_test` |
| Unit (`tests/`) | `test_save_load`, `test_save_points`, `test_save_summary`, `test_week_calendar`, `test_weekend_levels`, `test_week_end_preview`, `test_week_payments`, `test_events`, `test_hosted_event`, `test_battle_events`, `test_event_levels`, `test_promises`, `test_special_levels`, `test_trigger_alert_text`, `test_office_notices`, `test_office_ticker`, `test_ticker_calendar`, `test_seasons`, `test_ledger`, `test_visitor_selection`, `test_office_hours_engine`, `test_staff_tasks`, `test_text`, `test_spoken_no_game_terms`, `test_balance_keys` |
| Wording | `tests/wording_snapshot.json` (refreshed with `--accept-wording` when Text rows change on purpose) |

Real-click tests set `COP_NO_RANDOM_EVENTS` so a chance popup never lands on the button they press. A location-gated Dated or forced event would need the same switch.
