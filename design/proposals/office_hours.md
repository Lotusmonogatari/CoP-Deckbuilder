# Proposal: Office Hours (ST07) — a multiple-choice visitor room

Supersedes CLAUDE.md §8's original Office Hours sketch (5 fixed time slots,
2-choice visitor cards, raw deltas to Jiban/Kaban/Party support/Yoron,
`data/visitors.json`). This is a different, more developed mechanic per
Cameron's 2026-09-25 brief: multiple-choice dialogue, a named visitor pool
drawn dynamically per stage (the same way opponents already are), and
rewards pulled from the game's existing booster/modifier/shop-item systems
rather than raw meta-variable deltas.

Not started. This document is the plan; nothing below is built yet.

## Two things confirmed with Cameron before writing this

| Question | Answer | What it decided |
|---|---|---|
| One question per visitor, or several? | **Several per visitor** | Needs a second, linked tab — one visitor, many possible questions — the same shape Opponents/Press Questions already use, not a single wide row. |
| What does a wrong answer cost? | **Something, not just "no reward"** | Needs a real penalty column and a decision on what it touches (proposed below: a meta-variable dip, the same four the rest of the game already moves). |

## Executive summary

| Layer | What's new | Reuses |
|---|---|---|
| Data | 2 workbook tabs: **Visitors** (identity + eligibility + reward + penalty), **Visitor Questions** (the dialogue content, many rows per visitor) | The Opponents/stage-eligibility pattern; the Press-Questions-style pool pattern; the `range` and `stage_list` coerce kinds already in the exporter |
| Selection | Draw N visitors for a stage from its eligible pool | **The existing `Opponent Count` column and `_opponents_for()` logic on Stages — no new stage column.** A stage doesn't know or care whether its "count" resolves to opponents or visitors; that's decided by whether the stage is Combat or Non-combat. |
| Rules engine | New `scripts/rules/OfficeHoursEngine.gd` — pure, headless, no cards/energy/gaffe | `LevelRunner`'s shape (current/advance/is_finished/outcome); `BattleEngine._draw_questions()`'s draw-and-shuffle pattern |
| Reward/penalty application | Dispatch a visitor's reward (Booster standing / Modifier grant / Shop item) and a miss's penalty (a meta-variable dip) | `GameState.owned_modifiers`, `GameState._please_organisations()`-style booster bump, `Ledger`'s existing refusal/cost helpers as a model |
| UI | New `scenes/office_hours/VisitorScreen.tscn` — background + portrait (kept, as asked), a dialogue text block, 4 choice buttons | `ArtLoader`'s placeholder-portrait fallback; `OpponentPresenter`'s expression-from-state pattern, twinned as `VisitorPresenter` |
| Validation | `DataDB` cross-checks: every Visitor Question's `visitor_id` exists; every Visitor's reward/penalty target exists; every stage-eligible Visitor has at least one question | Same "readable error report at load" DataDB already does for cards/stages/opponents |

## 1. Data model

### 1.1 `Visitors` tab → `data/visitors.json` (replaces the unused stub already in `export_data.py`)

One row = one character's identity, eligibility, and what answering them
correctly or incorrectly is worth. No question text here — that's the
second tab, because one visitor can ask from several.

| Column | JSON key | Kind | Notes |
|---|---|---|---|
| Visitor ID | `visitor_id` | id | `VIxx`, parallel to `OPxx` |
| Name (EN) | `name_en` | str | |
| Name (JP) | `name_jp` | str | |
| Romaji | `romaji` | str | |
| Role / description | `title` | str | flavor only, e.g. "Constituent", "Lobbyist" — shown under their name |
| Stage | `stages` | stage_list | which STxx this visitor can be drawn for — **same column, same semicolon-list convention as Opponents' own "Stage" column** |
| Reward Type | `reward_type` | str | `Booster`, `Modifier`, or `ShopItem` (blank = no reward — a visitor can exist purely for flavor) |
| Reward Target | `reward_target` | str | `BOxx` / `MODxx` / `SHxx`, matching Reward Type |
| Reward Value | `reward_value` | num | magnitude for a Booster standing bump; ignored for Modifier (a grant is binary — you own it or you don't) and for ShopItem (see §4, still open) |
| Miss Penalty Meta | `miss_penalty_meta` | str | one of `Jiban` / `Reputation` / `Funds` / `PartySupport` (the same four keys `ModifierEffects.RESOURCE_TARGET_TO_META` already uses), blank = no penalty |
| Miss Penalty Value | `miss_penalty_value` | int | magnitude subtracted on a wrong answer |

### 1.2 `Visitor Questions` tab → `data/visitor_questions.json`

One row = one possible exchange. Many rows can share a `visitor_id` — this
is the "several questions per visitor" shape, resolved by drawing one at
setup time the same way `BattleEngine._draw_questions()` already draws from
a stage's question pool.

| Column | JSON key | Kind | Notes |
|---|---|---|---|
| Question ID | `question_id` | id | `VQxx` |
| Visitor ID | `visitor_id` | str (FK) | which Visitors row this belongs to |
| Question text | `question_text` | str | the dialogue prompt |
| Choice A–D | `choice_a` … `choice_d` | str | the four options, always exactly four |
| Correct Choice | `correct_choice` | str | `A`/`B`/`C`/`D` |
| Response – Right | `response_right` | str | the visitor's own line on a correct pick |
| Response – Wrong | `response_wrong` | str | the visitor's own line on a wrong pick |
| Reaction – Right | `reaction_right` | str | a shorter reaction/expression cue for a correct pick |
| Reaction – Wrong | `reaction_wrong` | str | same, for a wrong pick |

*(Splitting "reaction text" into Right/Wrong, to match how "response text"
was already asked for as a pair — flagged in §4 as my own reading, easy to
collapse to one shared column if that's not what was meant.)*

### 1.3 Selection: reusing `Opponent Count`, not a new column

Cameron's brief: *"stage will indicate quantity of randomized visitors from
eligible pool and should be a range value."* That's exactly what the
`Opponent Count` column (already live on every Stage, part of the
2026-09-25 living-rules set) already is — a range-string, defaulting to 1,
already read through `BattleSetup._opponent_count()`.

Rather than add a second, parallel "Visitor Count" column that would have to
be kept in sync with it, `expand_level()` picks which pool to draw from by
the stage's own `mode`:

```
mode == "Non-combat"  → draw VISITORS, count from Opponent Count
mode == "Combat"      → draw OPPONENTS, count from Opponent Count (unchanged)
```

New functions mirroring the existing opponent ones exactly:

- `eligible_visitors(stage_id)` — twin of `eligible_opponents()`
- `_visitors_for(level_id, stage_id, slot, count)` — twin of `_opponents_for()`
- A new **`data/level_visitor_overrides.json`**, same shape as
  `level_opponent_overrides.json`, to pin a specific visitor to a specific
  level+slot (kept as a separate file rather than widening the existing one,
  so a mistake in the new mechanic can't touch the well-tested opponent one).

`expand_level()`'s stage dict grows one more resolved field for a
Non-combat stage: `stage["visitors"] = [...]`, each entry carrying its own
drawn question already attached (`visitor["question"] = {...}`), the same
way a press-conference stage's questions are resolved once at setup rather
than re-rolled mid-battle.

## 2. Rules engine — `scripts/rules/OfficeHoursEngine.gd`

Pure `RefCounted`, no autoload or file access — same discipline as every
other file in `scripts/rules/`, and the same reason: it has to run
headless, in GUT, with no scene tree.

```
OfficeHoursEngine
  setup(config: Dictionary) -> bool
      config = { "visitors": [ {visitor fields..., "question": {...}}, ... ] }
  current_visitor() -> Dictionary
  current_question() -> Dictionary
  answer(choice: String) -> Dictionary
      returns { "correct": bool, "response_text": String, "reaction": String,
                "reward": {...} or {}, "penalty": {...} or {} }
      — a result dictionary the screen narrates and GameState applies,
      exactly the shape BattleEngine already returns from end_turn() for
      the opponent's move. The engine never touches GameState directly.
  advance() -> void       # moves to the next visitor
  is_finished() -> bool
  outcome() -> Dictionary # { "visited": n, "correct": n, "rewards": [...], "penalties": [...] }
```

No energy, no hand, no cards, no gaffe meter, no turn limit distinct from
"one exchange per visitor, then the next." This is deliberately a simpler
machine than `BattleEngine` — Office Hours was never a card battle.

### Reward / penalty dispatch

On `answer()`, the engine reads the *current visitor's* Reward/Penalty
columns (not the question's — reward is per-visitor, per Cameron's brief)
and packages, but does not apply, one of:

| Reward Type | Package | Applied by (GameState) |
|---|---|---|
| `Booster` | `{"kind": "booster", "id": "BOxx", "value": n}` | the same standing-bump path `_please_organisations()` already uses |
| `Modifier` | `{"kind": "modifier", "id": "MODxx"}` | `owned_modifiers.append(id)` if not already owned — a free version of what `buy_modifier()` already does, minus the cost/refusal checks |
| `ShopItem` | `{"kind": "shop_item", "id": "SHxx"}` | **open — see §4** |
| *(blank)* | `{}` | nothing |

A miss packages `{"meta": "Jiban", "value": -3}` (say), applied through
whatever GameState already uses to move a Sanban variable on a stage
result — the same clamped, floor/ceiling-respecting path `finish_stage()`
uses for win/loss deltas today, not a new one.

## 3. UI — a dedicated scene, not a BattleScreen branch

`BattleScreen.gd` already carries real complexity (energy pips, hand,
guard, intent, four presenters). Branching it for a mode with none of
those would make both harder to read. Instead: **`scenes/office_hours/
VisitorScreen.tscn`**, a new scene that keeps the same *visual* shell
Cameron asked to keep —

- stage background (same `ArtLoader` background-by-ID convention as a
  battle stage)
- a portrait row (a new `VisitorPresenter.gd`, a near-twin of
  `OpponentPresenter.gd` — same placeholder-when-no-art fallback, same
  ID-colored placeholder, same expression-from-state idea, just driven by
  `reaction_right`/`reaction_wrong` instead of support-bar math)

— and replaces the card hand/energy/guard row entirely with:

- a dialogue text block (the question text)
- four choice buttons (the four `choice_a`..`choice_d` texts)
- a response line that appears after the pick, before moving on

`OfficeScreen.gd` routes into it the same way it already routes into
`BattleScreen.tscn` today (`_on_start()`), just checking the current
stage's `mode` first.

## 4. Open points — flagging rather than deciding

| # | Point | My default (used above) | Needs |
|---|---|---|---|
| 1 | **Shop item reward** — `data/shop.json`'s SHxx rows today are one-time-use *actions* ("Commission Policy Research"), reset per Office visit, with no ownership/inventory concept at all. Cameron's example ("coffee, tea") sounds like small consumable flavor items, which don't exist in the Shop tab today. | Left unresolved — flagged, not guessed | Cameron: are "coffee, tea" new SHxx-style rows to add, or a genuinely new small inventory this feature should introduce? |
| 2 | Miss penalty target | One of the 4 Sanban meta-variables (Jiban/Reputation/Funds/Party support), magnitude from a new column | Confirm this is the right place to feel a wrong answer, vs. e.g. a Yoron topic move (CLAUDE.md's old sketch used Yoron for choice deltas) |
| 3 | Reaction text split | Split into Right/Wrong (matching Response text's own split) | Confirm, vs. one shared "Reaction" column regardless of outcome |
| 4 | Can a player skip/decline a visitor rather than always picking one of 4? | No — must pick one of the four, no decline | Confirm this matches intent; a press conference's "decline" mechanic could be mirrored if not |
| 5 | Repeat visits — can the same visitor/question reappear in a later level, or once answered are they retired for the run? | Unset — no dedup, a visitor can reappear (same as opponents can) | Confirm |

## 5. Build order

1. Exporter + workbook: both new tabs, `data/visitors.json` /
   `data/visitor_questions.json`, `DataDB` loading + cross-reference
   validation. ~6 placeholder visitors / ~10 placeholder questions to build
   and test against, same as CLAUDE.md's original "create 6 placeholder
   events" ask.
2. `BattleSetup` selection: `eligible_visitors()`, `_visitors_for()`,
   `level_visitor_overrides.json`, `expand_level()` wiring.
3. `OfficeHoursEngine.gd` + full headless GUT coverage (rubric below) —
   built and tested before any UI exists, same discipline as `BattleEngine`.
4. Reward/penalty application in `GameState`.
5. `VisitorScreen.tscn` + `VisitorPresenter.gd` + `OfficeScreen.gd` routing.
6. Real click-driven interaction test (`tests/interaction/`), extending
   `loop_driver.gd`'s pattern to walk a Non-combat stage.
