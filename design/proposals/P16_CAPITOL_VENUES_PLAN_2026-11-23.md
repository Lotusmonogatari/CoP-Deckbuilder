# P16 plan: Capitol venues, phase 1 (draft for Cameron, 2026-11-23)

Nothing in this plan is built. It waits for one answer (section 5) and a "Go". Base: `main` at the P15 merge (`9743412`); P13 and P14 are merged, so the Office frame and the pop-up card are there to reuse.

## 1. Executive summary

| Question | Answer |
|---|---|
| What it builds | A **Step out** button at the Capitol office, a place map, the **Cafeteria** and **Capitol Gardens** (daily gossip, some of it rhetoric tips the player keeps), the **Speech Coach** as a Capital Area venue, and the Tips button, pop-up and briefing marks. The Library, Sapporo Stage and Super Station show as "Coming soon". |
| Size | Large: about 1,500 lines of code and tests, three new workbook tabs, 90 lines and about 70 Text rows, in seven commits (the brief's order) on `feature/p16-capitol-venues`; a full check before pushing; no merge. |
| Name checks | **Clear.** `Venues`, `Venue Activities`, `Venue Lines` do not exist (only `Places`, a different tab), and no Text row starts `hint.`, `venue.` or `tips.`. |
| Package checks | The brief and README say 90 Venue Lines and 56 Hint Text rows; the workbook's "Read me" tab says 120 lines (an older count). The sheet holds 90 (VL001 to VL090). I build with 90. |
| Answered | Cameron, 2026-11-23: all 90 lines and the Text rows go in as written (section 5). Now waiting only for "Go". |

## 2. What I found in the code

| Part | Finding |
|---|---|
| Office Management | `OfficeScreen._show_management_tab` has three tabs: Staff, Your Deck, Rhetoric Training. The Rhetoric tab (`_rhetoric_cards`) is the page the Speech Coach venue must open **unchanged**; I move its entry point and delete the tab. A Rhetoric draw left on screen at app close also resumes through `_show_rhetoric_training`, which must open the venue instead. |
| Tests that mention Rhetoric Training | `test_management_screen`, `test_speech_coach`, `test_training_coupon`, `test_training_hours`, `shop_items_driver`, `card_faces_test`, the text sweep, `ui_target_audit_driver` and `office_screen_shots`. I update each to reach the page through the venue. |
| Run seed | There is no run-level random seed in `GameState` today. "Seeded by run and day" needs one: I add a `run_seed` (made once at New Game, saved; an old save gets one derived from its start state) and nothing else changes. |
| Levels on offer | The Levels list decides what is on offer at the Capitol; the tips' "reachable this week" rule reuses that, plus the next Decision! scene (`DecisionScenes`). |
| Where Step out goes | The Office's button column (Start, Reputation and Results, Administration, End the Work Week). It is hidden at the District office, during a level, and when the work week is full. |

## 3. Build order (the brief's seven steps, one commit each)

| # | Step | New code |
|---|---|---|
| 1 | **Workbook and exporter.** Tabs Venues, Venue Activities, Venue Lines; the 56 Hint Text rows plus the `venue.*` and `tips.*` UI rows; seven Rules rows; the exporter checks the brief lists (unique IDs, Venue ID and Pool exist, Kind, Speaker never a protagonist, dates, Seasons, After Law, hint kind and target, `{stage}` or `{name}` kept). | `export_data.py` |
| 2 | **Pure rules**, headless: `VenueRules.gd`, `VenueLines.gd`, `RhetoricTips.gd` and their tests. | three files, three test files |
| 3 | **Save.** `run_seed`; per venue per day the dealt set and how many were heard; the held tips. Old saves load with none. | `GameState.gd` |
| 4 | **Step out and the place map** on the Office frame; Cafeteria, Gardens and Speech Coach open, the other three greyed as "Coming soon". | `OfficeScreen.gd`, a small `PlaceMapView` |
| 5 | **Cafeteria and Gardens**: the venue screen and the line pop-up (tag, "Line n of 8 today", portrait and quote or narration, the tip box, Back and Keep listening, the dry state "Come back tomorrow"). | `VenueScreenView` |
| 6 | **Tips**: the Tips button with its count on the Levels header, the Tips you hold pop-up, the briefing marks (a tipped room, an opponent tip on that opponent's room). | `OfficeScreen.gd`, `LevelBriefingView.gd` |
| 7 | **Speech Coach**: the venue's activity opens the Rhetoric Training page unchanged; the tab leaves Office Management. | `OfficeScreen.gd` |

Then: unit tests, the real-click test the brief describes, screenshots of the seven screens in three styles beside the mockup shots, the text sweep, `ui_target_audit`, contrast 4.5:1, docs (`GAME_SYSTEMS.md`, a "Venue lines" section in `CONTENT_GUIDE.md`, the changelog and the brief's index), and art entries for six backgrounds and six icons in `design/ART_CHECKLIST.md`. Old Text rows the screens stop using go on `CLEANUP_CANDIDATES.md`.

## 4. Small points I will settle the way I describe unless you say otherwise

| Point | What I will do |
|---|---|
| The Rules row `venue_hint_share` is written "1 in 8" | Stored as the number 8 ("one in N") so code does not parse words; the Means text says so. |
| The Venue Lines columns Unlocks Doc and Effects | Imported as given (blank in every row today); nothing reads them in this phase. |
| Where it happens | Walking is free (0 h); the visit's hour is charged once when a visit starts; Keep listening never costs hours and a reload never reshuffles the set (the set is dealt from run seed, day and venue). |
| A hint's target | Stage tips use the stage's Favored Suit, opponent tips use `suit_1`; never a stage with no Favored Suit, a level not on offer this week, or an opponent the player cannot face. |

## 5. The one question (answered: all as written, Cameron 2026-11-23)

Do the **90 Venue Lines and 56 Text rows go in as written** (all "Claude's draft" in Notes), or **only the structure with a handful of lines**?

## 6. Risks I will check first and stop on

| Risk | Plan |
|---|---|
| Moving Rhetoric Training breaks tests and audits | Update each test to reach the page through the venue; run the whole unit suite and the click tests that name it before each commit. |
| A new run seed changes existing behavior | It only feeds the venue deal; nothing else reads it; old saves get a derived seed. |
| Hint targets empty on a quiet week | A hint slot with no eligible target falls back to a gossip line from the same pool. |
| The mockups' look | I reuse `OfficeScreenFrame` and the pop-up card; differences from the mockups go in the report. |
