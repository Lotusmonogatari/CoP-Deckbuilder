# Audit summary: Coliseum of Parliament

Commit `b02bbab` and later, 2026-11-14. **Read-only audit:** no game code, asset or workbook was changed. All output is in `audit/`. Evidence: 80,150 seeded fights, 210 seeded 30-week runs, 4 unseeded full runs, 1,200-row mechanics inventory, edge-case probes, and the project's own tests (all passing). Bots are not people: treat balance numbers as relative.

## Verdict

The rules engine is sound and fast. In 80,150 simulated fights there were **zero invariant violations** and a card play costs 0.04 ms. The risks are elsewhere: **design values are held outside the workbook**, the **weekly party dues do not constrain play**, several **economy meters saturate**, the **combat game is easy for a competent player**, and **nothing has ever run on a phone**, so every technical budget is unproven.

## Benchmark scorecard

(Corrects the 7 / 4 count in my Phase 5 message: the correct balance tally is 8 / 10 / 3.)

| Area | Pass | Fail | Reported or not measurable |
|---|---|---|---|
| Balance (21) | 8 | 10 | 3 |
| Technical (17) | 9 | 5 | 3 |
| Invariants (29) | 22 | 4 | 3 not tested |

Details: `audit/testing.md`.

## Top 10 findings

| # | Finding | Severity | Where |
|---|---|---|---|
| 1 | 976 design values sit in hand-written JSON outside the workbook; more are numbers typed in scripts; 83 code fallbacks disagree with the data (INV-29) | High | `conformance.md` F-01, F-02, F-23 |
| 2 | Party dues can be ignored: 24 to 26 of 30 weeks unpaid, 1.4M to 1.8M owed, Party support still 90 | High | F-03 |
| 3 | Data load 0.67 to 0.82 s and redraw after a turn 71 to 86 ms on desktop, 10x and 3x the October baseline; never measured on a phone | High | F-18, F-19 |
| 4 | A blank threshold in a non-committee room makes a fight that never ends; blank numbers crash with `int(null)` | High (data-entry risk) | `edge_cases.md` E-01, E-02 |
| 5 | Reading one newer-version save switches saving off for the session; no mid-stage save; a loaded save is not validated | Medium | E-03 to E-06 |
| 6 | Party support at 100 for 62% of level-ends; awareness saturates; Reputation's reward is out of reach | Medium | F-04, F-12, F-13 |
| 7 | Harder levels pay less per hour than easier ones | Medium | F-05 |
| 8 | 37 rooms won over 95% on the opening deck; 10 rooms under 50% with my full kit (Media Ambush, caucuses) | Medium | F-08 to F-10 |
| 9 | Card power uneven: suits 1.84x, 3 cards over-played, 9 never played, 4 discard-card outliers | Medium | F-06, F-07 |
| 10 | The project's own rubric tool dropped from 66 to 61 of 66; party-tier law lean is documented only in a code comment | Medium | F-15 |

## What I could not verify

| Item | Why |
|---|---|
| Frame time, memory, load time, thermal and touch on a phone | No device and no export setup; every technical number is a desktop proxy |
| Download size against store limits | No export; `assets/` is 275 MB uncompressed |
| Real app suspend and resume, OS kill | Needs a mobile OS; I only sent the pause notification by hand |
| Human balance and feel | Bots only; my full kit has no items and uses my own deck heuristic, so the ten "too hard" rooms need a human check |
| Reproducing a whole stage from a seed | Who is seated cannot be seeded |
| Information standards, audio, art | Out of scope or nonexistent |
| Malformed workbook rows through the real exporter | I did not edit the workbook; I read the exporter's checks instead |
| Whether a reloaded stage keeps its seating | Not tested |

## Where to start

1. `audit/conformance.md`: all 27 findings with sources.
2. `audit/roadmap.md`: the ordered patch plan (workbook, code, assets).
3. `audit/improvements.md`: separate proposals, not bug fixes.

Files: `phase0_orientation.md`, `benchmarks.md` (frozen), `mechanics.md` and `.csv`, `dynamics.md`, `testing.md`, `conformance.md`, `edge_cases.md`, `roadmap.md`, `improvements.md`, and `tests/` (harness, probes, raw results, `analyze.py`).
