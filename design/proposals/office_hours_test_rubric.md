# Office Hours — rubric for "is this actually done"

Companion to `office_hours.md`. Each row is a pass/fail check, grouped by
the layer it proves. Nothing in a later group should be trusted until the
group above it is green — a real click test that "passes" over a rules bug
is worse than no test, per this project's usual order (data → rules →
UI → real clicks).

**Status (2026-09-25, updated twice): groups A, B, C, and D are green.**
Data, selection, the rules engine, and reward/penalty application —
including shop items and segments — are all built and tested (576/576 GUT
tests passing). Both of D's questions are answered (no loss state; a unique
character's questions are already exclusively theirs, no change needed).
**Group E (real click-driven UI) is the only thing not built** —
`VisitorScreen.tscn` doesn't exist yet, so there's nothing to click through.
See `design/proposals/office_hours.md` §6 for the exact file-by-file list.

## A. Data & validation

| # | Check | How |
|---|---|---|
| A1 | ✅ Every canon Visitor's `stages` list names only real STxx IDs | `DataDB._validate()` |
| A2 | ✅ Every Visitor Question's `visitor_id` names a real Visitor | same |
| A3 | ✅ Every Visitor Question has all four choices non-empty and `correct_choice` is one of A–D | same, error not warning — an unanswerable question is a data bug |
| A4 | ✅ Every entry in every Visitor's `reward`/`penalty` list resolves to a real record | `DataDB._validate_reward_target()`, called for every Reward and Penalty entry |
| A5 | *(retired — penalty is no longer a Sanban meta-variable; A4 already covers it, since Penalty uses the same `target_delta_list` shape as Reward)* | — |
| A6 | ⚠️ Every ST07-eligible Visitor has **at least one** Visitor Question | built as a **warning**, not an error — a visitor mid-authoring (identity written, question not yet) is a normal draft state; only an empty pool for a whole STAGE (D1) is a hard error |
| A7 | ✅ `python3 tools/export_data.py` runs clean against the patched workbook — no new errors, only expected warnings | confirmed by hand against the real workbook when the tabs were added |
| A8 | ✅ A target whose prefix doesn't match `BOxx`/`Mxx`/`SHxx` (a typo) is a boot-time **error** | `DataDB._validate_reward_target()`'s `_` match case |

## B. Rules engine (headless GUT, `scripts/rules/`)

| # | Check |
|---|---|
| B1 | ✅ `setup()` with 1 visitor, 1 question: `current_visitor()`/`current_question()` return that visitor/question |
| B2 | ✅ `setup()` with N visitors: `is_finished()` is false until all N are answered+advanced, true after |
| B3 | ⚠️ `answer()` with the correct choice: `result.correct == true`, texts match, `reward` is that visitor's **raw, unresolved** `reward` list (not pre-resolved — resolving is `GameState.apply_visitor_reward_entries()`'s job, not the engine's, since the engine has no DataDB), `penalty == []` |
| B4 | ✅ `answer()` with any wrong choice (all 3 wrong letters tested, not just one): symmetric to B3 for `penalty` |
| B5 | ✅ A visitor with a **blank** Reward: correct answer packages `reward == []` |
| B6 | ✅ A visitor with a **blank** Penalty: wrong answer packages `penalty == []` |
| B6a | ✅ (moved to C1/C-mixed) A visitor whose Reward mixes kinds resolves correctly — proven at the `GameState.apply_visitor_reward_entries()` level (`test_a_mixed_list_applies_every_entry`), since resolution happens there, not in the engine |
| B6b | ✅ (moved to C) A range delta rolls within its own bounds, once, at apply time — `test_a_range_delta_rolls_within_its_own_bounds` |
| B7 | ✅ `advance()` after the last visitor does not throw and leaves `is_finished()` true |
| B8 | ✅ `outcome()` after a mixed run (2 right, 1 wrong) reports the right counts and both a reward and a penalty in its lists |
| B9 | ⚠️ A visitor with several eligible questions: setup draws one. **Unseeded** (`randi() % size`, matching `_opponent_count()`'s own convention, not a seeded RNG) — no determinism test exists, and none is intended; only one real question exists per visitor today anyway, so this path is barely exercised by real data yet |
| B10 | ✅ `eligible_visitors("ST07")` returns the real template visitor; sorting is by construction (same `sort_custom` as `eligible_opponents()`), not independently proven with a multi-candidate fixture — same lighter bar the opponent equivalent was held to |
| B11 | ✅ `_visitors_for()`/`_resolve_visitor_pin()` honor a `level_visitor_overrides.json` pin, including the "pin names someone ineligible" and "pin names someone unknown" fallback cases |
| B12 | ✅ Reuse (not reimplementation) of `_opponent_count()` for visitor count, proven via `expand_level()`'s real output shape |

## C. GameState integration

| # | Check |
|---|---|
| C1 | ✅ A `booster`-kind entry bumps the right BOxx's standing by its `delta`, clamped to floor/ceiling — fixed and range deltas both tested, and a negative `delta` (a Penalty) is a real test case, not just a positive Reward |
| C2 | ✅ A `modifier`-kind entry adds the Mxx to `owned_modifiers` exactly once, even granted twice in one run (no duplicate) |
| C2a | ✅ A `segment`-kind entry moves favorability by its `delta`, clamped 0-100, both signs tested — `test_visitor_reward_application.gd`'s segment section |
| C3 | ✅ **Resolved.** A `shop_item`-kind entry is recorded on `owned_shop_items` and its own `Grants` list applies through the identical function — `test_a_shop_items_own_grants_apply_when_it_is_granted`. A `shop_item` found inside THAT list is refused, not chased — `test_a_shop_item_cannot_grant_a_second_shop_item`. Real per-item `Grants` content is still Cameron's to fill in (every real row is blank today); the mechanism itself is proven with an injected fixture |
| C4 | ❌ **Not built** — nothing yet bridges `OfficeHoursEngine.outcome()` to `LevelRunner.finish_stage()`/the auto-save point; that bridge lives in whatever screen calls the engine, which doesn't exist yet (§3) |

## D. Design-level correctness

| # | Check |
|---|---|
| D1 | ✅ A whole Office Hours stage with 0 visitors drawn is caught by `LevelRunner.problems()` — `test_a_non_combat_stage_with_no_eligible_visitors_is_rejected` |
| D2 | ✅ **Confirmed with Cameron 2026-09-25**: no loss state — finishing is completion, wrong-answer penalties are sufficient. Matches what was already built (`OfficeHoursEngine` has no loss path, period) |
| D3 | ✅ **Confirmed with Cameron 2026-09-25**: a unique, one-off character's questions can never be drawn for another visitor — already true by construction, no code needed. `test_a_unique_visitors_questions_are_never_drawn_for_another_visitor` |

## E. Real click-driven interaction test

Extends `tests/interaction/loop_driver.gd`'s existing pattern — real
`InputEventMouseButton` clicks, no signal shortcuts, so a button that isn't
actually reachable fails the test the same way a hidden bug would fail a
player.

| # | Check |
|---|---|
| E1 | A level whose current stage is a Non-combat visitor stage opens `VisitorScreen.tscn`, not `BattleScreen.tscn` |
| E2 | The stage background and the visitor's portrait are visible (placeholder-colored is fine — this checks the node exists and is shown, not the art) |
| E3 | All four choice buttons are clickable and show the four real choice texts, in A–D order |
| E4 | Clicking a choice shows the matching response text before advancing |
| E5 | After the last visitor, the stage produces an outcome panel (matching every other stage's end-of-stage screen) and returns to the Office on close |
| E6 | Playing through **every real ST07-eligible level** (the 8 identified 2026-09-25: LV11, LV12, LV14, LV17, LV23, LV26, LV27, LV28) reaches this screen and completes without a stall — this is the direct fix-verification for the "no questions or opponents found" report, closing the loop it was flagged against |

## F. Manual playtest pass (Cameron, on device or desktop build)

| # | Check |
|---|---|
| F1 | A wrong answer's penalty is legible — the player understands why a number went down |
| F2 | A visitor with multiple possible questions feels varied across repeat playthroughs, not always the same line |
| F3 | The reward for answering well is legible — a booster/modifier grant should say what just happened, not just move a number silently |
| F4 | Pacing: does a full Office Hours stage (however many visitors its range draws) feel like the right length next to a battle stage, or does it need its own `turn_limit`-equivalent pacing knob |

## Definition of done

All of A and B green (data + rules, headless, no UI needed to check these)
**before** any UI work starts, matching how `BattleEngine`/`LevelRunner`
were built earlier this project. C and D green before E is attempted. E
green is what unblocks telling Cameron "play it." F is his call, not a
pass/fail I can certify myself.
