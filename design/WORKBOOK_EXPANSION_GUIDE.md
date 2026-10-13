# Expanding the workbook: a guide for an assistant

For an assistant (human or AI) adding content to `design/CoP_Starter_Card_Stage_Data.xlsx`: new stages, questions tied to them, spoken cues, opponents, bills and their effects. It explains how the pieces connect, what each number does to play, and how to phrase writing so it fits where it can appear.

Read with: `design/EDITING_TEXT.md` (tab-by-tab editing), `design/CONTENT_PROMPT.md` (a batch-drafting prompt), the **Tone Guide** tab, and the header notes on every column (hover a header cell in Excel). Written 2026-10-12, revised the same day and again on 2026-10-13 after a review of a 21-room draft (see §2.7, §3 and §10). **Ground rule (Cameron, 2026-10-13): an expansion adds content, never mechanics.** Every room, existing or new, may draw on the base (generic) content and on stage-specific content where it applies; new rooms are built like an existing room of their kind against the code and workbook as they stand (23 stages, 60 levels, 30 organisations, 125 opponents, 39 visitors, 30 bills, 201 question themes).

---

## Executive summary

| If you remember six things | |
|---|---|
| **1. Everything is a draft for Cameron.** | Write it, mark it ("Draft YYYY-MM-DD" in a Why/Note cell where there is one), never decide canon: no new named characters, parties, committees or political positions he has not written. |
| **2. Rooms are rows, not code, and they follow a family.** | A new stage is a Stages row + an Affinity column + opponents who list it + (optionally) its own questions and cues. Build it from the nearest existing room's family template (§3.0), keep its numbers inside that family's range, and let it use the generic content first. No programming, unless you need a new *kind* of room (see §9). |
| **3. A question does three jobs.** | Its suit grades scale the card that answers it (×1.3 Strong, ×0.7 Weak), its Theme decides which organisations are pleased or set back, and those standings feed backing, party opinion and the Floor Vote influence gate. |
| **4. Scope decides wording.** | The wider a line can appear, the more generic it must be. Any-stage lines obey all five Tone Guide rules; stage-scoped lines may name the room's business; lines scoped to one opponent may carry that person's party or organisation voice. |
| **5. Who asks a question is picked from the room.** | The asker is someone the room seats. Use the **Asked By Party** column to limit a question to one or more parties (or `OWN`, the player's own) before you write it in a party voice (§6). |
| **7. Count what the player actually meets.** | Content is read by the engine in tiers and pools (§2.7). Judge a cue by how many lines one *card moment* can draw, a question set by what it does to the room's pool and difficulty, a transition by how long it stays on screen. A total across a whole room is not the measure. |
| **8. Rebase before you edit, and test before you hand over.** | Edits to existing rows must be written against today's master, with numbers stored as numbers. Run the §8 audit and a bot trial on every new room before handing a draft over. |
| **6. A new person needs three rows.** | Opponents (or Visitors) for the game, an **Assets** row per expression for the art team, and the name spelt identically in both (§7). |

After any edit: `python3 tools/export_data.py` (must end "No errors"), then `tools/verify.sh`. Edit the workbook in Excel, or by raw XML (never an openpyxl save; it corrupts cached formulas).

---

## 1. How the systems connect

```
           Stages row ──► who can be drawn (Opponents "Stage" cell)
                │                 │
                ▼                 ▼
     Affinity (suit x stage)   opponent suits ──► which Opponent Cues they speak
                │
                ▼
   card played ── answers the turn's question (room pool + Stage Questions)
                │          │
                │          └─ Theme ─► Question Themes ─► pleases / annoys organisations
                ▼                                              │
     support bar moves                                         ▼
     (win / lose the stage)                     organisation standing (0-100, starts 30)
                │                                   │        │         │
                ▼                                   ▼        ▼         ▼
     stage win/loss deltas             backing (needs 60)  party   Floor Vote
     (four meta values, XP)            + modifier triggers opinion  influence gate
                                                           (Party      │
                                                           Standing)   ▼
                                                                bill passes / fails
                                                                       │
                                                                       ▼
                                                     statute book ─► Law Effects ─► standing,
                                                                                    meta, Funds
```

The loop that matters for content: **questions move organisations; organisations move parties and the vote; votes become laws; laws move organisations again.** A question you write for a committee is not flavour only; its Theme changes who likes the player for the rest of the run.

---

## 2. Mechanics reference

### 2.1 A stage's shape (Stages tab)

| Column | What it does | Values in use |
|---|---|---|
| **Mode** | Which screen | `Combat` (card battle), `Non-combat` (visitor choices, ST07/ST22), `Vote` (ST23 only) |
| **Bar Model** | How winning is measured | `Shared_pool` (both sides draw from one pool, Undecided in the middle; most rooms), `Single` (one tone bar judged after the last question; press conference), `Survival` (stay at or above the line every turn; TV debate) |
| **Energy Mode / Energy Pool** | Energy per turn, or one budget for the whole stage | `per_turn` (default), `pool` (ST08, ST18, ST19, ST20) |
| **Sequence Mode** | Several opponents, one after another | `single` (one opponent), `reset` (committee: everything restarts per opponent), `stream` (Town Hall: clock and gaffes carry, energy refills), `continuous` (floor debate: everything carries) |
| **Opponent Count** | How many are drawn | a number or `2-4`. For Combat stages, more than 1 needs a Sequence Mode other than `single` (a test enforces this). On Non-combat rooms (ST07, ST22) it counts visitors, not opponents |
| **Question Pool** | Which room tab it asks from | `press_conference`, `town_hall`, `media_ambush`, `lobbyist_meeting`, `policy_study`, or blank. Blank means the built-in default for that stage (ST04, ST05, ST19, ST20, ST21 each have one, so ST05's blank cell still asks the Town Hall questions); a blank on any other stage asks only its own Stage Questions, if any |
| **% Press … % Other** | Who is watching | fractions summing to 1. Trigger audience modifiers and cards aimed at a segment |
| **Win/Loss Δ** | What the stage pays or costs | signed numbers; blank = 0 |
| **Loss Ends Level** | Does a loss end the level | blank = Yes |
| **Reveal In Briefing** | Is the stage shown before the level | `No` = a surprise (Media Ambush) |
| **Show Transition** | A scene before this stage when it is **not the first stage of its level** | uses the Transition Cast/Backgrounds/Dialogue tabs. Set it only on new or unique rooms unless Cameron asks (§2.7) |

The 20 battle (Combat) rooms today (the workbook has 23 stages in all: these 20, the two Non-combat rooms ST07 and ST22, and the Floor Vote ST23):

| Family | Stages | Shape |
|---|---|---|
| Committees | ST01, ST09–ST18 | Shared pool, `reset`, 2–4 members, ask only Stage Questions (one bag for the whole stage, §2.7) |
| Floor debate | ST02 | 101 seats, win at 51, `continuous` |
| Party caucus / steering | ST03, ST08 | Shared pool; ST08 is a pool-energy single fight |
| Press | ST04, ST19 | ST04 single tone bar; ST19 surprise ambush, `continuous`, pool energy, gaffe limit 2 |
| Public | ST05 (Town Hall), ST06 (TV debate) | ST05 `stream` of constituents; ST06 survival |
| Interest groups | ST20 (Lobbyist), ST21 (Policy Study) | room question pools |
| Non-combat / vote | ST07, ST22 / ST23 | not card battles |

### 2.2 Suits and the room (Affinity tab)

Every Combat stage needs a column in **Affinity**: a multiplier per suit on the card's support gained and opponent support taken (guard, draw and gaffes are never scaled). **House style:** each room favours two suits (1.5 and 1.3), punishes two (0.5 and 0.7) and leaves two at 1.0. Pick them from what the room rewards in real politics. The table gives **examples only** (the Affinity tab is the full grid; copy a similar room's column and adjust):

| Suit | Rewarded where… | Punished where… |
|---|---|---|
| Earnest | accountability matters: committees on the environment, administration and Assembly rules; Town Hall; Policy Study | spectacle and slipperiness pay: TV, ambush, lobbying, finance, construction |
| Emotional | stakes are human: ethics, agriculture, ambush, floor, press, Town Hall, TV, war | procedure and money: finance, foreign affairs, administration, lobbying, Policy Study, caucus |
| Appeal | unity and favours: caucus, floor, press, lobbying, Cabinet | adversarial scrutiny: ethics, construction |
| Data Driven | the file decides: finance, administration, Assembly rules, Cabinet | crowds and cameras: TV, press, caucus |
| Divisive | loyalty is the currency: caucus, steering, war, agriculture | consensus rooms: Town Hall, Assembly rules, Cabinet |
| Duplicitous | deals happen quietly: construction, finance, lobbying | where you are on the record: floor, committees |

### 2.3 Questions

| Grade | The answering card | The organisations behind the Theme |
|---|---|---|
| **S** Strong | ×1.3 this round | pleased **+5**; organisations in the theme's **Annoys** cell set back **−3** |
| **M** Medium | unchanged | nothing |
| **W** Weak | ×0.7 this round | the *pleased* organisations are annoyed **−1** |

The question multiplier stacks with the room's affinity. Per organisation, one stage's net change is capped at ±5. Grades are per suit. **The room tabs' own footers set the rule: at least 2 S and at most 2 W per question, no time references, no assumed past events, and no specific policy area** (a room question has to fit any audience). A W on at least one suit is good practice, because it makes the choice of suit matter, but the footers do not require it (legal either way). **Stage Questions are exempt from "no specific policy area"**: being specific to a room's business is their point, and they should still keep 2 or more S and 2 or fewer W. Every existing question has at least 2 S. About 37 have no W, mostly in the Press, Ambush and Lobbyist tabs: leave them, but give a new question one. Do not regrade existing rows without Cameron. A question whose Theme no row maps pleases nobody (an export warning).

**Spread targets (from the 272 room-tab questions).** Share of questions graded Strong / Weak per suit: Earnest 54 / 14, Emotional 38 / 27, Appeal 29 / 20, Data Driven 42 / 19, Divisive 35 / 38, Duplicitous 35 / 24. A batch should stay within about 15 points of each figure. Hard limits: no suit Weak on 0% of a batch, no suit Strong on more than 60%, and every suit Strong on at least 20%. A batch where one suit is nearly always Strong makes that suit the only sensible answer for every protagonist (the 2026-10-13 draft had Earnest Strong on 90% and Duplicitous on 5%). Compute the table for every batch and put it in the hand-over notes.

**Grading by suit.** Ask "which register actually answers this?":
- Earnest wins when the question asks for accountability or a plain commitment.
- Emotional wins on people and harm; Appeal on unity, belonging and favours.
- Data Driven wins on cost, evidence and yes/no.
- Divisive wins on loyalty, sides and in-group versus out-group (not mere rudeness).
- Duplicitous wins only where deflection is the smart move (a trap question, a deal best left vague). It is usually Weak in public rooms.

### 2.4 Organisations and standing

| Number | Value | Source |
|---|---|---|
| Start | 30 (or the Boosters tab's Starting Standing) | `booster_standing.json` |
| Needed to buy that organisation's backing | 60 | `required_standing` |
| An organisation-triggered backing (BOxx trigger) is on while standing ≥ its Trigger min % | 10–30 today | Modifiers tab |
| Arguing an opponent out of the room costs their Affiliation | −2 | `instant_win_penalty` |

Standing also feeds **party opinion**: the Party Standing tab weights organisations per party (`OWN` = the player's own party; negative weight = a rival), blended 50/50 with that party's direct number. Your own party's blended opinion is what triggers the Steering Committee check-in, the funding freeze and free Party Backing. Standing also passes the **Floor Vote influence gate** (Vote Influence Triggers: every enabled row must clear its threshold, some scoped to parties).

### 2.5 Opponents and how they speak

An opponent row: **Affiliation** (a BOxx), **Party** (a Parties name or N/A), **Role/Title**, **Stage** (every STxx they can be drawn for), **Suit 1–3**, and attack/gain/block ranges (`min-max`, or one number for a fixed amount; `0` means never; a stronger opponent has higher ranges). Opponents for a stage are drawn at random from everyone listing it. A suit may repeat across Suit 1–3 (19 opponents do); that is deliberate and simply weights the suit.

**What they say on their turn** (Opponent Cues). The game picks a suit (Suit 1 55%, Suit 2 30%, Suit 3 10%, any other 5%) and the verb of their move (`attack`, `gain`, `block`), then looks up, most specific first:
1. a row naming this opponent and this stage;
2. a row naming this opponent, any stage;
3. a general row (no opponent) for that suit and verb, this stage;
4. a general row for that suit and verb, any stage.

**Pooling and shadowing (verified in the code).** Rows that resolve to the same lookup key are **pooled** (their lines join one list). A more specific tier **replaces** all less specific ones: it does not add to them. So a stage-scoped Player Cue row with a verb hides the card's own Flavor Text and every any-stage row for that suit and verb. An Opponent Cue row that names an opponent ignores its Suit column and applies to every suit; with no Stage ID it follows that character into every room, so leave Stage ID blank only for party leaders.

**What the player says** (Player Cues, then the card's own Flavor Text): this stage and verb, this stage any verb, any stage this verb, any stage any verb, then the card's five lines. The verb is what the card did: `attack` (took the opponent's support), `gain` (won support), `block` (only banked guard).

### 2.6 Bills, votes and laws

A level names its bill (`BIxx`) in a stage slot. Floor Vote Party Positions give each party's Yes/No/Abstain split (must add to that party's seats; the exporter warns) and Disposition. The player's seat sits with their party's majority unless they vote otherwise. A strong player can swing other parties (resistance per party). **A bill passes only when Yes reaches a majority of the whole house (51 of 101); abstentions count against it.** So a bill whose splits give Yes under 51 fails by default, and its Vote Influence Cue must be a "Flipped to Pass" line (and a bill that passes by default needs "Flipped to Fail"). Every vote is recorded in the statute book. **Law Effects** rows (per bill, per outcome) apply once or at the end of every later level. House rule (checked by the playtest rubric, D8): **every organisation is pleased by at least one bill outcome and annoyed by at least one.**

### 2.7 How the engine reads content (so specific content is sized well)

**Ground rule (Cameron, 2026-10-13): an expansion adds content, never mechanics, and every room, existing or new, may draw on the base (generic) content and on stage-specific content where it applies.** The engine reads the most specific tier that has a line and falls back to the generic content, so writing stage-specific rows is how a room gets its own voice, and a cell left empty keeps the generic. Do not ask for code changes; size the data so the result plays well. The rows below describe the read order and the sizes that work.

| Behaviour | What happens | How to size the content |
|---|---|---|
| **Questions per stage** | A stage asks `questions_per_turn × turn_limit` questions **in total**, drawn once into one bag (a `reset` room does not refill it per opponent). Stage Questions are dealt before the room's pool. | A room with no pool asks only its Stage Questions: write from 3 (the committee norm) up to turn_limit. A room that has a Question Pool (ST04, ST05, ST19, ST20, ST21, and new rooms in the Town Hall or Policy Study family) should keep its pool in play: write at most a third of turn_limit as Stage Questions, so the generic pool still supplies the rest. Six Stage Questions on a six-turn press conference would remove the whole 34-question press pool. |
| **Turning questions on in a room** | The first Stage Question on a room that asked none switches on the Strong/Weak multiplier and organisation pleasing there. That changes its difficulty (ST18 went from 40% to 100% bot wins; ST06 was tuned without questions). | Allowed when the expansion intends it (ST02, ST03, ST06, ST08 ask none today). Run `PLAYTEST_STAGE_TRIAL` before and after and put the win rates in the hand-over. |
| **Player Cues** | Each suit and verb reads one pool, from the most specific tier that has any line: this stage and verb, this stage any verb, any stage and verb, any stage. Card Flavor Text (45 lines per suit) is used only when no tier has one, so a stage row for a suit and verb replaces Flavor Text for that suit and verb in that room. Rows at the same tier pool. | Any room may have stage rows. For a cell you cover, write at least two rows (10 lines), so variety is no thinner than the universal Opponent Cue default; cover attack, gain and block (or a blank-verb row). A cell you leave empty simply keeps the card's own lines. Committees: append a new committee-style room's STxx to the Stage ID cells of PL01–PL18 so it pools with them. |
| **Opponent Cues** | Order: this opponent in this stage, this opponent anywhere, the suit's pool for this stage, the suit's pool anywhere. A stage pool replaces the any-stage pool for that suit and verb. An opponent-scoped row ignores its Suit column. | Any room may have stage pools. Write at least two rows (10 lines) per suit and verb you cover, since the universal pool is 10. Opponent-scoped rows must carry a Stage ID unless the character is a party leader. |
| **Transitions** | Plays before a stage that is **not first in its level**, shows exactly one exchange, and the banner auto-advances after at most 4 seconds (about 110 characters). A speaker is a specific named staff member whether or not the player hired them. | Any room may turn Show Transition on. Keep a character line to about 110 characters (18 words) and the reply to 8 words, so it can be read in time. A room that fires often (ST03 fires 45 times across the levels) needs at least 3 variants. Describe the feel in-universe, never numbers. A room that is only ever a level's first slot never shows its transition. |
| **A bill passes on Yes of 51 or more** (half the house, rounded up) | Abstentions count against it. | Compute each draft bill's default outcome and make its Vote Influence Cue the opposite direction (Pass cue for a bill that fails by default). |
| **Tab formulas** | Stages' Favored suit and Segment check are formulas that read the Affinity tab up to column V. | Paste formulas, not values, and extend the Affinity range to cover new columns. |


---

## 3. Recipe: a new unique stage

### 3.0 Start from a family template (the current norm)

Pick the nearest family, copy its row, and change only the name, audience mix, affinity, and reward within the family's range. Do not invent a new shape. Values are from the live Stages tab.

| Family | Existing rooms | Bar unit / value | Bar max | Threshold | Turns | Energy | Hand | Gaffe limit | Start (you / opp) | Sequence · opponents | Question source | Rewards (win) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Committee / hearing** | ST09–ST17 (ST01 and ST18 are variants) | Favourability / Percentage | 100 | 51–70 | 10 | 3–5 | 5 | 3–7 | 20–35 / 25–40 | `reset` · 2–4 | Stage Questions only (3) | Jiban 0–3, Yen 10k–50k, Rep 1–5, XP 30–100 |
| **Town Hall-like** (visits, rallies, town meetings) | ST05 | Appeasement / Percentage | 100 | 60 | 17 | 3 | 5 | 6 | 15 / 20 | `stream` · 3 | `town_hall` pool (blank cell uses it) | Jiban 5, Yen 35k, Rep 1, XP 50 |
| **Policy Study-like** (seminars) | ST21 | Consensus / Percentage | 50 | 35 | 10 | 5 | 5 | 10 | 1 / 10 | `stream` · 2 | `policy_study` pool | Jiban 1, Yen 15k, Rep 1, XP 70 |
| **Party caucus** | ST03 | Support / Percentage | 100 | 60 | 10 | 3 | 5 | 5 | 20 / 40 | `continuous` · 2, Own Party Only | none | Jiban 0, Yen 10k, Rep 1, XP 70 |

Rules: the bar unit and Value for a family are fixed (a hearing says Favourability, a town-hall room says Appeasement); Reveal In Briefing, Loss Ends Level and Own Party Only stay as in the family row; vary the numbers only inside the ranges above. A room outside every family is a new *kind* of room and is §9's business.

Example brief: "a Budget Committee hearing", "a Prefectural Assembly visit", "a Labour rally".

| # | Tab | Do | Required? |
|---|---|---|---|
| 1 | **Stages** | New row, next STxx. Set Mode, Bar Model, energy, Sequence Mode/Opponent Count, threshold, turns, gaffe limit, audience %, win/loss deltas. Copy the closest family row (§3.0) and change from there, staying inside the family's range. Within that range, vary hand, energy, gaffe limit and starting numbers by the room's difficulty rather than giving every room identical values | Yes |
| 2 | **Affinity** | Add a column for the new STxx: two up (1.5/1.3), two down (0.5/0.7), two at 1.0 | Yes for Combat (export error otherwise) |
| 3 | **Opponents** | Add the STxx to the Stage cell of everyone who belongs in that room, or add new opponents (placeholder names only unless Cameron supplies them) | Yes, at least Opponent Count of them |
| 4 | **Question Pool** column | Point at an existing room tab if it should ask those questions, or leave blank | Optional |
| 4b | **Own Party Only** | Yes for a room of the player's own party only | Optional |
| 5 | **Stage Questions** | Rows with this STxx: the room's own questions, asked first. Count by the §2.7 rule | Optional, but this is what makes a room unique. Count by the §2.7 rule (a pooled room keeps its pool in play) |
| 6 | **Question Themes** | A row for every new Theme, Organisation (and optional Annoys) filled, Why "Draft…" | Yes for every theme you use |
| 7 | **Opponent Cues / Player Cues** | Stage-scoped rows (Stage ID = the STxx), sized by §2.7. A committee-style room may also be appended to PL01–PL18's Stage ID cells | Optional |
| 8 | **Levels** | Put the STxx in a level's stage slot (or make a new level). Every new room must appear in at least one level. Tier, cooldown and XP costs are numbers, not text | Yes, or nobody plays it |
| 9 | **Transition Cast/Dialogue** + Show Transition | Optional scene before the room when it is not a level's first stage; sized by §2.7 | Optional |
| 10 | Art | `assets/backgrounds/{STxx}.png` | Optional (a labelled placeholder shows) |

**Balance check.** A room is fair when a decent deck can win it about half to most of the time. Run the bot on it: `PLAYTEST_PROTAGONIST=PC02 PLAYTEST_STAGE_TRIAL="ST24:40" .tools/godot --headless --path . tools/playtest_optimal.tscn`. Note that questions make a room easier (Strong answers ×1.3): ST18 went from 40% to 100% bot wins once it asked questions.

---

## 4. Recipe: questions for a stage

1. **Decide what the room is about**: its business, not its mood. A finance committee asks about costs, audits and taxes; a rally asks about loyalty and the fight.
2. **Pick Themes from organisations who care**: check Question Themes for an existing theme first (re-use keeps the mapping consistent). **Type the Theme exactly as the Question Themes row spells it, capital letters included**: the join is case-sensitive (six themes exist as separate rows differing only in case, for that reason); add a new theme only for a genuinely new subject. A theme may please 1–5 organisations (`BO05; BO23`) and set back others (Annoys) when a strong answer on it is a political cost to someone.
3. **Write the question** to its scope (§5).
4. **Grade six suits** (§2.3), reading the room's affinity: grade the room's favoured suits Strong on some questions and Weak on others, or the room becomes trivially "always play Data Driven".
5. **Keep pools balanced**: a committee asks one question a turn and draws from its own rows first, so three to six per committee is enough. Spread themes so one room does not please a single organisation every turn.
6. **Check the spread**: run the §2.3 table over the batch (Strong and Weak share per suit). Fix a lopsided batch before continuing.
7. **Check coverage**: every organisation should have at least 15 questions across the game (the current floor), and the How to Play suit table (HT21) reflects which suits please whom, recomputed from your grades automatically.

---

## 5. Writing to scope: generic versus specific

**The rule: the wider a line can appear, the less it may assume.**

| Scope | Where it can appear | May mention | Must not |
|---|---|---|---|
| **Universal** (Flavor Text; Player Cues and Opponent Cues with no Stage ID or Opponent ID; room question tabs used by several stages) | Any room, any opponent, any turn | Only what is true everywhere: you, them, the people, the record, the choice | name a venue, audience, party, post, date or past event; reply to the last move |
| **Stage-scoped** (Stage ID filled; Stage Questions) | That room only, any opponent eligible there | The room's business and audience: "this committee", the budget, the harbour, the camera | name a party or person (anyone eligible may say or ask it) |
| **Opponent-scoped** (Opponent ID filled) | That person only | Their party's line, their organisation's interest, their Role/Title | invent history or relationships Cameron has not written |

**The five Tone Guide rules** apply to every universal line and are good practice everywhere:
1. Nine words or fewer (cues).
2. Universal setting, with no venue-specific address.
3. No time references (now, today, again, still…).
4. No invented history (votes, favours, meetings).
5. Not a reply to what the opponent just did.

Stage-scoped lines may break rule 2 for their own room only; nothing should break 3–5.

**Suit voice** (from the Tone Guide):

| Suit | Register | Example |
|---|---|---|
| Earnest | plain, first person, short | "Judge me by my record." |
| Emotional | exclamations, faces, families | "I will not be shouted down!" |
| Appeal | we, us, together, favours | "One good turn deserves another." |
| Data Driven | numbers, yes/no, no exclamations | "Which is it? You can't have both." |
| Divisive | us versus them, sides, labels | "Pick a side. The voters are watching." |
| Duplicitous | hedges, passive voice, ellipses | "We will consider that positively." |

**Party and affiliation voice, for opponent-scoped lines only.** These are leanings from the Party Standing draft (Cameron's to correct), not new canon. Write the interest, not a slogan the party never said.

| Party | Leans toward (organisations it weights) | A line in its voice cares about… |
|---|---|---|
| Butsutou (PT01) | families, temples, care and welfare, neighbourhoods | care, compassion, the vulnerable |
| Yezo Heritage Party (PT02) | Ainu councils, fisheries, artisans | heritage, language, land and sea |
| Frontier Party (PT03) | farmers, fisheries, rural councils, mayors, kōenkai | the regions over the cities |
| Five Point Independents (PT04) | media, consumers, urban voters, students | the citizen against the machine |
| Keizaijiyuutou (PT05) | business, finance, taxpayers, innovation | growth, markets, the bill's cost |
| Country Initiative (PT06) | tradition, veterans, shrines, families | order, custom, the nation |

An organisation (Affiliation) speaks its own interest: a Fisheries Cooperative member about quotas and harbours, a journalist (BO08) about answers and accountability, a lobbyist about access and favours.

**Transition style.** One staff voice, one short briefing (18 words or fewer), then the player's short reply. Convey the room's feel (a short clock, a hostile crowd, a forgiving panel) in plain words. Never quote energy, turns, gaffe limits, thresholds or percentages. Do not claim facts about an organisation or a party in a briefing that is stage-scoped to a base room.

**Examples**

| Line | Scope | Verdict |
|---|---|---|
| "Answer the question, Minister." | universal cue | No: names a post |
| "Yes or no? It is a simple question." | universal cue | Good |
| "This committee deserves the figures, not adjectives." | ST16 Player Cue | Good: stage-scoped |
| "Your party abandoned the farmers." | general Opponent Cue | No: assumes the player's party and history |
| "The regions feed this country. Remember that." | Opponent Cue on a Frontier Party member | Good: their interest, no history |
| "Who audits the auditors when the money goes missing?" | Stage Question, ST16, theme Audit | Good |
| "As a Keizaijiyuutou member I ask…" | any question | No: the asker is assigned, not chosen (§6) |

---

## 6. Who asks, and limiting it by party

A question's asker is picked from **the people the room seats**: everyone whose Opponents-tab Stage cell lists that stage (for Stage Questions, the stages the row names; for a room tab, the room using that pool). The exporter assigns one in rotation, and the game swaps in someone else if that person is not in the room this time.

**Asked By Party** (optional column on all six question tabs, 2026-10-12) limits who may ask:

| Cell | Who may ask |
|---|---|
| blank | anyone the room seats |
| `PT05` | only Keizaijiyuutou members the room seats |
| `PT03; PT06` | Frontier Party or Country Initiative members |
| `OWN` | members of the **player's own** party (settled in the game, since it depends on the protagonist) |

Rules:
- If nobody of the named parties sits in the room, the question is **not asked there** (it never goes into the wrong mouth). For a named PTxx, the export reports this as an error so you notice; for `OWN` it can only be known in play.
- Once a question is party-limited you may write it **in that party's voice** (§5), the same freedom as an opponent-scoped cue.
- Who the room seats is decided on the Opponents tab (Stage cell) and, for the caucus, by **Own Party Only** (below).

| Stage | Who the room seats today |
|---|---|
| ST04 Press, ST19 Ambush | 8 journalists, all National Media (BO08) |
| ST05 Town Hall | constituents of several organisations (BO18, BO11, BO06, BO12 and BO03); no party |
| ST20 Lobbyist | lobbyists from several organisations; no party |
| ST03 Party Caucus | **only the player's own party** (Own Party Only = Yes) |
| Committees, ST02, ST08, ST21 | MPs of several parties: use Asked By Party for any party voice |

**Own Party Only** (Stages tab, Yes/No, blank = No): the room seats only MPs of the player's own party. It is set on the Party Caucus (ST03). For it to work, each protagonist's party needs at least as many MPs listing the room as its Opponent Count: today Frontier Party has 2 (OP101, OP17), Keizaijiyuutou 2, Country Initiative 2. If a party has nobody there, the room falls back to everyone (with a warning in the log). A caucus question written for "your party" should carry `OWN` in Asked By Party.

## 7. Other content types, briefly

| Tab | Unit | Notes |
|---|---|---|
| **Visitors / Visitor Questions** (ST07, ST22) | a person, and a 4-choice question with one right answer. Spread the right answer across A to D, and do not make it the longest choice (it was in 33 of 35 drafted) | Reward/Penalty use the Grants format (`BO05 +1; SG02 -1`). Right/wrong replies are spoken; reactions are short stage directions |
| **Level Intro Cues / Thoughts** | a staff member's line about a level; the player's own thought on a bill level | Specific to the level, so may name the bill's subject |
| **Transition Dialogue** | a two-line exchange, character then player | Stage-scoped or any-stage; the character must be in Transition Cast |
| **Vote Influence Cues** | the line when the player's influence flips a bill | Per bill and direction (passed/failed); may name the bill |
| **Law Effects** | what a passed or failed bill does | Beneficiaries +2/+3, those it hurts −2; failed rows mirror smaller. Keep D8 (every organisation pleased once and annoyed once) |
| **Assets** | one row per file the art team must draw: Asset ID, Category, Name, Expression, File Name, Folder, Size, Drawn (Yes/No) | Add rows whenever you add an opponent, visitor, staff member or protagonist: three expressions for a visitor (neutral, gaining, damaged), six for an opponent (neutral, attacking, guarding, gaining, damaged, defeated). **Name must match the Opponents/Visitors/Player tab exactly** (given name first); set Drawn to No |
| **Office Notices / Ticker** | Office flavour lines under conditions (staff, meta, `always`, or `law` passed/failed) | `{player}` fills the protagonist's name in the ticker |

---

## 8. Before you hand it over

1. `python3 tools/export_data.py`: the last line must say **No errors**. Read the warnings (an unmapped theme, seats not adding up).
2. If you reworded existing Text rows on purpose: `python3 tools/export_data.py --accept-wording`.
3. `tools/verify.sh`: all checks pass.
4. For anything touching organisations, bills or votes: `xvfb-run .tools/godot --path . tools/rubric_playtest.tscn` should still score full marks.
5. A new room: run the bot's stage trial (§3) and note the win rate for Cameron.
6. Mark every new row as a draft where the tab has a Why or Note column.
7. **Rebase.** For every row under Edits to Existing Rows, re-read the Current value from today's master and confirm it matches. A draft written against an older master can silently undo a later fix (the 2026-10-13 draft would have removed OP30's ST08 seat).
8. **Types.** Every number is a number cell (tier, cooldown, XP costs, thresholds). Text-typed numbers are a defect.
9. **Audit table.** Hand over: ID ranges and collisions; seat totals per bill; default outcome against cue direction; Strong and Weak share per suit; questions per room against turn_limit; Player and Opponent Cue lines per (suit, verb) cell; transition word counts and how often each fires across the levels; rooms with no level; every new room's seated-opponent count against its Opponent Count.
10. **Bot trial.** Run `PLAYTEST_STAGE_TRIAL` on every new room and on every existing room whose questions or cues changed, and report the win rates.
11. **Canon calls.** List every new place, institution, or real-world analogue in a Decisions tab for Cameron. Approved on 2026-10-13: the Aomori, Hokkaido and Chishima assemblies and the people seated in them (existing MPs and organisation members, with OP106–OP108 and OP125 at the rallies); do not re-ask about those.
7. Check names agree across tabs (Assets against Opponents, Visitors, Player and **Shop**: an item-icon row must use the Shop tab's Item ID, name and Icon cell, so rebuild those rows when the Shop tab is renumbered) and that cue lines pass the Tone Guide's five rules (a quick read for time words such as now, again, still, already, always, never).
8. Re-read the README tab: if you changed a count (stages, levels, organisations, themes), update its tab guide. It is Cameron's overview, so keep it true.

## 9. When the workbook is not enough (ask first)

These need code, so propose them to Cameron rather than working around them:
- a new **kind** of room (a new Mode or Bar Model);
- a new **room question tab** (a sixth pool beside the five); Stage Questions usually does the job instead;
- any new column a script must read.

## 10. Pitfalls seen in review (2026-10-13)

A 21-room, 6-bill draft was audited against the live workbook and code. What it got right: matching headers, no ID collisions, exact seat totals, correct bill outcomes against the 51-of-101 rule, valid references, clean cue length and tone. What it got wrong is now rules above; this table is the quick map.

| Problem in the draft | Rule that now prevents it |
|---|---|
| An edit's "Current" value was stale, so it would remove ST08 from OP30 | §8 item 7 |
| Four levels had tier, cooldown and XP costs as text | §3 step 8, §8 item 8 |
| 6 Stage Questions on a 6-turn press conference, hiding its 34-question pool | §2.7 questions per stage |
| Questions switched on for ST02, ST03, ST06 and ST08 with no difficulty check | §2.7 turning questions on (bot trial before and after) |
| Earnest Strong on 90% of questions, Duplicitous on 5% | §2.3 spread targets |
| Stage cue pools of 5 lines per suit and verb, thinner than the 10-line universal pool | §2.7 Player Cues and Opponent Cues (at least two rows per cell) |
| Transition lines of 43 words on a 4-second banner, one fixed line per stage | §2.7 transitions |
| One fixed 43-word transition per room, firing 302 times across the levels (ST03 alone 45) | §2.7 transitions (short lines, variants) |
| Booster Rally (ST37) used by no level | §3 step 8 |
| Every new room had the same hand, energy and gaffe numbers instead of a family's range | §3.0, §3 step 1 |
| Favored suit pasted as values, with formulas stopping at Affinity column V | §2.7 tab formulas |
| The correct visitor answer was the longest choice 94% of the time | §7 |

