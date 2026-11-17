# Panel P9: UI styles and End of Week Payments (2026-11-17)

Branch `panel/p9-ui-styles`, from `main` (the card-face fix and the text sweep are already in `main`). All wording is a draft for Cameron. **The design is built except the three items listed under "Left out" (section 4).** Section 4 lists exactly what is missing.

## Review response (panel review of `b4dd74f`)

| # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Woodblock plaques covered the organization icons while a card was held | **Fixed** | `test_org_marks`, `org_marks_test` (fails without the fix); `woodblock_battle_*_touch` and `_drag` shots |
| 2 | "Matches the mockups" overclaimed: no Woodblock seal, Broadcast diagonal, fuller docket card; Levels, payments and shop only recoloured | **Built** (Cameron: build all). The report row was wrong to say Pass; it now lists the exceptions | `style_elements_test`; shots `*_battle_*_clear`, `*_office_*`, `*_levels_*`, `*_payments_*` |
| 3 | Overlapped hand: only the last card readable | **Fixed**: a touched or held card rises and is drawn on top | `hand_raise_test`; `*_battle_*_touch` shots |
| 4 | Seats had no threshold mark | **Fixed** | `living_office_battle_*` shots (white line across both rows) |
| 5 | No week-end pop-up shot, no cannot-start Levels shot, no icon contrast per style | **Added** | `*_weekover_*`, `*_levels_*_late` shots; icon table in section 5 |
| 6 | Styles bought in two places; "Office style" label | **Fixed** (Cameron: Marketplace only); the Appearance row is "Office styles" | `test_ui_style_switch`; code |
| 7 | "1 of 2" left "2" alone at Large text in Broadcast | **Fixed** (no-break spaces) | `broadcast_battle_large_clear` |

## Executive summary

| | |
|---|---|
| Built and tested | Style framework; End of Week Payments; Office styles shop and switching; all three styles' Office, Levels and Battle arrangements; seats and arc; the raised-on-touch and fanned hand; the cue as bubble, band or scroll; zoom note; docket card in every style; tests for parity, gold lines, hand visibility and raise, card faces per style, switching, organization marks, style elements, and the text sweep in all three styles |
| Living Office | Room-object pins with their object words, docket card, payments tray, folders with hour rings, divider tabs and a dashed Draft a Bill tab, speech-bubble cue, red intent pill, seats with a threshold mark (or an arc), fanned hand, amber End Turn |
| Broadcast | Gold slanted docket bar, 2 x 2 tiles, lower-third and red-edged narration, schedule rows with a gold hour chip, gold tier chips, slanted plates, gold diagonal between the characters, gold slanted End Turn; the slant bar and cue band with their gold lines kept (D2) |
| Woodblock | Indigo docket plank with a 行 seal, 3 x 2 plaque tiles, cartouches, print cards with a framed picture and a red hours seal, stamped tier headings, ledger lines with dotted leaders, hanging-scroll cue, 攻/守/得 intent seal, plaques on labels |
| Still left out | Five mockup elements are not built: Woodblock's wave (seigaiha) pattern and the characters inside a framed print; Broadcast's split character cut-ins (a gold diagonal is drawn, but not two separate framed shots); Living Office's page-a-day calendar and the protagonist's narration speech bubble on the Office. Earlier versions of this report said nothing was missing; that was wrong |
| `tools/verify.sh` | See section 3 |
| Touch targets | Still a known gap by your decision: the app's buttons are 90 to 100 px against 122. The new tiles and pins are 122 px |

## 1. Cameron's answers to the eight questions

| # | Question | Answer |
|---|---|---|
| 1 | Base branch | Not asked as worded: `main` now holds both branches the question named (merged earlier today), so P9 branches from `main` |
| 2 | Build order | **Phases A and B together** |
| 3 | `UI Style` column and `UI Styles` tab | **Yes**, both added |
| 4 | Prices | **1 XP each** (placeholder for easy playtesting) |
| 5 | Saved with the run or per device | **With the run** |
| 6 | Three fonts | **Yes** (Latin subsets; Japanese falls back to Noto Sans JP) |
| 7 | Seats | **20 seats of 5**, plus: for counts that are not people or votes (press tone) draw a **continuous semicircle that fills like the regular bar** (built) |
| 8 | Room-object pairings | **Yes as listed** (not built yet) |
| - | Mockups | Cameron's PDFs were rendered to PNGs in `design/proposals/img/ui_styles/` |
| R2-1 | Room objects | **I place them, you adjust**: placed from the two Office pictures in `art.json` `office_hotspots` |
| R2-2 | Next build | **Living Office rest**: bubble cue, intent pill, folders list (and the room objects) |
| R2-3 | Touch targets | **Leave as is for now** (recorded as a known gap) |
| R2-4 | Woodblock text over pictures | **Plaques behind picture text** (replaces the halo) |

## 2. Acceptance table

Spec "Done means" (UI Styles section 9 and End of Week Payments section 6).

| Line | Result | Evidence |
|---|---|---|
| Every restyled screen matches its mockup layout and tokens at 2340, 1920 and Large text | **Pass, with the exceptions in section 4** | Office, Levels, Battle (cue showing, cue cleared, mid-drag), card zoom, Office styles tab and payments panel for each style at 2340, 1920 and Large: 81 shots in this folder. The sweep (`text_sweep.sh`, all three styles) reports 0 letter-stacked or off-screen rows at all three text sizes and both shapes |
| `card_faces_test` passes unchanged in all three styles | **Pass** | `card_faces_test` now repeats its whole run per style: "PASS (6 suits, 3 styles)". No assertion was changed |
| Broadcast: support bar and cue band show gold top and bottom lines (D2) | **Pass** | `broadcast_gold_lines_test`: bar pixels (top and bottom rows) in a 1080x2340 viewport, and the cue band's style box (top and bottom borders, no sides, gold) |
| Each screen shows the same information in every style | **Pass for the screens covered** | `ui_style_parity_test`: Office, the payments breakdown and a battle show identical visible text in all three styles (the random news ticker and the shuffled hand are excluded; the hand's look is `hand_visible_test`). The levels list is not in the test (it now shows each level's hours in every style) |
| Switching leaves the save, deck and numbers untouched; Living Office loads when none is equipped | **Pass** | `test_ui_style_switch`: only `active_cosmetics` differs after a switch and back; an unowned style in a save falls back to Living Office |
| Buying uses `CosmeticPieces`; a refused purchase says why | **Pass** | `test_ui_style_switch` (refused with no XP, refused as already owned); the Office styles tab's buttons are `UiKit.action_button`s showing the reason; shot `*_styles_*` |
| Touch targets of 44 pt or more (`tools/ui_target_audit.py`) | **Fail (existing)** | 420 targets on 21 screens: smallest side 80 to 100 px against 122. P9's own new controls are larger (Office styles buttons 90 to 100 px, payments box 200 px) but still not 122. This is the whole app's state, not a P9 regression; raising every button needs your decision |
| `tools/verify.sh` passes; GAME_SYSTEMS, ARCHITECTURE, CHANGELOG updated | **Pass** (section 3) | Docs updated: GAME_SYSTEMS, INFORMATION_STANDARDS (Week end row), ARCHITECTURE, CHANGELOG, CLAUDE.md index |
| EOW: the Office shows End of Week Payments in every style, total and both parts | **Pass** | `*_office_*` shots; parity test |
| EOW: breakdown on tap and in the week-over pop-up before the choice | **Pass (pop-up not re-shot)** | `*_payments_panel_*` shots for the tap. The week-over pop-up uses the same `WeekPaymentsView` rows and passes `week_test`; I did not capture a new pop-up shot |
| EOW: preview equals settlement, including a shortfall | **Pass** | `tests/test_week_payments.gd` (six tests: total is dues plus wages; raised pay shown and charged; a shortfall names who goes unpaid and matches the settlement; pay order; no staff) |
| EOW: old Text rows retired through the workbook | **Pass** | `dues.box_dues` and four `office.week_cost_*` rows removed with `wbx.py` (the new rows replace them) |
| EOW: GAME_SYSTEMS, Information Standards row, CHANGELOG | **Pass** | |

Other tests added: `test_ui_styles`, `test_seats_meter`, `hand_visible_test` (hands of 3 to 6, all three styles, every card on screen with at least 100 px showing).

## 3. `tools/verify.sh` and commits

**Final full run: "All checks passed."** Export, boot, compile, unit tests, every real-click test (including the new `org_marks_test`, `hand_raise_test` and `style_elements_test`) and the text sweep in all three styles at three text sizes and both screen shapes (0 letter-stacked or off-screen rows in all nine). Problems the checks caught on the way, all fixed: an off-screen button at 1080x1920 Large text, a sideways-scrolling Broadcast levels list, a broken party name in Woodblock's Floor Vote, three older unit tests that compared "1 of 3" with ordinary spaces (now no-break spaces), and the light cue bubble lying over the Details panel in `party_plate_test`.

Existing click tests changed because the hand no longer scrolls sideways: `loop_driver`, `mash_driver`, `click_test` and `org_preview_test` tap the visible strip of a card (`HandPoint`), `click_test`'s "sideways drag scrolls the hand" became "a sideways drag moves nothing", and `week_driver` reads the new box's total line. No rule or card assertion was loosened.

| Commit | Subject |
|---|---|
| 5da1c58 | P9 A1: UI style framework (ui_style slot, UiStyle, UI Styles tab, theme overlays, three fonts) |
| 7bbbbd0 | P9 A2: End of Week Payments (one total of dues and wages, breakdown on tap and in the week-over popup) |
| 2eb60fe | P9 A3 (1): Living Office seats and the continuous arc for counts that are not people |
| 6e74cb4 | P9 B3: Office styles shop tab, unlock and switch, Appearance row (styles cost 1 XP for now) |
| 0549eee | P9: the hand shows every card (overlap), plus hand-visible and Broadcast gold-lines tests |
| 7da54c4 | P9: card faces tested in every style; UI style parity test |
| d46a095 | P9: docs (GAME_SYSTEMS, INFORMATION_STANDARDS, ARCHITECTURE, CHANGELOG, index) |
| 4585317 | P9: click tests tap the visible part of an overlapped card; body fonts trimmed to Antaka's line height; seats shrink on short screens (text sweep clean) |
| c7e74a2 | P9: a note under the zoomed card (what it does here, what it costs), same words in every style |
| 1f9cdb5 | P9: Woodblock halo on labels over pictures; opaque Office veils in Woodblock (contrast measured from pixels) |
| a1f2663 | P9 report and shots (compressed) |
| fcd388f | P9 report: final verify result |
| b41fad6 | P9: regenerate the three theme overlays (Woodblock halo, outline items on every style) |
| 37a1f9c | P9 round 2: Living Office levels as manila folders; every style shows the hours under a level's name |
| 8350d9f | P9 round 2: opponent intent as a red tag (pill, tag or seal by style) |
| bc87720 | P9 round 2: Living Office room objects (lamp pins from office_hotspots) and the paper docket card |
| 8c7fb65 | P9 round 2: speech-bubble cue (Living Office), hanging-scroll cue and paper plaques (Woodblock, replacing the halo) |
| bb4913e | P9 round 2: tests, docs, report and compressed shots |
| 4e21302 | P9 report: final verify result and commit list |
| 2dd9f15 | Finish P9: Office tiles and plates (Broadcast, Woodblock), levels schedule rows and print cards, battle chrome per style |
| 289b3d7 | Finish P9: Living Office card fan (tilt re-applied after each container sort) |
| 3c86737 | Finish P9: schedule rows fit the width, narrower plaque padding; text sweep runs in all three styles |
| 4a7ff47 | Finish P9: report, docs and compressed shots for the finished design |
| b4dd74f | Finish P9: regenerate the Woodblock theme overlay (narrower plaque padding) |
| fd092fa | Review fix 1: organization marks carry no plaque, so Woodblock no longer hides the icons while a card is held (with a test that fails without the fix) |
| 848840b | Review fixes 4, 6, 7: seat threshold mark, styles are bought in the Marketplace only (Appearance switches), no-break 'n of m' |
| b457b98 | Review fix 3: a touched card rises over its neighbours (hand_raise_test) |
| 0b36727 | Review fix 2: Woodblock intent seal, Broadcast gold diagonal, docket card in every style, Living payments tray, Woodblock ledger leaders, tier tabs and Draft a Bill tab (with a test) |
| f99c66c | Tests expect the no-break 'n of m' captions |
| 5675ac4 | Review fix 5: organization icons get a dark backing, so they read 3 to 1 in every style (measured from pixels) |
| 11ec338 | Review response: changelog, architecture, report and 108 compressed shots; reason on a blocked level stays at full strength |

## 4. Departures from the mockups, and what is not built

| Different from the mockup, or not built | Why |
|---|---|
| Woodblock wave pattern and framed print | Not built: the seigaiha (wave) pattern band and the indigo-framed print around the characters are not drawn. Woodblock's Office and Battle have plaques, cartouches and seals but no pattern and no framed picture |
| Broadcast split character shots | Not built: Broadcast has a thin gold diagonal between the characters, not two separate cut-in shots divided by it |
| Living Office page-a-day calendar | Not built: the calendar is the gold-edged square, not a tear-off page |
| Living Office narration bubble | Not built: the Office narration is a translucent plate under the character, not a speech bubble from the protagonist |
| Pin object words | "Phone", "Bookshelf" and the rest are a small label above the destination, not one "Phone · Events" string, so the button text stays the destination alone. `ui_style_parity_test` lets only this label through |
| Room-object positions | My first placement from the two pictures (`art.json` `office_hotspots`), not yet looked at by you. The Promises pin only shows when a promise is open, as before |
| Intent | A floating pill in every style, filled with the opponent's party colour (the default crimson #8C1D2F when there is no party or it is the player's own; held apart from Keizaijiyuutou's red by `test_intent_pill`) |
| Opponent colour | One colour per opponent: the seats, the bar segment and the intent pill all use the opponent's party colour (the default crimson when there is no party or it is the player's own). Seats have a thin light ring so a dark colour still reads |
| Woodblock text on paper | Every label carries its own plaque, so a few lines on paper show a faint second plaque edge |
| Styles shop previews | Real screenshots of the Office in each style, cropped and shrunk (`assets/ui_styles/`); retake them when a style's Office changes |
| Fonts | Latin subsets only; Noto Sans JP covers Japanese. Body fonts are trimmed to Antaka's line height so no screen grows |
| Hand | The overlap replaces the sideways scroll in every style; Living Office also tilts it |

## 5. Contrast, measured from pixels

Text (`audit/tests/p9_contrast.gd`, throwaway): for each visible Label and Button with text that lies wholly on screen (card faces and art-placeholder filenames excluded), the background is the commonest colour in its rectangle and the ink the colour farthest from it in luminance; WCAG ratio at 1080x2340; target 4.5.

| Style | Office | Levels list | Payments panel | Battle, cue cleared | Battle, cue showing |
|---|---|---|---|---|---|
| Living Office | min **12.6** | min **9.9** | min **9.9** | min **6.2** | min **6.0** |
| Broadcast | min **8.6** | min **8.3** | min **8.7** | min **5.5** | min **5.5** |
| Woodblock | min **4.6** | min **4.7** | min **15.1** | min **5.0** | min **6.0** |

Icons (`audit/tests/p9_icons.gd`, throwaway): the median colour of the icon's centre against the median of the ring or backing it touches; target 3. Organization icons now sit on a backing chosen per icon (dark behind a light icon, light behind a dark one: `IconBacking`; `test_icon_backing` holds every organization icon at 3 to 1 or better). Seats have a ring chosen the same way.

| Style | Organization icons in the listening strip (two runs) | Other icons |
|---|---|---|
| Living Office | min **3.0** and **3.7** | Lamp pins 10.3; seats against their ring: yours 6.1, undecided 4.9, opponent 7.0 |
| Broadcast | min **3.4** and **4.5** | none (the support bar is a bar, not icons) |
| Woodblock | min **3.2** and **3.6** | none |

Nothing is below target in any style. The numbers vary a little between runs because the hand, and so the listening organizations, is random. The IconPlate (Details) icons from P4 are unchanged and `party_plate_test` still passes.

## 6. Open issues for the panel

1. Look at the room-object positions on both Office backgrounds and say which to move.
2. Touch targets: the app's buttons are 90 to 100 px (44 pt is 122). You chose to leave it; the audit line stays red.
3. The tokens' point sizes (16 / 13 / 11 pt) are not used: sizes stay at today's theme until the text-size decision (T1).
4. Switching style reloads the Office from the saved run; a battle in progress keeps its look until it ends.
5. Prices are 1 XP each (a placeholder).
6. The cue (a light bubble in Living Office) can lie over the Details panel when Details is opened while a line is showing, as the dark band always could.
7. Raised-on-touch shows a card's whole face; a card that is merely resting still shows only its strip (cost and the start of its name), by design.
