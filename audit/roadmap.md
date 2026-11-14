# Phase 7: Roadmap

A prioritized patch plan. Nothing here has been done. Effort: **S** under a day, **M** a few days, **L** a week or more. Order is severity, then dependency. "Benchmark moved" uses the IDs in `audit/benchmarks.md`. Each item cites the finding it answers (`F-` in `audit/conformance.md`, `E-` in `audit/edge_cases.md`).

## Workbook (data and schema)

| # | Problem | Fix | Sheets touched | Depends on | Effort | Risk | Benchmark moved |
|---|---|---|---|---|---|---|---|
| W-1 | F-01: design values live in hand-written JSON | Add workbook tabs **Rules** (key, value, options, meaning), **Standing Rules** (the `booster_standing` values and bands) and **Party Standing**; make the exporter write `rules.json`, `booster_standing.json`, `party_standing.json` from them and drop them from the hand-written list. Keep `level_visitor_overrides`, `level_opponent_overrides` and `staff_names` as workbook tabs too | 3 new tabs; exporter `SHEETS` entries | none (schema change: needs Cameron's approval) | M | Low: values are copied, a test compares old and new JSON | INV-29 |
| W-2 | F-03: dues can be ignored | Re-tune: raise the overdue penalty, or make unpaid dues block something concrete (a level, a backing). A design decision first | Balance `dues_overdue_*`, `dues_holiday_weeks` | W-1 not needed | S for numbers, M for a new block | Medium: changes the whole economy; re-run `audit/tests/run_strategy.sh` | BAL-12, BAL-16, BAL-17 |
| W-3 | F-04, F-12, F-13: Party support, awareness saturate; Reputation unreachable | Re-tune decay, gain and caps (Balance, Sanban, Awareness Effects) | Balance, Sanban, Awareness Effects | W-2 first | M | Medium | BAL-12 |
| W-4 | F-05: harder levels pay less per hour | Raise Win delta and bonus ranges on the low-clear levels, or lower on the easy | Levels, Stages | none | M | Low | BAL-14 |
| W-5 | F-06, F-07, F-09: card power spread, over- and under-played cards | Re-tune the outlier discard cards C63, C65, C67, C69; give Appeal and Earnest more per energy; decide C01 and the nine unplayed cards | Cards | none | M | Medium: re-run the sweeps | BAL-08, BAL-10 |
| W-6 | F-08, F-10: 37 rooms too easy, ten too hard for my full kit | Raise thresholds or opponent starts in the 15 rooms at 100%; check Media Ambush and the caucus rooms with items and a human | Stages, Affinity | none | M | Medium | BAL-01, BAL-02, BAL-03 |
| W-7 | F-21: columns nothing reads | Decide per column: wire it up (`patron_bills` lines, `shop.bonus_condition_*`) or remove; Cameron approves any removal | Patron Bills, Shop, Stages, Sanban | none | S | Low | INV-29 |
| W-8 | F-14: election strength fires nothing | Cameron decides what it unlocks, then add rows | new tab or Balance | decision | M | Medium | none |
| W-9 | E-01, E-02: blank cells that loop or crash | Exporter: error on a blank threshold, start or bar size in non-committee Combat rooms; error on a blank card cost | `tools/export_data.py` (validation only) | none | S | Low | INV-12 |
| W-10 | Import pipeline validation | Add a CI step that runs `export_data.py`, the formula check and `tools/verify.sh` on every push; fail if `data/*.json` differs from a fresh export | `tools/verify.sh`, CI config | none | S | Low | INV-29 |

## Code

| # | Problem | Fix | Files | Depends on | Effort | Risk | Benchmark moved |
|---|---|---|---|---|---|---|---|
| C-1 | E-03: a newer save disables saving | Do not touch `enabled` on a read; only on the main slot, and show a message | `scripts/autoload/SaveManager.gd:222-225` | none | S | Low | INV-24 |
| C-2 | E-05, E-06: loaded values not validated | After `load_save`, clamp meta, standing and awareness, floor the clock at 0, refill a short deck | `scripts/autoload/GameState.gd:571-596` | none | S | Low | INV-24, INV-28 |
| C-3 | E-04: no mid-stage save | Save the engine's checkpoint at each turn end, or save the seed and replay | `GameState`, `BattleScreen`, `SaveManager` | C-2 | M | Medium | INV-24 |
| C-4 | E-01: unending stage | `BattleEngine.setup` refuses a null threshold; also enforce the turn limit when no end condition exists | `scripts/rules/BattleEngine.gd:296-310`, `:865-1063` | W-9 | S | Low | INV-12 |
| C-5 | E-02: `int(null)` | Replace with `SafeNum` reads | `BattleEngine.gd:151,174,1123`, `BattleSetup.gd:611` | none | S | Low | INV-28 |
| C-6 | F-02, F-23, E-07: numbers in scripts and wrong fallbacks | Move `BillPositions`, `SpecialEffects`, `ElectionStrength`, `Ledger` severance, `DraftBill` constants to Balance rows; delete the 83 fallbacks that disagree; add a test that fails when a `.get("key", N)` fallback exists | many; see `audit/mechanics.md` section 4.1 | W-1 | L | Medium: touches the rules | INV-29 |
| C-7 | F-16: rules calling autoloads | Pass `DataDB` rows and `Text` into `PatronVisit` as arguments; add a purity test over `scripts/rules/` | `scripts/rules/PatronVisit.gd`, a new test | none | S | Low | INV-27 |
| C-8 | F-17: seating cannot be seeded | Give `BattleSetup` an optional seed and store it in the level snapshot | `scripts/BattleSetup.gd:352-355`, `LevelRunner` | none | M | Low | INV-26 |
| C-9 | F-18: load and redraw cost | Profile `DataDB.load_all` (0.67 to 0.82 s) and `BattleScreen` refresh after a turn (71 to 86 ms): cache parsed JSON, load tabs lazily, avoid rebuilding unchanged rows | `scripts/autoload/DataDB.gd`, `scripts/ui/BattleScreen.gd` | measure on a phone first (M6) | M | Medium | TEC-03, TEC-06 |
| C-10 | F-25: per-frame work | Stop `PlaceholderArt._process` when Image Pan is off or the picture is not a background; stop `OfficeScreen` ticker when hidden | `scripts/ui/PlaceholderArt.gd:300`, `OfficeScreen.gd:280` | none | S | Low | TEC-14 |
| C-11 | F-26: texture growth | Re-check after the art is drawn; add a cache cap | `scripts/ui/ArtLoader.gd` | art | S | Low | TEC-11 |
| C-12 | F-15: undocumented party-tier law lean; stale rubric tool | Document it in `design/GAME_SYSTEMS.md`; update `tools/rubric_playtest.gd` D1/D3 to expect it (or decide it is a bug) | `design/GAME_SYSTEMS.md`, `tools/rubric_playtest.gd` | decision | S | Low | INV-25 |

## Source assets

| # | Problem | Fix | Effort | Risk |
|---|---|---|---|---|
| A-1 | `assets/` is 275 MB of lossless PNG against about 200 MB store limit (finding S-03 in `audit/06-ship-readiness.md`) | Convert backgrounds to WebP or compressed textures; keep character art at the sizes shown | M | Low |
| A-2 | No app icon, splash or export setup | Make the icon, splash and export presets (milestone M6) | M | Low |
| A-3 | Audio does not exist | Commission or record the sounds (already planned in `design/proposals/AUDIO_PLAN_2026-10-26.md`) | L | Low |
| A-4 | Most character art undrawn; texture memory will grow | Draw art; re-run `audit/tests/tech_probe.tscn` | L | Low |

## Order of work

1. W-9, C-4, C-5, C-1, C-2 (small, protect against crashes and lost saves).
2. W-1 and C-6 (the workbook-first requirement), with W-10.
3. W-2, W-3, W-4 (economy), then W-5, W-6 (cards and rooms), re-running the harness after each.
4. C-3, C-8, C-9, C-10 (persistence and speed), with the M6 phone build.
5. Assets A-1 to A-4 in parallel.
