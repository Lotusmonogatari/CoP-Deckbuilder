# Brand B, "The Assembly Seal": icon, splash and start screen (design spec, 2026-11-18)

**Status:** draft for Cameron. Every wording here is a draft until it is a Text row. Every number is a proposal.
**Mockups:** the design canvas "Coliseum of Parliament: icon, start screen and brand directions", Direction B row (boards `B_Icon`, `B_Start`, `B_Brand`). Export them as PNGs into `design/proposals/img/brand_b/`.
**Copy source:** the doc "Coliseum of Parliament: brand copy and positioning", second pass (Nov 18).
**Art sources (in this package):** `icon_b.svg`, `icon_b_adaptive_foreground.svg`, `icon_b_adaptive_background.svg`, `icon_b_monochrome.svg`, `mark_b.svg`, `waves_b.svg`, and a reference render, `icon_b_1024_reference.png`.

## 1. Decisions

| # | Decision | Source |
|---|---|---|
| D1 | The brand is Direction B, the Assembly Seal: a vermilion hanko carved with the chamber's 20 seats, on the card backs' washi, indigo bands and seigaiha waves | Cameron, Nov 18 |
| D2 | **The brand is fixed and does not follow the UI style.** The start screen, icon and splash look the same whichever UI style the player owns. The UI style is saved with the run, so before Continue is pressed there is no style to follow. | This spec; matches P9 (style saved with the run) |
| D3 | The card fronts and backs are unchanged. The brand borrows from the card backs and never alters them. | P9 D3 |
| D4 | The icon carries no text. | Copy doc, section 7 |

## 2. Tokens

| Token | Hex | Use | Contrast (measured) |
|---|---|---|---|
| Indigo | `#1F3561` | Top band, print frame, primary button, title line 2 | 9.75:1 on washi, 10.74:1 on paper |
| Wave blue | `#3E5C8A` | Second band, waves | 5.47:1 on washi |
| Pale band | `#7E9BC4` | Third band only (no text) | n/a |
| Washi | `#F1E6CF` | Ground | n/a |
| Paper | `#F8F1E3` | Plate, mat, secondary button | n/a |
| Vermilion | `#C23B22` | **Seal and plate borders only, never text** | 4.3:1 on washi: fails for text, passes for shapes (3:1) |
| Sumi | `#1C1A17` | Title, body text | 15.45:1 on paper |
| Quiet ink | `#5A5146` | Tagline, footer | 6.28:1 on washi |
| Rule grey | `#8C7F6B` | Third button's border only | 3.16:1 (a boundary, not text) |

| Font role | Font | In repo |
|---|---|---|
| Title | Shippori Mincho B1 Bold | Yes (`assets/fonts/ShipporiMinchoB1-Bold.woff2`, Latin subset) |
| Body, buttons | Shippori Mincho B1 Regular/Bold | Yes |
| Japanese (蓮物語 and any Japanese title) | Noto Sans JP, falling back per glyph | Yes. The mockups use Noto Serif JP, which is **not** in the repo: ask before adding it. |

## 3. App icon and store art

The source is `icon_b.svg` (1024 × 1024, full bleed, no transparency, no rounded corners; the stores apply their own masks). Rasterize it in the repo with a tool script, so the PNGs can be rebuilt; don't commit hand-exported files.

| File (under `assets/brand/`) | Size | From | Notes |
|---|---|---|---|
| `icon_1024.png` | 1024 × 1024 | `icon_b.svg` | App Store marketing icon. **No alpha channel.** Also the Godot project icon |
| `icon_512.png` | 512 × 512 | `icon_b.svg` | Google Play listing icon |
| `icon_192.png` | 192 × 192 | `icon_b.svg` | Android legacy launcher |
| `icon_180.png`, `icon_167.png`, `icon_152.png`, `icon_120.png`, `icon_87.png`, `icon_80.png`, `icon_76.png`, `icon_60.png`, `icon_58.png`, `icon_40.png` | as named | `icon_b.svg` | iOS sizes. Check which Godot 4.5's iOS export still asks for; generate only those, and list them in `assets/brand/README.md` |
| `adaptive_foreground_432.png` | 432 × 432 | `icon_b_adaptive_foreground.svg` | Seal only, transparent; it sits inside the 66% safe circle |
| `adaptive_background_432.png` | 432 × 432 | `icon_b_adaptive_background.svg` | Bands, washi and waves, no seal |
| `adaptive_monochrome_432.png` | 432 × 432 | `icon_b_monochrome.svg` | White seal with the seats cut out, on transparent (Android 13 themed icons) |
| `splash_seal.png` | 600 × 600 | `mark_b.svg` | Boot splash image, on the washi background colour |
| `feature_graphic_1024x500.png` | 1024 × 500 | Composed (section 5) | Google Play feature graphic |

**Rules:**
- The seal always tilts −4° and is never redrawn or recoloured.
- Below 40 px, the waves may become a plain indigo band. Only the 29 and 20 pt iOS sizes are affected; use the same art unless it fails the size check.
- A check fails if `icon_1024.png` has an alpha channel, or if any size is wrong.

## 4. Boot splash

| Setting | Value |
|---|---|
| `application/boot_splash/bg_color` | Washi `#F1E6CF` |
| `application/boot_splash/image` | `res://assets/brand/splash_seal.png` |
| `application/boot_splash/fullsize` | false (the seal shows at its own size, centred) |
| `application/boot_splash/show_image` | true |
| `application/config/icon` | `res://assets/brand/icon_1024.png` |

## 5. Start screen (`scenes/menus/IntroScreen.tscn`, `scripts/ui/IntroScreen.gd`)

Coordinates are base pixels on the 1080 × 2340 viewport, converted from the 390 × 844 pt mockup at ×2.77. On a 1080 × 1920 screen, only the framed print shrinks (rule below).

| # | Element | Position and size (1080 × 2340) | Style | Content |
|---|---|---|---|---|
| 1 | Ground | full screen | Washi `#F1E6CF` | |
| 2 | Three bands | top: 0–83, 83–133, 133–166 px | Indigo, wave blue, pale band | |
| 3 | Framed print | x 100, y 244, w 881, h 809 | 17 px indigo border, paper mat, 22 px padding; picture fills (cover), focus at 50% across, 42% down | `TITLE` art (the coliseum and gate), via the existing art lookup |
| 4 | Title plate | x 150, y 953, w 781, height by content | Paper; a 8 px vermilion border, plus a 3 px vermilion line inset by 25 px (the card backs' double border); a 17 px offset shadow at 14% sumi; padding 55 / 50 / 50 | Lines 5 to 7 |
| 5 | Title, line 1 | centred in the plate | Shippori Mincho B1 Bold, about 105 px, sumi | `intro.title_top`: "Coliseum" |
| 6 | Title, line 2 | under line 1 | Shippori Mincho B1 Bold, about 55 px, indigo | `intro.title_bottom`: "of Parliament" |
| 7 | Tagline | under line 2, 22 px gap | Shippori Mincho B1 Regular, about 40 px, quiet ink, letter spacing 0.04 em | `intro.tagline`: "The Assembly is in session." (open question 1) |
| 8 | Seal | x 820, y 881, 172 × 172 | `mark_b.svg`, rotated −4°, overlapping the plate's top-right corner | (no text) |
| 9 | Continue | x 89–991, y 1495, h 161 | Indigo fill, paper text about 53 px bold, an 11 px solid indigo-dark (`#142443`) underside | `intro.continue` |
| 10 | New Game | 33 px below, h 150 | Paper fill, 6 px indigo border, indigo text about 50 px bold | `intro.new_game` |
| 11 | How to Play | 33 px below, h 138 | Transparent, 3 px rule-grey border, sumi text about 47 px | `intro.how_to_play` |
| 12 | Footer | y 2010, margins 89 | Shippori Mincho B1 Regular, 33 px, quiet ink; left and right aligned | Left: the version, from `ProjectSettings` `application/config/version`. Right: `intro.footer_mark` (open question 2) |
| 13 | Waves | bottom 199 px, full width | `waves_b.svg`, top-aligned crop | |

**Layout rules:**
- The bands are anchored to the top, and the waves and footer to the bottom. The three buttons stack upward from the footer. The plate sits above the buttons.
- The framed print fills whatever height is left between the bands (plus 78 px) and the plate's top edge (minus 72 px). Its minimum height is 520 px; below that, the picture crops more and the frame keeps its border.
- At Large text, the plate grows downward and the buttons keep their heights. If that doesn't fit, the print shrinks first. Nothing may letter-stack, sit off screen or overlap (the P3 sweep must stay clean).
- Respect the safe area: the bands may run under the status bar, but no text or button may.
- **Continue when there is no save:** keep today's behaviour (shown greyed, with the reason as today). Grey it with 45% opacity on the fill and text, never by changing the colours to vermilion.
- Every touch target is at least 122 px tall (the three buttons are 138 to 161 px).

**What leaves the screen:** today's full-bleed painting, the dark scrim, the small-caps title and the gold-outlined buttons.

## 6. Text rows (drafts for the Text tab, via `tools/workbook/wbx.py`)

| Key | Where | Draft | Replaces |
|---|---|---|---|
| `intro.title_top` | Start screen, plate line 1 | Coliseum | Part of `intro.title` |
| `intro.title_bottom` | Start screen, plate line 2 | of Parliament | Part of `intro.title` |
| `intro.tagline` | Start screen, plate line 3 | The Assembly is in session. | (new) |
| `intro.footer_mark` | Start screen, footer right | Yezo · National Assembly | (new). If Cameron confirms the series: 蓮物語 · Lotus Monogatari |
| `intro.version` | Start screen, footer left | v{version} | (new) |

Keep `intro.title` ("Coliseum of Parliament"), since other places may use it. Check before retiring it.

## 7. Store feature graphic (1024 × 500)

- **Left 48%:** washi, with the plate (Coliseum / of Parliament) and the seal at about 34 px, plus the hook line "Can you talk your way to 51?" in quiet ink.
- **Right 52%:** the `TITLE` painting in a 4 px indigo frame on paper.
- **Bottom:** 40 px of waves.
- **Text:** none smaller than 24 px at 1024 wide, since the graphic is often shown small.

Compose it in the same tool script, from the same parts, so it rebuilds with the art.

## 8. Done means

- [ ] `tools/brand/export_brand.gd` (or similar, headless) rebuilds every PNG in section 3 from the SVGs. A check fails on a wrong size, an alpha channel on `icon_1024.png`, or a foreground that leaves the 66% safe circle.
- [ ] `project.godot` has the icon and boot-splash settings from section 4.
- [ ] The start screen matches `B_Start` at 1080 × 2340, 1080 × 1920 and Large text. Shots have a save present (Continue live) and no save (Continue greyed).
- [ ] All start-screen words are Text rows, with no literals in the scene or script.
- [ ] Contrast is measured from pixels: text at least 4.5:1, borders and the seal at least 3:1.
- [ ] The P3 text sweep is clean on the start screen in all its states. `tools/verify.sh` passes.
- [ ] `assets/brand/README.md` lists every file, its size, its source SVG and where it is used. `GAME_SYSTEMS.md` ("What it looks and sounds like"), `ARCHITECTURE.md` and `CHANGELOG.md` are updated.

## 9. Open questions for Cameron (ask as one popup before building)

| # | Question | Default if unanswered |
|---|---|---|
| 1 | Start-screen line: "The Assembly is in session." or another line from the copy doc? | "The Assembly is in session." |
| 2 | Footer right: "Yezo · National Assembly" or "蓮物語 · Lotus Monogatari"? | Yezo · National Assembly |
| 3 | Short name under the phone icon: "Coliseum"? (Set it when export presets exist; record it in the README now.) | Coliseum |
| 4 | Create `export_presets.cfg` for Android and iOS now, or leave the export presets for the phone-build task? | Leave them; assets only |
| 5 | May Noto Serif JP (SIL OFL, a Japanese subset) be added for 蓮物語 and a possible Japanese title? | No; use Noto Sans JP |
