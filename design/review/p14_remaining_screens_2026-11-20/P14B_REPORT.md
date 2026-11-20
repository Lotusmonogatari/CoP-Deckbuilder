# P14b: the remaining screens (draft for Cameron, 2026-11-20)

Branch `panel/p14b-remaining-screens` (from `main` at the merged part one, `ec5f855`). Presentation only: no rule, number, ID or canon changed. Pictures (540 x 1170) are in `img/`: `floor_vote_cards_*`, `B14_staff_assignments_*`, `B13_staff_profile_*`, `B06_deck_*`, `card_offer_*`, `item_sheet_*`, `c3_*` (Travel, party, draft, law, promises), `c4_*` (Appearance, Characters, How to Play, New Game), `c5_level_intro_*`.

## 1. Executive summary

| Question | Answer |
|---|---|
| What | The 16 screens of groups 4 to 7, the Floor Vote built to the mock-up (with your two changes), the full Travel page, one tile per promise and the level intro's bill card. Seven commits, each passing the full `tools/verify.sh` before it was pushed. |
| What did not change | Node names, button texts, flows and the way out of every screen. Two click tests changed on purpose (section 4). |
| Needs your word | Section 5. |

## 2. Screens against the plan

| # | Screen | Done | Note |
|---|---|---|---|
| 4.1 | Staff Assignments | Yes | Frame and section cards; a card for every hired person (tested); Confirm fixed in the foot with its reason |
| 4.2 | Staff profile | Yes | Identity, Loyalty and pay, Bonuses by rank, actions; Fire last in the fall colour |
| 4.3 | Rhetoric Training | Yes | Cards since P13; names a coupon you hold. The spec's "your next session is free" is reworded: a coupon is redeemed from your items, not taken off a price |
| 5.1 | Your Deck | Yes | Suit chips, In your deck / Collection switch, two-column tiles. The Collection stays the default, as before |
| 5.2, 5.3 | Card offer, card look | Yes | Pop-up cards |
| 5.4 | Inventory | Yes | The picked item is a bottom sheet with Use and Close |
| 6.1 | Travel | Yes | Bottom sheet confirm with **All trips**, opening the full Travel page |
| 6.2 | Draft a Bill | Yes | Frame and cards; Draft fixed in the foot |
| 6.3, 6.4 | A bill to carry, law detail | Yes | Pop-up cards; the law's tag is PASSED (green) or FAILED (red) |
| 6.5 | Party detail | Yes | Colour band, seats and leader, how they see you, Allies and Rivals cards |
| 7.1 to 7.3 | Appearance and Music, How to Play, Characters | Yes | Cards; the equipped option filled; Characters in two columns with the colour as a left edge |
| 7.4 | New Game | Partly | Cards, a Choose button in the accent colour. The pick-then-"Play as" flow is **not** built |
| 1.6 | One card per promise | Yes | A tile for each, with the office and the time left (red when close) |
| 3.1 | Floor Vote | Yes | Built to the mock-up; the action row is up under the bill; each projection shows "Likely Passes" or "Likely Fails" at the right in green or red |
| 2.5 | Level intro bill card | Yes | A card, the stance note on a plate, leader portrait or kanji disc on the lean buttons |

## 3. Data added

Text rows (all Claude drafts for you to reword): `floor_vote.projection_result`, `deck.filter_deck`, `deck.filter_all`, `deck.suit_chip`, `travel.page_title`, `travel.where_title`, `travel.all_trips`, `party_opinion.seats_line`, `party_opinion.seats_line_no_leader`; `rhetoric.coupon_line` reworded. None of these were in the approved list of 18. No schema change.

## 4. Tests

| Test | Checks |
|---|---|
| `tests/test_group4_staff.gd` (3) | Every hired person has a card; Confirm in the foot; the profile's cards with Fire last; the coupon note |
| `tests/test_group5_cards.gd` (4) | Suit chips add up; the switch lists the deck or the collection; the card look and the item sheet are pop-up cards |
| `tests/test_group6_bills_travel.gd` (6) | The Travel page and its sheet, the law tag, the party band, Draft in the foot, a tile for each promise |
| `tests/test_group7_reference.gd` (4) | A card for every guide entry; Characters in two columns; a card for every champion; the equipped option filled |
| `tests/test_group2_3_dress.gd` (+2) | The party disc is a circle; party words sit on a plate that reads |
| Changed on purpose | `tests/interaction/whip_driver.gd`: the click now scrolls the control into view (the whip stepper sits below the fold). `tests/interaction/office_menus_driver.gd`: a rival's bar is the card's ink, not white (white vanishes on a light card). |

## 5. For your word

| # | Question | My recommendation |
|---|---|---|
| 1 | New Game: build the spec's flow (tap a portrait, see its card, then "Play as {name}")? It changes how a run starts, and you tuned the swipe strips and Choose buttons recently. | Leave it as is. |
| 2 | Show each member-visit and trade answer's rhetorical style (from part one)? | Not yet. |
| 3 | The mock-up's colour legend under the projection bars ("green Aye, red Nay, grey Abstain, empty unknown") needs new wording. Add it? | Yes, one Text row. |
| 4 | The Travel page opens only from the trip confirm's All trips button. Is that findable enough? | Yes for now; a new Office button was your other option. |

## 6. Found, not fixed

| What | Where |
|---|---|
| Promises demo text in my pictures shows "0 hours of your time for , due in 0 hours": the demo promises have no text; real ones do | pictures only |
| 40 MB of review pictures now in `design/review/` for P14 | `CLEANUP_CANDIDATES.md` |
