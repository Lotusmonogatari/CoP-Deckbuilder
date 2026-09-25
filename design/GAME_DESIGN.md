# Coliseum of Parliament — Game Design, As It Currently Stands

*A description of what the game does and how its systems connect, written
for a reader rather than a build tool. Numbers below reflect the current
checked-in data (54 cards, 125 opponents, 30 levels, 21 canon rooms, 16
organisations, 31 modifiers) and current behaviour, not the long-term
vision — where a system is designed but not yet switched on, that's said
plainly at the point it comes up, and gathered again at the end.*

## The premise

You are a freshly elected legislator in Yezo, a fictional unicameral
parliament of 101 seats (51 to a majority). You have no army, no budget of
your own worth mentioning yet, and no natural allies — only the ability to
argue. Every fight in the game is a room full of people you are trying to
win over or hold off: a committee, the whole floor, your own party's
caucus, a press conference, a town hall, a television debate. You fight
with a hand of *argument cards* — turns of phrase, gambits, and rhetorical
moves, each belonging to one of six *suits* of persuasion — and each room
plays by its own version of the same underlying rules.

Between fights you return to your Office, where the *result* of every
fight becomes the *ammunition* for the next one: reputation you can spend,
organisations whose backing you've earned, money, and experience. The game
is really two loops wearing one skin — a card battle, and a resource
loop that decides how hard the next battle will be — and the whole design
is about how tightly those two loops feed each other.

## The core exchange: playing a hand

A battle is a race, measured in turns (5 to 10 depending on the room), to
push a support number past a threshold before the clock runs out or you
talk yourself into too many gaffes.

Each turn you're shown what your opponent intends to do — attack, block,
or rally support of their own, with a number attached — *before* you act,
so every hand is played against a known threat rather than a guess. You
then spend *energy* (refilled each turn, never carried over) playing cards
from a hand of three to five, in any order, until you're out of energy or
choose to stop.

Every card does some mix of five things: it **moves support** (yours up,
theirs down, or both), it **banks guard** (a standing shield that carries
between turns and absorbs the next hit aimed at you, capped at 5), it
**costs or clears gaffes** (a mistake meter that ends the fight outright if
it fills), and it **draws more cards**. A card's stated numbers are
adjusted first by which suit it belongs to and which room you're in — see
Suits and rooms, below — before anything else happens.

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

## Suits, affinity, and the room's own bias

Every card belongs to one of six suits of persuasion — **Earnest,
Emotional, Appeal, Data Driven, Divisive, Duplicitous** — six equally-sized
families of nine cards each, so no single approach dominates by weight of
numbers alone. What separates them is fit: each of the 21 kinds of room in
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

## Five shapes a room can take

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
  Reporters' questions stand in for the opponent's own intent, and here
  the cards you play do double duty: whichever suit you answer with is
  *also* graded against the question actually being asked (see Segments
  and boosters, below).
- **Survival** (the TV debate): the same single meter, but you don't win
  by crossing the threshold once — you have to be *at or above it at the
  end of every single turn*, so a strong opening doesn't forgive a bad
  middle turn.
- **Committee** (11 different named committees, from Ethics to Finance to
  the Cabinet): instead of one number, a roster of individual members,
  each with their own private lean from 0 (locked against you) to 100
  (locked for you), starting undecided at 50 unless the data says
  otherwise. Every card targets one member; a member locks in for good
  once their lean clears 66 or falls under 33. You win the moment a
  majority — half the roster plus one — is locked in your favour, and lose
  the moment a majority is no longer mathematically possible. The
  committee's chair has no vote and no move of their own; a committee is
  decided entirely by what you do to the room.
- **Non-combat** (Office Hours): no cards, no energy, no bar at all — a
  visitor asks you one multiple-choice question, you pick an answer, and
  the *right* answer pays out (usually raising an organisation's opinion
  of you) while the *wrong* one costs you something similar. There is no
  way to lose an Office Hours visit; every visitor is eventually gotten
  through, for better or worse.

A **level** is simply an ordered chain of these rooms — the game currently
ships 30 of them — usually built around getting one piece of legislation
through, and what one room leaves behind can genuinely change how the next
one plays: a level can carry a support bonus or an organisation's newly
earned goodwill forward into its very next stage, and reputation earned in
an earlier press-shaped room nudges where a later one starts. Losing any
single stage of a level ends the level there and sends you back to the
Office; finishing every stage carries you through to the level's own
reward.

## Segments and boosters: who's actually in the room

Every room has an audience made of five kinds of people — Press, Party
Members, Constituents, Donors, Bureaucrats — mixed in different
proportions depending on the room, and that mix quietly decides which of
the game's 31 modifiers are switched on for this particular fight (a
modifier fires only once its trigger segment makes up enough of the
audience). A press conference full of reporters behaves differently, mechanically as well as thematically, from a
caucus full of your own party.

Sixteen **organisations** — Party Headquarters, the Chamber of Commerce,
local Kōenkai associations, Labor, and so on, split into Party,
Constituency and National tiers — sit behind those modifiers as the thing
actually being pleased or annoyed. Playing a strong answer to a themed
question (in a press conference, media ambush, lobbyist meeting, town
hall, or policy study session) pleases whichever organisation asked it;
a weak answer costs you tone in the room instead. What those
organisations think of you doesn't evaporate at the end of the fight — it
becomes your **standing** with them, held between levels, and modifiers
tied to strong standing quietly start giving you a better opening position
in later fights (a caucus that starts ahead, a press conference that opens
warmer). This is the second big point of interdependence: **who you please
in one room can make a later, unrelated room easier**, entirely through
which organisation happens to be watching.

## The four numbers that follow you everywhere

Outside any single fight, your standing as a legislator is tracked in four
meta-variables, shown on screen by name because they're also how the game
itself reaches for them: **Constituency support**, **Reputation**,
**Funds**, and **Party support**. Winning a level moves some mix of these
(and awards XP) according to that level's own numbers; losing costs you a
smaller, separate set of penalties. Reputation in particular leans on a
fight before it's even fought — entering a press-shaped room with strong
reputation nudges its opening number in your favour by a fixed amount at
set thresholds, and weak reputation nudges it the other way.

These four numbers are also meant to be the game's early-warning system —
low Constituency support is supposed to force a Town Hall into your
schedule whether you wanted one or not, a Funds level of exactly zero is
supposed to freeze your income until it recovers, and Party support
crossing 75 or falling under 50 is supposed to switch a standing
organisational modifier on or off automatically. **These four consequences
are written into the data and tested, but nothing in the level flow
triggers them yet** — today they're numbers you watch and manage by
choice, not by mechanical force. It's an honest gap worth knowing rather
than a secret one.

## Turning results into strength: the Office loop

Between levels, the Office is where a level's rewards become next level's
capability, through three parallel systems:

- **Cards.** XP earned from wins unlocks new cards at a cost set by their
  tier (0 through 3), and upgrades an owned card further. This is the
  slow, deliberate way you broaden which suits you're strong in — today,
  every card is actually available to try in the deck screen regardless of
  XP, so this gate is open for playtesting rather than closed as final
  balance.
- **Staff.** Three roles — Policy Research Assistant, Media Spokesperson,
  District Representative — seven hireable candidates deep each, cost
  Funds to hire and can be upgraded a tier at a time. A handful of Shop
  items (commissioning policy research, press engagement, district
  engagement) pay out more once the matching staff role is hired at a high
  enough tier — hiring the right staff makes an existing Office action
  quietly better rather than unlocking something new outright.
- **Supplies and the inventory.** 29 purchasable items, bought with Funds
  and/or XP, ranging from one-stage consumables (a coffee for +1 energy,
  paperwork automation for +1 card drawn) through whole-level buffs, to
  organisation-standing actions and permanent unlocks (a funds cap
  increase, a new level tier, a random card). An item goes into your bag
  when bought and does nothing until you actually press Use — from the
  Office (queued for your next stage or level) or mid-fight (immediate,
  for the rest of that fight). A few items let you pick which organisation
  benefits rather than rolling one at random from its tier.

An Office Hours visit (see above) is really this same loop wearing a
different face — instead of Funds buying an item, a right answer buys
organisational goodwill directly, on the spot.

## Choosing who you are

Before any of this starts, a title screen offers **Continue**, which reads
your one save slot back in, or **New Game**, which hands you a choice of
four protagonists — each with their own name, party (or lack of one), and
short blurb — and, on the same screen, exactly what standing and XP you'd
start with as them. Today all four start identically; the screen already
shows the numbers so that giving one of them a real head start, later, is
a data change rather than a new system.

Progress is saved automatically after every stage, whenever the Office
opens, and whenever anything is bought or changed there — but never in the
middle of a stage itself, so reopening the game mid-fight always restarts
that one fight fresh rather than resuming it half-played.

## What's designed but not yet load-bearing

For a complete, honest picture: four of the meta-variable consequences
above (the Town Hall trigger, the funding freeze, and both Party-support
modifiers) exist as written, tested rules with nothing in the level flow
calling them yet, and six of the sixteen organisations' modifiers sit
inert for the same reason. A Steering Committee trigger is specified but
still needs its own room built. Card unlocks are gated by data but left
open for playtesting rather than enforced. None of this changes how the
game plays today — it's simply where the next layer of pressure is already
wired and waiting.
