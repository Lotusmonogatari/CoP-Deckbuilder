# P14 part one: the pop-up card, the conversation screens, the Floor Vote and the stage outcome (draft for Cameron, 2026-11-20)

Branch `panel/p14-remaining-screens`. Presentation only: no rule, number, ID or canon changed. Pictures (540 x 1170, the real game in all three styles) are in `img/`.

## 1. Executive summary

| Question | Answer |
|---|---|
| What was built | One **pop-up card** (kind tag, meta line, title, scrolling body, fixed buttons) now draws the nine group-1 pop-ups plus the P13 reasons and open-place pop-ups. The **conversation screens** (Office Hours, member visit, lobbyist trade, level intro) and the **stage transition** wear the style's dress. The **stage outcome** is a STAGE WON / STAGE LOST card over the dimmed room. The **Floor Vote** has party discs (portrait, else colour disc with the first kanji and the English initials) and dressed vote buttons. |
| What did not change | Node names, button texts, flows and the way out of every pop-up. A pop-up that had to be answered still cannot be dismissed. |
| Gate | `tools/verify.sh`: All checks passed (2,370 unit tests, 52 click tests, text sweep in three styles). |
| Needs your word | Section 5 (four small decisions). |

## 2. Screens against the plan

| # | Screen | Done | Note |
|---|---|---|---|
| 1.1 | Decision! event | Yes | Red DECISION! tag; day, office and hours; date and speaker line; "This is set by the calendar, not bought."; choices at the foot; never a price or buy button (tested) |
| 1.2 | Something comes up | Yes | SOMETHING COMES UP tag; same card |
| 1.3 | Your event in progress | Yes | "YOUR EVENT · 1 OF 3"; the 3 is read from the event's options (`HostedEvent.step_count`), options in a two-column grid |
| 1.4 | Event result | Yes | The result card keeps the same tag; the gathering result says YOUR EVENT · RESULT |
| 1.5 | Week over | Yes | WEEK'S END; payment rows scroll, the two ways on stay at the foot, "Pay Party Dues and Go Home" filled |
| 1.6 | Promises | Partly | PROMISES tag on the card; the rows and Keep buttons are today's (one card per promise and the place chip are left for P14b) |
| 1.7 | Promise broken and alerts | Yes | Alarm tags; alerts use their own title as the tag |
| 1.8 | Moved for you | Partly | The "moved" lines (`travel.forced_move`, `travel.forced_free`) sit at the top of the event card. The staff speech card and the "not open at this office" list have no data, so they are not drawn. The forced special level uses its own title as the tag. |
| 1.9 | Level in progress | Yes | Resume filled, Abandon beside it |
| 2.1 to 2.3 | Office Hours, member visit, trade | Dress only | Name plate, filled choices, accent Continue, in all three styles. The layout (VisitLayout) is the existing one. "Visitor n of m" and the leverage bar were already there. |
| 2.4 | Stage transition | Dress, plus a reason | Continue dressed; while held for 2 seconds it reads "Hold for 2 seconds" instead of staying silent (Standard 2) |
| 2.5 | Level intro | Dress only | The bill card text overlaps itself at some sizes (already so before P14); the redrawn bill card is not done |
| 3.1 | Floor Vote | Partly | Party discs, dressed vote and Research buttons. The header scene, the three stacked projections and the Influence row are today's. |
| 3.2 | Stage outcome | Yes | STAGE WON (green) or STAGE LOST (red) tag on a card over the dimmed room |

## 3. Data added

| What | Detail |
|---|---|
| UI Styles | 9 rows (`scrim`, `alarm`, `scrim_alpha`) |
| Text | 20 rows: the 11 tags and 7 notes from the spec, plus two not in the approved list: `popup.tag_reasons` WHAT MOVED IT and `popup.tag_hire` OPEN PLACE |
| Parties | Two new columns, **Short Name** (BU, YHP, FP, FPI, KJT, CI) and **Japanese Name**, as you gave them. The disc letter is the first **kanji** (遺 for Yezo Heritage, skipping the kana エゾの). |
| Unused for now | `popup.tag_moved`, `event.delegate_who`, `rhetoric.coupon_line`, `travel.closed_here`, `travel.destination` belong to P14b or to the unbuilt pieces above |

## 4. Tests

| Test file | Checks |
|---|---|
| `tests/test_popup_card.gd` (10) | The card, its tag colours at 4.5:1, lending and returning the Overlay's buttons |
| `tests/test_group1_popups.gd` (6) | Tags by kind, a Decision! card has nothing to buy, a must-answer pop-up cannot be dismissed, step count from data |
| `tests/test_group2_3_dress.gd` (5) | Disc letter and initials, disc lettering on every party colour, buttons dressed in three styles |
| Changed on purpose | None of the 52 click tests needed changing: names and texts were kept. The text sweep found one real overflow (three tall choices at Large text on a short screen), fixed by sizing the card's body from the room left. |

## 5. For your word

| # | Question | My recommendation |
|---|---|---|
| 1 | The mockup shows each member-visit and trade answer's **rhetorical style** under it. Today the game does not show it, so the researcher's briefing is a real help. Showing it to everyone changes how hard the visit is. Show it? | Not now. I left it out. It is your design call. |
| 2 | The level intro's bill card text overlaps itself at some sizes (before and after P14). Redraw the bill card in P14b? | Yes |
| 3 | Promises: one card per promise with a place chip (the spec's 1.6) is not built yet. Do it in P14b with the Travel work? | Yes |
| 4 | Party names on the Floor Vote are now white (they were in the party colour, which could not be read on the room picture); the colour stays in the disc and the bar. OK? | Yes |

**Cameron's answers (2026-11-20):** (2) Yes, redraw the level intro's bill card in P14b; wherever a party leader's picture exists in the assets it is used, and a kanji disc stands in only where it does not (the same rule as the Floor Vote). (3) The horizontal line under each party stays in the party colour; the name and the position blurb under it must be legible. Done: both now sit on a dark plate in white (over 7:1), the line is unchanged.

## 6. Found, not fixed

| What | Where |
|---|---|
| The level intro's bill card text overlaps | `LevelIntroScreen` (before P14) |
| 12 MB of pictures here: `design/review/` already holds about 210 MB of finished working papers | listed in `CLEANUP_CANDIDATES.md` |
