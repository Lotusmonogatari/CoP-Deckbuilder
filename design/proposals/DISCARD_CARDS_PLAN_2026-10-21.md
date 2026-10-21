# Discard cards: build plan (2026-10-21), waiting for approval

Your decisions, as I read them:

| Question | Your answer |
|---|---|
| Who picks the discard? | **The player** (chosen) |
| Playable in rooms that do not refill the hand? | **No** (inert and greyed) |
| Does the room mix change during a stage? | **No, it stays fixed** (so no "shift the room" card) |
| Which cards? | See the rule table below |

## The rules, exactly

| Mechanic | Tier 0 | Tier 1 | Tier 2 | Tier 3 | Suits |
|---|---|---|---|---|---|
| **Discard to draw**: choose a card in hand to discard, then draw | none | discard 1, draw 1 (the most) | discard 1, draw up to 2 | none | Duplicitous, Divisive, Emotional, Data Driven |
| **Discard to play**: discard other cards from hand as part of paying for this card | none | discard **2** other cards | discard **1** other card | none | the same four suits |

Not in Earnest or Appeal. Both kinds are unplayable, and greyed with a reason, in a room whose hand is not refilled (the engine's `draw_mode: none`; no real stage uses it today).

## Size of the card set (my proposal, say if you want fewer)

One card per mechanic, tier and suit: 2 mechanics x 2 tiers x 4 suits = **16 new cards**, C55 to C70. That takes Tier 1 from 9 to 17 cards and Tier 2 from 29 to 37. The random opening deck recipe (4 / 4 / 6 per tier, suit-balanced) is unchanged, so new cards only enter the pool; they are not forced into the opening deck.

## What gets built

| # | Piece | Detail | Approx. lines |
|---|---|---|---|
| 1 | **Schema (needs your OK)** | Two new Cards columns: `Discard To Play` (0, 1 or 2) and `Discard For Draw` (0 or 1); the existing `Draw` column says how many cards the effect draws. Header notes added. The exporter rejects a Tier 0 or Tier 3 card with either column set, any other suit, a Tier 1 card with Discard To Play other than 2, and a Tier 2 card with it other than 1. | 60 |
| 2 | **Engine** | `BattleEngine.play_card(card_id, discard_ids)` pays energy, discards the chosen cards to the discard pile, resolves the card, then (for a cycle card) discards the chosen card and draws. `preview()` reports `needs_discard` with a reason ("Needs 2 other cards" / "Hand is not refilled here") so the hand greys correctly. Nothing else triggers on a discard. | 90 |
| 3 | **The choose-a-card prompt** | Tapping a card that needs a discard turns the rest of the hand into "pick" targets (a banner says how many), Confirm plays it, Cancel returns the card. Dragging such a card up opens the same prompt instead of playing at once. Card zoom shows "Discard 2 other cards to play". | 140 |
| 4 | **Content** | 16 cards (names, Japanese names, numbers, effect text) as workbook rows, drafts for you; Text rows for the prompt; How to Play entry; an effect line in the card zoom. | workbook |
| 5 | **Bot** | `playtest_optimal.gd` discards its lowest-value cards; stage trials re-run for balance. | 40 |
| 6 | **Tests** | Engine tests (cost paid, discards to pile, draws after, refused with too few cards, refused in a no-refill room), content tests (the tier and suit rules above), one real-click test of the prompt. | 150 |

About 480 lines in total, over the 150-line threshold, hence this plan.

## Draft card numbers (to tune with bot trials; none final)

| Suit | T1 cycle (cost 1) | T2 cycle (cost 1) | T1 discard 2 (cost 1) | T2 discard 1 (cost 2) |
|---|---|---|---|---|
| Data Driven | Opp -2; discard 1, draw 1 | Opp -3; discard 1, draw 2 | Opp -9; Guard 1 | Opp -11; Gain 2; Reduce gaffe by 1 |
| Divisive | Gain 1, Opp -1, Gaffe +1; discard 1, draw 1 | Opp -2, Gaffe +1; discard 1, draw 2 | Opp -11; Gaffe +2 | Opp -13; Gain 2; Gaffe +2 |
| Emotional | Gain 3; discard 1, draw 1 | Gain 3, Gaffe +1; discard 1, draw 2 | Gain 11; Gaffe +1 | Gain 12, Draw 1; Gaffe +1 |
| Duplicitous | Gain 2, Guard 2, Gaffe +1; discard 1, draw 1 | Gain 2, Guard 2, Gaffe +1; discard 1, draw 2 | Gain 10, Guard 3; Gaffe +2 | Gain 12, Guard 4; Gaffe +2 |

Rough rule behind the draft: a discard-to-play card should be worth about two extra cards of value, so it is a deliberate sacrifice, not a free play.

## Questions before I start

| # | Question | My default |
|---|---|---|
| 1 | OK to add the two Cards columns (a schema change)? | Yes |
| 2 | 16 cards, one per combination? | Yes |
| 3 | May the discarded card be any other card in hand? | Yes, any card |
| 4 | If the hand has too few other cards, is the card unplayable? | Yes, greyed with "Needs 2 other cards" |
| 5 | Card names and Japanese names: draft them myself for you to rewrite? | Yes |
| 6 | Also build the "+1 per 10% of the audience" scale from the earlier ideation? | Not in this round |
