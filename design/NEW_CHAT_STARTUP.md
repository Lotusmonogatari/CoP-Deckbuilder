# Coliseum of Parliament: new session start-up (2026-10-28)

Point the assistant at this file at the start of a new session. The fuller record is `CLAUDE.md` (the brief, and an index of every dated change in `design/CHANGELOG.md`); `README.md` is the short snapshot. This guide replaces the 2026-10-27 version.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo and branches | `lotusmonogatari/cop-deckbuilder`. Work on the designated session branch; merge to `main` only after `tools/verify.sh` says "All checks passed". Everything to date is merged; the branch is level with `main`. |
| Workbook | `design/Game_Workbook.xlsx` (renamed 2026-10-27 from `CoP_Starter_Card_Stage_Data.xlsx`). |
| Content (`data/`) | 270 stage rows (226 combat), 97 levels, 70 cards, 32 organizations, 125 opponents, 50 floor-vote bills, 166 visitors, 38 events, 155 ticker lines, 6 cosmetic packages. |
| Tests | About 1,551 GUT tests (120 scripts) and 27 real-click interaction tests. `tools/verify.sh` (which also compiles every script) passes in about 2 minutes. |
| Missing | All audio files, most character and card art, 97 topic-room backgrounds, the eight generic outside scenes (`OUT_*`, show the Town Hall until drawn). No real-phone build yet (milestone M6). |

## 2. The person and the working rules

- Cameron is the designer and a legislature expert. He is not a programmer. He is often on a phone: ask decisions as popup questions (AskUserQuestion, at most four per popup), not long Markdown, and publish anything he must read as a short mobile-friendly page when it is more than a few lines. He likes tables, quick-reference layout and an executive summary on medium and long answers.
- Never decide design or canon for him. Draft, label the draft, and let him correct it. Names of characters, parties, committees and places come only from the data; keep real-world place names and proper names as written. Staff Biography and Role Flavor Text are his to write.
- Ask before adding a dependency, changing a data schema, renaming an ID, or resolving anything marked open. More than about 150 lines of new code: outline first and wait. He says "go" to approve outlines and "merge" to approve merges. **No deletion or removal without his say-so:** candidates go in `design/CLEANUP_CANDIDATES.md`.
- No sentence lives in a script (every line is a row in the Text tab, literal keys only). No design number lives in a script either: a number goes in the Balance tab and is read as `DataDB.balance.get("key")` or, from a rules file, `Levers.num("key")` / `Levers.whole("key")`. `tests/test_balance_keys.gd` fails the build if a script asks for a key the workbook does not have.
- Rules code (`scripts/rules/`) is pure, with no UI or scene access. Every rules bug fix gets a test.
- Commits: small, plain-English messages, ending with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and the `Claude-Session:` line from the session reminder. Do not open pull requests unless asked.
- Dates are YY.MM.DD everywhere (calendar square, Events "On Date", ticker from_date/to_date). `WeekCalendar.parse_date()` is the one parser.

## 3. Where things live

| Thing | Where |
|---|---|
| Source of truth | `design/Game_Workbook.xlsx`, exported by `python3 tools/export_data.py` to `data/*.json` |
| Hand-kept data | `data/rules.json`, `data/art.json` (card frames, outside scenes), `data/sounds.json`, `data/stage_types.json` |
| Rules (no UI) | `scripts/rules/` (BattleEngine, FloorVoteEngine, Ledger, WeekCalendar, CalendarStyles, OfficeTicker, StaffDelegation, Levers, ...) |
| Screens | `scripts/ui/`, `scenes/` (the Office and battle scenes are edited by hand; see CLAUDE.md section 13 before running a scene builder) |
| State, data, saves, audio, text | autoloads in `scripts/autoload/` (GameState, DataDB, SaveManager, Layout, Audio, Text) |
| Workbook tools | `tools/workbook/` (`wbx.py` with `delete_row`, `add_notes.py`, `check_formulas.py`, README, and the archive of past batch scripts) |
| Plans and reviews | `design/proposals/` (the audio plan and composer brief are `AUDIO_PLAN_2026-10-26.md` and `AUDIO_BRIEF_2026-10-26.md`), `design/review/` (content review, decisions, fixes log, `HARDCODED_AUDIT_2026-10-27.md`) |
| Guides | `design/CONTENT_GUIDE.md`, `design/EDITING_TEXT.md`, `design/PLAYTEST_CHECKLIST.md`, `design/ART_CHECKLIST.md`, `design/OUTDOOR_BACKGROUNDS.md`, `design/CLEANUP_CANDIDATES.md` |

## 4. Commands

```
tools/get_godot.sh                         # if .tools/godot is missing
.tools/godot --headless --path . --import  # after adding a class_name script
python3 tools/export_data.py               # must say "No errors" (add --accept-wording when Text rows change)
python3 tools/workbook/check_formulas.py   # Excel-repair check; verify.sh runs it
.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
tools/verify.sh                            # the whole gate, about 2 minutes; merge only on "All checks passed"
tools/verify.sh --quick                    # data, boot and unit tests only, about 1 minute (JOBS=2 limits parallel click tests)
python3 tools/outdoor_backgrounds.py       # the outside scenes: drawn?, who uses them, art prompts (--write saves the page)
xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 <scene>   # screenshots / one click test
```

`tools/verify.sh` finds every `tests/interaction/*_test.tscn` by itself, so a new click test needs no edit there. When a gate's log is checked, look for the real "All checks passed" line; words like "failed" also appear in test names. Do not edit files while a gate runs. The "Parse Error: NavigationServer2DManager" lines in GUT output are harmless noise. A screenshot driver must be added to the scene root (`get_tree().root.add_child.call_deferred(...)`), not be the scene itself, or `change_scene_to_file` frees it; delete throwaway drivers before committing.

## 5. Things that bite

1. Never save the workbook with openpyxl (it corrupts cached values). Edit with `wbx.py`; run `python3 tools/export_data.py` after every edit. `wbx.save()` drops `calcChain.xml` on purpose, and `check_formulas.py` catches the shared-formula and calc-chain problems that make Excel say "repair". Header cells need `style=''` (or `style_from=1`). Setting cells without calling `save()` loses the edit. A workbook upload from Cameron can land on `main` while you work: take his file in a merge and re-apply your edits with `wbx`.
2. A blank workbook cell exports as JSON null; guard `str(null)` and `int(null)`.
3. A new `class_name` script is invisible to tests until `godot --headless --path . --import` runs.
4. A Node must not await a timer; a lambda stored in a long-lived object must not capture `self`.
5. A "fixed" visual may not have changed anything: check a real screenshot or a click test. `PlaceholderArt` only re-reads its art when its own setters run; the calendar square and music only re-read the equipped cosmetic when told (`OfficeScreen._on_equip_cosmetic()`).
6. Containers that centre their children give them only their minimum size. `UiKit.line()` forces a full-column minimum width (760): in a narrower column set `custom_minimum_size.x = 0` or the layout runs off the right edge.
7. Content-budget tests pin visitor choice values and per-organization tastes; a content edit can trip them (`tests/test_content_budget*.gd`, `test_party_bodies.gd`, `test_bill_player_cues.gd`).
8. Agent-written text edits need guards: keep place names and proper names, keep digits, enforce word limits.
9. Staff pictures resolve `SF01_{expression}.png` first and a plain `SF01.png` last; an `OUT_*` background id shows the Town Hall until its own picture exists.
10. Copy a workbook row with `w.copy_row(...)` in `wbx`, not by reading `rows()` and writing it back (that turns numbers into text and drags formulas along). See `design/CONTENT_GUIDE.md` section 4.4 and `tools/workbook/README.md`.
11. A new copy of a family room (a topic Town Hall, caucus, committee) must be added to the Modifiers tab's Effect Target cells that name its family, or its backings silently do nothing there. Only one test checks this.
12. The export saying "No errors" is not the whole check: a room with no visitors or a bad Background ID now errors, but a thin cue pool or a missing level does not. Run `tools/verify.sh`, `python3 tools/content_depth.py` and a bot trial for new rooms.
13. The Decline generator (`tools/workbook/archive/b9/decline_options.py`) is a one-off for 17 events; add a new event's Decline by hand.

## 6. What was done most recently (2026-10-27 to 2026-10-29)

The Party Dues / Office Funds box (two lines, with 円); the Japanese name off card fronts; two lines off card backs; "send a staff member" choices greyed out with no staff; level briefing Back returns to the levels list; public room per tier moved to the Bill Level Templates tab and the unlock-tier and slot caps removed; staff pictures fall back to a plain `SF##.png`; the staff profile rearranged (picture, hiring info, biography, role flavor, tiers, buttons) with two new Staff columns; a faster `verify.sh` (about 2 minutes, `--quick`); eight generic outside background scenes with a Town Hall fallback and eleven outdoor events pointed at them; a delete-row helper; `design/CLEANUP_CANDIDATES.md`. Then, on 10-29: several pictures per event and per stage with picture terms (winter, snow), the Marketplace Funds/limit line, a View button and no-scroll offer in the deck and Rhetoric Training, centered card titles, a Decline choice on 17 Random events (wording in the Text tab, `@key` cells), a compile check in `verify.sh`, one content guide (`design/CONTENT_GUIDE.md`, tried out in a dry run) replacing the older expansion guide and prompts, and export checks for visitorless rooms and bad Background IDs. See the last entries of `design/CHANGELOG.md`.

## 7. Open items

| # | Item | Notes |
|---|---|---|
| 1 | Audio build, step 1 (approved in principle, outline not yet sent) | Five sliders (Master, Music, Cues, Effects, Interface), starting volume 50% in `data/rules.json`, a Sound page in Administration, interface-sound hooks, a stage-change hook, a vibration switch (full set of moments, on by default), settings saved. Sounds are commissioned; the brief is `design/proposals/AUDIO_BRIEF_2026-10-26.md`. |
| 2 | Content review leftovers | Events and mechanics values (EV12, EV44, EV45, EV05, AE07 note) and How to Play wording (whip discount HT28, dated events HT32, district activities) await Cameron. VQ105, VQ131-134 and VQ46-48 effect fixes need his numbers. The "no-decision actions" list is paused at his request. |
| 3 | Staff Biography and Role Flavor Text | Both Staff columns are blank; Cameron is writing them. |
| 4 | Ticker rows TK150-TK155 | Cameron is editing them. |
| 5 | Real phone build and notched-phone pass | Milestone M6; `design/DYNAMIC_SCREEN_PLAN.md`. |
| 6 | Art | Portraits, card art, topic-room backgrounds, and the eight `OUT_*` scenes (`design/OUTDOOR_BACKGROUNDS.md` has the prompts; OUT_LAKESIDE has no content mentioning lakes yet). Appeal is the weakest suit. |
| 7 | Cleanup pass | `design/CLEANUP_CANDIDATES.md`: unused Text rows and a few little-referenced tool scripts. Nothing is removed without Cameron's approval. |

Closed by Cameron on 2026-10-28 and not being pursued: click-test coverage for the day's changes, staff biography drafting by the assistant, and the Chamber of Commerce rebalance. Settled earlier: Ainu month order (January to December), the Ainu Thursday name (ニト), the hard-coded leftovers in the audit's section E (starts of 50 stay as fallbacks; the slot cap, unlock-tier cap and public room per tier are resolved).

## 8. A good first message

"Read design/NEW_CHAT_STARTUP.md, check git status and git log -5, and tell me the state in one table before we start."
