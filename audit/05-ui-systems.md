# Phase 5: UI and systems cohesion

Finding format:
ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

## UI: what holds together

- **One theme.** `project.godot` sets `theme/custom="res://theme/cop_theme.tres"`, built by `tools/build_theme.gd`. It defines the default font (Antaka Brush Text with Noto Sans JP fallback) and named sizes: default 34, Button 40, HeaderLabel 46, TitleLabel 58, SmallLabel 26, JapaneseAccent 24, CueBanner 64 (`theme/cop_theme.tres:90-123`).
- **Safe areas are handled in one place.** `Layout.gd:99-143` reads `DisplayServer.get_display_safe_area()` and raises the margins of every `MarginContainer` named `Safe` or `Margin`, on load and on resize. All 10 game scenes have a `Safe` container at the top.
- **Aspect ratios are tested.** `tests/interaction/aspect_matrix_test.gd:11-12` runs screens at 1080x1920, 1080x2160, 1080x2340, 1080x2520 and 1600x2000.
- **A text-size setting exists** (small, normal, large; `Layout.gd:146-183`, `scripts/rules/TextScale.gd`) and is saved in `user://settings.json`.
- **Overlays always have a way out** (`Overlay.gd`: Back button, Escape, tap outside).

## UI findings

| ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| U-01 | High | Touch targets | Office lists and most buttons; `design/review/MC2T_TARGETS_2026-11-06.md` | Most buttons are shorter than both platforms' recommended touch size. Buttons are 80 to 110 base pixels tall; Apple's 44 pt is 122 base pixels and Android's 48 dp is 126 to 144. The project's own audit found 83% to 98% of targets on each Office screen under the Apple size. The 144 px fix was tried on 2026-11-06 and reverted the same day at the designer's request because the buttons looked too large. Neither store rejects for this; it is a usability risk that only a real phone can settle. | "Office > levels: 80 targets, smallest side 90 px / 34 dp, 79 (98%) under iOS 44 pt"; code: `custom_minimum_size = Vector2(0, 90)` (5 uses), `Vector2(0, 100)` (8), `Vector2(0, 110)` (9). | Test on a real phone (M6). If taps miss, raise heights to about 122 to 126 px, a middle value between today's 90 and the rejected 144, or keep the look and add spacing between rows so the tappable area grows without a bigger button. | M | High |
| U-02 | High | Text legibility | `theme/cop_theme.tres:101,113,120` | The small text sizes are at or under comfortable reading size on a phone, and under Steam Deck's minimum. SmallLabel 26 and JapaneseAccent 24 base pixels are about 9 to 10 dp on a 412 dp-wide phone. On a Steam Deck (1280x800, landscape) the portrait layout scales to the screen height, 800/2340 = 0.34, so default text (34) draws at about 11.6 px and small text (26) at about 8.9 px; Valve's minimum is 9 px and its recommendation is 12 px (see Phase 6). | Theme font sizes; scale computed from `project.godot` viewport 1080x2340 and stretch `canvas_items`/`expand`. **Not viewed on a device.** | Phones: test at the "large" text setting and consider making it the default. Steam Deck: needs a landscape layout or a much larger text scale (S-09). | M | High |
| U-03 | Medium | Styling | `scripts/ui/*.gd`, `scenes/**/*.tscn` | The theme is one, but a lot of styling bypasses it: 110 theme overrides and 18 hand-built `StyleBoxFlat`s in UI scripts, 142 `theme_override` lines in the scenes, and 69 literal colors. Small drifts already show (two gold lines of different thickness, near-duplicate yellows). | Counts and examples in R-03 and R-05. | Add named theme variations for the recurring cases (panel backgrounds, gold accents, warning red, success green) and switch the scripts to them over time. | M | High |
| U-04 | Medium | Navigation | all screens | There is no controller or keyboard navigation. Only one `focus_mode`/`grab_focus` use exists in the game's scenes and scripts, no joypad events are read, and nothing sets an initial focus when a screen opens. Fine for phones; it blocks Steam Deck (S-08). | `grep -rn "focus_mode\|grab_focus\|focus_neighbor" scripts scenes` = 1 match; `grep InputEventJoypad scripts` = 0. | See S-08. | L | High |
| U-05 | Medium | Navigation | `project.godot:18`; C-01 | Android's back button is not handled (C-01), and there is no pause or system menu inside a stage: the only way out of a battle is to finish it or close the app. The Office offers Resume or Abandon when a level is in progress (`OfficeScreen.gd:844-846`), but nothing in the battle leads there. | No "leave" control in `scenes/battle/BattleScreen.tscn` top-level nodes (Background, Safe, DetailsPanel, CardZoom, OutcomePanel, Notice). **Unverified by play.** | Add a small menu to stage screens (Settings, How to Play, Leave to Office) and route the back button to it. | M | Medium |
| U-06 | Low | Scene changes | 21 `change_scene_to_file` call sites | Scene changes are instant cuts with no fade and no loading indicator, called directly from 12 files. On a slow phone, a change that loads large textures will freeze on the old screen for a moment. | `grep change_scene_to_file scripts` = 21. | Route all changes through one helper (a small `SceneChanger` in `StageRouting`) that fades out, changes, and fades in. | M | High |
| U-07 | Low | Aspect ratios | `tests/interaction/aspect_matrix_test.gd:11-12` | The aspect tests cover tall phones and one tablet-like size, but no landscape size (Steam Deck 1280x800) and no small-phone width below 1080 base. | `const SIZES := [Vector2i(1080, 1920), ... Vector2i(1600, 2000)]` | Add 1280x800 and 2560x1600 if Steam Deck stays in scope. | S | High |

## Systems: who owns what

| System | Owner | One owner? | Notes |
|---|---|---|---|
| Save / load | `SaveManager.gd` (file handling), `GameState.to_save()` / `load_save()` (contents) | Yes | Clean split. One list of saved fields (`GameState.gd:525-545`). |
| Audio | `Audio.gd`, driven by `EventBus` signals and `data/sounds.json` | Yes | No sounds exist yet; no volume settings (C-14). |
| Settings | `Layout.gd` (`user://settings.json`) | Yes, but misnamed | `Layout` owns four unrelated jobs: safe-area margins, the settings file, text scaling, button outline colors, and the on-screen "Saved" flash (Y-01). |
| Scene transitions | `StageRouting.gd` chooses the next stage scene; every screen calls `change_scene_to_file` itself | Partly | See U-06. |
| Economy / progression | `GameState.gd` holds state and applies changes; rules in `scripts/rules/` (`Ledger`, `Promises`, `WeekCalendar`, ...) decide | Yes | Pure rules are separated and unit-tested; `GameState` is very large (C-07). |
| Text | `Text.gd` from `data/strings.json` | Yes | Every sentence goes through `Text.say()`; the exporter checks keys. |
| Art loading | `ArtLoader.gd` with fallbacks; `PlaceholderArt.gd` draws | Yes | |
| Data | `DataDB.gd` | Yes | Loads and validates all JSON at start (C-04, C-06). |

## Systems findings

| ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| Y-01 | Low | Structure | `scripts/autoload/Layout.gd` | One autoload does five jobs under a name that describes one of them. It works; it makes "where are settings saved?" hard to find. | Functions: `refresh`/`_apply` (safe area), `_load_settings`/`_save_settings`, `apply_text_scale`, `_build_button_outlines`, `flash`. | When audio settings are added, move settings into a small `Settings` autoload and leave `Layout` with layout. | S | High |
| Y-02 | Low | Localization | `scripts/autoload/Text.gd`; `data/strings.json` | The game has its own text table and does not use Godot's translation system. That is a sound choice for one language, but shipping a second language later means adding a language column and switch to this table; nothing in the stores requires it. | 78 stray `.translation` files come from review CSVs (R-07), not from game text. | No action for an English launch. | L | High |
