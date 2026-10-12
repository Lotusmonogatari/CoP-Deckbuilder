# Expanding the workbook: a guide for an assistant

For an assistant (human or AI) adding content to `design/CoP_Starter_Card_Stage_Data.xlsx`: new stages, questions tied to them, spoken cues, opponents, bills and their effects. It explains how the pieces connect, what each number does to play, and how to phrase writing so it fits where it can appear.

Read with: `design/EDITING_TEXT.md` (tab-by-tab editing), `design/CONTENT_PROMPT.md` (a batch-drafting prompt), the **Tone Guide** tab, and the header notes on every column (hover a header cell in Excel). Written 2026-10-12 against the code as it stands.

---

## Executive summary

| If you remember five things | |
|---|---|
| **1. Everything is a draft for Cameron.** | Write it, mark it ("Draft YYYY-MM-DD" in a Why/Note cell where there is one), never decide canon: no new named characters, parties, committees or political positions he has not written. |
| **2. Rooms are rows, not code.** | A new stage is a Stages row + an Affinity column + opponents who list it + (optionally) its own questions and cues. No programming, unless you need a new *kind* of room (see §9). |
| **3. A question does three jobs.** | Its suit grades scale the card that answers it (×1.3 Strong, ×0.7 Weak), its Theme decides which organisations are pleased or set back, and those standings feed backing, party opinion and the Floor Vote influence gate. |
| **4. Scope decides wording.** | The wider a line can appear, the more generic it must be. Any-stage lines obey all five Tone Guide rules; stage-scoped lines may name the room's business; lines scoped to one opponent may carry that person's party or organisation voice. |
| **5. Who asks a question is picked from the room.** | The asker is someone the room seats. Use the **Asked By Party** column to limit a question to one or more parties (or `OWN`, the player's own) before you write it in a party voice (§6). |

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
| **Opponent Count** | How many are drawn | a number or `2-4`. More than 1 needs a Sequence Mode other than `single` (a test enforces this) |
| **Question Pool** | Which room tab it asks from | `press_conference`, `town_hall`, `media_ambush`, `lobbyist_meeting`, `policy_study`, or blank (asks only its own Stage Questions, if any) |
| **% Press … % Other** | Who is watching | fractions summing to 1. Trigger audience modifiers and cards aimed at a segment |
| **Win/Loss Δ** | What the stage pays or costs | signed numbers; blank = 0 |
| **Loss Ends Level** | Does a loss end the level | blank = Yes |
| **Reveal In Briefing** | Is the stage shown before the level | `No` = a surprise (Media Ambush) |
| **Show Transition** | A between-stages scene | uses the Transition Cast/Backgrounds/Dialogue tabs |

The 22 battle rooms today:

| Family | Stages | Shape |
|---|---|---|
| Committees | ST01, ST09–ST18 | Shared pool, `reset`, 2–4 members, ask only Stage Questions |
| Floor debate | ST02 | 101 seats, win at 51, `continuous` |
| Party caucus / steering | ST03, ST08 | Shared pool; ST08 is a pool-energy single fight |
| Press | ST04, ST19 | ST04 single tone bar; ST19 surprise ambush, `continuous`, pool energy, gaffe limit 2 |
| Public | ST05 (Town Hall), ST06 (TV debate) | ST05 `stream` of constituents; ST06 survival |
| Interest groups | ST20 (Lobbyist), ST21 (Policy Study) | room question pools |
| Non-combat / vote | ST07, ST22 / ST23 | not card battles |

### 2.2 Suits and the room (Affinity tab)

Every Combat stage needs a column in **Affinity**: a multiplier per suit on the card's support gained and opponent support taken (guard, draw and gaffes are never scaled). **House style:** each room favours two suits (1.5 and 1.3), punishes two (0.5 and 0.7) and leaves two at 1.0. Pick them from what the room rewards in real politics:

| Suit | Rewarded where… | Punished where… |
|---|---|---|
| Earnest | accountability matters: committees on ethics, environment, administration; Town Hall | spectacle and slipperiness pay: TV, ambush, lobbying |
| Emotional | stakes are human: floor, press, Town Hall, agriculture, war | procedure and money: finance, foreign affairs, administration |
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

The question multiplier stacks with the room's affinity. Per organisation, one stage's net change is capped at ±5. Grades are per suit; give every question **at least one S and at least one W**, and usually two of each, so the choice matters. A question whose Theme no row maps pleases nobody (an export warning).

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

An opponent row: **Affiliation** (a BOxx), **Party** (a Parties name or N/A), **Role/Title**, **Stage** (every STxx they can be drawn for), **Suit 1–3**, and attack/gain/block ranges (`min-max`; a stronger opponent has higher ranges). Opponents for a stage are drawn at random from everyone listing it.

**What they say on their turn** (Opponent Cues). The game picks a suit (Suit 1 55%, Suit 2 30%, Suit 3 10%, any other 5%) and the verb of their move (`attack`, `gain`, `block`), then looks up, most specific first:
1. a row naming this opponent and this stage;
2. a row naming this opponent, any stage;
3. a general row (no opponent) for that suit and verb, this stage;
4. a general row for that suit and verb, any stage.

**What the player says** (Player Cues, then the card's own Flavor Text): this stage and verb, this stage any verb, any stage this verb, any stage any verb, then the card's five lines. The verb is what the card did: `attack` (took the opponent's support), `gain` (won support), `block` (only banked guard).

### 2.6 Bills, votes and laws

A level names its bill (`BIxx`) in a stage slot. Floor Vote Party Positions give each party's Yes/No/Abstain split (must add to that party's seats; the exporter warns) and Disposition. The player's seat sits with their party's majority unless they vote otherwise. A strong player can swing other parties (resistance per party). Every vote is recorded in the statute book. **Law Effects** rows (per bill, per outcome) apply once or at the end of every later level. House rule (checked by the playtest rubric, D8): **every organisation is pleased by at least one bill outcome and annoyed by at least one.**

---

## 3. Recipe: a new unique stage

Example brief: "a Budget Committee hearing", "a Prefectural Assembly visit", "a Labour rally".

| # | Tab | Do | Required? |
|---|---|---|---|
| 1 | **Stages** | New row, next STxx. Set Mode, Bar Model, energy, Sequence Mode/Opponent Count, threshold, turns, gaffe limit, audience %, win/loss deltas. Copy the closest existing room and change from there | Yes |
| 2 | **Affinity** | Add a column for the new STxx: two up (1.5/1.3), two down (0.5/0.7), two at 1.0 | Yes for Combat (export error otherwise) |
| 3 | **Opponents** | Add the STxx to the Stage cell of everyone who belongs in that room, or add new opponents (placeholder names only unless Cameron supplies them) | Yes, at least Opponent Count of them |
| 4 | **Question Pool** column | Point at an existing room tab if it should ask those questions, or leave blank | Optional |
| 4b | **Own Party Only** | Yes for a room of the player's own party only | Optional |
| 5 | **Stage Questions** | Rows with this STxx: the room's own questions, asked first | Optional, but this is what makes a room unique |
| 6 | **Question Themes** | A row for every new Theme, Organisation (and optional Annoys) filled, Why "Draft…" | Yes for every theme you use |
| 7 | **Opponent Cues / Player Cues** | Stage-scoped rows (Stage ID = the STxx) | Optional |
| 8 | **Levels** | Put the STxx in a level's stage slot (or make a new level) | Yes, or nobody plays it |
| 9 | **Transition Cast/Dialogue** + Show Transition | Optional between-stage scene | Optional |
| 10 | Art | `assets/backgrounds/{STxx}.png` | Optional (a labelled placeholder shows) |

**Balance check.** A room is fair when a decent deck can win it about half to most of the time. Run the bot on it: `PLAYTEST_PROTAGONIST=PC02 PLAYTEST_STAGE_TRIAL="ST24:40" .tools/godot --headless --path . tools/playtest_optimal.tscn`. Note that questions make a room easier (Strong answers ×1.3): ST18 went from 40% to 100% bot wins once it asked questions.

---

## 4. Recipe: questions for a stage

1. **Decide what the room is about**: its business, not its mood. A finance committee asks about costs, audits and taxes; a rally asks about loyalty and the fight.
2. **Pick Themes from organisations who care**: check Question Themes for an existing theme first (re-use keeps the mapping consistent); add a new theme only for a genuinely new subject. A theme may please 1–5 organisations (`BO05; BO23`) and set back others (Annoys) when a strong answer on it is a political cost to someone.
3. **Write the question** to its scope (§5).
4. **Grade six suits** (§2.3), reading the room's affinity: grade the room's favoured suits Strong on some questions and Weak on others, or the room becomes trivially "always play Data Driven".
5. **Keep pools balanced**: a committee asks one question a turn and draws from its own rows first, so three to six per committee is enough. Spread themes so one room does not please a single organisation every turn.
6. **Check coverage**: every organisation should have at least 15 questions across the game (the current floor), and the How to Play suit table (HT21) reflects which suits please whom, recomputed from your grades automatically.

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
| ST05 Town Hall | constituents of several organisations (BO18, BO11, BO06, BO12); no party |
| ST20 Lobbyist | lobbyists from several organisations; no party |
| ST03 Party Caucus | **only the player's own party** (Own Party Only = Yes) |
| Committees, ST02, ST08, ST21 | MPs of several parties: use Asked By Party for any party voice |

**Own Party Only** (Stages tab, Yes/No, blank = No): the room seats only MPs of the player's own party. It is set on the Party Caucus (ST03). For it to work, each protagonist's party needs at least as many MPs listing the room as its Opponent Count: today Frontier Party has 2 (OP101, OP17), Keizaijiyuutou 2, Country Initiative 2. If a party has nobody there, the room falls back to everyone (with a warning in the log). A caucus question written for "your party" should carry `OWN` in Asked By Party.

## 7. Other content types, briefly

| Tab | Unit | Notes |
|---|---|---|
| **Visitors / Visitor Questions** (ST07, ST22) | a person, and a 4-choice question with one right answer | Reward/Penalty use the Grants format (`BO05 +1; SG02 -1`). Right/wrong replies are spoken; reactions are short stage directions |
| **Level Intro Cues / Thoughts** | a staff member's line about a level; the player's own thought on a bill level | Specific to the level, so may name the bill's subject |
| **Transition Dialogue** | a two-line exchange, character then player | Stage-scoped or any-stage; the character must be in Transition Cast |
| **Vote Influence Cues** | the line when the player's influence flips a bill | Per bill and direction (passed/failed); may name the bill |
| **Law Effects** | what a passed or failed bill does | Beneficiaries +2/+3, those it hurts −2; failed rows mirror smaller. Keep D8 (every organisation pleased once and annoyed once) |
| **Office Notices / Ticker** | Office flavour lines under conditions (staff, meta, `always`, or `law` passed/failed) | `{player}` fills the protagonist's name in the ticker |

---

## 8. Before you hand it over

1. `python3 tools/export_data.py`: the last line must say **No errors**. Read the warnings (an unmapped theme, seats not adding up).
2. If you reworded existing Text rows on purpose: `python3 tools/export_data.py --accept-wording`.
3. `tools/verify.sh`: all checks pass.
4. For anything touching organisations, bills or votes: `xvfb-run .tools/godot --path . tools/rubric_playtest.tscn` should still score full marks.
5. A new room: run the bot's stage trial (§3) and note the win rate for Cameron.
6. Mark every new row as a draft where the tab has a Why or Note column.

## 9. When the workbook is not enough (ask first)

These need code, so propose them to Cameron rather than working around them:
- a new **kind** of room (a new Mode or Bar Model);
- a new **room question tab** (a sixth pool beside the five); Stage Questions usually does the job instead;
- any new column a script must read.
