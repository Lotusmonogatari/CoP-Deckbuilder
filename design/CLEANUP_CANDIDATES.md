# Cleanup candidates (noted 2026-10-28, nothing deleted)

Cameron's call: **do not delete or remove any of these now.** This is a list for a future cleanup pass; each item needs a fresh check and his approval before it goes.

## Unused code

| Item | Where | Why it is a candidate |
|---|---|---|
| `StageBrief.how_this_room_works()` | `scripts/ui/StageBrief.gd` | Removed 2026-10-28 (the only public function found with no caller anywhere in scripts, tests or tools). Listed so the pass knows the scan has been done. |

## Tool scripts with few or no references

| Item | References found | Note |
|---|---|---|
| `tools/build_floor_vote_scene.gd` | 0 | Scene builder; check it is not the only way to rebuild FloorVoteScreen before removing. |
| `tools/art_prompt.py`, `tools/content_lint.py` | 1 each | Single mention; may be run by hand. |
| `tools/build_intro_scene.gd`, `build_stage_transition_scene.gd`, `build_theme.gd` | 1 each | Builders; CLAUDE.md section 13 says which are safe to rerun. |
| `tools/bench.sh`, `measure_plays.sh`, `build_level_intro_scene.gd` | 2 each | Likely still used by notes. |

The stress, benchmark and playtest scripts (`stress*.sh/.gd`, `benchmark.gd`, `rubric_playtest.gd`, `playtest_optimal.gd`, `balance_audit.*`) are referenced from the change log and each other, so they are not candidates.

## Text-tab rows nothing asks for (exporter notes: "nothing asks for ... yet")

| Rows | Why |
|---|---|
| `card.room_enhanced`, `card.room_greatly_enhanced`, `card.room_greatly_suppressed`, `card.room_neutral`, `card.room_suppressed` | Orphaned 2026-10-28 when the card back dropped the room's suit match line. |
| `card.question_strong`, `card.question_weak`, `card.question_medium` | Orphaned the same day (the question's effect line). |
| `election.c_district`, `election.c_national`, `election.component_line`, `election.inputs_heading`, `election.meter_line`, `election.potential_line`, `election.record_heading` | Not checked. Confirm they are not built up dynamically before removing. |
| `office.trigger.*` (backing_lapsed, funding_freeze, gaffe_penalty, steering_committee, town_hall; entered / left) | Not checked; the trigger alerts may build these keys dynamically. |
| `record.cause_gaffe_awareness` | Not checked. |

`tools/workbook/wbx.py` has no delete-row helper today, so removing Text rows would need one first.

## Tests

No test was found that covers a removed feature. The two click tests that `verify.sh` never ran (`intro_test`, `mash_test`) now run and pass, so they are not candidates either.

## Added 2026-10-30 (playtest fixes)
- Text rows no longer asked for: `briefing.against_one`, `briefing.against_many`, `briefing.reporters_ask` (the briefing no longer names opponents) and `dues.preview`, `dues.preview_owed` (the Friday dues line is gone; the Party Dues box shows it).
- Balance lever "Starting Training Session Coupons" (now 0): replaced by the Player tab's Starting Items; no longer read by the code (2026-10-31).
- Text rows no longer asked for after the briefing template (2026-10-30): `briefing.loss_ends_level`, `reward.if_lost` (the briefing no longer lists loss costs, carry-over lines, bill sides or "standing with whichever organizations"). `CarryOverLines.gd` and `StanceLines.briefing_lines()/briefing_sides()` may now be unused by the briefing; check other callers before removing.
