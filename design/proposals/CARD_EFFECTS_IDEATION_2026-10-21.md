# Card effect ideation: room composition, discard to draw, discard to play (2026-10-21)

Ideation only. Nothing here is built. Each idea says what the player sees, what it needs from the rules and data, and what could go wrong, so you can pick which to take forward.

## Executive summary

| Topic | Today | Best opportunity | My recommendation |
|---|---|---|---|
| **Room composition buffs** | 17 of 54 cards read the audience mix, almost all as one switch ("+2 if the audience is at least 50%"). The mix never changes during a stage. | Replace the single switch with a **scale** (+1 per 10% of the audience), add **low-audience** and **two-audience** cards, and let a few cards **shift the room**. | Build the scale first. It is one new effect key, needs no UI, and fixes the weak spot that only 13 of 226 combat rooms are 50% Boosters. |
| **Discard to draw** | Nothing discards on purpose. Draw cards simply draw; the hand is discarded at end of turn. | Cycling cards ("Discard 1, draw 2") and a "mulligan". | Build the **random-discard** version first (no new screen), then the **choose-a-card** version if you like it. |
| **Discard another card to play this** | Does not exist. | An extra cost that makes a strong card cost a card from your hand, with a payoff from what you throw away. | Build after discard-to-draw, since both need the same "choose a card" prompt. |

Shared dependency: both discard ideas need a **choose a card from your hand** step, which is a new UI prompt and a change to `BattleEngine.play_card()`. Doing it once serves both.

## 1. Expanding buffs tied to room composition

### Facts from the data

| Fact | Number |
|---|---|
| Combat rooms | 226 |
| Rooms where an audience is 50% or more: Party Members / Press / Bureaucrats / Constituents / Boosters | 59 / 48 / 41 / 30 / 13 |
| Rooms where an audience is 30% or more | 68 / 64 / 55 / 31 / 26 |
| Rooms that carry an "Other" share (now shown in Room rules) | 123 |
| Cards that name an audience | 32 of 54 (22 are "Any") |
| Cards with a composition effect today | 17 (15 use the 50% switch, one the 30% switch, one doubles at 50%) |

The Boosters audience is 50% or more in only 13 rooms, so a Boosters card with the 50% switch is dead in 94% of rooms. The room mix is also fixed per stage, so composition never becomes a decision.

### Ideas

| # | Idea | Example card | What it needs | Risk |
|---|---|---|---|---|
| A1 | **Scale per 10 points.** Gain grows with the share, not a switch. | "Read the Letters Aloud: Gain 3, +1 for every 10% Constituents." In a 40% room that is +4. | New key `scale_per_10_target_segment`; `special_value` is the bonus per 10 points. Card text and the zoom line show the live number. | Needs a cap so a 100% room (Media Ambush) is not absurd. |
| A2 | **Underdog: bonus when the audience is small.** | "Speak for the Few: +3 if Party Members are 20% or less." | New key `bonus_if_target_segment_le_N` family, like the existing `_ge_` family. | Needs care: tiny shares are common. |
| A3 | **Two audiences together.** | "Join the Chorus: +2 if Press and Bureaucrats are 60% combined." | New key with two segment ids; the card needs a second target column. | A new column, so a schema change. |
| A4 | **Largest audience.** | "Play to the Crowd: +3 if the biggest audience in the room is Constituents." | New key `bonus_if_dominant_target`. No new column. | Ties need a rule. |
| A5 | **Win over the undecided (Other).** Now that Other is visible, a card can scale with it. | "Make the Case Plain: Gain 3, +1 for every 10% Other." | Uses `pct_other`, already exported. | Other is large in some rooms (ST18 is 90%). Cap it. |
| A6 | **Shift the room.** A card moves 10% of the audience toward its target for the rest of the stage. | "Work the Hall: move 10% from Other to Press for this stage." | Breaks the current rule that the mix never changes. Needs a per-battle mix and a visible change. | **Biggest design change.** Opens synergy and a new decision, but HT19's "the mix of a room does not change during a stage" would have to change. |
| A7 | **Audience combo with a backing.** An owned backing triggered by audience share (already exists for stage-start bonuses) also boosts the cards aimed at that audience. | Backing M01 Local Support: Constituent cards +1. | The modifier trigger exists; add a card-side effect. | Moderate. |

Presentation for any of these: in the card zoom, the room line already reads in plain words; add "40% Constituents here: +4" so the player sees the live number.

## 2. Discard to draw

| # | Idea | Example card | What it needs | Risk |
|---|---|---|---|---|
| B1 | **Random discard, draw more.** Discard a random card, then draw 2 (net +1). No choice needed. | "Cut the Appendix (Data Driven, cost 0): Discard a random card. Draw 2." | New key `discard_random_draw_2`; the engine already draws and discards. | Random loss can hit your best card; keep it to low-tier cards. |
| B2 | **Choose a card.** Discard a card of your choice, draw 2. | "Review the Record (Data Driven, cost 1): Discard 1. Draw 2." | Needs the choose-a-card prompt (below) and a bot rule. | Cost 0 cards can loop. Require cost 1 or draw at most 2. |
| B3 | **Mulligan.** Discard your whole hand, draw that many. | "Start Over (Earnest, cost 1)." | Simple engine change. Dead in rooms that do not draw. | Strong with big hands; limit to once a turn. |
| B4 | **Dump a gaffe card.** Discard a gaffe-adding card to draw. | "Bury the Evidence (Duplicitous): Discard a card that adds gaffes. Draw 2. Reduce gaffe by 1." | Needs a card filter on the prompt. | Gaffe cards are the Divisive and Duplicitous identity, so it could undercut their cost. |
| B5 | **Reshuffle.** Put the discard pile back into the deck and draw 1. | "Reopen the File: reshuffle your discard pile. Draw 1." | `_draw` already reshuffles when the deck is empty. | Little risk. |

Rules to settle: rooms that never refill the hand (the press conference's no-draw mode) must treat these as inert and grey them out, the way a card that does nothing is greyed today. Hand size 5 and energy 3 give about 2 spare cards a turn, so one cycling card per turn is the right scale.

## 3. Discard another card to play this card

| # | Idea | Example card | What it needs | Risk |
|---|---|---|---|---|
| C1 | **Sacrifice for power.** Extra cost: discard a card. In return, a stronger effect for the energy. | "Declare Them Unfit: Opponent -11 for cost 2 instead of 3. Discard another card." | The choose-a-card prompt; `preview()` must say "Needs another card to discard" and grey the card when the hand is empty. | Easy to break if the discarded card can be a free dud. |
| C2 | **Payoff from the discarded card.** The bonus equals something about it. | "Trade Up (Appeal): Discard a card. Gain equals half its Gain." | Reads the discarded card's numbers. | Makes the best card to discard a weak one; keep the bonus small. |
| C3 | **Discard the same style.** Extra cost: a card of the same rhetorical style. | "Press the Point (Earnest): discard another Earnest card; +3 Gain." | Needs a style filter on the prompt. | Favors single-style decks. That may be the point. |
| C4 | **Discard instead of energy.** Pay by discarding, not energy. | "Call In a Favor: discard a card instead of paying 1." | Alternate cost path in `play_card()`. | Energy is the game's main limit; this loosens it. |
| C5 | **Echo.** Discard a card and copy its effect for free. | "Repeat the Line (Duplicitous): discard a card and play its effect now." | A recursive resolve path. | Highest complexity and the most exploitable; leave for later. |

By suit identity: Earnest "Conscience" cards purge gaffes; Emotional cards trade a card for crowd energy; Appeal cards "trade a favor"; Data Driven cards cut the appendix (discard to draw); Divisive "burn the bridge" (discard for a bigger hit); Duplicitous "bury the evidence" (discard a gaffe card).

## What both discard ideas share (the build)

| Piece | Work |
|---|---|
| The prompt | When a card needs a choice, the hand turns into "pick one" (other cards highlighted, the played card waits). Cancel puts the card back. |
| `BattleEngine.play_card()` | Takes an optional `discard_id`. Validates it (in hand, not the card itself, passes the filter) and spends it before resolving. Discards go to the discard pile and trigger nothing else. |
| `preview()` | Reports "needs a card to discard" so the hand dims correctly. |
| Data | A `special` key per effect (for example `discard_1_draw_2`) and a card-text line; the filter in `special_value` or a new column. |
| Bot | `tools/playtest_optimal.gd` picks the lowest-value card to discard. |
| Tests | Engine tests per effect, one prompt click test. |
| Size | About 250 to 400 lines plus the cards. Over the 150-line threshold, so this needs your approval of a plan first. |

## Recommended order

| Step | Build | Needs a new screen? |
|---|---|---|
| 1 | A1 (scale per 10 points) plus A5 (Other scaling), with 4 to 6 new or reworked cards | No |
| 2 | B1 (random discard and draw) and B5 (reshuffle) | No |
| 3 | The choose-a-card prompt, then B2 and C1 with 4 cards each | Yes, one prompt |
| 4 | A6 (shift the room) only if you want the mix to become a decision | Rule change |

## Questions for you

| Question | Options |
|---|---|
| Should a discard cost be chosen by the player, or random? | Chosen (more skill, needs the prompt) or random (simpler, swingier) |
| Can discard-to-play cards be played in rooms that do not refill the hand? | No (recommended: inert and greyed) or yes |
| Should the room mix ever change during a stage? | Keep fixed (simpler) or allow shifting (A6) |
| How many new cards per mechanic? | 4 to 6 per mechanic, one per suit where it fits |
