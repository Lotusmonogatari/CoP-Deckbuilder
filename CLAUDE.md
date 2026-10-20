
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
| `law_effects.json` | law_id (LWxx) | What a voted bill does: Bill ID, Outcome (Passed/Failed), Timing (Once/Each level), Effects (a Grants-style list), four meta columns and XP (2026-10-12) — `StatuteBook.gd` |
| `player_cues.json` | cue_id (PLxx) | What the player says by suit + verb (attack/gain/block, blank = any), optionally per stage; checked before `card_cues.json` (2026-10-12) |
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
- **Influence swing (built 2026-09-28, Cameron)**: a strong enough player can additionally swing *other* parties' seats toward their own pick, not just their own single seat — hard but achievable, gated behind a real threshold rather than a routine button. `VoteInfluence.gate_passed()` checks the workbook's new **Vote Influence Triggers** tab (`data/vote_influence_triggers.json`): every row Cameron switches on must independently clear its own threshold (default 85, `balance.json`'s `vote_influence_default_threshold`) — a hard AND-gate, not a weighted score — and a row names either a meta value (Reputation, Party support, ...) or a booster_id, so which variables count is his to add or remove from the workbook alone. Once the gate passes, `FloorVoteEngine._apply_influence_swing()` reuses `majority_bucket()` for every party (not just the player's own): any party whose own assumed majority isn't the picked bucket gives up some seats, deterministically (no roll), capped by that party's own **Vote Resistance** (`parties.json`'s own `vote_resistance` — blank falls back to `balance.json`'s flat `vote_swing_resistance_default`, 70 first-draft, Cameron's to retune — the same per-item-override-over-flat-default shape Boosters' Starting Standing already uses). `choose()`'s own result gains `influence_gate_passed` and `outcome_flipped_by_influence` (true only when the swing changes the bill's own pass/fail, not on every swing — attributable specifically to the player's own influence). A flip shows an optional cutscene line (the workbook's new **Vote Influence Cues** tab, `data/vote_influence_cues.json`, one row per (Bill ID, Outcome Direction) pair, blank-tolerant the same way Level Intro Cues is) on `FloorVoteScreen`'s own `CueBanner` — this screen's first use of one — and can apply an optional bonus (Floor Vote Bills' new **Influence Bonus (Reputation)**/**Influence Bonus (Party support)** columns, blank = none) via the new `GameState.apply_floor_vote_influence_bonus()`. Sanity-checked against real, already-hand-verified data: forcing the gate open on LV31/BI01 with 0% resistance turns its known 45/48/8 loss into a 96/5/0 win, with `outcome_flipped_by_influence` correctly `true`. Both new tabs shipped with the gate off by default at first (`data/vote_influence_triggers.json`'s one seed row had `Enabled = No`) and every Vote Resistance/Influence Bonus cell blank, so no existing level's behavior changed until Cameron turned it on — confirmed by `floor_vote_test.tscn` (`tools/verify.sh`) still showing LV31's own unswung 45/48/8 totals. **Cameron has since filled this out for real** (2026-10-02 workbook upload): 16 enabled rows live today — three unscoped (Reputation ≥85, BO02 ≥75, BO03 ≥70, each applying everywhere) plus 13 scoped to specific parties via the per-party column below. The interaction test still shows LV31's unswung totals only because that fixture's own low starting meta never clears the thresholds — a real run that does clear them will see the real swing.
- **Per-party scope (2026-10-02, filled in with real data 2026-10-02)**: a Vote Influence Triggers row can also carry an **Applies To Parties** column (`data/vote_influence_triggers.json`'s own `applies_to_parties`, a semicolon-separated list of party_ids, exported as `"id_list"` the same way `opponents.json`'s own `stages` column is — e.g. `"PT04; PT05"`) so a trigger gates the swing into one or a few specific parties rather than the whole chamber — blank/empty still means every party, so a row written before this column existed behaves exactly as it always did. `VoteInfluence.gate_passed()` takes an optional `party_id` and skips any row whose own scope doesn't name it; `FloorVoteEngine._apply_influence_swing()` checks the gate **once per party** being considered (by that party's own `party_id`), rather than once for the whole vote, so the same vote can swing one party and not another. `influence_gate_passed` on the result is true if the gate passed for at least one party. New GUT coverage: `test_vote_influence.gd` (unscoped rows count everywhere; a scoped row counts only for its named party/parties; a global row and a scoped row combine per party) and `test_floor_vote_engine.gd` (a scoped trigger swings only the party it names, leaving an un-named party untouched even though its own assumed majority also isn't the picked bucket; a trigger scoped to a party absent from the bill swings no one). Cameron's own workbook upload (2026-10-02) was the column's first real content — initially exported as the wrong column type (`"list"`, comma-split) since his rows use semicolons like every other multi-ID column in this project; caught immediately by `export_data.py`'s own validation ("'Funds' names party 'PT04; PT05'... which is not a party_id") and fixed by switching to `"id_list"`.

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
| Party support < 50 | **Removed** (2026-10-11, Cameron). It used to grant M10 (Cold Shoulder), whose discount was never applied to anything; M10 and its "Party support: debuff" lever are gone. |
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

## 12. Working agreement

- **Explain like a colleague, not a manual.** Keep it short and plain English, and say what changed and why.
- **Ask before** you add a dependency, change a data schema, rename an ID, or resolve anything marked open or canon.
- **Never hardcode content** to get something working faster. If data is missing, use a placeholder and flag it.
- **Keep rules separate from visuals.** `/scripts/rules/` must run without any UI (tests prove this).
- **Test the rules**: every bug fix in the rules engine gets a test.
- **Small commits**, each with a message a non-programmer can read.
- If a task will take more than about 150 lines of new code, outline the plan first and wait for approval.
- When you are unsure, **say so** and offer 2–3 options with your recommendation.

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

**Starting numbers, per protagonist.** The New Game screen lists each
protagonist's opening Constituency support/Reputation/Funds/Party
support/XP (`OfficeScreen._starting_stat_lines()`), read through
`BattleSetup.starting_meta_for()`/`starting_xp_for()`. All four
protagonists now carry real, distinct `starting_meta`/`starting_xp`
(`data/player.json`, the 2026-10-04 databook pull — confirmed live, not
just wired: a fresh run with each protagonist starts at genuinely
different numbers, from PC01's strongest opening (Constituency support 35,
Reputation 25, Funds 100,000, Party support 40, XP 60 — "Easy") down to
PC04's weakest (5, 0, 10,000, 0, 0 — "Very Hard"), matching each
protagonist's own `blurb`).

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

## 14. Working notes that still apply

- **The change log.** Dated build notes (what each feature does, its levers and tests) are in `design/CHANGELOG.md`, in the order they were written; search it by system name (Special Levels, game clock, patron bills, organization chips, party opinion, bill stance, and so on). The list of its sections is at the end of this file.
- **Workbook edits.** Never save `design/CoP_Starter_Card_Stage_Data.xlsx` with openpyxl (it corrupts values and wipes formula caches). Edit raw XML with `tools/workbook/wbx.py` (`tools/workbook/README.md`); brand-new tabs get header notes from `tools/workbook/add_notes_new_tabs.py`, older tabs from `add_notes.py`. After every edit run `python3 tools/export_data.py` (it must say "No errors"); `--accept-wording` refreshes `tests/wording_snapshot.json` when Text-tab rows change.
- **Every sentence is a Text-tab row** and the exporter requires literal keys (`Text.say("a.b")`, never a built-up key).
- **New `class_name` scripts** need `.tools/godot --headless --path . --import` before GUT will see them.
- **Verification.** GUT: `.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`. Full gate: `tools/verify.sh` (about 10 to 15 minutes; run it in the background and wait for "All checks passed"). Merge the working branch to `main` only after it passes.
- **Screenshots** need a real display (`xvfb-run -a -s "-screen 0 1080x2340x24" ... --path .`), not `--headless`.
- **Memory leaks.** A lambda stored in a long-lived object must capture the thing it needs, not `self`; a Node must not `await` a timer.
- **Scene builders.** Only the builders listed in section 13 as safe may be rerun; the Office and battle scenes are edited by hand.
- **Content is draft.** Anything written by Claude in the workbook (cues, questions, bills, components) is a draft for Cameron to rewrite; never decide canon.

## 15. Change log index

Sections of `design/CHANGELOG.md`, oldest first:

- Implemented systems and remaining work
- §8's four crisis triggers — now wired (2026-09-25)
- The 2026-09-26 databook pull
- The 2026-09-27 databook pull: real Floor Vote content
- The 2026-09-27 playtest fixes
- The 2026-09-28 systematic evaluation pass
- The 2026-09-28 mobile playtest fixes
- A thorough code stress test (2026-09-28)
- "Your Record" — lifetime stats (2026-09-28)
- Balance tuning and a question-effectiveness multiplier (2026-09-28, Cameron)
- A weak answer's own booster penalty, and a per-stage cap (2026-09-28, Cameron)
- Your Record's Sanban values, a real Media Ambush surprise, and a real Outcome-panel bug (2026-09-28, Cameron)
- A text veil behind the Office's floating text (2026-09-28)
- Three Office wording/structure changes (2026-09-28, Cameron)
- Defunct shop items removed; three player-facing raw-ID leaks fixed; Sanban deltas shown; workbook columns get their permutations (2026-09-30, Cameron)
- A Level Buff's own Extra Guard bonus vanished after the first opponent in a committee (2026-09-30, Cameron)
- SH19's own Funds cap increase was silently ignored by stage rewards (2026-09-30, Cameron)
- A combat stage can now be lost instantly too — the player's own support argued down to nothing (2026-10-01, Cameron)
- The Level Intro screen gets a bill-lean choice (2026-10-01, Cameron)
- A text audit: 25 more sentences moved out of scripts and into the workbook (2026-10-01, Cameron)
- A pure-special-effect card read as useless in every room (2026-10-03, Cameron)
- The Funds cap was already at its hard ceiling by default (2026-10-04, Cameron)
- The 2026-09-27/28 player-perspective UI review
- A new workbook upload dropped the Question Themes tab, and renumbered the whole Shop tab (2026-10-04)
- The Question Themes tab is back, updated for the current question set (2026-10-04, Cameron)
- Town Hall only ever fought the first of its four constituents (2026-10-04, Cameron)
- Cleared the Shop-renumbering test fallout; a real UI bug found while doing it (2026-10-04, Cameron)
- Resume or Abandon a level in progress (2026-10-04, Cameron)
- A random 15-card opening deck (2026-10-05, Cameron)
- A How to Play guide (2026-10-06, Cameron)
- The Office's button row got two intermediary menus (2026-10-06, Cameron)
- Cosmetic icon cells fixed; the art checklist tool works again (2026-10-06, Cameron)
- Three stale tests now follow the workbook (2026-10-07, Cameron)
- The playtest bot got smarter, and its deck bug is fixed (2026-10-07, Cameron)
- The playtest bot now takes backing and uses items (2026-10-07, Cameron)
- A stage-trial mode for the bot, and what it found about the Cabinet committee (2026-10-07, Cameron)
- The Cabinet committee (ST18) retuned for a ~45-50% bot win rate (2026-10-07, Cameron)
- Two How to Play entries on live card numbers (2026-10-07, Cameron)
- A Staff Profile screen (2026-10-07, Cameron)
- Backing is now "Boosters", inside Reputation and Results (2026-10-07, Cameron)
- Organisation images in three places (2026-10-07, Cameron)
- A refilling press conference ended early with cards still in the discard (2026-10-10, Cameron)
- The briefing says what a loss costs and what resets between opponents (2026-10-10, Cameron)
- ST19 and ST21 now cycle through their opponents (2026-10-10, Cameron)
- How each party sees the player: one model for all six parties (2026-10-10, Cameron)
- Your Record shows the live Party support; a theme rebalance is proposed (2026-10-10, Cameron)
- Ainu rights, fisheries and commuter questions; a strong answer can now set organisations back (2026-10-10, Cameron)
- The theme rebalance is applied (2026-10-11, Cameron)
- How to Play: which suits please which organisations (2026-10-11, Cameron)
- New Game moved to the Administration menu (2026-10-11, Cameron)
- Performance pass and cleanup (2026-10-11, Cameron)
- Every organisation now has at least 15 questions (2026-10-12, Cameron)
- Divisive lean for Students United, Our Traditional Society and Party Faction (2026-10-12, Cameron)
- Three in-group / out-group Divisive questions (2026-10-12, Cameron)
- Phase 1 of the legislation plan: suit- and stage-based cues and questions (2026-10-12, Cameron)
- Draft content for Phase 1: committee questions and committee Player Cues (2026-10-12, Cameron)
- Phase 2 of the legislation plan: the statute book and Law Effects (2026-10-12, Cameron)
- Draft Law Effects for all 30 bills, and a note on every workbook column (2026-10-12, Cameron)
- A scored playtest of backing, influence and laws; a BOxx trigger now means standing (2026-10-12, Cameron)
- BI25's seat counts fixed; every organisation now has a stake in the statute book (2026-10-12, Cameron)
- A guide for an assistant expanding the workbook (2026-10-12, Cameron)
- Asked By Party, and the caucus seats only your own party (2026-10-12, Cameron)
- A review of the expansion guide against the workbook; the mechanical fixes applied (2026-10-12, Cameron)
- Review leftovers applied: typo, names, cues, grades, README, Assets (2026-10-12, Cameron)
- The expansion guide revised (2026-10-12, Cameron)
- A second review of the guide and workbook (2026-10-12, Cameron)
- A bill now needs a majority of the whole house (2026-10-12, Cameron)
- The Party Steering Committee (ST08) is now Own Party Only (2026-10-12, Cameron)
- The expansion guide revised after a draft review; feedback for the drafter (2026-10-13, Cameron)
- Expansion ground rule: add content, never mechanics; every room may carry generic and stage-specific content (2026-10-13, Cameron)
- Expansion focus: content gaps and topic-specific rooms (2026-10-13, Cameron)
- Expansion focus widened: transitions are a gap; topic rooms of any kind (2026-10-13, Cameron)
- Batch 1 draft: transitions and two topic levels; a transition bug fixed (2026-10-13, Cameron)
- The three-times rule, a depth audit, and a revised Batch 1 draft (2026-10-13, Cameron)
- Committee seating rule, a lean-toward-the-unmet people draw, Media Ambush (2026-10-13, Cameron)
- Special Committee and Cabinet seating decided; Media Ambush left alone (2026-10-13, Cameron)
- Party values saved as reference for bill drafting (2026-10-13, Cameron)
- Batch 1 adopted into the master workbook (2026-10-13, Cameron)
- Batch 2 draft: twenty new bills, BI31-BI50 (2026-10-13, Cameron)
- Batch 2 bills adopted (2026-10-13, Cameron)
- Booster and party balance across the 50 bills; Party-tier organisations follow the player's party (2026-10-13, Cameron)
- Batch 3 draft: rooms and levels for the twenty new bills (2026-10-13, Cameron)
- Batch 3 adopted; town halls cast from existing characters (2026-10-13, Cameron)
- The last five people shortfalls closed; branch merged to main (2026-10-13, Cameron)
- Salience-scaled party opinion, a visitor per bill, Level Intro and opponent cues (2026-10-14, Cameron)
- Unhired staff no longer speak in transitions; blank cue cells no longer say "<null>" (2026-10-14, Cameron)
- Wrapping everywhere, and safe-area margins (2026-10-14, Cameron)
- Parties popup, and dynamic screens steps 2-4 (2026-10-14, Cameron)
- A text-size setting (2026-10-14, Cameron)
- Transition audit: a thought when no one can speak, no transitions on Media Ambush (2026-10-14, Cameron)
- Gap-filling batch: questions, transitions, cues, ticker (2026-10-14, Cameron)
- Review fixes: stuck stage screens, safer saves, three engine bugs (2026-10-14, Cameron)
- Late-game stress test, and two memory leaks fixed (2026-10-14, Cameron)
- Thousands separators and a roomier Marketplace grid (2026-10-14, Cameron)
- Remaining icons identified; a brief and a merge checker for them (2026-10-14, Cameron)
- The twelve organisation icons are drawn and merged (2026-10-14, Cameron)
- Backing prices get thousands separators; "free" comes from the Text tab (2026-10-14, Cameron)
- Backings for the twelve new organisations; audience icons in the Boosters panel (2026-10-14, Cameron)
- Backings for BO17 and BO18 (2026-10-14, Cameron)
- Workbook editing tool and batch-builder scripts added to the repo (2026-10-14, Cameron)
- The five audience icons are drawn and merged (2026-10-14, Cameron)
- An art prompt template; two review leftovers closed (2026-10-14, Cameron)
- Button outlines (2026-10-15, Cameron)
- A text pass: 11 more sentences moved into the Text tab (2026-10-15, Cameron)
- A "Saved" flash and one manual backup slot (2026-10-15, Cameron)
- Floor Vote: influence readiness and a result preview (2026-10-15, Cameron)
- Your Record says why each number moved (2026-10-15, Cameron)
- Player thoughts open transitions more often (2026-10-15, Cameron)
- A Training Session Coupon (2026-10-15, Cameron)
- New runs start with a Training Session Coupon; two small fixes; proposals (2026-10-15, Cameron)
- Vote result tiles, Majority/Supermajority, law pop-ups, a fuller backup slot (2026-10-15, Cameron)
- Vote result alignment, Aye / Nay wording, Administration cleanup (2026-10-15, Cameron)
- Administration menu spacing and Save Game / Load Game labels (2026-10-15, Cameron)
- TV Debate rising threshold: workbook columns added, engine waiting for approval (2026-10-16, Cameron)
- The TV Debate's line now rises each turn (2026-10-16, Cameron)
- Terminology pass 1: money, the audience group, bar and Jiban wording (2026-10-16, Cameron)
- Terminology pass 2: American spelling, Threshold, Staff Rank, Party Bodies (2026-10-16, Cameron)
- Press conference: the last turn is played out; questions are cues (2026-10-16, Cameron)
- Booster standing is harder to hold; the Details panel says who a question is about (2026-10-16, Cameron)
- Visitor dilemmas and three snub items (2026-10-16, Cameron)
- Header notes for the newest columns (2026-10-16, Cameron)
- All visitor questions are dilemmas (2026-10-16, Cameron)
- The rhetoric and bill through-line (2026-10-18, Cameron)
- Party Activists and the Candidate Selection Committee (2026-10-18, Cameron)
- Bill-specific stages for every bill level; a default background for every stage (2026-10-18, Cameron)
- Content 2: opponents sound different in each style they use (2026-10-18, Cameron)
- Content 3: every bill-specific room asks its own questions (2026-10-18, Cameron)
- Content 4: five generic questions for every committee (2026-10-18, Cameron)
- Content 5: more ways to please the organizations that stayed out of reach (2026-10-18, Cameron)
- Content 6: more dilemmas for the original fifteen visitors (2026-10-18, Cameron)
- Content 10: the player's style lines for six more room families (2026-10-18, Cameron)
- Content 7: the player's thoughts (2026-10-18, Cameron)
- Content 1: the templated bill content is now written from each bill (2026-10-18, Cameron)
- The game clock (2026-10-18, Cameron) -- step 1 of 3
- Special Levels: the crisis triggers on the game clock (2026-10-18, Cameron) -- step 2 of 3
- Cooldowns and decay on the game clock (2026-10-18, Cameron) -- step 3a of 3
- Optional durations in clock units for items and backings (2026-10-18, Cameron) -- step 3b of 3
- The listening strip keeps one set of organizations for the whole turn (2026-10-18, Cameron)
- Card balance pass: gaffe-light Divisive, a free cantrip, a trimmed Data Driven (2026-10-19, Cameron)
- Patron Bills, step 1 of 7: schema and five seeded organizations (2026-10-19, Cameron)
- Patron Bills, step 2 of 7: the rules (2026-10-19, Cameron)
- Patron Bills: Option A coverage and the full component library (2026-10-19, Cameron)
- Patron Bills, step 3 of 7: the runtime level (2026-10-19, Cameron)
- Influence building, step A: `BillAssist`, the vote hook and the news ticker (2026-10-19, Cameron)
- Influence building, step B: the member visit (2026-10-19, Cameron)
- Influence building, step C: the lobbyist trade (2026-10-19, Cameron)
- Influence building, step D: the bot, balance and a small fix (2026-10-19, Cameron)
- Patron Bills, step 4 of 7: the Requests block and Request panel (2026-10-19, Cameron)
- Patron content (steps 5-6), headings, and a balance evaluation (2026-10-19, Cameron)
- The sponsored-bill vote result, and an ST261 trial (2026-10-19, Cameron)
- Review leftovers closed (2026-10-19, Cameron)
- Patron Visit: sponsored-bill levels open with the organization's representative (2026-10-19, Cameron)
- Draft a Bill: the player's own bill (patron step 7, 2026-10-19, Cameron)
- Organization chips, patron tab notes, component supply (2026-10-20, Cameron)
- Bill player cues: fifteen lines per style and lean, leans read differently (2026-10-20, Cameron)
