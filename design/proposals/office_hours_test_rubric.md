# Office Hours — rubric for "is this actually done"

Companion to `office_hours.md`. Each row is a pass/fail check, grouped by
the layer it proves. Nothing in a later group should be trusted until the
group above it is green — a real click test that "passes" over a rules bug
is worse than no test, per this project's usual order (data → rules →
UI → real clicks).

## A. Data & validation

| # | Check | How |
|---|---|---|
| A1 | Every canon Visitor's `stages` list names only real STxx IDs | `DataDB` boot-time cross-reference (extend the existing report) |
| A2 | Every Visitor Question's `visitor_id` names a real Visitor | same |
| A3 | Every Visitor Question has all four choices non-empty and `correct_choice` is one of A–D | same, error not warning — an unanswerable question is a data bug |
| A4 | Every Visitor's `reward_target` (when set) names a real BOxx/MODxx/SHxx of the matching type | same |
| A5 | Every Visitor's `miss_penalty_meta` (when set) is one of the 4 real Sanban variable keys | same |
| A6 | Every ST07-eligible Visitor has **at least one** Visitor Question | same — the exact class of bug this whole feature exists to prevent (an empty pool at runtime) |
| A7 | `python3 tools/export_data.py` runs clean against the patched workbook — no new errors, only expected warnings | `tools/verify.sh` step 1 |

## B. Rules engine (headless GUT, `scripts/rules/`)

| # | Check |
|---|---|
| B1 | `setup()` with 1 visitor, 1 question: `current_visitor()`/`current_question()` return that visitor/question |
| B2 | `setup()` with N visitors: `is_finished()` is false until all N are answered, true after |
| B3 | `answer()` with the correct choice: `result.correct == true`, `response_text == response_right`, `reaction == reaction_right`, `reward` matches that visitor's Reward Type/Target/Value, `penalty == {}` |
| B4 | `answer()` with any wrong choice (test all 3 wrong letters, not just one): `result.correct == false`, `response_text == response_wrong`, `reaction == reaction_wrong`, `reward == {}`, `penalty` matches that visitor's Miss Penalty |
| B5 | A visitor with **no** Reward Type set: correct answer packages `reward == {}}`, not a malformed dict |
| B6 | A visitor with **no** Miss Penalty set: wrong answer packages `penalty == {}`, not a malformed dict |
| B7 | `advance()` after the last visitor does not throw and leaves `is_finished()` true |
| B8 | `outcome()` after a mixed run (2 right, 1 wrong) reports the right counts and both a reward and a penalty in its lists |
| B9 | A visitor with several eligible questions: setup draws exactly one, deterministically reproducible under a fixed seed (mirrors `_draw_questions()`'s existing seeding discipline) |
| B10 | `eligible_visitors("ST07")` returns only visitors whose `stages` names ST07, sorted by lowest `visitor_id` first (mirrors `eligible_opponents()`'s own test) |
| B11 | `_visitors_for()` honors a `level_visitor_overrides.json` pin the same way `_opponents_for()` honors an opponent pin — including the "pin names someone ineligible" warning-and-fallback case |
| B12 | `BattleSetup._opponent_count()`'s existing range behavior, exercised through a Non-combat stage's `Opponent Count`, produces the right *visitor* count (reuse, not reimplementation — this test is really checking that reuse actually happened) |

## C. GameState integration

| # | Check |
|---|---|
| C1 | A `Booster` reward bumps the right BOxx's standing by the right amount, clamped to its ceiling like every other standing change |
| C2 | A `Modifier` reward adds the MODxx to `owned_modifiers` exactly once, even if the same modifier is rewarded twice in one run (no duplicate entries) |
| C3 | A meta-variable penalty moves the right Sanban variable by the right (negative) amount, clamped to its floor — a visitor whose penalty would push Jiban below 0 does not produce a negative Jiban |
| C4 | Office Hours completing (win or loss — see D-series for whether this stage even has a "loss") triggers the same auto-save point every other stage does |

## D. Design-level correctness (needs an answer from open point 4 in the proposal first)

| # | Check |
|---|---|
| D1 | A whole Office Hours stage with 0 visitors drawn (empty eligible pool for that STxx) is caught by `LevelRunner.problems()` the same way an empty combat pool is today — not a silent empty screen |
| D2 | Finishing every visitor (regardless of right/wrong mix) ends the stage — Office Hours does not "lose" on a bad answer the way a battle loses on gaffes, unless Cameron says otherwise |

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
