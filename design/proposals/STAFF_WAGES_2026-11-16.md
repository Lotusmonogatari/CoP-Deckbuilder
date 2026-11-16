# Staff wages: two designs (draft for Cameron, nothing built)

Staff today are a one-time cost: hire price, upgrade prices, severance when fired (10% of hire cost, Balance `Staff Severance Share`). Hired staff are kept at no running cost. Both designs below add a weekly wage, charged at the week end beside party dues, with a penalty for non-payment. Every number is a Balance row; every sentence is a Text row. Both need new run state and code, so they are proposed here first.

Ground rules shared by both:
- Wage per person = a share of **their total paid-in price** (hire plus upgrades) or of the hire price (Cameron's example: 10% of hire cost). Balance: `Staff Wage Share`.
- Paid from Funds at the week end, after dues. The week-end report lists each wage.
- The Staff screen shows the wage and the status (Paid, Late, Last warning) before the player acts.
- A relief mode follows the Campaign Pressure setting (Relaxed halves, Harder adds half), like dues.

## Method A: Tier ladder (Cameron's example)

| Step | Rule |
|---|---|
| Wage | 10% of hire cost per week, per person (extras included) |
| Missed payment | That person drops **one rank**. They keep their rank rewards already earned, but lose the rank's effects (item boosts, level-unlock price reduction from the researcher) |
| Paid again later | They stay at the lower rank; climbing back costs the normal upgrade price |
| Two misses at rank 0 | The person **quits for good** and is removed from the candidate list (they never return). No severance is paid either way |
| Whom to pay first | Player chooses nothing: payment goes in staff-list order, so a shortfall hits the last-listed people. Primary staff are paid first |

Strengths: simple, tells a clear story, the cost is felt as lost strength before it is lost people. Weakness: a short week of Funds can strip several people at once; a spiral is possible (lower rank means lower boosts, so less income).

Safeguards to consider: partial payment pays whoever it can in full (no half payments); the first miss on a person is a **warning** shown in the Office that week and costs nothing yet (a "grace week"); a Balance switch for the grace weeks (0 or 1).

## Method B: Retainer with a loyalty meter (softer, more choice)

| Step | Rule |
|---|---|
| Wage | 10% of hire cost per week, per person |
| Each person has a **Loyalty** 0 to 100 (starts at 70) | Paid on time: +5 (cap 100). Missed: −25 |
| Thresholds | Loyalty under 50: the person's rank rewards on **new** upgrades are withheld and their transition lines turn curt. Under 25: effects of the rank pause. 0 or below: they resign and never return |
| Player choices | On the Staff screen: **Raise pay** (wage x1.5 for the week, loyalty +10), **Skip this week** (a chosen miss, shows the cost first), **Pay all** (default) |
| Recovery | Paying on time rebuilds Loyalty at +5 a week; a bonus event or a gift item could add more later |

Strengths: the player chooses who to shortchange and sees it coming; a bad week is recoverable. Weakness: one more meter to explain, more screens and text, and a new stored number per person.

## Comparison

| | A: Tier ladder | B: Loyalty meter |
|---|---|---|
| New run state | A "weeks unpaid" count per person, rank penalty | Loyalty per person |
| New screens | None (week-end report and Staff profile lines) | Staff profile gains the meter and three buttons |
| Player agency | Low (only: keep Funds up) | High (choose who to pay) |
| Risk of a spiral | Higher | Lower |
| Build size (estimate) | About 150 lines plus tests | About 300 lines plus tests |
| Closest to your example | Yes | No, but covers the same intent |

## Costs to check before choosing (draft arithmetic, to be simulated)

At 10% of hire price: Hana Takahashi (hire 40,000円) would cost 4,000円 a week. The full 21-person staff would cost about 10% of the sum of their hire prices; the weekly Funds income and party dues in the simulations should be compared before the share is fixed. A simulation (the dues-first bot used for dues) can be run once Cameron picks a method.

## Open questions for Cameron

1. Wage base: hire price only, or hire plus upgrades paid?
2. Should extras (slots bought with Expanded Staff Office) pay the same wage?
3. A person who quits: gone forever (your example), or can they be re-hired at a higher price after some weeks? (Forever is easier to build; the candidate-list removal needs a saved "quit" list like `staff_fired`.)
4. Does the lost rank hit **effects only**, or also the rank's one-time rewards (already given, so nothing to take back)?
