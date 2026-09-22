# Coliseum of Parliament — Build Brief for an AI Coding Agent

> **How to use (for Cameron):** Save this file as `CLAUDE.md` in the project root (Claude Code) or paste it into the project instructions (Summer Engine). Put the exported workbook JSON in `/data/`. Then ask the agent to start **Milestone 0** and work one milestone at a time.

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
| Text | English is primary everywhere. Japanese appears only as a small, muted accent **next to** English, never alone. Bundle **Noto Sans JP** (SIL OFL) as the theme font. |
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
/assets/
  characters/       {OPPONENT_ID}_{expression}.png  e.g. OP03_neutral.png
                    PROTAGONIST_{expression}.png
  cards/            {CARD_ID}.png                   e.g. C11.png
  backgrounds/      {STAGE_ID}.png                  e.g. ST02.png
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

Expressions for character art: `neutral`, `attacking`, `confident`, `flustered`, `defeated` (the protagonist also has `victory`).

## 6. Data contract

The design workbook (`CoP_Starter_Card_Stage_Data.xlsx`) has one tab per table. `/tools/export_data.py` converts each tab to `/data/{tab}.json`, an array of objects keyed by snake_case column names.

| File | Key | Purpose |
|---|---|---|
| `balance.json` | lever name | Global numbers: thresholds, XP tiers, bill difficulty factor, committee size bands |
| `suits.json` | element | 6 suits: Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous |
| `affinity.json` | element × stage_id | Suit power multipliers per stage (0.7–1.3) |
| `cards.json` | card_id | name_en, name_jp, suit, type, cost, self_plus, opp_minus, guard, draw, gaffe, target_segment, effect_text, upgrade_text, tier |
| `stages.json` | stage_id | mode, bar_unit, bar_max, win_threshold, turn_limit, energy_per_turn, hand_size, gaffe_limit, player_start, opp_start, segment mix %, win deltas, xp_reward, signature_rule |
| `segments.json` | segment_id | Press, Loyalists, Constituents, Donors, Bureaucrats |
| `modifiers.json` | mod_id | category, trigger_segment, trigger_min_pct, effect, magnitude, kaban_cost, available_to, source_booster |
| `boosters.json` | booster_id | 10 organizations; tier (Party / Constituency / National); linked modifiers |
| `opponents.json` | opp_id | name, party, committee, positioning, element_1, element_2, deck sizes. Turn behaviour is an `intent_pattern`; until the workbook carries that column it comes from `intent_patterns.json` |
| `committee.json` | module + seq | Committee members for a committee stage, with starting stance (For / Undecided / Against) |
| `yoron.json` | topic_id | Public-opinion topics, 0–100 value |
| `bills.json` | bill_id | topic_id, direction (+1/−1), difficulty_mod |
| `modules.json` | module + seq | Ordered stage list per module, with opponent_id, bill_id, difficulty, committee size |
| `sanban.json` | variable | Meta-variables with start, min, max, and thresholds. **Four of the names are lookup keys as well as display text** — see §6 |
| `strings.json` | key | **Every sentence the game says.** From the workbook's Text tab; nothing is typed into a script |
| `card_cues.json` | card_id | Five spoken lines per card, from the Flavor Text tab |
| `questions.json` | stage type | The questions each kind of room can ask, graded S/M/W per suit |
| `rules.json` | flag | **You create this file.** Switches for open design decisions (see §9) |

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
- `effect_text` is **display only**. Never parse it. Conditional effects ("doubled if Constituents ≥ 50%") are implemented through a small named-effect registry keyed by a new `special` column. Propose the column and its values to Cameron and let him add them to the workbook.
- Some workbook cells hold `"varies"` or `"—"`. Treat those as null and resolve them from the module or committee data.
- On load, `DataDB` validates cross-references (every card suit exists, every module stage and opponent exists, and so on) and prints a readable error report.

## 7. Battle rules

Items marked **[DEFAULT]** are your implementation choice. Put each one behind a `rules.json` switch or a `balance.json` value so Cameron can change it.

### 7.1 Setup
1. Load the stage, opponent, and bill from the current module row.
2. Starting support = stage `player_start` / `opp_start`, plus the bill's `difficulty_mod` added to the opponent, plus reputation (Kanban) effects in press stages (±5 at the Sanban thresholds).
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
| Press conference (ST04) | A single "press tone" bar starting at `player_start`. Reporter questions are the opponent intents. |
| TV debate (ST06) | A single bar. The player wins only if it is **at or above the threshold at the end of every turn** (survival). |
| Committee (ST01) | Per-member model; see §7.5. |

### 7.4 Win and loss
- **Loss:** the gaffe meter reaches `gaffe_limit` (immediate), or the turn limit ends without a win (§9 switch).
- **Win:** the bar reaches its threshold, or a committee majority locks For.

### 7.5 Committee stage
- Members come from `committee.json`. The committee chair is the module's `opponent_id` and is not a voting tile.
- Each member has a lean from 0 to 100. Undecided members start at 50. An "Against" stance means the member starts **locked Against** **[DEFAULT]**.
- The player targets one member with each card. `self_plus` and `opp_minus` (after affinity) both add lean to that member **[DEFAULT]**.
- At lean ≥ 66 the member locks For; at ≤ 33 the member locks Against **[DEFAULT]**.
- The chair's intent lowers one member's lean.
- Win when locked-For members reach a majority: floor(size ÷ 2) + 1. Lose if a majority is no longer reachable, or at the turn limit.

### 7.6 Opponent behavior (MVP)
Opponents use **scripted intent patterns**, not deck AI. Add an `intent_pattern` field per opponent (for example `[["attack",6],["gain",4],["block",5]]`) that cycles in order. Propose default patterns based on each opponent's element pair and ask Cameron to confirm them.

## 8. Meta systems

| System | Rule |
|---|---|
| Stage rewards | On a win, apply the stage's win deltas to constituency support (Jiban), reputation (Kanban), funds (Kaban), party support, and XP. Clamp every meta-variable to its min and max. |
| Jiban ≤ 15 | Insert a Town Hall stage (ST05) event into the module queue. |
| Jiban = 0 | Funding frozen: Kaban income becomes 0 until Jiban rises above 0. |
| Party support > 75 | Modifier M09 (Party Backing) is active. |
| Party support < 50 | Modifier M10 (Cold Shoulder) is active. |
| Party support < 25 | Insert the Steering Committee stage (ST08). Its entry cost disables one Kōenkai and one Bankisha modifier for the next module. |
| Bills and opinion | Bill difficulty = round((50 − alignment) × factor), where alignment is the Yoron value for the bill's topic, or 100 minus that value when the bill's direction is −1. |
| Office hours (ST07) | Non-combat. Five time slots. Visitor event cards come from a new `visitors.json` (propose the schema). Each card offers 2 choices, and each choice has outcome deltas to Jiban, Kaban, party support, or Yoron. Create 6 placeholder events. |
| XP checkpoint | Shown between modules. Spend XP to unlock cards at their tier cost from `balance.json`. Upgrade cost is 30 XP **[DEFAULT]**. |
| Save | Auto-save JSON to `user://` after every stage and at every checkpoint. |

## 9. Open design decisions: implement as switches, do not decide

Create `rules.json` with these flags, set to the listed defaults, and list them in your Milestone 1 report.

**Built and still set to the defaults**, as of 2026-09-21. Every one is read
at runtime, so changing the file changes the game with no code edit:

| Flag | Default | Currently | Options |
|---|---|---|---|
| `turn_limit_outcome` | `"loss"` | `"loss"` | `"loss"`, `"highest_support_wins"`, `"tie_retry"` |
| `opponent_can_win_by_threshold` | `false` | `false` | `true` / `false` |
| `opponent_engine` | `"intent_patterns"` | `"intent_patterns"` | `"intent_patterns"`, `"deck_ai"` (not built) |
| `press_answer_timer` | `false` | `false` | `true` / `false` (seconds value in balance) |
| `discard_hand_end_of_turn` | `true` | `true` | `true` / `false` |

Three more levers have been added to the same file since, for the same
reason — each was about to become a number written into a script:

| Flag | Currently | What it does |
|---|---|---|
| `pass_energy_penalty` | `1` | Energy lost on the turn after playing nothing |
| `guard_cap` | `5` | How high the guard bank stacks |
| `default_intent_pattern` | `attack 1–6 / gain 1–6 / block 0–2` | What an opponent does when the data gives them no pattern |

### Still unresolved — ask, don't guess

- **The protagonist's identity and party.** `data/player.json` holds "Hiro,
  Frontier Party" as a **placeholder** so the screens have a name to show.
  Frontier Party is canon (it is OP02 Yuriko Mayeda's), so nothing has been
  invented — but this is not a casting decision, and the workbook's note on
  MOD01 seq 3 says the Caucus rival should become a same-party opponent once
  the party is settled.
- **The Yoron topic list and starting values.** Every topic still starts at
  the neutral 50, so every bill's difficulty works out to **zero** and the
  whole system currently does nothing. The exporter says so on every run.
- **Party post titles.**
- **The `weak_answer_tone_cost` number.** A weak answer costs press tone, per
  Cameron's rule. The cost is a **placeholder of 1** in `stage_types.json`,
  chosen only so that a bad answer stings less than the 3 or 5 that declining
  costs. The right number is a playtest away.
- **The Theme → organisation mapping.** The workbook's new Question Themes tab
  maps all 69 themes to one of the ten organisations, with the reasoning for
  each in a Why column. It is a **draft Claude wrote for Cameron to correct**,
  not a decision made on his behalf. Only existing booster IDs are used.
- **Who asks each question.** The journalists are still Reporter A to Reporter
  E, so the questions are handed round in turn rather than by beat. When they
  are cast this becomes a column like the mapping above.
- **Whether the town hall asks questions.** Twenty are written for it; the
  stage type does not ask any today.

## 10. UI specification

Every screen is portrait, uncluttered, and English-first. Layout from top to bottom:

1. **Header:** stage name in English with a small muted Japanese accent (for example "Floor debate 本会議"), and on the right, "Turn 3 of 8".
2. **Opponent row:** portrait (initials placeholder), name, and the intent in plain words (for example "Attacking · −6").
3. **Win condition:** the support bar with a visible threshold line and a caption such as "51 seats to win". Committee stages show member tiles instead; press conferences show the current question.
4. **Status row:** Energy pips and "Gaffes 2 / 6". The gaffe warning turns red **only** when one more gaffe would end the stage.
5. **Hand:** 3–5 cards. Each card face shows cost, English name, and a one-line effect. At most one small Japanese accent per card. Tapping a card opens a zoom view with the full text, suit, art, and Japanese name.
6. **Footer:** a full-width "End turn" button.

Secondary information (deck and discard counts, active modifiers, opinion topics) goes in a **details panel** opened from an icon, not on the main screen.

Placeholder art: a flat colored rectangle labeled with the asset ID, so missing PNGs never block testing.

## 11. Milestones

Build **one milestone at a time**. After each one, stop and give Cameron: (a) what you built, in plain English; (b) how to test it (exact clicks); (c) any questions or decisions you need from him.

| # | Milestone | Done when | Status (2026-09-21) |
|---|---|---|---|
| M0 | Project setup, `export_data.py`, `DataDB` loading and validation, placeholder art loader, font theme | Every JSON file loads; the validation report is clean or lists readable errors; Japanese renders | **Done** |
| M1 | Headless rules engine plus GUT tests | Tests pass for affinity math, block, gaffe loss, intent cycling, shared-pool seats, and committee locking | **Done** — 469 tests |
| M2 | Battle UI: Floor debate (ST02) vs OP03 | A full battle is playable to a win or loss on desktop | **Done** |
| M3 | Committee (ST01) and Party Caucus (ST03) | Both playable using Module 01 data | **Done** |
| M4 | Office hours, module runner for MOD01, meta-variables, auto-save | MOD01 plays start to finish; quitting and reopening resumes the run | **Part done.** The level runner and meta-variables work; a level plays start to finish. **Auto-save is not built** — `SaveManager` is a stub, so quitting loses the run. Office hours (ST07) and `visitors.json` are not built |
| M5 | XP checkpoint shop | Unlocks and upgrades persist across the run | **Part done.** The shops, prices, refusals and deck screen work. The economy is switched off for playtesting: `GameState.open_collection` hands over every card, so XP has nothing to buy. Cards have no upgrades — Cameron settled that |
| M6 | Android export test, then iOS | Runs on a real phone in portrait with crisp Japanese text | Not started |
| Later | Press, Town Hall, TV, Steering Committee, booster UI, details panel polish | Staged separately | **Mostly done ahead of schedule.** Press conference, TV debate, town hall, policy study, media ambush and lobbyist meeting all play. The **Steering Committee (ST08) has no stage type** and needs content before code |

### Not on the original list, but built

The browser playtest (`web/`), the shoji card frames, booster standing, the
six playtest levels, scripted intent patterns with ranges, and the audio and
event seams described in §13.

**Every sentence moved out of the code** (2026-09-21). 200 lines now come from
the workbook's Text tab, in both builds. `tests/wording_snapshot.json` plus one
test catches a code change that quietly rewords something; a reword made on
purpose is recorded with `python3 tools/export_data.py --accept-wording`.

**Cameron's 270 card cues and 100 questions** (2026-09-21). A card says one of
its five lines when played. Every room that asks questions draws from a pool of
20 for its kind, seeded, without repeats. A question grades all six suits:
**S pleases the organisation, M does nothing, W costs press tone**
(`weak_answer_tone_cost`, a placeholder of 1 awaiting Cameron's number). The
town hall's 20 are written but not asked — that stage type puts no questions to
the player today, and giving it some is a design decision.

### §8 systems that are specified but NOT switched on

Four rules are written and tested and **nothing calls them**, so they do
nothing in the game today. Named here so a passing test suite is not mistaken
for a finished feature:

| Rule | §8 says | Waiting on |
|---|---|---|
| Town Hall trigger | Jiban ≤ 15 inserts ST05 | M4's queue machinery |
| Steering Committee trigger | Party support < 25 inserts ST08 | M4, **and a stage type for ST08** |
| Funding freeze | Jiban = 0 stops Kaban income | M4 |
| Party support modifiers | > 75 gives M09, < 50 gives M10 | M4 |

Six of the fifteen modifiers are inert for the same reason, and the shop says
"Not active yet" rather than selling something that does nothing.

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

Added 2026-09-21, in the debugging and scaling pass. Three places where the
wiring is finished and the content is not, so that adding the content is the
whole job rather than the start of one.

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
happening — attacking when they wind up, flustered when their support falls,
defeated when they are argued down. It works with **no art at all**, because
the placeholder is coloured from the ID and changes with the expression. It
becomes a face the moment one is drawn to
`assets/characters/{ID}_{expression}.png`.

**The battle screen was split** to make room for what comes next: it keeps
the engine, the refresh, the status row and navigation, and four presenters
own the speaker row, the hand, the passing messages and the outcome panel.
The hand keeps its card views between refreshes rather than rebuilding them,
so a card that is played is a node that can still be animated.
