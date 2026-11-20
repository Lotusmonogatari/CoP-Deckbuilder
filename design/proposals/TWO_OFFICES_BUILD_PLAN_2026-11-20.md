# Two offices: build plan (2026-11-20, for Cameron's "Go")

Outline only: no code or data has been changed. It follows the decisions in `TWO_OFFICES_DECISIONS_2026-11-20.md` and the file-by-file reading in the audit's `touchpoints.md` and `feasibility.md` (branch `review/p11-two-offices-audit`). Under the working agreement (more than about 150 lines of new code), this waits for "Go".

## Executive summary

| Question | Answer |
|---|---|
| How big? | About 35 pieces of work (spec "Dependencies"). I propose **seven slices**, each one leaving the game fully playable and ending in a green `tools/verify.sh` and a merge to `main`. |
| What ships first? | **Slice 1, "Where you are":** the player has an office, trips cost hours, levels list only at their office, and a labelled-placeholder District office exists. Tap-to-travel, no swipe yet. |
| Art needed to start? | None. Missing art falls back to a labelled placeholder (hard constraint); art drops in by ID later. |
| One thing I need beyond what you approved | A `Travel Built In` column on Levels (see slice 1). Everything else is in your approved list. |
| Merge rule | After each slice: verify passes, then merge to `main`. (You said "then merge to main"; the popup asks whether that covers every slice or only the first.) |

## Step 0: unmerged work this build sits on

| Branch | State | Why it matters |
|---|---|---|
| `panel/p12-level-preview` | Verified, pushed, **not merged** | The Location badge on the briefing hangs on its panel. It also edits the workbook, and two branches that both edit the binary workbook cannot be merged by git. Merge it first and everything after starts clean. |
| `ccr-f187c072-e9y7wp` | The decisions log and this plan | Docs only. |

## The seven slices

| # | Slice | What the player gets | Main pieces | Needs art? | Size |
|---|---|---|---|---|---|
| 1 | **Where you are** | A saved office (Capitol or District). A trip costs hours and a confirm tap. The level list shows only levels at this office, with a badge. EV47 and crisis levels respect the offices. No weekend travel. | See below | No (placeholder District office) | L |
| 2 | **The District office, three styles, the swipe** | The train strip and drag, the fade and travel card, the District picture in Living Office, Broadcast and Woodblock, one shared pin set, the office name on the calendar square | `OfficeScreen`, `OfficeLayouts`, `RoomObjects`, `StyleMarks`, `art.json` | Placeholders until the art arrives | L |
| 3 | **Events, promises, notices, ticker, visitors by location** | Each office draws its own events; follow-ups wait for arrival; "Keep it in the District" on promises; the District Representative's lines at the District; Office Hours visitors by office; "Decision!" in the interface for dated events | Location columns, `EventEngine`, `Promises`, `OfficeNotices`, `OfficeTicker`, `OfficeHoursEngine` | No | L |
| 4 | **Tickets and train encounters** | Paid train ticket (+2 with BO23, BO05, BO14) and private car (instant, hours still spent, skips encounters); the short dilemma on the train at 1 in 8 trips on the pass | Shop rows, a Train Encounters tab, an encounter room that reuses the Office Hours layout | Rider silhouettes, ticket icons (placeholders first) | M |
| 5 | **Places and tokens** | `{place:harbor}` and similar resolve per protagonist; events needing a place type the district lacks do not fire; district text rewritten | Places tab (4 × 24), Needs Place column, a token resolver and its checker, text rewrites | No | L |
| 6 | **The eight protagonist levels** | One District fight and one Capitol policy fight per protagonist | Protagonist column on Levels, workbook rows only | No | M |
| 7 | **Tune and test** | Re-simulation with travel hours (P5), the PC01 and PC04 rating call, a How to Play page for travel, docs | Bot, `GAME_SYSTEMS.md`, `INFORMATION_STANDARDS.md` | No | M |

## Slice 1 in detail

| Part | Change |
|---|---|
| **Data (workbook)** | `Location` on Levels, **all 114 levels tagged from the audit's `levels_location.csv`** (Capitol 80, District 29, Either 5; LV10, LV21 and LV28 are Capitol, LV12, LV61 and LV62 District, as you decided), and a `Location` column on the Bill Level Templates for the four generated bill levels (all Capitol). **New, needs your OK:** an optional `Travel Built In` (Yes/No) column on Levels, so the briefing can say a mixed level's travel is included (Information Standard 1) without code guessing from its rooms. Balance rows: train hours and car hours for PC01 to PC04 (6/1/1/6 and 5/1/1/9), `Forced Travel Hours` (0). About 25 Text rows for the strip label, confirm, refusals and badges (drafts for you). |
| **Rules** (`scripts/rules/`, pure) | A small `Offices` rule (the two offices; "Either") and a `Travel` rule: hours for a protagonist and mode, and the refusals (not enough hours; a level in progress; the weekend; a crisis level waiting). Unit-tested. |
| **State** | `GameState.office_location`, its own saved field (not in `calendar`, which `WeekCalendar.normalized()` would drop on load). Old saves load at the Capitol with no migration. New runs start at the Capitol. `GameState.travel(mode)` spends the hours through the same pool as any level, so promise deadlines keep running (decided). |
| **Level list and start** | One more filter in the level list (a level at the other office is not listed), a location badge on each row and on the briefing's P12 badge, and a guard in `begin_level` that the player is at the level's office. Either levels list at both. |
| **Forced moves** | EV47 (Dated) moves the player to the Capitol at no hours at the start of the week and greys the other choices with a reason; the two crisis levels (LV83 District, LV84 Capitol) wait at their own office with the staff warning and are forced on arrival, never moving the player. |
| **Weekend** | No travel at the weekend; refusal says so. The week starts where the weekend ended (free: nothing resets position). |
| **District office (placeholder)** | The same Office scene with a different background ID per protagonist (`DISTRICT_OFFICE_PC01` to `PC04`) that falls back to a labelled placeholder, plus a travel button showing the cost before the tap: "To Teine Ward · 1 h by train · free". The swipe, picture and styles come in slice 2. |
| **Tests** | Unit: travel hours and refusals, location save round trip, the level filter, weekend and forced moves. Click: a trip from the Office, a District level that cannot start from the Capitol, return. The starting-location helper for the existing real-click suite. Run the text sweep, touch-target audit and contrast checks. |
| **Docs** | `GAME_SYSTEMS.md` (hours, locations, travel), `INFORMATION_STANDARDS.md` (travel cost before the choice), `CHANGELOG.md`, the index line in `CLAUDE.md`. |
| **Risks** | The Office screen is one 5,000-line scene with a fixed popup order, so the District office is the same scene with a new background; the Promises button position is fragile (`promises_placement_test` guards it); the crisis-level "wait and force on arrival" touches seven places (audit `forced_and_dated.md`). |

## Art IDs the build will look for

Drop a PNG under `assets/` with the ID and it is used; until then the game shows a labelled placeholder.

| ID | What |
|---|---|
| `DISTRICT_OFFICE_PC01` to `DISTRICT_OFFICE_PC04` | The four District office images (shared layout) |
| `TRAIN_STRIP` | The long train picture for the strip (the car uses the same strip) |
| `TRAIN_INTERIOR` | Encounter background |
| `DISTRICT_LOBBYIST_MEETING`, `DISTRICT_POLICY_STUDY`, `DISTRICT_AMBUSH_STREET` | District versions of the Either rooms |
| `OUT_NEIGHBORHOOD` | The existing gap |
| Rider silhouettes, `TICKET_TRAIN`, `TICKET_CAR` | Slice 4 |

## What would change the plan

| If | Then |
|---|---|
| You would rather start with the District office look | Swap slices 1 and 2 only if you accept placeholders for the trip logic; I advise against it, because the swipe needs a real location behind it. |
| You want only slice 1 reviewed before continuing | I stop after its merge and report. |
