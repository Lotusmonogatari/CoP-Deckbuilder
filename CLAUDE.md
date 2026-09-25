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
contains 30 levels, 21 canon stages, 16 boosters, 31 modifiers, and 54 cards.

| File | Key | Purpose |
|---|---|---|
| `balance.json` | lever name | Global numbers: thresholds, XP tiers, bill difficulty factor |
| `suits.json` | element | 6 suits: Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous |
| `affinity.json` | element × stage_id | Suit power multipliers per stage (0.7–1.3) |
| `cards.json` | card_id | name_en, name_jp, suit, type, cost, self_plus, opp_minus, guard, draw, gaffe, target_segment, effect_text, upgrade_text, tier |
| `stages.json` | stage_id | mode, bar_unit, bar_max, win_threshold, turn_limit, energy_per_turn, hand_size, gaffe_limit, player_start, opp_start, segment mix %, win deltas, xp_reward, signature_rule |
| `segments.json` | segment_id | Press, Loyalists, Constituents, Donors, Bureaucrats |
| `modifiers.json` | mod_id | category, trigger_segment, trigger_min_pct, effect, magnitude, kaban_cost, available_to, source_booster |
| `boosters.json` | booster_id | Organizations; tier (Party / Constituency / National); linked modifiers |
| `opponents.json` | opp_id | Opponent data and intent patterns |
| `yoron.json` | topic_id | Public-opinion topics, 0–100 value |
| `bills.json` | bill_id | topic_id, direction (+1/−1), difficulty_mod |
| `levels.json` | level_id | Workbook-derived level data and ordered stage references |
| `sanban.json` | variable | Meta-variables with start, min, max, and thresholds. **Four of the names are lookup keys as well as display text** — see §6 |
| `strings.json` | key | **Every sentence the game says.** From the workbook's Text tab; nothing is typed into a script |
| `card_cues.json` | card_id | Five spoken lines per card, from the Flavor Text tab |
| `questions.json` | stage type | The questions each kind of room can ask, graded S/M/W per suit |
| `player.json` | player_id | The four choosable protagonists (PC01–PC04, all placeholders) and the default |
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
| TV debate (ST06) | A single bar. The player wins only if it is **at or above the threshold at the end of every turn** (survival). Retuned 2026-09-25 (energy 3→5, hand 5→6, player_start 50→60) after a full playtest found the room mathematically unwinnable on turn 1 as originally tuned — the best possible turn-1 gain, any suit, full collection, was 12, short of the 15 needed from 50 to the 65 threshold. First-draft numbers, Cameron's to retune further. |
| Committee (ST01, ST09-ST18) | An ordinary Shared_pool bar. `sequence_mode: "reset"` draws several opponents from the stage's eligible pool (`opponent_count`) and fights them one at a time, a full reset between each — see §7.5. |

### 7.4 Win and loss
- **Loss:** the gaffe meter reaches `gaffe_limit` (immediate), or the turn limit ends without a win (§9 switch).
- **Win:** the bar reaches its threshold, or a committee majority locks For.
- **Whether a loss ends the level**, `stages.json`'s `loss_ends_level` (Stages tab, blank = Yes): normally yes — a lost stage sends the player back to the Office. Press conference (ST04) and Media Ambush (ST19) are marked "No" — Cameron, 2026-09-26: their threshold only decides which reward table applies (`win_delta_*`/`loss_delta_*`, already resolved from `state.outcome` before this is checked), not whether the level continues. `LevelRunner.loss_ends_level()` is the one place this is read; `OutcomePresenter.next_step_label()` reads the same flag so the button never says "Back to the Office" when the level is actually about to move on.

### 7.5 Committee stage
- A committee (ST01, ST09-ST18) is an **ordinary sequential battle**, not a separate mechanic. It draws `opponent_count` opponents from its eligible pool — every opponents.json row whose own "stages" list names that STxx, the same dynamic-by-default selection every other Combat stage uses (`BattleSetup._opponents_for()`) — and fights them **one at a time**.
- `sequence_mode: "reset"` (`BattleEngine._advance_to_next_opponent()`/`_reset_for_new_bout()`) is what makes each opponent a fresh argument: support, gaffes, guard, energy, the clock and the hand all start again the moment the last one is beaten. `bar_model` is left blank on these rows, so the bar itself is the ordinary Shared_pool default (`BarModel.for_stage()`).
- Win by getting through every opponent in the sequence — the same win condition any multi-opponent stage uses. Lose on the gaffe limit, or on the turn limit of whichever bout is in progress.
- Corrected 2026-09-25: an earlier pass built a separate per-member "lean/lock" persuasion model (locking a simultaneous majority of up to 13 voting members) that did not match this design. It's gone — `CommitteeModel.gd`, `BattleState.committee`, and every `is_committee_stage()` special-case were removed, and the 11 committee stages now use the `sequence_mode: "reset"` mechanism above, which was already built and tested (`data/playtest_level.json`'s `PT_S1` fixture) but never wired to the real canon rows. `opponent_count` on these rows is a first-draft `{min:3, max:3}` — Cameron's to tune per stage.

### 7.6 Opponent behavior (MVP)
Opponents use **scripted intent ranges**, not deck AI. Their attack, gain, and block ranges are exported with the opponent data. When a pattern is missing, the fallback comes from `data/rules.json`.

## 8. Meta systems

| System | Rule |
|---|---|
| Stage rewards | On a win, apply the stage's win deltas to constituency support (Jiban), reputation (Kanban), funds (Kaban), party support, and XP. Clamp every meta-variable to its min and max. |
| Jiban ≤ 15 | **Built** (2026-09-25). Inserts a Town Hall stage (ST05) into the level queue — `GameState._check_town_hall()`, `MetaRules.town_hall_triggered()`. |
| Party support = 0 | **Built** (2026-09-25), redesigned from Jiban = 0 (Cameron's call — the party cutting you off reads better than your constituents controlling party money). Funding frozen: Funds income becomes 0 until party support rises back above. `GameState._check_funding_freeze()`, `MetaRules.funding_frozen()`; named for the shop as modifier M32 "Funding Freeze" (`ModifierEffects.FUNDS_INCOME_FREEZE`), never purchasable. |
| Party support > 75 | **Built** (2026-09-25). Modifier M09 (Party Backing) is active for free, in addition to anything owned — `MetaRules.party_support_modifiers()`, `GameState._effectively_owned_modifiers()`. |
| Party support < 50 | **Built** (2026-09-25), same mechanism, M10 (Cold Shoulder) — though M10's own effect (UNLOCK_DISCOUNT) has no consumer anywhere yet, a pre-existing gap this wiring didn't open. |
| Party support < 25 | **Built** (2026-09-25), redesigned from "insert the Steering Committee stage (ST08)": ST08 is already a Combat stage hand-placed in 7 real levels, so repurposing it would have changed what they do. Inserts a **new** Non-combat stage instead, ST22 "Party Steering Committee Check-In" — Office Hours' own visitor-event machinery, reused wholesale, with one placeholder visitor (VI04) and question (VQ04). The original entry-cost idea (disabling a Kōenkai/Bankisha modifier) is not built — "Bankisha" doesn't map to any of the 16 current organisations. |
| Bills and opinion | Bill difficulty = round((50 − alignment) × factor), where alignment is the Yoron value for the bill's topic, or 100 minus that value when the bill's direction is −1. |
| Office hours (ST07) | Non-combat. Five time slots. Visitor event cards come from a new `visitors.json` (propose the schema). Each card offers 2 choices, and each choice has outcome deltas to Jiban, Kaban, party support, or Yoron. Create 6 placeholder events. |
| XP checkpoint | Shown between modules. Spend XP to unlock cards at their tier cost from `balance.json`. Upgrade cost is 30 XP **[DEFAULT]**. |
| Save | **Built.** One slot, `user://savegame.json`, written after every stage, whenever the Office opens or something is bought or changed there, and when the app is backgrounded outside a stage. A stage in progress is never saved: reopening mid-stage restarts that stage. No save on launch opens the New Game screen. |

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
| `default_intent_pattern` | attack 1–6 / gain 1–6 / block 0–2 |

### Still unresolved — ask, don't guess

- **The protagonists' identities and parties.** `data/player.json` now holds
  **four** choosable protagonists. PC01 keeps the earlier placeholder "Hiro,
  Frontier Party" (Frontier Party is canon — OP02 Yuriko Mayeda's); PC02–PC04
  are neutral stand-ins ("Protagonist B/C/D", no party). None is a casting
  decision, and the workbook's note on MOD01 seq 3 says the Caucus rival
  should become a same-party opponent once the party is settled.
- **The Yoron topic list and starting values.** The eight values in
  `data/yoron.json` are currently 50 and marked as placeholders; they are not
  final balance decisions.
- **Party post titles.**
- **The `weak_answer_tone_cost` number.** The current value is 1 in
  `stage_types.json`; the file labels it as a placeholder pending playtesting.
- **The Theme → organisation mapping.** The workbook's Question Themes tab
  maps its themes to organizations, with the reasoning for
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
| M4 | Office hours, module runner for MOD01, meta-variables, auto-save | MOD01 plays start to finish; quitting and reopening resumes the run | **Done.** The level runner, meta-variables and saving/resuming exist (resuming mid-level returns to the start of the current stage). Office Hours visitor events are playable end to end (`design/proposals/office_hours.md`): a multiple-choice visitor room, its own `VisitorScreen`, and `StageRouting.gd` sending a level to the right screen stage by stage as it mixes Combat and Non-combat rooms. |
| M5 | XP checkpoint shop | Unlocks and upgrades persist across the run | **Part done.** The shops, prices, refusals, and deck screen exist. `rules.json`'s `open_card_collection` is now `false` and `level_gating_enabled` is now `true` (2026-09-25, both fully built, just switched on) — XP genuinely gates card unlocks (`cards.json`'s own `xp_to_unlock`, filled in for all 54 cards) and level unlocks/cooldowns for the first time. A second, Yen-based route now exists alongside it (2026-09-26, Cameron): Supplies' "Purchase Random Tier N Card" (SH27/28/29) grants a random unowned card of that tier on purchase — `GameState.buy_random_card()`, `shop.json`'s own `card_tier` column — rather than sitting in the inventory unusable, which is what these three did before (`Use In Office`/`Use In Stage` were both blank, so nothing could ever use one). SH13-19 (level unlocks, staff tiers, funds cap via the shop) remain deliberately unwired — `design/proposals/inventory.md` recommended leaving them out since they overlap the existing XP-based level/staff screens, and Cameron's own bug report was about SH27-29 specifically. |
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
as an ID-coloured placeholder, same as any other missing art.

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
