# Phase 5: Design conformance audit

Each row compares one stated design outcome or expectation with what the code and the simulations do. Evidence labels: **V** Verified (ran it), **I** Inferred (read from code or data), **A** Assumed. Status: **meets**, **deviates**, **missing** (stated but not built or not enforced), **undocumented** (behavior with no stated design), **not verified**. Severity is for a pre-shipment mobile game: Blocker, High, Medium, Low, or n/a where the row meets.

Numbers come from `audit/testing.md`; mechanics references from `audit/mechanics.md` and `audit/dynamics.md`.

## 1. Findings that need a decision (deviates, missing, undocumented)

| ID | Expectation | Source | Actual behavior | Evidence | Status | Severity |
|---|---|---|---|---|---|---|
| F-01 | Values are pulled from the workbook; data is held behind code only in rare exceptions | Cameron, 2026-11-14; `CLAUDE.md` section 3 "Data-driven" | 976 values sit in 10 hand-written JSON files the exporter never writes, including every organization-standing rule (`booster_standing.json`) and 21 rule switches (`rules.json`: guard cap, pass penalty, Funds cap, intent defaults). They cannot be tuned from the workbook | `tools/export_data.py:4333`; `audit/mechanics.md` M-01 to M-04 (V) | **deviates** | **High** |
| F-02 | "No design number lives in a script" | `CLAUDE.md` section 6 | Party positions for sponsored and drafted bills are computed from seven typed constants; card special effects use typed thresholds (Reputation 60, share 0.5, step 0.2); election strength a typed 0.5; severance a typed 10%; 77 UI constants hold timing and feel numbers | `scripts/rules/BillPositions.gd:78-96`; `scripts/rules/SpecialEffects.gd:108`, `:114`, `:170`; `scripts/rules/ElectionStrength.gd:49`; `scripts/rules/Ledger.gd:337`; `audit/mechanics.md` M-05 to M-11 (I, count V) | **deviates** | **Medium** |
| F-03 | Party dues are a weekly cost; a short week costs Party support, backings and standing | `design/GAME_SYSTEMS.md:164`, `:170` | The penalty does not bind. The baseline bot skipped dues in 24 to 26 of 30 weeks, owed 1.41M to 1.76M, and still held Party support at 90 at 86% of week ends and reached election strength 69 to 74. Paying dues is optional in practice | 12 seeded runs, `strategy_protagonists.jsonl` (V) | **deviates** | **High** |
| F-04 | "No meta value at its ceiling for more than half of a full run" | `design/BALANCE_AUDIT_PROCESS.md:50` | Party support is at 100 for 62% of level-ends (76%, 78%, 62%, 33% by run) and reaches 90 by week 2 to 10 | BAL-12 (V) | **deviates** | **Medium** |
| F-05 | "Harder rooms pay at least as much as easier ones" | `design/BALANCE_AUDIT_PROCESS.md:49` | The hardest third of levels pays 10,625 Funds and 25.0 XP an hour; the easiest third 12,667 and 30.0 | BAL-14 (V, static rewards against measured clear chance) | **deviates** | **Medium** |
| F-06 | "No card played more than three times the average; no card never played" | `design/BALANCE_AUDIT_PROCESS.md:51` | C14 4.3x, C38 3.9x, C09 3.0x; nine cards never played by the bot | BAL-08, 90,302 plays (V) | **deviates** | **Medium** |
| F-07 | "a mix of suits at every tier so no approach dominates by weight of numbers" | `design/GAME_DESIGN.md:35`; `tools/balance_audit.py:33` | Printed power per energy runs from Appeal 2.24 to Duplicitous 4.13 (1.84x, limit 1.35); tier power is not monotonic (2.92 / 4.44 / 3.10 / 2.97); four discard cards are outliers; C01 is dominated by C25. In play the suits stay inside 8% to 28% and no single-suit strategy leads | BAL-09, BAL-10, BAL-16 (V) | **deviates** on printed power; **meets** in play | **Medium** |
| F-08 | A first-time player should face a real challenge (win rate under 95%) | `tools/balance_audit.py:25` | 37 of 229 rooms are won over 95% of the time on the opening deck by a simple greedy bot; 15 at 100% | BAL-01, n = 100 per room (V) | **deviates** | **Medium** |
| F-09 | "Every family has a visible kit gain (starter to full at least 10 points)" | `design/BALANCE_AUDIT_PROCESS.md:48` | 10 of 22 families gain under 10 points; six because the starter kit already wins 92% to 100%. Media Ambush is worse with the full kit in my harness (−26.5 points) | BAL-03 (V; the Media Ambush result depends on my deck heuristic and no items) | **deviates** | **Medium**; the Media Ambush part is **not verified** as a game fault |
| F-10 | A late, well-kitted player wins at least half the time in every room | `tools/balance_audit.py:26` | 10 rooms under 50% with my full kit: two Media Ambush rooms (0%, 2%), one caucus at 0% (ST212), Candidate Selection Committee 34%, six caucus rooms 38% to 46% | BAL-02, n = 50 per room (V) | **deviates**, with the same caveat as F-09 | **Medium** |
| F-11 | The dominant-strategy ceiling (proposed: best ≤ 1.25x median) | `audit/benchmarks.md` BAL-16; `design/GAME_DESIGN.md:35` | Best 1.70x the median. Every top-five strategy buys the Funds cap petition and pays dues. Because not paying dues costs little (F-03), the gap comes from the Funds cap, not from play | 180 runs, 60 strategies (V) | **deviates** (proposed benchmark) | **Medium** |
| F-12 | Reputation at 80 or more starts a press-style room 5 ahead | `design/GAME_SYSTEMS.md:99` | Reputation ended 30-week runs at 11 to 44. Weekly decay of 6% x 2.5 outruns what the bot earns, so the reward is out of reach | `strategy_protagonists.jsonl` (V) | **deviates** in effect | **Medium** |
| F-13 | Leftover gaffes erode awareness | `design/GAME_SYSTEMS.md:113` | National awareness reached 100 by week 9 to 15 and District by week 18 to 24 with 1,131 leftover gaffes in a run. The erosion is invisible next to the gains | baseline runs (V) | **deviates** in effect | **Low** |
| F-14 | Election strength should lead somewhere | `design/GAME_SYSTEMS.md:58`, `:114`; `CLAUDE.md` section 9 | Built and shown; fires nothing. It rises at its speed cap whatever the player does (69 to 74 at week 30) | `scripts/rules/ElectionStrength.gd`; runs (V) | **missing** (stated as open) | **Medium** |
| F-15 | Law effects: "exactly the organisations, meta values and XP in that bill's Once row change, nothing else" | `design/PLAYTEST_RUBRIC.md` line D1 | Party-body organizations also move by a lean adjustment (`law_lean_party_tier_pass_delta` 3, `fail_delta` 1, scaled by salience and each body's multiplier). The project's own rubric tool now fails D1 and D3 and scores 61 of 66 (66 of 66 in October). The adjustment is described only in a code comment | `scripts/autoload/GameState.gd:4203-4229`; rubric run today (V) | **undocumented** behavior; stale rubric tool | **Medium** |
| F-16 | `scripts/rules/` uses no UI, no autoloads and no files ("tests prove it") | `CLAUDE.md` section 5 | `scripts/rules/PatronVisit.gd` calls `DataDB` three times and `Text` 11 times. I found no test that proves the claim | `grep`; lines 23, 26, 94 (V) | **deviates** | **Low** |
| F-17 | Seeded replay (proposed INV-26) | `audit/benchmarks.md` | The engine is deterministic under a seed. Who is seated is drawn with `randomize()` and cannot be seeded; the opening deck is dealt unseeded in the game; the save stores no seed | `scripts/BattleSetup.gd:352-355`; `scripts/autoload/GameState.gd:773`; harness 14 of 14 (V) | **undocumented** (no design statement either way) | **Low** for players; **Medium** for testing and bug reports |
| F-18 | Technical budgets | none stated | No document gives a frame, memory, load or size budget. Against my proposed ones: data load 0.67 to 0.82 s (10x the October baseline); redraw after a turn 71 to 86 ms (3x the baseline); redraw spikes of 53 to 56 ms after a card | `bench_headless.json` (V, desktop proxy) | **missing** (no stated budget); proposed budgets **deviate** | **High** until measured on a phone |
| F-19 | The game ships on phones: 60 fps, fits in memory, loads quickly | `CLAUDE.md` sections 3 and 11 | Never run on a device; no export preset exists | `audit/phase0_orientation.md` section 3 (V) | **not verified** | **Blocker** for shipment (already known as M6) |
| F-20 | The design documents describe the game as it is | `design/GAME_SYSTEMS.md:3` | Counts are stale in two documents: `CLAUDE.md` section 6 says 113 levels, 288 stages, 166 visitors, 56 events, 34 shop items, about 916 Text rows; the data has 114, 289, 167, 87, 35 and 988. `GAME_DESIGN.md:3` says 101 levels and 273 stages. `GAME_DESIGN.md:158` says a stage is never saved mid-fight, against the checkpoint in `GAME_SYSTEMS.md:323`. `GAME_DESIGN.md:43` calls the TV debate a single meter, against `GAME_SYSTEMS.md:192`. `PLAYTEST_RUBRIC.md` line B5 says a weak answer costs 1; the game and `GAME_SYSTEMS.md:110` say 3 | cited lines; `data/*.json` row counts (V) | **deviates** | **Low** |
| F-21 | Workbook columns do something | `CLAUDE.md` section 6 ("The workbook's structured columns are the truth") | Filled columns no script reads: `stages.win_pct`, `bar_value_kind`, `segment_check`; `shop.bonus_condition_1/2`; `patron_bills.request_line`, `accept_line`, `decline_line`; `sanban.low_consequence`; Balance `xp_tiers`; several reference columns | `audit/mechanics.md` M-13 to M-19 (V by `grep`) | **missing** readers | **Low**; `patron_bills` lines are written content that never shows (**Medium** if Cameron expects to see them) |
| F-22 | Audience segment favorability | `design/GAME_SYSTEMS.md:112` | Saved in every save file; read by nothing | same line (I) | **missing** | **Low** |
| F-23 | Code fallbacks match the workbook | implied by `tests/test_balance_keys.gd:1-5` | 83 `balance.get("key", N)` fallbacks differ from the data (for example decay multiplier 1.0 against 2.5). Harmless today; wrong the day a lever is renamed | `audit/mechanics.md` M-12 (V) | **deviates** | **Low** |
| F-24 | Turns per encounter (proposed 40% to 85% of the limit) | `audit/benchmarks.md` BAL-06 | Median 55%, but 39 rooms are won in under 40% of their limit (Lobbyist Meetings in about 21%) and 40 need over 85% | BAL-06 (V) | **deviates** (proposed benchmark) | **Low** |
| F-25 | Per-frame work should be event-driven (proposed) | `audit/benchmarks.md` TEC-14 | Three `_process` functions run every frame on idle screens; the background polls the tilt sensors each frame while Image Pan is on | `tech_probe.json`; `scripts/ui/PlaceholderArt.gd:300` (V) | **deviates** (proposed) | **Low** (battery on phones: not measured) |
| F-26 | Memory stays flat over repeated stages (proposed) | `audit/benchmarks.md` TEC-11 | Objects +2.1% and textures +18% over 40 stage loads; no orphan nodes | `tech_probe.json` (V) | **deviates** marginally | **Low**, to re-check when the art is drawn |
| F-27 | A benchmark I froze is poorly framed | `audit/benchmarks.md` BAL-07 | "No single loss cause above 80%" fails in 14 families, but a caucus or committee has only one practical way to be lost (time), and my greedy policy never loses to gaffes. The result says more about the benchmark than the game | BAL-07 (V) | benchmark issue, recorded as frozen | n/a |

## 2. Expectations that are met

| Expectation | Source | Evidence | Status |
|---|---|---|---|
| 101 seats, 51 to pass, abstentions count against, supermajority 67% | `CLAUDE.md` section 4; `design/GAME_SYSTEMS.md:202` | Rubric C1, C1b: 600 votes (V) | meets |
| No early elections, recall or snap-election mechanics | `CLAUDE.md` section 4 | No such mechanic in the inventory (`audit/mechanics.md`) (I) | meets |
| Gaffe meter checked first; threshold ends the stage at once | `design/GAME_SYSTEMS.md:186` | 25 of 25 and 521 of 521 (V) | meets |
| Guard stacks to 5 and carries; energy never carried | `design/GAME_SYSTEMS.md:188`; `design/GAME_DESIGN.md:25` | 0 violations in 80,150 fights (V) | meets |
| Guard, draw and gaffe numbers are never multiplied | `design/GAME_SYSTEMS.md:188` | 29,541 comparisons (V) | meets |
| Conversion costs 1; then 1 / 2 / 3 at 60 / 30 / 10% | `design/GAME_SYSTEMS.md:190` | 58.9 / 31.0 / 10.1% over 10,000 rolls (V) | meets |
| Opening deck: 15 cards, suits within one, at most half gaffe cards, 25% chance of one tier-3 | `design/GAME_SYSTEMS.md:69` | 2,000 decks, 25.4% (V) | meets |
| Survival line rises 0 to 3 a turn | `design/GAME_SYSTEMS.md:192` | 500 turn ends (V) | meets |
| Political Pressure changes opponents, gaffe limit and rewards, never energy, hand size or turn limits | `design/GAME_SYSTEMS.md:196` | All rooms compared; win rates 84.6 / 76.8 / 66.3% (V) | meets |
| Every stage ends in a win or a loss within its limit | `design/GAME_SYSTEMS.md:194` | 80,150 fights (V) | meets |
| Meta numbers stay in range; Funds never exceed the cap | `design/GAME_SYSTEMS.md:98-101` | 210 runs (V) | meets |
| Election strength moves at most +2.5 / −1.5 a week | `design/GAME_SYSTEMS.md:114` | 6,120 week steps (V) | meets |
| Dues formula; decay percentages; draft costs; whip costs | `design/GAME_SYSTEMS.md:147`, `:164`, `:167`, `:203` | Values in `data/balance.json` and `data/sanban.json` match the text (I); project tests pass (V) | meets |
| Influence gate is an AND; flips conserve seats; resistance respected | `design/GAME_SYSTEMS.md:203` | Rubric C2, C3, C4, C5 (V) | meets |
| A full-strength player flips 10% to 60% of votes | `tools/balance_audit.py:34` | 55% to 60% (V) | meets (at the upper edge) |
| Recording a bill twice changes nothing; "each level" laws pay on schedule; laws survive save and reload | `design/PLAYTEST_RUBRIC.md` D2, D4, D5 | Rubric run (V) | meets |
| Save and load return every saved field | `design/GAME_SYSTEMS.md:212` | 81 fields, fresh run (V) | meets (fresh run only) |
| Card choice matters | `design/GAME_DESIGN.md:25` | Random 6.8% against greedy 78.7% (V) | meets |
| No room a first-time player can never win | `design/BALANCE_AUDIT_PROCESS.md:47` | Lowest starter room rates are above 15% (V) | meets |
| Suit share of plays 8% to 28% | `design/BALANCE_AUDIT_PROCESS.md:52` | 9.7% to 27.7% (V) | meets |
| No organization permanently maxed or unreachable | `design/BALANCE_AUDIT_PROCESS.md:50` | Highest 48% of level-ends at 100 (V, 4 runs) | meets |
| Reward per hour rises with tier | `audit/benchmarks.md` BAL-15 | 8,000 / 10,491 / 12,857 Funds an hour (V) | meets (the earlier audit's B-08 is resolved) |
| Every lever the code reads exists in the workbook | `tests/test_balance_keys.gd` | 0 missing keys (V) | meets |
| Rules cost per turn is negligible | `audit/benchmarks.md` TEC-04, TEC-05 | 0.04 ms per card (V) | meets |
| Draw calls and node counts are light | `audit/benchmarks.md` TEC-12, TEC-13 | 69 and 38 draw calls; 183 nodes (V) | meets |

## 3. Stated expectations I could not verify

| Expectation | Source | Why |
|---|---|---|
| Saving on every button press, on backgrounding, and of a result shown on screen | `design/GAME_SYSTEMS.md:56`, `:323` | Needs UI-driven tests and a real suspend; planned for Phase 6 |
| A level starts only if it fits the hours left | `design/GAME_SYSTEMS.md:85` | The data fits (longest level 35 hours); the gate was not driven |
| Crisis triggers fire once per crossing; Acts return only after 7,488 hours | `design/GAME_SYSTEMS.md:172`, `:182` | Not driven by my tools; project tests exist and pass |
| Floor Votes and Office Hours cannot be lost | `design/GAME_SYSTEMS.md:194` | Not tested as a negative case |
| Information standards (cost shown before a choice, reasons on disabled buttons, no machinery in speech) | `design/INFORMATION_STANDARDS.md` | Out of scope for a mechanics and performance audit; the project has its own tests |
| Anything on a phone | `CLAUDE.md` section 11 | No device |

## 4. Reading this table

- **F-01 and F-03 are the two findings I would act on first.** F-01 is the direct answer to your note on the orientation document. F-03 means a core weekly pressure can be ignored.
- F-08 to F-10 rest on bot play and on my own full-kit deck. They show where to look, not how a person will fare.
- F-18 and F-19 cannot be closed without a phone.
