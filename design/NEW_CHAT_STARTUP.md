# Coliseum of Parliament: new session start-up (2026-10-31)

Point the assistant at this file at the start of a new session. The fuller record is `CLAUDE.md` (the brief, and an index of every dated change in `design/CHANGELOG.md`); `README.md` is the short snapshot. This guide replaces the 2026-10-28 version.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo and branches | `lotusmonogatari/cop-deckbuilder`. Work on the designated session branch; merge to `main` only after `tools/verify.sh` says "All checks passed". Everything to date is merged; the branch is level with `main`. |
| Workbook | `design/Game_Workbook.xlsx` (renamed 2026-10-27 from `CoP_Starter_Card_Stage_Data.xlsx`). |
| Content (`data/`) | 273 stage rows (229 combat), 101 levels, 70 cards, 32 organizations, 131 opponents, 50 floor-vote bills, 166 visitors and 397 dilemmas, 55 events, 32 shop items, 155 ticker lines, 6 cosmetic packages. |
| Tests | About 1,600 GUT tests (130 scripts) and 30 real-click interaction tests. `tools/verify.sh` (which also compiles every script) passes in about 2-3 minutes. |
| Missing | All audio files, most character art (122 opponents, 6 students, 166 visitors, PC02/PC03), 8 goods icons, `OUT_NEIGHBORHOOD`. No real-phone build yet (milestone M6). |

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
13. The Decline generator (`tools/workbook/archive/b9/decline_options.py`) is a one-off for 17 events; add a new event's Decline by hand (the rule: 1.5x the shortfall of the staff choice against choice A).
14. The workbook's structured columns are the truth (Cameron, 2026-10-31): when text and a column disagree, change the text. Drafting rules (the discard tiers) only warn.
15. Protagonist rows in the Opponents tab (OP06, OP22, OP35, OP40) are never seated; a test enforces it.
16. Tests must read workbook values, never type them (a retune must not break a test).

## 6. What was done most recently (2026-10-29 to 2026-10-31)

10-29/30: the design document refreshed; `wbx.copy_row()`; the Assets tab's backgrounds brought in line with the art (Generic / Pool / Fallback); staff biographies and role flavor from Cameron's upload; taller event pictures; **Image Scroll and Image Pan** (drag and tilt every drawn background; switches in Administration); playtest fixes (no opponent names in briefings, **seasons** for levels and events, no Friday dues line, hours in briefings, **per-protagonist starting items**, the coupon off the Marketplace); the **briefing template** (totals, durations, gold lines; one-stage levels show only the totals); two lakeside events and a cultural-center event with Cameron's art; card titles centered; victory/defeat poses visible.

10-31: **events that lead to a stage** (Starts Level / Event Only columns, briefing with Back to the event, duration ranges, "Insufficient Work Hours"; Radio Debate ST271, Radio Call-In ST272, Campus Q&A ST273; LV98-LV101; EV51-EV53 and converted EV27/EV36/EV50); six placeholder students; room-cast and organization-balance audits (`design/review/BALANCE_AUDIT_2026-10-31.md`) and Cameron's decisions applied (level rewards so every organization has 3+, temple and small-business dilemmas, eight organization events EV54-EV61, Campus Q&A's own 45 questions, the full lobbyist cast in ST28); a test that protagonist rows (OP06, OP22, OP35, OP40) are never seated; the drafting rules for discard cards made advisory (structured columns are the truth); the **choice honesty rewrite** of all 452 choice sets (`tools/choice_audit.py`); **commitments** (choices cost hours, Funds or items; promises with deadlines kept from the Office's Promises panel; follow-up events EV62-EV64; regional Hokkaido/Aomori goods SH25-SH32). See the last entries of `design/CHANGELOG.md`.

## 7. Open items

The list for Cameron's return, with the interim choice made for each, is `design/review/OPEN_ITEMS_2026-10-31.md`. Standing items:

| # | Item | Notes |
|---|---|---|
| 1 | Audio build, step 1 (approved in principle, outline not yet sent) | Five sliders, a Sound page in Administration, interface and stage-change hooks, vibration switch. Brief: `design/proposals/AUDIO_BRIEF_2026-10-26.md`. |
| 2 | Content review leftovers | Closed 2026-10-31 (see the change log, "Open items closed"). |
| 3 | Student names | OP126-OP131 are "Student A" to "Student F"; Cameron names them. |
| 4 | Real phone build | Milestone M6; Image Pan's tilt direction needs a real phone. |
| 5 | Art | 122 opponents, 6 students, 166 visitors, PC02/PC03, 8 goods icons (SH25-SH32), `OUT_NEIGHBORHOOD`. Character art is Cameron's pipeline; Claude writes prompts on request. |
| 6 | Cleanup pass | `design/CLEANUP_CANDIDATES.md`; nothing removed without Cameron's approval. |
| 7 | Ministers | Five ministers sit in every TV debate; Cameron chose to leave it. |

## 8. A good first message

"Read design/NEW_CHAT_STARTUP.md, check git status and git log -5, and tell me the state in one table before we start."
