# Proposal: Office Hours (ST07) — a multiple-choice visitor room

Supersedes CLAUDE.md §8's original Office Hours sketch (5 fixed time slots,
2-choice visitor cards, raw deltas to Jiban/Kaban/Party support/Yoron,
`data/visitors.json`). This is a different, more developed mechanic per
Cameron's 2026-09-25 brief: multiple-choice dialogue, a named visitor pool
drawn dynamically per stage (the same way opponents already are), and
rewards pulled from the game's existing booster/modifier/shop-item systems
rather than raw meta-variable deltas.

**Status (2026-09-25, updated): everything except the UI screen is built.**
Data, DataDB validation, visitor selection, the rules engine, and the
GameState reward/penalty application all exist and are tested (566 GUT
tests passing). What's NOT built: `VisitorScreen.tscn` — nothing routes a
Non-combat stage anywhere yet, so reaching one today shows BattleScreen's
existing "cannot start" refusal (`BattleEngine` correctly says "there is
nobody to argue with" rather than crashing — see §6 and
`tests/test_real_battle.gd`'s `test_a_non_combat_stage_fails_battleengine_
setup_safely_for_now`). §6 below is the authoritative "what's actually
built" list; treat the rest of this document as the plan that produced it.

## Four things confirmed with Cameron before writing this

| Question | Answer | What it decided |
|---|---|---|
| One question per visitor, or several? | **Several per visitor** | Needs a second, linked tab — one visitor, many possible questions — the same shape Opponents/Press Questions already use, not a single wide row. **Built.** |
| What does a wrong answer cost? | **Something, not just "no reward"** | Needs a real penalty column. **Built** — see the next row. |
| What can Reward/Penalty actually touch, and in what shape? | **A Booster standing / Modifier grant / Shop item, in one cell, mixed, e.g. "BO05 +1; BO03 -2"** (2026-09-25) | Replaces the 3-column Reward Type/Target/Value + 2-column Miss Penalty split originally sketched here with **one column each** (Reward, Penalty), both the same `target_delta_list` format — the kind of each target (booster/modifier/shop item) is read from its own ID prefix at runtime (`RewardTargets.gd`), not a separate column. **Built.** |
| When does Reward apply vs. Penalty? | **Reward on a correct answer, Penalty on a wrong one — never both, per question** (2026-09-25) | Confirms the shape already designed in §2: `OfficeHoursEngine.answer()` returns the visitor's Reward list on a hit or Penalty list on a miss, the other always empty. **Built.** |

## Executive summary

| Layer | Status | What it is |
|---|---|---|
| Data | **Built** | 2 real workbook tabs, `data/visitors.json` / `data/visitor_questions.json`, one template visitor+question (`VI01`/`VQ01`) demonstrating a static reward, a range reward, and a penalty |
| Selection | **Built** | `BattleSetup.eligible_visitors()` / `_visitors_for()` / `data/level_visitor_overrides.json`, reusing the existing `Opponent Count` column — no new stage column |
| Rules engine | **Built** | `scripts/rules/OfficeHoursEngine.gd` — pure, headless, no cards/energy/gaffe |
| Reward/penalty application | **Built** | `GameState.apply_visitor_reward_entries()` resolves each target (`RewardTargets.gd` + `DataDB.resolve_reward_target()`), rolls a range delta once at apply time, and applies a booster standing change or a modifier grant. Shop item: pulls the real record, applies nothing yet — still open, see §4 |
| Validation | **Built** | `DataDB` cross-checks every Visitor's stage eligibility and Reward/Penalty targets, every Visitor Question's link back to a real Visitor and a real, answerable A–D, and a `level_visitor_overrides.json` pin the same way opponent pins are checked |
| UI | **Not built** | `scenes/office_hours/VisitorScreen.tscn` — background + portrait (kept, as asked), a dialogue text block, 4 choice buttons; `OfficeScreen._on_start()` still always opens `BattleScreen.tscn` regardless of stage mode |

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
| Role | `title` | str | flavor only, e.g. "Constituent", "Lobbyist" — shown under their name |
| Stage | `stages` | stage_list | which STxx this visitor can be drawn for — **same column, same semicolon-list convention as Opponents' own "Stage" column** |
| Reward | `reward` | **target_delta_list** *(built)* | `"BO05 +1; M12; SH04"` — a booster standing bump, a modifier grant, a shop item grant, any mix, in one cell. Blank = no reward. |
| Penalty | `penalty` | **target_delta_list** *(built)* | Same format, applied on a wrong answer — typically `"BO05 -2"` against a booster, not a Sanban meta-variable. Blank = no penalty. |

**`target_delta_list`** (new exporter coerce kind, built 2026-09-25; range
support added the same day after a follow-up question caught the gap):
`"<ID>; <ID> +N; <ID> min-max; ..."` → a mix of
`{"target": "BO05", "delta": 1}`, `{"target": "M12", "delta": null}`, and
`{"target": "BO01", "delta": {"min": 1, "max": 6}}`. A target's delta is one
of three shapes:

- absent — a modifier or shop item is granted outright, not incremented,
  so a bare ID (`"M12"`) is valid
- a single fixed signed number (`"+1"`, `"-2"`)
- a range to roll (`"+1-6"` or `"1-6"` — the leading `+` is decorative,
  same `min-max` shape the `range` coerce kind already uses elsewhere).
  **Can be negative on either or both ends** — `"-3-3"` (min −3, max 3) and
  `"-6--1"` (min −6, max −1) both parse correctly; there is no separate
  "negative range" syntax, just negative numbers in the same `min-max`
  shape.

Rolling a range into a real number is **not** this exporter's job — it only
ever produces the `{"min", "max"}` shape. `GameState.apply_visitor_reward_
entries()` rolls it (built, §2/§6) the same way `_roll_range()` already
rolls a level's bonus-win ranges, once, at the moment the reward or penalty
is actually applied.

Which *kind* of thing a target is comes from its own prefix, read by
`scripts/rules/RewardTargets.gd` (`BOxx` → booster, `Mxx` → modifier, `SHxx`
→ shop item; a real modifier's ID is bare `M##`, not `MOD##` — checked
against the live ID patterns in `export_data.py`, not assumed). Pulling the
real record a target names is `DataDB.resolve_reward_target(entry)`, which
now works for all three kinds and all three delta shapes, `SHxx` included —
see §6.

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

## 2. Rules engine — `scripts/rules/OfficeHoursEngine.gd` (built)

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
                "reward": [...], "penalty": [...] }
      — the raw, UNRESOLVED target_delta_list from the visitor's own Reward
      or Penalty column (whichever applies; the other is always []). This
      class has no DataDB to resolve a target's real kind in — same
      separation BattleEngine keeps for the opponent's move, which it also
      hands back raw for the screen/GameState to interpret.
  advance() -> void       # moves to the next visitor
  is_finished() -> bool
  visitor_count() / visitor_index() -> int
  outcome() -> Dictionary # { "visited": n, "correct": n, "rewards": [...], "penalties": [...] }
      rewards/penalties here are also the raw lists, collected across every
      visitor actually answered.
```

No energy, no hand, no cards, no gaffe meter, no turn limit distinct from
"one exchange per visitor, then the next." This is deliberately a simpler
machine than `BattleEngine` — Office Hours was never a card battle. There is
no way to lose it — see §4 open point D2's rubric entry.

### Reward / penalty dispatch — `GameState.apply_visitor_reward_entries()` (built)

Resolving and applying is deliberately NOT the engine's job (it can't touch
DataDB), and NOT resolved ahead of time at setup either (a range delta rolls
once, at the moment it's actually applied, per the confirmed answer to open
point 5 below) — so this one GameState function is where a raw entry
(`{"target": "BO05", "delta": 1}`) becomes a real effect:

1. `DataDB.resolve_reward_target(entry)` — the target's real kind
   (`RewardTargets.gd`, by ID prefix) and its real record.
2. A range delta (`{"min", "max"}`) is rolled here, once — never shown to
   the player as a range.

| Kind (by ID prefix) | What actually happens |
|---|---|
| `booster` (`BOxx`) | standing moves by the resolved delta, clamped to `booster_standing`'s floor/ceiling — the general form of `_please_organisations()`'s fixed step |
| `modifier` (`Mxx`) | `owned_modifiers.append(id)` if not already owned — a free version of what `buy_modifier()` already does, minus the cost/refusal checks; the delta is ignored, a grant is binary |
| `shop_item` (`SHxx`) | the real row resolves; nothing applies it — **still open, see §4** |
| unresolvable (bad prefix, or a well-formed ID that doesn't exist) | logged, does not stop the rest of the list from applying |
| *(empty list)* | nothing happens |

A `Penalty` entry runs through the identical function — most often a
negative `delta` against a `booster`, per Cameron's own example
(`"BO05 +1; BO05 -2"` shows both signs of the same target kind).

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

`OfficeScreen.gd` still always opens `BattleScreen.tscn` regardless of
stage `mode` — this section (and `VisitorScreen.tscn`/`VisitorPresenter.gd`
themselves) is the one part of the plan **not** built yet.

## 4. Open points — flagging rather than deciding

| # | Point | My default (used above) | Needs |
|---|---|---|---|
| 1 | **What a `shop_item` reward/penalty actually DOES at runtime.** The prefix resolves to a real row (`DataDB.resolve_reward_target()`, built) and `GameState.apply_visitor_reward_entries()` reaches the case and applies nothing (built, deliberately) — `data/shop.json`'s SHxx rows are one-time-use *actions* ("Commission Policy Research"), reset per Office visit, with no ownership/inventory concept at all. Cameron's example ("coffee, tea") sounds like small consumable flavor items, which don't exist in the Shop tab today. | Left unresolved — the *pull* and the *dispatch point* are built, the *effect* is not | Cameron: are "coffee, tea" new SHxx-style rows to add (and if so, does granting one via a visitor make it free-to-use once, or add it to a running inventory)? Or a different, smaller mechanic entirely? |
| 2 | Reaction text split | Split into Right/Wrong (matching Response text's own split) | Confirm, vs. one shared "Reaction" column regardless of outcome — **built** as split; cheap to collapse later if wrong |
| 3 | Can a player skip/decline a visitor rather than always picking one of 4? | No — must pick one of the four, no decline | Confirm this matches intent; a press conference's "decline" mechanic could be mirrored if not. Not reachable yet — no UI to skip from |
| 4 | Repeat visits — can the same visitor/question reappear in a later level, or once answered are they retired for the run? | Unset — no dedup, a visitor can reappear (same as opponents can) | Confirm |
| 5 | A range delta rolls a real number when? | **Resolved 2026-09-25**: once, the moment the reward/penalty is actually applied (`GameState.apply_visitor_reward_entries()`), never shown to the player as a range. **Built.** | — |

## 5. Build order — updated to reflect what's actually built

1. ~~Exporter + workbook: both new tabs...~~ **Built** — one template
   visitor+question (`VI01`/`VQ01`), not the full ~6/~10 placeholder set;
   see §6.
2. ~~`BattleSetup` selection...~~ **Built.**
3. ~~`OfficeHoursEngine.gd` + full headless GUT coverage...~~ **Built.**
4. ~~Reward/penalty application in `GameState`...~~ **Built.**
5. `VisitorScreen.tscn` + `VisitorPresenter.gd` + `OfficeScreen.gd`
   routing. **Not built** — the one remaining step.
6. Real click-driven interaction test (`tests/interaction/`), extending
   `loop_driver.gd`'s pattern to walk a Non-combat stage. **Not built** —
   needs step 5 first.

## 6. Built already (2026-09-25)

- **`tools/export_data.py`**: the `target_delta_list` coerce kind,
  including range deltas (`"BO01 +1-6"` → `{"min": 1, "max": 6}`, caught as
  a gap and added the same day — see the delta-shape table above); the
  `Visitors` tab schema rewritten to the resolved 8-column shape in §1.1
  (replacing the dead 2-choice stub); the new `Visitor Questions` tab
  schema from §1.2.
- **The real master workbook** now has both tabs — added via the
  established raw XML zip-surgery method (new sheet files plus the three
  registry parts that reference them; every pre-existing sheet's bytes,
  cached formulas included, verified byte-identical before the file was
  replaced). One template row in each: visitor `VI01` ("Sample
  Constituent", eligible for ST07), question `VQ01` (a 4-choice exchange),
  `VI01`'s Reward is `"BO01 +1; BO02 +1-3"` — one static entry and one
  range entry, exactly the shapes point 3 asked to demonstrate — and its
  Penalty is `"BO01 -1"`.
- **`data/visitors.json` / `data/visitor_questions.json`**: real, exported
  files (1 row each) — not the ~6/~10 placeholder set the original build
  order sketched; expanding the roster is content work for Cameron, not a
  code gap.
- **`scripts/rules/RewardTargets.gd`**: pure ID-prefix classifier — `BOxx`
  → booster, `Mxx` → modifier, `SHxx` → shop item. No data access, fully
  unit-testable.
- **`scripts/autoload/DataDB.gd`**: loads `shop.json` (existed on disk with
  29 real rows, nothing read it before 2026-09-25), `visitors.json`,
  `visitor_questions.json`, and `level_visitor_overrides.json` (new, a
  visitor-pin file with the same shape and purpose as
  `level_opponent_overrides.json`, kept separate rather than widening it).
  `resolve_reward_target(entry)` pulls the real record for any
  target_delta_list entry, any kind, any delta shape. Boot-time validation
  now cross-checks every Visitor's stage eligibility and Reward/Penalty
  targets, every Visitor Question's link to a real Visitor and a real,
  answerable A–D, and visitor pins the same way opponent pins are checked.
- **`scripts/BattleSetup.gd`**: `eligible_visitors()` / `_visitors_for()` /
  `_resolve_visitor_pin()` / `_question_for_visitor()` — direct twins of
  the opponent-selection functions, same dynamic-by-default rule.
  `expand_level()` now draws a stage's real `visitors` list (each with its
  own drawn question already attached) whenever the stage's `mode` is
  `Non-combat`, the same place it already draws `opponents` for Combat.
- **`scripts/rules/LevelRunner.gd`**: a Non-combat stage with an empty
  drawn visitor pool is now rejected by `problems()`, the same as an empty
  combat opponent pool — closing the gap the earlier Non-combat exemption
  (2026-09-25, the "no questions or opponents found" fix) deliberately left
  open until visitors were real.
- **`scripts/rules/OfficeHoursEngine.gd`** (new): the actual rules engine —
  see §2.
- **`scripts/autoload/GameState.gd`**: `apply_visitor_reward_entries()` —
  see §2.
- **48 new GUT tests** across 4 new files
  (`test_reward_targets.gd`, `test_office_hours_engine.gd`,
  `test_visitor_reward_application.gd`, `test_visitor_selection.gd`) plus
  one in `test_level_runner.gd` and one in `test_real_battle.gd` pinning
  down today's safe-failure behavior at the UI boundary. 566/566 passing,
  real click-driven loop test still clean.

**Not built:** the UI (§3) — `VisitorScreen.tscn`, `VisitorPresenter.gd`,
and `OfficeScreen.gd` routing. Today, a level that reaches a Non-combat
stage opens `BattleScreen.tscn` as normal and gets a clean refusal
("there is nobody to argue with") rather than a crash or a broken battle —
safe, but not playable. That refusal is itself covered by a test
(`test_real_battle.gd`) so it can't silently start doing something worse
before the UI exists to replace it.
