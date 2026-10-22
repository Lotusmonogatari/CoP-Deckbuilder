# Spending party sentiment on a bill level: where it could live (2026-10-22)

Ideation only; nothing here is built. The idea: in a level about a named bill, the player can **spend Party support** to buy an **extra vote** or a **level-wide bonus** (a bonus card, extra energy, an extra turn, and so on).

## Executive summary

| Question | Answer |
|---|---|
| Best place to offer it | **Two places**: a "Call the party" choice on the **Level Intro** screen (level-wide bonuses, before the first stage) and a "Whip the vote" button on the **Floor Vote** screen (extra votes, just before voting). Both screens already exist for every bill level. |
| Is the machinery there? | **Mostly.** Level-wide bonuses already exist (ENERGY, GUARD, DRAW, TURNS, GAFFE_CAP, `GameState.level_bonuses`). Extra votes already exist (`BillAssist` won-over seats, counted by the vote preview). Spending Party support is the new piece. |
| What is missing | A **spend path** for Party support, a place to show it, and one schema gap: visitor choices cannot touch Sanban values today (see option 4). |
| Biggest risk | Party support also drives the Town Hall / Steering Committee crisis, the funding freeze and the vote-influence gate. Spending it can push the player into those, so every offer needs a **floor** and a clear label. |
| Named bills it reaches | All 50 bill levels through the two screens above (plus sponsored and drafted bills, since they use the same screens). Visitors reach only the 31 levels that have an Office Hours stage. |
| My recommendation | Build options 1 and 2 first (about 300 lines, no new schema), then decide on 5 and 6 once you see how the spending feels. |

## What "party sentiment" is in the game today

| Term | Meaning | Spendable? |
|---|---|---|
| **Party support** (stored) | The Sanban number the player's votes, leans and laws move | Yes: `GameState._move_meta()` already spends Funds the same way |
| Party support (effective) | A 50/50 blend of the stored number and how the party's allied organizations feel; **this is what the rules read** (crisis triggers, funding freeze, the vote-influence gate) | No: it is derived. Spending lowers the stored number, so effective support falls by about half as much |
| Party standing (other five parties) | How each other party sees the player | No: not the player's to spend |

So "spend party sentiment" should mean **spend the stored Party support**. Because the rules read the effective number, a spend of 10 costs about 5 effective points; the offers below price in stored points.

## What the player could buy

| Boost | Machinery | Reads as |
|---|---|---|
| **+1 Aye (an extra vote)** | `BillAssist.add_won_over(own party, 1)`; already counted by the vote preview and the influence-flip flag | "Whip one more member into line" |
| **+1 energy in every stage** | `level_bonuses` token ENERGY | "The caucus backs you with time" |
| **+1 card in hand each turn** (a bonus card) | token DRAW (hand size) | "Staff brief you better" |
| **+1 turn in every stage** | token TURNS | "Extra time on the floor" |
| **+1 gaffe allowed** | token GAFFE_CAP | "The party covers a slip" |
| One extra card on the first turn only (new) | a one-time opening draw; new token | "A strong opening" |
| Start each stage with 2 Guard | token GUARD | "Whips shield you" |

Draft prices (stored Party support, all Balance levers): extra vote 8 (up to 3 a vote), +1 energy 15, +1 card 12, +1 turn 10, +1 gaffe 10, opening card 6, guard 8.

## Where it could live

| # | Opportunity | What the player sees | Needs | Reach | Effort | Notes |
|---|---|---|---|---|---|---|
| 1 | **Level Intro: "Call the party"** | After the lean choice, a row of 3 to 4 boosts, each showing its Party support price; pick one or none | `GameState.spend_party_support()` (new), then the existing `pending_level_bonuses` path; a Text-tab row per boost | All 50 bill levels (and sponsored and drafted bills) | About 150 lines | Best level-wide fit. The party leader's portrait is already on this screen |
| 2 | **Floor Vote: "Whip the vote"** | A button under the bill: "Whip 1 more Aye: 8 Party support", up to three times; the preview updates live | A spend plus a `BillAssist` entry; the vote preview already adds assist | All bill levels | About 120 lines | Directly "an extra vote". Cost can depend on the bill (see below) |
| 3 | **Battle: "Call the whip" button** | Beside Inventory, once per stage: spend for +1 energy now, or draw 1 | Item-style effect from the Party panel | Bill levels' battles | About 200 lines | Most flexible and most likely to feel like a cheat code; keep it last |
| 4 | **Special visitor: the party whip** | A visitor question whose choices cost Party support and grant a level bonus or a vote | **Schema:** a visitor choice's Effects cannot target Sanban values today; it would need a "spend Party support" target | Only the 31 levels with an Office Hours stage (11 older levels plus the 20 newer ones pinned to slot 1) | About 100 lines plus workbook | Good flavor; thinner coverage |
| 5 | **A booster effect: "Party Discipline" backing** | A purchasable backing from Party Faction or Party Activists that unlocks a once-per-level boost, paid in Party support | New modifier effect type; an activate button | Every level once owned | About 180 lines | Ties into the existing Party Bodies and their standing |
| 6 | **A shop item priced in Party support** | "Whip's Favor" in the Marketplace: a level buff bought with Party support, used before a level | A third cost column on Shop items | Every level | About 80 lines | Smallest build, least tied to the named bills |
| 7 | **Stage transition offer** | A staff member or leader between stages offers a one-time boost | Uses transition dialogue plus a choice | Rooms that show a transition | About 150 lines | Transitions are optional and sparse |
| 8 | **Lobbyist trade: pay with Party support** | Spend Party support as extra leverage in the trade | Trade stage change | Sponsored and drafted bills only | About 60 lines | Not for named bills; listed for completeness |

## Making it about the bill (so it is not generic)

| Lever | Effect |
|---|---|
| **The player's party's position on the bill** | Supportive: the boosts cost the base price. Neutral: base price. Opposed: double, or unavailable ("your own party will not whip for this") |
| **The bill's salience for that party** (`PartySalience`, 0.5 to 2.0) | Scales the price: a bill the party cares about is cheaper to rally for |
| **The lean the player took** | Leaning with the party: normal price. Leaning against it: costlier |
| **Seats available** | An extra vote is limited by how many of your party's seats are not already on your side; at some point there is nobody left to whip |

## Guardrails

| Risk | Guard |
|---|---|
| Spending drops the player into the Steering Committee crisis (effective Party support below 25) or the funding freeze | A **floor**: refuse any spend that would leave stored Party support below a lever (Balance, draft 30) |
| Stacking boosts makes bill levels trivial | One level-wide boost per level; extra votes capped per vote |
| Spending hurts the vote-influence gate (it reads effective Party support) | Show the gate's state in the spend row, and let the floor protect it |
| The spend is not visible later | A cause line in Your Record: "Called in the party" |
| A refund if the level is abandoned | No refund (it was a choice made at the start); an abandoned level keeps the spend |

## Questions for you

| # | Question | My default |
|---|---|---|
| 1 | Spend the stored Party support (not a new currency)? | Yes |
| 2 | Floor for spending (stored Party support never goes below)? | 30, a Balance lever |
| 3 | One level-wide boost per level, or several? | One |
| 4 | May a player whose party **opposes** the bill still whip? | Yes, at double price |
| 5 | Do bought votes count as "your influence" for the flip cue and the Vote Influence Cues? | Yes (they already do for assist seats) |
| 6 | Start with options 1 and 2? | Yes |
