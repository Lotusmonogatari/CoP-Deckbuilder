# Discard card trial (2026-11-03)

The playtest bots never played a card that makes you discard, so every balance figure before today left the 16 discard cards (C55 to C70) out. The bot now plays them (`tools/playtest_optimal.gd`, `_best_play`), and a new trial mode measures each one.

## Executive summary

| Finding | Evidence |
|---|---|
| Six discard cards are stronger than any ordinary card tested, including Tier 3. | C69 and C70 +19 points of win rate, C67 +17; the best ordinary card (C53, Tier 3) +14, the typical ordinary card +2 to +5. |
| Discarding is nearly free. | The rest of the hand is thrown away at the end of the turn anyway, so the bot almost always discards cards it would not have played. |
| Opponent-only cards are dead in the Party Caucus. | C55, C56, C58, C63–C66 lose up to 21 of 40 caucus fights (a caucus does not count the opponent's support). Ordinary opponent-only cards (C17, C20) show the same. |
| The hardest room flips. | Finance (ST16): 5–8 wins in 40 for the starting deck; 33–40 with C63, C64, C69 or C70. |

## Method

`PLAYTEST_CARD_TRIAL=40 PLAYTEST_CARD_TRIAL_BASE="C27;C01;C05;C06;C35;C38;C14;C13;C07;C19;C22;C51;C23;C33;C26" PLAYTEST_CARD_TRIAL_CARDS="C63;..." .tools/godot --headless --path . tools/playtest_optimal.tscn`

- One fixed 15-card starting deck (a real opening deck). Each tested card replaces its weakest card (C22).
- 8 rooms (Floor Debate ST02, Party Caucus ST03, Press Conference ST04, Town Hall ST05, TV Debate ST06, Construction ST15, Finance ST16, Government Administration ST17), 40 fights each, the same seeds for every deck: 320 fights per card.
- The starting deck alone won 254, 252, 247 and 255 of 320 in the four processes (78.8% overall), so a difference of about 5 points is noise and 10 or more is real.

## Results: discard cards

| Card | Tier | Style | Cost | Effect | Win % | vs start | Played per fight |
|---|---|---|---|---|---|---|---|
| C69 | 1 | Duplicitous | 1 | Gain 10, Guard 3, Gaffe +2; discard 1 | 97.8 | +19.1 | 3.1 |
| C70 | 2 | Duplicitous | 2 | Gain 12, Gaffe +2; discard to play | 97.8 | +19.1 | 2.7 |
| C67 | 1 | Emotional | 1 | Gain 11, Gaffe +1; discard 1 | 95.6 | +16.9 | 3.7 |
| C61 | 1 | Duplicitous | 1 | Gain 2, Gaffe +1 | 91.6 | +12.8 | 3.4 |
| C62 | 2 | Duplicitous | 1 | Gain 2, Gaffe +1 | 91.2 | +12.5 | 4.4 |
| C64 | 2 | Data Driven | 2 | Gain 2, Opponent −11, Gaffe −1; discard 2 to play | 91.2 | +12.5 | 3.1 |
| C68 | 2 | Emotional | 2 | Gain 12, Draw 1, Gaffe +1; discard 2 to play | 91.2 | +12.5 | 3.7 |
| C63 | 1 | Data Driven | 1 | Opponent −9, Guard 1; discard 1 | 90.9 | +12.2 | 3.8 |
| C56 | 2 | Data Driven | 1 | Opponent −3, Draw 2; discard 2 to play | 90.0 | +11.2 | 5.2 |
| C59 | 1 | Emotional | 1 | Gain 3 | 89.1 | +10.3 | 4.7 |
| C55 | 1 | Data Driven | 1 | Opponent −2 | 82.8 | +4.1 | 4.6 |
| C60 | 2 | Emotional | 1 | Gain 3, Draw 2, Gaffe +1; discard 2 to play | 81.9 | +3.1 | 4.0 |
| C65 | 1 | Divisive | 1 | Opponent −11, Gaffe +2; discard 1 | 78.8 | 0.0 | 3.0 |
| C66 | 2 | Divisive | 2 | Gain 2, Opponent −13, Gaffe +2 | 78.4 | −0.3 | 2.6 |
| C57 | 1 | Divisive | 1 | Gain 1, Opponent −1, Gaffe +1 | 77.8 | −0.9 | 2.5 |
| C58 | 2 | Divisive | 1 | Opponent −2, Gaffe +1 | 72.5 | −6.2 | 3.7 |

## Control: ordinary cards in the same seat

| Card | Tier | Style | Cost | Effect | Win % | vs start |
|---|---|---|---|---|---|---|
| C53 | 3 | Duplicitous | 2 | Gain 9 | 93.1 | +14.3 |
| C25 | 2 | Earnest | 2 | Gain 5 | 87.5 | +8.7 |
| C30 | 1 | Emotional | 1 | Gain 4 | 83.4 | +4.6 |
| C34 | 2 | Emotional | 2 | Gain 7 | 82.5 | +3.7 |
| C32 | 2 | Emotional | 2 | Gain 5, Opponent −2 | 81.2 | +2.5 |
| C17 | 1 | Divisive | 1 | Opponent −3 | 80.3 | +1.5 |
| C08 | 3 | Emotional | 3 | Gain 11 | 80.3 | +1.5 |
| C20 | 2 | Divisive | 2 | Gain 1, Opponent −7 | 71.9 | −6.9 |

## Limits

- One starting deck and one bot. A human chooses discards less well than a planner that sees the whole turn, so the edge may be smaller in real play.
- A card swapped for the weakest card in an early deck; later decks are stronger, so the gaps would narrow.
- Rooms with no fights lost (Press Conference, Town Hall, TV Debate, Government Administration) cannot show a gain.

## Options for Cameron (nothing changed)

| # | Option | What it does |
|---|---|---|
| A | Trim the six strongest: C67, C69 (Tier 1) gain 11/10 → 7; C70 and C68 gain 12 → 9; C63 opponent −9 → −6; C64 opponent −11 → −8 | Brings them to the Tier 3 range (about +10) |
| B | Make discarding cost something: the discarded cards go out of the deck for the rest of the stage, not to the discard pile | Keeps the numbers; a real price for deep stages |
| C | Leave as is: discard cards are rare unlocks and meant to feel strong | No change |
