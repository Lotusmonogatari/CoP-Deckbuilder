# Coliseum of Parliament: new session start-up (2026-11-20)

Point the assistant at this file at the start of a new session. The brief and the working rules are in `CLAUDE.md`; `README.md` is the short snapshot. This guide replaces the 2026-11-17 version.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo and branches | `lotusmonogatari/cop-deckbuilder`. Work on the designated session branch; merge to `main` only after `tools/verify.sh` says "All checks passed". The two-offices build (slices 1 to 7) is merged to `main`, one `--no-ff` merge per slice. |
| Workbook | `design/Game_Workbook.xlsx` |
| Content (`data/`) | 289 stage rows, 122 levels, 70 cards, 32 organizations, 131 opponents, 50 floor-vote bills, 167 visitors and 429 visitor questions, 103 events (EV105 to EV110 are train encounters), 44 shop items (SH42 to SH44 are travel tickets), 21 staff, 64 staff tasks in 8 families, 180 bill components, 8 cosmetic packages, 112 Places rows, 1,329 Text rows, 359 Balance levers |
| Tests | About 2,280 GUT tests (205 scripts) and 52 real-click interaction tests. `tools/verify.sh` (export, compile of every script, unit tests, click tests, and the text sweep in three styles at three text sizes) takes about 9 minutes. |
| Missing | All audio files, most character art (opponents, students, visitors, PC02/PC03), 8 goods icons, `OUT_NEIGHBORHOOD`, and the two-offices art (four District office pictures, `TRAIN_INTERIOR`, `TICKET_*` icons, the three District rooms; a labelled placeholder shows until each exists). No real-phone build yet (milestone M6). |

## 2. The document map

| Read | For |
|---|---|
| `design/GAME_DESIGN.md` | What the game is and how its parts connect, as a story |
| `design/GAME_SYSTEMS.md` | **The exact mechanics**: resources, growth and decline, where the player chooses, and every piece of run state |
| `design/INFORMATION_STANDARDS.md` | **How the player must be told things**: what is shown before and after a choice, the terms, who may say what, layout |
| `design/ARCHITECTURE.md` | How the code is organised, the rules-versus-screens split, pitfalls |
| `design/CONTENT_GUIDE.md` | How to write levels, stages, events and the content they depend on |
| `design/EDITING_TEXT.md` | How to reword existing text, tab by tab |
| `design/STAFF_ASSIGNMENTS_RUBRIC.md` | The measurable test rubric for the staff mechanic, and how to run it |
| `design/CHANGELOG.md` | A summary of September and October, then every dated change since 2026-11-01 |
| `design/CLEANUP_CANDIDATES.md` | Things that look removable. Nothing is deleted without Cameron's say-so |

## 3. The person and the working rules

- Cameron is the designer and a legislature expert. He is not a programmer. He is often on a phone: ask decisions as popup questions (AskUserQuestion, at most four per popup), not long Markdown, and publish anything he must read as a short mobile-friendly page when it is more than a few lines. He likes tables, quick-reference layout and an executive summary on medium and long answers.
- Never decide design or canon for him. Draft, label the draft, and let him correct it. Names of characters, parties, committees and places come only from the data. Staff Biography and Role Flavor Text are his to write.
- Ask before adding a dependency, changing a data schema, renaming an ID, or resolving anything marked open. More than about 150 lines of new code: outline first and wait. He says "go" to approve outlines and "merge" to approve merges. **No deletion or removal without his say-so:** candidates go in `design/CLEANUP_CANDIDATES.md`.
- No sentence lives in a script and no design number lives in a script (workbook Text and Balance tabs; `tests/test_balance_keys.gd` enforces the second).
- Rules code (`scripts/rules/`) is pure, with no UI or scene access. Every rules bug fix gets a test.
- Commits: small, plain-English messages, ending with the `Co-Authored-By:` and `Claude-Session:` lines the session reminder gives. Do not open pull requests unless asked.
- Dates are YY.MM.DD everywhere. `WeekCalendar.parse_date()` is the one parser.

## 4. Commands

```
tools/get_godot.sh                         # if .tools/godot is missing
.tools/godot --headless --path . --import  # after adding a class_name script
python3 tools/export_data.py               # must say "No errors" (add --accept-wording when Text rows change)
python3 tools/workbook/check_formulas.py   # Excel-repair check; verify.sh runs it
.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
tools/verify.sh                            # the whole gate, about 9 minutes; merge only on "All checks passed"
tools/verify.sh --quick                    # data, boot and unit tests only (JOBS=2 limits parallel click tests)
python3 tools/cue_coverage.py              # which opponent bill-line pools would repeat inside 30 turns
python3 tools/outdoor_backgrounds.py       # the outside scenes: drawn?, who uses them, art prompts
xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 <scene>   # screenshots / one click test
```

When a gate's log is checked, look for the real "All checks passed" line; words like "failed" also appear in test names. Do not edit files while a gate runs. The "Parse Error: NavigationServer2DManager" lines in GUT output are harmless noise.

## 5. Things that bite

The code-level ones are in `design/ARCHITECTURE.md` section 8. Workbook and content ones:

1. **Never save the workbook with openpyxl** (it corrupts cached values). Edit with `tools/workbook/wbx.py` and run `python3 tools/export_data.py` after every edit. Header cells need `style=''` (or `style_from=1`). Setting cells without `save()` loses the edit. Copy a row with `w.copy_row(...)`, not by reading `rows()` and writing it back. A workbook upload from Cameron can land on `main` while you work: take his file in a merge and re-apply your edits with `wbx`.
2. A blank workbook cell exports as JSON null; guard `str(null)` and `int(null)`.
3. Agent-written text edits need guards: keep place names and proper names, keep digits, enforce word limits.
4. Content-budget tests pin visitor choice values and per-organization tastes; a content edit can trip them.
5. The export saying "No errors" is not the whole check: run `tools/verify.sh`, `python3 tools/content_depth.py` and a bot trial for new rooms.
6. The workbook's structured columns are the truth: when text and a column disagree, change the text. Drafting rules (the discard tiers) only warn.
7. Protagonist rows in the Opponents tab (OP06, OP22, OP35, OP40) are never seated; a test enforces it.
8. Tests must read workbook values, never type them.
9. Staff pictures resolve `SF01_{expression}.png` first and a plain `SF01.png` last; an `OUT_*` background id shows the Town Hall until its own picture exists.
10. The Decline generator under `tools/workbook/archive/` is a one-off; add a new event's Decline by hand (1.5 times the shortfall of the staff choice against choice A).
11. Shop item IDs were renumbered (2026-10-04): quote an item by name in prose, and never assume an old ID.
12. **Offices in tests.** A real-click driver must stand at the office of the level, event or promise it uses (`GameState.office_location = Offices.CAPITOL` or `DISTRICT`), or the list will not show it. `verify.sh` exports `COP_NO_RANDOM_EVENTS`, `COP_NO_CONTINUE_DELAY` and `COP_NO_TRAVEL_FADE`. Unit tests that count levels or events by office move with the data (`test_offices_travel`).
13. **Place tokens** (`{place:harbor}`, `{office_city}`) are filled when a protagonist is chosen (`DataDB.use_protagonist`); text read before that shows the token. An event that uses a token must list its type in Needs Place.
14. **The strategy bot knows the offices** (`tools/strategy_playtest.gd`): `PLAYTEST_OFFICES=0` plays the older way (offices ignored, no travel hours), the default plays as a batching player on the rail pass. Runs of 30 weeks take about 1 to 2 minutes each; `tools/strategy_runs.sh` runs four at a time.

## 6. What was done most recently (2026-11-06 to 2026-11-20)

Details are the sections at the end of `design/CHANGELOG.md`. In short:

- **Two offices (new, 2026-11-20, slices 1 to 7):** the player stands at the Capitol (Sapporo) or a District office (Noheji, Akeno Shinmachi, Teine Ward, Daikoku for PC01 to PC04). Levels, events, promises, notices, ticker lines and visitors carry a `Location`; the level list shows only what can start where the player stands; a trip is a train strip drag (or tap) that spends hours (7 / 1 / 1 / 6 by rail pass); tickets in the Marketplace (SH42 to SH44) change the mode; 24 "mixed" levels charge their built-in trips (`Travel Trips`); one trip in 8 by pass or paid ticket brings a train encounter (EV105 to EV110); the Places tab and `{place:...}` tokens give each district its own names; eight protagonist levels (LV115 to LV122) use the new Protagonist column. Rules: `GAME_SYSTEMS.md` section 3.1; plan and decisions in `design/proposals/TWO_OFFICES_*_2026-11-20.md`; the hours re-simulation and the PC01 and PC04 rating options in `design/review/two_offices_hours_2026-11-20/REPORT.md`. Everything written for it (prices, encounters, place names, the eight levels, text) is a draft for Cameron.
- **P9 to P12 (2026-11-17 to 2026-11-19):** the three UI styles (Living Office, Broadcast, Woodblock; `UiStyles`), End of Week Payments, the Brand B start screen and app icon, built-in problem reporting (hold three fingers for two seconds), the card hand and play-spot rework, Resign by holding five seconds, crisis levels that cancel on recovery, and the level briefing redrawn (`LevelBriefing` pure data, `LevelBriefingView`, three style palettes).

- **Stage results and saves:** a stage's result is saved when shown, so closing the app on a loss still counts it; every button press saves; haptics (with a setting); the Android back button is deliberately inert.
- **Resign:** a two-part screen (normal layout, then the mirrored goodbye and the title), available only while all three standings are far down.
- **Money:** party dues are 50,000 + 10,000 per 15 Party support above 40 + a share of the week's earnings (5% Relaxed); the national awareness dues relief is 50,000; Tier 0 stage pay is capped at 30,000; the Funds-cap petition leaves the Marketplace at the ceiling.
- **Lost Acts:** a failed win/lose stage in a bill level shows party-colour or gaffe cues; a lost Act records an absent vote and the bill returns after 7,488 hours. A bill the player voted on never returns; absent or abstained ones do.
- **Rooms and items:** the lobbyist's organization always applies scrutiny; the TV debate bar shows the opponent again; items that take hours show a greyed Use button when there is no time; Your Record's changes sit behind buttons.
- **Content:** transitions for custom-bill stages; EV83 to EV94 (twelve events favorable to six organizations); visitors 58 to 78 and 144 and 167 (VI167 has no stage, reward, penalty or questions yet, so it never appears); the Japanese font was re-subset for new names.
- **Characters list (new, 2026-11-13):** Administration, Characters. A scrolling list of every opponent and visitor; the button colour is the party colour, the player's party colour for a party body with no named party, or one muted tier colour (nine Balance rows). Unmet people read 誰ですか。 (a deliberate exception to English-first). "Met" is saved in `GameState.met_characters` and recorded when someone actually appears. Rules in `scripts/rules/CharacterCodex.gd`, UI in `scripts/ui/CharacterCodexPanel.gd`.
- **Staff Assignments (new, 2026-11-16):** staff have wages and Loyalty; each workday delivers tasks (64 tasks, 8 icon families, a ramp from 0 tasks in week 1 to 15) that the player gives to staff on Management > Staff Assignments; Due tasks nobody takes cost a penalty; events can delegate to staff. A person's day is 8, 9 or 10 hours by rank. Read `design/GAME_SYSTEMS.md` (Addendum: staff wages, Loyalty, daily tasks) and `design/STAFF_ASSIGNMENTS_RUBRIC.md` (the test rubric; run `audit/tests/staff_rubric_run.tscn` after any change to the staff tabs or rules).
- **Items with uses (new, 2026-11-16):** a Shop row's Uses column; copies wear out; six office-supply items SH36 to SH41 (Printer, Shredder, Flex-Work, Priority Inbox, Commendation Gift, Lunch Delivery) and the Kaiju-sized coffee and tea (2 uses) are the staff items. The Printer, Shredder and Priority Inbox act at once.
- **Words stay whole:** the `TextFit` autoload stops a wrapped word splitting across lines.
- **Hard-coded numbers moved (2026-11-17):** the Restless boost share, a patron request's tries, and four fixed ids (training coupon, bill vote stage, the two party-dues organizations) are now Balance and Rules rows.
- **Reviews (read-only reports):** `audit/` (project audit), `audit/gameplay/` (gameplay review), `design/review/ORG_REPRESENTATION_2026-11-13.md` and `ORG_OUTCOMES_2026-11-13.md` (how events and visitors treat each organization).

- **Cleanup pass (2026-11-20):** the old Level Bonus block, 14 retired briefing Text rows and some dead code were removed; what was kept and why, and the new candidates, are at the end of `design/CLEANUP_CANDIDATES.md`.
- **Art list for the two-offices build:** `design/ART_ASSETS_TWO_OFFICES_2026-11-20.xlsx` (14 assets: asset ID, file name, text name, how it is used, size, whether it is wired).

## 7. Open items

| # | Item | Notes |
|---|---|---|
| 1 | Audio build, step 1 (approved in principle, outline not yet sent) | Five sliders, a Sound page in Administration, interface and stage-change hooks, vibration switch. Brief: `design/proposals/AUDIO_BRIEF_2026-10-26.md` |
| 2 | Real phone build | Milestone M6; Image Pan's tilt direction and the new portrait sizes need a real phone |
| 3 | Art | Opponents, students, visitors, PC02/PC03, 8 goods icons, `OUT_NEIGHBORHOOD`. Character art is Cameron's pipeline; Claude writes prompts on request |
| 4 | Election strength | Built and shown; fires nothing yet. What it should unlock is Cameron's to decide |
| 5 | Unused stored numbers | `segment_favorability` is stored but read by nothing since staff rewards moved to organizations; the Sanban tab's low/high "consequence" notes are text only |
| 6 | Cleanup | `design/CLEANUP_CANDIDATES.md` (old working papers in `design/review/`, `design/proposals/`, `design/bench/`, balance audits) awaits Cameron's approval |
| 7 | Ministers | Five ministers sit in every TV debate; Cameron chose to leave it |
| 8 | MC²T results | `design/review/MC2T_REPORT_2026-11-06.md`: touch targets (93% under 44 pt), no mid-stage save, "Boosters" naming clash; kit ready for a 5-player round on a real phone. Decisions are Cameron's |
| 9 | Gameplay review leftovers | `audit/gameplay/00-summary.md`: Tier 1 and 2 pay less XP per hour than Tier 0 and repeats do not decay; meters hit their ceilings by week 4 to 8; no audio. Cameron decides |
| 10 | Taxpayers' Alliance | Still the most over-represented organization with net negative outcomes (EV83 choice C and the Decline rows); a rebalance was offered, not approved |
| 11 | VI167 | Done 2026-11-13 as a draft: 16 rooms, standing and six questions (VQ424-VQ429). Cameron to rewrite |
| 12 | Characters list | Colours and the nine Balance rows are drafts; opponents faced before 2026-11-13 show as unmet until they reappear; unmet popup not yet seen on a phone |
| 15 | Staff Assignments tuning | The rubric (`design/STAFF_ASSIGNMENTS_RUBRIC.md`) has no FAIL; R4.2 (net points a week) is a WARN and the week 4 to 5 ramp step is a cliff (`audit/staff_tasks_tuning.md`). Item prices and the six office-supply items are drafts. Cameron decides |
| 14 | Party-support-locked events | Own-party events and levels that open at a Party support level; proposal in `design/proposals/PARTY_SUPPORT_LOCKED_EVENTS_2026-11-16.md`; needs the Party support re-tune first |
| 16 | Two offices: Cameron's review list (closed on 2026-11-20: no District nudge, the car price stays, LV10 stays, four tickets are enough) | The six train encounters, the 118 place names (six of them, for Misawa, Tohoku and Shichinohe, added 2026-11-20 as drafts), the 29 rewritten events (and the 10 left as written: EV01, EV14, EV18, EV23, EV34, EV51, EV85, EV88, EV92, EV93), the eight protagonist levels, the Text rows. Settled by Cameron on 2026-11-20: the ratings stay (PC01 Easy, PC04 Very Hard), PC01 starts with four plane tickets and PC04 with nothing, ticket prices 10,000 / 30,000 / 60,000円, the spellings Daikoku and Akeno Shinmachi (明野新町), and that Misawa, Tohoku and Shichinohe lie inside Aomori Block 3. Art IDs to draw: `DISTRICT_OFFICE_PC01` to `PC04`, `TRAIN_INTERIOR`, `TICKET_*`, `DISTRICT_LOBBYIST_MEETING`, `DISTRICT_POLICY_STUDY`, `DISTRICT_AMBUSH_STREET`, `OUT_NEIGHBORHOOD` |
| 17 | Pinned art (Cameron, 2026-11-20) | `DISTRICT_LEGISLATURE_1` to `_3` and `DISTRICT_LIBRARY_1` and `_2` are in `assets/backgrounds/` and not used by anything: **pinned for future stages and events, after P14**. |
| 18 | P13 and P14 | **P13 (the Office screens on one frame) is merged** (`design/review/p13_office_screens_2026-11-20/REPORT.md`). **P14 (the 32 remaining screens) is next**: the roadmap is `design/proposals/P13_P14_ROADMAP_2026-11-20.md`; the package is in the repo's upload, not yet copied in; groups 1 to 3 first, then P14b. Cameron's decisions so far: two `panel/` branches, party discs show the leader's portrait else a colour disc with the single kanji (initials BU, YHP, FP, FPI, KJT, CI; Japanese names 仏党, エゾの遺産党, 辺境党, 五無所属, 経済自由党, 国家維新党). |
| 13 | Branches | Four old remote branches (`ccr-1bbd9851-yg8on5`, `claude/happy-ramanujan-e0mrxj`, `claude/optimistic-noether-1j0yqh`, `claude/new-session-s1juv4`) could not be deleted from a session (no permission); Cameron asked for them to be deleted, so he must do it on GitHub |

## 8. A good first message

"Read design/NEW_CHAT_STARTUP.md, check git status and git log -5, and tell me the state in one table before we start."
