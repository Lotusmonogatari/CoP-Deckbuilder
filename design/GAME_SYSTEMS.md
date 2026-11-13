# Coliseum of Parliament — How the Game Works

*The mechanics reference: what the player holds, how each thing grows and declines, where the player chooses, and every piece of state the run keeps. Written 2026-11-06 from the code and data as they stand (not from the old change log). Numbers are the **Standard** Campaign Pressure values in `data/balance.json`, `data/rules.json` and the other data files; they are Cameron's to retune in the workbook, so when a number here disagrees with the data, the data wins. For the story of the game see `design/GAME_DESIGN.md`; for how the code is organised see `design/ARCHITECTURE.md`; for how the player must be told things see `design/INFORMATION_STANDARDS.md`.*

## 1. Names: what the code calls things and what the player reads

The player never sees internal names. Documents and code use these pairs:

| Player reads | Code and data say | Notes |
|---|---|---|
| Constituency support | `Constituency support` (romaji *Jiban*) | Meta number. Some older code and docs still say Jiban. |
| Reputation | `Reputation` (*Kanban*, *Chimeido*) | Meta number |
| Funds (shown with 円) | `Funds` (*Kaban*, *Yen*) | Meta number |
| Party support | `Party support` | Meta number |
| Organization | booster (`BOxx`), "organization" in the workbook | 32 of them: Party 4, Constituency 13, National 15 |
| Backing | modifier (`Mxx`) | A purchasable boost an organization offers once its standing is high enough |
| Legislative Work | the statute book (`StatuteBook.gd`, `statute_book`) | Every bill voted on and what it did |
| Aye / Nay / Abstain | Yes / No / Abstain (engine) | |
| Level | module in old docs | An ordered chain of stages |
| Stage / room | `STxx` | One screen's worth of play |
| Hours | game calendar hours (`calendar`), and the hidden clock `time_units` | See section 3 |
| Training Session | Rhetoric Training, `card_tier` shop items | The only way new cards arrive |
| Campaign Pressure | `difficulty`: relaxed / standard / harder | Chosen at New Game |

**Four names are lookup keys as well as text** (`Constituency support`, `Reputation`, `Funds`, `Party support`): renaming one in the workbook alone is an export error.

## 2. The player's journey

```
Title screen ── Continue (loads the save)  or  New Game (protagonist + Campaign Pressure)
      │
      ▼
The Office  ◄───────────────────────────────────────────────────────────────┐
  Reports what changed, then offers (any order):                              │
  • Levels  → pick a level → Briefing → Go in                                 │
  • Events (arranged ones are paid for; random and dated ones arrive)         │
  • Marketplace, Rhetoric Training, Staff, Boosters (backings), Deck, Appearance
  • Requests and Draft a Bill (sponsored and own bills)                       │
  • Promises (keep what you owe), Reputation and Results, How to Play, Administration
  • Weekly choice: end the work week early / weekend / pay dues and go home   │
      │                                                                       │
      ▼                                                                       │
Level Intro (only if there is something to say)                               │
  purpose line → hired staff lines → bill card, "Read the Bill", lean choice  │
      │                                                                       │
      ▼                                                                       │
Stages, one after another; between two of them an optional Transition         │
  Combat room (cards) · Office Hours / check-in (dilemmas) · Floor Vote       │
  Member Visit · Lobbyist Trade                                               │
  After each stage: a result panel shows what moved and why                   │
      │                                                                       │
      ▼                                                                       │
Level ends (win, or a loss that ends it) → rewards, laws, triggers → back ────┘
```

**Save points:** after every stage, whenever the Office opens, whenever something is bought or changed there, and **on every button press** (outside a stage, and only once a run exists; `SaveManager._on_node_added`); when the app is backgrounded outside a stage; one automatic slot (`user://savegame.json`) plus one manual backup. A stage in progress is saved only at an opponent's defeat, and at the moment its result is shown (`pending_stage_result`): reopening the game on a result screen counts that result, a loss included, instead of replaying the stage.

**Ending a run:** there is no final win screen. A run is the campaign; the player stops when they like. (Election strength builds toward a campaign but fires nothing yet.)

**Choosing who you are (New Game).** Four protagonists, each with their own party and **different starting numbers** and items; plus **Campaign Pressure**, which can be raised during a run but never lowered.

| | Constituency support | Reputation | Funds | Party support | XP | Starting items |
|---|---|---|---|---|---|---|
| PC01 Kenshin Sako (Frontier Party) | 35 | 25 | 100,000円 | 40 | 60 | Training Session Coupon, 2 Kaiju Sized coffees, 2 Kaiju Sized teas, Wakkanai Milk Caramels |
| PC02 Haru Yashi (Frontier Party) | 20 | 15 | 50,000円 | 10 | 30 | Training Session Coupon, a Kaiju Sized coffee and tea, Haskap Yoitomake |
| PC03 Arata Ran (Keizaijiyuutou) | 10 | 5 | 25,000円 | 15 | 0 | Training Session Coupon, 2 coffees, a Bottle of District Sake |
| PC04 Jyurou Nishihara (Country Initiative) | 5 | 0 | 10,000円 | 0 | 0 | Training Session Coupon, a Box of Aomori Apples |

Every run also starts with a **15-card opening deck dealt at random** from a recipe on the Balance tab (mostly tier-0 to tier-2 cards, a 25% chance of one tier-3 card, suits within one card of even, at most half the deck gaffe cards).

## 3. Time

Two clocks run side by side. The player sees only the first.

| | Calendar (`calendar`) | Hidden clock (`time_units`) |
|---|---|---|
| Shown? | Yes: date, weekday, hours left | Never |
| Unit | Hours. A work week is five 8-hour days pooled as **40 hours**; the optional weekend is two 4-hour days (**8 hours**). The run starts Monday 1 October 2018. | One unit per hour passed |
| Spent by | A stage finishing (its `Time Units` in the Stages tab, 1 to 4), an event or visit that costs hours, a promise of hours being kept | The same, **plus** hours that went unused when a week or weekend ended |
| Caps | Hours past the end of a pool are lost: the week does not carry over | Never caps |
| Decides | Whether a level or event can start, and the date | Cooldowns, backing and buff durations, promise deadlines, when a special level appears, news stories, when decay runs |

**Rules about hours**

- A level may start on a weekday only if it **ends within the hours left in the work week**; otherwise its button says "Too long for the hours left". The longest level is 35 hours, so a level always fits on a Monday. Sponsored and drafted bills follow the same rule.
- A level can run past Friday only through hours added after it starts (a crisis stage inserted mid-level, a visitor choice that costs hours). Those spill away.
- At the weekend only levels marked weekend-ready, short enough for the hours left, can start.
- On the last weekday the player may end the work week early. When the work week is full, a pop-up offers the weekend or going home; the weekly button stays available if it is missed.
- **Going home** ("Pay Party Dues and Go Home") ends the week: dues are settled, week-end awareness effects run, election strength moves, the calendar advances to the next Monday, decay runs once (section 6), a random event may be rolled for the next Office visit.
- **Promise deadlines pause while a level is played** (you cannot reach the Office mid-level) and resume when it ends or is abandoned, moved on by the level's hours.

## 4. What the player holds: resources and standing

### 4.1 The five numbers

| Number | Range | Starts at | Goes up by | Goes down by | Spent on / gates |
|---|---|---|---|---|---|
| **Constituency support** | 0–100 | Per protagonist (5–35) | Stage and level wins; events; backings that add on a win | Stage losses; gaffe lifetime penalty (−15, once, at 50 lifetime gaffes); some events; **week-end decay (10% of the distance back to the protagonist's start, × the decay multiplier)** | Backings (some cost it). **At 15 or below a Town Hall is forced in.** Counts toward election strength |
| **Reputation** | 0–100 | Per protagonist (0–25) | Wins; events; kept promises (for the organization) | Losses; broken promises (−2); **week-end decay (6%)** | Backings (some cost it). **At 80 or more a press-style room starts you 5 ahead; at 20 or less, 5 behind.** Gates some influence swings |
| **Funds** | 0 to a **cap** | Per protagonist (10,000–100,000円) | Wins, events, laws, donations | Purchases, dues, drafting a bill (300,000円), commissioned items | Everything bought for yen. **Cap: 100,000円 to start; each Fund Limit Increase Petition adds 100,000; the hard ceiling is 1,000,000.** At Party support 0, **income from stages and levels freezes** (events, visitors and laws still pay) |
| **Party support** | 0–100 | Per protagonist (0–40) | Wins; laws; events; floor-vote favorability | Losses; overdue dues; going against your party on a vote; **spent by whipping** | **Above 75 a free backing (M09) switches on. Below 25 a Steering Committee check-in is forced in. At 0 the funding freeze starts.** Raises dues. Whipping spends it down to a floor of 30 |
| **XP** | 0 up | Per protagonist (0–60) | Stage and level wins, laws, some events | Rhetoric Training, level unlocks, staff, backings, shop items; −50 at the week end if District awareness ≤ 13 | Everything bought in XP. Lifetime XP earned (`xp_earned_total`) never falls and feeds election strength |

The Sanban tab's "low/high threshold consequence" notes (for example "LV10 cannot be activated") are descriptive text only; no code enforces them. Winning pays a stage's own `Win Δ` columns; losing charges its `Loss Δ` columns (shown in the level briefing). Level wins add the level's own bonus ranges (rolled each win) and per-organization deltas. Campaign Pressure scales Funds and XP payouts (Relaxed 115%, Harder 85%).

### 4.2 Standing with people

| Stock | Who | Range | How it moves | How it fades |
|---|---|---|---|---|
| **Organization standing** | 32 organizations, by `BOxx` | 0–100; most start 20–50 (each organization's own *Starting Standing*; blank = 30) | **Every answer counts** in rooms that ask questions: a strong answer pleases the organizations behind the question (+5), a weak answer annoys them (−3), a strong answer on an opposed theme sets back the opposed organization (−3); per stage the net is capped at ±10 per organization. Gains shrink as standing rises (× 1.0 below 40, × 0.6 below 60, × 0.4 above); penalties grow (× 1.0 below 60, × 1.5 above). Also: visitor answers, laws, votes and stances, kept promises (+2), broken promises (−5), hosted events, items, patron results; arguing an opponent's support to zero costs their organization 2; **Standing Links** make one organization follow or oppose another (one hop) | **Neglect:** an organization nobody moved this week drifts 1 point toward its start at the week end; every organization also settles toward its start by its own Decay Percent (default 5%) at the week end; both × the decay multiplier (2.5 at Standard) |
| **Party standing / opinion** | The 6 real parties | Own party's lives in Party support; the other five in `party_standing` | A blend of a *direct* number (votes, rewards, your lean) and the average standing of the organizations tied to that party; scaled by how much the bill matters to the party (salience, 0.5×–2×). Whether a party is Hostile / Cold / Neutral / Warm (bands at 20, 40, 60, 80) shapes the Parties pop-up | Moves only through events |
| **Audience segment favorability** | 5 audience kinds (Press, Party Members, Constituents, Boosters, Bureaucrats), `SG01–05` | 0–100 | Nothing now: staff rewards used to move it and were switched to organizations on 2026-11-04. The number is still stored but **no stage, screen or score reads it**; the audience *mix* of each room (a different thing) still decides which backings switch on | Does not fade |
| **Awareness** | **District** and **National** | 0–100 each (start 20 and 10) | Wins, carrying bills (own bill: +5 national, +2 district), flipping a bill by influence (+3 national), hosting | Gaffes left on the counter when a stage ends add up across the run: every 65 leftover gaffes cost 1 District point and every 35 cost 1 National point (scaled by pressure); see the awareness effects below |
| **Election strength** | One slow score | 0–100 | Each week end it moves toward a **potential** (the sum of eight inputs: district awareness 15, national 15, Constituency support 15, organizations on side 15, war chest 10, experience 10, legislative record 10, party backing 10) by at most +2.5 a week up, −1.5 a week down | The cap on weekly movement is the fade. **Fires nothing yet**; shown on its own page |

**Awareness effects** (the Awareness Effects tab, seven rows): National ≥ 80 takes 50,000円 off the base party dues; District ≥ 80 earns a free Training Session Coupon each week end; National ≥ 65 starts press, ambush and TV rooms +5; District ≥ 65 starts Town Halls +5; District ≤ 25 costs −10 standing with the Candidate Selection Committee each week end; District ≤ 13 costs −50 XP each week end; National ≤ 20 costs −5 standing with every National organization each week end, growing by 5 for each consecutive week.

### 4.3 What the player owns

| Thing | Where it comes from | What it does | Limits |
|---|---|---|---|
| **Cards** (70: tiers 0 to 3; suits Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous; types Gain, Attack, Defend, Buff) | Opening deck, then **Rhetoric Training only** | Played in battles | The deck is a **fixed size** (15 plus bought slots), so every unlock means leaving a card out |
| **Deck** | Chosen from owned cards | What a battle draws from | Exactly the right size, owned cards only; up to 5 Expanded Briefing Binders add slots |
| **Backings** (53 modifiers) | Bought in Boosters | Permanent or timed effects (a better start in Town Halls, +Party support on a flip, income, guard and so on); an organization's backing needs its standing at or above that backing's requirement (default 60; many are 45–60) and a price in Funds, Reputation or Constituency support | Timed backings lapse and can be bought again; at Party support above 75 backing M09 is free |
| **Inventory** (34 shop items) | Marketplace, visitor rewards, events, starting kits | Consumables used from the Office or mid-stage: stage buffs, whole-level buffs, standing actions, hosted dinners and tours, regional gifts for promises | Per-item stack caps (default 5) and purchase limits per level |
| **Staff** (3 roles: Policy Research Assistant, Media Spokesperson, District Representative; 21 candidates) | Hired in Staff, upgraded rank by rank, fired for severance (a fired person never returns) | Each rank pays a one-time bonus; hired staff speak Level Intro lines and transitions, brief you on a visiting member, and boost some items | Higher ranks need Staff Training Consultancy Sessions (recruitment tier starts at 0); the researcher's rank sets level unlock prices |
| **Unlocked levels** | Spend XP; many early levels are free | Which levels can be played | Price depends on the researcher's rank |
| **Laws** (Legislative Work) | Floor votes | Each law's effects pay once, and some pay again at the end of every later level | Permanent |
| **Cosmetic packages** (6) | Funds or XP | An outfit, an Office background, music, a calendar style | Decorative only; one equipped per slot |
| **Promises** | Choices that promise an item or hours later | Owed from the Promises panel; kept ones earn standing | Deadline 48 hours by default (scaled by pressure); paused during levels |

## 5. Where the player chooses

| Where | The choice | Consequence |
|---|---|---|
| New Game | Protagonist; Campaign Pressure | Starting numbers and items; the whole campaign's pressure |
| Office, Levels | Which level to play (or to unlock) | Rewards, hours, risk; locked, cooling-down and too-long levels are shown with the reason |
| Level briefing | Go in, or Back | Nothing is taken until Go in |
| Level Intro | **Lean Support or Oppose** the level's bill | Decides who hears you as friend or opponent in every room of that level; your final vote moves them again |
| Combat room | Which cards to play and in what order; when to pass or end the turn; which item to use; the suit to answer a question with | Support, guard, gaffes, standing (answers feed organizations) |
| Office Hours and other dilemma rooms | One of four answers, none "right" | Different organizations move; a choice may cost hours, Funds or an item now, or promise something later |
| Events | Which choice (or Decline) | Funds, XP, numbers, standing, a revealed level, a scheduled follow-up |

**Abandon Level** (in a battle's stage info panel, 2026-11-10) asks first, then loses the stage in play with its ordinary loss penalties and ends the level as lost, whatever that stage's Loss Ends Level says. A follow-up scheduled by a choice that also made a promise waits while that promise is open, fires once it is kept, and is dropped if the promise breaks; a follow-up from a choice with no promise fires on time (2026-11-09). In a bill level, about a quarter of the player's spoken lines (Balance `Player Cues: Room Line Chance`) come from the topic room's own lines on the player's side (Stance matching the player's lean, or blank) instead of the bill's lines.
| Floor Vote | **Aye, Nay or Abstain**; how many members of your own party to whip | The bill passes or fails; party favorability; laws; standing |
| Requests | Carry, amend (swap one part) or decline a patron's bill | Standing, a new level, a law |
| Draft a Bill | Two or three parts from any organizations; optionally an **extra member visit** | Your own bill; costs 350 XP and 300,000円 (and 50 XP for the extra visit); cooldown 90 hours |
| Member Visit | Take the visit or skip it; answer in styles the member favors | Rapport sets the next fight's start; winning wins one seat for this vote |
| Lobbyist Trade | Which part of the bill to drop; which package; whether to use leverage | Seats, standing, Funds, XP |
| Office: Rhetoric Training | Learn the card shown, or pass (up to 3 looks, the last must be learned) | New cards |
| Office: Staff, Boosters, Marketplace, Deck, Appearance | Hire, upgrade, fire; buy backings; buy and use items; build the deck; equip cosmetics | Strength for the next level |
| Office: Promises | Keep a promise (hand over the item or spend the hours) | Standing; or let it break |
| Week end | End the work week early; weekend or home | Time passes; dues, decay |
| Administration | Save, Load, backup, text size, New Game, abandon a level in progress | |

## 6. Growth and decline in one place

**Each stage** (`GameState.finish_stage`): the clock and calendar advance by the stage's hours; its win or loss deltas apply; question answers move organizations (net, capped); instant-win penalties apply; overdue promises break (unless a level is in progress); time-based backing expiry runs; the three crisis triggers are checked.

**Each level end:** rewards from the level's bonus ranges and per-organization deltas; laws with an "every level" effect pay out; item purchase limits reset; level buffs end; cooldown starts; if a special level is due, the next one is forced in.

**Each week end (Going Home):**

1. Party dues are settled (base 50,000円, plus 10,000円 per full 15 points of Party support above 40, plus 10% of the Funds earned Monday to Friday, less any National-awareness reduction).
2. Week-end awareness effects run.
3. Election strength moves toward its potential.
4. Decay runs once, multiplied by the **decay multiplier (2.5 at Standard; 2 Relaxed; 3 Harder)**: neglect decay, each organization's own Decay Percent, then meta decay (Constituency support 10%, Reputation 6%).
5. The next week begins; a random event may be rolled.

**Unpaid dues** roll over. A short week costs 10 Party support (once, not scaled), withdraws the party's backings, and costs standing with Party Headquarters (20), the other parties (5) and the Selection Committee (5); those standing penalties are multiplied by 1.5 for every full 100,000円 still owed.

**Crisis triggers** (checked after every stage and after Office time; each fires once when the value crosses in, and again only after it has come back out):

| Trigger | Condition | Effect |
|---|---|---|
| Town Hall | Constituency support ≤ 15 | After a countdown (15 units) an "Urgent Matters" Town Hall level appears; if an ordinary level is played while it waits, it is forced in right after |
| Steering Committee check-in | Your party's opinion of you (the blended Party support) < 25 | The same, as a Party Steering Committee check-in |
| Funding freeze | Party support = 0 | Stage and level Funds income becomes 0 until Party support rises |
| Party Backing | Party support > 75 | Backing M09 is active free |
| Lifetime gaffes | 50 gaffes in a run | One-time −15 Constituency support |

**Cooldowns, limits and clearance:** a cleared level cannot be replayed until its cooldown (in clock units) has passed; **one-time** levels disappear once finished (win or loss); **Acts** (the 50 bill levels): a bill the player voted **Aye or Nay** on never comes back; a bill they were **absent for or abstained on** returns after a replay timer of **7,488 hours** (about three years, a parliament's tenure at 48 hours a week), and a real vote then replaces the earlier absent or abstained entry (`GameState.act_is_settled`); **Needs Discovery** levels stay hidden until an event choice or a hosted organization reveals them; **seasonal** levels appear only in their months; **event-only** levels open only from an event choice.

## 7. Rooms: how a fight works

**Turn loop.** The opponent's intent (attack, gain support, or block, each with a range) is shown first. Energy refills to the stage's amount (3 in most rooms; some give 4, 5 or more); the hand draws to its size (5 in almost every room). Play cards by paying energy; a card moves support, banks guard, adds or clears gaffes and draws. Ending a turn discards the hand (except in a press conference) and resolves the opponent: an attack is met by banked guard first. **Lobbyist Meeting (2026-11-12, Cameron):** the lobbyist's own organization is always among those applying scrutiny, listed first. A question that names it on neither side gets it added to the organizations it pleases, so a strong answer pleases it; one that already pleases or displeases it is left as written (`BattleEngine.room_organization()`). Other rooms are unchanged. **Ending order (2026-11-11, Cameron):** the gaffe meter is checked first, after every card, so a card that fills it loses the stage even if it also crosses the threshold. Otherwise crossing the threshold ends the stage at once and the opponent's queued move never resolves. A turn with no cards played is a pass (next turn has 1 less energy; in a press conference it also declines the question).

**Card numbers.** A card's support numbers are multiplied by the room's affinity for its suit (about 0.5× to 1.5×), then by the question grade where a question is asked (strong 1.3×, weak 0.7×). Guard, draw and gaffe numbers are never multiplied. Guard stacks to 5 and carries between turns.

**Winning people over.** Undecided people come across for 1 point; people already opposed cost 1 (60%), 2 (30%) or 3 (10%) points, rolled per person; leftover points mid-conversion are lost. Where the opponent's number is not part of the win condition (press conference, scored caucus) lowering it does nothing.

**Bars.** *Shared pool* (floor debate, caucus, town hall, committee, steering committee): you, the opponent and the undecided split a pool, win at the threshold. *Single* (press conference): a tone number judged against the line after the last question. *Survival* (TV and radio debates): the same three-way room as a shared pool (yours, undecided, the opponent's; 60, 15 and 25 in the data), with the opponent's Gain, Guard and your Opp minus all working as on the floor, but you must be at or above a minimum line at the end of every turn. The line rises by a random amount each turn (0 to 3 in the current data) (with an optional cap, blank today). The bar shows all three parts and the line (2026-11-12, Cameron). *Committee*: several opponents one at a time, fully reset between each. Town hall: clock and gaffes carry, energy refills. Floor debate and caucus: everything carries.

**Win and loss.** Win at the threshold (or by taking every opponent in a sequence). Lose when the gaffe meter reaches its limit (usually 5, changes with pressure), the turns run out (`turn_limit_outcome` = loss), or your own support is argued to zero. A lost stage ends the level, except press conferences and media ambushes (their threshold only picks which reward table applies). Floor Votes and Office Hours cannot be lost.

**Campaign Pressure** (`Difficulty.gd`; every number a Balance row named `difficulty_<tier>_<lever>`): opponents start with 6 less / 6 more support, the gaffe limit is one higher / one lower, awareness gaffe percent (50/150), reward percent (115/85), dues share (5/20%), dues holiday weeks (3/0), decay multiplier (2/3), promise deadlines (150/75%), broken-promise penalty (−5/−7), item prices (85/115%), election strength speed, and the draft cost (200,000 / 400,000円). Card values, energy, hand size, turn limits and text never change.

## 8. Bills, votes and laws

- **A bill level** names one of the 50 Floor Vote bills (or a sponsored or drafted one). Every room in it is a bill-specific copy of a generic room with its own questions, cues and transitions. The Level Intro shows the level's **purpose** (said by a hired staff member, or as narration with no staff) and a **bill card**; **Read the Bill** opens a dossier (what it does, who gains, who pays, the strongest case each way, the main risk, a middle ground, how each party leans). The **lean** you pick shapes every room: you stand with the bill's supporters (Support) or its opponents (Oppose); answers that please the far side count at half; winning a combat room gains 2 standing with your side and loses 2 with the other; your final vote moves them 2 again. **Switching your vote away from your lean** costs the side you leave 5, wins back up to 25% of that from the side you join, and moves Party support (+1 if you now match your party's position, −3 if you now oppose it).
- **Who argues what.** An opponent argues their own party's position on the bill, or, in a split or neutral party, a personal side rolled from the party's own Aye / Nay / Abstain mix; party leaders also say their party's Floor Vote line. If the player is on the same side, an opponent challenges as a demanding ally instead. Lines are chosen so that none repeats inside a level while unused ones remain.
- **The vote.** 101 seats; **51 Aye needed, abstentions counting against the bill**; some bills need a supermajority (67% of the house). Your seat sits wherever your party's majority sits; voting another way moves exactly that one seat. Each party's baked-in Aye / Nay / Abstain split gives the rest.
- **Moving more seats.** *Whip:* spend Party support to pull members of your own party to your pick (10 each, three times that against your party's position; a flat 1 cheaper, never under 5, when at least one organization with a stake in your party holds you at 65 or more; at most 3 per vote; Party support cannot drop under 30 by whipping). *Influence swing:* when **every enabled gate row** (Reputation, several organization standings, some scoped to particular parties) clears its threshold, other parties give up seats toward your pick, up to each party's resistance (default 85%). *Members won over* in a member visit and *lobbyists working against you* add or remove seats outside the gate.
- **What the Floor Vote screen shows before the vote.** A line says whether your influence will or will not affect the vote; an **Influence Status** button lists every requirement still missing. **Vote Projections** show one bar per choice (Aye, Nay, Abstain) labelled "Likely Passes" or "Likely Fails" from the true result, with influence and whips included. A share of the house, drawn between `Vote Projection: Unknown Minimum Percent` and `Maximum Percent` (10 to 25) when a level begins or a stage ends, is shown black as Unknown, taken from the three buckets in proportion, so the exact tally waits for the outcome screen. Whipping sits behind a **Whip Details** button. A hired primary **Policy Research Assistant** narrows the Unknown range (Tier 0/1/2 take 1/2/3 points off both ends) and offers **Vote Intention Research** above the whip block: once per vote, 2 hours and 50 XP, clearing a further 1/2/3% of the house (the tier's own value, not added up). The drawn share and the briefed flag are saved.
- **After the vote.** Every party's favorability moves according to which side of the bill it stood on (whether or not the bill passed); your own party's share lands on Party support. The bill goes into **Legislative Work** with its tally, how you voted and whether your influence turned it. Its **Law Effects** then apply once and, for some, at the end of every later level.
- **Sponsored bills.** When an organization's standing reaches 50 (a **Favor**, two of its parts) or 70 (a **Flagship**, its two plus an ally's), it asks you to carry a bill; up to two requests wait at once. You may carry, amend (swap one part) or decline (5 or 10 standing). A patron bill cannot pass without your influence. A sponsored level opens with a **patron visit** (the organization's representative asks two dilemmas), and may include a **member visit** (Favor 50%, Flagship always), a **public room** and a **lobbyist trade**; it ends in the vote.
- **Drafted bills.** Pick two or three parts; two make a Favor-like level (member visit half the time), three a Flagship-like one. An **extra member visit** (a second Member Visit and Win Over a Member pair, directly before the vote, with a different member) costs 50 XP and 2 hours. Hours and the work-week rule apply.
- **The member visit.** Three questions answered in rhetorical styles; each strong answer is +1 rapport, each weak −1; rapport sets the one-on-one fight's start (+5 per point). The fight is titled "Convince <member>" (fallback "Convince Your Colleague"). Winning wins one seat for this vote only.

## 9. State the run keeps (`GameState`)

Everything below lives in the autoload `GameState`. **Saved** means it is in `_SAVED_FIELDS` and survives closing the app; **not saved** values are rebuilt or lost (they only describe the moment just past).

**Identity and pressure**

| Variable | Meaning | Saved |
|---|---|---|
| `protagonist_id` | Which of PC01–PC04 | yes |
| `difficulty` | `relaxed`, `standard` or `harder` | yes |
| `awaiting_new_game` | True from boot until a protagonist is chosen | no |

**The numbers**

| Variable | Meaning | Saved |
|---|---|---|
| `meta` | `{Constituency support, Reputation, Funds, Party support}` | yes |
| `xp`, `xp_earned_total` | Spendable XP; lifetime XP earned | yes |
| `funds_cap_bonus` | Added to the 100,000円 starting cap by Fund Limit Increase Petitions | yes |
| `last_meta_change`, `last_meta_cause`, `last_xp_gained` | What the last stage or level did to each number and why, for the result panel and Your Record | no |

**People and standing**

| Variable | Meaning | Saved |
|---|---|---|
| `booster_standing` | Standing with each organization, by `BOxx` | yes |
| `last_booster_change`, `last_booster_cause` | Last level's movement and reasons | no |
| `party_standing`, `last_party_change` | Standing with the six parties (the other five); last floor vote's movement | yes / no |
| `segment_favorability`, `last_segment_change` | Audience-segment favorability (stored but read by nothing today); last movement | yes / no |
| `awareness`, `awareness_streaks`, `awareness_gaffe_tally` | District and National meters; consecutive-week counters; leftover gaffes | yes |
| `last_awareness_change` | The last stage's movement | no |
| `election_strength` | The slow 0–100 campaign score | yes |
| `booster_moved_in_period`, `last_decay_at` | Which organizations moved since decay last ran; clock at last decay | yes |
| `faced_people` | How often each person has been seated against the player (the draw leans to the least met) | yes |

**Progress through levels**

| Variable | Meaning | Saved |
|---|---|---|
| `level_runner` | The level in progress (stages, position, scores); null in the Office | yes (as a snapshot) |
| `mid_stage` | True while a stage is being fought | no |
| `last_level_outcome` | `win`, `loss` or empty | yes |
| `levels_unlocked` | Level IDs bought with XP | yes |
| `levels_cleared` | Wins per level (Your Record) | yes |
| `levels_completed_count`, `level_last_completed_at` | A running count of finished levels, and for each level the count when it last finished (this is what hides a one-time level once it is done) | yes |
| `level_cleared_units` | The hidden-clock reading when each level last finished (what cooldowns count from) | yes |
| `discovered_levels` | Hidden levels an event or hosting revealed | yes |
| `special_levels`, `special_forced` | Countdowns running for the Town Hall and Steering check-in; one to start at once | yes |
| `town_hall_active`, `steering_committee_active`, `funding_frozen_active` | Edge latches so each crisis fires once per zone | yes |
| `pending_trigger_alerts` | News of triggers for the Office to show once | no |
| `stage_type_results`, `lifetime_gaffes`, `stages_lost_to_gaffes`, `gaffe_penalty_applied` | Win/loss per stage; gaffe tallies; whether the one-time penalty fired | yes |

**Time**

| Variable | Meaning | Saved |
|---|---|---|
| `time_units` | The hidden clock | yes |
| `calendar` | `{week, phase (work or weekend), hours}` | yes |
| `level_clock_started` | Clock when the current level began (−1 between levels); promise deadlines pause while it is set | yes |
| `week_funds_earned`, `dues_balance` | Funds earned Monday to Friday this week; unpaid dues carried | yes |
| `event_last_at`, `dated_events_done`, `scheduled_events`, `event_roll_due` | When events last happened, dated events played, follow-ups scheduled, whether a random event may arrive | yes (`event_roll_due` no) |

**Holdings**

| Variable | Meaning | Saved |
|---|---|---|
| `owned_cards`, `deck` | Cards owned; the cards carried into a fight | yes |
| `deck_size_bonus`, `deck_expansions` | Extra deck slots bought; how many times | yes |
| `card_draw` | A Rhetoric Training draw in progress (so quitting restores the same card) | yes |
| `owned_modifiers`, `modifier_expires` | Backings owned; when timed ones lapse | yes |
| `inventory` | Shop items held, by `SHxx` | yes |
| `shop_bought_this_level` | Per-item purchases this level (purchase limits) | yes |
| `pending_stage_bonuses`, `pending_level_bonuses`, `level_bonuses`, `timed_bonuses` | Item effects waiting for the next stage or level; active for the level; or running on the clock | yes |
| `staff_hired`, `staff_fired`, `staff_recruitment_tier` | Who is hired at what rank; who was fired; how many recruitment tiers are open | yes |
| `owned_cosmetic_packages`, `active_cosmetics` | Bought packages; the one equipped per slot | yes |
| `promises`, `promises_broken_unseen`, `promise_serial` | Owed promises; broken ones the Office has not yet announced; id counter | yes |

**Bills and laws**

| Variable | Meaning | Saved |
|---|---|---|
| `bill_stance` | The lean taken on this level's bill, the standing it has cost, whether the vote was cast | yes |
| `bill_assist` | Seats won over or worked against for the vote in front of the player | yes |
| `statute_book` | One entry per bill voted on (Legislative Work) | yes |
| `bills_flipped_by_influence` | Bills the influence swing turned | yes |
| `patron_requests`, `enacted_components` | Each request's status; every bill part that has become law | yes |
| `patron_runtime`, `patron_composed`, `patron_armed` | The sponsored or drafted level in play and its composed bill; countdown starts | yes |
| `patron_drafts`, `draft_counter`, `last_draft_at` | The player's drafted bills; how many; when the last was drafted | yes |
| `patron_news` | Stories the Office ticker is running | yes |
| `last_patron_outcome` | What the latest sponsored-bill vote did, read once by the vote result | no |
| `last_visitor_effects` | The organization changes the latest Office Hours answer made (for its result chips) | no |
| `last_level_start_refusal` | Why a sponsored or drafted level could not start | no |
| `hosted_session` | A dinner or tour in progress | no |

**Presentation memory (never saved):** `transition_memory` (who spoke at the last transition), `opponent_lines_said` (lines this level has used, so none repeats while unused ones remain).

Internal scratch variables (leading underscore) are not part of the run.

## 10. The numbers Cameron can retune

Every number below is in the workbook and exported to data; none is hard-coded.

| Where | What |
|---|---|
| Balance tab → `data/balance.json` | About 230 levers, grouped by prefix: `starter_deck_*`, `question_*`, `stance_*`, `lean_*`, `party_*`, `vote_*`, `whip_*`, `patron_*`, `draft_bill_*`, `mp_visit_*`, `trade_*`, `workday_*` / `weekend_*` / `calendar_*`, `week_decay_multiplier`, `dues_*`, `awareness_*`, `election_*`, `event_*`, `hosted_*`, `promise_*`, `difficulty_*`, `text_scale_*`, `transition_*`, `win_over_*`, and the crisis thresholds (`jiban_town_hall_trigger`, `party_support_*`, `gaffes_lifetime_*`) |
| `data/rules.json` (hand-written) | Switches with allowed options: `turn_limit_outcome`, `opponent_can_win_by_threshold`, `opponent_engine` (only `intent_patterns` exists), `discard_hand_end_of_turn`, `pass_energy_penalty`, `guard_cap`, `level_gating_enabled`, `open_card_collection`, `funds_starting_cap`, `card_training_looks`, `default_consumable_stack_cap`, `default_intent_pattern`, seasons |
| `data/booster_standing.json` | Standing rules: start, please/displease amounts, the ±10 cap, gain and loss bands, neglect decay, default decay percent, default backing requirement |
| `data/party_standing.json`, `data/vote_influence_triggers.json`, `data/awareness_effects.json`, `data/standing_links.json` | Party start values; the influence gate rows; awareness consequences; organization links |
| Stages, Levels, Events, Shop, Boosters, Modifiers, Staff tabs | Per-room energy, hand, gaffe limit, turn limit, hours, rewards and penalties; level unlock prices, cooldowns and rewards; event choices; item prices and effects; backings; staff ranks |

## Addendum 2026-11-06: saving inside a stage

A stage is not saved while it is fought, with one exception: in a stage with several opponents, the run is saved when one is defeated (`GameState.stage_checkpoint`), so a closed app resumes at the next opponent with that stage type's carried state (committee: fresh; Town Hall and floor debate: gaffes, guard, hand and clock). A single-opponent stage returns to its own start. When a stage ends, its result is written to the save before the result panel is dismissed (`GameState.pending_stage_result`, cleared by `finish_stage`), so closing the app on a loss screen does not undo the loss.

## Addendum 2026-11-07: promises can owe Funds

A promise now has three kinds: an item, hours, or Funds (`Promise Funds N within H for BOxx`). A Funds promise is kept from the Office's Promises panel, which takes the Funds then; the Pay button is greyed with "Not enough Funds" while the player is short, and nothing is reserved in the meantime. One unpaid at its deadline is broken like any other promise.

## Addendum 2026-11-08: staff slots and the primary

The Marketplace's **Expanded Staff Office** (SH35: 150 XP, 300,000円 and 15 Reputation; up to twice) adds one place to every staff role. The first person hired in a role is its **primary**; later ones are extras. Extras pay their rank rewards on hire and upgrade, can be upgraded and fired on their own, and may speak in stage transitions; the primary alone is read by Level Intro cues, the purpose line, notices, the ticker, item bonuses and the Member Visit briefing, so scenes never conflict. **Make primary** on an extra's profile swaps the two; firing a primary promotes the first extra. The price's Reputation part, the item's number and the purchase cap are Balance rows (`Staff Slots: ...`).

**Resigning (2026-11-11, Cameron).** At the top of Reputation and Results a crimson **Resign** button appears only while Reputation is below 10, Party support below 20 and Constituency support below 20 (Balance rows `Resign: ...`, `ResignRules`). It ends the run at once: the save is deleted (a manual backup stays), the Resign screen shows in two parts. Part one: RESIGN.png, the closing words (Text tab) and a crimson **Goodbye** button. Goodbye swipes part one left and part two in from the right: RESIGN_2.png with the words and button flipped left to right, as if seen from behind. After a hold it fades to black, stays black, then the title appears (Balance `Resign: Swipe / Hold / Fade / Black Seconds`: 1.2, 4, 1, 2).

**Haptics and the back button (2026-11-11).** Confirming buttons (card played, end turn, purchases, hire and fire, Back and Continue buttons, going home, the floor vote) give one short buzz (`Haptics`, Balance `Haptics: Confirm Milliseconds`); Administration and the stage menu have a Haptics on/off switch. The Android back button does nothing: every way out is a button on screen.

**A lost Act (2026-11-12, Cameron).** When a stage whose loss ends a bill level is lost, the battle screen shows a cue before the result panel: gaffes full gives "Tongue tied and babbling away. Fortunately, your staff [or party staff, with none hired] pulled you away because any more damage could be done." with crimson lines; any other loss gives "Your party pulled you away from this bill due to lackluster performance." with lines in the player's party colour (`BillLossCue`). Abandoning gets no cue. A lost or abandoned Act still comes to a vote with the player abstaining (no whips, no influence); the result enters the statute book as a limited **absent** entry and takes effect like any vote, with no extra penalty. Your Record lists it as "<Bill>: passed/failed in your absence." and its pop-up shows only that and the note "Stakeholders for this bill observed your absence from proceedings." A real Aye or Nay vote on the bill is final; an absent or abstained entry is replaced by a later real vote once the bill has come back.
