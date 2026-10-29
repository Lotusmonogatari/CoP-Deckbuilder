# Content generation guide: levels, stages, events and what they depend on

**Status: written 2026-10-29 from the workbook, exporter, code and tests as they stand** (97 levels, 270 stages, 125 opponents, 166 visitors and 393 visitor questions, 50 bills, 38 events, 32 organizations). It replaces the 2026-10-12/13 expansion guide, the content prompts and the visitor-dilemma note (see section 11). Everything an assistant writes is **a draft for Cameron** and never a canon decision.

Read with: `design/EDITING_TEXT.md` (how to reword existing text, tab by tab), the workbook's **Tone Guide** tab and the header notes on each column, `tools/workbook/README.md` (the editing tool) and `CLAUDE.md` (the brief).

---

## 1. Executive summary

| # | Rule | Why it matters |
|---|---|---|
| 1 | **Add content, never mechanics.** A new room, level or event is rows in the workbook, built like the nearest existing one. Anything needing code (a new room kind, a new column a script must read) is proposed to Cameron first. | Cameron is not a programmer; the engine is verified against today's shapes. |
| 2 | **Draft, mark it, never decide canon.** No new named characters, parties, committees, places or political positions he has not written. Where there is a Why/Note cell write "Draft YYYY-MM-DD". | Canon is his. People you need but cannot name: report the shortfall. |
| 3 | **A room is a family member.** Copy the nearest stage row and change only its name, audience, affinity and rewards inside that family's range. | Stages are tuned in families; a new shape is a new kind of room. |
| 4 | **Content is keyed by stage ID, never by level or bill** (bill-scoped rows excepted, section 6). A topic needs its own `STxx` row. | Questions, cues, transitions and people all look up the stage. |
| 5 | **Every line obeys its scope.** The wider it can appear, the less it assumes (section 7). | One bad universal line shows up everywhere. |
| 6 | **Numbers are numbers, text is Text-tab rows or tab cells, and workbook numbers beat code.** No sentence or design number goes in a script. | The exporter and `test_balance_keys.gd` enforce it. |
| 7 | **Every new thing must be reachable.** A room is in a level, a level is unlocked or discoverable, an event has choices, a person is seated somewhere. | Unreachable content is invisible and the export errors on some cases. |
| 8 | **Verify before handing over.** `python3 tools/export_data.py` must say "No errors", then `tools/verify.sh` must say "All checks passed". New rooms get a bot trial. | Section 10. |

After any workbook edit: edit with Excel or `tools/workbook/wbx.py` (**never save with openpyxl**, it corrupts cached values), run the export, and commit the workbook and the regenerated `data/*.json` together.

---

## 2. How the content system fits together

```
 Level (Levels tab)                       the player's choice in the Office
   └─ stage slots 1-10 ── STxx / BIxx     (BIxx = the Floor Vote for that bill)
        │
        ├─ Stage row (Stages tab) ── Affinity column (suits x room)
        │     ├─ who is drawn ........ Opponents "Stage" cell (Combat)  /  Visitors "Stage" cell (Office Hours)
        │     ├─ what is asked ........ Stage Questions + a room Question Pool
        │     ├─ what is said ......... Player Cues, Opponent Cues, Flavor Text (card)
        │     ├─ beat before it ....... Transition Cast / Dialogue / Backgrounds (if not the first slot)
        │     └─ its picture .......... Background ID (own picture, else its family's, else OUT_ scenes)
        │
        └─ win/loss deltas ─► meta values, XP, organization standing, awareness
                                   │
 question Theme ─► Question Themes ─┴─► organizations pleased / set back ─► backing, party opinion, vote influence
 bill (Floor Vote Bills + Party Positions) ─► vote ─► Law Effects ─► standing, meta, Funds
 week layer: hours per stage ─ work week / weekend ─ party dues ─ awareness ─ events (Buyable, Random, Dated)
```

The loop that matters when writing: **questions move organizations; organizations move parties and votes; votes become laws; laws move organizations again.** A question's Theme is not flavour: it changes who likes the player for the rest of the run.

---

## 3. Levels (Levels tab)

A level is a row of up to ten stage slots plus rewards, cost and availability.

| Column | What it does |
|---|---|
| **Level ID, Description** | Next free `LVxx` (today **LV98**). The description is the briefing title; for a bill level it is the bill name. |
| **Cooldown** | Hours before it can be played again (the calendar is in hours). A number cell. |
| **Level Tier** | 0, 1 or 2. Tier gates the XP unlock price (four cost columns: PRA vacant, tier 0, tier 1, tier 2). |
| **Stage ID for Part 1-10** | `STxx` for a room, or `BIxx` where the Floor Vote for that bill is played (ST23 with that bill). The last slot of a bill level is its `BIxx`. |
| **Bonus Win Range Δ** (5 meta columns) and **Win ΔBOxx** (BO01-BO32) | Extra rewards on completing the level. Numbers, not text. |
| **One-Time** | Yes: disappears once completed (a payoff that must not be farmed). |
| **Special Trigger** | `Town Hall` or `Steering Committee`: a crisis level (LV83, LV84) shown in the Special Levels block when due. One level per trigger; the export checks. |
| **Weekend OK** | Yes: can start in the optional weekend if it fits the hours left. Short levels (one stage of 2-4 hours) are the weekend ones. |
| **Needs Discovery** | Yes: hidden until revealed. It must be reachable: an Event Choice whose **Unlocks Level** names it, or a **Host Org** (a BOxx) whose hosting reveals it (the export errors on an unreachable hidden level). Tier 0 levels stay shown. |
| **Host Org (BOxx)** | The organization whose dinner (National tier) or walking tour (Constituency tier) reveals this level. Party-tier organizations cannot host. |

**Kinds of level in use**

| Kind | Shape | Notes |
|---|---|---|
| Generic levels (LV01-LV30) | Chains of generic rooms | Original campaign levels. |
| **Bill levels** (50 of the rows from LV31 to LV82; LV61 and LV62 are topic levels without a bill) | Every stage is a **bill-specific copy** of a generic room (section 4), ending in the bill's Floor Vote | Each has Level Intro Cues, a Level Intro Thought, a bill visitor in its Office Hours, bill-scoped questions/cues/transitions (section 6). Half are gated (Needs Discovery). |
| Special / crisis levels | LV83, LV84 | One room, `Special Trigger`. |
| **Single-stage outings** | LV85-LV97: a lobbyist word, weekend Office Hours, a local festival (LV87, 92, 93), press gaggle, town hall, study evening, TV interview, walkabout, clinic day, school visit, farmers' market | Office Hours clones seating several local visitors; weekend-ready; short cooldowns. |
| **Patron / drafted bills** | Built at run time from **Patron Bills**, **Bill Components** and **Bill Level Templates** (section 8) | Not rows in the Levels tab; nothing to add there. |

**Recipe: a new level.** (1) Pick the shape of an existing level of the same kind and copy its row. (2) Fill stage slots from existing or new rooms (section 4). (3) Set tier, cooldown, XP costs and rewards as **numbers**, close to a comparable level. (4) If it is a bill level, add the bill (section 8) and put its `BIxx` last. (5) Decide availability: ordinary, Weekend OK, Needs Discovery (then wire a reveal), or Special Trigger. (6) Add Level Intro Cues and a Thought (section 7). (7) Make sure every room appears in at least one level.

---

## 4. Stages (Stages tab)

A stage is one room. **Mode**: `Combat` (card battle), `Non-combat` (Office Hours-style visitor room), `Vote` (ST23 only), `Visit` and `Trade` (the patron member visit and lobbyist trade, run by the patron machinery). Next free ID: **ST271**. Other next-free IDs today: stage questions **S2481**, player cues **PL3517**, opponent cues **OC3109**, transition dialogue **TD2084**, transition cast **TC223**, transition backgrounds **TB79**, ticker **TK156**.

### 4.1 The columns that matter

| Column | Meaning |
|---|---|
| Bar unit / value / max, **Win threshold**, **Turn limit**, energy, hand size, gaffe limit, player/opponent start | The shape of the fight. Copy the family row, vary inside its range. |
| **% Press ... % Other** (six audience columns) | Who is watching; fractions summing to 1. They trigger audience modifiers and aimed cards. |
| **Bar Model** | `Shared_pool` (most rooms), `Single` (press conference tone), `Survival` (TV debate; rising threshold columns Threshold Rise Min/Max/Cap). |
| **Energy Mode / Pool** | `per_turn` or a stage-long `pool`. |
| **Sequence Mode** | `single`, `reset` (committees: everything restarts per opponent), `stream` (town hall: clock and gaffes carry), `continuous` (floor debate, caucus). |
| **Opponent Count** | A number or range. On a Non-combat room it counts **visitors**. More than one opponent in a Combat room needs a non-`single` sequence mode. |
| **Question Pool** | `press_conference`, `town_hall`, `media_ambush`, `lobbyist_meeting`, `policy_study`, or blank. **Blank means no pool**: only Stage Questions are asked (the old built-in defaults were removed on 2026-10-27, so a copy of a pooled room such as ST05 must set the cell, e.g. `town_hall`). |
| **Own Party Only** | Yes: seats only the player's own party (the caucus family). |
| **Reveal In Briefing / Loss Ends Level** | `No` hides a surprise room; Loss Ends Level blank = Yes (press conference and ambush are No). |
| **Show Transition / Transition Speaker Count** | A beat before the room when it is not a level's first slot. Yes on 219 stages today; blank is No. Media Ambush rooms show none. |
| **Time Units** | **Hours** the room takes on the calendar (2 for most single rooms, 4 for committees, caucus, steering and floor debate, 3 for a TV debate, 1 for a floor vote or ambush). |
| **Win Δ District / National Awareness** | Awareness gained on a win; draft values by room type. |
| **Background ID** | Picture to borrow (4.3). |
| Win/Loss Δ columns | Jiban (constituency support), Yen, Reputation, XP, Party support. Numbers; blank = 0. |

### 4.2 Families and bill-specific copies

| Family | Rooms | Questions come from |
|---|---|---|
| Committees / hearings | ST01, ST09-ST18 | Stage Questions only |
| Floor debate, caucus, steering | ST02, ST03, ST08 | Stage Questions (usually few) |
| Press | ST04 conference, ST19 ambush | `press_conference` / `media_ambush` pool (+ Stage Questions) |
| Public | ST05 Town Hall, ST06 TV debate | `town_hall` pool / Stage Questions |
| Interest groups | ST20 Lobbyist, ST21 Policy Study | `lobbyist_meeting` / `policy_study` pool |
| Non-combat | ST07 Office Hours, ST22 Check-In | visitors and their dilemmas |
| Vote | ST23 | the bill itself (section 8) |

**Every bill level plays bill-specific stages, never a generic room.** Each is a **copy of its generic family room about the bill**, named "{Room} on {Topic}" ("Town Hall on Ainu Heritage and Language"), "Committee on Finance: {Topic}" or "Office Hours: {Topic}", with the family row's numbers, its own **Affinity column**, and every table that names the family room also naming the copy (Opponents, Stage Questions, Player/Opponent Cues, Visitors, Modifiers, transition rows). A new bill level repeats this for each room it chains. The seating rule follows the room kind before a colon, so "Committee on Finance: Topic" still seats only Finance members. `tests/test_bill_stages.gd` enforces: no generic room in a bill level, every combat stage seats people, every copy has questions of its own, a copy of a pooled room (town hall, policy study) has its pool cell set, and every stage resolves to a background.

### 4.3 Pictures: Background ID

A room's picture is `assets/backgrounds/{STAGE_ID}.png` if drawn; otherwise it **borrows** the picture named in **Background ID** (every stage from ST24 on has one: its family room, a hearing taking its committee's room). The cell may list **several pictures separated by semicolons**; one is chosen when the room's picture is set and kept while it is on screen. A picture whose name carries a **term** (`..._WINTER`, `..._SNOW`) is only eligible when the room's name contains that term or a related word (terms and related words are listed in `data/art.json` `image_terms`; Cameron edits them). Order of preference: a term picture the room invokes, else a picture with no term, else any. Names beginning `OUT_` are generic outside scenes (`data/art.json` `outdoor_scenes`; `python3 tools/outdoor_backgrounds.py` lists them and writes prompts); an undrawn `OUT_` picture shows the Town Hall (ST05) until drawn. A thematic outdoor room (a festival, school visit, harbor town hall) should list the matching `OUT_` pictures. Pictures need not be portrait; events and stages crop them to fit.

### 4.4 Recipe: a new room

**Copying a row with `wbx` (read this first).** `w.rows()` returns every cell as text, so writing a copied row back with `append_row` stores numbers as text. Convert numeric-looking strings to numbers before writing (`int(v)` or `float(v)`), keep ranges such as `2-3` and IDs as text, skip formula cells (see step 2), and give the new row its own ID, name and Background ID. Always `w.save()` and re-run the export.

1. Choose the family and read its live row. Add a Stages row (copy it), next `STxx`, named for the topic.
2. **Affinity tab**: add the `STxx` column (export error for Combat otherwise): two suits at 1.5 and 1.3, two at 0.5 and 0.7, two at 1.0, chosen from what the room rewards. Do **not** paste formulas into the new Stages row: its Segment check (W) and Favored suit (X) cells are formulas on older rows, but the Favored suit formula only reads Affinity columns B to V and already shows "—" for every stage from ST24 on. Write the audience shares so they add to 1 (the export errors otherwise), put `1` in Segment check and `—` in Favored suit as plain values. Shared formulas copied by hand are what made Excel ask to repair the file.
3. **Opponents tab**: add the `STxx` to the Stage cell of the people who belong there (existing people only; section 5). Or, for Non-combat, the Visitors tab.
4. Questions (section 6), cues (section 7), transitions (section 7), picture (4.3).
5. Put it in a level (section 3). A Combat room needs at least its Opponent Count of seated people.
6. Bot-trial it (section 10).

---

## 5. People: opponents, visitors, staff

| Who | Tab | Key facts |
|---|---|---|
| **Opponents** | Opponents | Opp ID (next **OP126**), Name, Title (overrides Role for display), Party, Affiliation (a BOxx), Role, **Stage** (every STxx they can be drawn for), Suit 1-3, attack/gain/block ranges (`min-max`, one number = fixed, `0` = never). Opponents are drawn at random from everyone listing the room; the draw favours people met least and nobody is seated twice in one stage. |
| **Visitors** | Visitors | Visitor ID (next **VI167**), Role, **Stage** (rooms they visit), Reward/Penalty. Generic roles like "Fishing Cooperative Member"; bill visitors are "{Organization} Representative" (no invented person). A level can pin a visitor to a slot in `data/level_visitor_overrides.json` (hand-kept) and an opponent in `level_opponent_overrides.json`. |
| **Staff** | Staff | The hireable people (Role, tiers, costs, rewards, Biography, Role Flavor Text). Cameron writes Biography and Role Flavor Text. |

**Seating rules the export enforces:** a "Committee on X" room, and any hearing or study run by one, lists only MPs whose Role is that committee; the Special Committee (ST01) seats any MP who is not a minister; the Committee of the Cabinet (ST18) seats ministers and committee chairs (from Title); the Party Caucus is **Own Party Only** (each protagonist's party needs enough MPs listing it); press rooms seat the journalists (BO08). Outside those rules the same person may appear in several rooms. **People are canon**: raising a room's people count is done by listing it in more *existing* people's Stage cells where their job allows, or by reporting how many new characters it needs. A new person needs an Opponents (or Visitors) row **and** `Assets` rows for each expression (three for a visitor, six for an opponent, the name spelt identically in both). A staff portrait may be a plain `SF##.png` with no expression.

---

## 6. Questions

A question does three jobs: its **suit grades** scale the card that answers it, its **Theme** decides which organizations are pleased or set back, and standing feeds backing, party opinion and the vote-influence gate.

| Grade | Answering card | Organizations behind the Theme |
|---|---|---|
| **S** Strong | x1.3 this round | pleased +5; those in the theme's **Annoys** cell set back -3 |
| **M** Medium | unchanged | nothing |
| **W** Weak | x0.7 this round | the pleased organizations are annoyed -1 |

The multiplier stacks with the room's affinity; per organization one stage's net change is capped. **Rules for every question:** at least 2 S, at most 2 W, a W on at least one suit for a new question, no time references, no assumed past events. Room-tab questions (Press, Town Hall, Lobbyist, Study Session, Media Ambush) must also name no specific policy area (they fit any audience); **Stage Questions** are exempt, because specificity to the room's business is their point. **Spread across a batch** (Strong/Weak share per suit, from the master): Earnest 54/14, Emotional 38/27, Appeal 29/20, Data Driven 42/19, Divisive 35/38, Duplicitous 35/24; stay within about 15 points of each, no suit Weak on 0%, none Strong on more than 60%, each Strong on at least 20%. Report the table with a batch.

**Grading by suit.** Earnest wins on accountability or a plain commitment; Emotional on people and harm; Appeal on unity, belonging and favours; Data Driven on cost, evidence and yes/no; Divisive on loyalty, sides and in-group versus out-group; Duplicitous only where deflection is the smart move (usually Weak in public rooms).

### 6.1 Where questions live and how many a room asks

| Tab | For | Notes |
|---|---|---|
| Press / Town Hall / Lobbyist / Study Session / Media Ambush Questions | The five room pools | Theme must match a Question Themes row (join is case-sensitive). Optional **Asked By Party** / **Asked By Organization**. |
| **Stage Questions** | One or more rooms (Stage ID cell takes a list) | Asked first. Columns: Q ID, Stage ID, Question, Theme, six grades, Asked By Party, **Bill ID**, **Component ID**, Asked By Organization. |
| **Question Themes** | Theme -> organizations (and Annoys) | Reuse a theme before adding one; a new theme needs a Why cell starting "Draft". A theme mapped to nobody pleases nobody (export warning). Every organization should keep at least 15 questions across the game. |

A stage asks `questions per turn x turn limit` questions **in total**, drawn once into one bag (a `reset` room does not refill it per opponent). Stage Questions are dealt first, then the pool. Sizing: a room with no pool asks only Stage Questions, so write at least 3 (the committee norm) up to its turn limit, sharing general sets across rooms; a pooled room keeps its pool in play, so write at most about a third of the turn limit; a topic-pure room writes its turn limit and leaves Question Pool blank. A press conference asks exactly its turn limit. **Turning questions on in a room that asked none changes its difficulty** (the first Stage Question switches on the multiplier): bot-trial before and after.

**Who asks.** The asker is drawn from the people the room seats. **Asked By Party** (`PT05`, `PT03; PT06`, or `OWN` for the player's own party) and **Asked By Organization** limit it; if nobody of that party or organization sits in the room the question is not asked there (the export errors for a named party). A party-limited question may be written in that party's voice (section 7).

**Bill-scoped questions.** Leave Stage ID blank and set **Bill ID**: the question is dealt in any Combat room of that bill's level, up to half the questions the room asks. **Component ID** does the same for a patron/drafted bill's component.

---

## 7. Cues, transitions and level intros (the spoken lines)

### 7.1 Scope decides wording

| Scope | Where it can appear | May mention | Must not |
|---|---|---|---|
| **Universal** (no Stage ID / Opponent ID: Flavor Text, general cues) | Any room, any opponent | Only what is true everywhere | name a venue, audience, party, post, date or past event; answer the last move |
| **Stage-scoped** | That room, any opponent eligible there | The room's business and audience | name a party or person |
| **Opponent-scoped** | That person only | Their party's line, organization's interest, role | invent history or relationships |
| **Bill-scoped** (Bill ID, optional Stance) | That bill's level | The bill's subject; Support lines argue for it, Oppose against | state an opponent's party position as fact |

**The five Tone Guide rules** (universal lines; good practice everywhere; stage lines may break rule 2 for their own room, nothing breaks 3-5): (1) nine words or fewer; (2) universal setting; (3) no time references (now, today, again, still, already, always, never); (4) no invented history; (5) not a reply to what was just done. **Suit voice:** Earnest plain, first person, short; Emotional exclamations, faces, families; Appeal we/us/together/favours; Data Driven numbers, yes/no, no exclamations; Divisive us versus them, sides, labels; Duplicitous hedges, passive voice, ellipses. Party voice only in opponent-scoped (or party-limited) lines: Butsutou care and the vulnerable; Yezo Heritage heritage, language, land and sea; Frontier the regions over the cities; Five Point Independents the citizen against the machine; Keizaijiyuutou growth, markets and cost; Country Initiative order, custom, the nation. These are leanings from the Party Standing draft, not new canon.

### 7.2 Cue lookup (so you know what a row replaces)

| Tab | Read order, most specific first | Note |
|---|---|---|
| **Player Cues** (suit, verb attack/gain/block; Stage ID, Bill ID, Stance, Component ID) | bill + verb + stance, bill + verb, this stage + verb, this stage any verb, any stage + verb, any stage any verb, then the card's own five Flavor Text lines | A more specific tier **replaces** the less specific ones; rows at the same tier pool. Bill lines are chosen by the lean the player took. |
| **Opponent Cues** | bill (suit or opponent), this opponent in this stage, this opponent in this style, this opponent anywhere, the style's pool for this stage, the style's pool anywhere | An opponent picks a style by weight (Suit 1 55%, Suit 2 30%, Suit 3 10%, other 5%). An opponent-scoped row follows that person into every room unless a Stage ID is set; leave Stage ID blank only for party leaders. |

**Sizing.** Cover a cell you write with at least two rows (10 lines) so it is no thinner than the universal pool; cover attack, gain and block for the suits the room favours; an uncovered cell keeps the card's own lines. Committee-style rooms are appended to the Stage ID list of the committee Player Cue rows.

### 7.3 Transitions

A transition plays before a stage that is **not first in its level**, shows one exchange, and the banner holds a line for about 4 seconds. **Transition Cast** (Stage ID, Character ID: an OPxx or SFxx; a blank Stage ID is a wildcard), **Transition Backgrounds**, **Transition Dialogue** (Character ID, Stage ID, Character Line, Player Reply, Bill ID, Stance, Component ID). Lines: character up to about 18 words (110 characters), reply up to 8, no numbers; describe the room's feel in-world, never energy, turns or thresholds. A cast member needs at least one dialogue row or they never speak; staff speak only if hired. A speaker is drawn from the wildcard cast plus any room-scoped cast, then a line from that character's rows, so for a topic room give **every** cast member a room-scoped line. A transition may open with the player's own **thought** (a `PLAYER` row; Balance lever `transition_player_thought_chance`). Media Ambush shows none. A room that fires often needs at least 3 variants. Bill rows are preferred over general ones.

### 7.4 Level Intro Cues and Thoughts

**Level Intro Cues** (Level ID, Role, Cue Text): a hired staff member's own line about a level, shown between the Office and its first stage; every hired role with a row speaks, in Staff-tab order; a level with no rows skips the screen. Role is one of the Staff-tab roles (Policy Research Assistant briefs on substance, Media Spokesperson on optics, District Representative on stakes at home). Under about 12 words, in that person's voice, no mechanic talk (no "stages", "win" or numbers), and do not hint at a room whose **Reveal In Briefing** is No. **Level Intro Thoughts** (Level ID, Thought Text): the player's own private thought for the level.

---

## 8. Bills, votes, laws and patron bills

| Tab | Unit | Rules |
|---|---|---|
| **Floor Vote Bills** | one bill, `BIxx` (BI01-BI50) | Name, description (the scroll text), three Favorability Δ (Supportive/Opposed/Neutral; scale by how salient the bill is: high +5/-5, ordinary +3/-2, low +1/-1), Influence Bonus columns, **Vote Requirement** (Majority, Supermajority or blank), **Proponent Party**, optional **Stakeholders Override**. A bill is named by exactly one level; the level names it in a stage slot. |
| **Floor Vote Party Positions** | six rows per bill (PT01-PT06) | Yes + No + Abstain must equal that party's seat count (Butsutou 19, Yezo Heritage 14, Frontier 27, Five Point Independents 5, Keizaijiyuutou 25, Country Initiative 11 = 101; the exporter warns). Disposition Supportive/Opposed/Neutral. A high-salience party is about 90-100% unified, medium 70-89%, low 55-69%; a Neutral position mostly abstains. Cue Text: the party leader reacting, under about 12 words, no mechanic talk. |
| **Vote Influence Cues** | per bill and direction | **A bill passes only when Yes reaches a majority of the whole house (51 of 101); abstentions count against it.** Compute each bill's default outcome: a bill that fails by default needs a "Flipped to Pass" cue, one that passes by default a "Flipped to Fail" cue. |
| **Law Effects** | per bill per outcome | Beneficiaries +2/+3, those it hurts -2; failed rows mirror smaller; Timing Once or Each level. House rule: **every organization is pleased by at least one bill outcome and annoyed by at least one** (the playtest rubric checks it). |
| **Party Values / Party Standing** | reference data | Use as the reference when drafting positions and effects. |
| **Bill Components, Patron Bills, Bill Level Templates, Visit/Trade Questions** | the patron system | Components are the parts of a composed bill (slot, owner organization, hearing committee, gains/loses, each-level effect, excludes, amend options). A Patron Bill names an organization, kind (Favor or Flagship), components, an ally and a template, plus its request/accept/decline/pass/fail lines. A **Bill Level Template** lists tokens (`PATRON_VISIT`, `HEARING`, `PUBLIC`, `CAUCUS`, `MP_VISIT`, `LOBBYIST_TRADE`, `VOTE`; the last must be `VOTE`) and, for `PUBLIC`, the room per organization tier (Public Room (Constituency/National) columns, defaults Town Hall and Press Conference). Component-tagged rows (Component ID on questions, cues, transitions) reach the composed bill. |

**Recipe: a new bill level.** (1) Bill row, six Party Positions rows (seats add up), Law Effects, Vote Influence Cues in the right direction. (2) The level and its bill-specific stages (3, 4.2). (3) Bill-scoped questions, cues and transitions (6, 7), a bill visitor for Office Hours, Level Intro Cues and a Thought, an Office Ticker line per outcome. (4) Check every organization still has a stake (Law Effects).

---

## 9. Events and the week layer

### 9.1 Events (Events and Event Choices tabs)

An event is a screen of flavor text with two to four fixed choices; each choice rolls its own ranges. Next free **EV48**.

| Events column | Meaning |
|---|---|
| **Trigger** | `Buyable` (an arranged event: listed under Events, price paid when arranged), `Random` (may arrive after a level or week end; Balance chance, weighted), `Dated` (a scripted event on **On Date**, forced the first time the Office is open on or after it, once per run; **Speaker Title** names the opponent shown) |
| Available | `Weekday`, `Weekend` or `Both` |
| Hours | 1, 2 or 4; a weekend event must fit the hours left, a finished work week takes none |
| Cost (Funds / XP), Weight, Cooldown Hours | price and frequency |
| Min District / National Awareness | the player must be known enough |
| **Needs Dues Owed** | arrives only while party dues are carried over |
| **Image** | one background ID, or several separated by semicolons; one is chosen each time and the result screen keeps it. Term pictures obey the event's title and flavor (4.3). Outdoor events use `OUT_` scenes. A picture with no file is an export warning (an `OUT_` one just shows the Town Hall). |

| Event Choices column | Meaning |
|---|---|
| Event ID, **Choice** (A-D), **Choice Text**, **Result Text** | Either text cell may hold `@some.key` to read a Text-tab row (the export swaps in the English; an unknown key is an error). The Decline choices use this. |
| Funds Cost, Funds Δ, XP Δ, Constituency / Reputation / Party support Δ, District / National Awareness Δ | Ranges (`min-max`, a bare number is both). Never put a penalty in XP. |
| **Rewards** | Organization standing in the usual format (`BO06 +1; BO20 -1`) |
| **Unlocks Level** | Reveals a gated level (the event is one way in) |
| Dues Δ | A negative number writes down the carried balance |

**Rules.** Every event needs at least one choice and every choice lettered once. A choice whose text contains one of `data/rules.json` `staff_delegation_phrases` ("a staff member", "a staffer", "a deputy") is greyed out with "No staff hired" when nobody is hired, so word a send-staff option with one of those phrases. **Decline:** a Random event whose choices have no decline-like option gets a **Decline** choice whose penalty is **1.5 x the shortfall of sending staff against accepting** (choice A), applied as a loss and rounded half up; an event with no send-staff choice counts staff as giving nothing. Scale Constituency, Reputation, Party, District, National and organization standing; never XP, Funds, dues or unlocks. Label `@event.decline`, result `@event.decline.EVxx`. The one-off generator in `tools/workbook/archive/b9/decline_options.py` is **not reusable as it stands**: its Decline wording is a fixed table of the 17 events, so a new event stops it with a `KeyError`; for a new event add the Decline row by hand (or add the event's line to that table first) using the rule above. It reads `data/*.json`, so export before running it. Keep every event inside the content budget used by Office Hours (below): meaningful rewards cost something somewhere.

### 9.2 Hosted events, shop events and the week

- **Hosted Events + Event Options**: the walking tour (Constituency organizations) and dinner (National): three steps of options with tags; organizations like and dislike tags (**Organization Tastes**); **Reaction Lines** give guest reactions. Hosting an organization reveals one of its hidden levels. Items **SH19/SH20** and the Shop **Hours** column take 4 hours.
- **Calendar**: five 8-hour days pooled into a 40-hour work week, an optional 2 x 4-hour weekend, then "Pay Party Dues and Go Home". **Party dues**: a base plus a step per 15 Party support above 40 plus 30% of the week's Funds earned, less National Awareness relief; unpaid dues roll over and cost Party support, backings and standing (Balance "Dues: ..." levers). Awareness meters (District and National) and **Awareness Effects** rows are data.
- **Office Ticker** (`ticker_id`, `condition_type/target/op/value`, `text_en`, optional `weekdays`, `from_date`, `to_date`, `yearly`; dates YY.MM.DD, inclusive; `{player}` fills the protagonist's name) and **Office Notices** are Office flavor lines under conditions (staff, meta thresholds, `always`, or a law passed/failed).

### 9.3 Office Hours content (visitors and dilemmas)

A visitor question has **no right answer**: each of the four choices carries its own **Effects** (a target list like `BO06 +3; BO04 -1`: organizations, a pool `BO01|BO02 +1`, a tier `TIER:Party +1`, a shop item or a modifier; a range is `BO06 +1-3`; Sanban variables are not supported), **Response** (what the visitor says back; 14 words or fewer, no time words) and **Reaction** (a short stage direction). A choice with blank cells falls back to the visitor's Reward/Penalty. **Budget (enforced by `tests/test_office_hours_engine.gd` on every real question):** each choice is 2 to 7 points counting minus signs as plus; any choice gaining more than 1 also costs something somewhere; at least one choice pleases someone by +3 or more; no more than two choices net 2 or more; typical mix: a friend-pleaser, a rival-pleaser, a middle path (+1) and a refusal (-2 to -4). Standing from visitors is flat. Festival and district-activity pools are local-only visitors (not in ordinary Office Hours); a bill's visitor appears first in that bill's Office Hours.

---

## 10. Dependency checklist and verification

### 10.1 If you add X, also touch Y

| You add | Also needed |
|---|---|
| A **stage** | Stages row; Affinity column (Combat); seated people (Opponents Stage cell, or Visitors, enough of them for the room's seats); Background ID; appear in a level; questions/cues/transition rows as sized; Assets row only for new art files. **Modifiers tab, Effect Target cell**: a backing that applies to a family of rooms lists their stage IDs (`ST05; ST122; ...`); a new copy of a family room must be appended to every modifier that names its family or the backing silently does nothing there (one test, `test_party_bodies.gd`, checks only M47: every stage named "Town Hall" or "Caucus") |
| A **bill-specific room copy** | the above, plus its name added to every table that names the family room, bill-scoped rows, and a Background ID of the family room |
| A **level** | stage slots reachable; tier, cooldown, costs as numbers; Level Intro Cues + Thought; if gated, an event Unlock or Host Org; if a bill level, section 8 |
| An **opponent** | Opponents row (Stage cell, suits, ranges), Assets rows (six expressions), cue rows if they should sound distinct, name identical in both tabs |
| A **visitor** | Visitors row (Stage cell), two or more dilemma questions inside the budget, Assets rows (three) |
| A **question** | a Theme that exists (or a new Question Themes row with a "Draft" Why), six grades, asker limits if party-voiced |
| An **event** | Events row + choices; Decline choice if Random and none exists; Image; an Unlock/Host path if it reveals a level |
| A **new sentence the game says** | a Text-tab row asked for by a literal key (`Text.say("a.b")`); money placeholders named `cost`, `price`, `count` or `yen_...` so they get commas |
| A **number the code uses** | a Balance-tab row read with `DataDB.balance.get(...)` or `Levers.num(...)`; `tests/test_balance_keys.gd` fails on a missing key |

### 10.2 Hand-over checklist

1. `python3 tools/export_data.py` ends **No errors**; read the warnings (unmapped theme, seats not adding up, picture with no file). `--accept-wording` only when Text rows were reworded on purpose.
2. `python3 tools/workbook/check_formulas.py` and `tools/verify.sh` (about 2 minutes; `--quick` for a fast check) say all clear.
3. `python3 tools/content_depth.py` (the **three-times rule**: every room holds at least three times the content a run meets: questions 3 x turn limit, people 3 x opponent count, each cue cell 3 x its moments, transitions at least 3 exchanges). One general question or cue row can serve many rooms by listing them in its Stage ID cell.
4. A new or changed room: `PLAYTEST_PROTAGONIST=PC02 PLAYTEST_STAGE_TRIAL="STxx:40" .tools/godot --headless --path . tools/playtest_optimal.tscn` and report the win rate (a fair room is won roughly half to most of the time; questions make a room easier).
5. Anything touching organizations, bills or votes: `xvfb-run .tools/godot --path . tools/rubric_playtest.tscn` still scores full marks.
6. **README tab**: Cameron's overview still says "259 stages, 82 levels"; update its counts when you add stages or levels. Mark new rows as drafts where a Why/Note cell exists; keep numbers as numbers (the master has a few hundred text-typed numbers the export tolerates, but do not add more); re-read current values from today's workbook before editing existing rows.
7. Hand over an audit: ID ranges and collisions, seat totals per bill, default outcome against cue direction, Strong/Weak share per suit, questions per room against turn limit, cue lines per (suit, verb) cell, transition word counts, rooms in no level, seated people per room against Opponent Count, and every new place or institution listed for Cameron.

### 10.3 Pitfalls that have happened

| Problem | Rule |
|---|---|
| An edit written against an older workbook undid a later fix | Re-read current values; Cameron's uploads can land on `main` while you work: take his file and re-apply your edits with `wbx` |
| Numbers typed as text (tier, cooldown, costs) | Number cells only |
| Too many Stage Questions on a pooled room hid its pool | Section 6.1 sizing |
| Questions switched on for a room that asked none, with no difficulty check | Bot trial before and after |
| One suit Strong on 90% of a batch | Spread targets |
| Cue pools thinner than the 10-line universal pool | Two rows per cell |
| Transition lines too long for a 4-second banner | 18 words / 8 words |
| A room in no level | Section 3, step 7 |
| Same hand/energy/gaffe numbers on every new room | Vary inside the family's range |
| Amounts without commas ("100000円") | `cost`/`price`/`count`/`yen_` placeholder names |
| A picture name that never loads | IDs are exact; a typo only warns for non-`OUT_` pictures |
| An Office Hours room with no seated visitor | The export says "No errors"; only `test_every_real_level_is_usable` fails. Run the unit tests, not just the export |
| A stage's Background ID with a typo or a list on a new non-bill room | No export warning. `test_a_bill_specific_copy_plays_like_its_family` hard-codes the outing stages ST264-ST270 and the patron rooms, so a new stage with a picture list (or any non-stage Background ID) can crash that test; ask Cameron before editing the test |
| A new outing or festival | `test_district_activities.gd` and `test_weekend_levels.gd` name their stages, so a new one is not covered by them; bring its pool (more visitors than seats, two dilemmas each) up by hand |
| `content_depth.py` on a brand-new room | It has no measured plays for it and assumes a default; run `tools/measure_plays.sh` for a real figure |

---

## 11. What this guide replaces, and what stays

Replaced and deleted (2026-10-29): `design/WORKBOOK_EXPANSION_GUIDE.md` (the 2026-10-12/13 expansion guide, counts and room list out of date, missing events, calendar, bill-specific stages, pictures), `design/CONTENT_PROMPT.md` (early cue/question drafting prompt), `design/LEVEL_INTRO_PROMPT.md`, `design/FLOOR_VOTE_PROMPT.md`, `design/VISITOR_DILEMMA_GUIDE.md` and `design/EXPANSION_DRAFT_FEEDBACK_2026-10-13.md` (feedback on one finished draft). Kept: `design/EDITING_TEXT.md` (rewording existing text), `design/OUTDOOR_BACKGROUNDS.md` (the outside scenes), the art prompt and checklist files, `design/PLAYTEST_CHECKLIST.md` and `design/PLAYTEST_RUBRIC.md`, `design/GAME_DESIGN.md`, and the archived batch scripts in `tools/workbook/archive/`, which remain worked examples of how each earlier batch was generated.

**When the workbook is not enough (ask Cameron first):** a new kind of room (a new Mode or Bar Model); a sixth room question pool; any new column a script must read.
