# Panel P9: UI styles and End of Week Payments (2026-11-17)

Branch `panel/p9-ui-styles`, from `main` (the card-face fix and the text sweep are already in `main`). All wording is a draft for Cameron. **This is a partial delivery: the framework, End of Week Payments, the style shop, switching and Living Office are built and tested; the Broadcast and Woodblock per-screen arrangements in the mockups are not.** Section 4 lists exactly what is missing.

## Executive summary

| | |
|---|---|
| Built and tested | Style framework (slot, tokens tab, themes, fonts); End of Week Payments (box, breakdown, week-over pop-up); Office styles shop and switching; seats and arc; the all-cards-visible hand; card-zoom note; parity, gold-lines, hand-visible, card-faces-per-style and switch tests |
| Styles today | Each of the three styles changes fonts, colours, panel plates, buttons and the support-count drawing on **every** screen. Broadcast keeps its gold lines. Card faces are identical |
| Round 2 built | Living Office room objects (lamp pins, positions by Claude), manila-folder levels list, red intent tag (all styles), speech-bubble cue (Living Office), hanging-scroll cue and paper plaques (Woodblock) |
| Not built | The Broadcast and Woodblock room arrangements (slanted plates, 2 x 2 tiles, plaque tiles, framed prints), the rotated card fan, Broadcast schedule rows, Woodblock print cards; the mid-drag battle shot |
| `tools/verify.sh` | See section 3 |
| Touch targets | The audit shows every screen in the game is under 44 pt (existing buttons are 90 to 100 px against 122): not caused by P9, but the acceptance line is not met |

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
| Every restyled screen matches its mockup layout and tokens at 2340, 1920 and Large text | **Partial** | Living Office: tokens, fonts, plates, buttons, room-object pins, docket card, seats/arc, speech-bubble cue, intent pill, overlapped hand, folders list, zoom note and payments box are built. Broadcast and Woodblock: tokens, fonts, plates, buttons, gold-line bar and band (Broadcast), scroll cue and plaques (Woodblock), intent tag, hand, zoom note and payments box; their room arrangements (tiles, plaque tiles, framed prints, schedule rows) are not. Shots: `<style>_<screen>_<size>` in this folder |
| `card_faces_test` passes unchanged in all three styles | **Pass** | `card_faces_test` now repeats its whole run per style: "PASS (6 suits, 3 styles)". No assertion was changed |
| Broadcast: support bar and cue band show gold top and bottom lines (D2) | **Pass** | `broadcast_gold_lines_test`: bar pixels (top and bottom rows) in a 1080x2340 viewport, and the cue band's style box (top and bottom borders, no sides, gold) |
| Each screen shows the same information in every style | **Pass for the screens covered** | `ui_style_parity_test`: Office, the payments breakdown and a battle show identical visible text in all three styles (the random news ticker and the shuffled hand are excluded; the hand's look is `hand_visible_test`). The levels list is not in the test (it now shows each level's hours in every style) |
| Switching leaves the save, deck and numbers untouched; Living Office loads when none is equipped | **Pass** | `test_ui_style_switch`: only `active_cosmetics` differs after a switch and back; an unowned style in a save falls back to Living Office |
| Buying uses `CosmeticPieces`; a refused purchase says why | **Pass** | `test_ui_style_switch` (refused with no XP, refused as already owned); the Office styles tab's buttons are `UiKit.action_button`s showing the reason; shot `*_styles_*` |
| Touch targets of 44 pt or more (`tools/ui_target_audit.py`) | **Fail (existing)** | 420 targets on 21 screens: smallest side 80 to 100 px against 122. P9's own new controls are larger (Office styles buttons 90 to 100 px, payments box 200 px) but still not 122. This is the whole app's state, not a P9 regression; raising every button needs your decision |
| `tools/verify.sh` passes; GAME_SYSTEMS, ARCHITECTURE, CHANGELOG updated | **See section 3** | Docs updated: GAME_SYSTEMS, INFORMATION_STANDARDS (Week end row), ARCHITECTURE, CHANGELOG, CLAUDE.md index |
| EOW: the Office shows End of Week Payments in every style, total and both parts | **Pass** | `*_office_*` shots; parity test |
| EOW: breakdown on tap and in the week-over pop-up before the choice | **Pass (pop-up not re-shot)** | `*_payments_panel_*` shots for the tap. The week-over pop-up uses the same `WeekPaymentsView` rows and passes `week_test`; I did not capture a new pop-up shot |
| EOW: preview equals settlement, including a shortfall | **Pass** | `tests/test_week_payments.gd` (six tests: total is dues plus wages; raised pay shown and charged; a shortfall names who goes unpaid and matches the settlement; pay order; no staff) |
| EOW: old Text rows retired through the workbook | **Pass** | `dues.box_dues` and four `office.week_cost_*` rows removed with `wbx.py` (the new rows replace them) |
| EOW: GAME_SYSTEMS, Information Standards row, CHANGELOG | **Pass** | |

Other tests added: `test_ui_styles`, `test_seats_meter`, `hand_visible_test` (hands of 3 to 6, all three styles, every card on screen with at least 100 px showing).

## 3. `tools/verify.sh` and commits

**Final full run, on the last code commit: "All checks passed."** (export, boot, compile, unit tests, every real-click test, and the text sweep at three sizes with 0 letter-stacked or off-screen rows.) Along the way the sweep caught two off-screen buttons at 1080x1920 Large text (the new body fonts set taller lines; fixed by trimming them to Antaka's line height and shrinking the seats on short screens), and `party_plate_test` caught the new light cue bubble lying over the Details panel (the test now sets the cue aside).

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

## 4. Departures from the mockups, and what is not built

| Not built / different | Why |
|---|---|
| Room-object labels | The pins read "Events", "Marketplace" and so on (the destination), not the mockup's "Phone · Events". An object word shown in one style only would break the same-information rule; the lamp sits where the object is |
| Room-object positions | My first placement from the two pictures (`art.json` `office_hotspots`), not yet looked at by you; the Promises pin only shows when a promise is open, as before. The pins ride on the Office's existing layout, so at very large text they may need a second pass |
| Levels list | Folders use the level's first-room picture, name, hours and button. The mockup's hours ring and the folder-divider tier tabs and "+ Draft a bill" tab are not built; the tier headings and Draft a Bill button are today's |
| Intent | A red band the width of the opponent block, not a floating pill (the label sits in the opponent block's column) |
| Hand fan | All styles use the overlapping row; Living Office's rotated fan is not built |
| Broadcast and Woodblock room arrangements | Slanted plates, 2 x 2 tiles with a Reputation bar, 3 x 2 plaque-topped tiles, framed prints, schedule rows and print cards are not built; those two styles change fonts, colours, plates, buttons, cue and bar, not the arrangement of the Office, Levels or Battle |
| Seat colour for the opponent | The opponent's seats use the existing opponent red, not the party colour (the bar does not know the party yet) |
| Mid-drag battle shot | Not captured (the shot driver has no drag step). Cue showing and cue cleared are captured |
| Office styles tab | Cards with a colour swatch, not picture previews (no preview art exists) |
| Fonts | Latin subsets only; the full Japanese families are not included (Noto Sans JP covers Japanese) |
| Body-font line height | Zen Kaku, Shippori and Noto are trimmed to Antaka's line height so no screen grows |

## 5. Contrast, measured from pixels

Method (`audit/tests/p9_contrast.gd`, throwaway): for each visible Label and Button with text (card faces and art-placeholder filenames excluded), the background is the commonest colour in its rectangle and the ink the colour farthest from it in luminance; WCAG ratio at 1080x2340; text target 4.5. A control clipped by a scroll edge or covered by the cue can read 1.0 (it is not seen); those two are marked.

| Style | Office | Levels list | Payments panel | Battle, cue cleared | Battle, cue showing |
|---|---|---|---|---|---|
| Living Office | min **12.6** | min **9.9** | min **9.9** | min **6.2** | min **6.0** |
| Broadcast | min **11.3** | 8.7 (one clipped button read 1.0) | min **8.7** | min **5.6** | min **5.6** |
| Woodblock | min **4.6** ("· Frontier Party" on its plate) | 13.4 (one clipped button read 1.0) | min **15.1** | min **5.0** | 6.0 (the label under the cue, "49 to advance", is covered: reads 1.0) |

Before the Woodblock plaques the same measurement gave 1.2 to 1 on the battle's turn, threshold and gaffe text. **Icons (3 to 1) were not measured per style**: the seats and the lamp pins were not sampled from pixels. The P4 organization-icon plates are unchanged, and `party_plate_test` still passes (it now sets the cue aside while it measures, because the new light bubble otherwise lies over the Details panel; the old dark band hid that).

## 6. Open issues for the panel

1. Look at the room-object positions on both Office pictures and say which to move.
2. The Broadcast and Woodblock room arrangements are the biggest piece still missing (see section 4).
3. Touch targets: every screen in the app is under 44 pt (90 to 100 px). You chose to leave it; the audit line stays red.
4. The tokens' point sizes (16 / 13 / 11 pt) are not used: sizes stay at today's theme until the text-size decision (T1).
5. Switching style reloads the Office from the saved run; a battle in progress keeps its look until it ends.
6. Prices are 1 XP each (a placeholder); the Appearance and Music panel and the Office styles tab both unlock and switch, so there are two places to buy.
7. The cue (now a light bubble in Living Office) can lie over the Details panel when Details is opened while a line is showing, as the dark band always could.
