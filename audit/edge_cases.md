# Phase 6: Edge cases and failure states

Run with `audit/tests/edge_probe.gd` (one case per process, so one script error cannot hide another) through `audit/tests/run_edge.sh`; raw output in `audit/tests/results/edge_cases.json`. Each case is **Verified** unless marked. Risk is the risk of the proposed patch, not of the bug. A patch here is a proposal only: nothing in the game was changed.

## Summary

| Result | Count |
|---|---|
| Handled cleanly (no change needed) | 13 |
| Real defect reproduced | 7 |
| Behavior worth a decision | 4 |
| Not testable here | 4 |

## 1. Defects reproduced

| ID | Case and how to reproduce | What happens | Cause | Proposed patch | Patch risk |
|---|---|---|---|---|---|
| E-01 | **A non-committee combat room with a blank win threshold, start or bar size.** `AUDIT_CASE=stage_null_field`: set `win_threshold`, `player_start`, `opp_start` or `bar_max` to null on ST02 (Floor Debate) | The fight **never ends**: after 60 turns and 104 card plays the outcome is still "ongoing", even though the turn limit is 10. The player can only Abandon | The exporter only **warns** for these four columns (`tools/export_data.py:2393-2398`) because committees leave them blank on purpose (resolved at setup). Nothing resolves them for other room types, and the engine's fallback (`BattleEngine.gd:301`, 51) does not restore the end check | Make the exporter an **error** for any Combat room whose bar model is not a committee-style room and whose four columns are blank; and have `BattleEngine.setup` refuse (`setup_problems`) a stage whose threshold resolves to null | Low (data check) / Low |
| E-02 | **Blank energy, hand size, gaffe limit, turn limit or card cost in a workbook row.** `stage_null_field`, `card_null_number` | `int(null)` is a script error ("Nonexistent 'int' constructor") at `BattleEngine.gd:151`, `:174`, `BattleSetup.gd:611`, `BattleEngine.gd:1123`. Setup is refused for energy, hand and gaffe limit; a null card cost errors on every cost lookup and the fight continues with a wrong cost | Direct `int(x)` on a value that can be `null` | The exporter already **errors** for blank turn limit, energy, hand size and gaffe limit on Combat rooms (`export_data.py:2389-2391`) and cards need a cost column check added; in code, read with a null-safe helper (`SafeNum` exists in `scripts/rules/SafeNum.gd`) | Low |
| E-03 | **Reading one save from a newer build switches saving off for the whole session.** `AUDIT_CASE=save_newer_version` | `SaveManager.enabled` goes true to false after `read_save` of a version-99 file (`SaveManager.gd:222-225`), so every later autosave is silently skipped, even for the player's own current run | `enabled = false` is a global side effect of reading any path, including the manual backup or an undo file | Return the "newer" problem without touching `enabled`; set it only when the main slot is the newer one, and tell the player | Low |
| E-04 | **Saving never happens during a stage, so a suspend or kill loses the bout.** `suspend_mid_stage` | The pause notification between stages writes a save; during a stage it writes nothing (`SaveManager.gd:85-88`, `mid_stage` guard). The only mid-stage save is the checkpoint at a defeated opponent | A design choice (`design/GAME_SYSTEMS.md:56`, `:323`), but on a phone the OS can kill the app at any switch away | Save the engine's own state at each turn end (the engine already exposes `checkpoint()`, `BattleEngine.gd:1447`), or at least the stage and seed so the bout can be replayed | Medium: restoring mid-stage state needs a test per bar model |
| E-05 | **A loaded save is not fully validated.** `save_wrong_types`, `save_bad_deck` | A string stored as an organization's standing loads as the string `"high"`; a negative hidden clock (−5) loads; a deck containing an unknown card id is cut to the cards that exist, leaving a deck of **1 card** (fights then start with a one-card deck) | `GameState.load_save` (`GameState.gd:571-596`) checks the type of each top-level field and the keys of a few dictionaries, not the values inside them or the deck size | After loading: clamp meta and standing to their ranges, force the clock to ≥ 0, and if the deck is not the required size, refill it from owned cards (`GameState.set_deck` already validates) | Low |
| E-06 | **A value above its ceiling is never pulled back.** `funds_over_cap` | Funds set to 5,000,000 stay at 5,000,000 when 1 is added (the hard ceiling is 1,000,000). Only reachable through a hand-edited or corrupted save | `MetaRules.clamp_meta` limits the result of a change but does not lower an out-of-range starting value | Clamp every meta value after load (same patch as E-05) | Low |
| E-07 | **A missing Balance lever falls back to a number typed in code, with no warning.** `lever_missing` | Removing `dues_base` still gives 50,000 | `PartyDues.settings` reads `balance.get("dues_base", 50000)` (`scripts/rules/PartyDues.gd:16`) | Same fix as audit finding M-12: remove the fallback numbers and let `tests/test_balance_keys.gd` fail the build | Low |

## 2. Behavior that is correct but worth a decision

| ID | Case | What happens | Note |
|---|---|---|---|
| E-08 | `zero_cost_card_loop` | C07 costs 0 and was played 52 times in one turn, ending only because the stage ended. There is no plays-per-turn cap | A cost-0 card can be chained as long as the hand and deck allow. Only one card has cost 0 today (C07). A design statement on whether chaining is intended would close it |
| E-09 | `draw_loop` | With draw-1 cards at cost 1 and 3 energy: 3 plays in a turn | Draw cards cannot chain for free: pass |
| E-10 | `deck_one_card` | A one-card deck plays on: the card recycles and the fight runs 4 turns | Not a bug; combines with E-05 |
| E-11 | `turn_limit_zero` | A stage with no turn limit and a player who only passes ends in a loss after 31 turns through the gaffe or support rules | Ends, so no softlock; the exporter forbids a blank turn limit anyway |

## 3. Handled cleanly

| Case | Result |
|---|---|
| Empty deck | `setup` refuses with "the player has no deck" |
| Unknown card in the deck | `setup` refuses and names the card |
| Hand size 0, energy 0 | The fight ends in a loss by the stage's own rules (6 and 10 turns) |
| Meta overflow (+1e12, −1e12, +INT_MAX) | Clamped to 0 to 100 and to the Funds cap |
| Simultaneous crisis triggers (Constituency support 10, Party support 0) | Town Hall and Steering Committee are both armed once; a second check adds nothing |
| Corrupt save with a good backup | Loads the backup |
| Corrupt save with no backup, truncated save | Refuses cleanly (`unreadable`), GameState untouched |
| Level with no stages or an unknown stage | `LevelRunner` reports "the level has no stages" |
| Office Hours with no visitors or an unknown visitor | `setup` refuses with the reason |
| Whip below the floor (Party support 20 or 30, floor 30) | 0 whips; at 45, 1 whip |
| Save and load of every saved field on a fresh run | No field changed (Phase 4) |
| Draw loops | Bounded by energy (E-09) |
| Rules cost | Negligible (Phase 4) |

## 4. Not testable with these tools

| Case | Why |
|---|---|
| Real app suspend and resume, low memory, OS kill | Needs a device. I sent the pause notification by hand (E-04) |
| Interruption of a click or drag mid-action, simultaneous touches | Needs UI-driven input; the project's click tests cover the main screens |
| A save written by an older build | No older save file available |
| Malformed workbook rows through the real exporter | I did not edit the workbook (audit rule). The exporter's own checks were read instead (E-01, E-02) |
