# Coliseum of Parliament — Game Design, As It Currently Stands

*A description of what the game does and how its systems connect, written
for a reader rather than a build tool. Numbers below reflect the current
checked-in data (54 cards, 125 opponents, 60 levels, 23 canon rooms, 18
organisations, 32 modifiers, 6 real parties, 30 Floor Vote bills, 2
cosmetic packages) and current behaviour, not the long-term vision — where
a system is designed but not yet switched on, that's said plainly at the
point it comes up, and gathered again at the end.*

## The premise

You are a freshly elected legislator in Yezo, a fictional unicameral
parliament of 101 seats (51 to a majority). You have no army, no budget of
your own worth mentioning yet, and no natural allies — only the ability to
argue. Every fight in the game is a room full of people you are trying to
win over or hold off: a committee, the whole floor, your own party's
caucus, a press conference, a town hall, a television debate — or, once in
a while, not a fight at all, but a vote you and 100 colleagues are about to
cast. You fight with a hand of *argument cards* — turns of phrase,
gambits, and rhetorical moves, each belonging to one of six *suits* of
persuasion — and each room plays by its own version of the same underlying
rules.

Between fights you return to your Office, where the *result* of every
fight becomes the *ammunition* for the next one: reputation you can spend,
organisations and parties whose favour you've earned or lost, money, and
experience. The game is really two loops wearing one skin — a card battle,
and a resource loop that decides how hard the next battle will be — and
the whole design is about how tightly those two loops feed each other.

## The core exchange: playing a hand

A battle is a race, measured in turns (5 to 10 depending on the room), to
push a support number past a threshold before the clock runs out or you
talk yourself into too many gaffes.

Each turn you're shown what your opponent intends to do — attack, block,
or rally support of their own, with a number attached — *before* you act,
so every hand is played against a known threat rather than a guess. You
then spend *energy* (refilled each turn, never carried over) playing cards
from a hand of three to six, in any order, until you're out of energy or
choose to stop.

Every card does some mix of five things: it **moves support** (yours up,
theirs down, or both), it **banks guard** (a standing shield that carries
between turns and absorbs the next hit aimed at you, capped at 5), it
**costs or clears gaffes** (a mistake meter that ends the fight outright if
it fills), and it **draws more cards**. A card's stated numbers are
adjusted first by which suit it belongs to and which room you're in — see
Suits and rooms, below — and, in a room that's actually asking you a
question, by how well that suit answers the question on the table.

**Winning someone over costs more the more opposed they already are.**
Support isn't simply added and subtracted; the game models an audience of
individual people. Someone currently undecided comes over to you for a
single point of support. Someone who already opposes you costs more — most
often 1 point, sometimes 2, occasionally 3, rolled per person as your
argument works through the room — and if your card runs out of support
mid-conversion, whatever's left over is simply lost rather than carried to
the next person. A big, flashy number on a card is not the same thing as
winning that many people; it's an upper bound on how many you might reach,
spent from the hardest case first.

At the end of your turn, whatever you didn't play is discarded (except in
a press conference, where you can't simply refresh your hand — declining
to answer the question in front of you has its own cost, described below).
A turn where you play nothing at all is a pass: it costs you one energy at
the start of your next turn, a small, permanent tax on hesitation. Then
your opponent's intent resolves — their attack is met by your banked guard
first, and only the excess actually lands; the same is true in reverse for
your own attacks against them, since guard defends both directions.

## Suits and the room's own bias

Every card belongs to one of six suits of persuasion — **Earnest,
Emotional, Appeal, Data Driven, Divisive, Duplicitous** — six equally-sized
families of nine cards each, so no single approach dominates by weight of
numbers alone. What separates them is fit: each of the 23 kinds of room in
the game has its own affinity table, multiplying a card's support numbers
up or down (roughly 0.7× to 1.3×) by how well that suit plays in that
room. A floor debate rewards different instincts than a press conference;
the same card in your hand is meaningfully stronger in one room and weaker
in another. Guard, draw, and gaffe numbers are never touched by this — only
the persuasion itself is.

This is the first real point of interdependence: **which cards you own and
have upgraded decides which rooms you're naturally strong in**, and the
game's progression (below) is built around gradually giving you a wider
spread of suits so fewer rooms catch you flat-footed.

## Six shapes a room can take

Every stage in the game is one of a handful of underlying shapes, and
knowing the shape tells you how to read the number on screen:

- **Shared pool** (floor debates, caucuses, town halls, steering
  committees, media ambushes, lobbyist meetings, policy study sessions): one pool of
  support is split three ways — you, your opponent, and everyone still
  undecided. Winning someone over pulls them from Undecided first, and
  only from your opponent once Undecided runs dry; support your opponent
  loses returns to Undecided rather than vanishing.
- **Single** (press conferences): one tone meter, no opposing number at
  all — you're not fighting a person so much as a mood in the room.
  Reporters' questions stand in for the opponent's own intent, one asked
  per turn for the room's whole turn limit ("Question 2 of 5"), and here
  the cards you play do double duty — see Questions, organisations, and
  standing, below.
- **Survival** (the TV debate): the same single meter, but you don't win
  by crossing the threshold once — you have to be *at or above it at the
  end of every single turn*, so a strong opening doesn't forgive a bad
  middle turn.
- **Committee sequence** (11 different named committees, from Ethics to
  Finance to the Cabinet): an ordinary shared-pool fight, fought against
  several opponents from the committee's own roster **one after another**
  rather than all at once. Beating one member resets support, guard,
  gaffes, energy and the clock and puts the next one in front of you — a
  fresh argument each time, not a single running tally. You win by getting
  through everyone the room draws; you lose the moment any one bout's
  gaffe limit or turn limit runs out against you.
- **Vote** (National Assembly Floor Voting): not a fight at all — you cast
  one vote, Yes/No/Abstain, on a real bill, and watch where all 101 seats
  land. See National Assembly Floor Voting, below, for the whole shape.
- **Non-combat** (Office Hours, and the Party Steering Committee check-in
  that mirrors it): no cards, no energy, no bar at all — a visitor asks
  you one multiple-choice question, you pick an answer, and the *right*
  answer pays out (usually raising an organisation's opinion of you) while
  the *wrong* one costs you something similar. There is no way to lose an
  Office Hours visit; every visitor is eventually gotten through, for
  better or worse.

A **level** is simply an ordered chain of these rooms — the game currently
ships 60 of them — usually built around getting one piece of legislation
through (or, for 30 of them, around one specific Floor Vote bill), and
what one room leaves behind can genuinely change how the next one plays: a
level can carry a support bonus or an organisation's newly earned goodwill
forward into its very next stage, and reputation earned in an earlier
press-shaped room nudges where a later one starts. A hired staff member
with something to say about the level ahead gets one beat to say it,
before the level's first stage, on the Level Intro screen — most levels
have nothing written for them yet, and skip straight to the action.
Losing any single stage of a level ends the level there and sends you back
to the Office (a Floor Vote can't be lost, so it never ends a level this
way); finishing every stage carries you through to the level's own reward.
A level can also be marked **one-time** — once cleared, win or loss, it
disappears from the Office's level list rather than staying available to
replay, which is how the 30 real Floor Vote levels are set up: each bill
is voted once.

## Questions, organisations, and standing: who's actually in the room

Every room has an audience made of five kinds of people — Press, Party
Members, Constituents, Donors, Bureaucrats — mixed in different
proportions depending on the room, and that mix quietly decides which of
the game's 32 modifiers are switched on for this particular fight (a
modifier fires only once its trigger segment makes up enough of the
audience). A press conference full of reporters behaves differently, mechanically as well as thematically, from a
caucus full of your own party.

Eighteen **organisations** — Party Headquarters, the Chamber of Commerce,
local Kōenkai associations, Labor, and so on, split into Party,
Constituency and National tiers — sit behind those modifiers as the thing
actually being pleased or annoyed. A press conference, media ambush,
lobbyist meeting, town hall, or policy study session draws a real written
question each turn, and whichever suit you answer with is graded Strong,
Medium, or Weak against it:

- **Strong** boosts that card's own numbers by 1.3× this round, on top of
  whatever the room's own affinity already gave it, and pleases the
  organisation the question belongs to.
- **Medium** changes nothing either way.
- **Weak** cuts that card's numbers to 0.7× this round, and annoys the
  same organisation a strong answer would have pleased — there's no tone
  cost any more for a weak answer, only a worse-performing card and a
  cooler relationship. The card-zoom view tells you which grade you're
  looking at before you play the card, so this is never a guess.

What organisations think of you doesn't evaporate at the end of the
fight — every please or annoy nets out per organisation, once per stage
(capped either way so one very lopsided stage can't move a standing too
far), and becomes your **standing** with them, held between levels.
Modifiers tied to strong standing quietly start giving you a better
opening position in later fights (a caucus that starts ahead, a press
conference that opens warmer). This is the second big point of
interdependence: **who you please or annoy in one room can make a later,
unrelated room easier or harder**, entirely through which organisation
happens to be watching.

## National Assembly Floor Voting

A different kind of stage: not a battle, a single choice against one real
bill, drawn from a slate of 30. You cast **Vote Yes**, **Vote No**, or
**Vote Abstain**, and the chamber's other 100 seats fall the way each of
the six real parties' own baked-in split already leans — your own seat is
assumed to sit wherever your own party's majority already sits, and
voting anything else moves exactly that one seat out of that assumed
bucket and into whichever you actually picked.

Every party's own standing with you shifts afterward regardless of how
the vote went, purely by which side of the bill it was on — your own
party's share lands directly on your Party support number; the other five
parties' opinions are tracked the same way organisation standing is.

A strong enough legislator can go further: an **influence swing**, gated
behind a hard set of thresholds (several meta-numbers or organisation
standings must each clear their own bar, not just average out to one) that
Cameron can add to or remove from freely. Clear the gate and every party
whose own assumed majority doesn't match your pick gives up some of its
seats toward it, deterministically and capped by that party's own
resistance to being swung. When that swing is big enough to flip the
bill's own pass/fail outcome, a short cutscene line can mark the moment,
and a bill can carry its own bonus for a flip that specifically favoured
it. The gate ships off today — no trigger rows are switched on yet — so
every real Floor Vote plays out on the single-seat model above until
Cameron turns it on.

## The four numbers that follow you everywhere

Outside any single fight, your standing as a legislator is tracked in four
meta-variables, shown on screen by name because they're also how the game
itself reaches for them: **Constituency support**, **Reputation**,
**Funds**, and **Party support**. Winning a level moves some mix of these
(and awards XP) according to that level's own numbers; losing costs you a
smaller, separate set of penalties, shown up front in the level briefing
so a loss is never a silent one. Reputation in particular leans on a fight
before it's even fought — entering a press-shaped room with strong
reputation nudges its opening number in your favour by a fixed amount at
set thresholds, and weak reputation nudges it the other way.

These four numbers are also the game's early-warning system, and every one
of the four triggers below is live: Constituency support at or below 15
inserts a Town Hall into your schedule whether you wanted one or not; Party
support at exactly 0 freezes your Funds income until it recovers; Party
support above 75 switches on a standing modifier that gives you a free
edge everywhere; Party support below 50 switches on a different one, and
below 25 additionally inserts a short Party Steering Committee check-in
before your next level. Each fires once on the way into its threshold and
stays quiet, even while the condition holds, until you've come back out —
so a Town Hall lost while Constituency support is still low doesn't
immediately queue a second one — and you're told about either edge,
entering or leaving, the next time you're in the Office. A separate,
lifetime tally of your own gaffes also carries a one-time Constituency
support penalty once you've racked up enough of them across the whole run.

## Turning results into strength: the Office loop

Between levels, the Office is where a level's rewards become next level's
capability, through four parallel systems:

- **Cards, via Rhetoric Training.** XP or Funds buys a session at a card
  tier (0 through 3) in Office Management; a session shows you one random
  card you don't yet own from that tier, front and back, before you pay
  anything. **Learn it** pays and adds that exact card to your collection;
  **Pass** costs nothing and shows you another, up to a few looks, with
  the very last one forced — a session always ends in a learned card, so
  passing can't stall forever. This is the only way new cards enter your
  collection today; XP genuinely gates which tiers you can afford, and
  which levels are open to you at all.
- **Staff.** Three roles — Policy Research Assistant, Media Spokesperson,
  District Representative — several hireable candidates deep each, cost
  Funds to hire and can be upgraded a tier at a time, with higher tiers of
  candidate needing a recruitment-tier purchase to unlock. A handful of
  Shop items (commissioning policy research, press engagement, district
  engagement) pay out more once the matching staff role is hired at a high
  enough tier — hiring the right staff makes an existing Office action
  quietly better rather than unlocking something new outright.
- **The Marketplace.** Everything you own, and everything you can buy,
  in one screen: purchasable items — one-stage consumables (a coffee for
  +1 energy, paperwork automation for +1 card drawn, each capped at a
  handful in your bag at once) through whole-level buffs, to
  organisation-standing actions and permanent unlocks (a funds cap
  increase, a new level tier, a random level) — bought with Funds and/or
  XP. An item goes into your bag when bought and does nothing until you
  actually press Use — from the Marketplace (queued for your next stage
  or level) or mid-fight (immediate, for the rest of that fight). A few
  items let you pick which organisation benefits rather than rolling one
  at random from its tier.
- **Appearance and Music.** Purely decorative packages, bought once with
  Funds and/or XP: an outfit for your own protagonist, an upgraded Office
  background, and/or a music theme for the Office and battle alike. A
  package is what you buy; each of its pieces (outfit, background, music)
  is equipped independently, so owning several packages lets you mix a
  look from one with the music from another. No gameplay effect at all —
  purely how the game looks and sounds to you.

An Office Hours visit (see above) is really the Marketplace's own loop
wearing a different face — instead of Funds buying an item, a right
answer buys organisational goodwill directly, on the spot.

"Your Record", a separate page beside Important Stakeholders, keeps the
running lifetime tally none of the above shows on its own: your four
meta-numbers at a glance, every bill an influence swing has ever flipped,
and how many times each level (and each level tier) has been cleared.

## Choosing who you are

Before any of this starts, a title screen offers **Continue**, which reads
your one save slot back in, or **New Game**, which hands you a choice of
four protagonists — each with their own name, party (shown in that
party's own official colour) or lack of one, and short blurb — and, on the
same screen, exactly what standing and XP you'd start with as them. Today
all four start identically; the screen already shows the numbers so that
giving one of them a real head start, later, is a data change rather than
a new system.

Progress is saved automatically after every stage, whenever the Office
opens, and whenever anything is bought or changed there — but never in the
middle of a stage itself, so reopening the game mid-fight always restarts
that one fight fresh rather than resuming it half-played.

## What's designed but not yet load-bearing

For a complete, honest picture: the Floor Vote influence swing (above)
is real, tested code sitting behind a gate with nothing switched on yet —
every real Floor Vote plays the plain single-seat version until Cameron
turns on at least one trigger row. M10 (Cold Shoulder), one of the two
Party-support modifiers, is live but its own effect (a discount on
unlocks) has nothing in the game that spends it yet. Cosmetic
backgrounds only cover the Office today, on purpose — extending them to
every stage's own background is a small, deliberate follow-up, not a
gap. Which real-world post titles Yezo's parties use, and the theme →
organisation mapping behind press/lobbyist/town-hall questions, are both
still drafts waiting on Cameron's own political knowledge rather than
code gaps. None of this changes how the game plays today — it's simply
where the next layer of content or pressure is already wired and
waiting.
