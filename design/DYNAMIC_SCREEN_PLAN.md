# Plan: making screens fit typical phones (draft 2026-10-14)

**Status:** steps 0-5 built (2026-10-14). Only step 6 (a real-device pass) is open.

## Where we are

| Fact | Today |
|---|---|
| Design size | 1080 x 2340 (9:19.5), portrait only |
| Stretch | `canvas_items`, aspect `expand` (the 1080 width is fixed; extra height is given to the layout) |
| Safe areas (notch, rounded corners, home bar) | Not read anywhere. Screens use a flat 40 px margin |
| Wide phones, tablets, foldables | Not handled (a 4:3 tablet is far wider than 1080 at that height) |
| Text | Most is set to wrap; a few labels in scene files and some buttons did not |

## Typical targets

| Device class | Aspect | Notes |
|---|---|---|
| Tall phones (most Android, iPhone Pro) | 9:19.5 to 9:21 | Our design size; extra height is the main variable |
| Older / shorter phones, iPhone SE | 9:16 | Less height: the hand, bar and header must still all fit |
| Foldable (cover screen) | about 9:22+ | Very tall and narrow |
| Tablets | 3:4 to 4:5 | Wide: content should stay a centred column, not stretch |

## Steps

| # | Step | What it does | Effort |
|---|---|---|---|
| 0 | **Wrap everything** (built 2026-10-14) | `UiKit.wrap_all()` makes every label and button in a panel wrap; headings wrap; panels never scroll sideways; the column has a fixed 1000 px width to wrap against; the runtime-text labels in scenes wrap. Test: `test_overlay_wrap.gd` | Done |
| 1 | **Safe-area margins** | Read `DisplayServer.get_display_safe_area()` once at start (an autoload, `Layout.gd`), convert to base-resolution pixels, and have every screen's outer margin use `max(40, safe inset)`. One place to change, no per-screen numbers | Small |
| 2 | **Aspect test matrix (BUILT: `tests/interaction/aspect_matrix_test.tscn`, in `verify.sh`)** | A throwaway driver renders each screen type at 1080x1920, 1080x2160, 1080x2340, 1080x2520 and 1600x2000 (tablet) and saves screenshots, plus an automated check that no control extends past the viewport and no scrollbar is horizontal. Becomes a click test in `verify.sh` | Medium |
| 3 | **Short-screen mode (BUILT: the battle art box now shrinks to 320 px minimum, so the End Turn button stays on a 1080x1920 screen)** | At 9:16 and shorter, the battle screen drops to a compact layout: smaller art box (it is the one elastic block), hand cards a notch smaller. Rule of thumb: art box takes whatever height is left after the fixed rows, with a floor | Medium (battle screen is the hard one) |
| 4 | **Wide-screen cap (BUILT in `Layout.gd`: screens wider than 1080 get side margins, so a tablet shows a centred column)** | Above about 1.0 width:height, keep the 1080-wide column centred, with the stage background filling the sides. No screen stretches its content to tablet width | Small |
| 5 | **Text scale (BUILT: Administration menu button cycles Small / Normal / Large; sizes are Balance levers `text_scale_small` 90 and `text_scale_large` 120; saved in `user://settings.json`, separate from the save)** | A single `ui_scale` in Settings (Small / Normal / Large) applied to the theme font sizes, so players with large-text needs are served without re-laying out every scene | Medium |
| 6 | **Real-device pass** | Android first (Pixel and a small phone), then iOS. Checklist in `design/PLAYTEST_CHECKLIST.md` gains a "layout" line per screen | Needs devices |

## Rules to keep from now on

1. A new screen takes its outer margin from the one safe-area value (after step 1), never a typed number.
2. Text that can be long (names, titles, anything from the workbook) wraps; a fixed-width label is only for numbers.
3. Nothing needs a sideways scroll. Vertical scroll is fine for panels, never for the battle screen's play area.
4. One elastic block per screen (the art box on battle, the list on a panel), so extra or missing height has one place to go.

## Suggested order

Step 1, then step 2 (it shows where steps 3 and 4 are actually needed), then 3 and 4 as the screenshots demand, then 6. Step 5 can wait.
