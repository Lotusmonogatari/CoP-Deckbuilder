# Coliseum of Parliament — Game Design, As It Currently Stands

*A description of what the game does and how its systems connect, written for a reader rather than a build tool. **Refreshed 2026-10-29; updated 2026-10-31.** Counts: 70 cards, 131 opponents, 101 levels, 273 stages, 32 organizations, 53 backings, 6 real parties, 50 Floor Vote bills, 166 visitors, 55 events. Numbers marked "first draft" are Cameron's to retune. Where a system is designed but not yet doing anything, that is said at the point it comes up and gathered again at the end. For how to add content see `design/CONTENT_GUIDE.md`; for the day-to-day state see `design/NEW_CHAT_STARTUP.md`; for every dated change see `design/CHANGELOG.md`.*

## In one page

| Layer | What it is | Feeds |
|---|---|---|
| **The fight** | A turn-based card battle in a room (committee, floor, caucus, press, town hall, TV, lobbyist, study session), or a vote | A win or loss, and what the audience thought of your answers |
| **Standing** | What 32 organizations, 6 parties and your four meta numbers think of you | Backings, opening positions, whether bills can be carried, the vote itself |
| **Bills and votes** | 50 real bills in the Floor Vote, plus sponsored and self-drafted bills | Laws that change standing again |
| **The Office** | Rhetoric Training, staff, the Marketplace, backings, deck, appearance | Strength for the next level |
| **The week** | Hours, a work week and weekend, party dues, awareness, events | Pressure and opportunity between levels |

## The premise

You are a freshly elected legislator in Yezo, a fictional unicameral parliament of 101 seats (51 to a majority). You have no army and no natural allies, only the ability to argue. Every fight is a room full of people you are trying to win over or hold off: a committee, the whole floor, your own party's caucus, a press conference, a town hall, a television debate. Now and then it is not a fight at all but a vote you and 100 colleagues are about to cast, or a visit, a festival, a school or a harbor where people ask you hard questions with no right answer. You fight with a hand of *argument cards* (turns of phrase and rhetorical moves, each belonging to one of six *suits* of persuasion), and each room plays by its own version of the same rules.

Between fights you return to your Office, where the result of every fight becomes the ammunition for the next: reputation, money and experience, and the favor of organizations and parties you have earned or lost. The game is two loops wearing one skin, a card battle and a resource loop that decides how hard the next battle will be, and the design is about how tightly they feed each other.

## The core exchange: playing a hand

A battle is a race, measured in turns, to push a support number past a threshold before the clock runs out or you talk yourself into too many gaffes. A turn limit runs from 5 to 17 depending on the room.

Each turn you are shown what your opponent intends to do (attack, block, or rally support of their own, with a number attached) *before* you act, so every hand is played against a known threat. You then spend *energy* (refilled each turn, never carried over) playing cards from a hand of three to six, in any order, until you are out of energy or choose to stop.

Every card does some mix of four things: it **moves support** (yours up, theirs down, or both), it **banks guard** (a shield that carries between turns, absorbs the next hit aimed at you, capped at 5), it **costs or clears gaffes** (a mistake meter that ends the fight outright if it fills), and it **draws more cards**. A few cards ask you to discard others to play them. A card's stated numbers are adjusted first by its suit and the room (below) and, in a room that asks questions, by how well that suit answers the question on the table.

**Winning someone over costs more the more opposed they already are.** The game models an audience of individual people. Someone undecided comes over for a single point. Someone who already opposes you costs 1 point 60% of the time, 2 points 30% and 3 points 10%, rolled per person as your argument works through the room; support left over mid-conversion is lost. A big number on a card is an upper bound on how many people you might reach, spent from the hardest case first.

At the end of your turn whatever you did not play is discarded (except in a press conference, which cannot refresh your hand). A turn where you play nothing is a pass: it costs one energy at the start of your next turn, and in a press conference it also declines the question in front of you. Then your opponent's intent resolves: their attack is met by your banked guard first and only the excess lands; the same is true in reverse, since guard defends both ways.

## Suits and the room's own bias

Every card belongs to one of six suits: **Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous**. There are 70 cards, drawn in four tiers, with a mix of suits at every tier so no approach dominates by weight of numbers. What separates the suits is fit: **every battle room has its own affinity column** (a bill's room is a copy of its generic room and gets its own), multiplying a card's support numbers up or down (roughly 0.5x to 1.5x) by how well that suit plays there. House style is two suits up, two down, two neutral. A floor debate rewards different instincts than a press conference. Guard, draw and gaffe numbers are never touched, only the persuasion.

This is the first interdependence: **which cards you own decides which rooms you are naturally strong in**, and progression is built around giving you a wider spread of suits so fewer rooms catch you flat-footed.

## The shapes a room can take

- **Shared pool** (floor debates, caucuses, town halls, steering committees, media ambushes, lobbyist meetings, policy study sessions): one pool of support split three ways, you, your opponent, and everyone undecided. Winning someone pulls them from Undecided first, and from your opponent only once Undecided runs dry. Several opponents can follow one another in three ways: a **committee** resets everything for each opponent, a **town hall** carries the clock and gaffes but refills energy, and a **floor debate or caucus** carries everything.
- **Single** (press conferences): one tone meter and no opposing number. A reporter's question arrives each turn on the cue banner for the room's whole turn limit, and the last turn is played out in full before the tone is judged against the line.
- **Survival** (the TV debate): the same single meter, but you must be at or above the line at the end of every turn, and the line **rises** by a small random amount each turn (first-draft 0 to 3), up to a cap.
- **Vote** (National Assembly Floor Voting): not a fight; see below.
- **Non-combat** (Office Hours, the Party Steering Committee check-in, and the outings below): no cards, energy or bar. A visitor puts a **dilemma** to you with four answers and **no right one**; each answer moves different organizations, and you can never lose a visit.
- **Member visit and lobbyist trade**: two small rooms that belong to sponsored bills (below).

**Special rooms and hosts.** Ambushes (a surprise room, which can be lost without losing the level) and the Cabinet committee are tuned separately. A committee seats only its own members, the Special Committee any MP who is not a minister, the Cabinet ministers and chairs, and the party caucus only your own party.

## Levels

A **level** is an ordered chain of up to ten rooms, with its own tier, cooldown (in game hours), unlock price and rewards. The kinds in play:

| Kind | What it is |
|---|---|
| Ordinary levels (30) | Chains of generic rooms around a policy theme |
| **Bill levels (50)** | Built around one Floor Vote bill. **Every room is a bill-specific copy of its generic room** ("Town Hall on Ainu Heritage and Language"), with its own questions, cues, transitions, a visitor for that bill's Office Hours, and a final vote. Half are hidden until found (below) |
| Urgent matters (2) | A Constituency Town Hall and a Party Steering Committee check-in that appear when your numbers fall (below) |
| **Outings (13)** | One-room, weekend-ready levels: a quiet word with a lobbyist, weekend Office Hours, a press gaggle, a town hall, a study evening, a late TV interview, three festivals (local, autumn harvest, winter snow), a walkabout, a clinic day, a school visit, a farmers' market |
| Sponsored and drafted bills | Built during a run from an organization's request or from parts you pick (below); never in the ordinary list |
| **Event levels (4)** | One-room levels reached only from an event choice, never the list: a radio debate, a radio call-in hour, a campus Q&A with Students United, and the Fisheries Cooperative's meeting at the harbor. The choice opens the level's briefing; **Go in** takes the choice and starts the room, **Back** returns to the event with nothing taken |
| Seasonal levels | A level or event can be limited to seasons (the autumn harvest and winter snow festivals, a snowed-in road); out of season it does not appear |

What a room leaves behind changes the next: a level can carry a support bonus or goodwill into its next stage, and reputation earned before a press-style room nudges where it starts. Beats between rooms keep a level feeling like a place:

- **Level Intro.** Before a level's first room, hired staff speak a line about it, and for a bill level you choose your **lean** (support or oppose the bill; sponsored bills are automatically support). The player can also have a private thought about the level.
- **Transitions.** Before any room that is not first, a short exchange plays: one or two characters (a hired staff member or an opponent) speak, or the player thinks aloud, over a background.
- **Losing.** A lost room ends the level and sends you back, except in a press conference or media ambush, where the threshold only decides which reward table applies. A Floor Vote cannot be lost. The level briefing says what a loss costs before you go in.
- **One-time levels** disappear once cleared; **cooldowns** keep a level from being replayed at once; **Needs Discovery** levels stay hidden until an event choice reveals one or you host their organization (below).

## Who is in the room: questions, organizations and standing

Every room's audience is mixed from five kinds of people, Press, Party Members, Constituents, Boosters and Bureaucrats, which decides which backings are switched on for the fight. A press conference, media ambush, lobbyist meeting, town hall, policy study session, committee or bill-specific room draws a written question each turn, and the suit you answer with is graded:

- **Strong** boosts that card's numbers by 1.3x this round, pleases the organizations the question's theme belongs to, and sets back any the theme opposes.
- **Medium** changes nothing.
- **Weak** cuts that card to 0.7x and annoys the organizations a strong answer would have pleased.

The card-zoom tells you the grade before you play. A question may name who asks it (a party, or an organization), and a bill's own questions are dealt first in any room of that bill's level.

**32 organizations**, in Party, Constituency and National tiers (and two Party Bodies, the activists and the candidate selection committee, who belong to whichever party you are in), hold a **standing** with you. What they think of you does not evaporate at the end of the fight:

- Every please and annoy nets out per organization, per stage, and is capped either way. Gains are harder as standing rises, and an organization you leave alone drifts back toward where it started.
- **Standing links** let one organization's change move another's (a rival moves the other way), one hop only.
- Standing opens **backings** (53 of them): permanent or timed boosts such as a better start at every Town Hall, or +5 Party support when your influence turns a bill your party backs. Each backing needs its organization's standing high enough (45 to 60 or more, per backing) and a price in Funds, Reputation or constituency support.
- It also makes a bill carryable and feeds the vote.

This is the second interdependence: **who you please in one room can make a later, unrelated room easier**, through whichever organization was watching. Standing never explains itself in a fight, so the Details panel says who a question is about and the outcome panel shows each organization's change as a small icon.

**Parties.** Each of the six real parties has an opinion of you that blends a direct number (votes, rewards, your lean) with how the organizations tied to it feel about you. Your own party's blended opinion is what drives the crisis rules below and part of the vote.

## National Assembly Floor Voting

Not a battle: one choice against one real bill, drawn from 50. You cast **Aye, Nay or Abstain**, and the chamber's other 100 seats fall the way each of the six parties' own baked-in split leans. A bill passes only if **Yes reaches 51 of the 101, abstentions counting against it**, and some bills need a supermajority.

Your own seat sits wherever your party's majority sits, and voting otherwise moves exactly that one seat. Four things can move more:

- **Your party's own favor** shifts afterward, whether or not the bill passed, by which side of it each party stood on.
- **Whipping.** You can spend stored Party support to whip extra members of your own party to your pick (10 per extra vote, 3x that against your party's position, a flat 1 cheaper when at least one organization is in your corner, never under 5).
- **The influence swing.** A strong enough legislator can swing other parties' seats, gated behind hard thresholds (16 rows are enabled today: Reputation, several organization standings, some scoped to specific parties). The gate is an AND: every row must clear. Each party resists by its own resistance. The vote screen says whether you are ready and previews what each choice would do.
- **Members won over and lobbyists working against you** (from sponsored-bill levels below) add or remove seats outside the gate.

A flipped bill can show a cutscene line and carry a bonus. Every vote goes in the **statute book**, and each bill's **Law Effects** then change standing, meta numbers and Funds once or at the end of every later level. House rule: every organization is pleased by at least one outcome and annoyed by at least one.

## Sponsored and drafted bills

Organizations ask things of you, and you can ask things of the chamber:

- **Requests.** Once an organization's standing reaches a threshold, it brings a **Favor** (two of its own parts) or a **Flagship** (its two plus an ally's) request. You see the bill, its default vote, your party's position and the rewards, and may **carry it**, **amend** it (swap one part), or **decline** (at a cost). A level of its own is built for the bill; a patron bill cannot pass without your influence.
- **The patron visit.** A sponsored level opens with the organization's representative putting two dilemmas to you about the bill's parts.
- **Member visit.** An optional room for a Flagship: you meet a member of a party and, by answering in the styles they favor, can win a seat before the vote. A researcher on staff briefs you on the member's styles at the top rank.
- **Lobbyist trade.** An optional room where a hurt organization's representative offers help or refusal; you can drop a part of the bill to buy leverage. Refusing costs seats on a Flagship.
- **Draft a Bill.** You pick two or three parts from any organizations and carry your own bill through the same machinery.

## The four numbers, and what follows you

Your standing as a legislator is tracked in four meta numbers shown by name: **Constituency support**, **Reputation**, **Funds** and **Party support**, plus **XP**. Winning a level moves some mix of them according to that level's numbers; losing costs a separate set shown in the briefing. Reputation leans on a press-style fight before it starts.

**Awareness.** Two meters, **District** and **National**, rise when you win rooms, carry bills, or host and fall with gaffes. Seven data rows turn them into consequences: National 80 cuts party dues, District 80 earns a free Training Session Coupon each week, 65 starts press and town halls ahead, and low awareness costs the Selection Committee, XP, or National organizations. **Election strength** is built and shown on its own page (nine bars) but fires nothing yet.

**Crisis levels.** When Constituency support falls to 15 or below, a Town Hall appears under "Urgent Matters" after a countdown; when your party's opinion of you falls below 25, a Steering Committee check-in does. If you play an ordinary level while one waits, it is forced in right after. Party support at 0 freezes Funds income until it recovers, and above 75 gives a free backing. A lifetime tally of gaffes carries a one-time Constituency penalty.

## The week

The game has a calendar, kept in hours.

- **Hours.** A work week is five 8-hour days pooled into 40 hours; each room takes 1 to 4 hours (a committee or caucus 4, most single rooms 2). A stage that runs past a day spills into the next. On Friday you can end the work week early.
- **The weekend.** Optional, two 4-hour days; only levels marked weekend-ready that fit the hours left can start.
- **Going home.** "Pay Party Dues and Go Home" ends the week (or the choice when the work week is full) and starts the next Monday.
- **Party dues.** At each week's end the party takes a base of 50,000円, plus 50,000円 for every full 15 points of Party support above 40, plus 30% of the Funds you earned that week, less what National Awareness takes off. Unpaid dues roll over; a short week costs Party support, withdraws the party's backings, and costs standing, all scaled up by 1.5 for every full 100,000円 owed.
- **Decay and cooldowns** run on the calendar, so unused hours still pass time.
- **Events.** An event is a screen with two to four fixed choices, each with its own ranges. **Buyable** events (an advertisement, a rally weekend, a community grant, a radio spot, a festival float) are arranged from the Events list and paid up front; **Random** ones may arrive after a level or week end, only when you are known enough and off cooldown; **Dated** ones (the Prime Minister's opening address) open by themselves on a calendar date. Choices can spend or earn Funds and XP, move the meta numbers, awareness and organization standing, **reveal a hidden level**, or settle party dues. A Random event with a staff choice shows it greyed out if you have hired no one, and almost every Random event has a **Decline** that costs 1.5x what sending staff would have lost.
- **Durations.** An event shows how long it can take, from its quickest choice to its longest (a choice that leads into a level adds that level's hours); a choice that would not fit the hours left reads "Insufficient Work Hours".
- **Commitments.** A choice can cost what it promises: hours now (a visit, a call made in person), Funds now (commissioning a study), or an item handed over (a box of Aomori apples). It shows the cost and greys out when it cannot be paid. A choice can also **promise** an item or hours owed later: the Office's Promises panel lists what is owed and when, keeping a promise earns standing with the organization it was made to, and missing the deadline breaks it (standing and Reputation lost). A choice can schedule a **follow-up** that arrives as its own event later (the meeting you promised to convene, the ministry's reply). The Marketplace sells **regional goods** for such gifts: Aomori apples, Tsugaru lacquer chopsticks, dried scallops, wind-dried salmon, milk caramels, white chocolate cookies, a Nebuta festival hand towel and district sake.
- **Honest choices.** Every set of choices offers sincere positions of similar length, so the right answer is not given away by being the only thoughtful one.
- **Hosting.** A walking tour (Constituency organizations) and a dinner (National) are guest events with three screens of choices; hosting an organization reveals one of its hidden levels.
- **The Office ticker and notices** speak a line of news or flavor under conditions: staff, thresholds, a bill passed or failed, a weekday or date range, a story you made.

## The Office loop

Between levels the Office turns a level's rewards into the next level's capability:

- **Rhetoric Training.** XP or Funds buys a session at a card tier (0 to 3); it shows one random card you do not own, front and back, before you pay anything. **Learn it** pays and adds that card; **Pass** costs nothing and shows another, up to three looks, the last forced. This is the only way new cards enter your collection. A Training Session Coupon gives a free draw.
- **Staff.** Three roles, each with several hireable people. Their profile shows a full picture, name, cost, role, a biography, and what each rank gives; you hire, upgrade rank by rank, or fire (severance). Higher ranks need a recruitment-tier purchase. A hired person unlocks Level Intro lines, transition speakers, and the researcher's briefing, and makes some Marketplace items pay more.
- **The Marketplace.** Everything you own and can buy, with your Funds and its current limit at the top (the limit rises as you buy increases, up to a hard ceiling). Items are one-stage consumables, whole-level buffs, organization-standing actions and permanent unlocks; an item goes into your bag and does nothing until you press Use, from the Marketplace or mid-fight. A few let you choose which organization benefits.
- **Boosters.** The backings above, bought here.
- **The deck.** A fixed number of slots, so unlocking a card means leaving another out; each card has a **View** button showing its front and back.
- **Appearance and Music.** Decorative packages bought with Funds or XP: an outfit, an upgraded Office, a music theme, a calendar style (Japanese era names or Ainu), a dining room and a walking-tour picture. Each piece is equipped on its own slot. No gameplay effect.
- **Reputation and Results** holds Important Stakeholders (organizations), Parties, Boosters, Election Strength and **Your Record** (the lifetime tally and why each number last moved). **Administration** holds Save and Load (one automatic slot plus one manual backup), Appearance and Music, text size, New Game, and **How to Play**.

## Choosing who you are

A title screen offers **Continue** or **New Game**, with a choice of four protagonists, each with their own name, party (in the party's official colour), blurb, and **different starting numbers**, from an easy start (Constituency support 35, Reputation 25, Funds 100,000円, Party support 40, XP 60) down to a very hard one (5, 0, 10,000円, 0, 0). A new run starts with a 15-card deck dealt at random and each protagonist's own starting items (a Training Session Coupon for everyone, plus coffee and tea for the easier starts).

Progress is saved automatically after every stage, whenever the Office opens, and whenever anything is bought or changed, but never in the middle of a stage: reopening mid-fight restarts that fight.

## What it looks and sounds like

Every picture is found by ID with a fallback, so nothing blocks the game: a card without art shows a shared stand-in; a character with no drawn face for an expression uses a neutral or a plain `ID.png`; a stage's picture is its own, else its family room's. **Outside scenes** (festival, harbor, school, shrine, street, village road in snow, a coastal battery, farm) are generic pictures that events and outings can list in twos and threes, one chosen each time; a picture carrying a term such as *winter* or *snow* is only used when the room or event mentions it. Undrawn outside scenes show the Town Hall. The game is **silent**: every sound is wired to a name and none has a file yet.

## What is designed but not yet doing anything

- **Election strength** is built, shown and moves, but nothing fires from it.
- **Audio:** the sounds and settings plan exists (`design/proposals/AUDIO_PLAN_2026-10-26.md`); no files and no volume controls yet.
- **A real phone build** (iOS and Android) has not been done; layout has been checked only in desktop screenshots at several shapes and text sizes.
- **Art:** most opponent, visitor and card art, 97 topic-room backgrounds, and the outside scenes not yet drawn.
- **Cosmetic backgrounds** cover the Office, the dining room, the walking tour and the calendar, not every stage's own background.
- **Cameron's to define:** the real post titles Yezo's parties use, the theme-to-organization mapping behind questions (a draft), and all the "first draft" numbers named above (decay, dues, awareness, the TV line's rise, standing bands and more all live in the workbook's Balance tab).
- **Draft content:** most written lines (cues, questions, bills, components, law effects) are drafts for Cameron to rewrite.
