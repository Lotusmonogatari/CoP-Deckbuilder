# Coliseum of Parliament — Build Brief for an AI Coding Agent

> **How to use:** This file records the game's design constraints and implementation brief. Its milestone and progress notes are historical; use the checked-in code and data to establish current behavior, and see `README.md` for a concise project snapshot.

---

## 1. Your role

You are the sole programmer on a solo-developer mobile game. The designer (Cameron) is a domain expert in legislatures and politics but **not a programmer**. He will not write or debug code. Your job is to build a working, maintainable Godot 4 project from the design and data below, explain every change in plain English, and never make design or canon decisions on his behalf.

## 2. The game in one paragraph

*Coliseum of Parliament* (CoP) is a **single-player, portrait-mode, turn-based card battler** set in **Yezo**, the fictional parliamentary nation from Cameron's manga. The player is a legislator who fights rhetorical battles (committee hearings, floor debates, party caucuses, press conferences, town halls, TV debates) using a hand of **argument cards**. Each battle is a race to push a **support bar** past a **win threshold** before turns run out or the player's **gaffe meter** fills. Battles ("stages") chain into **modules** (levels), usually built around a single bill. Between battles, persistent **meta-variables** (constituency support, reputation, funds, party support) and **booster organizations** shape the next fight. Progression is linear, with XP checkpoints to unlock and upgrade cards.

## 3. Hard constraints

| Constraint | Requirement |
|---|---|
| Engine | Godot 4 (latest stable 4.x), GDScript only. Keep it a **standard Godot project**: no proprietary SDKs, no paid plugins without asking. If running in Summer Engine, avoid Summer-specific SDK features so the project opens in stock Godot. |
| Platforms | iOS and Android. Portrait only. |
| Resolution | Base 1080 × 2340 (9:19.5). Stretch mode `canvas_items`, aspect `expand`. Respect device safe areas. |
| Data-driven | **All content comes from `/data/*.json`.** Never hardcode card values, stage rules, names, or numbers in scripts. |
| Art | 2D PNGs only (ComiPo! renders + Midjourney + manual edits), loaded by ID from `/assets/`. No 3D, no rigging. Missing art must fall back to an auto-generated placeholder. |
| Text | English is primary everywhere. Japanese appears only as a small, muted accent **next to** English, never alone. Fonts (Cameron, 2026-09-27): cards use **Antaka Brush Display** (`CardView.CARD_FONT`); everything else uses **Antaka Brush Text** (GUST Font License) as the theme font, with **Noto Sans JP** (SIL OFL) as its fallback — Antaka Text is Latin-only (no Japanese, no ō, −, ×, • or →), so those characters come from Noto. Antaka Text has one weight and a small-caps design; size alone carries hierarchy. `tools/build_theme.gd` builds it. |
| Code style | Heavily commented, small files, descriptive names. Pure game rules live separately from UI code. |
| Source control | Git from day one. Commit at the end of each milestone with a plain-English message. |

## 4. Canon rules (Yezo): do not break

- The parliament is **unicameral with 101 seats**; a floor majority is **51**.
- Yezo has **no early elections**, so do not build recall or snap-election mechanics.
- Character names, parties, committees, political positioning, and rhetorical elements come **only** from the data files. Never invent canon characters. Use neutral placeholders such as "Visitor A" when data is missing.
- If any design choice seems to touch canon, **stop and ask**.

## 5. Project structure

```
/data/              JSON exported from the design workbook (source of truth)
/assets/            (the scheme is data/art.json; tools/art_checklist.py lists what is drawn,
                     and the workbook's own "Assets" tab, 2026-09-26, is the fuller production
                     tracker — naming convention, folder, purpose and minimum size per file)
  characters/
    protagonists/   {PC01-PC04}_{expression}.png    e.g. PC01_neutral.png
    opponents/      {OPPONENT_ID}_{expression}.png  e.g. OP03_attacking.png
    staff/          {SF..}_{expression}.png
    visitors/       {VI..}_{expression}.png
    journalists/    {JR_..}_{expression}.png
  cards/art/        {CARD_ID}.png                   e.g. C11.png (frames stay in cards/)
  backgrounds/      {STAGE_ID}.png                  e.g. ST02.png, OFFICE.png
  icons/            {ICON_NAME}.png, {BOOSTER_ID}.png
  fonts/            NotoSansJP-*.ttf
/scripts/
  autoload/         DataDB.gd, GameState.gd, SaveManager.gd, EventBus.gd
  rules/            BattleEngine.gd, CardResolver.gd, IntentRunner.gd, MetaRules.gd  (NO UI code)
  ui/               screen and component scripts
/scenes/            battle/, office_hours/, module_map/, shop/, menus/
/tools/             export_data.py (workbook → JSON)
/tests/             GUT unit tests for /scripts/rules/
```

Expressions for character art (data/art.json): `neutral`, `attacking`, `guarding`, `gaining`, `damaged`, plus the optional `defeated` and `victory`. A missing face falls back (defeated → damaged, victory → gaining) and finally to `neutral`; the old flat `assets/characters/` and `assets/cards/` folders are still checked last.

## 6. Data contract

The design workbook (`design/CoP_Starter_Card_Stage_Data.xlsx`) is exported by
`tools/export_data.py`. The exporter maps workbook tabs into JSON files; some
outputs are objects or nested structures rather than arrays, and some runtime
files are maintained by hand. Follow the exporter and the `_README` fields in
the current data files when changing the data contract. The checked-in snapshot
contains 60 levels, 23 canon stages, 18 boosters, 32 modifiers, 54 cards,
125 opponents, 6 real parties, 30 Floor Vote bills, and 2 cosmetic packages.

| File | Key | Purpose |
|---|---|---|
| `balance.json` | lever name | Global numbers: thresholds, XP tiers, bill difficulty factor |
| `suits.json` | element | 6 suits: Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous |
| `affinity.json` | element × stage_id | Suit power multipliers per stage (0.7–1.3) |
| `cards.json` | card_id | name_en, name_jp, suit, type, cost, self_plus, opp_minus, guard, draw, gaffe, target_segment, effect_text, upgrade_text, tier |
| `stages.json` | stage_id | mode, bar_unit, bar_max, win_threshold, turn_limit, energy_per_turn, hand_size, gaffe_limit, player_start, opp_start, segment mix %, win deltas, xp_reward, signature_rule |
| `segments.json` | segment_id | Press, Loyalists, Constituents, Donors, Bureaucrats |
| `modifiers.json` | mod_id | category, trigger_segment, trigger_min_pct, effect, magnitude, kaban_cost, available_to, source_booster |
| `boosters.json` | booster_id | Organizations; tier (Party / Constituency / National); linked modifiers; `starting_standing` (blank = the flat default in `booster_standing.json`) — §8 |
| `opponents.json` | opp_id | Opponent data and intent patterns. Affiliation is a booster_id (their org); Role is their real-world job (MP, journalist, staffer...); Title, when a row has one, overrides Role for display — see `OpponentDisplay.gd` |
| `opponent_cues.json` | cue_id | Spoken lines per opponent for battle, keyed by `opponent_ids` |
| `levels.json` | level_id | Workbook-derived level data and ordered stage references |
| `sanban.json` | variable | Meta-variables with start, min, max, and thresholds. **Four of the names are lookup keys as well as display text** — see §6 |
| `strings.json` | key | **Every sentence the game says.** From the workbook's Text tab; nothing is typed into a script |
| `card_cues.json` | card_id | Five spoken lines per card, from the Flavor Text tab |
| `questions.json` | stage type | The questions each kind of room can ask, graded S/M/W per suit. `asked_by` is an opp_id, resolved dynamically from whichever opponents.json rows list that room's stage_id in their own `stages` — never a hardcoded reporter list (`export_data.py`'s `fold_questions()`) |
| `player.json` | player_id | The four choosable protagonists (PC01–PC04), all cast with real names and parties as of the 2026-09-26 databook. New fields beyond name/party/blurb are display-only for now (Cameron's call) |
| `office_notices.json` | notice_id | One line of Office-screen flavor text per slot, conditioned on staff hired or a meta-variable threshold — see §13-adjacent `OfficeNotices.gd` |
| `office_ticker.json` | ticker_id | Lines for the Office screen's scrolling news strip, same condition schema as office_notices.json (or `always`), but every eligible line cycles rather than one winner per slot — see the 2026-09-28 mobile playtest fixes, `OfficeTicker.gd` |
| `parties.json` | party_id | The six real parties: name, official RGB colour, seat count (the real Sep-18 session, summing to 101), Leader Opp ID (blank until Cameron casts one), `vote_resistance` (blank = the flat default) — §7.7 |
| `floor_votes.json` | bill_id (BIxx) | National Assembly Floor Voting (ST23) bills: bill text, per-disposition favorability deltas, a `positions` list (one per party), and an optional influence-swing bonus (`influence_bonus_reputation`/`influence_bonus_party_support`, blank = none). No level link on the bill itself — see §7.7 |
| `level_intros.json` | level_id + role | A hired staff member's own line about a specific level, shown on the Level Intro screen between the Office and that level's first stage. Flat rows, entirely optional per (level, role) pair — see §7.8 |
| `vote_influence_triggers.json` | flat rows | The Floor Vote influence swing's own gate: which meta values or booster standings count, switched on/off, each with its own threshold — see §7.7 |
| `vote_influence_cues.json` | bill_id + outcome_direction | The optional cutscene line for a bill the influence swing above flips — see §7.7 |
| `cosmetic_packages.json` | package_id (CPxx) | Purely decorative packages (outfit/Office background/music) the player can buy — see §8 |
| `art.json` | kind | Where each kind of picture lives, the expression list and fallbacks |
| `rules.json`, `stage_types.json`, `playtest_level.json` | varies | Hand-maintained runtime and playtest configuration |

**Data rules:**
- **No sentence lives in a script.** Every line the game says is a row in the
  Text tab, asked for by a Key. The exporter checks both directions: a key the
  code asks for and the tab has not got is an **error** naming the file and
  line, and a row nothing asks for is a note. `design/EDITING_TEXT.md` is the
  guide to editing each kind of prose.
- **Four names are data, not just words.** "Constituency support",
  "Reputation", "Funds" and "Party support" are shown on screen *and* are how
  the code reaches into `sanban.json` and the run's meta. Renaming one in the
  workbook alone is an **error** at export, naming which files use it.
- `effect_text` is **display only**. Never parse it. Conditional effects use the structured special-effect fields in the current exported card data.
- Some workbook cells hold `"varies"` or `"—"`. Treat those as null and resolve them from the module or committee data.
- On load, `DataDB` validates cross-references (every card suit exists, every module stage and opponent exists, and so on) and prints a readable error report.

## 7. Battle rules

Items marked **[DEFAULT]** are your implementation choice. Put each one behind a `rules.json` switch or a `balance.json` value so Cameron can change it.

### 7.1 Setup
1. Load the stage, opponent, and bill from the current module row.
2. Starting support = stage `player_start` / `opp_start`, plus reputation (Kanban) effects in press stages (±5 at the Sanban thresholds).
3. Apply every modifier whose trigger segment's share of the stage audience is at least `trigger_min_pct`. The gaffe meter starts at 0 and is then adjusted by modifiers.
4. Shuffle the player deck and draw up to `hand_size`.

### 7.2 Turn loop
1. **Show the opponent's intent** for this turn.
2. **Refill energy** to `energy_per_turn`. Unused energy does not carry over.
3. **Player plays cards** by paying their cost. Resolve each card in this order:
   - Look up `m` = affinity[suit][stage]. Multiply `self_plus` and `opp_minus` by `m` and round half up. Guard, draw, and gaffe values are **not** multiplied.
   - Apply any `special` effect.
   - Add support and subtract opponent support. **Winning somebody over costs points, not one for one:** somebody undecided comes across for 1 point; somebody already with the opposition costs 1 (60%), 2 (30%) or 3 (10%), rolled per person. Points that cannot pay for the next person are lost. Where the opponent's number is not part of the win condition — a press conference, a scored caucus — subtracting opponent support does **nothing**.
   - Add guard. Guard is a **bank**: it stacks to `guard_cap` (5), carries between turns, and is spent by whatever it stops.
   - Add or subtract gaffe points (floor at 0).
   - Draw cards; when the deck is empty, reshuffle the discard pile.
4. **End turn:** discard the rest of the hand **[DEFAULT]**, except where the hand cannot be replaced (a press conference). Ending a turn having played **no cards** is a pass: the next turn starts on `energy_per_turn − pass_energy_penalty` (1), and in a press conference it also declines the question in front of you, which costs press tone and pleases nobody.
5. **Opponent resolves its intent.** An attack of X is met by the target's guard first: the guard absorbs what it can and is spent doing so, and max(0, X − guard) gets through. This applies **both ways** — the opponent's guard absorbs the player's attempts to argue their supporters away. Guard is not cleared at the end of a turn; only an attack takes it.
6. **Check** win and loss, then advance the turn counter and draw up to hand size.

### 7.3 Bars by stage type
| Stage | Bar model |
|---|---|
| Floor debate (ST02), unit "Seats" | Shared pool of `bar_max` (101). Undecided = pool − player − opponent. Player gains come from Undecided first, then from the opponent **[DEFAULT]**. Opponent losses return to Undecided. Win at `win_threshold` (51). |
| Caucus, Town Hall, Steering Committee (ST03, ST05, ST08), unit "Support" | The same shared-pool model on a 0–100 scale. |
| Press conference (ST04) | A single "press tone" bar starting at `player_start`. Reporter questions are the opponent intents — one per turn, so it asks exactly `turn_limit` questions ("Question 2 of 5"). After the last one the tone is judged: at or above `win_threshold` is a win, below is a loss (2026-09-27; the bar shows "55 to win"). It never ends early on reaching the threshold. |
| TV debate (ST06) | A single bar. The player wins only if it is **at or above the threshold at the end of every turn** (survival). Retuned 2026-09-25 (energy 3→5, hand 5→6, player_start 50→60) after a full playtest found the room mathematically unwinnable on turn 1 as originally tuned — the best possible turn-1 gain, any suit, full collection, was 12, short of the 15 needed from 50 to the 65 threshold. First-draft numbers, Cameron's to retune further. |
| Committee (ST01, ST09-ST18) | An ordinary Shared_pool bar. `sequence_mode: "reset"` draws several opponents from the stage's eligible pool (`opponent_count`) and fights them one at a time, a full reset between each — see §7.5. |

### 7.4 Win and loss
- **Loss:** the gaffe meter reaches `gaffe_limit` (immediate), or the turn limit ends without a win (§9 switch).
- **What a loss costs:** the stage's own `loss_delta_*` columns (Jiban, Reputation, Yen, Party support, XP — signed as written; a few stages hand back a little Funds or XP even for a loss). Applied by `GameState._apply_stage_rewards()` via `MetaRules.apply_loss_deltas()`, shown on the result panel, and listed as "If you lose: …" under each stage in the level briefing (`LevelRunner.loss_penalties()`). Before 2026-09-27 these columns were in the data but nothing read them.
- **Win:** the bar reaches its threshold, or a committee majority locks For.
- **Whether a loss ends the level**, `stages.json`'s `loss_ends_level` (Stages tab, blank = Yes): normally yes — a lost stage sends the player back to the Office. Press conference (ST04) and Media Ambush (ST19) are marked "No" — Cameron, 2026-09-26: their threshold only decides which reward table applies (`win_delta_*`/`loss_delta_*`, already resolved from `state.outcome` before this is checked), not whether the level continues. `LevelRunner.loss_ends_level()` is the one place this is read; `OutcomePresenter.next_step_label()` reads the same flag so the button never says "Back to the Office" when the level is actually about to move on.

### 7.5 Committee stage
- A committee (ST01, ST09-ST18) is an **ordinary sequential battle**, not a separate mechanic. It draws `opponent_count` opponents from its eligible pool — every opponents.json row whose own "stages" list names that STxx, the same dynamic-by-default selection every other Combat stage uses (`BattleSetup._opponents_for()`) — and fights them **one at a time**.
- `sequence_mode: "reset"` (`BattleEngine._advance_to_next_opponent()`/`_reset_for_new_bout()`) is what makes each opponent a fresh argument: support, gaffes, guard, energy, the clock and the hand all start again the moment the last one is beaten. `bar_model` is left blank on these rows, so the bar itself is the ordinary Shared_pool default (`BarModel.for_stage()`).
- Win by getting through every opponent in the sequence — the same win condition any multi-opponent stage uses. Lose on the gaffe limit, or on the turn limit of whichever bout is in progress.
- Corrected 2026-09-25: an earlier pass built a separate per-member "lean/lock" persuasion model (locking a simultaneous majority of up to 13 voting members) that did not match this design. It's gone — `CommitteeModel.gd`, `BattleState.committee`, and every `is_committee_stage()` special-case were removed, and the 11 committee stages now use the `sequence_mode: "reset"` mechanism above, which was already built and tested (`data/playtest_level.json`'s `PT_S1` fixture) but never wired to the real canon rows. `opponent_count` on these rows is a first-draft `{min:3, max:3}` — Cameron's to tune per stage.

### 7.6 Opponent behavior (MVP)
Opponents use **scripted intent ranges**, not deck AI. Their attack, gain, and block ranges are exported with the opponent data. When a pattern is missing, the fallback comes from `data/rules.json`.

### 7.7 National Assembly Floor Voting (ST23, built 2026-09-26)
- Not a battle: a single **Vote Yes / Vote No / Abstain** choice against one bill. Mode `"Vote"` (`data/stages.json`), routed by `StageRouting.gd` to its own `FloorVoteScreen.tscn`, the third screen family alongside BattleScreen (Combat) and VisitorScreen (Non-combat).
- Generic and reusable like any other stage: ST23 itself carries no bill data, and there is no separate "which level has a Floor Vote" flag either. **A level names its own bill directly in its own stage sequence** — a `"BIxx"` value in one of its `stage_1..stage_10` cells, the exact same slot series every other room fills with an `"STxx"` (2026-09-27 pull: Cameron's own levels put `"BI01"` where another row would put `"ST05"`). `BattleSetup.build_stage_for_slot()` recognizes the shape (`_is_bill_id()`) and treats it as ST23 played with that bill; `DataDB.get_floor_vote(level_id)` does the same lookup by scanning the level's own row for a slot that matches a real `floor_votes.json` key. The workbook's **Floor Vote Bills** tab (one row per bill, its own **Bill ID**, BIxx — a separate namespace from Level ID, 2026-09-26, so "the bill" and "the level" are never the same identifier — bill name, scroll description, a favorability delta per disposition) joins with **Floor Vote Party Positions** (one row per bill per party, keyed by that same Bill ID: its baked-in Yes/No/Abstain split, its disposition — Supportive/Opposed/Neutral — and its leader's cue line for this bill) purely by Bill ID — neither tab mentions a level at all. `tools/export_data.py`'s `fold_floor_votes()` does that join; a level naming more than one bill, or a bill named by more than one level, is an export error. The workbook's own **Vote Tally & Swing** tab is Cameron's hand-check of the same math the engine computes at runtime — not exported, confirmed to agree with `FloorVoteEngine`'s own totals on real data.
- **The six real parties** live in a new **Parties** tab / `data/parties.json`: name, official RGB colour, and a Leader Opp ID (an Opponents-tab row) for that party's portrait and cue — blank until Cameron casts one, same bargain as any other missing-art/missing-cast slot. Party Name is the same free-text string `opponents.json`/`player.json` already carry as `party`, so nothing new has to be renamed.
- **The player's own seat is assumed to be wherever their party's own majority already sits** (Yes, No, or Abstain, whichever bucket is biggest — Cameron's call, 2026-09-26, over an explicit authored field). Voting anything else moves exactly one seat out of that assumed bucket into whichever the player actually picked. `FloorVoteEngine.majority_bucket()`/`choose()`.
- **Party favorability** (new mechanic): every party's own standing moves after the vote, unconditionally on its own disposition — a bill's three deltas (Favorability Delta: Supportive/Opposed/Neutral) apply to every party that held that stance, regardless of whether the bill passed. The player's own party's share lands on the existing `Party support` sanban variable directly (no second number to keep in sync); the other five live in `GameState.party_standing`, seeded from `data/party_standing.json` the same way `booster_standing.json` seeds organisation standing. `GameState.party_favorability()`/`apply_floor_vote_favorability()`.
- Cannot be lost, the same as Office Hours — a decision, not a contest. Worth whatever the stage's own `win_delta_*` fields say.
- **Influence swing (built 2026-09-28, Cameron)**: a strong enough player can additionally swing *other* parties' seats toward their own pick, not just their own single seat — hard but achievable, gated behind a real threshold rather than a routine button. `VoteInfluence.gate_passed()` checks the workbook's new **Vote Influence Triggers** tab (`data/vote_influence_triggers.json`): every row Cameron switches on must independently clear its own threshold (default 85, `balance.json`'s `vote_influence_default_threshold`) — a hard AND-gate, not a weighted score — and a row names either a meta value (Reputation, Party support, ...) or a booster_id, so which variables count is his to add or remove from the workbook alone. Once the gate passes, `FloorVoteEngine._apply_influence_swing()` reuses `majority_bucket()` for every party (not just the player's own): any party whose own assumed majority isn't the picked bucket gives up some seats, deterministically (no roll), capped by that party's own **Vote Resistance** (`parties.json`'s own `vote_resistance` — blank falls back to `balance.json`'s flat `vote_swing_resistance_default`, 70 first-draft, Cameron's to retune — the same per-item-override-over-flat-default shape Boosters' Starting Standing already uses). `choose()`'s own result gains `influence_gate_passed` and `outcome_flipped_by_influence` (true only when the swing changes the bill's own pass/fail, not on every swing — attributable specifically to the player's own influence). A flip shows an optional cutscene line (the workbook's new **Vote Influence Cues** tab, `data/vote_influence_cues.json`, one row per (Bill ID, Outcome Direction) pair, blank-tolerant the same way Level Intro Cues is) on `FloorVoteScreen`'s own `CueBanner` — this screen's first use of one — and can apply an optional bonus (Floor Vote Bills' new **Influence Bonus (Reputation)**/**Influence Bonus (Party support)** columns, blank = none) via the new `GameState.apply_floor_vote_influence_bonus()`. Sanity-checked against real, already-hand-verified data: forcing the gate open on LV31/BI01 with 0% resistance turns its known 45/48/8 loss into a 96/5/0 win, with `outcome_flipped_by_influence` correctly `true`. Both new tabs ship with the gate off by default (`data/vote_influence_triggers.json`'s one seed row has `Enabled = No`) and every Vote Resistance/Influence Bonus cell blank, so no existing level's behavior changed until Cameron turns it on — confirmed by `floor_vote_test.tscn` (`tools/verify.sh`) still showing LV31's own unswung 45/48/8 totals.
- **Per-party scope (2026-10-02)**: a Vote Influence Triggers row can also carry an **Applies To Parties** column (`data/vote_influence_triggers.json`'s own `applies_to_parties`, a list of party_ids) so a trigger gates the swing into one or a few specific parties rather than the whole chamber — blank/empty still means every party, so a row written before this column exists behaves exactly as it always did. Cameron is adding the column to the Vote Influence Triggers tab himself; `export_data.py` already has it in its `optional` list (the same "not in the workbook yet" bargain every other in-progress column uses), so nothing breaks before or after he uploads it. `VoteInfluence.gate_passed()` takes an optional `party_id` and skips any row whose own scope doesn't name it; `FloorVoteEngine._apply_influence_swing()` now checks the gate **once per party** being considered (by that party's own `party_id`), rather than once for the whole vote, so the same vote can swing one party and not another. `influence_gate_passed` on the result is true if the gate passed for at least one party. New GUT coverage: `test_vote_influence.gd` (unscoped rows count everywhere; a scoped row counts only for its named party/parties; a global row and a scoped row combine per party) and `test_floor_vote_engine.gd` (a scoped trigger swings only the party it names, leaving an un-named party untouched even though its own assumed majority also isn't the picked bucket; a trigger scoped to a party absent from the bill swings no one).

### 7.8 Level Intro screen (built 2026-09-27)
- A short beat between the Office and a level's first stage: any hired staff member with a written line about that level says it over the Office background before the level begins. `scenes/office_hours/LevelIntroScreen.tscn` / `scripts/ui/LevelIntroScreen.gd`, built by `tools/build_level_intro_scene.gd` the same way `VisitorScreen.tscn` is.
- Entirely data-driven and blank-tolerant: `data/level_intros.json` is flat rows of `(level_id, role, cue_text)`, from the workbook's new **Level Intro Cues** tab — most (level, role) combinations will have no row at all, and that role simply stays silent for that level. `LevelIntroCues.resolve()` (`scripts/rules/LevelIntroCues.gd`, pure/UI-free per §12, mirrors `OfficeNotices.gd`) returns one entry per role that is BOTH hired AND has a written line for this level, in `staff.json`'s own row order.
- **Skipped entirely when there's nothing to say**: `OfficeScreen._on_start()` resolves the cues before changing scene — a non-empty result routes to `StageRouting.LEVEL_INTRO_SCENE` instead of straight to the first stage; an empty one goes straight to the first stage exactly as before this feature existed, so no level regresses until Cameron actually writes a row for it. Resuming a level already in progress never shows this screen — it is a start-of-level beat only.
- **Every qualifying role speaks, one after another** (not just the first, unlike Office Notices) — a level briefing can genuinely have more than one person weigh in. Lines queue on the same `CueBanner` every other spoken line uses, from the player's own (blue) side — staff are the player's own team, not an opponent. The portrait swaps to match whoever is currently speaking.
- Content prompt: `design/LEVEL_INTRO_PROMPT.md`. The tab exists in the workbook today with no rows — Cameron's to write.

### 7.9 Stage Transition screen (built 2026-10-01, Cameron)
- A short beat between two stages of the SAME level — distinct from §7.8's Level Intro, which only ever plays once, before a level's first stage. Opt-in per stage: `stages.json`'s new `Show Transition` column (blank = No, every existing stage ships off) and `Transition Speaker Count` (blank = 1, how many distinct characters speak). `scenes/office_hours/StageTransitionScreen.tscn` / `scripts/ui/StageTransitionScreen.gd`, built by `tools/build_stage_transition_scene.gd` the same way the other two screen-builder tools are.
- **Three new workbook pools**, all flat and blank-tolerant, a row's own `Stage ID` left blank making it usable for ANY stage's transition (a wildcard): **Transition Cast** (`data/transition_cast.json` — which OPxx/SFxx characters are eligible), **Transition Backgrounds** (`data/transition_backgrounds.json`), **Transition Dialogue** (`data/transition_dialogue.json` — a `Character ID`-scoped paired exchange, `Character Line (EN)` + `Player Reply (EN)`). All three ship empty — Cameron's to write, the same "nothing written yet" bargain Level Intro Cues shipped with.
- **One reusable pool-of-choices function**, not three: `scripts/rules/PoolPicker.gd` (new, pure) generalizes `OfficeTicker.gd`'s own eligible-then-random-pick — filter a table to rows whose scope field is blank or matches, then pick one at random, never repeating the excluded row unless it's the only option. Character selection, background selection, and dialogue selection all go through this one function.
- **`scripts/rules/StageTransition.gd`** (new, pure) composes the picks: samples up to `Transition Speaker Count` distinct characters from Transition Cast — only ever counting one that ALSO has an eligible Transition Dialogue exchange (a cast candidate with nothing written for them simply doesn't speak, rather than appearing silent) — then one background. `resolve()` returns `{}` whenever the stage doesn't show a transition, or shows one but nobody eligible has anything written, so a half-authored pool never blocks the game.
- **All art is existing art**: every portrait (the player's own and every speaker's) resolves at the `neutral` expression by ID — no new art-loading path, no expression logic. Which kind a `Character ID` is (an opponent or a hired staff member) is told apart by its own OPxx/SFxx prefix, the same trick `BattleSetup._is_bill_id()` already uses for a BIxx vs. an STxx; an opponent speaks from CueBanner's red/right side, staff from the blue/left side alongside the player, matching Level Intro's own "staff are the player's own team" convention.
- **The speaker portrait swaps and slides in** each time the current speaker changes — one portrait slot reused for however many speakers there are (generalizing Level Intro's own speaker-swap-on-`lines_shown` polling), rather than cramming several portraits on screen at once. The player's own portrait is static and present throughout, lower-left; the current speaker's is lower-right, the same two-corner `ArtBox` shape `BattleScreen.tscn` already uses for its own opponent row.
- **One random draw per transition, never two that could disagree**: `StageRouting.go_to_next_stage()` — the new single chokepoint `BattleScreen`/`VisitorScreen`/`FloorVoteScreen` all call instead of each duplicating their own "same scene or different" logic — only checks the cheap `Show Transition` flag before routing to `StageTransitionScreen.tscn`; the real pool picks (which speakers, which background, which lines) happen exactly once, inside that screen's own `_ready()`. If that draw comes back empty, the screen immediately continues on to the real next stage rather than showing anything.
- Confirmed end to end with a throwaway driver (deleted before commit): forced `Show Transition = Yes` with a 2-speaker pool on a real stage (LV04's ST04, after a real ST03 win) — the player's own portrait was present throughout, both speakers (one opponent, one staff) appeared in turn each with their own paired exchange, and Continue landed on ST04's real BattleScreen afterward.

## 8. Meta systems

| System | Rule |
|---|---|
| Stage rewards | On a win, apply the stage's win deltas to constituency support (Jiban), reputation (Kanban), funds (Kaban), party support, and XP; on a loss, its loss deltas (§7.4). Clamp every meta-variable to its min and max. A blank delta cell is JSON null and reads as 0 (`MetaRules.stage_delta()` — `int(null)` used to crash every Floor Vote level's briefing). |
| Jiban ≤ 15 | **Built** (2026-09-25). Inserts a Town Hall stage (ST05) into the level queue — `GameState._check_town_hall()`, `MetaRules.town_hall_triggered()`. |
| Party support = 0 | **Built** (2026-09-25), redesigned from Jiban = 0 (Cameron's call — the party cutting you off reads better than your constituents controlling party money). Funding frozen: Funds income becomes 0 until party support rises back above. `GameState._check_funding_freeze()`, `MetaRules.funding_frozen()`; named for the shop as modifier M32 "Funding Freeze" (`ModifierEffects.FUNDS_INCOME_FREEZE`), never purchasable. |
| Party support > 75 | **Built** (2026-09-25). Modifier M09 (Party Backing) is active for free, in addition to anything owned — `MetaRules.party_support_modifiers()`, `GameState._effectively_owned_modifiers()`. |
| Party support < 50 | **Built** (2026-09-25), same mechanism, M10 (Cold Shoulder) — though M10's own effect (UNLOCK_DISCOUNT) has no consumer anywhere yet, a pre-existing gap this wiring didn't open. |
| Party support < 25 | **Built** (2026-09-25), redesigned from "insert the Steering Committee stage (ST08)": ST08 is already a Combat stage hand-placed in 7 real levels, so repurposing it would have changed what they do. Inserts a **new** Non-combat stage instead, ST22 "Party Steering Committee Check-In" — Office Hours' own visitor-event machinery, reused wholesale, with one placeholder visitor (VI04) and question (VQ04). The original entry-cost idea (disabling a Kōenkai/Bankisha modifier) is not built — "Bankisha" doesn't map to any of the 16 current organisations. |
| Office hours (ST07) | Non-combat. Five time slots. Visitor event cards come from `visitors.json`. Each card offers 2 choices, and each choice has outcome deltas to Jiban, Kaban, party support, or funds. |
| Party favorability | **Built** (2026-09-26). National Assembly Floor Voting (ST23) is the first stage to move more than the player's own party's standing at once — see §7.7. |
| One-time levels | **Built** (2026-09-26). `levels.json`'s own "One-Time (Yes/No)" column (blank/No = the old, only behavior): once completed — win or loss — the level disappears from the Office's own level list entirely, not shown-locked like a cooldown. A deliberate exception to `OfficeScreen._level_row()`'s own stated rule that a locked/cooling-down level stays visible — Cameron's explicit call, for a level whose payout (a Floor Vote's favorability swing, say) shouldn't be a replayable grind. `Ledger.level_is_hidden()`. |
| XP checkpoint | Shown between modules. Spend XP to unlock cards at their tier cost from `balance.json`. Upgrade cost is 30 XP **[DEFAULT]**. |
| Save | **Built.** One slot, `user://savegame.json`, written after every stage, whenever the Office opens or something is bought or changed there, and when the app is backgrounded outside a stage. A stage in progress is never saved: reopening mid-stage restarts that stage. No save on launch opens the New Game screen. |

**Yoron/Bills removed** (2026-09-26, Cameron: "the deletion of yoron (remove
that mechanic)"). The public-opinion topic list (`data/yoron.json`), bills
(`data/bills.json`), bill difficulty (`MetaRules.bill_difficulty*()`,
`BattleSetup.bill_difficulty()`, and the `bill_difficulty` config field
`BattleEngine._setup_board()` used to add to the opponent's starting
support), and the visitor `choice_X_yoron_topic` field are all gone — every
call site was checked first and confirmed dead (no real workbook data ever
populated a topic choice, and nothing outside these functions read the
result). A press stage's starting support is now just `player_start` plus
reputation (Kanban) effects, per §7.1.

**Cosmetic packages** (built 2026-09-28, Cameron): purely decorative —
an outfit, an Office background, and/or music, no gameplay effect. A new
**Cosmetic Packages** workbook tab / `data/cosmetic_packages.json`, one
row per package (`CPxx`), flat and blank-tolerant: any subset of its four
piece columns (Outfit Variant, Background Variant, Music: Office Sound,
Music: Battle Sound) may be blank, so an outfit-only, background-only, or
music-only package is the same row shape as a full bundle. A **package is
the purchase unit** (its own `GameState.buy_cosmetic_package()`, Funds/XP
via the same `cost_xp`/`cost_yen` columns Supplies items use, refused via
the new `scripts/rules/CosmeticPieces.gd` — an "already yours" check then
the same afford check every other one-time unlock makes); the **slot**
(Outfit / Office Background / Music) is the **equip** unit —
`GameState.active_cosmetics` picks one owned package per slot
independently via `equip_cosmetic()`, so a player can mix a red suit from
one package with the Office background from another and the music from a
third. Two seed packages ship (Cameron's to retune or replace): CP01
"Neon Ambition" (a red outfit, an upgraded Office, and a synth-pop
theme), CP02 "Quiet Chamber" (a gentle-shamisen music theme only).

No new art-loading mechanism was built for this — it reuses the exact
"stage outfit" shape §5/§13 already describe, with one more axis:
`ArtLoader.character_path_candidates()` now also takes an optional
`variant`, tried before everything else
(`{ID}_{variant}_{STAGE_ID}_{expression}.png`, then
`{ID}_{variant}_{expression}.png`), falling all the way through to the
plain file — missing cosmetic art never blocks anything, the same bargain
every other axis here keeps. `character_path()`/`background()` resolve
the equipped variant automatically (`ArtLoader._outfit_variant()`/
`_background_variant()`, reading `GameState.active_cosmetics` directly),
so no call site anywhere in the game had to change: the Office's own
background, the battle screen's presenters, and `PlaceholderArt`'s own
"is this a placeholder?" check all pick up cosmetics for free.
`_outfit_variant()` only ever returns non-blank for the **current
protagonist's own ID** (`DataDB.player.get("player_id")`), so an
opponent, staff member, or visitor can never accidentally wear the
player's own cosmetic; `_background_variant()` only ever applies to
`"OFFICE"` — extending cosmetic backgrounds to the 23 stage backgrounds
is a deliberate, small follow-up, not built here, since Cameron's own
example was specifically "an upgraded office."

Music works the same way, one layer up: `Audio.play_music(sound_name)`
checks the equipped Music package for its own `music_office_sound`/
`music_battle_sound` override (a `sounds.json` key, not a filename
directly — four new silent seed rows, `music_office_pop`/
`music_battle_pop`/`music_office_shamisen`/`music_battle_shamisen`, ship
the same "empty file, wire it up later" way every other cue does) before
falling through to play `sound_name` as asked. Every screen still calls
`Audio.play_music("music_office")` exactly as before; the substitution
happens once, inside `Audio.gd`, the same "no call site has to know
cosmetics exist" shape `ArtLoader` uses.

A blank JSON cell on an optional column is `null`, not `""` — caught
before it became this project's next `<null>`-class bug (§13's Party/
Title fields already needed the same guard): `CosmeticPieces.field()` is
the one place every optional cosmetic column is read from now, returning
`""` for a genuinely blank cell rather than the literal text `str(null)`
would otherwise give.

A new **"Cosmetics"** button beside "Your Record", built in code exactly
like it (`OfficeScreen._build_cosmetics()` — no `.tscn` edit, §13).
`_show_cosmetics()` lists every not-yet-owned package to buy, then, once
at least one is owned, an "Equip" section with one row of buttons per
slot that has anything owned for it — Default plus every owned package
with a piece for that slot, the currently active one shown disabled with
its own name and "— Equipped" rather than losing its name to a generic
greyed-out reason.

## 9. Open design decisions: implement as switches, do not decide

`data/rules.json` holds the current runtime settings. Its values and accepted
options are authoritative; the table below describes the current settings:

| Flag | Current value |
|---|---|---|---|
| `turn_limit_outcome` | `"loss"` |
| `opponent_can_win_by_threshold` | `false` |
| `opponent_engine` | `"intent_patterns"` |
| `press_answer_timer` | `false` |
| `discard_hand_end_of_turn` | `true` |
| `pass_energy_penalty` | `1` |
| `guard_cap` | `5` |
| `card_training_looks` | `3` — cards one Rhetoric Training draw may show; the last must be learned (Cameron, 2026-09-27) |
| `default_consumable_stack_cap` | `5` — the Stack Cap any Supplies consumable (usable in the Office or a stage) gets when its own Shop-tab cell is blank; filled in once at load by `DataDB._apply_default_consumable_cap()` (Cameron, 2026-09-27) |
| `default_intent_pattern` | attack 1–6 / gain 1–6 / block 0–2 |

### Still unresolved — ask, don't guess

- **Party post titles.** `data/opponents.json`'s Title column overrides Role
  for display when a row has one (`OpponentDisplay.title_for()`); which
  real-world post titles Yezo's parties actually use is Cameron's to define,
  not a decision made on his behalf.
- **The `weak_answer_tone_cost` number.** The current value is 1 in
  `stage_types.json`; the file labels it as a placeholder pending playtesting.
- **The Theme → organisation mapping.** The workbook's Question Themes tab
  maps its themes to organizations, with the reasoning for
  each in a Why column. It is a **draft Claude wrote for Cameron to correct**,
  not a decision made on his behalf. Only existing booster IDs are used.

## 10. UI specification

Every screen is portrait, uncluttered, and English-first. Layout from top to bottom:

1. **Header:** stage name in English with a small muted Japanese accent (for example "Floor debate 本会議"), and on the right, "Turn 3 of 8".
2. **Opponent row:** an art box showing the stage's own background, with two full-body cutouts in its bottom corners — the opponent (lower right), name and intent in plain words (for example "Attacking · −6") shown beside it; and your own face (lower left), reacting to what you just did.
3. **Win condition:** the support bar with a visible threshold line and a caption such as "51 seats to win". A committee stage shows the same bar against whichever member is currently up, with an "Opponent 2 of 5" style caption for how far through the sequence the player is; press conferences show the current question instead.
4. **Status row:** Energy pips and "Gaffes 2 / 6". The gaffe warning turns red **only** when one more gaffe would end the stage.
5. **Hand:** 3–5 cards. Each card face shows cost, English name, and a one-line effect. At most one small Japanese accent per card. Tapping a card opens a zoom view with the full text, suit, art, and Japanese name; dragging a card up out of the hand plays it directly.
6. **Footer:** a full-width "End turn" button.

Secondary information (deck and discard counts, active modifiers, opinion topics) goes in a **details panel** opened from an icon, not on the main screen.

Placeholder art: a flat colored rectangle labeled with the asset ID, so missing PNGs never block testing.

## 11. Milestones

Build **one milestone at a time**. After each one, stop and give Cameron: (a) what you built, in plain English; (b) how to test it (exact clicks); (c) any questions or decisions you need from him.

| # | Milestone | Done when | Current status |
|---|---|---|---|
| M0 | Project setup, `export_data.py`, `DataDB` loading and validation, placeholder art loader, font theme | Every JSON file loads; the validation report is clean or lists readable errors; Japanese renders | **Done** |
| M1 | Headless rules engine plus GUT tests | Tests pass for affinity math, block, gaffe loss, intent cycling, shared-pool seats, and committee locking | **Done** |
| M2 | Battle UI: Floor debate (ST02) vs OP03 | A full battle is playable to a win or loss on desktop | **Done** |
| M3 | Committee (ST01) and Party Caucus (ST03) | Both playable using Module 01 data | **Done** |
| M4 | Office hours, module runner, meta-variables, auto-save | A full level plays start to finish; quitting and reopening resumes the run | **Done.** The level runner, meta-variables and saving/resuming exist (resuming mid-level returns to the start of the current stage). Office Hours visitor events are playable end to end (`design/proposals/office_hours.md`): a multiple-choice visitor room, its own `VisitorScreen`, and `StageRouting.gd` sending a level to the right screen stage by stage as it mixes Combat and Non-combat rooms. |
| M5 | XP checkpoint shop | Unlocks and upgrades persist across the run | **Done.** *As of 2026-09-27, new cards come only from Rhetoric Training (see "The 2026-09-27 playtest fixes", #5); the direct XP "New cards" list and `buy_random_card()` described below are gone.* The shops, prices, refusals, and deck screen exist. `rules.json`'s `open_card_collection` is now `false` and `level_gating_enabled` is now `true` (2026-09-25, both fully built, just switched on) — XP genuinely gates card unlocks (`cards.json`'s own `xp_to_unlock`, filled in for all 54 cards) and level unlocks/cooldowns for the first time. A second, Yen-based route now exists alongside it (2026-09-26, Cameron): Supplies' "Purchase Random Tier N Card" (SH27/28/29) grants a random unowned card of that tier on purchase — `GameState.buy_random_card()`, `shop.json`'s own `card_tier` column — rather than sitting in the inventory unusable, which is what these three did before (`Use In Office`/`Use In Stage` were both blank, so nothing could ever use one). The remaining seven items (SH13-19, Cameron, 2026-09-25) are now wired the same way, each its own purchase-time effect rather than an inventory item to Use: SH13/14 ("Unlock Tier 1/2 Level") grant one random not-yet-unlocked level of that `level_tier` (`GameState.buy_random_level()`); SH15/16/17 ("Unlock Random Tier 1/2/3 Card") reuse `buy_random_card()` outright — they only needed their own `card_tier` set, the same column SH27-29 use, XP-costed instead of Yen; SH19 ("Increase Office Funds Cap") raises the Funds ceiling by its own `funds_cap_increase`, repeatable (`GameState.funds_cap_bonus`, read in `_sanban_row()`). SH18 ("Unlock New Staff Recruitment Tier") is a genuinely new rule, not just a wiring gap: staff candidates now gate on a candidate's own `highest_tier` against a new persistent `staff_recruitment_tier` counter (starts at 0 — only Tier 0 candidates are hireable at a new game), which SH18 raises by 1 per purchase (`Ledger.staff_hire_refusal()`/`can_hire_staff()`, `GameState.buy_staff_recruitment_tier()`) — Cameron's call, since no such gate existed anywhere before. A random card grant (SH15-17 and SH27-29 alike, since both are the same `buy_random_card()` effect) now shows the actual card instead of only naming it (2026-09-25, Cameron — asked for full reveal popups specifically): `buy_random_card()`'s result carries the drawn card's own `card_id` (its art asset ID, cards/art/{CARD_ID}.png) alongside its message, and `OfficeScreen._show_card_reveal()` puts up a pop-up on top of Supplies with the card's front (`CardView`) and, stacked below it (Cameron, 2026-09-25 — the same two views a tap on a card in battle shows, front and back, here one under the other since nothing else needs the screen), its back (`CardBackView`, full printed text, no "in this room" line since there is no room), then the "unlocked" line and a "Nice." button to dismiss it, below both. |
| M6 | Android export test, then iOS | Runs on a real phone in portrait with crisp Japanese text | Not started |
| Later | Additional room systems and mobile export | Defined as needed | The project includes nine playtest stage types. The Town Hall and Steering Committee triggers are connected to the level queue now (2026-09-25) — see §8. |

### Implemented systems and remaining work

The project also contains a browser playtest, booster standing, scripted intent
patterns, card cues, opponent cues, and a text catalog exported from the
workbook. Canon Town Hall (ST05) now draws its own written questions the
same way a press conference does (`BattleSetup.QUESTION_POOL_BY_STAGE`), and
BattleScreen shows what is being asked on the CueBanner itself
(`_announce_question()`), as its own default content until the player's turn
gives the banner something else to say, since ST05's Shared_pool bar means
it never gets the press-conference-shaped opponent row. What actually
happened — the opponent's own narration, a bout finishing, or the player's
own pass/decline penalty — moved to a small `%RoomNotice` label instead
(2026-09-26), so the banner in a question-asking room is never anything but
the question or the opponent's own cue, and never restates a name its own
tag already carries. The weak-answer tone cost remains a placeholder value
of 1 pending playtesting, and ST05 does not set it at all today, so a weak
answer there costs nothing yet — Cameron's number to set, not a gap in the
wiring.

### §8's four crisis triggers — now wired (2026-09-25)

All four are live: see §8's own table above for what each does today and
where. `MetaRules.gd`'s own file comment carries the same summary next to
the pure functions themselves. Each of the three that inserts or freezes
something (Town Hall, Steering Committee, funding freeze) fires once on the
way INTO its threshold and stays quiet — even while the condition keeps
holding — until the player has come back OUT (`GameState.town_hall_active`/
`steering_committee_active`/`funding_frozen_active`); a Town Hall lost while
Jiban is still low does not immediately queue a second one. The player
finds out about either edge — entering or leaving — through a popup on the
Office screen the next time they're there (`GameState.pending_trigger_
alerts`, `OfficeScreen._show_trigger_alerts_if_any()`), the same panel
pattern the battle screen's own outcome panel uses.

A fifth, related system went in alongside these: lifetime meta-variables —
`GameState.stage_type_results` (wins/losses per stage_id, including any
stage type added later, with no code change needed), `lifetime_gaffes`,
`stages_lost_to_gaffes`. At `gaffes_lifetime_penalty_threshold` (Balance
tab, 50 today) lifetime gaffes, a one-time `gaffes_lifetime_penalty_jiban_
delta` (−15 today) hits Constituency support once and never again this run.

### The 2026-09-26 databook pull

A new export of the workbook expanded Player, Opponents, Boosters and
Opponent Cues, and added Office Notices; four things came out of it.

- **Player is now real data.** All four protagonists (`data/player.json`)
  are cast with real names and parties, exported by `export_data.py`'s new
  `fold_player()` from a Player tab (was hand-maintained placeholder data
  before). Fields beyond name/party/blurb (a per-protagonist `starting_meta`
  and `starting_xp`) exist but are display-only for now, per Cameron.
- **Opponents split Affiliation from Role**, rather than one free-text
  field doing both jobs: Affiliation is a booster_id (their organisation),
  Role is their real-world job. A Title column, when a row has one,
  overrides Role for display (`OpponentDisplay.title_for()`) — party post
  titles themselves are still Cameron's to define (§9).
- **Journalists are opponents.json rows now**, not a separate
  `journalists.json` (deleted, along with `ArtLoader`'s "journalist" art
  kind and folder — a journalist's portrait is an ordinary opponent
  portrait now). `asked_by` on a question is resolved by checking which
  opponents.json rows list that room's own stage_id in their `stages`
  (`export_data.py`'s `fold_questions()`, `DataDB.get_opponent()`) — the
  same dynamic-by-stage-ID selection every other room uses for its
  opponents, never a hardcoded reporter list or a Role text match.
- **Four opponents (OP15/22/35/40) have a blank Stage on purpose**: each
  shares a name with a protagonist — literally the same character, before
  being cast as playable — so the workbook leaves them out of the dynamic
  pool rather than risk the player fighting themselves.
  `BattleSetup.eligible_opponents()` now also guards this generally: any
  opponent whose name matches the current protagonist's name is skipped,
  whoever they are, so a future addition to the workbook can't reopen the
  same problem (`tests/test_real_battle.gd`'s `test_the_player_never_
  meets_an_opponent_with_their_own_name`).

**Office Notices** (new): one line of Office-screen flavor text per named
slot, each row (`data/office_notices.json`, hand-seeded) conditioned on
whether a staff role is hired or a meta-variable crosses a threshold —
Cameron's own example, `"{staff} is greeting visitors"` /
`"{if reputation < 30} Yezo News has not covered your work recently."` The
first row per slot whose condition holds wins; `OfficeNotices.resolve()` is
pure logic (`tests/test_office_notices.gd`), wired onto the Office screen
as a label under Resources (`OfficeScreen._refresh_notices()`).

**Yoron and Bills removed** (Cameron: "the deletion of yoron (remove that
mechanic)") — see §8's own note. **MOD01 and the caucus rival are gone**:
the old numbered-step Modules sheet was already retired in an earlier
session, and there was never a caucus-rival *mechanic* in code to remove
(no script referenced one) — the phrase only lived in `data/player.json`'s
old placeholder blurb and in this file's own §9, both now corrected to
match the real cast above.

### The 2026-09-27 databook pull: real Floor Vote content

30 real bills (BI01-30), 30 new levels built around them (LV31-60, each
with its own `"BIxx"` slot per §7.7), all six party leaders cast (`Leader
Opp ID` on the Parties tab), and every one of those 30 levels marked
`"One-Time (Yes/No)"` = Yes (§8) — Cameron used the mechanism exactly as
built, on his own, no prompting needed. This closed out every "Cameron's
to write" item §9 used to list for Floor Voting.

One real structural change came with it: the Floor Vote Bills tab **lost
its Level ID column** — the level-to-bill link now runs the other way,
a level names its own bill directly in its stage sequence (see §7.7's
now-current description). `tools/export_data.py`, `DataDB.gd`, and
`BattleSetup.gd` were updated to match (the previous pull's Level-ID-on-
the-bill design lived for about a day). Re-verified against real data,
not fabricated fixtures this time: LV31 (Ainu Heritage and Language Act,
BI01) played through the real `FloorVoteScreen` end to end, and its
resolved totals (45 Yes / 48 No / 8 Abstain) matched the workbook's own
**Vote Tally & Swing** tab exactly — independent confirmation that
`FloorVoteEngine`'s math and Cameron's own hand-check agree. That tab
itself is not exported (`NOT_EXPORTED`): it's a derived check, the same
status as Tone Guide and Assets.

### The 2026-09-27 playtest fixes

A phone playthrough of the 2026-09-27 build turned up nine problems; each
is its own commit.

| # | Problem | Fix |
|---|---|---|
| 1 | Long text ran off the right edge, taking the portrait and "Turn X of Y" with it | Opponent name/intent lines wrap; a room name wraps only when it can't fit on one line (`BattleScreen._fit_stage_name()`), otherwise its Japanese accent stays beside it; energy pips are an `HFlowContainer` and wrap. Edited straight into `BattleScreen.tscn` (§13's note on the drifted builder) |
| 2 | "Name, <null>" for opponents with no Title; several titles overflowed | `OpponentDisplay.title_for()` treats null as blank and shows only the first `;`-separated title |
| 3 | Press conference showed "Question 6 of 20" and was lost on time | `BattleSetup` wrote the whole pool's size into `questions_count`, which the engine reads as how many to ask; that field is now `question_pool_size`. The conference is judged on its threshold (§7.3) |
| 4 | Opening any Floor Vote level froze the game | `int(null)` on ST23's blank reward cells — `MetaRules.stage_delta()` |
| 5 | Any card could be bought outright for XP | "New cards" replaced by **Rhetoric Training** (Office Management): the six card-tier sessions (SH15-17 XP, SH27-29 Yen, moved out of Supplies). "See a card" shows a random unowned card of that tier, front and back, before anything is paid; "Learn it" pays and adds that exact card, "Pass" costs nothing (`GameState.offer_random_card()`/`learn_offered_card()`). Cameron's call, knowing Pass lets a player keep drawing until a card they want appears. `GameState.buy_card()`/`Ledger.card_refusal()` remain only for `tools/playtest_optimal.gd` |
| 6 | Losing showed and cost nothing | §7.4's loss deltas |
| 7 | No limit on consumables (20+ Coffees, 20+ energy pips) | `default_consumable_stack_cap` (§9) |
| 8 | Press conference questions asked by MPs | Workbook data fix, Cameron's choice over a code rule: ST04 added to the 8 journalists' Stage cells (OP110-117) and removed from the 12 MPs that listed it — so the dynamic-by-stage-ID rule still decides, and would need redoing if an older copy of the workbook is uploaded over it |
| 9 | Opponent lines appeared twice, once as "Them: …" | The narrated version of the opponent's move shows only when they have no written cue for it |
| 5b | (follow-up) Unlimited passing in Rhetoric Training | A draw shows up to `card_training_looks` (rules.json, 3) cards with a "1/3" counter; Pass shows the next, the last has no Pass and the pop-up can't be closed, so a draw always ends in a learned card. The draw is saved (`GameState.card_draw`), so quitting mid-draw brings the same card back. Learning is what starts a fresh draw (`GameState.pass_offered_card()`, `can_pass_offered_card()`) |

Ten new Text-tab rows came with 3, 5 and 6 (`reward.if_lost`,
`outcome.reason.conference_short/reached`, `office.rhetoric_training`,
`rhetoric.*`); `office.new_cards`, `office.cards_blurb`, `office.unlock` and
friends are now unused by the game.

### The 2026-09-28 systematic evaluation pass

Asked to design a plan to evaluate every mechanic, not just whatever a
recent playthrough happened to touch. Rather than build new machinery,
this read what already exists (798 GUT tests, 6 real-click interaction
tests, `tools/playtest_optimal.gd`'s full automated playthrough,
`tools/verify.sh`'s CI gate) and found two structural gaps that were real,
not guessed:

- **`tests/interaction/office_hours_test.tscn` and `shop_items_test.tscn`
  existed and passed, but `tools/verify.sh` never called them** — a
  real-click regression in Office Hours or the shop/Rhetoric Training
  flow could ship without the gate catching it. Both are now wired into
  step 4.
- **`playtest_optimal.gd` had no branch for Vote-mode stages** —
  `_play_level()` only ever split Non-combat vs. everything else into
  `_play_battle_stage()`, which builds a `BattleEngine` config and has no
  idea what a bill is. Every one of the 30 real Floor Vote levels
  (LV31-60) hit this; the full-game playtest was blind to a third of the
  level catalog. `_play_vote_stage()` now drives `FloorVoteEngine`
  directly, voting with the player's own party's assumed majority (the
  same no-reallocation case `FloorVoteScreen.gd`'s own real flow falls
  into) — confirmed against real bills, including the same LV31 totals
  (45/48/8) the 2026-09-27 pull verified by hand.

Two new interaction tests close the remaining hole — neither
`FloorVoteScreen.tscn` nor `LevelIntroScreen.tscn`, the two newest screen
families, had ever been opened by a real click before this:
`tests/interaction/floor_vote_driver.gd` (votes on LV31's real bill,
confirms the outcome shows its real 45/48/8 totals and that favorability
moved) and `level_intro_driver.gd` (proves both halves in one run on real
Tier-0 levels: LV01 with nothing written skips straight to its first
stage, LV02 with one fake in-memory cue shows the real hired staffer's
portrait/name/line and routes on correctly). Both now run in `verify.sh`
alongside the other six.

`design/MECHANIC_COVERAGE.md` is the resulting matrix — every stage type,
meta trigger, and shop mechanic against what actually checks it (GUT /
click / playtest), built by reading the real test files rather than from
memory, with the honest "—"s left in. It also names the fifth category
the matrix structurally can't show: six of the 2026-09-27 session's nine
bugs were a correct rule with a GUT test AND a correct screen that had
been click-tested — they only broke with real content at real scale (a
20-question pool, a two-clause title, a phone-width screen). No unit or
click test can catch that class by construction, which is what
`design/PLAYTEST_CHECKLIST.md` is for: a manual pass, one per stage type
plus every meta/shop/save system, each line a concrete action and what
"wrong" looks like.

### The 2026-09-28 mobile playtest fixes

A real-phone playthrough turned up three more problems.

| # | Problem | Fix |
|---|---|---|
| 1 | The flinch reaction on a character's face (yours or the opponent's) was too quick to register on a phone | `FLINCH_SECONDS` doubled, 0.9 → 1.8, in both `OpponentPresenter.gd` and `PlayerPortraitPresenter.gd` |
| 2 | A press conference's drawn question showed no speaker name, and with no name the CueBanner's own coloured name tag stayed hidden — the question read as coming from nobody in particular | `OpponentPresenter.display_name()` deliberately returns `""` in a press conference (no opponent whose support can be taken) — correct for the opponent row's own name label, but `BattleScreen._announce_question()` was reusing it for the banner's speaker name too. Added `OpponentPresenter.question_speaker_name()`, which resolves the real asking journalist the same way `_show_journalist()` already does, and pointed `_announce_question()` at it instead |
| 3 | Scrollbars felt inconsistently fast — some lists used the touch-drag-and-glide feel (`DragScroll`), others fell back to Godot's own default scroll speed | Three scroll views had never been wired to `DragScroll`: the battle screen's own Outcome panel, and the Outcome panel on both `FloorVoteScreen` and `VisitorScreen`. Every scrollable list now goes through the same `DragScroll.attach()` |

**The Office news ticker** (new, 2026-09-28, Cameron): a scrolling strip
along the bottom of the Office screen, the same idea as Office Notices but
for lines that cycle rather than sit still. A new **Office Ticker**
workbook tab (rows: `ticker_id`, `condition_type`/`condition_target`/
`condition_op`/`condition_value` — the exact same condition schema Office
Notices already uses, or `always` for an unconditional line — and
`text_en`) exports to `data/office_ticker.json` the same way Office
Notices does. `OfficeTicker.gd` (pure, `scripts/rules/`) decides which
line is eligible right now and picks the next one at random, never
repeating the line just shown unless it is the only one eligible —
`OfficeNotices.condition_met()` was made public so both files read the
same condition logic rather than duplicating it. Unlike Office Notices
there is no "slot": a ticker can show every line that is currently true,
one after another, instead of picking one winner per subject.
`TickerPresenter.gd` (`scripts/ui/`) owns the actual scrolling and timing,
driven every frame from `OfficeScreen._process()`. Two independent levers,
both in `rules.json`, both Cameron's to retune: `ticker_speed_px_per_sec`
(how fast the current line travels, 50 by default) and
`ticker_pull_interval_seconds` (how long to pause, with nothing showing,
after one line has fully scrolled off before the next one enters — 12 by
default). A line always travels the full width and disappears only once
every letter of it has scrolled past the strip's own left edge — it
originally swapped to a freshly-picked line on the interval alone,
wherever the current one had scrolled to, which cut a line off mid-screen
and popped it out of existence with letters still showing (2026-09-28
mobile playtest; `ticker_pull_interval_seconds` now measures the gap AFTER
a full exit, not a forced swap). Six seed lines (TK01-06) ship in the
workbook so the ticker has something to show out of the box; the rest of
the tab is Cameron's to write.

**A "{player}" token for `text_en`** (2026-10-03): any ticker row — `always`,
`meta`, or `staff_role` alike — can include the literal text `{player}` and
it is filled in with the current protagonist's own name before the line is
shown, e.g. `"{player}'s latest floor speech is already being clipped for
tonight's broadcast."` becomes "Haru Yashi's latest floor speech is
already...". `OfficeTicker.fill_tokens()` does the substitution inside
`eligible_lines()` (so `next_line()` picks up the filled version
automatically); `TickerPresenter._pull_next()` is the one real call site
and passes `DataDB.player.get("name_en", "")` in — `OfficeTicker.gd` stays
pure, never reading DataDB itself. Unlike Office Notices' own `{staff}`
token (only safe on a staff_role row, since that's the only row with a
lookup to resolve it), `{player}` is safe everywhere, since the player's
name is fixed for the whole run. A blank name (no run started) leaves the
token untouched rather than blanking it, so a half-wired caller never ships
a broken-looking line. No workbook rows use it yet — Cameron's to write as
he continues filling out the Office Ticker tab.

### A thorough code stress test (2026-09-28)

Everything above proves a mechanic *works*. `tools/stress.sh` (new) asks
whether it keeps working under punishment — not part of `tools/verify.sh`
or CI, the same bargain `stress_shop_items.gd`/`stress_crisis_triggers.gd`
already strike (minutes, not seconds; run before a release or after
touching `BattleEngine`/`GameState`/`Ledger`, not on every commit).

- **Invariant checks inside `tools/playtest_optimal.gd`'s own battle loop**
  (`_check_invariants()`): deck+hand+discard conservation, guard/gaffe/
  energy bounds, and bar bounds (`BarModel.totals_balance()`), checked
  after every `play_card()`/`end_turn()` against every real stage in the
  game — nothing in `BattleEngine` itself asserts these; it is all soft-
  refusal via `_refused()`. A violation names its own exact reproducer: a
  stage ID and a `BattleEngine` seed (now always explicit —
  `config["seed"]` — rather than left to `setup()`'s own `randi()`
  fallback), since that one seed decides every random roll in a battle.
- **An adversarial mode, same tool**: `PLAYTEST_RANDOM_MOVES=1` swaps the
  greedy best-card heuristic for a shuffled hand played in shuffled order,
  with a real chance of a deliberate pass — explores play orders and
  timings the greedy heuristic never would (discarding whole hands, far
  more deck-empty/reshuffle cycles, far more press-conference declines).
  Losing constantly is expected here, not a bug — only an invariant
  violation, a crash, or a stuck stage is. `PLAYTEST_PROTAGONIST` (falls
  back to the existing hardcoded `PC02`) lets a run sweep all four.
- **`tests/interaction/mash_test.gd`/`mash_driver.gd`** (new): real
  rapid-fire clicks — End Turn spammed, the same card dragged up twice in
  a row, Details opened/closed ten times fast, Vote Yes and a Supplies
  purchase each double-clicked — checking "exactly one effect, no stuck
  UI" rather than re-proving a screen works at all (`click_test.gd`'s own
  job). Confirmed while building it: this codebase's click handlers are
  end-to-end synchronous (check, mutate, refresh, no `await` in between),
  so a same-frame double-submit race structurally can't happen most
  places — these are regression guards more than bug hunts, except for
  the End Turn case, which does cross a real `await` boundary
  (`OpponentPresenter.flinch()`/`PlayerPortraitPresenter`'s own reaction
  animations), and is the one most likely to matter.
- `tools/stress.sh` runs all of the above plus the two existing fuzzers in
  one command, mirroring `tools/verify.sh`'s own shape and reporting.

**Rhetoric Training: only one draw at a time, now said out loud**
(2026-09-28). Cameron asked whether the XP route (SH15-17) and the Yen
route (SH27-29) could conflict or double up a card. They can't duplicate a
card — both draw from the exact same "unowned cards of this tier" pool
(`GameState._unowned_cards_at_tier()`), so a card learned through either
route is in `owned_cards` and out of every future draw regardless of
currency. But `GameState.card_draw` is a single field, so only one
Rhetoric Training draw can be open at a time — tapping "See a card" on a
different row while one is already in progress silently reopens THAT
draw (already true, already tested:
`test_seeing_a_card_again_mid_draw_returns_the_same_card_not_a_reroll`,
"even a different session"), with no explanation for why a different
row's price just appeared. `OfficeScreen._on_see_card()` now compares the
returned draw's own `item_id` against the row actually tapped and, when
they differ, shows a new line (`rhetoric.draw_in_progress`) saying a
session is already open — the draw itself is unchanged, only the player
now knows why.

**Party names, coloured everywhere by their own official RGB**
(2026-09-28). `FloorVoteScreen.gd` already coloured each party's own name
by its `data/parties.json` row (`r`/`g`/`b`, 0-255 each — three separate
keys, not a packed array); three other places showed a party name as
plain text. New `PartyDisplay.gd` (pure, `scripts/rules/`,
`color_for(party: Dictionary) -> Color`, a neutral grey for an unmatched
row so a name never goes invisible) is the one place the RGB→Color
conversion lives now, reused by:
- The New Game protagonist picker (`OfficeScreen._protagonist_row()`) —
  each candidate's own party line.
- The Office header — used to be one `"{name} · {party}"` string on a
  single Label, which cannot colour only part of itself; split into
  `_title` (the name) and a new `_title_party` Label (`"· {party}"`,
  built in code the same way `_notices_label` is) so only the party
  portion carries the colour.
- The battle screen's own Details panel — "You: {name}, {party}" and
  "Opponent: {name}, {party}" used to be two lines inside one big joined
  `_details_text` Label; the party is now two small labels
  (`_you_party_label`/`_opponent_party_label`) appended after it instead,
  each shown only when that side actually has a party (not every
  opponent does).
`FloorVoteScreen.gd`'s own `_party_color()` is untouched — it already
reads the identical RGB from a pre-built `"party_color"` array
(`BattleSetup.gd`'s own Floor Vote position dicts), a different shape
than `PartyDisplay.color_for()`'s `{r,g,b}` row, and was already correct,
so there was nothing to fix there.

### "Your Record" — lifetime stats (2026-09-28)

Cameron asked how a Floor Vote's influence-swing flip (§7.7) gets tracked
— it didn't; the flag lived only for the instant of that one vote. Three
new lifetime counters, bundled into one new Office screen page:

- **`GameState.bills_flipped_by_influence`**: every `bill_id` the
  influence swing has flipped, in the order it happened.
  `GameState.record_bill_flip(bill_id)` (dedup-guarded, though a bill can
  only be voted once since every real Floor Vote level is One-Time)
  is called from `FloorVoteScreen._on_vote()`'s existing flip block.
- **`GameState.levels_cleared`**: `{level_id: win_count}`, bumped once
  inside `finish_stage()`'s existing `if last_level_outcome ==
  LevelRunner.WON:` block — a win only, never a loss, and it can bump
  past 1 on a replayed level.
- **Tier clears are derived, not a third counter**: the Office page sums
  `levels_cleared` by each level's own `tier` at display time rather than
  keeping a parallel tally that could drift out of sync — cheap over the
  ≤60 real levels, and correct by construction.

Both fields are in `_SAVED_FIELDS` (reset with everything else lifetime
on a new run — `bills_flipped_by_influence` in `reset_crisis_triggers()`,
`levels_cleared` in `reset_levels()`). New **"Your Record"** button beside
Organisations, built in code exactly like Inventory beside Management
(`OfficeScreen._build_record()`) — no `.tscn` edit, since `tools/build_
office_scene.gd` is unsafe to rerun (§13). `_show_record()` lists the
flipped bills by their real `bill_name`, each cleared level by its own
`description` and clear count, and clears per tier — all through new
Text-tab rows, per the "no sentence lives in a script" rule.

### Balance tuning and a question-effectiveness multiplier (2026-09-28, Cameron)

Five small, direct numbers, plus one new mechanic, from a single pass
through this file's own open-items list:

- **Floor Vote influence swing** (§7.7): `vote_swing_resistance_default`
  raised 70 → 85 (Balance tab), with three parties now overriding it on
  their own row (Parties tab's own Vote Resistance column, blank = the
  flat default): Frontier Party 75, Five Point Independents 99, Country
  Initiative 90. The other three parties (Butsutou, Yezo Heritage Party,
  Keizaijiyuutou) stay on the flat default.
- **Booster starting standing** (§13's own note on the flat `start`
  fallback): 50 → 30, `data/booster_standing.json`.
- **The Office ticker** (§8): `ticker_speed_px_per_sec` 50 → 70,
  `ticker_pull_interval_seconds` 12 → 10 (`data/rules.json`), each with
  its own dated rationale line alongside the original options, the same
  documented-choice shape every other `rules.json` lever already uses.
- **Whether the Town Hall asks questions** (§9's own list used to carry
  this as unresolved): it already does, and has since 2026-09-25
  (`BattleSetup.QUESTION_POOL_BY_STAGE`'s own `"ST05": "town_hall"` entry,
  proven against real level data by `tests/test_real_battle.gd`'s
  `test_st05_town_hall_actually_answers_its_drawn_question_too`) — the
  §9 bullet was stale, not a real gap, and is now removed.
- **A question's own effectiveness on the card that answers it** (new
  mechanic, redesigned once on the same day — see below): a Strong-graded
  answer now boosts that card's own `self_plus`/`opp_minus` **1.3x** this
  round, on top of the stage's own affinity, and still pleases the asking
  organisation exactly as before (settled 2026-09-21, untouched); a Weak
  one penalizes it **0.7x**; Medium is unchanged. `balance.json`'s new
  `question_strong_multiplier`/`question_weak_multiplier` (one pair of
  numbers across every question-asking room, not per-stage), both
  mirroring `affinity.json`'s own 0.7–1.3 range at Cameron's direct
  instruction. `BattleEngine.question_multiplier_for(card)` composes into
  the same `context["affinity"]` float `CardResolver.resolve()` already
  multiplies by — both `play_card()`'s real resolution and `preview()`'s
  card-zoom read from the same place, so what the zoom promises is what
  play_card() actually does. Shown to the player **before** they play the
  card: a second card-zoom line (`describe_question_for()`,
  `CardBackView.show_card()`'s new `question` parameter) right below the
  existing stage-affinity line, using the same "plain English, not a raw
  multiplier" convention. Both default to `1.0` (no change — today's
  exact behaviour outside a question-asking room) when a config never
  sets them, so every older fixture/test stays deterministic without
  knowing this mechanic exists; `BattleSetup.gd` is the one place that
  reads the real `balance.json` numbers for an actual game. No tone cost
  at all any more on a weak answer — not the old flat
  `weak_answer_tone_cost` (§9, still 1, still exported, now simply
  unread — the same "unused, not removed" precedent `office.new_cards`
  already set), and not an earlier same-day build of this feature (a
  75%-chance-to-cost-tone roll) that Cameron redesigned within the hour
  once he saw it described back to him: that version, and its
  `narration.not_convinced` "No one was convinced" line, are both fully
  gone, not layered under this one.

### A weak answer's own booster penalty, and a per-stage cap (2026-09-28, Cameron)

Two follow-ups once Cameron saw the theoretical-maximum math for how far
one stage's question-answering could move a booster's standing (§8's own
pleasing mechanic, until now a please-only, uncapped-by-anything-but-
dedup system):

- **A weak-graded answer now annoys the same organisation a strong one
  would have pleased**, by `per_displease` (`booster_standing.json`,
  1 — a tenth of `per_please`'s 5, Cameron's literal number). Mirrors
  pleasing exactly: `BattleState.displeased_boosters` (new field,
  deduplicated the same way `pleased_boosters` already is) is populated
  in `BattleEngine._answer_question()`'s `"W"` branch, off the same
  question's `pleases_boosters` list (there's no separate "annoys" column
  in the data — the org a weak answer annoys is the one a strong one
  would have pleased). `BattleEngine.displeased_boosters()` exposes it,
  the same shape as `pleased_boosters()`.
- **The two lists are kept deliberately separate, never merged**: only
  the pleased list carries a buff into a later stage of the same level
  (`LevelRunner.carried_buffs()`) — a weak answer must never grant that,
  so `displeased_boosters` is threaded everywhere as its own value,
  never mixed into `boosters`. `GameState.finish_stage()` gained a 6th,
  end-of-signature parameter, `displeased_boosters: Array = []`, so
  every existing positional call site (there are dozens, across the GUT
  suite) keeps working unchanged. `BattleScreen._on_outcome_closed()`
  is the one real call site, passing `engine.displeased_boosters()`.
- **A hard per-stage cap, both directions**: `GameState._apply_question_
  boosters()` (renamed from `_please_organisations()`, since it now
  handles both) computes one NET change per organisation touched —
  pleased once this stage: `+per_please`; displeased once:
  `-per_displease`; both (two different questions about the same
  organisation, one answered well and one badly): the two amounts settle
  together — then clamps that net to `booster_standing.json`'s new
  `question_swing_cap` (5) before applying it. With today's numbers
  (5 and 1) the cap never actually binds — pleasing alone already sits
  exactly at it — but it is a real, tested ceiling for whenever those two
  numbers get retuned, not just documentation.
- **Shown to the player**, the same "no news is no line" rule the pleased
  list already used: the battle Details panel gets a new "Annoyed so
  far: …" line beside "Pleased so far: …", and the end-of-stage Outcome
  panel gets a new `outcome.displeased` Text-tab row ("Annoyed: {names}.")
  beside `outcome.pleased` — the connection between a bad answer and a
  standing hit is otherwise lost by the time the player reaches the
  Office, the same reasoning `outcome.pleased`'s own comment already
  gives.

### Your Record's Sanban values, a real Media Ambush surprise, and a real Outcome-panel bug (2026-09-28, Cameron)

- **"Your Record" now opens on the four Sanban values** (Constituency
  support, Reputation, Funds, Party support) — `OfficeScreen._show_record()`,
  a new heading ahead of the bills/levels/tiers sections it already had,
  reading straight off `GameState.meta` (live, not the run's starting
  numbers the New Game screen shows) via the same `DataDB.sanban` loop and
  `new_game.stat_line` wording New Game's own `_starting_stat_lines()`
  already uses. New `office.record_sanban_heading` Text row ("Where you
  stand").
- **Media Ambush (ST19) is now a real surprise, not a half one.**
  `stages.json`'s `reveal_in_briefing: "No"` already hid a stage's name and
  opponent in the level briefing, but its win/loss numbers still showed —
  a deliberate earlier choice so the player could weigh the risk. Cameron's
  call this time: remove the stage from the briefing entirely instead —
  no heading, no placeholder, no rewards, no "if you lose" line. Confirmed
  live against LV02 (the real level pairing a Lobbyist Meeting with a
  Media Ambush): the briefing now shows exactly its one other stage and
  nothing else. `office.briefing.surprise_stage`'s old placeholder text is
  now unread, same "unused, not removed" precedent as `office.new_cards`.
- **A real bug, found chasing down what turned out to be a vague report**
  ("the negative outcome values are not displaying"): `OutcomePresenter.
  _body_for()`'s loss branch returned early, before the code that prints
  which organisations the player's answers pleased or annoyed — that block
  only ever ran on the WIN path. The standing change itself was always
  applied correctly (`GameState.finish_stage()` doesn't care about
  outcome for that); only the one place that explains WHY a booster's
  number just moved stayed silent, and only on the stage that lost. Fixed
  by moving the pleased/displeased lines ahead of the win/loss branch, so
  both show regardless of outcome. `tests/test_outcome_presenter.gd` (new)
  proves it two ways — confirmed failing before the fix, passing after:
  a lost stage's displeased organisation reaches the panel, so does a
  pleased one, and the loss's own cost line (Constituency support etc.)
  is untouched alongside it.

### A text veil behind the Office's floating text (2026-09-28)

The Office's header ("Kenshin Sako · Frontier Party") and its flavour-text
block (the last-level report, "XP · Funds", Office Notices) both sat
directly on the bookshelf background and the protagonist's own art with
only the screen's single uniform `BackgroundScrim` (0.55 alpha) behind
everything — legible, but low-contrast against a busy, lit background,
and the text visually crowded the character rather than reading as its
own layer. Cameron's ask: the same idea `CardBackView.gd`'s own veil
already uses behind a card's printed text, so the text reads as sitting
on its own surface rather than painted onto the art.

`scenes/office_hours/OfficeScreen.tscn`: a new shared `StyleBoxFlat`
(`Color(0.06, 0.05, 0.04, 0.6)`, rounded 18px corners, ~20/14px content
margins) backs two new `PanelContainer`s — `HeadingBackdrop` around the
title row, and `TextBackdrop` (wrapping a new `TextColumn` VBoxContainer)
around the Report/Resources block. Office Notices — built in code,
inserted at runtime right after `%Resources` via `_resources.get_parent()`
— needed no code change at all: that lookup now resolves to the new
`TextColumn` instead of the old bare `Column`, so the notices lines land
inside the same backdrop automatically. The Ticker strip already had its
own dedicated `TickerBackground` (0.85 alpha) and was left alone.

**Widened to near-full screen width** (2026-09-28, same day, Cameron's
follow-up): both boxes first shipped shrink-to-fit, hugging just their own
text — too narrow once seen on a real screenshot. Now each sits inside its
own `MarginContainer` (`HeadingBackdropMargin`/`TextBackdropMargin`) with
a 21.6px margin each side — 2% of the 1080px base width, Cameron's own
number — and the `PanelContainer` inside fills that margin's full
remaining width. That 2% is measured from `Safe`'s own already-inset
content area, not the true device edge: `Safe` (`MarginContainer`, 40px
each side) exists specifically for device safe areas (notches, rounded
corners, §3's own hard constraint), and these two boxes are the only
content on this screen that isn't already governed by it in some other
way, so shrinking that margin itself, or letting a box bleed past it, was
not this fix's call to make on its own. Confirmed by a real screenshot
before and after each change, not just a scene-file read.

## 12. Working agreement

- **Explain like a colleague, not a manual.** Keep it short and plain English, and say what changed and why.
- **Ask before** you add a dependency, change a data schema, rename an ID, or resolve anything marked open or canon.
- **Never hardcode content** to get something working faster. If data is missing, use a placeholder and flag it.
- **Keep rules separate from visuals.** `/scripts/rules/` must run without any UI (tests prove this).
- **Test the rules**: every bug fix in the rules engine gets a test.
- **Small commits**, each with a message a non-programmer can read.
- If a task will take more than about 150 lines of new code, outline the plan first and wait for approval.
- When you are unsure, **say so** and offer 2–3 options with your recommendation.

### Three Office wording/structure changes (2026-09-28, Cameron)

- **"The organisations" → "Important Stakeholders"** — `OrganisationsButton`'s
  own hardcoded `.tscn` text and the `office.organisations` Text-tab row both
  updated; nothing else reads that wording.
- **Shop moved out of Office Management and into the Inventory screen,
  which is now called "Marketplace"** — `_show_supplies()` is gone;
  `_show_marketplace()` shows the held-items grid (`InventoryPanel.
  inventory_rows()`, split out for this) followed by the Supplies listing,
  in one panel. `InventoryPanel` (shared with the battle screen) gained a
  `reopen: Callable` so using an item from the Office's Marketplace comes
  back to the whole merged view rather than narrowing to the plain grid —
  the battle screen's own `InventoryPanel` instance never sets it, so its
  behavior is unchanged. A new `office.marketplace` Text row was added
  rather than reusing `inventory.button`/`inventory.title`, which the
  battle screen's own mid-stage Inventory button also reads — renaming
  those would have relabeled that button too.
- **"Cosmetic Packages" → "Appearance and Music"** — `office.cosmetics`
  Text-tab row updated.

All three interaction-test drivers that hardcoded the old Office
Management → Supplies path (`mash_driver.gd`, `shop_items_driver.gd`,
`inventory_driver.gd`) were updated to the new one-click Marketplace path.
Full GUT suite and `tools/verify.sh` confirmed green afterward.

**The Marketplace panel reordered** (2026-09-29, Cameron, from a real
screenshot): the panel used to open on its own "Marketplace" title with
the held-items grid (or "Nothing here yet…") sitting directly under it,
then a "Supplies" heading further down for the blurb, XP/Funds, and the
buyable rows. Cameron's read: the "Nothing here yet. Supplies you buy or
are given will appear here." line is really about Supplies, not about the
Marketplace heading it sat under — and he wanted "Supplies" to be what
opens the panel, with "Marketplace" as a second heading further down,
right above XP/Funds. `OfficeScreen._show_marketplace()` now opens on
`Text.say("shop.supplies")` (the panel's own title) with the blurb and
`InventoryPanel.inventory_rows()` first, then a `UiKit.heading("office.
marketplace")` row directly above the XP/Funds lines and the buyable
Supplies rows. No Text-tab or schema change — both keys already existed,
only which one is the panel title and where the other one sits as a row
changed. Confirmed with a real screenshot (`xvfb-run … "$GODOT" --path .`
— no `--headless`, since that swaps in the dummy renderer and
`get_viewport().get_texture()` comes back null) before deleting the
throwaway driver, the same convention as every other UI-only change this
session.

**A random Grants outcome now says which organisation it landed on**
(2026-09-29, Cameron): using a Commission item (SH01-03, Grants a random
booster from a tier) used to just say "{name} used." — the same generic
line every item gets, whether its effect was random or not. Which
organisation actually got the standing bump was only ever inferable
later, from Important Stakeholders' own "(+1)" line next to whichever one
moved. `GameState._apply_reward_entries()` now returns every entry it
actually applied (`{"kind","id","delta"}`, a BOOSTER_TIER pick recorded
as the concrete BOOSTER it resolved to), and `use_item_in_office()`/
`use_item_in_stage()` turn that into a "{name} used — {org} {+/-N}."
message (`_describe_grant_outcomes()`) whenever a booster or segment was
touched — a plain modifier or shop-item grant is left alone, since its
own name already says exactly what it is, nothing rolled. Three new Text
rows (`item.used_with_outcome`, `item.queued_with_outcome`,
`item.queued_level_with_outcome`), same wording shape as the existing
`item.used`/`item.queued`/`item.queued_level` rows they sit beside.

**A combat stage can now be won instantly by arguing the opponent down to
nothing** (2026-09-29, Cameron). CLAUDE.md's own §7.2 already described
"arguing a debater's seats down to nothing" as a way to end them short of
the threshold, but that branch (`BattleEngine._check_outcome()`) only
ever fired for `sequence_mode: "continuous"` — a shape built for the
floor debate but never actually used by any of the 23 real stages
(`stages.json`'s own `sequence_mode` column is `single` or `reset`
everywhere), so the rule was a dead seam, not something a real battle
could ever trigger. Generalized to fire whenever the room has a real
threshold to race toward at all (`has_threshold`, already computed just
above it — every Shared_pool Combat stage, i.e. not a press conference
and not the TV debate's survival bar) rather than only in the one
sequence_mode nothing uses: `state.bar.opponent <= 0` now ends a
single-opponent room outright, and ends the current bout of a committee
sequence the same way a threshold win already does
(`has_more_opponents()`/`_advance_to_next_opponent()`, both untouched).
The existing threshold-win check runs first in `_check_outcome()`, so a
turn that both crosses the threshold AND empties the opponent is still
an ordinary win, never this one — confirmed by a GUT test doing exactly
that.

Whichever opponent was argued out this way costs their own organisation
standing: `BattleState.crushed_opponent_boosters` (deduplicated per
stage, the same shape `displeased_boosters` already uses), read off the
opponent's own `affiliation` field (`opponents.json`) in the new
`BattleEngine._register_crushed_opponent()`, applied as a flat
`-instant_win_penalty` (2, hand-maintained in `booster_standing.json`
beside `per_please`/`per_displease` — that file is never exported, so no
workbook edit needed for the number itself) via the new `GameState.
_apply_instant_win_penalties()`, called from `finish_stage()`'s new 7th,
end-of-signature `crushed_boosters` parameter — the same positional-
default pattern `displeased_boosters` used, so every existing call site
keeps working (`BattleScreen._on_outcome_closed()` is the one real
caller, passing `engine.crushed_opponent_boosters()`). This is a
separate, simpler penalty from the please/displease netting a question's
own grade already applies — never capped or netted alongside it, since
it isn't about a question at all. Shown on the Outcome panel as a new
`outcome.crushed` line ("Argued out of the room: {names}.") beside
`outcome.pleased`/`outcome.displeased`, same reasoning as always: a
standing hit nobody's told about may as well not have happened.
Confirmed against a real level/stage/opponent (LV08's ST02, a real
opponent affiliated with BO17): opponent's support driven to zero ends
the stage in a win with the real "argued out of the chamber" text, and
BO17's standing drops from 30 to 28.

**The Floor Vote party row laid out as a semicircle instead of one
compressed line** (2026-09-30, Cameron, from a real screenshot): six
full portrait-plus-cue cards in a single `HBoxContainer` overlapped and
compressed on a 1080px-wide screen — nothing to scroll to, just too
narrow to hold six 100px-wide blocks of wrapped sentence text side by
side. `PartyRow` is now a plain `Control` (position managed in code,
not by an HBoxContainer's own layout pass) and `FloorVoteScreen.
_show_parties()` positions each of the six fixed card nodes along an
arc — left to right in the bill's own position order (Butsutou, Yezo
Heritage Party, Frontier Party, Five Point Independents, Keizaijiyuutou,
Country Initiative, since that is simply the order `floor_votes.json`'s
own Floor Vote Party Positions rows are in for every real bill), a dome
shape with the two middle parties highest and the two end ones lowest —
the way a hemicycle's own back benches are usually diagrammed. **Spacing
is even in x, not in angle**: the first version spaced the six cards at
equal angles around a true semicircle, which — since cosine bunches near
0°/180° — crowded the two end cards hard against their neighbours
(caught on a real screenshot, not guessed at); recomputed to evenly
spaced x positions with a sine-curve height instead, which keeps the
same dome look with a guaranteed gap between every card. Portraits and
cue text both widened 100→150px alongside the fix, since a 150px-wide
sentence wraps to noticeably fewer lines than a 100px one.
`tests/interaction/floor_vote_driver.gd`'s own `PartyRow` type
annotation updated to match (`Control`, not `HBoxContainer`);
`floor_vote_test.tscn` confirmed still green afterward.

**A committee's "final blow" line named the wrong opponent**
(2026-09-30, Cameron, from a real screenshot): finishing off a
committee member mid-sequence showed something like "Atsuko Takeo is
finished — Yuki Kasukasa rises, ... argued away from Yuki Kasukasa" —
crediting the seats to whoever had just RISEN, not whoever was actually
argued down. `BattleScreen._play_selected()` read
`OpponentPresenter.display_name(engine)` AFTER `engine.play_card()`
returned — but a card that finishes the current opponent (a threshold
win, or the new instant-win mechanic above) already advances the engine
to the next one inside `play_card()` itself, so by the time the name was
read it was already the new opponent's. `_on_end_turn()` right below it
already reads its own `acting_opponent`/`speaker` BEFORE `_refresh()`,
with a comment explaining exactly why — the same care had just never
been applied to the player's own card-play narration path. Fixed by
capturing `acting_opponent_name` right after `preview()` (still the true
opponent) and before `play_card()`, then using that captured value
instead of a fresh read. Confirmed against a real committee (LV09/ST01):
forcing a lethal card against the first of three opponents, the
narration built from the name read after `play_card()` said "argued
away from Aoi Oba" (who had just risen); built from the name captured
before, it correctly said "argued away from Ayala Taiyounokage" (who
was actually beaten) — the exact bug, reproduced and confirmed fixed.

**A lesson worth keeping for later workbook edits**: `openpyxl` is safe
for *reading* `design/CoP_Starter_Card_Stage_Data.xlsx`, but a direct
`load_workbook()` → edit → `save()` round-trip silently corrupted the
Sanban tab's start/min/max values this session — caught only by
`export_data.py`'s own validation (3 errors), not by a before/after diff
that also used openpyxl to read both sides. Any future workbook edit
should use the raw-XML zip-surgery technique already established earlier
in this file's own history (edit the XML fragment directly, re-zip, then
confirm with a clean `export_data.py` run — never trust an openpyxl-based
diff alone). Confirmed again this session on comment-only edits (see
below): a plain `load_workbook()` → add-comments → `save()` round trip
still wiped every formula-cell cache on the Stages tab (`win_pct`,
`segment_check`, `favored_suit` all read back `null`) even though no
value was touched — caught the same way, by a clean `export_data.py`
diff immediately after, and reverted before it ever reached a commit.

### Defunct shop items removed; three player-facing raw-ID leaks fixed; Sanban deltas shown; workbook columns get their permutations (2026-09-30, Cameron)

Four small, independent asks in one pass.

- **Two defunct shop entries removed.** SH13/SH14 ("Unlock Tier 1/2
  Level") and CP01/CP02 ("Neon Ambition"/"Quiet Chamber") deleted
  outright from the Shop and Cosmetic Packages tabs — both rows'
  worth of feature, unpurchased content that had nothing behind it
  worth keeping in front of a player. Neither mechanism was torn out:
  `buy_random_level()`, the whole Cosmetics/Appearance-and-Music page,
  `CosmeticPieces.gd`, `ArtLoader`'s variant axis and `Audio`'s music
  override all stay exactly as built, the same "empty is a valid state"
  bargain every other optional table in this project already keeps —
  nothing stops Cameron from writing new rows into either tab later.
  Eight test/tool files that hardcoded these six specific IDs
  (`test_cosmetics_game_state.gd`, `test_cosmetic_pieces.gd`,
  `test_art_scheme.gd`, `test_save_load.gd`, `test_inventory.gd`,
  `shop_items_driver.gd`, `cosmetics_driver.gd`,
  `stress_shop_items.gd`) were updated to inject synthetic fixture rows
  straight into `DataDB` for their own duration instead — the same
  "fake row" technique `floor_vote_driver.gd`/`level_intro_driver.gd`
  already used for a table with nothing real in it.
- **Two real raw-ID leaks fixed.** The level briefing panel
  (`OfficeScreen._on_level_chosen()`) was titling itself with the raw
  `level_id` ("LV31") instead of the level's own `description` — its
  stated fallback text ("Before you go in") could never actually fire,
  since every real level has a `level_id`. The battle screen's own
  Details panel (`BattleScreen._refresh_details()`) printed
  `"Stage: Floor debate (ST02)"`, the raw `stage_id` included
  unconditionally; now just the name. A full audit of every other
  `.open()`/`.text =` call across `scripts/ui/` turned up nothing else
  unconditional — the remaining `get("name_en", some_id)`-style
  fallbacks only ever surface an ID on data that's missing entirely,
  which is the existing, intentional placeholder bargain, not a leak.
- **Sanban's own page ("Your Record") now shows a `(+N)`/`(-N)` next to
  each of the four meta-variables**, the same treatment Important
  Stakeholders already gives a booster's own recent change
  (`GameState.last_booster_change`). The underlying field,
  `last_meta_change`, already existed and was already being written on
  every stage reward — it had simply never been read anywhere. Two
  small fixes were needed to make it tell the truth: it used to reset
  itself at the top of `_apply_stage_rewards()`, per-stage, which would
  have wiped a Floor Vote's own favorability/influence-bonus swing
  before the Office ever got to show it (those land on Sanban via
  `apply_floor_vote_favorability()`/`apply_floor_vote_influence_bonus()`
  earlier in the same flow, before `finish_stage()` runs) — the reset
  was removed so it now scopes to the whole level, the same as
  `last_booster_change` already does. And three call sites that were
  genuine stage/vote *outcomes* — the Floor Vote's own favorability and
  influence bonus, and the lifetime-gaffe Constituency-support penalty
  — were routed through `_apply_meta_reward()` instead of the plain
  `_move_meta()` they'd used before, since only the reward-shaped path
  records into `last_meta_change`; `_move_meta()` itself is untouched
  and still deliberately silent for the Office's own spending (buying,
  hiring, firing), per its own existing doc comment — a purchase was
  never meant to look like a reward.
- **19 header-cell comments added to the workbook**, one per column
  whose values come from a closed set of text options rather than free
  prose: Stages' Mode/Bar Model/Energy Mode/Sequence Mode/Reveal In
  Briefing/Loss Ends Level/Reputation Affects Start, Cards' Type/Tier,
  Modifiers' Effect Type, Boosters' Tier, Floor Vote Party Positions'
  Disposition, Opponent Cues' Verb, Vote Influence Triggers' Enabled,
  Vote Influence Cues' Outcome Direction, and Office Notices'/Office
  Ticker's shared condition_type/condition_op pair — each comment
  spelling out the real permutations read straight from the code that
  consumes that column (`BarModel.gd`, `BattleEngine.gd`,
  `OfficeNotices.gd`, `export_data.py`'s own validation, and the real
  distinct values already in the exported data), not guessed at. Built
  by hand as raw comment/VML-drawing XML parts (`xl/commentsN.xml`,
  `xl/drawings/vmlDrawingN.vml`, one new worksheet `_rels` file per
  sheet, a `<legacyDrawing>` element added to each sheet, two new
  `[Content_Types].xml` entries) rather than through openpyxl, for
  exactly the reason the lesson above already gives — confirmed by
  reading the comments back with openpyxl (safe) and, more importantly,
  by a clean `export_data.py` diff showing zero data changes.

### A Level Buff's own Extra Guard bonus vanished after the first opponent in a committee (2026-09-30, Cameron)

Reported as "shop items that provide a bonus across a full level are not
working — the bonus applies only to the first stage used in." Confirmed
with a throwaway headless repro (deleted before commit, this session's
own convention) before touching any code: an item bought before a level
begins correctly reaches every real stage of that level — `GameState.
level_bonuses` isn't cleared between stages, and `take_item_bonuses_for_
stage()` hands it to a fresh `BattleEngine.setup()` each time, confirmed
against two real multi-stage levels for both a "bought in the Office" and
a "used mid-stage" purchase. The real bug was one level narrower than
"stage": inside a SINGLE committee stage (`sequence_mode: "reset"`,
§7.5), `BattleEngine._reset_for_new_bout()` unconditionally set
`state.block = 0` for every opponent after the first, with nothing to
re-grant an Extra Guard (Level Buff) item's own starting bonus. Energy
and hand-size bonuses never had this problem — they live in
`state.energy_per_turn`/`state.hand_size`, fields `_reset_for_new_bout()`
never touches — but guard is spent, not merely a baseline, so its bonus
had nowhere to survive a bout reset. To a player, a committee's full
support/gaffe/hand/deck reset between opponents already reads as "a new
fight," which is exactly why this shipped as "only the first stage."

Fixed by remembering the amount, not just applying it once: a new
`BattleEngine._item_guard_bonus` instance var accumulates every GUARD
application (`_apply_item_bonus`'s own "GUARD" case, whether from
config's `item_bonuses` at `setup()` or a Stage-duration item used
mid-battle — either way it's this stage's bonus, and a committee's
several opponents are all one stage), and `_reset_for_new_bout()` now
sets `state.block = clampi(_item_guard_bonus, 0, state.guard_cap)`
instead of a flat `0`. `tests/test_battle_engine.gd`'s new
`test_a_level_buffs_guard_bonus_carries_into_every_new_bout()` sits
right beside the existing `test_a_new_committee_bout_clears_both_banks()`
it's a variant of — the old test (no item bonus in its config) still
correctly asserts a plain `0`, since `_item_guard_bonus` defaults to
that; the new one uses the same fixture with `"item_bonuses": {"GUARD": 1}`
and asserts `1` survives the reset. `tools/verify.sh` confirmed green
afterward.

### SH19's own Funds cap increase was silently ignored by stage rewards (2026-09-30, Cameron)

Reported as "the yen/funds cap is not working — Funds accumulate beyond
the cap." Traced every place Funds is written before touching anything:
`GameState._move_meta()`/`_apply_meta_reward()` (Office spending, the
Floor Vote's own favorability/influence bonus, the lifetime-gaffe
penalty) all clamp correctly against `_sanban_row("Funds")`, which
already raises the ceiling by `funds_cap_bonus` (SH19, "Increase Office
Funds Cap," repeatable). A stage's own `win_delta_yen`/`loss_delta_yen`
and its score-effects path — `GameState._apply_stage_rewards()`, the one
place that actually pays out after a battle — went through `MetaRules.
apply_win_deltas()`/`apply_loss_deltas()`/`apply_score_effects()` with
`DataDB.sanban` passed in **raw**, un-adjusted for any purchased bonus.
The clamp itself was never missing (a real headless repro confirmed
Funds never exceeded either max, whichever one a given path happened to
check) — the bug is that stage rewards were capping against the flat
*workbook* number even after the player paid Yen or XP to raise it,
silently discarding the difference: buy SH19, win a stage, and the extra
headroom you paid for never landed. Read literally ("beyond the cap")
this is the mirror image — Funds falling short of the cap the player
actually has — but it's the one real inconsistency anywhere in the Funds
cap system, and "the cap isn't working" is an accurate description of a
stage-reward path quietly enforcing the wrong one.

Fixed with one new method, `GameState.sanban_rows_with_bonuses()` —
`DataDB.sanban`, with Funds' own row replaced by `_sanban_row("Funds")`'s
already-correct bonus-adjusted version, a no-op array copy when
`funds_cap_bonus` is 0 so nothing changes for a run that never bought
SH19. `_apply_stage_rewards()`'s three `MetaRules` calls now read from
it instead of `DataDB.sanban` directly. `OutcomePresenter._what_it_was_
worth()` had the identical bug, one layer up — it recomputes the same
deltas purely to show "+N Funds" on the outcome panel, and was reading
`DataDB.sanban` raw too, which would have kept promising the old amount
right after this fix corrected what actually lands — now reads
`GameState.sanban_rows_with_bonuses()` as well, so the panel and the
real payout always agree. New `tests/test_game_state_meta_tracking.gd`
coverage: a stage win near the flat max still clamps there with no
bonus bought; the same win with `funds_cap_bonus` set lands the full
delta past the old flat max instead of being clamped short.

### A combat stage can now be lost instantly too — the player's own support argued down to nothing (2026-10-01, Cameron)

The mirror image of 2026-09-29's instant win (§12, "A combat stage can
now be won instantly by arguing the opponent down to nothing"): where
that rule fires when `state.bar.opponent <= 0`, `BattleEngine._check_
outcome()` now checks `state.bar.player <= 0` right after it, under the
same `has_threshold` gate (every Shared_pool Combat stage — not a press
conference, not the TV debate's survival bar, not a scored stage), and
ends the stage outright in a loss (`outcome.reason.player_argued_out`,
a new Text-tab row). Two design calls, made rather than left for Cameron
to discover by accident, both because the opponent's own side of this
rule already settled them the same way:

- **It ends the whole stage, not just the current bout.** A committee's
  own instant-win advances to the NEXT opponent when the one in front of
  you is emptied out, because there's a fresh opponent waiting;
  symmetrically there is no fresh *player* waiting once the one at the
  table has been argued down, so `state.bar.player <= 0` is an outright
  loss even mid-sequence, never a bout reset.
- **A turn that empties both sides at once is a win, not a loss.** The
  existing opponent-emptied-out check already runs earlier in
  `_check_outcome()` than this new one, so the same priority the
  threshold-win check already enjoys over the opponent's own instant-win
  extends one step further: cross the threshold → win; empty the
  opponent → win; only then, empty your own side → loss. A single card
  that happens to drain both at once still reads as an ordinary win, the
  same reasoning CLAUDE.md already gives for threshold-vs-opponent-empty.

No stage in `stages.json` starts at `player_start: 0` for a Combat room
(only two Non-combat rows do, which never reach `BattleEngine` at all),
and `_check_outcome()` is only ever called after a card resolves or a
turn ends, never at `setup()` — so this cannot fire before the player
has had a turn. `tests/test_battle_engine.gd` gained three tests
alongside the existing opponent-side ones: a single-opponent room and a
mid-committee-sequence room both end outright in a loss when the
player's own support is driven to 0, and a turn that empties both sides
at once is confirmed still a win.

### The Level Intro screen gets a bill-lean choice (2026-10-01, Cameron)

Cameron's ask: on a bill level's Level Intro screen, after the staff
finish speaking, show the player protagonist's own internal thought about
the level, then let them pick "Lean Support" or "Lean Oppose" on the
bill's topic — two boxes, each with the player's own party leader's
headshot. The choice moves Party support ± depending on whether it agrees
or disagrees with the party's own stance on the bill.

- **Scope**: only a level that names a Floor Vote bill
  (`DataDB.get_floor_vote(level_id)` non-empty) gets this step — this is
  the level's own bill, read off whichever of its `stage_1..stage_10`
  slots names a `BIxx`, exactly §7.7's existing lookup. `OfficeScreen.
  _on_start()` now routes to the Level Intro screen on EITHER a written
  staff cue OR a bill, where before it was staff cues alone — a bill
  level with no staff cues at all still gets this screen now, since the
  lean choice is its whole point. `LevelIntroScreen.gd`'s own sequencing
  gates `%ContinueButton` (`disabled = true`) the moment a bill is
  present, so the choice can never be skipped by clicking through fast —
  the one place this screen needed real gating, since before this it had
  none at all (`_on_continue()` was always clickable).
- **Three new pieces of workbook data**, all per the user's own
  instruction that every number and line of text stay editable in the
  workbook, not hand-rolled in a script or a hidden JSON table:
  - A new **Level Intro Thoughts** tab (`data/level_intro_thoughts.json`,
    optional, blank-tolerant, one row per level_id) for the player's own
    thought line — kept as its own tab rather than another row on Level
    Intro Cues, since that tab's key is (level_id, role) and a thought
    isn't any one staff member's role, it's the level's own.
  - A new Balance lever, **"Lean: Party Support Delta"**
    (`balance.json`'s `lean_party_support_delta`, 2 — first-draft,
    Cameron's to retune) — the ± magnitude applied either way.
  - Two new Text rows, `level_intro.lean_support`/`level_intro.
    lean_oppose` ("Lean Support"/"Lean Oppose"), the two button labels.
- **"The party's position" is the bill's own Disposition** (Floor Vote
  Party Positions' existing Supportive/Opposed/Neutral column for the
  player's own party), not a vote-tally bucket — it's the field already
  designed to answer exactly this question. A Neutral disposition never
  rewards or penalizes either lean, since there's no stance to agree or
  disagree with. New pure rule, `scripts/rules/BillLean.gd`
  (`party_support_delta(own_position, lean, magnitude)`), and
  `LevelIntroCues.player_thought(thoughts, level_id)` for the thought
  lookup — both pure/UI-free per §12, both covered by new GUT tests
  (`tests/test_bill_lean.gd`, `tests/test_level_intro_cues.gd`'s new
  cases). The delta lands via the same `GameState.apply_floor_vote_
  favorability({own_party: delta})` a real Floor Vote's own favorability
  already uses — no new apply path.
- **UI**: two new cards on the Level Intro screen, each a leader portrait
  (`parties.json`'s `leader_opp_id`, the player's own party — both boxes
  show the same single leader, since there's only one) above a button,
  built via `tools/build_level_intro_scene.gd`'s new `_add_lean_row()`/
  `_add_lean_card()` (that tool is confirmed safe to rerun, unlike
  `build_battle_scene.gd` — see §13's own note). Hidden until every
  staff/thought line has shown, the same `lines_shown` polling
  `_process()` already used for swapping the speaking portrait.
- Confirmed end to end with a throwaway driver (deleted before commit,
  this session's own convention) against a real level (LV31, the Ainu
  Heritage and Language Act / BI01) and a real protagonist (PC02,
  Frontier Party — Opposed on BI01): Continue stayed disabled until a
  lean was picked, the leader portrait resolved to Frontier Party's own
  leader (OP27) on both boxes, picking "Lean Oppose" (aligned with the
  party's own Opposed stance) moved Party support by the full +2, and
  "Let's go" correctly landed on the level's own real first stage
  afterward.

### A text audit: 25 more sentences moved out of scripts and into the workbook (2026-10-01, Cameron)

Asked to review every `.gd` file for text that should have been a Text-tab
row and move what qualified. A systematic grep across `scripts/ui/` and
`scripts/rules/` for quoted English sentences, filtered by hand, found a
real, bounded set — several of them sitting right next to an already-
converted sibling line, which is what made them easy to confirm as gaps
rather than a deliberate exception:

- **`BattleScreen.gd`'s `describe_room_for()`** (the card-zoom's stage-
  affinity line: "Being greatly enhanced by supporters.", etc.) — its own
  sibling, `describe_question_for()` right below it, already read its
  three lines from `card.question_strong/medium/weak`; this one never
  had been. Five new keys, `card.room_greatly_enhanced/enhanced/neutral/
  suppressed/greatly_suppressed`.
- **The battle Details panel**, mostly converted already (`battle.
  one_at_a_time` was already `Text.say()`-driven) but with real gaps
  beside it: the always-visible "Gaffes {current} / {limit}" status-row
  label (`battle.gaffes_status`), the "You: {name}"/"Opponent: {name}"
  lines (`battle.you_name`/`battle.opponent_name`), "In the room:
  {mix}." (`battle.room_mix`), the shared-pool rules paragraph
  (`battle.shared_pool_rules`), "This question invites a {suit} answer."
  (`battle.question_invites`), and the pleased/annoyed lines
  (`battle.nobody_pleased`/`battle.pleased_so_far`/`battle.
  annoyed_so_far`).
- **`Overlay.gd`'s own default "Back" button label** — the widest reach
  of anything found, since every panel in the game that uses `Overlay`
  gets it. New `ui.back`, read in both of `Overlay.gd`'s two call sites
  (`_build()`'s own default, and `open()`'s fallback when no `back_text`
  is given).
- **`LevelIntroScreen.gd`'s own "Let's go"** — inconsistent with its own
  newer sibling, `StageTransitionScreen.gd`, whose equivalent button
  already read `stage_transition.continue`. New `level_intro.continue`.
- **The Office header** — `"{name}'s Office"` (shown only when the
  protagonist has a name but no party; `office.title_named`) and the
  header's own small Japanese accent, `"陳情"`, which was typed directly
  into the script rather than read from the Text tab like every other
  Japanese accent in the game (`office.subtitle_jp`).
- **The Levels list and briefing panel**, again partially converted
  already (`reward.delta`, `reward.nothing_set` sit right beside these):
  the list's own blurb (`office.levels_blurb`), "Tier {tier}" headings
  (`office.tier_heading`), the panel's own title (`office.levels_title`),
  a per-stage "What winning this is worth has not been set yet."
  (`reward.stage_not_set` — distinct from the existing `reward.
  nothing_set`, which is for a whole level with nothing set at all), the
  briefing's fallback title (`office.briefing_fallback_title` — a
  fallback only; every real level has its own `description`, so this
  cannot currently show) and its "Go in" button (`office.go_in`).
- **The level-start refusal message**, "This level cannot start:\n•
  {problems}" (`office.level_cannot_start`), at both of its two call
  sites (`OfficeScreen.gd`'s `_on_start()` and its resume-mid-level
  path).
- **One title reused rather than duplicated**: the Backing panel's own
  `_backing_panel.open(...)` call was passing the literal string
  "Backing" as its title, when `office.backing` ("Backing") already
  existed — it is the Office button that opens this same panel, just
  never reused for the panel's own title. No new key needed there.

**What was NOT moved, and why** — three categories deliberately left as
code, not oversights: the rules-layer's own diagnostic strings
(`LevelRunner.problems()`, `BattleEngine`'s `setup_problems`/
`_refused()`, `IntentRunner`, `FloorVoteEngine`, `OfficeHoursEngine` —
workbook-authoring-mistake messages like "a stage has no seq number",
not narrative content; moving them into the workbook that is broken to
explain the breakage would be circular); `BootCheck.gd`'s own labels
("Game data", "Floor debate") — a developer/QA diagnostic screen (§11's
M0), not player-facing gameplay; and internal lookup constants
(`Ledger.STAFF_ROLES`, `ModifierEffects`'s Jiban→"Constituency support"
map, `FloorVoteEngine.BUCKETS`) that have to match real data elsewhere
and are not duplicated sentences at all.

25 new Text-tab rows (344-368), same raw-XML workbook technique used all
session. Confirmed with a throwaway driver (deleted before commit): a
real screenshot of the Office (the "陳情" accent rendering correctly next
to the English title), the Levels panel (blurb, "Tier 0" heading, no
raw keys or unfilled placeholders), and a real battle's Details panel
("You: Haru Yashi · Frontier Party", "Opponent: Yuriko Mayeda · Frontier
Party", the room-mix and shared-pool-rules lines) — all reading real
wording, not keys or `{placeholders}`. Full GUT suite (922 tests) and
`tools/verify.sh` (including `click_test.gd`, which clicks "Back" on
real overlay panels, and `loop_test.gd`, which plays a real battle
through `BattleScreen`) both confirmed green afterward.

## 13. The seams that are built but carry nothing

These systems have working structure while some content remains incomplete.

**The noticeboard.** `EventBus` carries eight signals, and the rule for that
file is now written into it: *a signal exists only if something emits it.*
Five that nothing emitted were deleted. What is there:

```
card_played(card_id, result)        turn_started / turn_ended(turn)
intent_revealed(intent)             gaffe_changed(value, delta, limit, final)
battle_ended(outcome, reason)       meta_changed(name, value, delta)
                                    xp_changed(total, delta)
```

`gaffe_changed` fires only when the meter actually moves, and carries the
direction, so a sound can tell a gaffe earned from a gaffe cleared.

**Audio.** `scripts/autoload/Audio.gd` listens to the noticeboard and plays
whatever `data/sounds.json` names against each moment. Three buses — Music,
Effects, Speech — so they mix separately, which spoken lines will need. **No
filename appears in any script.** There are no sound files, so the game is
silent; a named file that is missing logs one quiet line and is ignored, the
same bargain `ArtLoader` strikes with art that has not been drawn.

**Portrait expressions.** `OpponentPresenter` picks a face from what is
happening — attacking, guarding or gaining to match the intent they are
winding up, damaged when their support has fallen (and for a moment after a
card hits them), defeated when they are argued down. It works with **no art
at all**: the placeholder is labelled with the file it wants. It becomes a
face the moment one is drawn to
`assets/characters/opponents/{ID}_{expression}.png`.

**Your own face** (`PlayerPortraitPresenter`) is a full-body cutout in the
art box's lower-left corner, matching the opponent's own cutout in the
lower right — the two read as a pair rather than the opponent's portrait
with a "you" chip in front of it (2026-09-24: that was the earlier layout).
Unlike the opponent, nothing is known ahead of time about what you will do,
so it reacts to what you just did instead: attacking when a card argues the
room away from the opponent, gaining when it wins support, guarding when it
only banks guard, damaged for a moment when an opponent's attack actually
lands, victory on a win. It works with no art either, the same bargain.

**Stage backgrounds.** Both the battle screen and the Office show the room's
own picture behind everything (`data/art.json`'s `background` folder —
`{STAGE_ID}.png`, or `OFFICE.png` for the Office), with a dark scrim over it
so text stays readable whatever the art turns out to look like. Blank shows
as an ID-coloured placeholder, same as any other missing art. **The Office
got its first two real drawings** (2026-09-28, Cameron): `OFFICE.png` (a
wood-panelled study) is now the base look everywhere the Office shows
today, and `OFFICE_UPGRADED.png` is the cosmetic background piece CP01
"Neon Ambition" (§8) already pointed at, a modern glass office — so
buying and equipping CP01's Office Background slot now genuinely changes
what's on screen, not just in the data. This was confirmed rather than
assumed (2026-09-28): a throwaway driver caught that the equip button
only updated `GameState.active_cosmetics`, not the live Office picture
behind the Cosmetics panel — `PlaceholderArt` only re-reads its art on
its own property setters, and nothing else re-set `_background`'s, so
the new look only ever showed up on the NEXT time Office loaded, not the
moment you equipped it. `OfficeScreen._on_equip_cosmetic()` now re-sets
`_background.art_id` (a self-assignment; that setter's own `_refresh()`
runs regardless) whenever the slot equipped is Background, so the change
is visible at once. `cosmetics_driver.gd`'s interaction test now checks
the live node's own resolved texture after a real click, not just the
data, so a regression here fails a real click test again. `PC01_RED_
neutral.png` is the
first real cosmetic outfit piece too (CP01's own `outfit_variant`, "RED")
— it arrived as a flat RGB drawing rather than a transparent cutout the
way PC01's four other expressions are, so its background was stripped
afterward to match (`rembg`'s U2Net matting model, alpha feathered at the
edge the same soft way the original art's own edges are) — confirmed
corner-transparent/centre-opaque like every other portrait. The other
three RED expressions (attacking/guarding/gaining) aren't drawn yet —
`character()` falls through to the plain (non-RED) file for those, the
same "missing art never blocks anything" bargain every other axis here
keeps, so CP01's outfit is only visible when PC01 is at rest.

**Stage outfits.** Entirely optional: a character can have a one-off look
for a single room —
`assets/characters/{kind}/{ID}_{STAGE_ID}_{expression}.png`, e.g.
`OP03_ST04_attacking.png` for how OP03 dresses only at a press conference.
Tried before the plain file of that same expression; nothing has to be drawn
for it and it is not counted by `tools/art_checklist.py`.

**The cue banner.** `CueBanner` throws the spoken line across the middle of
the screen, Ace Attorney style: the player's card cue from the left (blue
name tag) with what the card did underneath, the opponent's turn from the
right (red). Lines queue; tapping the band skips; it never blocks the hand.

**Starting numbers, per protagonist.** The New Game screen now lists each
protagonist's opening Constituency support/Reputation/Funds/Party
support/XP (`OfficeScreen._starting_stat_lines()`), read through
`BattleSetup.starting_meta_for()`/`starting_xp_for()`. All four
protagonists' own `starting_meta`/`starting_xp` (`data/player.json`) are
empty/0 today, so every row still shows sanban.json's one shared set of
numbers — the seam exists so a real per-character difference, Cameron's
call, has somewhere to go, the same bargain `ArtLoader` strikes with art
that has not been drawn.

**Touch.** Every scrolling list drags with a finger (`DragScroll`); a drag
that starts on a button scrolls and does not press it. A card pulled up out
of the hand and let go is played; a short pull drops back. Scrollbars are
36 px wide (`tools/build_theme.gd`).

**A note for whoever next touches `PlaceholderArt.gd`.** Its own art and
label are always pushed to the very back of its children (`_build()`'s
`move_child()` calls) rather than left wherever `add_child()` happens to put
them — a caller can add its OWN static child to a PlaceholderArt in the
scene file (present before `_ready()` runs), and without this the texture
just drawn would land on top of it and hide it completely. No node in the
current battle screen relies on this today (the player's own portrait chip
used to be nested inside the opponent's, 2026-09-24: the two are now
siblings, so neither paints over the other), but the guarantee stays in
place for the next caller that nests something inside a PlaceholderArt.
`tests/test_art_scheme.gd` guards it with a real scene-tree test.

**A note for whoever next runs the scene builders.** `tools/build_battle_
scene.gd` drifted again after its 2026-09-27 re-sync (2026-09-25: rerunning
it to add the label that became `%RoomNotice` lost the card zoom's
`ZoomColumn` its `unique_name_in_owner`, breaking the click-test interaction
suite, and a few sizes/anchors no longer match the checked-in scene either)
— fixed the one regression that actually broke something, but the file is
not fully re-synced again; the label itself, and its 2026-09-26 rename from
`%QuestionPrompt`, were both made straight to the real `.tscn` by hand
instead, specifically to avoid widening that gap further. Confirm with a
structural diff before trusting a rerun, the same discipline the 2026-09-27
fix used. `tools/build_visitor_scene.gd` (2026-09-25, new)
builds `scenes/office_hours/VisitorScreen.tscn` the same way. `tools/
build_office_scene.gd` is NOT kept in sync at all: it predates most of the
Office and would delete Office Management, Supplies, the deck screen and
more if run. See its own doc comment before touching it.

**The battle screen was split** to make room for what comes next: it keeps
the engine, the refresh, the status row and navigation, and four presenters
own the speaker row, the hand, the passing messages and the outcome panel.
The hand keeps its card views between refreshes rather than rebuilding them,
so a card that is played is a node that can still be animated.

### The 2026-09-27/28 player-perspective UI review

Every mechanic proven correct is not the same as every screen reading
clearly to someone seeing it for the first time — so this pass took one
screenshot per screen *shape* (not per stage, same reasoning as
`design/PLAYTEST_CHECKLIST.md`), at the real 1080×2340 resolution, and
cross-checked each one against the real code and data behind it rather
than trusting a first impression. `design/UI_PLAYER_REVIEW.md` is the
result — findings tagged Confusing/Inaccurate/Lacking, design-touching
items (ST06's bar label, a Supplies item's name, the flat 50 booster
standings) left as open questions for Cameron rather than decided here.
All three are now answered: ST06's `bar_unit` is "Viewer Tone" (edited
directly in the workbook's Stages tab and re-exported — only ST06's own
cell changed; ST04 and ST19 still correctly read "Press tone"); `"ね3"
Coffee` is confirmed as an intentional in-universe brand name, not a
data artifact; and the flat-50 booster standings now have a real
mechanism to vary. First pass put the override in a hand-maintained
`start_by_booster` table inside `data/booster_standing.json`; Cameron
asked whether the starting value already lived on a workbook sheet he
could just edit, so it moved there instead — the Boosters tab now has
its own **Starting Standing** column (`boosters.json`'s own
`starting_standing`), which `GameState.reset_booster_standing()` reads
per booster before falling back to `booster_standing.json`'s flat
`start` for any row the column leaves blank. The column itself is still
blank for all 16 organisations — how warm each real organisation is to a
brand-new legislator is Cameron's own political-characterization call,
left for him to write in the workbook rather than guessed at.

Everything else — three real layout bugs with no design call attached —
was fixed directly in a follow-up pass: the battle Details panel's text
bleed-through (its backdrop now uses the same fully-opaque style
`CardZoom` already did) and its party-colour labels moved from the very
end of the block to sit right next to the "You:"/"Opponent:" lines they
describe; the Party Steering Committee Check-In header no longer clips
its Japanese accent and visitor counter off the right edge
(`VisitorScreen.gd` now has its own `_fit_stage_name()`, the same
wrap-long-titles fix `BattleScreen` got in the 2026-09-27 playtest pass,
plus a scene fix — `VisitorScreen.tscn`'s header `Title` container needed
`size_flags_horizontal` set to expand, the same as `BattleScreen.tscn`'s,
or the wrapped label had nowhere to wrap into and collapsed to one letter
per line); and the Level Intro screen's CueBanner no longer covers the
speaking staffer's own portrait (the screen used to centre its portrait
vertically with two expanding spacers, landing it in the banner's fixed
band — the top spacer no longer expands, so the portrait sits above it).

One suspected engine bug was chased down and ruled out along the way: a
screenshot of a committee sequence's second bout appeared to show gaffes
carrying over from the bout just won, seemingly contradicting §7.5's own
claim that `_reset_for_new_bout()` clears them. It didn't — the
screenshot driver's own greedy-play helper only checked its stop
condition between turns, so it kept playing cards into the freshly reset
bout before the loop noticed the fight had moved on. Fixed the driver,
not the engine; the corrected shot shows a clean `gaffe=0/5` on turn 1 of
the new bout, exactly as documented. Worth recording because it's the
same "is this real or is this the harness" question this session's
stress-testing work keeps running into, and this time the answer was
"the harness."

Also fixed in passing, found the same way this session finds most
`<null>`-class bugs — by actually looking at a real screenshot: a battle
Details panel could show the literal text `<null>` for a side with no
party, the same bug class already guarded for opponent titles.
`PartyDisplay.party_name()` (`scripts/rules/PartyDisplay.gd`) is now the
one place every party-display call site reads the field from, rather
than stringifying it directly.
