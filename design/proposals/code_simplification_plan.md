# Plan: code simplification pass (2026-09-27)

**Status: done.** This plan was written against the codebase as it stands
today — commit `1017b29`, well past the `8c3b74c` snapshot the source prompt
(`code_simplification_prompt.md`, attached by Cameron) was written against.
Section 0 records what actually happened; the rest is the assessment that
led to it.

## 0. What happened

Baseline (before any edit): `tools/verify.sh` all green, 677 tests / 4801
asserts, step 4 (click tests) ran under `xvfb-run`, web parity "172 of 172
agree with the Godot engine."

Of the prompt's 13 numbered work items (A1–A5, B1–B4, C1–C4) plus 3 found
issues (F1–F3), the codebase had already moved past several of them by
itself, in earlier rounds of this same session:

| ID | Verdict | Why |
|---|---|---|
| A1 | **Done this pass** | Still exactly as described: `DataDB.COMMITTEE_STAGE_IDS` and `BattleEngine.COMMITTEE_STAGE_IDS` are two copies of the same 11-ID list. |
| A2 | **Done this pass, scaled down** | The four sites have diverged since the prompt was written: `_string_field` doesn't treat an empty (non-null) string as absent, the way the other three do; `_reputation_affects_start` returns a bool and `strip_edges()`s; `_question_pool_name` chains two independently-guarded fields into a dict-lookup fallback, not a plain default. Forcing one polymorphic helper over real, currently-untested differences is exactly what §1's "no behaviour change" rule warns against. Comment-only: the `<null>` trap is now explained once and referenced, not repeated four times. |
| A3 | **Already done** | Fixed in this session's earlier "Tidy: one place for standing changes and for shop buttons" commit (`2a4b58b`) — `_apply_staff_reward`, `_apply_level_bonus_win` and `_please_organisations` already route through `_apply_booster_delta`/`_apply_segment_delta`. |
| A4 | **Done this pass** | Root `README.md` was still a byte-for-byte copy of `web/README.md`. Replaced with a real project snapshot. **This is prose Cameron should skim** — see the report. |
| A5 | **Deferred** | Still a real pattern (50 dated comments across 16 files now, up from 44 — this session added its own). Full sweep is out of proportion to this pass; only touched where A1/A2 already required an edit. |
| B1 | **Rejected — do not do** | The code already explains, in its own comment (`BattleSetup.gd`, above `eligible_visitors()`), exactly why the opponent and visitor pin-resolution functions are kept separate rather than merged: "the moment they diverge (and Office Hours already diverges: no committee shape, no sequence_mode) sharing the code would cost more than these few lines of duplication save." That is a considered decision already on record, not an oversight. |
| B2 | **Done this pass** | Still hardcodes `range(1, 17)` / `"BO%02d"`. Confirmed `data/boosters.json` is exactly BO01–BO16 today, so the fix is behaviour-neutral now and future-proof if a 17th is added. Also closes F3. |
| B3 | **Skipped** | `_roll_range`/`_opponent_count` genuinely differ in domain defaults (0 vs 1, floored vs not) — not just repeated code. Per the prompt's own permission ("if it needs more than one flag to cover them all, leave it"), left alone. |
| B4 | **Already done** | `UiKit.gd` (this session, commit `2a4b58b`) already extracted the repeated label/button/column construction `OfficeScreen.gd` was doing by hand. The remaining per-panel `_*_row()` functions build genuinely different content per row and are not boilerplate. |
| C1–C4 | **Still propose-only, not implemented** | Sizes are in the same range as before (`BattleEngine.gd` 1324 lines, `export_data.py` 1893, `DataDB._validate()` ~373 lines to end of file). Listed below for Cameron to schedule if he wants them. |
| F1 | **Already resolved** | Fixed alongside A3 (`2a4b58b`): a booster pleased twice in one level now reports the total change, not just the last. Disclosed in that commit's own message at the time. |
| F2 | **Already resolved** | Same commit: `_apply_staff_reward`'s segment branch now adds and skips no-ops, via `_apply_segment_delta`. |
| F3 | **Resolved by B2** | A 17th booster now gets its `win_delta_boNN` read like every other one. |

Net new code touched this pass: `scripts/autoload/DataDB.gd`,
`scripts/rules/BattleEngine.gd`, `scripts/autoload/GameState.gd`, `README.md`.
Four commits, each independently green.

**Not done — full "beyond the list" sweep** (unused functions/vars, 5+ line
copy-paste blocks, contradicting comments) was not carried out as its own
exercise. The codebase has been through several of my own cleanup passes
already this session; nothing suspicious turned up incidentally while
reading the files above. If Cameron wants a dedicated sweep, it is worth
its own pass rather than folding into this one.

---

## 1. Assessment detail (why each verdict)

### A1 — committee stage list, two copies

`DataDB.gd:56` and `BattleEngine.gd:41` carry the identical 11-ID list, each
with a comment claiming the other cannot be reached ("rules code cannot read
DataDB, so it cannot be deduplicated further than 'keep both lists in sync'"
— true in one direction only). `DataDB` is an autoload; it is allowed to
call `scripts/rules/` code (CLAUDE.md §5, §12 only forbids the reverse).

**Fix:** `DataDB.is_committee_stage(stage_id)` becomes
`BattleEngine.is_committee_stage(get_stage(stage_id))`; `DataDB`'s own list
and duplicate bar_model check are deleted.

**Edge case checked:** the two versions differ for a stage_id that does not
exist in `stages.json` — the old `DataDB` version checks the ORIGINAL id
string against the list; the new version checks `get_stage(id).get(
"stage_id", "")`, which is `""` for an unknown id (an empty dict has no
`stage_id` key). Both real call sites (`DataDB._validate()`,
`BattleSetup.gd:83`) already confirm the id exists in `stages.json` before
calling this, and no test calls it with an unknown id — grepped
`tests/test_stage_rules_columns.gd` and the rest of `tests/` to confirm.
Behaviour-neutral for every real (and every currently tested) input.

### A2 — the `<null>` trap, four sites

Re-read all four sites (`BattleEngine._string_field`,
`BarModel.for_stage`/`BattleEngine.is_committee_stage`'s guard,
`BattleSetup._question_pool_name`, `BattleSetup._reputation_affects_start`)
line by line. They no longer share one shape:

| Site | Empty string (non-null) | Trim | Returns |
|---|---|---|---|
| `_string_field` | **kept as-is**, not treated as absent | no | lowercased string or fallback |
| `is_committee_stage` / `BarModel.for_stage` | treated as absent | no | bool / enum |
| `_question_pool_name` | treated as absent (per field) | no | string, via a two-field chain then a dict lookup |
| `_reputation_affects_start` | treated as absent, after trimming | **yes** | bool |

A single parameterised helper covering all four safely needs at least three
independent flags (empty-counts-as-absent, trim, lowercase) before it is
even attempted, at which point the "one paragraph explaining the trap" the
prompt wants has become a flag table nobody reads faster than four short
functions. That is the prompt's own escape hatch in the B3 write-up,
applied here.

**What was still worth doing:** the `<null>` trap explanation — "stages.json
carries this column as an explicit JSON null on a row that doesn't set it,
not an absent key; `str(null)` is the literal text `"<null>"`, not `""`" —
was written out in full at three of the four sites. It is now written once
(at `BarModel.for_stage`, the first one a reader is likely to meet) and the
other three point to it in one line. No behaviour touched.

### A4 — root README

`README.md` and `web/README.md` were identical, and CLAUDE.md's own header
note says "see `README.md` for a concise project snapshot" — a promise the
file did not keep. Replaced with a short, factual snapshot: what the game
is, the hard constraints, how to run `tools/verify.sh`, where data and
design docs live, and a link to `web/README.md` for the browser mirror.
Nothing about canon or design decisions; every fact is copied from CLAUDE.md
or the code itself.

### B1 — opponent/visitor pin-resolution pairs

Re-read `scripts/BattleSetup.gd` in full. Immediately above
`eligible_visitors()` sits:

> "Kept as separate functions rather than generalising both into one,
> because 'eligible for a stage' and 'who is in the room' mean different
> things for a person you argue with and a person you talk to — the moment
> they diverge (and Office Hours already diverges: no committee shape, no
> sequence_mode) sharing the code would cost more than these few lines of
> duplication save."

This is the exact merge B1 proposes, already considered and declined on the
record. Re-opening it without a new reason would be re-litigating a design
call CLAUDE.md §12 says is not mine to make. Also concretely: `_opponents_for`
delegates its `count <= 1` case to a freshly-called `_opponent_for()`, while
`_visitors_for` computes `pinned` once up front and reuses it in both
branches — a real shape difference, not just duplicated syntax.

### B2 — hardcoded 16 boosters

`data/boosters.json` today is exactly `BO01`–`BO16`, no gaps (checked
directly). Changed `_apply_level_bonus_win()` to iterate `DataDB.boosters`
sorted by `booster_id` — same order the old `range(1, 17)` produced, which
matters because each iteration calls the unseeded `_roll_range()` — and
build the `win_delta_boNN` key from each row's own id, lowercased.
Behaviour-neutral today; stops silently ignoring a 17th booster if one is
ever added to the workbook (this was F3).

### B3 — small range resolvers

`GameState._roll_range` (default 0, no floor), `BattleSetup._opponent_count`
(default 1, floored at 1) genuinely encode different domain rules — a
reward that fails to roll should give nothing; a stage that fails to roll an
opponent count still needs at least one opponent. Left separate.

### B4 — OfficeScreen.gd row builders

Already addressed this session (`UiKit.gd`): `line()`, `heading()`,
`action_button()`, `tight_column()` replaced the hand-built labels and
buttons across every panel. What is left — `_card_row`, `_supply_row`,
`_deck_row`, `_modifier_row`, `_staff_candidate_row`,
`_organisation_row`, `_protagonist_row` — each lay out genuinely different
fields for genuinely different data; merging them further would trade
readability for a smaller line count, which is not the goal.

---

## 2. Tier C — still propose-only (not implemented, per the prompt's own instruction)

| ID | Where | Idea | Size today |
|---|---|---|---|
| C1 | `scripts/rules/BattleEngine.gd` | Split press-conference question handling and multi-opponent sequencing into their own rules scripts, as `CommitteeModel`/`BarModel` already are. Needs a mirrored split in `web/src/engine.js`. | 1,324 lines |
| C2 | `scripts/autoload/DataDB.gd`, `_validate()` | Split into one validator per file/relationship. | ~373 lines to end of file |
| C3 | `BattleSetup.QUESTION_POOL_BY_STAGE`, `REPUTATION_START_STAGE_IDS`, `BarModel.for_stage`'s ST04/ST06 fallback, `BattleEngine.COMMITTEE_STAGE_IDS` (A1 keeps this one, just in one place now) | Fallback lists standing in for workbook columns (`question_pool`, `reputation_affects_start`, `bar_model`) that no canon row fills yet. Filling the columns is the real fix — Cameron's data, not a code change. | 4 fallback lists |
| C4 | `tools/export_data.py` | Out of scope beyond noting it; it is the data contract and needs its own review. | 1,893 lines |

None of these were touched.

---

## 3. Definition-of-done check

- [x] Baseline recorded; green before and after (677/677 → 680/680 — the
      three new tests are B2's, which is the one item that changed an actual
      code path rather than only comments; every other item is comment-only
      or a pure delegation with no new behaviour to test).
- [x] Web parity unchanged (172/172 both before and after).
- [x] `tests/wording_snapshot.json` untouched.
- [x] No file under `data/` or `design/*.xlsx` changed.
- [x] Each item its own commit, plain-English message.
- [x] `grep -rnE 'DataDB|GameState|EventBus|Audio|SaveManager|Text\.' scripts/rules` matches only comments (checked after every commit).
- [x] This file updated with what was actually done, skipped, or deferred.
- [x] Final report posted to Cameron.
