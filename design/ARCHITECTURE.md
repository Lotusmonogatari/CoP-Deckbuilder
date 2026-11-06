# How the Code Is Organised

*Written 2026-11-06. This replaces the "project structure" and "seams" sections that used to sit in `CLAUDE.md`. For what the game does see `design/GAME_SYSTEMS.md`; for the rules every contributor follows see `CLAUDE.md`.*

## 1. The one-paragraph picture

The designer edits a workbook. `tools/export_data.py` turns each tab into a JSON file under `data/`. The `DataDB` autoload loads every file and is the **only** thing that reads `data/*.json`. Pure rules in `scripts/rules/` (no UI, no autoloads, no files) hold the game's arithmetic and are handed everything they need. `GameState` holds the run (see `GAME_SYSTEMS.md` section 9) and calls the rules. Screens in `scripts/ui/` and `scenes/` draw state and send the player's choices back. `SaveManager` writes the run to disk.

```
Game_Workbook.xlsx ──export_data.py──► data/*.json ──► DataDB ──► GameState ◄──► screens
                                                         │            │
                                                         └─► rules ◄──┘   (scripts/rules/: pure)
```

## 2. Autoloads (load order matters)

| Autoload | Job |
|---|---|
| `DataDB` | Loads and validates every data file; hands out rows by ID; prints a readable error report at boot |
| `EventBus` | A noticeboard: a signal exists only if something emits it. Eight today: `card_played`, `turn_started`, `turn_ended`, `intent_revealed`, `gaffe_changed` (only when the meter moves; carries direction), `battle_ended`, `meta_changed`, `xp_changed` |
| `Text` | Looks up every sentence from `data/strings.json` (the Text tab) and fills its placeholders |
| `GameState` | The run: numbers, standing, holdings, calendar, promises, laws; applies stage and level rewards; the crisis triggers; the saved-fields list |
| `SaveManager` | One slot at `user://savegame.json`, plus one manual backup; when it saves is in `GAME_SYSTEMS.md` section 2 |
| `Audio` | Listens to `EventBus` and plays whatever `data/sounds.json` names. Three buses (Music, Effects, Speech). **No sound files exist yet**, so the game is silent; a missing file logs one quiet line |
| `Layout` | Keeps every full-screen container ("Safe" for screens, "Margin" for panels) inside the device's safe area |

## 3. Folders

| Path | What is there |
|---|---|
| `data/` | Exported JSON (never hand-edited), plus a few hand-written files: `rules.json`, `booster_standing.json`, `party_standing.json`, `art.json`, `sounds.json`, `staff_names.json`, `level_opponent_overrides.json`, `level_visitor_overrides.json`, and the playtest fixtures (`playtest_level.json`, `playtest_cards.json`) |
| `design/` | The workbook, the guides, the change log, reviews and proposals |
| `scripts/autoload/`, `scripts/rules/`, `scripts/ui/` | As above. A few builders that read `DataDB` sit directly in `scripts/` (`BattleSetup`, `PatronLevel`, `DraftBill`) |
| `scenes/` | `battle/BattleScreen`, `menus/IntroScreen` and `BootCheck`, and in `office_hours/` the Office, Level Intro, Stage Transition, Visitor, Visit, Trade and Floor Vote screens |
| `assets/` | Pictures, fonts, icons, shaders, how-to-play images, audio folder (empty). Art loads by ID with fallbacks (section 6) |
| `tests/` | About 140 GUT scripts (about 1,750 tests) for the rules and data; `tests/interaction/` holds about 30 real-click tests run under a virtual display |
| `tools/` | The exporter, workbook tools, verification, audits, bots and playtest runners, the theme and scene builders |

## 4. Rules versus screens

- **`scripts/rules/` is pure.** It never touches a scene, an autoload or a file; callers pass in the data and a plain answer comes back, which is how both the Office screens and the tests ask the same question. The file `Levers.gd` gives rules files read access to the Balance numbers without reaching into `DataDB`. A rules bug fix always gets a test.
- **Screen families.** `StageRouting.scene_for(stage)` maps a stage's mode to a screen: Combat to `BattleScreen`, Non-combat to `VisitorScreen`, Vote to `FloorVoteScreen`, Visit to `VisitScreen`, Trade to `TradeScreen`. `StageRouting.go_to_next_stage()` is the one place that decides whether a Stage Transition plays first. The Level Intro and Transition screens are built by scene builders in `tools/`.
- **The battle screen** keeps the engine, the refresh, the status row and navigation; four presenters own the pieces: `OpponentPresenter` (the opponent's face and move line), `PlayerPortraitPresenter` (your own reacting face), `HandPresenter` (the cards, reused between refreshes rather than rebuilt; a sideways drag scrolls it, an upward one lifts a card; its gold scroll bar is `HandScrollBar`), `MessagePresenter` (passing messages) and `OutcomePresenter` (the result panel). `CueBanner` throws spoken lines across the middle; `SupportBar`, `VoteMeter` and `PartyVoteBar` draw the score bars through `SlantBar`.
- **Opponents are scripted**, not deck AI: each follows a repeating list of moves (attack, gain, block with ranges). `rules.json`'s `opponent_engine` accepts only `intent_patterns`.

## 5. Text, numbers and data rules

- Every sentence is a Text-tab row asked for by a literal key; every design number is a Balance row; the exporter and `tests/test_balance_keys.gd` enforce both. See `design/INFORMATION_STANDARDS.md` section 6.
- A blank workbook cell reaches the game as JSON `null`, not `""` or 0: read optional cells with a guard (`SafeNum`, `str(x) if x != null else ""`). `int(null)` is a script error and `str(null)` is the literal text "<null>" (both have shipped bugs).
- `DataDB` validates cross-references at load: every card suit exists, every level's stages and opponents exist, and so on, and prints a report.
- Some workbook cells hold `"varies"` or `"—"`; those read as null.

## 6. Pictures and presentation plumbing

- **Characters:** `assets/characters/{kind}/{ID}_{expression}.png` with kinds protagonists, opponents, staff, visitors. Expressions: neutral, attacking, guarding, gaining, damaged, plus optional defeated and victory. A missing face falls back (defeated to damaged, victory to gaining) and finally to neutral, then to a plain `ID.png`, then to a labelled placeholder. An optional one-room outfit is `{ID}_{STAGE_ID}_{expression}.png`; a cosmetic variant adds `{ID}_{variant}_…`. `ArtLoader` finds all of this, and `PlaceholderArt` only re-reads its picture when its own setters run (a self-assignment re-triggers it).
- **Backgrounds:** `assets/backgrounds/{STAGE_ID}.png` (or `OFFICE.png`); a stage's Background ID cell names its picture (or several, one chosen each time). Outside scenes are `OUT_*`; an undrawn one shows the Town Hall. Image Scroll (drag) and Image Pan (tilt) use `PanMath`.
- **Cosmetics** (decorative packages): the equipped variant is resolved inside `ArtLoader` and `Audio`, so no call site knows cosmetics exist.
- **Fonts and theme:** built by `tools/build_theme.gd` (Antaka Brush Display for cards, Antaka Brush Text for the rest, Noto Sans JP as fallback; scroll bars 36 px).
- **Touch:** `DragScroll` makes every scrolling list draggable.

## 7. Verification

| Command | What it proves |
|---|---|
| `python3 tools/export_data.py` | The workbook exports with "No errors" (`--accept-wording` only when Text rows were reworded on purpose) |
| `python3 tools/workbook/check_formulas.py` | No Excel "repair" message |
| `tools/verify.sh` | The whole gate: export, workbook check, cue-coverage warning, boot, every script compiles, unit tests, real-click tests (four at a time under `xvfb-run`). Merge only on the real line "All checks passed" |
| `tools/verify.sh --quick` | Skips the click tests |
| `python3 tools/content_depth.py` | The three-times rule: every room holds at least three times the content a run meets |
| `tools/playtest_optimal.tscn`, `tools/rubric_playtest.tscn`, `tools/strategy_playtest.tscn` | Bot trials of a stage, the organization/bill rubric, and strategy runs |
| `tools/cue_coverage.py` | Which opponent bill-line pools would repeat within 30 turns |

A new `class_name` script is invisible to tests until `.tools/godot --headless --path . --import` has run. Screenshots need a real display (`xvfb-run -a -s "-screen 0 1080x2340x24" … --path .`), not `--headless`. A screenshot or click driver must be added to the scene root (`get_tree().root.add_child.call_deferred(driver)`), or the scene change frees it. Delete throwaway drivers before committing.

## 8. Pitfalls that have bitten

1. A Node must not `await` a timer; a lambda stored in a long-lived object must capture what it needs, not `self` (both leaked).
2. Containers that centre their children grant only a child's minimum size; a wrapping label with a zero width stacks one word per line. `UiKit.line()` forces a full-column minimum width: set `custom_minimum_size.x = 0` in a narrower column.
3. A "fixed" visual may not have changed anything: check a real screenshot or click test.
4. Scene builders: `tools/build_level_intro_scene.gd`, `build_stage_transition_scene.gd`, `build_visitor_scene.gd` and `build_intro_scene.gd` build their own scenes and may be re-run (check the diff of the `.tscn` afterwards, since hand edits to a scene, such as its sizes, are lost when its builder is re-run). The **Office and battle scenes are edited by hand** (they have no builder). `build_visitor_scene.gd` carries the current 420 × 760 portrait size, but the Visit and Trade scenes were sized by hand and have no builder.
5. Content tests pin choice values and per-organization tastes; a content edit can trip them (`tests/test_content_budget*.gd`, `test_party_bodies.gd`, `test_bill_player_cues.gd`).
6. A new copy of a family room must be added to every modifier whose Effect Target names that family, or its backings silently do nothing there.
7. Tests must read workbook values, never type them.
8. An unreachable piece of content (a room in no level, a person seated nowhere) is invisible; the exporter errors on some cases but not all.
