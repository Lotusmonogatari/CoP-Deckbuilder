# Influence building: two stages, worked out (2026-10-19)

Status: **ideation only, nothing built.** Expands the two ideas pinned in `INFLUENCE_BUILDING_IDEAS_2026-10-19.md`. Every number is a first draft and would be a Balance lever.

## Decisions (Cameron, 2026-10-19), which override the drafts below

| Topic | Decision |
|---|---|
| MP visit: who is offered | A visit is offered for a party **unless it is maxed out** (nothing left outside your pick). The point is to **guarantee +1 seat** on top of the influence swing, so it takes a seat from the party's larger non-pick bucket, ignoring the gate and Vote Resistance |
| MP visit: what +1 means | **One seat** |
| MP visit: a lost fight | No cost other than the stage |
| MP visit: optional | Yes, the player may skip it |
| MP visit: which bills | **Patron (player-sponsored) bills only.** Existing bills get a different form of the idea later (pinned below) |
| Policy Researcher briefing | A hired **Policy Research Assistant at staff rank 2 or 3** briefs the player first, in natural speech, on the visiting member's preferred styles. Below rank 2, or nobody hired: no briefing |
| News ticker (visit) | After the bill's outcome, a success shows on the Office ticker: "Sources say {player} was working hard to win over individual members of parliament for their latest sponsored legislation. - Yezo News Nightly" |
| Lobbyist leverage | A **budget** the player spends |
| Lobbyist refusal | Favor bill: free. **Flagship: refusing costs 2 seats; meeting without reaching an agreement costs 1 seat** |
| News ticker (lobbyist) | Shown the same way: "Reports from within Parliament indicate strong lobbyist work against {player}'s recent sponsored legislation. - Yezo News Nightly" |
| Lobbyist: which component | Any except the last, as recommended |
| Lobbyist: help | **A seat** |

Pinned for later: **a visit-style influence stage for the existing (not player-sponsored) bills, in another form.**

## Executive summary

| | Idea 1: MP visit | Idea 2: Lobbyist trade |
|---|---|---|
| One line | A member visits, you win them over in a short exchange and a one-on-one fight | A lobbyist offers to buy a component out of your bill; you negotiate what you get for it |
| What it gives the vote | **+1 seat for your pick** per member won, for this vote only | A smaller, tunable bill-wide help, plus Funds, XP, organization and party favor |
| What it costs | A stage of play; risk of losing the fight | A component of the bill (its effects, and the patron's pleasure) |
| Reaches parties the gate and resistance block | **Yes.** It is the only way to move Five Point Independents (resistance 99 means influence swings 0 of their 5 seats) | Partly (via party favor and the help package) |
| New engine | One pure rule (`BillAssist`), one stage family, a rapport step | A negotiation engine (leverage meter) and a screen |
| Best first target | Five Point Independents and Yezo Heritage Party, as you said | Flagship bills, where there are three components to spare one from |
| My recommendation | Build first: small, reuses battles, visitors and opponents | Build second: more new UI, but it opens the economy side (Funds, XP, favor) |

Both write into one per-level record, `bill_assist`, that the Floor Vote reads, so they can ship separately.

## What the data already gives us

| Fact | Why it matters |
|---|---|
| Every party's MPs in the Opponents tab add up to its seats (19, 14, 27, 5, 25, 11 = 101) | A member you win over is, literally, **one seat**. "+1 influence" can mean exactly that |
| Swing capacity per party from Vote Resistance: Butsutou 2, Yezo Heritage 2, Frontier 7, Five Point **0**, Keizaijiyuutou 8, Country Initiative 1 | Five Point can only be reached by the visit. Yezo Heritage's 14 seats yield 2 by influence, so a visit is worth a lot there |
| MPs carry three rhetorical styles (`suit_1..3`) | The visit's questions can be graded with no new authored grading |
| Eight lobbyist-type opponents exist in the Lobbyist Meeting (ST20), each with an organization | The lobbyist is already cast; the organization is already known |
| Every component lists the organizations it helps and hurts | The lobbyist's ask is derived: they want the component that hurts their organization dropped |

## Idea 1: the member visits

### Flow

| Step | What happens |
|---|---|
| 1. The visit | A short visitor-style exchange (3 questions, four answers each) with a member of a party you want to move. Pure dialogue, no cards |
| 2. Rapport | Each answer is Strong, Medium or Weak for that member. The sum is a **rapport** score from -3 to +3 |
| 3. The fight | A one-on-one battle against the same member. Rapport changes the **starting support** (draft: +5 for you per rapport point, so -15 to +15, and the member's start moves the other way) |
| 4. The prize | Win: the member's seat goes to your pick **for this bill's vote only**. Lose: nothing moves. Stage losses do not end the level (like the press conference) |

### How the answers are graded (options)

| Option | How | Cost | Verdict |
|---|---|---|---|
| A. Authored framings | Four hand-written framings per policy area, graded by the member's party values | 34 areas x 4 lines, plus grading rules | Rich, but the most content |
| **B. Rhetorical styles** | The four answers are four styles; grade = the member's own `suit_1/2/3` (Strong for their first or second, Weak for a style they dislike) | A pool of question stems (about 40) that name the bill's component | **Recommended.** Reuses data you already wrote, teaches the style system |
| C. Pure standing | Rapport is just your standing with the member's party | No content | Too passive |

### Who is eligible

| Rule | Draft |
|---|---|
| Party | Parties named by the template or by a lever: first Five Point Independents and Yezo Heritage Party |
| Member | A member of that party seated on the bill's **hearing committee** where one exists, otherwise any member. PeopleDraw leans toward members you have not met |
| Already with you | If the party's biggest bloc already matches your pick, the visit is not offered (nothing to win) |
| How many | One visit per target party per bill in a Flagship; a lever for more |

### The rule, in numbers

`won_over[party] = n` moves up to n seats from the party's biggest bloc to your pick **before** the influence swing, **ignoring the gate and Vote Resistance**. Seats cannot go below zero.

| Source | Reaches PT02 | Reaches PT04 | Needs gate |
|---|---|---|---|
| Influence swing | 2 | **0** | Yes |
| MP visit | 1 per member won (draft: 1 visit) | 1 per member won (draft: 1 visit) | **No** |

A Flagship starts 2 to 16 seats short of 51 after your own seat. Two visits cover 2 of them, so visits are a **supplement**, not a replacement for the gate. A lever for visits per party (default 1, up to 2) sets how big.

### Open questions for you

| # | Question | Recommendation |
|---|---|---|
| 1 | "+1 influence" = one seat, one gate point or a multiplier | One seat; it is honest (each member is a seat) and easy to show |
| 2 | Does a lost fight cost anything | Nothing but the stage; a small party favor loss (-1) is a lever |
| 3 | Is the visit optional | Yes: a Request-style choice before the level ("Take the visit?") |
| 4 | Do existing bill levels (the 50) get visits too | Later; patron Flagships first |

## Idea 2: the lobbyist's trade

### Flow

| Step | What happens |
|---|---|
| 1. The offer | A lobbyist whose organization the bill hurts proposes dropping a component. You pick **which** (never the last one) |
| 2. Negotiation | Three or four rounds, four answers each. Each answer moves a visible **leverage** meter (0 to 100) |
| 3. The package | Leverage is a budget. Spend it on rewards from a short menu; what you cannot afford stays on the table |
| 4. The change | The bill is recomposed without the dropped component: new name, tags, vote positions and effects. The patron's standing takes the cost |

### The leverage indicator

| Input | Effect (draft) |
|---|---|
| Starting leverage | Your standing with the lobbyist's organization (a quarter of it) |
| Which component you drop | The component that hurts their organization most is worth the most to them (more leverage); dropping a different one is worth less |
| Each round's answer | Strong +15, Medium +5, Weak -10, graded by the lobbyist's own styles |
| Bill strength | Fewer parties already leaning your way = you need them more = less leverage (a small modifier) |

The meter shows tier marks, so the player sees what each level buys before they commit.

### The reward menu (spend leverage)

| Reward | Cost (draft) | What it does |
|---|---|---|
| Office donation | 20 | Funds and XP, scaled by the organization's tier |
| Organization sentiment | 30 | The lobbyist's organization (and the ones tied to it by Standing Links) +standing |
| Party favor | 40 | The party best tied to the organization (Party Standing weights) +favor |
| Help work the bill | 50 | `bill_assist`: +1 seat won over for your pick, from the party best tied to the organization; or a one-point cut in every party's resistance for this vote (lever) |

The package cost against a typical 60 to 90 leverage means one or two choices, not all four. That is the negotiation.

### Costs and consistency

| Question | Rule |
|---|---|
| Patron anger | Dropping a component its patron owns costs that component's share of the patron's pass reward |
| Option A | Dropped components are **not** law, so they stay available for later bills |
| Cap and floor | The vote shaping still runs on the smaller bill, so dropping cannot make a patron bill pass alone |
| Amend | Amend still swaps one component; a trade drops one. They can combine; a bill never falls below one component |
| Name | A one-component bill needs a Text row like the two- and three-component ones |

### Open questions for you

| # | Question | Recommendation |
|---|---|---|
| 1 | Is leverage a budget or a tier ladder | A budget: the player decides |
| 2 | May the player refuse the lobbyist | Yes, no cost |
| 3 | Can any component be dropped | Any except the last; the patron's core costs the most standing |
| 4 | Is "help work the bill" a seat or a resistance cut | A seat, so it is visible and bounded |

## Shared plumbing

| Piece | Plan |
|---|---|
| `BillAssist` (pure) | The per-level record: `won_over` by party, an optional resistance relief, and the log of why. Saved in `GameState`, cleared when the level ends |
| `FloorVoteEngine` | New config `assist`; applied before the swing. The influence readout and the result preview include it ("Two members you won over lend 2 seats") |
| Level templates | Two new tokens: `MP_VISIT` (visit then fight) and `LOBBYIST_TRADE`; the exporter checks them; `LevelTemplate` maps them to stage families |
| Stage families | `MP_VISIT` = a visit screen (new, small) plus a one-on-one battle stage (copy of an existing family); `LOBBYIST_TRADE` = a negotiation screen (new) |
| Bot and tests | Playtest bot learns to take both; GUT proves the seat math and that no trade can make a bill pass alone |

## Build order if you approve

| Step | Work | Size |
|---|---|---|
| A | `BillAssist` + `FloorVoteEngine` support + vote screen readout; GUT proof | Small |
| B | MP visit: rapport rules, question stems (about 40), template token, one-on-one stage, screen | Medium |
| C | Lobbyist trade: `NegotiationEngine` (pure), recompose-without-component, screen, template token | Large |
| D | Playtest-bot support, balance trials with the Flagship floor, copy-edit pass on drafts | Small |

Both need patron step 4 (the Requests block and level start UI) to be reachable, so they follow it.
