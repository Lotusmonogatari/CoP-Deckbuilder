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
9. A theme set on a panel reaches every descendant: `BaseImage.plate_theme()` (a dark plate behind every Label) is on each Overlay and on the battle's card zoom, so any Label that must stay plain inside them (the card faces) overrides its own "normal" stylebox (`CardView.no_plate`). `tests/interaction/card_faces_test.gd` catches a regression.
10. A wrapping label needs a width from a parent that gives it one: a label in a `HBoxContainer` that does not expand (the Floor Vote's title at Large text) gets zero width and stacks a letter to a line (the same trap as pitfall 2). Give the container and the label `size_flags_horizontal = 3`. `tools/text_sweep.sh` finds this and verify.sh fails on it.


## Addendum 2026-11-17: staff and item code

| File | Role |
|---|---|
| `scripts/rules/StaffTasks.gd` | Pure: draws a day's pool (`draw_pool`, `roll_quotas`, `day_maximum`), the extra draw and clearing for the Printer and Shredder (`draw_extra`, `clearable`, `pick_to_clear`), and `evaluate` (what a plan does: fits, caps, Loyalty, Flex-Work doubling, no-penalty and quiet days) |
| `scripts/rules/StaffLoyalty.gd`, `StaffPoolModifiers.gd` | Pure: wages and Loyalty bands; drivers and event changes to the pool |
| `scripts/rules/ItemUses.gd` | Pure: copies with uses left, spend a use (most-used copy first), remove a whole copy, normalize against the count held |
| `GameState` (`staff_*`, `item_uses`, `_spend_use`, `_take_item`, `item_copies`) | Run state and flow; instant Office items go through `_staff_use_instant` |
| `scripts/ui/StaffAssignmentsView.gd`, `TaskChip.gd`, `TaskBox.gd`, `StaffLoyaltyView.gd` | The screens; drag and drop, item popup, uses shown |

Design numbers and ids belong in the workbook: `tests/test_balance_keys.gd` checks Balance, Rules and `get_rule` keys against the data, and a scan on 2026-11-17 moved the last fixed numbers and ids out of code (see the CHANGELOG).

## Addendum 2026-11-16: words stay whole

`scripts/autoload/TextFit.gd` watches every Label and Button that wraps text (`autowrap_mode` not off). A few frames after it appears, when its box has a real width, it switches smart wrap to word wrap and, if the longest word is wider than the box, shrinks the font size (a step at a time, to Balance `Text Fit: Minimum Font Size`) until the word fits (`WordFit.gd` does the measuring). Cards (`CardView`, `CardBackView`) are skipped. Pitfall: a label with `custom_minimum_size.x` of 0 inside a flow container collapses to one letter wide, so give such notes a sensible minimum.

## Addendum 2026-11-17: the text sweep (panel P3)

`tools/text_sweep.gd` (+ `.tscn`, run by `tools/text_sweep.sh`) opens about 50 screens (title, picker, Office and its panels, level intro, transition, fights, Office Hours, visit, trade, Floor Vote and the week popups) at **1080 x 2340 and 1080 x 1920** and at **Small, Normal and Large** text, inside SubViewports, and writes `screen,shape,text_size,control,problem,detail` rows:

| Problem | Rule | Fails verify.sh |
|---|---|---|
| `letter_stacking` | a Label or Button wraps into more lines than it has words | yes |
| `off_screen` | a visible text control, not inside a scroll or clip box, is partly outside the screen (or sideways inside one) | yes |
| `overlap` | two visible text controls on the same layer overlap (rectangles cut down to what a scroll box shows) | no, report only |
| `small_target` | a Button under 122 px on its smaller side (one row a screen) | no, report only |

Deliberate overlays are named in `DELIBERATE` at the top of the script (the cue band, card faces, the hand, the ticker, listening strip and the labelled stand-in for undrawn art); only the top layer is checked when a panel is open. `tools/text_sweep.sh [out.csv] [shots_dir]` runs the three text sizes in parallel (about 70 seconds on 4 cores) and joins the files; `SWEEP_ALWAYS=id,id` also saves pictures of named screens. The full `tools/verify.sh` runs it after the click tests. To add a screen, add a step to `_sweep_shape`.

Layout that makes a screen fit: the Office front page and the Level Intro sit in a `Scroll` box (`Safe/Scroll/Column`); the character picture keeps its full size and is drawn behind the text (`PortraitBehind`: the column squeezes an empty slot, the picture follows the slot and the text lies over its lower part, on its translucent plate), then the Office's calendar and dues boxes turn compact (100 px, no weekday row), and only then does the page scroll (Cameron, 2026-11-17: "compact first, then scroll"; "don't minimize the character images").

## Addendum 2026-11-17: UI styles and End of Week Payments (panel P9)

**Three styles, one code path.** `UiStyles` (rules, pure) maps a Cosmetic Package's `UI Style` value to a style and indexes the tokens of the workbook's **UI Styles** tab (`data/ui_styles.json`). `UiStyle` (ui) reads the equipped package (`active_cosmetics["ui_style"]`; none means Living Office), serves tokens (`colour`, `number`, `plate_colour`, `plate_ink`) and `sync()`s the active style's theme overlay into the project theme. `Layout._on_node_added` calls `sync()` when a new screen enters the root; `Layout.apply_ui_style()` is the same for a switch. Nothing in `scripts/rules/` reads `UiStyle`; the rules know only `UiStyles`.

**Themes.** `tools/build_theme.gd` still writes `theme/cop_theme.tres` (sizes, scroll bars) and now also three overlays, `cop_theme_living.tres`, `_broadcast.tres`, `_woodblock.tres`, built by `UiStyleTheme` from the tokens. An overlay carries the fonts, ink colours and button boxes and the SAME items in every style, so merging one over another leaves nothing of the first. Sizes stay in the base theme. `Layout` mutates the project theme in place (party outlines, text size), so overlays are merged into it rather than replacing it; the button outline boxes are rebuilt from the style's button fill.

**Screens ask while they build.** A style shows on the next screen; a battle in progress keeps its look. `SupportBar` draws seats (`SeatsMeter`) in Living Office for a room of people and a continuous arc for a count that is not a head count (press tone, percentages); other styles keep the `SlantBar` with its gold lines. `BaseImage` plates and the Office's veils take the style's plate colour.

**The hand** (all styles) is the real `CardView` row, overlapped by `HandPresenter._fit_overlap` so every card of a hand of 3 to 6 shows; the selected card rises. **End of Week Payments:** `WeekPayments.build` (pure) is called by `GameState.week_end_preview()`; `DuesBox` and `WeekPaymentsView` draw it.

**Tests.** `test_ui_styles`, `test_ui_style_switch`, `test_seats_meter`, `test_week_payments`; real-screen: `hand_visible_test`, `broadcast_gold_lines_test`, `ui_style_parity_test`, and `card_faces_test`, which now repeats its run for each style.

**Round 2 additions (P9).** `RoomObjects` moves five Office buttons onto the picture as pins from `art.json` `office_hotspots` (Living Office only; the same buttons keep their names and `%` lookups, so restore ownership when moving a node). `LevelFolder` wraps a level row in a folder (`OfficeScreen._level_row` calls `_level_row_plain`). `BattleScreen._style_intent_tag` skins the intent line; `CueBanner._skin_for_style` skins the band for each style (bubble, band with gold lines, scroll). `UiStyleTheme` gives Woodblock a paper plaque on every Label type but the cue's own.

**Finishing additions (P9).** `OfficeLayouts` arranges the Office's same buttons as tiles for Broadcast (2 x 2 grid plus a Reputation bar) and Woodblock (3 x 2 plaques); `LevelFolder.wrap_for_style` dresses a level row as a folder, a schedule strip or a print card; `BattleScreen._style_chrome` skins the room and turn plates and End Turn; `HandPresenter._apply_tilts` fans the hand in Living Office (a container resets rotation on each sort, so the tilt is re-applied after every sort). `tools/text_sweep.sh` takes `SWEEP_STYLE`, and `verify.sh` sweeps all three styles.

**Review additions (P9).** `StyleMarks` draws the small marks a style adds (folder, chevron, seal, gold diagonal, dotted leader) so they carry no words; `OfficeScreen._dress_docket` dresses the Start button in every style; `DuesBox` is a tray in Living Office; `LevelFolder.style_tier_heading` and `style_draft_button` dress the Levels list; `HandPresenter._raise` and `_settle` lift a touched card (and the tilt is re-applied after each container sort). Labels that lie over an icon (the organization marks) must set their own empty `normal` stylebox, or a style's label plaque will cover the icon.

**Last five (P9).** `StyleMarks` gained CURL (the calendar page's corner), TAIL (the narration bubble's tail), WAVES (`add_wave_band`), FRAME (`add_print_frame`) and CUTINS (Broadcast's two shots). `CalendarSquare._make_page` builds the Living Office page-a-day; it reads `GameState.calendar_date_text()` and `calendar_weekday_text()`, which already follow the Era and Ainu calendar styles, so a new calendar style needs no change there. The narration bubble's ink comes from a Theme on the bubble (so lines added later inherit it). A panel stretches every child to fill it, so a mark that belongs in a corner draws itself in that corner of a full-size overlay.

