# P10: Brand B assets, app icon, splash and start screen (Claude Code prompt)

**Before pasting:**
1. Copy this package into the repo:
   - `BRAND_B_SPEC_2026-11-18.md` goes in `design/proposals/`.
   - The SVGs (`icon_b.svg`, `icon_b_adaptive_foreground.svg`, `icon_b_adaptive_background.svg`, `icon_b_monochrome.svg`, `mark_b.svg`, `waves_b.svg`) go in `design/brand/source/`.
   - `icon_b_1024_reference.png` goes in `design/brand/reference/`.
2. Export the canvas boards `B_Icon`, `B_Start` and `B_Brand` as PNGs into `design/proposals/img/brand_b/`.

Then paste everything below the line into Claude Code at the root of `cop-deckbuilder`.

---

You are working on Coliseum of Parliament (Godot 4.5, GDScript). Read `CLAUDE.md` first and follow it. Cameron is the owner. "Ask Cameron" means a popup question, and then you wait for the answer.

## Read first

| File | Why |
|---|---|
| `design/proposals/BRAND_B_SPEC_2026-11-18.md` | The spec: decisions, tokens, every asset and size, the start-screen layout in base pixels, Text rows, done list |
| `design/proposals/img/brand_b/*.png` | The mockups. Match their layout and tokens; their wording is draft |
| `design/brand/source/*.svg` | The art. Rasterize these; never redraw or recolour them |
| `design/brand/reference/icon_b_1024_reference.png` | What `icon_b.svg` should look like when rasterized, to catch SVG features Godot drops |
| `scenes/menus/IntroScreen.tscn`, `scripts/ui/IntroScreen.gd` | Today's start screen. Keep its logic (Continue, New Game, How to Play, the save-problem and overwrite pop-ups) |
| `design/INFORMATION_STANDARDS.md` | Standards 2 (refuse with a reason), 3 (no internal IDs) and 9 (text size) |
| `tools/text_sweep.*`, `tools/ui_target_audit.py` | The checks the new screen must pass |

If the spec and the code disagree, the code is the fact. Say so in the report and ask Cameron which should change.

## Fixed decisions (do not reopen)

1. The brand is Direction B, the Assembly Seal.
2. **The start screen, icon and splash don't follow the UI style.** The style is saved with the run, so there is none before Continue. Living Office, Broadcast and Woodblock still apply everywhere else, as today.
3. Card fronts and backs are untouched. `card_faces_test` must still pass.
4. The icon has no text, and the seal always tilts −4°.

## Before you write code: ask Cameron (one popup, all at once)

| # | Question | Options to offer |
|---|---|---|
| 1 | Base branch | Branch from `main` (recommended) / Other |
| 2 | Start-screen line under the title | "The Assembly is in session." (recommended) / another line from the copy doc / none |
| 3 | Footer, right | "Yezo · National Assembly" (recommended) / "蓮物語 · Lotus Monogatari" |
| 4 | Short name for the phone icon label | "Coliseum" (recommended) / other |
| 5 | Export presets | Assets only; presets wait for the phone build (recommended) / create `export_presets.cfg` for Android and iOS now |
| 6 | Add Noto Serif JP (SIL OFL, Japanese subset)? | No, use Noto Sans JP (recommended) / Yes |

Then create branch `panel/p10-brand-b` from the chosen base.

## Step 1: rebuildable assets

- Write `tools/brand/export_brand.gd` (+ `.tscn` if needed), run headless. It loads each SVG with Godot's own SVG loader (`Image.load_svg_from_string` with a scale) and writes every PNG in spec section 3 to `assets/brand/`.
- Compose `feature_graphic_1024x500.png` (spec section 7) in the same script from the same parts. Use the existing `TITLE` art through the art lookup, not a copied file.
- `icon_1024.png` must have **no alpha channel**: convert to RGB before saving.
- Compare the 1024 render with `design/brand/reference/icon_b_1024_reference.png`. If the two differ visibly (for example, the wave band's clip path or the seal's inner border is missing), say so and fix it. Prefer simplifying the SVG (a flattened path for the waves) over drawing a different icon. Never change colours, proportions or the −4° tilt.
- Check which icon sizes Godot 4.5's Android and iOS exports actually take: read the engine's export options, don't guess. Generate those, plus the store sizes. List each in `assets/brand/README.md` with its size, source SVG and where it is used.
- Add `tools/brand/check_brand.py` (or a GDScript test) and wire it into `tools/verify.sh`, asking Cameron first. It fails on a wrong size, an alpha channel on `icon_1024.png`, or any opaque pixel of the adaptive foreground outside the central 66% circle.

## Step 2: project icon and boot splash

- In `project.godot`, set the icon and boot splash as in spec section 4. Check the exact setting names in Godot 4.5 (some boot-splash names changed in 4.x) and use the ones the engine reads.
- If Cameron chose to create export presets, wire the Android launcher, adaptive (foreground, background, monochrome) and iOS icons, and set the display name to the short name. Otherwise, record in the README where each file will go.

## Step 3: the start screen

Rebuild `IntroScreen` to spec section 5. Keep every behaviour of today's screen and its click tests.

- Rebuild the layout in the scene where possible; the scene is edited by hand. Elements:
  - three top bands;
  - the framed `TITLE` print;
  - the paper title plate with the vermilion double border and offset shadow;
  - the seal (`mark_b`) overlapping the plate's top-right corner;
  - three buttons (indigo plank, outlined paper, thin outline);
  - the footer;
  - the wave band.
- Draw the bands, frame, plate borders and buttons with StyleBoxFlat, or a small UiKit helper. Use art files only for the seal, the waves and the painting.
- Give the start screen its own small theme, or overrides, for brand B (`theme/brand_b_intro.tres` or code). It must not depend on `UiStyle.current()`.
- Everything flexes as in the spec's layout rules. Only the print shrinks on 1080 × 1920; at Large text the plate grows and the print shrinks first.
- All words are Text rows (spec section 6) added through `tools/workbook/wbx.py`, then `tools/export_data.py`. The version comes from `application/config/version`. Set one if it's empty, asking Cameron for the number.
- Continue with no save: keep today's logic and reason. Grey it out by opacity, as the spec says.
- Fonts: Shippori Mincho B1 (in repo). Japanese glyphs fall back per glyph to Noto Sans JP, unless Cameron approved Noto Serif JP.

## Tests to add

| Test | Fails when |
|---|---|
| `tools/brand/check_brand.*` | Any asset in spec section 3 is missing or the wrong size, `icon_1024.png` has alpha, or the adaptive foreground leaves the safe circle |
| `tests/interaction/intro_brand_test.gd` | A start-screen word isn't a Text row; any button is under 122 px tall; any text is under 4.5:1 or the seal and borders are under 3:1 (measured from pixels); the plate, buttons or footer overlap or leave the safe area at 1080 × 2340, 1080 × 1920 or Large text |
| Existing intro click tests | Continue, New Game, How to Play and the two pop-ups no longer work |
| `card_faces_test` | (unchanged) It must still pass |

## Screenshots

Save shots in `design/review/p10_brand_b_<date>/` (it has a `.gdignore`). Use the file name pattern `<screen>_<size>[_<state>].png`. Capture:
- the start screen with a save and with no save, at 1080 × 2340, 1080 × 1920 and Large text;
- the boot splash;
- a contact sheet of every icon size on a light and a dark ground, with the adaptive layers shown in a circle mask and a rounded-square mask;
- the feature graphic.

## Rules

- Use the workbook for every word, and ask Cameron before any schema change, new font or new `verify.sh` check.
- Never put an internal ID on screen (Standard 3). Every touch target must be at least 122 px.
- Run `tools/verify.sh` before each commit. Make small commits.
- Update `GAME_SYSTEMS.md` ("What it looks and sounds like"), `ARCHITECTURE.md`, `CHANGELOG.md` and the `CLAUDE.md` index.
- Push the branch and stop. Do not merge.

## Report (`design/review/p10_brand_b_<date>/REPORT.md`)

1. Cameron's answers to the six questions.
2. An acceptance table: each line of the spec's "Done means", with pass or fail and the evidence (a test name or a shot file).
3. The `tools/verify.sh` result and the commit hashes.
4. The asset list as built: file, size, source and where it is used. Note which iOS and Android sizes Godot 4.5 asked for.
5. Any difference between Godot's SVG render and the reference, and what you did about it.
6. Departures from the `B_Start` mockup, and why.
7. Contrast readings for the start screen, measured from pixels.
