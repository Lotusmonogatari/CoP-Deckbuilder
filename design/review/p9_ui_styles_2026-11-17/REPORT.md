# Panel P9: UI styles and End of Week Payments (2026-11-17)

Branch `panel/p9-ui-styles`, from `main` (the card-face fix and the text sweep are already in `main`). All wording is a draft for Cameron. **This is a partial delivery: the framework, End of Week Payments, the style shop and the first Living Office pieces are built and tested; most of the per-screen layouts in the mockups are not.** Section 4 lists exactly what is missing.

## Executive summary

| | |
|---|---|
| Built and tested | Style framework (slot, tokens tab, themes, fonts); End of Week Payments (box, breakdown, week-over pop-up); Office styles shop and switching; seats and arc; the all-cards-visible hand; card-zoom note; parity, gold-lines, hand-visible, card-faces-per-style and switch tests |
| Styles today | Each of the three styles changes fonts, colours, panel plates, buttons and the support-count drawing on **every** screen. Broadcast keeps its gold lines. Card faces are identical |
| Not built | Living Office room objects (lamp pins), speech-bubble cue, intent pill, manila-folder levels list; the Broadcast and Woodblock per-screen layouts (slanted plates, hanging-scroll cue, seals, plaque tiles, framed prints); the mid-drag battle shot |
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

## 2. Acceptance table

Spec "Done means" (UI Styles section 9 and End of Week Payments section 6).

| Line | Result | Evidence |
|---|---|---|
| Every restyled screen matches its mockup layout and tokens at 2340, 1920 and Large text | **Partial** | Tokens, fonts, plates, buttons, seats/arc, hand, payments box and zoom note match; the room objects, bubble cue, intent pill, folder levels list and the Broadcast/Woodblock layouts do not. Shots: `<style>_<screen>_<size>` in this folder |
| `card_faces_test` passes unchanged in all three styles | **Pass** | `card_faces_test` now repeats its whole run per style: "PASS (6 suits, 3 styles)". No assertion was changed |
| Broadcast: support bar and cue band show gold top and bottom lines (D2) | **Pass** | `broadcast_gold_lines_test`: bar pixels (top and bottom rows) in a 1080x2340 viewport, and the cue band's style box (top and bottom borders, no sides, gold) |
| Each screen shows the same information in every style | **Pass for the screens restyled** | `ui_style_parity_test`: Office, the payments breakdown and a battle show identical visible text in all three styles (the random news ticker and the shuffled hand are excluded; the hand's look is `hand_visible_test`). The levels list is not restyled, so not covered |
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

The last complete run before the final changes: the text sweep failed (two off-screen buttons at 1080x1920, Large text), because the new body fonts set lines 25% taller than Antaka and the seats added height. Both were fixed (line height trimmed to Antaka's; seats shrink on short screens) and the sweep then reported 0 letter-stacked or off-screen rows at all three sizes. The final full run is recorded at the end of this report.

| Commit | Content |
|---|---|
| 5da1c58 | A1 framework: slot, tokens tab, `UiStyles`/`UiStyle`/`UiStyleTheme`, theme overlays, fonts |
| 7bbbbd0 | A2 End of Week Payments |
| 2eb60fe | A3 seats and arc |
| 6e74cb4 | B3 Office styles shop, unlock, switch |
| 0549eee | Hand overlap, hand-visible and gold-lines tests |
| 7da54c4 | Card faces per style; parity test |
| d46a095 | Docs |
| 4585317 | Click tests tap the visible part of an overlapped card; line height; short-screen seats |
| c7e74a2 | Zoom note |
| 1f9cdb5 | Woodblock halo and veils |

Existing click tests changed because the hand no longer scrolls sideways: `loop_driver`, `mash_driver`, `click_test` and `org_preview_test` now tap the visible strip of a card (`HandPoint`), `click_test`'s "sideways drag scrolls the hand" became "a sideways drag moves nothing", and `week_driver` reads the new box's total line. No rule or card assertion was loosened.

## 4. Departures from the mockups, and what is not built

| Not built / different | Why |
|---|---|
| Living Office Office room objects, lamp pins, "Open today's docket" card, narration bubble, gear | Needs `office_hotspots` positions per background (`OFFICE`, `OFFICE_UPGRADED`) in `data/art.json`, which only you can place on the art; I did not guess them. The Office still shows today's buttons, in Living Office colours |
| Speech-bubble cue, intent pill | Touches `CueBanner`'s timing and the opponent block; not started. Today's cue band and "Attacking · -1 to -2" line remain in every style |
| Manila-folder levels list, Broadcast schedule rows, Woodblock print cards | Not started; the levels list is today's list in each style's colours and fonts |
| Broadcast and Woodblock layouts (slanted plates, hanging-scroll cue, 攻/守/得 seals, plaque tiles, framed prints) | Not started; only their colours, fonts, plates and buttons apply. Broadcast's slant bar and gold lines are today's, as D2 requires |
| Woodblock ink on pictures | Woodblock's dark ink read 1.2 to 1 on the dark battle picture. Instead of re-plating each screen, its labels carry a light paper halo (5 px outline). It reads, but it is a stand-in for proper plaques |
| Seats colour for the opponent | The opponent's seats use the existing opponent red, not the party colour, because the bar does not know the party yet |
| Hand "rotated fan" (Living Office) | All styles use the overlapping row; the fan rotation was not built |
| Lamp energy dots | Today's yellow dots already read as lamps; no change |
| Mid-drag battle shot | Not captured: the shot driver has no drag step. Cue and clear moments are captured |
| Marketplace "Office styles" tab layout | Cards with a colour swatch, not the mockup's picture previews (no preview art exists) |
| Fonts | Only the Latin subset of each is included; the full Japanese families (many files) are not |

## 5. Contrast, measured from pixels

Method (`audit/tests/p9_contrast.gd`, throwaway): for each visible Label and Button with text (card faces excluded), the background is the commonest colour in its rectangle and the ink the colour farthest from it in luminance; WCAG ratio, 1080x2340. Text target 4.5.

| Style | Office (18 texts) | Payments panel (7) | Battle (13) |
|---|---|---|---|
| Living Office | min **13.3**, 0 below | min **9.9**, 0 below | min **5.5**, 0 below |
| Broadcast | min **10.3**, 0 below | min **8.7**, 0 below | min 2.8, 1 below: the labelled placeholder for undrawn opponent art ("OP17_attacking.png"), not game text |
| Woodblock | min **4.6**, 0 below ("· Frontier Party" on its plate) | min **15.1**, 0 below | min 3.7, 1 below: the same placeholder label |

Before the Woodblock halo and opaque veils the same measurement gave 1.2 to 1 on the battle's turn, threshold and gaffe text; those are the fixes in 1f9cdb5. **Icons (3 to 1) were not measured per style**: the seats and the organization icons were not sampled from pixels. The existing party-colour plates (P4) are unchanged.

## 6. Open issues for the panel

1. Decide whether to place the Living Office room objects (I need the positions on both Office backgrounds) and whether the bubble cue and folder list are wanted before M6.
2. Touch targets: every screen in the app is under 44 pt (90 to 100 px). A single decision about button height is needed; P9 did not change it.
3. Woodblock's halo is a stand-in; real plaque panels behind picture text would be cleaner.
4. The tokens' point sizes (16 / 13 / 11 pt) are not used: sizes stay at today's theme until the text-size decision (T1).
5. Switching style reloads the Office from the saved run; a battle in progress keeps its look until it ends.
6. Prices are 1 XP each (a placeholder); the Appearance and Music panel and the Office styles tab both unlock and switch, so there are two places to buy.
