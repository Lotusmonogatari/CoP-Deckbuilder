# Phase 3: Redundancy

Finding format:
ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

## Summary

There is little redundancy in the game code itself. No two functions of five lines or more have the same body, no script is unused, and no image is clearly unreferenced. The duplication that exists is in three scene files, a few repeated constants and styling helpers, and in non-game files that sit inside the project folder.

## Findings

| ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| R-01 | Medium | Scenes | `scenes/office_hours/VisitorScreen.tscn`, `VisitScreen.tscn`, `TradeScreen.tscn` | Three scene files are 99% identical (225 lines each, 34 nodes, same tree). A layout fix made in one must be repeated by hand in the other two, and they have already needed the same fixes more than once. | Line-by-line similarity 0.991 for each pair (Python `difflib`). Their scripts differ properly (similarity 0.22 to 0.36), so only the scene is duplicated. | Keep one shared "conversation screen" scene and have the three scripts extend or configure it. Per `design/ARCHITECTURE.md`, check which builder script owns these scenes first. | M | High |
| R-02 | Low | Assets | `assets/backgrounds/ST08.png`, `assets/backgrounds/ST22.png` | The same picture is stored twice (1.3 MB each). | Identical MD5 hash. | Delete one and set the other stage's Background ID to borrow it (the Stages tab already supports this). | S | High |
| R-03 | Low | UI code | `scripts/ui/OfficeScreen.gd:3307-3316`; `scripts/ui/UiKit.gd` (`gold_rule()`) | Two different "gold line" helpers exist: a 4 px `HSeparator` in the Office and a 3 px `ColorRect` in `UiKit` (used by the Floor Vote screen). They look slightly different. | `func _gold_rule() -> Control: var rule := HSeparator.new() ... style.thickness = 4` versus `UiKit.gold_rule()` `custom_minimum_size = Vector2(0.0, 3.0)`. | Keep one, in `UiKit`. | S | High |
| R-04 | Low | Constants | `scripts/ui/BattleScreen.gd:32`; `scripts/ui/IntroScreen.gd:16`; `scripts/ui/StageStartFailure.gd:13` | The Office scene path is written out in three files that could use `StageRouting.OFFICE_SCENE`, as four other screens already do. | `const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"` in each. | Point the three at `StageRouting.OFFICE_SCENE`. | S | High |
| R-05 | Medium | Styling | `scripts/ui/*.gd` | Much of the look is set in code, not in the theme: 110 `add_theme_*_override` calls, 18 hand-built `StyleBoxFlat`s and 69 literal `Color(...)` values across the UI scripts (the 10 game scenes add 142 `theme_override` lines). The same near-colors recur with small differences (for example `Color(1.0, 0.93, 0.6)` and `Color(1.0, 0.92, 0.6)`). | grep counts over `scripts/ui` and `scenes/`. | Move the recurring colors and panel styles into `theme/cop_theme.tres` (via `tools/build_theme.gd`) as named type variations; leave one-off layout overrides alone. Detail in Phase 5. | M | High |
| R-06 | Low | Test-only code | `scripts/rules/StageCarryOver.gd`; 23 functions (list in C-12) | Code that only tests call. | See C-12 in `02-code.md`. | Review for removal. | S | Medium |
| R-07 | Medium | Repo layout | `design/`, `tools/`, `tests/`, `addons/gut/`, `audit/` | Non-game folders live inside the Godot project and have no `.gdignore`, so the editor imports their files and an export would include them by default. Eight review CSVs have already been imported as "translations", and their `.csv.import` files are committed. | `find . -name .gdignore` finds only `.godot/.gdignore`; `git ls-files` lists 8 `design/review/*.csv.import`; 78 `.translation` files on disk. | Add an empty `.gdignore` file to `design/` and `audit/` (they hold no game resources), delete the 8 `.csv.import` files, and exclude `tests/`, `tools/` and `addons/gut/` in the export presets (S-06). | S | High |
| R-08 | Low | Repo size | `.git` (553 MB); `design/Game_Workbook.xlsx`; `assets/` | The repository is large because the binary workbook and 240 MB of PNGs are committed on every change. Not a ship blocker; it slows clones and CI. | `du -sh .git` = 553 MB. | Consider Git LFS for `assets/**/*.png` and the workbook. Optional. | M | Medium |

## Checked and clean

- **Duplicate scripts:** none. No two functions of 5+ lines share a body across `scripts/`.
- **Unused scripts:** none (every script is referenced by a scene, another script or `project.godot`).
- **Unused images:** none found by ID matching against `data/` and `scripts/` (a heuristic: art is loaded by ID, so a file whose name is not an ID in the data would be missed by the game; none stood out).
- **Orphaned signals:** none (see Phase 2).
- **Orphaned input actions:** none, because no custom input actions exist.
- **Unused Text rows:** the exporter reports these itself on every export; the last export listed none beyond known notes.
