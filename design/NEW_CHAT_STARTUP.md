# Coliseum of Parliament: new session start-up (2026-10-27)

Point the assistant at this file at the start of a new session. The fuller record is `CLAUDE.md` (the brief, and an index of every dated change in `design/CHANGELOG.md`); `README.md` is the short snapshot. This guide replaces the 2026-10-14 version.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo and branches | `lotusmonogatari/cop-deckbuilder`. Work on the designated session branch (this one was `claude/new-session-s1juv4`), merge to `main` only after `tools/verify.sh` says "All checks passed". Everything to date is merged; the branch is level with `main`. |
| Workbook | **`design/Game_Workbook.xlsx`** (renamed 2026-10-27 from `CoP_Starter_Card_Stage_Data.xlsx`; older notes using the old name mean this file). |
| Content (data/) | 270 stage rows (226 combat), 97 levels, 70 cards, 32 organizations, 125 opponents, 50 floor-vote bills, 166 visitors, 38 events, 155 ticker lines, 6 cosmetic packages. |
| Tests | About 1,535 GUT tests (120 scripts) and 27 real-click interaction tests; `tools/verify.sh` passes. |
| Missing | All audio files, most character and card art, 97 topic-room backgrounds. No real-phone build yet (milestone M6). |

## 2. The person and the working rules

- **Cameron** is the designer and a legislature expert. He is **not a programmer**. He is often on a phone: **ask decisions as popup questions (AskUserQuestion), not long Markdown**, and publish anything he must read as a short mobile-friendly page when it is more than a few lines. He likes **tables, quick-reference layout and an executive summary** on medium and long answers.
- **Never decide design or canon for him.** Draft, label the draft, and let him correct it. Names of characters, parties, committees and places come only from the data; keep real-world place names and proper names as written.
- Ask before adding a dependency, changing a data schema, renaming an ID, or resolving anything marked open. More than about 150 lines of new code: outline first and wait. He has said "go" to approve outlines and "merge" to approve merges.
- **No sentence lives in a script** (every line is a row in the Text tab, literal keys only). **No design number lives in a script** either: a number goes in the Balance tab and is read as `DataDB.balance.get("key")` or, from a rules file, `Levers.num("key")` / `Levers.whole("key")`. `tests/test_balance_keys.gd` fails the build if a script asks for a key the workbook does not have.
- Rules code (`scripts/rules/`) is pure, with no UI or scene access. Every rules bug fix gets a test.
- **Commits**: small, plain-English messages, ending with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and the `Claude-Session:` line from the session reminder. Do not open pull requests unless asked.
- **Dates are YY.MM.DD everywhere** (calendar square, Events "On Date", ticker `from_date`/`to_date`). `WeekCalendar.parse_date()` is the one parser.

## 3. Where things live

| Thing | Where |
|---|---|
| Source of truth | `design/Game_Workbook.xlsx`, exported by `python3 tools/export_data.py` to `data/*.json` |
| Hand-kept data | `data/rules.json`, `data/art.json` (including `card_frames`), `data/sounds.json`, `data/stage_types.json` |
| Rules (no UI) | `scripts/rules/` (BattleEngine, FloorVoteEngine, Ledger, WeekCalendar, CalendarStyles, OfficeTicker, `Levers`, ...) |
| Screens | `scripts/ui/`, `scenes/` (Office and battle scenes are edited by hand; see CLAUDE.md section 13 before running a scene builder) |
| State, data, saves, audio, text | autoloads in `scripts/autoload/` (GameState, DataDB, SaveManager, Layout, Audio, Text) |
| Workbook tools | `tools/workbook/` (`wbx.py`, `add_notes.py`, `check_formulas.py`, README, and the archive of past batch scripts) |
| Plans and reviews | `design/proposals/` (plans; the audio plan and composer brief are `AUDIO_PLAN_2026-10-26.md` and `AUDIO_BRIEF_2026-10-26.md`), `design/review/` (the content review, decisions, fixes log, and `HARDCODED_AUDIT_2026-10-27.md`) |
| Guides | `design/WORKBOOK_EXPANSION_GUIDE.md`, `design/EDITING_TEXT.md`, `design/PLAYTEST_CHECKLIST.md`, `design/ART_CHECKLIST.md` |

## 4. Commands

```
tools/get_godot.sh                         # if .tools/godot is missing
.tools/godot --headless --path . --import  # after adding a class_name script
python3 tools/export_data.py               # must say "No errors" (add --accept-wording when Text rows change)
python3 tools/workbook/check_formulas.py   # Excel-repair check; verify.sh runs it
.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
tools/verify.sh                            # the whole gate, 10 to 15 minutes
xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . tests/interaction/<name>_test.tscn
```

Run the full gate in the background and wait for "All checks passed": `(setsid nohup tools/verify.sh > /tmp/<name>.log 2>&1 &)`, then watch the log. Do **not** `pkill -f verify.sh` (it kills your own shell); stop a run with `kill -TERM -<pid>` on its process group. **Never edit files while a gate is running**; stop it and restart, or its result means nothing. Merge only on a clean run of the final code. The "Parse Error: NavigationServer2DManager" lines in GUT output are harmless noise.

## 5. Things that bite

1. **Never save the workbook with openpyxl** (it corrupts cached values). Edit with `wbx.py`; run `python3 tools/export_data.py` after every edit. `wbx.save()` drops `calcChain.xml` on purpose, and `check_formulas.py` catches the shared-formula and calc-chain problems that make Excel say "repair". Header cells need `style=''`. Setting cells without calling `save()` loses the edit.
2. A blank workbook cell exports as JSON `null`; guard `str(null)` and `int(null)`.
3. A new `class_name` script is invisible to tests until `godot --headless --path . --import` runs.
4. A Node must not `await` a timer; a lambda stored in a long-lived object must not capture `self`.
5. A "fixed" visual may not have changed anything: check a real screenshot or a click test. `PlaceholderArt` only re-reads its art when its own setters run, and the calendar square and music only re-read the equipped cosmetic when told (see `OfficeScreen._on_equip_cosmetic()`).
6. Containers that centre their children give them only their minimum size: a scroll area or button with a minimum width of 0 can collapse to nothing, and a row of many buttons squeezes each to a sliver. Give real widths; prefer a column.
7. Content-budget tests pin visitor choice values and per-organization tastes; a content edit can trip them (see `tests/test_content_budget*.gd`, `test_party_bodies.gd`, `test_bill_player_cues.gd`).
8. Agent-written text edits need guards: keep place names and proper names, keep digits, enforce word limits (`scratchpad/fix/apply.py` pattern; not in the repo).

## 6. What was done most recently (2026-10-26 to 2026-10-27)

Content review fixes applied; card and shop decisions; singular "1 hour"; calendar as YY.MM.DD with the weekday; Era Name and Ainu calendar packages (the Ainu one now shows katakana day names); audio plan and a composer brief, with haptics decided; Marketplace item tiles show quantity only in a sideways row; appearance buttons stack; calendar and music change the moment they are equipped; hard-coded numbers, staff roles, suit names and card frames moved to the workbook and data files; ticker lines gated by weekday, date range and a yearly repeat; Excel repair message fixed; workbook renamed. See the last entries of `design/CHANGELOG.md`.

## 7. Open items

| # | Item | Notes |
|---|---|---|
| 1 | **Audio build, step 1** (approved in principle, outline not yet sent) | Five sliders (Master, Music, Cues, Effects, Interface), starting volume 50% in `data/rules.json`, Sound page in Administration, interface-sound hooks, stage-change hook, **vibration switch** (full set of moments, on by default), settings saved. Sounds are commissioned; brief is `design/proposals/AUDIO_BRIEF_2026-10-26.md`. |
| 2 | Content review leftovers | Events and mechanics values (EV12, EV44, EV45, EV05, AE07 note) and How to Play wording (whip discount HT28, dated events HT32, district activities) await Cameron. VQ105, VQ131-134, VQ46-48 effect fixes need his numbers. The "no-decision actions" list is **paused** at his request. |
| 3 | Confirm with Cameron | Ainu month-name order (taken as January to December); Thursday Ainu name (ニト shown, チクニト is the alternative); the six template ticker rows TK150-TK155 (edit or delete); which card-back preference line he meant removed. |
| 4 | Hard-coded leftovers | `design/review/HARDCODED_AUDIT_2026-10-27.md` section E lists what was deliberately left (segment and standing starts of 50, slot cap 10, public room per tier, level-unlock tier cap). |
| 5 | Real phone build and notched-phone pass | Milestone M6; `design/DYNAMIC_SCREEN_PLAN.md`. |
| 6 | Art, balance and older review leftovers | Portraits, card art, backgrounds; Appeal is the weakest suit; Chamber of Commerce is displeased more than pleased (381 vs 256) and could be spread further. |

## 8. A good first message

"Read `design/NEW_CHAT_STARTUP.md`, check `git status` and `git log -5`, and tell me the state in one table before we start."
