# Coliseum of Parliament: new chat start-up (2026-10-14)

Paste this (or point the assistant at it) at the start of a new chat. The fuller record is `CLAUDE.md` (the brief and a dated log of every change); `README.md` is the short snapshot.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo / branches | `lotusmonogatari/cop-deckbuilder`. Everything is merged to `main`; the working branch `ccr-1bbd9851-yg8on5` is level with it, tree clean. |
| Content | 120 stage rows (97 combat rooms), 82 levels, 50 floor-vote bills, 30 organisations (each with a backing), 125 opponents, 54 cards, 6 real parties. |
| Tests | 1,086 GUT tests (75 scripts) pass. 16 real-click interaction tests and `tools/verify.sh` pass ("All checks passed"). |
| Art | All 30 organisation icons, 20 shop icons, 2 cosmetic icons drawn. Missing: 5 audience icons (SG01-SG05), staff/visitor/opponent/card art, 97 topic-room backgrounds, all audio. |
| Mobile | Not yet run on a real Android/iOS device (milestone M6). Layout checked only in desktop screenshots at several shapes and text sizes. |

## 2. The people and the working rules

- **Cameron** is the designer and a domain expert in legislatures. He is **not a programmer** and will not write or debug code. Explain changes in plain English, briefly.
- **He likes tables, a quick-reference layout, and an executive summary on medium and long answers.**
- **Never decide design or canon for him.** Draft, label the draft ("Cameron's to correct") and move on. If a choice touches canon, stop and ask. Character, party, committee and position names come only from the data.
- Ask before adding a dependency, changing a data schema, renaming an ID, or resolving anything marked open. A task over about 150 lines of new code: outline the plan first.
- **No sentence lives in a script.** Every line the game says is a row in the workbook's Text tab (`design/EDITING_TEXT.md`).
- Rules code (`scripts/rules/`) is pure and has no UI. Every rules bug fix gets a test.
- Commit small, with plain-English messages. Commit trailers: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and the session link line given in the session reminder. Push to the designated working branch, then merge to `main` once `tools/verify.sh` passes. Do not open pull requests unless asked.

## 3. How the project is built

| Thing | Where |
|---|---|
| Source of truth for all content | `design/CoP_Starter_Card_Stage_Data.xlsx` (the workbook), exported by `python3 tools/export_data.py` into `data/*.json` |
| Rules (no UI) | `scripts/rules/` (BattleEngine, FloorVoteEngine, MetaRules, Ledger, ...) |
| Screens | `scripts/ui/` and `scenes/` |
| Game state, data, saves, layout, audio | autoloads in `scripts/autoload/` (GameState, DataDB, SaveManager, Layout, Audio, Text) |
| Art by ID | `assets/` (scheme in `data/art.json`; checklist `design/ART_CHECKLIST.md`) |
| Workbook editing tool and the batch-builder archive | `tools/workbook/` |
| Tests | `tests/` (GUT) and `tests/interaction/` (real clicks) |
| The full brief and change log | `CLAUDE.md` (long; search it by topic instead of reading it all) |

## 4. Commands that matter

```
tools/get_godot.sh                     # if .tools/godot is missing
.tools/godot --headless --import       # needed after adding a new class_name script
python3 tools/export_data.py           # workbook -> data/*.json (must say "No errors")
tools/verify.sh                        # the whole gate; merge only on "All checks passed"
tools/stress.sh                        # slow: fuzzers + late-game stress, before releases
.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_x.gd -gexit
xvfb-run -a --server-args="-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 <scene>
python3 tools/content_depth.py         # each room holds 3x the content a run meets
python3 tools/art_checklist.py         # what art is drawn
python3 tools/merge_icons.py <folder>  # check and merge returned icons (--apply to copy)
```

Screenshots need a real display (the xvfb line), not `--headless`. Use a throwaway driver script and delete it before committing. Run the four protagonists' bot playtests one after another, never in parallel.

## 5. Things that bite (learned the hard way)

1. **Never save the workbook with openpyxl.** It silently corrupts cached values. Use the raw-XML helper `tools/workbook/wbx.py` (see `tools/workbook/README.md`; `python3 tools/workbook/selftest.py` checks it), then confirm a clean export and that only the intended sheets changed. openpyxl is safe for reading.
2. A blank workbook cell exports as JSON `null`. Guard `str(null)` ("<null>") and `int(null)`.
3. A new `class_name` script is not seen by tests until `godot --headless --import` runs.
4. Leaks: a Node must not `await` a timer (use a `Timer` child); a lambda stored in a long-lived object must not capture `self`.
5. A change that "applied" may not have: look at a real screenshot before saying a visual fix works (the Marketplace column switch silently failed once).
6. Text keys the exporter cannot see (built from variables) show as "unused"; a removed row shows a raw key on screen.
7. The bot (`tools/playtest_optimal.gd`) is stronger than a person; read its win rates as a ceiling.

## 6. What was done most recently (2026-10-14)

Transitions fixed (a player thought when no staff can speak, none on Media Ambush, audit); a gap-filling content batch; a full review (`design/REVIEW_2026-10-14.md`) and fixes (stuck stage screens get an exit, safer saves with a backup, three engine bugs); a late-game stress test and two memory leaks fixed; thousands separators on amounts; Marketplace tiles fixed at Large text; the twelve new organisation icons merged; **Boosters panel**: audience rows get icons (placeholders until drawn), prices have commas, and drafted backings M33-M46 so every organisation has one.

## 7. Open items, in a sensible order

| # | Item | Notes |
|---|---|---|
| 1 | Draw the 5 audience icons SG01-SG05 | Prompt ready: `design/ICON_PROMPT_AUDIENCE.md`; merge with `tools/merge_icons.py` |
| 2 | Cameron to review the drafts | Backings M33-M46, Ainu icons BO28/BO29, Law Effects, theme mappings, opponent and transition cues: all marked drafts |
| 3 | A first real phone build and a notched-phone pass | Milestone M6; dynamic-screens plan step 6 (`design/DYNAMIC_SCREEN_PLAN.md`) |
| 4 | Art triage | Protagonist portraits for PC02/PC03 first, then the opponents who appear most, then card art, then topic-room backgrounds |
| 5 | Audio | `data/sounds.json` is fully wired but every file is empty |
| 6 | Balance | ST08 and Media Ambush unwinnable for the bot (Media Ambush accepted); the Caucus and Cabinet are now easy; most rooms 100% for a geared bot; Appeal is the weakest suit |
| 7 | Review leftovers | Engine items R4-R11, about 20 typed-in strings (U5), small fonts at Small text (U6), tween cleanup (U7), tap-outside-closes (U8): `design/REVIEW_2026-10-14.md` |
| 8 | Content depth | Topic Player Cues are still templated; visitor questions for VI04-VI59; Office Notices have no law lines; opponent and transition lines repeat a lot |
| 9 | Outcome-panel organisation icons | Shown only after a question answer moves an organisation; not yet checked in a real screenshot |

## 8. Where the guides are

`design/WORKBOOK_EXPANSION_GUIDE.md` (how to add content without breaking the engine), `design/EDITING_TEXT.md` (the Text tab), `design/PLAYTEST_CHECKLIST.md`, `design/MECHANIC_COVERAGE.md`, `design/PLAYTEST_RUBRIC.md`, `design/ICON_PROMPT.md` (reusable icon prompt), `design/ICON_GENERATION_BRIEF.md`, `design/REVIEW_2026-10-14.md`, `design/STRESS_LATE_GAME_2026-10-14.md`.

## 9. A good first message in the new chat

"Read `design/NEW_CHAT_STARTUP.md`, then check `git status` and `git log -5`, and tell me the state in one table before we start."
