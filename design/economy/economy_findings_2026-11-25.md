# Economy map findings: spirals, unused elements and runaway growth

2026-11-25 · written by Claude from the P19 economy map (`design/economy/`) · a draft for Cameron

## Summary

| Question | Short answer |
|---|---|
| **Spirals** | The map finds seven downward spirals, each a penalty that removes the means of recovery. Only National awareness at 20 or below accelerates (the penalty grows each week). The others are bounded by 0 and have a recovery room or a small penalty. |
| **Unused** | Election strength and audience segment favorability do nothing in play. Cosmetics is a deliberate sink with no effect on strength. |
| **Runaway** | Party support and both awareness meters never decay, so they ratchet to 100 and stay. XP has no ceiling and few sinks once the collection is complete. The dues limit switches off the dues brake at mid-game. |

**Caveat:** the weekly sizes come from the map's draft week (about 10 rooms a week, 92% won). They are not bot-measured. The structure is solid because it comes from the rules and data. Treat the numbers as rough.

## 1. Spirals

A spiral is a penalty that lowers the very thing that would let you climb out. All of them stop at a floor of 0 and do not run forever. The harm is the "stuck low" plateau.

| Spiral | What happens | Escape | Severity |
|---|---|---|---|
| **Party support 0 (S1)** | Funding freeze means no Funds from rooms or levels. Dues go unpaid and cost -30 Party support and the party's backings. | The forced Steering Committee room at 25 or below. Events, visitors and laws still pay Funds. | **Moderate.** It is the only one that starves your money, but it has a forced recovery room. |
| **District awareness 25 or below** | Standing with the Selection Committee falls 10 a week. | Winning district rooms. | Mild. It hits one organization. |
| **District awareness 13 or below (S2)** | -50 XP a week. | Same. | **Weak.** It is about 8% of the roughly 620 XP a week income, a nuisance more than a spiral. |
| **National awareness 20 or below (S3)** | -5 standing with every National organization, **plus 5 for each week in a row**. Backings need standing 60, so fewer backings lead to fewer wins and less awareness. | Winning press, TV and ambush rooms. | **Strongest.** It is the only one that accelerates. |
| **Reputation 20 or below** | Press-style rooms start 5 down. | Winning press rooms. | Mild. It only affects one room type. This one was not in the method doc; the map found it. |
| **Constituency 15 or below** | A Town Hall is forced in. | Winning it. | Not a spiral if the Town Hall is a recovery room. |

Constituency at 15 or below and the Steering Committee are both written in the map as brakes, which is a judgement call. If a forced room is hard to win at that point, they become spirals too.

## 2. Unused elements

| Element | State | Why it matters |
|---|---|---|
| **Election strength** | Computed every week (+2.5 up, -1.5 down) from eight inputs and shown in the Office, but it triggers nothing. | Ten `election_*` levers tune a number with no effect. It is an open question in CLAUDE.md. It could be the late-game goal or sink. |
| **Audience segment favorability** | Rewards from shop items and staff change it. Nothing reads it to change play. | Dead weight in the data and rewards. |
| **Cosmetics** | A Funds and XP sink with no effect on strength. | This is intentional and probably useful. Pure sinks are what the economy lacks late (see below). |

## 3. Runaway growth and inflation

Every growth loop (R1 to R6) runs through winning rooms. Here is what keeps each one bounded.

| Stock | Brake | Verdict |
|---|---|---|
| **Constituency and Reputation** | They decay 25% and 15% of the distance back to the start each week. Room pay of about 12 and 7 points a week gives a rough balance in the 50s and 60s. | **Bounded.** They may never reach the 80 gates on room pay alone. |
| **Organization standing** | Gains shrink to x0.6 and x0.4 above 40 and 60, and it decays about 12% a week. | **Well braked.** |
| **Party support** | It has **no decay**. Rooms add about 12 points a week. | **Runaway to 100 in about 7 weeks.** The free backing M09 (above 75) then stays on, and the only cost is dues. |
| **District and National awareness** | **No decay**. Rooms add about 2 and 5 points a week. | **Ratchets to 100 in roughly a game year.** At 80, you get dues relief and a **free training coupon every week**. The coupon is a free card draw with no XP spent. |
| **Funds** | Capped at 100,000円, raised by the petition (SH13, **100 XP for +100,000円**, up to 1,000,000円). | **Weakly braked.** Raising the cap is cheap in XP. |
| **XP** | **No ceiling.** The sinks are finite: about 28,000 XP for the collection, level unlocks, item prices and drafting. | **The main inflation risk.** After about 45 weeks, XP piles up with nothing to buy. |

**The dues limit weakens two brakes.** Dues at Party support 70 would be 97,431円 uncapped, so the 90,000円 limit holds. Above that point, extra Funds earned and extra Party support add no dues, so the dues-share brake (B2) and the dues-steps brake (B1) are both off.

## What to measure first

1. How many weeks Party support and awareness take to reach 100 in a bot run.
2. XP income against XP spent after the deck is complete.
3. Whether the weekly coupon plus free draws finishes the card collection early.

If any of these confirms a runaway, the cheap fixes are all data changes: awareness or Party support decay, a late XP sink, or letting election strength spend XP or Funds. Those are Cameron's design decisions, so nothing has been changed.

## Where the numbers come from

- `design/economy/economy_catalog.csv`: the flows (FL001 to FL563), including the unused-status rows FL525 and FL526.
- `design/economy/economy_loops.md`: the cycles, spirals by low gate and dead ends.
- `design/economy/economy_week.md`: the standard and early weeks and the dues arithmetic.
- `data/sanban.json`: Party support and the awareness meters have no `decay_percent`; XP has no maximum.
- `data/awareness_effects.json` AE01 to AE07; `data/shop.json` SH13 (the Funds cap petition) and SH21 (the Training Session Coupon, 150 XP).
