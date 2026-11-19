# P11 Part 2: the two-offices audit (Capitol and District)

Read-only audit, 2026-11-19. Everything here is a **draft for Cameron**. No game code, data or workbook was changed; the only new files are in `audit/two_offices/` (the scripts) and in this folder (their output and the notes).

Branch `review/p11-two-offices-audit`. Audit content commit: **b5fae925** (a second commit adds this hash to this line and changes nothing else).

## Executive summary

| Finding | Number or fact |
|---|---|
| Levels tagged | 114: **Capitol 80, District 29, Either 5**. 24 are Mixed (rooms at both offices): 21 Capitol by the settled rule and 3 District (LV12, LV61 and LV62, **Cameron decided 2026-11-19**: they start in the District and finish at the Capitol, travel built in). Confidence: 105 high, 6 medium, 3 low (LV10, LV21, LV28) |
| Either rooms are mostly inside other levels | Only 5 levels are Either all the way through (LV02, LV85, LV86, LV90, LV106), but **76 more levels contain at least one Either room** (61 Capitol, 15 District). The spec's "about 18 Either levels" counted these differently |
| Events | 89 rows (87 events plus the 2 hosted events): **District 53, Capitol 18, Either 18**. The Capitol is thin on random events: of 65 Random, 37 are District, 14 Capitol, 14 Either |
| Promises | 239 promise rows: **222 District**, 9 Either, 8 Capitol. 215 of 219 visitor-question promises are District by nature, yet Office Hours is an Either level (see open question 1) |
| Office notices and ticker | Notices: Capitol 10, District 6, Either 4. Ticker: 151 of 155 lines stay Either, 4 flagged (TK38, TK39, TK40, TK144) |
| Place and brand references | 14,131 hits in about 52,000 text rows: 1,162 real names (91 distinct), 12 real brands, 8,659 implied places that match a catalog type, 4,298 implied places the catalog has no type for. Most of the volume is generic words in spoken cues; the real work is the 1,162 names and the casework text |
| Catalog gaps | 13 place types the text uses that the 24 archetypes lack (housing, street, forest, road, bank, restaurant, care facility, newsroom or studio, police or fire, library, airport, sports venue, river works); 2 catalog types little used by casework (island, beach) |
| Hours | Settled hours, standard play: **PC02 and PC03 lose about 1 to 2 hours a week (2 to 5%). PC01 and PC04 lose 5 to 11 hours a week by train (12 to 28%), PC04 up to 17 by car (43% as played)**. PC01 and PC04 look harder |
| Feasibility | Negative `win_delta_boXX` already works (ASCII minus only). Seasons already work for levels and Random and Buyable events. A Protagonist column is read in four places. A place token is two mechanisms, not one |
| Surprises | `OUT_NEIGHBORHOOD` (used by three stages) has no picture file. Forced crisis levels ignore the hours left in the week. A waiting crisis level does not cancel when the meter recovers. `WeekCalendar.normalized()` would drop a location stored in `calendar` |
| Old remote branches | Nothing of substance is missing from `main` (see "The two old remote branches" below) |

## One paragraph per item

**1. `levels_location.csv`.** All 114 levels, each with its stages (id and name), the room kind and office of each room, a proposed Location, a Mixed flag, a confidence and a reason; plus four rows for the runtime-generated bill levels (`GEN-BT01` to `GEN-BT04`, all Capitol). The method reads each stage's mode, audience and question pool, the background family and the level's purpose line and speaker, not keywords. Rooms map to an office (committee, hearing, caucus, floor vote, steering committee, press conference and TV debate are Capitol; town hall and local-event rooms are District; Lobbyist Meeting, Policy Study, Office Hours and Media Ambush are Either). A level whose rooms are all one office takes it; a level with Capitol and District rooms is Mixed and takes the shape of its centre of gravity (a bill, a committee or the media makes it Capitol, per the settled rule). The rule alone put all 24 Mixed levels at Capitol (a committee, a floor debate or a bill makes a Mixed level Capitol). **Cameron then decided that LV12 (Family Outreach Tour), LV61 (Rail Fares and Timetables) and LV62 (Fishing Quotas and Harbors) are District levels that start in the District and finish at the Capitol**, so 21 Mixed levels are Capitol and 3 are District; three stay low confidence (LV10, LV21, LV28), because their District rooms are one or two of many. The 50 levels that hold a bill slot are all Capitol. The two crisis levels follow their offices (LV83 District, LV84 Capitol). The three Chishima acts are Capitol. The levels file differs from the spec's rough sort (Capitol about 53, District about 24, Either about 18, Mixed about 19) mainly in how Either rooms are counted, as described above.

**1b. `backgrounds_either.csv`.** The room types that could be Either (Lobbyist Meeting ST20, Policy Study ST21, Office Hours ST07 and the OFFICE variants, Open House Day, Media Ambush ST19, Lobbyist Trade, TV Debate ST06, Town Hall ST05), with today's background, whether it reads as the Capitol and the District background it would need. Judged by looking at the pictures: ST20 (a high-rise office) and ST21 (a government conference room) and ST19 (a TV corridor) and OFFICE read as the Capitol; ST07 is a generic office (ambiguous); ST05 is already District. Five Either room types (Lobbyist Meeting, Policy Study, Office Hours in the Office room, Open House Day, Media Ambush; 38 stages in all) show a Capitol-looking background today and would look wrong at the District; the 33 Office Hours stages on ST07 are ambiguous. Pictures that could serve a District version: OUT_STREET_1 to 3 for the media ambush; DINING and DINING_ALT for the lobbyist meeting; nothing for the policy study (a library or community-room interior is missing; `OUT_CULTURAL_CENTER_1_AINU` is an exterior) and nothing for the District office itself. **Finding: `OUT_NEIGHBORHOOD`, named by three stages (Community Clinic Day, Health Fair, Regional Health Forum), has no picture file**, so those stages already fall back to the ST05 outdoor picture (`art.json` `outdoor_background_fallback`).

**2. `events_location.csv`.** 89 rows with class, trigger, hours, proposed Location, confidence, Needs Place (from the 24 archetypes), real places named and the reason. Classes: Scenario Random 65, Scenario Follow-up 12 (they inherit the office of the event that schedules them), Arranged Buyable 9, Arranged hosted 2 (the Walking Tour SH20 District, the Dinner SH19 Either), Decision! Dated 1 (EV47, Capitol). 39 events name a place type the catalog covers; the rest are generic. `event_promises_location.csv` gives a proposed promise location and reason for each of the 239 promise-bearing rows (20 event choices, 219 visitor questions). The promise rule: a promise takes the office of the choice that made it unless the text says otherwise ("spend 2 hours with the fishermen" is District-only by nature).

**2b. `forced_and_dated.md`.** One Dated event (EV47, 18.10.09, a Tuesday), two forced crisis levels (LV83 Town Hall at Constituency support 15; LV84 Steering Committee at Party support below 25, both with a 15-hour hidden delay), and Floor Vote timing (no date; it is the last room of a bill level). For each: when it fires, whether the player can know in advance (the cause is announced by a popup, the timing is not), and its office. The note on the spec's "wait at the office and force on arrival, don't move the player" lists the seven places it touches (list filter, the forcing decision at `GameState.gd:3627`, arrival check, wording, waiting visibility, hours, weekend) and the failure mode (a crisis that can wait indefinitely at the office the player never visits).

**3. `notices_ticker_location.csv`.** 175 rows (20 notices, 155 ticker lines). Notices: ON01, ON02 and ON13 to ON16 District; the Policy Assistant, Spokesperson, journalist, party-colleague, committee-intern and Cabinet-bureau notices Capitol; ON07, ON08, ON17, ON18 Either. Ticker: 151 Either with no flag; four flagged because they put a staff member or an event inside "the" office (TK38, TK39, TK40, TK144), and they could read wrong in one office. Local outlets are named in 39 lines and Capitol outlets in 21, so the feed is mixed as the spec intends.

**4. `place_references.csv`.** 14,131 rows: table, key, field, the words, context, kind, proposed place type or Yezo brand, proposed token or note. Kinds: place (real name) 1,162; place (implied type) 8,659; place (implied, not in catalog) 4,298; brand (real) 12. **Treat the implied rows as a worklist, not a verdict**: they are matched by word, and about 11,200 of the hits are in spoken cues and question pools where "district" or "committee" is just a word. The signal is in the 1,162 real names (Sapporo 174, Hokkaido 168, Tsugaru 154, Hokkaido Shinkansen 153, China 148, Russia 40, Aomori 39, Japan 34, Hakodate 24, Otaru 24 ...), several of them canon decisions (Hokkaido and Japan against Yezo), and in the 12 brands. The Yezo brand map is only listed against each brand, not applied.

**5. `place_types.md`.** Counts per catalog type, split into casework rows and all rows. The heaviest: school, travel route, farmland, festival, market, station, hospital, shrine or temple, harbor. Catalog types that little or no casework uses: island and beach (the Rishiri text was already made generic in Part 1). Thirteen candidate types the catalog lacks: housing, street or neighborhood, road or bridge, forest or wildlife, bank, restaurant or inn, care facility, newsroom or studio, police or fire, library, airport, sports venue, river or flood works, each with a suggestion to add a type, fold into an existing one, or leave generic.

**6. `hours_impact.md` (with `hours_impact_numbers.csv`).** Method: replay the strategy bot's 144 logged runs (`design/bench/pc_difficulty.jsonl`: 4 protagonists by 3 pressures by 12 runs, 20,485 level plays), tag each level with its office from item 1, charge one trip whenever a level is at the other office, charge nothing for Either levels, mixed-level travel or forced moves. Two orders: as played (the bot's own order, a pessimistic upper bound) and batched (at most one trip a week, the best a careful player can do). Assumptions and limits are in the file (the bot ignores location; the logs predate the staff change of 2026-11-16; the weekend and weekend travel are left out). Result: PC02 and PC03 spend 0.8 to 1.9 hours a week (2 to 5%); PC01 spends 4.8 (12%) batched and 11.0 (28%) as played by train; PC04 spends 4.8 and 11.3 by train and **7.2 and 17.0 by car** (the car is slower for PC04). About 74% of the hours the bot plays are Capitol, 21% District, 5% Either, so most weeks (about 80%) include a trip. **PC01 and PC04 look harder**: the cost is not the average but the lump (a 12-hour round trip is 30% of a week at once). Whether PC01 stays Easy is Cameron's call; the file lists levers that would soften it.

**7. `touchpoints.md`.** The screens, scripts, save fields and tests a location would reach, with file and line, in twelve sections (run state and save, week end and weekend, the Office screen, level list and briefing, events and follow-ups, promises, visits, staff, notices and ticker, floor vote and crisis levels, the three UI styles, text, tests). The key finds: location must be its own saved field because `WeekCalendar.normalized()` rebuilds `calendar` with three keys; "each week starts where the weekend ended" is free because `go_home()` moves nothing; `spend_hours()` also runs the hidden clock, so travel time runs down promises and backings; the Office screen is one scene with a fixed popup order, so a same-scene District office keeps the forced-event logic; the three UI styles each need a District office; about 45 test files would need a starting-location helper.

**7b. `feasibility.md`.** (1) A negative `win_delta_boXX` loads and applies today; use an ASCII minus (`-2`, `-3--1`); a typographic minus errors; the briefing does not preview a level's booster deltas, so a loss would show only on the result screen (a Standard 1 question). (2) Seasons filter levels, Random events and Buyable events by the calendar month; follow-ups, Dated events and the marketplace's random-level purchase ignore them. (3) A Protagonist column would be read in the exporter, the level-list loop, the marketplace's random-level purchase and event-driven level reveals; no table is filtered by protagonist today. (4) A place token: only about 1,160 Text rows go through `Text.say`; most place words are in data tables that bypass it; `DataDB._fill_name_tokens()` is a ready precedent for protagonist-level tokens (fill once at protagonist selection), but office-level tokens need a display-time resolver or neutral wording; the exporter's placeholder check only matches `\w+` and would miss `{place:harbor}`.

## Open questions the data raises

| # | Question | Why it comes up |
|---|---|---|
| 1 | **Office Hours is an Either level today, but the spec says constituents' Office Hours belong to the District.** Which visitors appear at which office, and does the draw filter inside the Either room? | LV86 and LV106 are Either; 215 of 219 visitor-question promises are District; 167 visitors have no location |
| 2 | **Is the Capitol's event pool too thin?** | Random events: 37 District, 14 Capitol, 14 Either. Rule: "each office gets its own share of slots" |
| 3 | **EV47 choice C** ("Keep your appointments in the district instead") conflicts with the forced-Capitol rule. Reword, exempt, or leave EV47 unforced? Also its date is a Tuesday, though "Decision! events open the week" | `forced_and_dated.md` |
| 4 | **What does the player see while a crisis level waits at the other office?** And should a waiting crisis cancel when the meter recovers? (Today it does not.) | The warning popup is not saved |
| 5 | **A forced start ignores the hours left in the week** (today, and after) | `_on_forced_special_go` does not check hours |
| 6 | **Do the five Either room types (38 stages) that show a Capitol-looking picture today need a District background?** And `OUT_NEIGHBORHOOD` has no picture file | `backgrounds_either.csv` |
| 7 | **Real names are canon questions**: Hokkaido, Japan, China, Russia, Hokkaido Shinkansen, Tsugaru. Keep, or move to Yezo equivalents? | 1,162 hits; several are bill names |
| 8 | **Do level booster deltas need a briefing preview** if one is negative? | Standard 1 |
| 9 | **Travel at the weekend, and the weekend's 8 hours** (the spec's open question 3) | `touchpoints.md` section 2 |
| 10 | **Where does each protagonist start (Capitol or district)?** | `start_new_run` |
| 11 | **PC01 and PC04 difficulty**: keep PC01 Easy, or soften with more Either levels, a fixed District week, a bigger pool or train time as play | `hours_impact.md` |
| 12 | **Mixed levels: LV12, LV61 and LV62 are decided (District, ending at the Capitol).** Are LV10, LV21 and LV28 still right as Capitol? | `levels_location.csv`, `mixed_levels_review.md` |
| 13 | **Hand-picked place IDs**: levels that need one fixed place (Rokkasho's ports, Ishikari Fish-House Baths) | spec, "a way to name one row" |

## The two old remote branches

Both are unrelated to this task and were left alone (no merge, no change). The clone in this session was shallow (history to 2026-11-09 only), so I fetched the full history (`git fetch --unshallow`, a read-only operation on the local clone) before comparing.

| Branch | Tip | Not on `main` | Is anything missing from `main`? |
|---|---|---|---|
| `claude/happy-ramanujan-e0mrxj` (Oct 6) | `dc8d7e2` | 1 commit: "Fix workbook repair prompt: give the How To Play tab its own sheet ID" (a binary change to the old `design/CoP_Starter_Card_Stage_Data.xlsx`) | **No.** That workbook was renamed `Game_Workbook.xlsx` on Oct 27 and has since been rewritten many times. `main`'s workbook has the How To Play sheet with its own ID (44) and **no duplicate sheet IDs** across its 72 sheets, so the fix's purpose is met |
| `claude/new-session-s1juv4` (Oct 28) | `9fe1610` | 2 commits: a new start-up guide (Oct 27) and a Word copy of it (Oct 28) | **Nothing that matters.** `design/NEW_CHAT_STARTUP.md` on `main` was refreshed on Nov 17 and supersedes the Oct 27 guide. The only file not on `main` is `design/NEW_CHAT_STARTUP.docx`, a Word copy of the outdated guide. Delete both branches whenever you like (that is your call; I did not touch them) |

## Parts 0 and 1 (merged earlier)

| Part | What merged | `main` after |
|---|---|---|
| 0 | The two-offices spec and the six reference tables in `design/proposals/` (plus a `.gdignore` in the tables folder, so Godot does not import the CSVs as translations) | `6761fd5` |
| 1 | VQ380 made generic ("the beach", "Can you help?"); only the Visitor Questions cell changed. The `NavigationServer2DManager` parse lines appear on `main` too, so they come from the environment (the Godot build), not from this change | `2eb806e` |

## What is in this folder

| File | What |
|---|---|
| `REPORT.md` | This report |
| `levels_location.csv`, `levels_location_summary.json` | Item 1 |
| `backgrounds_either.csv` | Item 1b |
| `events_location.csv`, `event_promises_location.csv` | Item 2 |
| `forced_and_dated.md` | Item 2b |
| `notices_ticker_location.csv` | Item 3 |
| `place_references.csv` (2.2 MB) | Item 4 |
| `place_types.md` | Item 5 |
| `hours_impact.md`, `hours_impact_numbers.csv` | Item 6 |
| `touchpoints.md` | Item 7 |
| `feasibility.md` | Item 7b |
| `.gdignore` | So Godot does not import the CSVs as translations |

The scripts that make the CSVs and the two tables-and-notes files are in `audit/two_offices/` (`a1_levels.py`, `a1b_backgrounds.py`, `a2_events.py`, `a3_notices_ticker.py`, `a4_places.py`, `a5_place_types.py`, `a6_hours.py`, with `common.py`, `lexicon.py`, `textscan.py`, `corpus.py`). Run any of them from the repo root with `python3 -I audit/two_offices/<name>.py`; they read `data/` and the bench logs and write only this folder.

## Method notes and limits

- **All proposals are heuristic drafts.** Location comes from structure (stage modes, rooms, audiences, question pools, purpose speakers, backgrounds), then text cues as a tie-break. Where it was a judgment call, the confidence is medium or low and the reason says why.
- **Pictures were looked at**, not guessed from file names, for the backgrounds in item 1b.
- **The place and brand scan is wording-based.** It will over-report generic words and may miss a place described without a catalog word. The real-name and brand rows are the reliable ones.
- **Hours are an order of magnitude**: the bot ignores location, the logs predate the staff change, and the weekend is left out.
- **Nothing under `data/`, `design/Game_Workbook.xlsx`, `scripts/`, `scenes/` or `tests/` was touched.** `git diff main --stat` for this branch shows only `audit/two_offices/` and this folder.

## Follow-up (2026-11-19, after Cameron's review)

| File | What it adds |
|---|---|
| `mixed_levels_review.md` | A review sheet for the Mixed levels, with the case for Capitol and for District. **LV12, LV61 and LV62 are decided: District, finishing at the Capitol.** Three low-confidence levels (LV10, LV21, LV28) are still open |
| `place_worklist.md`, `place_worklist.csv`, `place_worklist_casework.csv` | The part of `place_references.csv` that needs a decision: 1,174 real-name and real-brand hits in 945 text rows (239 of them in casework tables), with a blank decision column. The 11,200 generic-word hits stay in the long file |
| `audit/two_offices/a7_worklist.py` | Rebuilds the worklist from `place_references.csv` |

The follow-ups from the first report that are not on this branch: the crisis-level fixes and the EV47 change are merged into `main`, the level-bonus briefing is on `feature/level-bonus-briefing`, the ten Capitol events are on `content/capitol-events`, and the visitor office tags are on `content/visitor-office-tags` (see `design/CHANGELOG.md` on those branches).

**Decisions recorded (2026-11-19, Cameron):** LV12, LV61 and LV62 are District levels that finish at the Capitol. `levels_location.csv` now says District, Mixed, high confidence for each, with the rule's own answer kept in the reason; the decisions are in `audit/two_offices/a1_levels.py` (`DECIDED`), and `hours_impact.md` was rebuilt from them (Capitol 74%, District 21%, Either 5% of the hours played; the travel hours move by about 0.3 a week and the conclusion is unchanged: PC01 and PC04 look harder).
