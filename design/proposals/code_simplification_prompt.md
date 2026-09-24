# Prompt: behaviour-preserving code simplification pass

> **How to use:** paste everything below the line into a fresh Claude Code
> session on this repository. It was written against commit `8c3b74c`
> ("Add the item inventory, Supplies shop, and item use"). Line numbers are
> from that commit and will drift, so treat them as pointers, not addresses.

---

## Executive summary

You are doing a **clean-up pass** on *Coliseum of Parliament*. The goal is
less code and fewer places that have to be kept in step, **with the game
behaving exactly as before**. You are not adding features, fixing balance, or
settling any design question.

| | |
|---|---|
| **What changes** | Duplicated logic, hard-coded lists that shadow data, changelog-style comments, dead or misleading docs |
| **What must not change** | Any number the game produces, any sentence it shows, any save/data format, any `data/*.json` schema, any test's expectation |
| **Proof** | `tools/verify.sh` is green before and after, test count does not fall, and the web page's parity summary still matches |
| **Process** | Baseline → written plan → **stop for Cameron's approval** → small commits → report |
| **Reader** | Cameron, the designer. Not a programmer. Every report is in plain English |

Read `CLAUDE.md` in full before starting. Everything in it still applies; this
prompt only narrows the task.

---

## 1. Ground rules

| Rule | Why |
|---|---|
| **No behaviour change.** A refactor that changes a roll, a clamp, an order of operations, a warning's text, or which record wins a tie is not a refactor. | Cameron balances from playtests; a silent change invalidates them. |
| **Found a bug or inconsistency? Report it, don't fix it.** List it in the plan and the final report (section 5). Fix it only if Cameron says so, and then in its own commit with its own test. | CLAUDE.md §12: never decide on his behalf. |
| **`scripts/rules/` never reads an autoload.** Autoloads and UI *may* call rules code; the reverse is forbidden. | CLAUDE.md §5, §12. Tests prove rules run without UI. |
| **No new dependencies, no schema changes, no ID renames, no data edits.** | CLAUDE.md §12 "ask before". |
| **Nothing in §9 "Still unresolved" or in the §11 "specified but NOT switched on" table is removed or wired up.** Inert-but-tested code stays. | Those are deliberate seams awaiting decisions. |
| **No text changes.** Every string comes from `data/strings.json`; `tests/wording_snapshot.json` must still match. | CLAUDE.md §6. |
| **Rules changes are mirrored.** If you change *behaviour* in `scripts/rules/` (you should not), `web/src/engine.js` changes in the same commit. A pure restructuring of GDScript needs no mirror, but the web parity summary must still pass. | `web/README.md`. |
| **Keep the comment density.** CLAUDE.md asks for heavily commented code. Simplify comments by making them *present-tense and about why*, not by deleting them. | Cameron reads these. |
| **Small commits, plain-English messages.** One idea per commit. | CLAUDE.md §3, §12. |
| **Anything over ~150 new/changed lines in one step needs the plan approved first.** This whole task qualifies, so Phase 1 is mandatory. | CLAUDE.md §12. |

---

## 2. Process

### Phase 0 — Baseline (no edits)

1. Get Godot if it is not on the PATH: `tools/get_godot.sh`.
2. Run `tools/verify.sh` and save the output. Record:
   - pass/fail of each of the four steps,
   - the GUT totals (tests, asserts, passes, failures),
   - whether step 4 ran or was skipped for lack of `xvfb-run`.
3. Build and check the web mirror: `python3 tools/build_web_playtest.py`, then
   open `web/playtest.html` headlessly (Playwright + the pre-installed
   Chromium) and record the parity summary line at the bottom of the page.
4. If anything is already red, **stop and report it** before touching code. Do
   not start a refactor on a red baseline.

### Phase 1 — Plan, then stop

Produce `design/proposals/code_simplification_plan.md` containing:

- A table of every change you intend to make: ID, files, what changes, why it
  is safe, how you will prove it, estimated lines removed/added.
- A separate table of **behaviour differences you found but will not fix**
  (section 5 seeds this).
- Anything in section 3 you decided *not* to do, and why.

Commit the plan on its own, push, and **stop**. Summarise the plan for Cameron
in the chat in plain English with a table, and wait for approval.

### Phase 2 — Execute (after approval only)

For each approved item, in the order in section 3 (lowest risk first):

1. Make the change.
2. Run the relevant GUT tests, then the full `tools/verify.sh`.
3. If a rules script changed, rebuild the web page and check the parity line.
4. Re-read your own diff adversarially: *could any input now produce a
   different number, different text, or a different warning?* If yes, undo.
5. Commit with a message Cameron can read, e.g. "Keep the committee stage list
   in one place instead of two".

Never batch several items into one commit. If an item turns out riskier than
planned, skip it and note why.

### Phase 3 — Report

Finish with a message to Cameron containing:

- **Executive summary** (3–4 sentences).
- A table: item, what changed, lines before → after, how it was verified.
- Before/after `verify.sh` results and test counts.
- The "found but not fixed" table, each with a one-line question for him.
- Anything skipped, and why.

Push to the branch you were told to use. Do not open a pull request unless
asked.

---

## 3. Work list

These were found by reading the code. **Confirm each one yourself before
acting**; if the code has moved on, adapt or drop the item.

### Tier A — low risk, clear win

| ID | Where | Problem | Proposed simplification |
|---|---|---|---|
| **A1** | `scripts/autoload/DataDB.gd:56` (`COMMITTEE_STAGE_IDS`), `:560` (`is_committee_stage`); `scripts/rules/BattleEngine.gd:41`, `:67` | The committee stage list and the "declared `bar_model` wins, else fall back to the list" logic exist twice. Both comments say it *cannot* be deduplicated because rules code cannot read DataDB — but the dependency only has to go one way. DataDB is allowed to call rules code. | Make `DataDB.is_committee_stage(stage_id)` return `BattleEngine.is_committee_stage(get_stage(stage_id))` and delete DataDB's copy of the list. Rewrite both comments to say where the single list lives. Check the empty-stage case (`get_stage()` on an unknown ID) gives the same answer as before. |
| **A2** | `BattleEngine._string_field` (`:62`), `DataDB.is_committee_stage`, `BattleSetup._question_pool_name` (`:408`), `BattleSetup._reputation_affects_start` (`:418`), `BarModel.for_stage` | The same "a workbook cell may be JSON `null`; `str(null)` is `"<null>"`; treat null/blank as absent" guard is hand-written in several places, each with its own paragraph explaining it. | One static helper in `scripts/rules/` (on an existing script, or a tiny new `Cell.gd` if that reads better — say which in the plan) that returns the trimmed string or a fallback. Call it everywhere; explain the `<null>` trap **once**, at the helper. Watch for subtle differences: some sites lowercase, some `strip_edges()`, some do neither. Preserve each site's exact result. |
| **A3** | `scripts/autoload/GameState.gd` — `_apply_staff_reward` (`:322`), `_apply_level_bonus_win` (`:522`), `_please_organisations` (`:635`), `_apply_booster_delta` (`:848`), `_apply_segment_delta` (`:863`) | Booster standing is read-clamped-written-recorded in four places; segment favourability in two. `_apply_booster_delta` / `_apply_segment_delta` already exist as the general form. | Route the copies through the two helpers. **But** the copies do not all record the change the same way (see section 5, items F1–F2). Where routing through the helper would change what `last_booster_change` / `last_segment_change` hold, either keep that site as-is or add a parameter that preserves its current behaviour, and list it in section 5 of the plan. Do not "fix" it in passing. |
| **A4** | `README.md` | The root README is a byte-for-byte copy of `web/README.md` ("This folder is a browser copy…"). CLAUDE.md tells readers to "see `README.md` for a concise project snapshot", which it is not. | Propose (in the plan) a short root README: what the game is, how to run it, how to run `tools/verify.sh`, where data and design docs live, and a link to `web/README.md`. Facts only, taken from CLAUDE.md and the code; nothing about canon. Needs Cameron's OK because it is prose he will read. |
| **A5** | Comments across `scripts/` — 44 dated comments (e.g. "2026-09-24 — every canon row…", "Cameron settled this 2026-09-22") and many multi-paragraph histories | Comments narrate *how the code got here* rather than *why it is like this now*. Git already records history. Some are now wrong (A1's "cannot be deduplicated"). | Rewrite as present-tense "why" comments of the same usefulness. **Keep** every design decision and every `[DEFAULT]` marker, and keep the decision's owner ("Cameron's call") where it tells a future reader not to change it unilaterally; drop only the date and the story. Do this file by file, one commit per file or small group, and only in files you are already touching or that are clearly worst. Grep: `grep -rnE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' scripts`. |

### Tier B — medium risk, worthwhile

| ID | Where | Problem | Proposed simplification |
|---|---|---|---|
| **B1** | `scripts/BattleSetup.gd` — `_override_for` / `_visitor_override_for` (`:146`, `:308`); `_resolve_pin` / `_resolve_visitor_pin` (`:265`, `:317`); `_opponents_for` / `_visitors_for` (`:204`, `:339`) | Three pairs of near-identical functions that differ only in the override table, the ID field (`opp_id` / `visitor_id`), the lookup function and the warning noun. | One generic "pick `count` from the eligible list, honouring a pin" helper, parameterised by those four things. **Differences to preserve:** `_opponents_for` with `count <= 1` delegates to `_opponent_for`, while `_visitors_for` handles it inline — confirm they give the same result before merging them, and keep each warning's exact wording. |
| **B2** | `GameState._apply_level_bonus_win` (`:545`): `for n in range(1, 17): "BO%02d" % n` | Hard-codes that there are 16 boosters, contrary to "never hardcode numbers". Today it matches `boosters.json`, so switching is behaviour-neutral. | Iterate `DataDB.boosters` (sorted by ID, to keep the roll order identical) and build the `win_delta_boNN` key from each ID. Confirm that roll order is unchanged, because each `_roll_range` call consumes the unseeded RNG. |
| **B3** | `GameState._roll_range` (`:562`), `_resolve_delta` (`:877`), `_stage_effect_amount` (`:833`); `BattleSetup._opponent_count` (`:182`) | Several small "number, null, or `{min,max}` range" resolvers, each with its own null rule. | Consider one shared resolver with an explicit "what null means" argument. Only do this if the call sites become clearer; if it needs more than one flag to cover them all, leave it and say so. |
| **B4** | `scripts/ui/OfficeScreen.gd` (901 lines): `_heading_label`, `_wrapped_label` and the many `_*_row()` builders | Row-building boilerplate is repeated for each panel (cards, supplies, deck, backing, staff, levels). | Look for repeated widget construction that can become one or two helpers **within the file**. Do not split the screen into new scenes in this pass; that is a design-level change. Verify with the three interaction tests in `verify.sh` step 4, which click real buttons. |

### Tier C — propose only, do not implement in this pass

List these in the plan with a short sketch and a size estimate, so Cameron can
decide whether to schedule them. **Do not implement them.**

| ID | Where | Idea |
|---|---|---|
| **C1** | `scripts/rules/BattleEngine.gd` (1,324 lines) | Press-conference question handling (`_draw_questions`, `_answer_question`, `_grade_of`, `question_caption`, `_decline_question`, …) and multi-opponent sequencing (`_advance_to_next_opponent`, `_reset_for_new_bout`, …) could become their own rules scripts, like `CommitteeModel` and `BarModel` already are. Would need a mirrored split decision for `web/src/engine.js`. |
| **C2** | `DataDB._validate()` (~230 lines at `:747`) | Split into one validator per file/relationship so the report is easier to extend. |
| **C3** | `BattleSetup.QUESTION_POOL_BY_STAGE`, `REPUTATION_START_STAGE_IDS`, `BarModel.for_stage` ST04/ST06 fallbacks, `COMMITTEE_STAGE_IDS` | Stage IDs hard-coded as fallbacks for workbook columns (`question_pool`, `reputation_affects_start`, `bar_model`) that canon rows do not fill yet. The real fix is filling those columns in the workbook, which is Cameron's data, so it is a question for him, not a code change. |
| **C4** | `tools/export_data.py` (1,869 lines) | Out of scope for this pass beyond noting obvious duplication. It is the data contract; changes there need their own review. |

### Beyond the list

Once the list is done, you may do a **short, general sweep** of `scripts/` for:

- functions nothing calls (confirm with a grep across `scripts/`, `tests/`,
  `tools/` and `scenes/`, including string-based calls such as `call()`,
  `connect()` and `.tscn` signal connections),
- unused `var`s, `const`s and parameters,
- copy-pasted blocks of five or more lines,
- comments that contradict the code.

Anything you find goes into the plan's table as a new ID before you touch it.
**Exclude** anything in the CLAUDE.md §11 "specified but NOT switched on" table
and the §13 seams (EventBus signals, Audio, portrait expressions): they look
unused on purpose.

---

## 4. Out of scope

| Area | Reason |
|---|---|
| `data/*.json`, `design/*.xlsx` | Source of truth; Cameron owns it. |
| `addons/gut/` | Third-party. |
| `web/src/ui.js`, `web/src/index.html` | Presentation; `web/README.md` says not to polish it. |
| `tests/` expectations | Tests may be *tidied* (shared fixtures, removed duplication), but no assertion may be weakened, deleted or re-pointed at a new value. The test count must not fall. |
| Renaming public functions, signals, autoloads, `class_name`s or scene paths | Breaks scenes, tests and the web mirror's naming; not worth it here. |
| Performance work | Not the goal. |
| Anything touching canon, open questions, or §8 rules that are not switched on | CLAUDE.md §4, §9, §11. |

---

## 5. Behaviour differences already spotted (report, do not fix)

These look like accidental inconsistencies. Put them in the plan and the final
report as questions for Cameron. If he says fix one, do it in its own commit,
with a GUT test, and mirror it in `web/src/engine.js` if it is rules code.

| ID | Where | What happens | Question for Cameron |
|---|---|---|---|
| **F1** | `GameState._please_organisations` (`:635`) | Sets `last_booster_change[id] = after - before`, **replacing** any earlier change recorded this round. Every other booster change **adds** to it. | "If an organisation's standing moves twice before you look, should the report show the total or only the last move?" |
| **F2** | `GameState._apply_staff_reward` segment branch (`:343`) | Records `last_segment_change` even when the value did not move, and replaces rather than adds. `_apply_segment_delta` adds and skips no-ops. | Same question, for voter segments. |
| **F3** | `GameState._apply_level_bonus_win` (`:545`) | Only pays `win_delta_bo01`–`bo16`; a 17th booster would silently get nothing. | Covered by B2 if approved; flag only if B2 is not done. |

Add to this table anything else you find.

---

## 6. Definition of done

- [ ] Baseline recorded; `tools/verify.sh` green before and after, with the
      same or higher test count, and step 4 run (not skipped) if `xvfb-run` is
      available.
- [ ] Web parity summary unchanged.
- [ ] `tests/wording_snapshot.json` untouched and passing.
- [ ] No file under `data/` or `design/*.xlsx` changed.
- [ ] Every approved item is its own commit with a plain-English message.
- [ ] `scripts/rules/` still contains no reference to an autoload
      (`grep -rnE 'DataDB|GameState|EventBus|Audio|SaveManager|Text\.' scripts/rules`
      matches only comments).
- [ ] Plan file updated with what was actually done, skipped, or deferred.
- [ ] Final report to Cameron posted, with the executive summary and tables
      described in Phase 3.
