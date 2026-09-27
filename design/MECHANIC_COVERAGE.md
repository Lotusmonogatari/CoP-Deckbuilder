# Mechanic coverage matrix

What actually checks each mechanic today, so "did we evaluate everything"
is something you can look at rather than something you have to trust.
Built 2026-09-28 by reading the real test files, not from memory — see
`tools/verify.sh`'s own comment for how the four layers below fit
together, and `design/PLAYTEST_CHECKLIST.md` for the manual pass that
covers what none of the automated layers can.

**Columns**, cheapest/fastest to most expensive:
- **GUT** — a headless unit test (`tests/*.gd`), proves the *rule* is
  right against fabricated data. Runs in seconds, in `verify.sh` step 3.
- **Click** — a real-mouse-click interaction test (`tests/interaction/
  *_test.tscn`), proves the *screen* actually lets a player do the thing.
  Runs under `xvfb`, in `verify.sh` step 4.
- **Playtest** — `tools/playtest_optimal.gd`, a full automated playthrough
  of the real game loop. Not part of `verify.sh` (run by hand); proves the
  mechanic survives in the context of an actual multi-level run, not just
  in isolation.
- **Manual** — only a phone/emulator playtest catches it (real content
  combinations, real screen geometry, "does this feel right"). See
  `design/PLAYTEST_CHECKLIST.md`.

A mechanic only needs to be caught by *one* layer to be "covered" — the
columns are redundant on purpose where they overlap, and a "—" is an
honest gap, not a rounding error.

## Stage types (§7.3)

| Mechanic | GUT | Click | Playtest | Notes |
|---|---|---|---|---|
| Combat, single opponent, shared-pool bar (ST02/03/05/08/19-21) | `test_bar_model.gd`, `test_battle_engine.gd`, `test_real_battle.gd` | `loop_test.tscn` (whichever level it picks first) | Yes, every level | |
| Combat, committee sequence (ST01/09-18, `sequence_mode: reset`) | `test_battle_engine.gd` ("Several opponents in one stage"), `test_real_battle.gd`, `test_stage_rules_columns.gd` | — | Yes | No interaction test opens a committee specifically |
| Combat, press-tone (ST04, judged on threshold since 2026-09-27) | `test_battle_engine.gd`, `test_real_battle.gd` | — | Yes | The bug this session (dealt 20 questions against a 5-turn clock) was never a GUT gap — the fixture used a small hand-built pool. Real gap was §"Content vs. rules" below |
| Combat, survival (ST06 TV debate) | `test_bar_model.gd` | — | Yes, if reached | |
| Non-combat, Office Hours visitor room (ST07) | `test_office_hours_engine.gd`, `test_visitor_selection.gd` | `office_hours_test.tscn` (now run by `verify.sh` — see Part A) | Yes | |
| Non-combat, Party Steering Committee check-in (ST22) | Same OfficeHoursEngine coverage as ST07 | — | Only if Party support < 25 fires during a run | |
| Vote, National Assembly Floor Voting (ST23) | `test_floor_vote_engine.gd` | `floor_vote_test.tscn` | Yes | |

## Meta systems (§8)

| Mechanic | GUT | Click | Playtest | Notes |
|---|---|---|---|---|
| Win/loss stage rewards (`win_delta_*`/`loss_delta_*`, incl. null-safe reads) | `test_meta_rules.gd`, `test_game_state_meta_tracking.gd`, `test_level_runner.gd` | — | Yes, every stage | |
| Jiban ≤ 15 → Town Hall insertion | `test_meta_rules.gd`, `test_game_state_meta_tracking.gd` | — | Only if Jiban falls that low in a run | |
| Party support = 0 → Funding Freeze | `test_meta_rules.gd`, `test_game_state_meta_tracking.gd` | — | Rare in optimal play | `tools/stress_crisis_triggers.gd` exists for forcing this |
| Party support > 75 / < 50 → M09/M10 | `test_meta_rules.gd`, `test_ledger.gd` | — | Only if standing crosses those lines | |
| Party support < 25 → ST22 insertion | `test_meta_rules.gd`, `test_game_state_meta_tracking.gd` | — | Rare in optimal play | |
| Party favorability (Floor Vote) | `test_floor_vote_engine.gd`, `test_game_state_party_standing.gd` | — | Yes (Part A2) | |
| One-time levels (`Ledger.level_is_hidden()`) | `test_level_gating.gd` | — | Not exercised (playtest never re-visits a completed level) | |
| XP/level gating (`xp_to_unlock`, `level_gating_enabled`) | `test_level_gating.gd`, `test_ledger.gd` | `new_game_test.tscn` touches the gate indirectly | Yes | |
| Save / load, every field in `_SAVED_FIELDS` | `test_save_load.gd` | `inventory_test.tscn` does one round trip mid-run | — | |
| Level Intro screen | `test_level_intro_cues.gd` | `level_intro_test.tscn` | Not driven (playtest calls `BattleEngine` directly, never routes through `OfficeScreen._on_start()`'s scene change) | |

## Shop / Office Management

| Mechanic | GUT | Click | Playtest |
|---|---|---|---|
| Plain consumable purchase + default stack cap (2026-09-27) | `test_items.gd`, `test_inventory.gd` | `inventory_test.tscn`, `shop_items_test.tscn` (now run) | Yes |
| Level-buff consumable, used in Office/mid-stage | `test_battle_items.gd`, `test_inventory.gd` | `inventory_test.tscn` | Yes |
| Rhetoric Training: draw / pass / pass / must-learn (2026-09-27/28) | `test_inventory.gd` | `shop_items_test.tscn` (now run) | Not exercised — `playtest_optimal.gd` still uses the old `buy_card()`/`Ledger.card_refusal()` path, not Rhetoric Training |
| Random level unlock (SH13/14) | `test_inventory.gd` | `shop_items_test.tscn` | Yes |
| One-shot config bumps (SH18 recruitment tier, SH19 funds cap) | `test_inventory.gd`, `test_game_state_staff.gd` | `shop_items_test.tscn` | Yes |
| Staff hire/upgrade/fire | `test_game_state_staff.gd`, `test_ledger.gd` | `shop_items_test.tscn` (gate check) | Yes |
| Organisations / Backing (modifier purchase) | `test_modifier_effects.gd`, `test_ledger.gd` | — | Yes |

## Core battle rules (§7.1-7.2, §7.6)

| Mechanic | GUT | Notes |
|---|---|---|
| Affinity multiplier, self/opp deltas, rounding | `test_bar_model.gd`, `test_card_resolver.gd` | |
| Guard bank, both directions | `test_battle_engine.gd`, `test_bar_model.gd` | |
| Gaffe meter, pass penalty, decline-a-question cost | `test_battle_engine.gd`, `test_real_battle.gd` | |
| Intent patterns, per-opponent + default fallback | `test_intent_runner.gd`, `test_battle_engine.gd` | |
| Opponent Cues (spoken line vs. narration, no double-showing) | `test_opponent_cues.gd`, `test_battle_narration.gd` | The "shown twice" bug (2026-09-27) was a screen-wiring bug (`BattleScreen.gd`), not a rules gap — `BattleNarration.gd`'s own logic was already right |
| Questions pool, `asked_by` dynamic resolution, journalist-only rooms | `test_questions.gd`, `test_data_errors.gd` | The "MPs asked press questions" bug was workbook data, not code — see CLAUDE.md's 2026-09-27 fixes table |
| Titles / display names (null-safe, first-of-several) | `test_opponent_display.gd` | |

## Content-shaped bugs: a fifth category the matrix above can't show

Six of this session's nine playtest bugs were not gaps in any layer above
— the *rule* was right and had a GUT test; the *screen* worked and had
been click-tested. They only appeared with real data at real scale: a
20-question pool (vs. a 2-question test fixture), a title with two
clauses (vs. a one-clause test fixture), a phone-width screen (vs. no
interaction test checks pixel widths at all). No unit test or click test
is structurally able to catch this class — it needs either (a) real data
in the fixture (worth doing where cheap — `test_real_battle.gd` already
does this for some), or (b) a human looking at the real screen with the
real workbook. That's `design/PLAYTEST_CHECKLIST.md`'s whole job.

## Still open after this round (2026-09-28)

- No interaction test opens a committee specifically (ST01/09-18) — the
  Combat/single row's own `loop_test.tscn` plays "whichever level it
  picks first," which may or may not be a committee.
- `playtest_optimal.gd` still drives new-card purchases through the old
  `buy_card()`/`Ledger.card_refusal()` path, not Rhetoric Training's
  draw/pass/learn flow — real, but lower-stakes than the two closed above
  since Rhetoric Training already has both GUT and click coverage.
- Party support crossing 0/25/50/75 during a run isn't forced by anything
  in `verify.sh` — `tools/stress_crisis_triggers.gd` exists for this and
  is a manual/CI-optional run, same as `playtest_optimal.gd` itself.
