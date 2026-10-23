# A campaign layer: party dues, name awareness, campaign strength, events (2026-10-23)

Ideation only; nothing here is built. Four ideas that fit together: a recurring cost (dues), a new kind of reputation (name awareness), a long-term score (campaign strength), and a way to deliver all of it (events). All numbers are drafts for Cameron.

## Executive summary

| # | Idea | Fits what already exists | New pieces | Biggest risk |
|---|---|---|---|---|
| 1 | **Party dues**: pay X Funds to the party every Y units (a "day" of 10 units) | The quiet game clock, Funds, Party support, the Funding Freeze, the Steering Committee special level | Show the clock to the player; a dues notice and a pay step; Balance levers | Funds income is lumpy, so dues can feel like a tax rather than a decision |
| 2 | **Name awareness**, two meters: District and National | Constituency support (Jiban) and Reputation already measure *how people feel*; awareness measures *how many know you* | Two meters, decay, media buys, grants, sources from existing stages | Too many meters on a phone screen; needs a clear "known versus liked" story |
| 3 | **Campaign strength score** | XP, Funds, organization standing, laws, staff, awareness all exist | One slow composite (a stock, not a snapshot), a daily growth cap, an Office display | Canon: the game has no early elections, so *when* the campaign pays off needs your decision |
| 4 | **Events**: buyable and random, each a screen of choices with flavor text | Office Hours visitors (multiple-choice rooms), patron requests, the shop's walking tour and dinner items | Two workbook tabs (Events, Event Choices) and one screen built on the visitor machinery | Content volume: about 30 events to feel varied |

**Recommended order:** 4 (events) first because the others need a way to deliver choices, then 2, then 1, then 3 last (it only works once the inputs exist).

## The numbers that frame everything

| Fact | Value |
|---|---|
| Average level length | 5.7 clock units (84 levels, longest 10) |
| A 10-unit day | about 1.75 average levels, about 48 days across all 84 levels |
| Funds income per won level | about 195,000 Yen before the organization value pass, more now |
| Funds ceiling | 1,000,000 (the Funds cap) |
| Typical Funds prices | shop 10,000 to 200,000; Draft a Bill 300,000 |
| Existing crisis triggers | Constituency support at or below 15 gives a Town Hall; Party support below 25 gives a Steering Committee; Party support at 0 freezes Funds income |

---

## 1. Party dues

**The idea:** the player owes the party X Funds every Y units. At 10 units a day, dues land about every 1.75 levels.

### Design choices

| Question | Options | My lean |
|---|---|---|
| How much? | (a) Flat. (b) Scaled to Party support or seat tier. (c) A percentage of income (a tithe). | **(b)**, with the base lever in the workbook. A strong standing with the party means lower dues |
| How is it paid? | (a) Auto-deducted at day end. (b) A notice in the Office: Pay, Pay late (with a penalty), Plead (an event). | **(b)**; a decision is more interesting than a silent drain |
| What if unpaid? | A ladder: Party support drops, then Party Headquarters standing, then the Steering Committee special level, then the Funding Freeze that already exists | Reuse the existing ladder rather than build a new one |
| What does paying buy? | Small Party support gain; standing with Party Headquarters; at a high payment streak, a free event (a party fundraiser invite) | Keep it small; the real reward is not being punished |
| Relief | Items, events, and a Party-tier backing can lower or waive dues | Gives the Party backings (BO01, BO02, BO31, BO32) a use |

### Draft numbers

| Lever | Draft |
|---|---|
| Units per day | 10 (a Balance lever) |
| Base dues | 40,000 Yen a day (about 10 to 12% of income) |
| Scaling | minus 5,000 for each 25 Party support, floor 15,000 |
| Late penalty | dues plus 25%, and minus 3 Party support |
| Missed twice | Steering Committee special level offered |

### What it needs

| Piece | Note |
|---|---|
| **Make the clock player-facing** | This reverses the 2026-10-18 rule that no time word is shown. Proposed words: "Day 4, hour 6 of 10". Text-tab rows only, plus an Office header line |
| A dues state | Next due day, streak, amount; saved with the run |
| A notice screen | Reuse the event screen from section 4 |
| Test impact | Cooldowns and durations already run on the clock; showing it changes no rules |

**Risk:** funds sinks stack (shop, backings, dues, media buys in section 2, a fundraising event). Total sink should be tuned against income in one pass, not one sink at a time.

---

## 2. Name awareness (district and national)

**The idea:** how many people know your name, separate from whether they like you.

### How it differs from what exists

| Meter | Measures | Moves today by |
|---|---|---|
| Constituency support (Jiban) | Whether your district's voters like you | Stage results, visitors, laws |
| Reputation | Standing with the press and public | Press stages, questions |
| **District Awareness (new)** | How many people in your district know you | Local media, grants, town halls, walking tours |
| **National Awareness (new)** | How many people nationally know you | National media, TV, bills carried, floor votes |

Two axes make a useful pairing: *known and liked* is the goal; *known and disliked* is notoriety, a real tension.

### Sources (the player's list, plus what already exists)

| Source | District | National | Mechanic |
|---|---|---|---|
| **Buy media** | local ads, a local paper | TV spot, national paper, web campaign | Funds for a one-off boost, with diminishing returns per day |
| **Grants from Office Funds** | to local groups and festivals | to a national cause | Funds for awareness plus organization standing |
| **Pass custom bills** (Draft a Bill, patron bills) | small | **large** | A passed bill you carried |
| **Influence static bills** (a vote flip, a whip that changes the result) | small | **medium** | The existing "influence turned the vote" result |
| Stages | Town Halls, Office Hours | Press conferences, TV debates, Media Ambush | A small gain per win, bigger for a strong result |
| Events | walking tours, rallies | talk-show invitations | Section 4 |

### Behavior rules

| Rule | Draft |
|---|---|
| Range | 0 to 100 each |
| **Decay** | Fades each day without upkeep (about 3 percent of the distance to 0; faster nationally) so it takes ongoing effort |
| Diminishing returns | Same gain bands the organization standing uses: full gain below 40, 60% below 60, 40% above |
| **Effect on play** | Awareness multiplies the *size* of sentiment moves (up to plus 20%), and also of gaffe penalties (fame cuts both ways) |
| Effect on rooms | Town Hall turnout and press-room starting tone scale with the matching awareness |
| Feeds | Campaign strength (section 3) |

### What it needs

Two Sanban-style variables, a daily decay step, a media shop tab or event buyables, a display (Your Record plus a small Office strip), and sources wired into existing results. About 250 lines plus workbook content.

**Risk:** a seventh and eighth number on screen. Mitigation: show them only in the Office and Your Record, never in battles.

---

## 3. Election campaign strength

**The idea:** one long-term score for how ready the player is for an election. Hard to raise even for the easy protagonists.

### A stock, not a snapshot

If the score simply read today's numbers, a rich start would max it at once. Instead it should be a **stock that accumulates** from daily growth, with a **daily cap** that is the same for every protagonist. Easy characters start higher; nobody gets there fast.

### Draft components (each capped; the score is 0 to 100)

| Component | Max | Reads from |
|---|---|---|
| District Awareness | 15 | Section 2 |
| National Awareness | 15 | Section 2 |
| Constituency support (liked) | 15 | Jiban |
| Organization breadth | 15 | Number of organizations at standing 50 or more, weighted by tier |
| War chest | 10 | Funds held, log-scaled so wealth saturates |
| Experience | 10 | Lifetime XP, capped by staff tier |
| Legislative record | 10 | Laws passed and bills carried |
| Party backing | 10 | Party support, dues streak, nomination support |

### Growth rules

| Rule | Draft |
|---|---|
| **Daily cap** | at most +1.0 per day (about 48 days across the whole game, so the cap is reachable only near the end) |
| Fall rate | slow decay when components fall (at most minus 0.5 a day) |
| Boosts | Items, events and endorsements can add to the *component*, never straight to the score |
| Display | "Campaign strength 37" plus the weakest component named ("Weakest: National Awareness") |
| Uses | Gates (Party nomination, an endorsement event), and the strength of an election level if you build one |

### Needs your decision (canon)

| Question |
|---|
| Yezo has **no early elections**. Is there a **fixed election date**, and where does it fall in the clock (for example, day 45)? |
| Is the score only a long-term measure, or does it feed a final **Election level** or ending? |
| What does failing cost? |

**Risk:** a composite hides cause and effect. Mitigation: the Record page lists each component with its own cause line, the same way booster standing now shows causes.

---

## 4. Events

**The idea:** a screen with flavor text and choices, opened from a purchase or a random roll. The Office Hours visitor room already does most of this (multiple choices, outcome deltas), so an event is a visitor room without a visitor.

### Three ways an event starts

| Kind | Example | Trigger |
|---|---|---|
| **Buyable** | Walking tour, rally, charity dinner, TV ad shoot, a retreat | A shop or Events item; the shop's existing SH19 (dinner) and SH20 (walking tour) become events instead of random effects |
| **Random** | A local disaster, a scandal rumor, a journalist's invitation, a constituent crisis | A daily roll, weighted by awareness, standing and crisis state |
| **Scheduled** | Dues day, a party fundraiser, an anniversary | The clock |

### What an event contains

| Part | Detail |
|---|---|
| Title and flavor text | One to three sentences (Text-tab rows) |
| Two to four choices | Each with a cost (Funds, units, an item), a result line, and outcomes in the existing reward format (meta, organization standing, awareness, items) |
| Conditions | Staff hired, an organization above N, awareness above N, the day of the week |
| Weight and cooldown | So random events do not repeat |
| Unit cost | A walking tour takes 2 units, the way a stage does |

### What it needs

| Piece | Note |
|---|---|
| Two workbook tabs | **Events** and **Event Choices**, same flat, blank-tolerant style as the visitor tabs |
| One screen | An event screen reusing `VisitorScreen` layout and `RewardTargets` outcomes |
| Triggers | A daily roll at day end, and a hook on buyable items |
| Content | About 30 events at launch: 8 buyable, 14 random, 4 scheduled, 4 awareness-gated. Drafts for you to rewrite |
| Size | About 200 lines plus content |

---

## How they fit together

| Loop | Flow |
|---|---|
| Money | Levels pay Funds; dues, media, grants and events spend them |
| Name | Spending and results raise awareness; awareness decays daily |
| Strength | Awareness, standing, laws, XP and Funds feed the slow score |
| Variety | Events carry choices for all of the above; scheduled events carry dues |

## Cross-cutting risks

| Risk | Mitigation |
|---|---|
| Too many currencies and meters | Show the new ones only in the Office and Your Record; none in battle |
| Funds economy gets over-sunk | One tuning pass for all sinks, with the economy bot |
| The clock was meant to be invisible | Decide whether "day" is a strict calendar or just a label |
| Saves | Add new fields with defaults so existing saves load |
| Content volume | Events and media items are the bulk; build the engine with five events and grow |

## Recommended build order

| Step | Build | Size |
|---|---|---|
| A | Events engine plus five seed events; convert SH19 and SH20 into events | about 200 lines plus content |
| B | Show the clock (a day and hour label) | about 60 lines |
| C | Name awareness meters, decay, media buys | about 250 lines |
| D | Party dues on the event screen | about 120 lines |
| E | Campaign strength (after the inputs are in) | about 150 lines |

Each step over about 150 lines needs your approval of a plan first.

## Questions for you

| # | Question | My default |
|---|---|---|
| 1 | Show a "Day and hour" display, or keep the clock hidden and show dues as "payment due soon"? | Show it: the dues idea needs it |
| 2 | Dues: flat, scaled by Party support, or a percentage? | Scaled by Party support |
| 3 | Pay by notice (a choice) or auto-deduct? | A notice (a choice) |
| 4 | Two awareness meters or one? | Two (district and national), as you described |
| 5 | Does the campaign score feed a final election level? Is there a fixed election date (canon)? | Your call; I will not decide canon |
| 6 | Start the events engine first? | Yes |
