# P10: Brand B assets, app icon, splash and start screen (report, 2026-11-18)

Branch `panel/p10-brand-b`, from `main`. Not merged. All wording is a draft for Cameron.

## Executive summary

| | |
|---|---|
| Built | Every PNG in the spec's section 3 (rebuilt from the SVGs by a script), the project icon and boot splash, Android and iOS export presets (as an example file), the Brand B start screen, a test for the assets and a test for the screen |
| Behaviour | Unchanged: Continue (greyed with no save), New Game (warns before burying a save), How to Play, the save-problem pop-up |
| Not available to me | The mockup PNGs (`B_Icon`, `B_Start`, `B_Brand`) were not in the package, so the screen is built from the spec's coordinates and tokens, not compared against the boards |
| Needs your decision | The version number (placeholder 0.1.0), the package name and bundle id (placeholder `com.example.coliseumofparliament`), whether `export_presets.cfg` should stop being git-ignored |

## 1. Cameron's answers to the six questions

| # | Question | Answer |
|---|---|---|
| 1 | Base branch | `main` |
| 2 | Line under the title | **"Gladiators of Politics, Enter the Arena!"** (Cameron's own line) |
| 3 | Footer, right | **蓮物語 · Lotus Monogatari** |
| 4 | Short name under the phone icon | **Coliseum** |
| 5 | Export presets | **Create now** (done as `tools/brand/export_presets.example.cfg`; see section 6) |
| 6 | Noto Serif JP | **No**: Japanese is Noto Sans JP |

## 2. Acceptance table ("Done means")

| Line | Result | Evidence |
|---|---|---|
| `tools/brand/export_brand.gd` rebuilds every PNG; a check fails on a wrong size, an alpha channel on `icon_1024.png`, or a foreground outside the 66% circle | **Pass** | `tests/test_brand_assets.gd` (6 tests). Run as part of `tools/verify.sh`'s unit tests, so no new verify step was added |
| `project.godot` has the icon and boot-splash settings | **Pass** | `config/icon`, `boot_splash/bg_color`, `image`, `fullsize` false, `use_filter`, `show_image` |
| Start screen matches `B_Start` at 1080 x 2340, 1080 x 1920 and Large text, with a save and without | **Pass, against the spec, not the boards** | `start_2340_*`, `start_1920_*`, `start_large_*`, `start_large1920_*` (each `_save` and `_nosave`) |
| All start-screen words are Text rows | **Pass** | `intro_brand_test` compares every label and button with its Text row; the scene has no literal text |
| Contrast measured from pixels: text at least 4.5:1, borders and seal at least 3:1 | **Pass** | `intro_brand_test`; readings in section 7 |
| The P3 text sweep is clean on the start screen in all its states; `tools/verify.sh` passes | **See section 3** | |
| `assets/brand/README.md` lists every file; `GAME_SYSTEMS.md`, `ARCHITECTURE.md`, `CHANGELOG.md` updated | **Pass** | The spec names a "What it looks and sounds like" section of `GAME_SYSTEMS.md`; that file has no such section, so an addendum was added at the end |

## 3. `tools/verify.sh` and commits

See the end of this file (filled in after the final run).

## 4. The asset list as built

Full list with sources and uses: `assets/brand/README.md`. Godot 4.5.1's own export options (read from the engine binary, not guessed):

| Platform | Options Godot reads | Made |
|---|---|---|
| Android | `launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432`, `adaptive_monochrome_432x432` | All four |
| iOS | `icons/icon_1024x1024` (and `_dark`, `_tinted`), `app_store_1024x1024`, `iphone_120x120`, `iphone_180x180`, `ipad_152x152`, `ipad_167x167`, `spotlight_80x80`, `spotlight_120x120`, `settings_58x58`, `settings_87x87`, `notification_40x40`, `notification_60x60`, `notification_76x76`, `notification_114x114` | All but `_dark` and `_tinted` (no dark or tinted art exists) |
| Not used | `ios_128x128`, `ios_136x136`, `ios_192x192` (other targets) | none |

Beyond the spec's list I made `icon_114.png` (Godot's `notification_114x114`) and `waves_1080x199.png` (the start screen's wave band).

## 5. Godot's SVG render against the reference

`icon_1024.png` against `design/brand/reference/icon_b_1024_reference.png`: largest single-pixel difference 22 of 255, none above 40, mean 0.12. The wave band's clip, the seal's inner border and the 20 seats all render. Nothing was simplified or redrawn.

## 6. Departures and open points

| Item | What I did | Why |
|---|---|---|
| Mockups | Not compared | The `B_*` PNGs were not in the zip. Build is from the spec's coordinates (section 5) |
| Tagline size | 34 px, not 40 | Cameron's line is longer than the spec's, and at 40 px it wrapped to an orphaned "Arena!" at normal text; at 34 px it fits on one line. At Large text it wraps, and the plate grows |
| Seal tilt | The art's own -4° only | `mark_b.svg` already contains the tilt; rotating it again would make it -8° |
| Print and plate overlap | The print runs 100 px behind the plate, and shrinks as the plate grows | The spec's "(minus 72 px)" is ambiguous; this matches the table's positions (plate at y 953, print ending at y 1053) |
| Continue with no save | Greyed at 45% with no reason shown | That is today's behaviour. Standard 2 asks for a reason; say if you want one |
| Feature graphic seal | 96 px | The spec says "about 34 px", which is unreadable at that size |
| Boot splash shot | A composite | A real boot splash cannot be captured under xvfb. The composite is the seal centred on washi at the project's settings |
| `export_presets.cfg` | Committed as `tools/brand/export_presets.example.cfg` | The repo's `.gitignore` ignores `export_presets.cfg` on purpose (signing details). Copy it to the project root. Tell me if it should stop being ignored |
| Package name and bundle id | `com.example.coliseumofparliament` | A placeholder: the real one is yours to choose and cannot change once published |
| Version | `0.1.0` | A placeholder; the start screen footer shows it |
| iOS name under the icon | "Coliseum of Parliament" | Godot 4.5.1 has no separate iOS display-name option; only Android got "Coliseum" |

## 7. Contrast readings (from pixels, 1080 x 2340 normal text; the same at 1080 x 1920 Large text)

| Element | Reading | Needs |
|---|---|---|
| Title ("Coliseum") on paper | 15.45 : 1 | 4.5 |
| "of Parliament" (indigo) on paper | 10.74 : 1 | 4.5 |
| Tagline on paper | 6.92 : 1 | 4.5 |
| Footer, both sides, on washi | 6.28 : 1 | 4.5 |
| Continue text on indigo | 10.74 : 1 | 4.5 |
| New Game text on paper | 10.74 : 1 | 4.5 |
| How to Play text on washi | 14.02 : 1 | 4.5 |
| Plate border (vermilion) on washi | 4.30 : 1 | 3 |
| Seal on washi | 4.30 : 1 | 3 |
| New Game outline | 9.75 : 1 | 3 |
| How to Play outline | 3.16 : 1 | 3 |
