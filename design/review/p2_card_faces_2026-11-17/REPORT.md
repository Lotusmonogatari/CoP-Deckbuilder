# P2: readable card faces and the zoom (2026-11-17)

Branch `panel/p2-card-faces`, from `4eae93c`.

## Step 1: root cause

| Question | Answer |
|---|---|
| Why were the faces dark in Rhetoric Training, the card View and the battle zoom? | Every panel built on `Overlay` calls `BaseImage.install_behind_panel(self)` (`scripts/ui/Overlay.gd:85`) and the battle's card zoom does the same (`scripts/ui/BattleScreen.gd:220`). That function ends with `panel.theme = plate_theme()` (`scripts/ui/BaseImage.gd:91`). `plate_theme()` gives every `Label` a dark translucent "normal" box (`BaseImage.gd:32`, colour `PLATE_COLOUR` 0.84 alpha). A theme set on a panel reaches every descendant, and the card's own labels (cost, name, effect in `CardView.gd`, the ruled rows in `CardBackView.gd`) set a font colour but never their own "normal" box, so they took the plate: dark ink on a dark plate. This arrived with the 2026-11-13 BASE_SCROLLING work and was made worse by "BASE pictures undimmed" on 2026-11-16, which turned the tint into plates. |
| Why was the hand fine? | The hand is not inside an `Overlay` or the zoom panel, so it never inherits the plate theme. |
| Was anything else darkening the zoom? | Yes. The cue banner (`CueBanner`, z_index 50) lay across the zoomed card and hid its name and text. |
| Where is the grade drawn today? | Nowhere. The grade and the room's suit match were taken off the card back on 2026-10-28 by Cameron (`scripts/ui/CardBackView.gd:137`, "The room's suit match and the drawn question's effect were taken off the back"). Their Text rows `card.room_*` and `card.question_*` were orphaned then and removed later (`design/CLEANUP_CANDIDATES.md` lines 26, 27 and 45). `design/INFORMATION_STANDARDS.md` section 1 still said the zoom gives the grade, so the document was stale, not the code. The engine still computes the grade and its multiplier (`BattleEngine.question_multiplier_for`, `_grade_of`) and the zoom still shows "In this room: ..." with the numbers after affinity and grade. |

## Step 2: the fix

| Change | File |
|---|---|
| `CardView.no_plate(label)`: an empty "normal" box override on the label itself, which beats the inherited plate | `scripts/ui/CardView.gd:149`, used at lines 250, 271, 298 |
| The ruled text cells on the back use it | `scripts/ui/CardBackView.gd:115` |
| The cue banner is hidden while the zoom is open and returns when it closes (Cameron chose this) | `scripts/ui/BattleScreen.gd:236` |
| Test: a front and a back of each of the six suits in the hand, the Rhetoric Training offer, the card View and the zoom; reads the pixels of the effect-text area; fails if the mean luminance is below the plain face's minus 10% or the ink contrast is under 4.5 to 1 | `tests/interaction/card_faces_test.gd` (found and run by `tools/verify.sh`) |

The test fails on the old code (before the fix: training offer, card View and zoom faces measured luminance 0.04 to 0.07 against 0.6 to 0.8 for the plain face and contrast 1.1 to 1.4 : 1) and passes now.

## Contrast measured from pixels (after the fix)

Contrast is WCAG relative luminance: the median pixel of the effect-text area (the face) against its darkest pixel (the ink). Plain = the same card drawn with nothing around it.

| Suit (card) | Front: plain / training / View | Back: plain / training / View / zoom |
|---|---|---|
| Earnest (C02) | 13.2 / 13.2 / 13.2 | 11.2 / 11.2 / 11.2 / 11.2 |
| Emotional (C05) | 15.4 / 15.4 / 15.4 | 13.1 / 13.1 / 13.1 / 13.1 |
| Appeal (C09) | 13.9 / 13.9 / 13.9 | 12.6 / 12.6 / 12.6 / 12.6 |
| Data Driven (C14) | 14.1 / 14.1 / 14.1 | 13.0 / 13.0 / 13.0 / 13.0 |
| Divisive (C19) | 14.2 / 14.2 / 14.2 | 12.8 / 12.8 / 12.8 / 12.8 |
| Duplicitous (C23) | 12.3 / 12.3 / 12.3 | 8.5 / 7.2 / 7.2 / 7.2 |

Hand fronts measure 12.3 to 15.4 : 1 in the real battle. Every figure is above 4.5 : 1. The Duplicitous back is the weakest (7.2 : 1): its frame is dark navy and the text sits on a grey veil, so it reads but looks heavier than the others. That is the card art, not a bug, and it passes.

## Step 3: the grade

Cameron decided by popup on 2026-11-17:

| Question | Decision |
|---|---|
| Restore the grade word, the room's affinity and the numbers after both on the zoom? | **No, leave them off.** INFORMATION_STANDARDS section 1 now says the zoom shows what the card will do in this room and does not name the grade or the affinity. |
| Also show a likely range of people reached? | **No.** Not built. |
| Hide the cue banner while the zoom is open? | **Yes.** Done. |

Because the grade is not restored, no new Text rows or Balance numbers were needed, and no "zoom numbers equal what the engine applies" test was added (the zoom already shows `engine.preview(card)`, which uses the same `affinity_for` and `question_multiplier_for` the engine applies when a card is played).

## Shots

At 1080 x 2340, the `_169` suffix (1080 x 1920) and the `_bigtext` suffix (Large text size). Names: `P2_B04_training_offer_C23` (the Rhetoric Training offer; front and back are one popup), `P2_B07_card_view_C09` and `P2_B08_card_view_C09_lower` (the Office card View, top and scrolled), `P2_D01_hand` (the hand, unchanged), `P2_D02_zoom_question_room_Strong_C02`, `..._Medium_C09`, `..._Weak_C23` (the zoom in a question room, one card for each grade against the room's current question), `P2_D02_zoom_no_question_room_ST271` (Radio Debate, the only one of 229 combat stages that asks no question).

## Things noticed and not changed

| Item | Note |
|---|---|
| Duplicitous back | A pale disc is drawn behind the middle of the text; with the dark frame it looks busy. Art, not code. |
| `design/CLEANUP_CANDIDATES.md` | Still lists the `card.question_*` rows as orphaned and later removed; accurate. |
