# Phase 0: Orientation

Audit of Coliseum of Parliament at commit `b02bbab` (branch `claude/new-session-klhgm8`, level with `main`), 2026-11-13. Read-only: nothing outside `audit/` is changed. Labels: **Verified** (I ran it), **Inferred** (read from code or data), **Assumed** (no evidence).

An earlier audit already lives in this folder (`audit/00-summary.md` to `07-actions.md`, 2026-11-10, and `audit/gameplay/`). I have not changed those files. This audit's files are `phase0_orientation.md`, `benchmarks.md` and, later, `mechanics.*`, `roadmap.md`, `SUMMARY.md` and `tests/`.

## 1. Project map

| Area | What is there | Evidence | Label |
|---|---|---|---|
| Engine | Godot 4.5.1 stable, GDScript only, GL Compatibility renderer, portrait 1080 x 2340, stretch `canvas_items` / `expand` | `project.godot:17`, `:38-49`, `:63-65`; binary reports `4.5.1.stable.official.f62fdbde1` | Verified |
| Main scene | `scenes/menus/IntroScreen.tscn` | `project.godot:16` | Inferred |
| Scenes | 11: 3 menus (Intro, BootCheck, Resign), 7 office_hours (Office, Visitor, Visit, Trade, FloorVote, LevelIntro, StageTransition), 1 battle | `find scenes -name "*.tscn"` | Verified |
| Scripts | 149 `.gd` under `scripts/`: 7 autoloads (7,760 lines), 82 pure rules files (11,638 lines), 57 UI files (14,746 lines), 3 builders at the top level (1,300 lines) | `find`, `wc -l` | Verified |
| Autoloads (load order) | `DataDB` (1,883 lines), `EventBus` (50), `Text` (51), `GameState` (4,947), `SaveManager` (272), `Audio` (241), `Layout` (316) | `project.godot:19-33` | Inferred |
| Rules layer | `scripts/rules/`: `BattleEngine`, `BattleState`, `BarModel`, `CardResolver`, `IntentRunner`, `FloorVoteEngine`, `OfficeHoursEngine`, `LevelRunner`, `MetaRules`, `Ledger`, `PartyDues`, `Promises`, `Difficulty` and 69 others | `ls scripts/rules` | Verified |
| Resources | 2 `.tres` (`theme/cop_theme.tres`, `audio/default_bus_layout.tres`); 2 shaders (`soft_edge`, `move_glow`); no custom `Resource` classes for content: content is JSON | `find . -name "*.tres"` | Verified |
| Assets | 275 MB, 344 PNGs; no audio files | `du -sh assets`; `CLAUDE.md` section 11 | Verified (size), Inferred (audio) |
| Signals | 19 `signal` declarations in `scripts/`: 8 on `EventBus` (`card_played`, `turn_started`, `turn_ended`, `intent_revealed`, `gaffe_changed`, `battle_ended`, `meta_changed`, `xp_changed`), the rest local to UI (`HandPresenter` 4, `CardView` 4, `Overlay` 2, `CueBanner` 1) | `scripts/autoload/EventBus.gd:21-50`; `grep "^signal"` | Verified |
| Per-frame scripts | 7 scripts define `_process`: `PlaceholderArt`, `MoveFlashLayer`, `LevelIntroScreen`, `OfficeScreen`, `StageTransitionScreen`, `DragScroll`, `Layout` | `grep "func _process"` | Verified |
| Tests | GUT addon (`addons/gut`); 223 test scripts under `tests/`; 32 real-click scenes under `tests/interaction/` | `find tests`; `ls tests/interaction/*_test.tscn` | Verified |
| Existing bots | `tools/playtest_optimal.gd` (greedy and random card play, stage sweeps, full runs), `tools/strategy_playtest.gd` (44 named strategies, seeded with `PLAYTEST_SEED`), `tools/benchmark.gd`, `tools/stress*.gd`, `tools/rubric_playtest.gd` | `tools/playtest_optimal.gd:14-15`, `tools/strategy_playtest.gd:146-148` | Inferred |

## 2. How workbook data reaches the game

| Step | What happens | Evidence | Label |
|---|---|---|---|
| Source | `design/Game_Workbook.xlsx`, 64 tabs | `openpyxl` sheet count | Verified |
| Export (manual) | `python3 tools/export_data.py` reads the workbook with openpyxl and writes `data/*.json` (64 files, 11 MB). Each tab is one `SHEETS` entry (columns, key, ID pattern); Balance, Affinity and Lists have their own readers. It prints a validation report and exits non-zero on errors | `tools/export_data.py:1-25`, `:111`, `:2109`, `:4238` | Verified (ran today: "No errors") |
| Hand-written data | Ten JSON files the exporter never overwrites (`rules`, `booster_standing`, `party_standing`, `art`, `sounds`, `staff_names`, two override files, two playtest files) | `CLAUDE.md` section 6 | Inferred |
| Load | `DataDB._ready()` calls `load_all()`, parses every JSON file, validates again and prints a report | `scripts/autoload/DataDB.gd:344-349` | Verified (boot check passes) |
| Read | Rules read numbers through `DataDB.balance` / `Levers`; sentences through `Text.say("key")` | `tests/test_balance_keys.gd:33-40` | Inferred |
| Manual steps | Edit the workbook only with `tools/workbook/wbx.py` (openpyxl saving corrupts it); run the exporter; run `tools/verify.sh`; commit workbook and JSON together. There is no automatic export on save or in CI | `tools/workbook/README.md:1-5`, `:37-44` | Inferred |
| Gate | `tools/verify.sh`: export, formula check, boot, compile check, GUT, 32 click tests | `tools/verify.sh:8-17` | Verified |

**Format risk (Inferred):** a blank cell exports as JSON `null`, so every consumer must guard `str(null)` and `int(null)` (`CLAUDE.md` section 6). Phase 6 will probe this.

## 3. What runs here, and what does not

| Capability | Status | Evidence |
|---|---|---|
| Headless boot | **Verified.** `.tools/godot --headless --path . scenes/menus/BootCheck.tscn` passes inside `tools/verify.sh` | verify run today: "All checks passed" |
| GUT unit tests | **Verified.** 163 scripts, 1,879 tests, 928,400 asserts, all passing, 117.6 s | verify log, GUT summary |
| Real-click tests | **Verified.** 32 of 32 pass under `xvfb-run` (software renderer `llvmpipe`) | verify log |
| Headless simulation | **Verified possible.** `BattleEngine.setup()` takes a `seed` (`scripts/rules/BattleEngine.gd:148`) and the rules layer has no UI or autoload dependencies | `tools/playtest_optimal.gd:767-769` |
| Screenshots | **Verified** under `xvfb-run` at 1080 x 2340 | taken today for the trade screen |

**What I cannot run or measure**

| Item | Why | Effect on the audit |
|---|---|---|
| A real phone (Android or iOS) | No device, no `export_presets.cfg`, no export templates | Frame time, memory, load time, thermal and touch on hardware are **not measurable**. I can give desktop proxies only |
| GPU frame time and real draw cost | The only display is Xvfb with the `llvmpipe` software renderer | Frame-time numbers here are not comparable to a phone. Draw-call counts and node counts are still meaningful |
| Stable timings | The repo's own benchmark notes timings wander 20 to 70% between identical runs on shared machines (`design/bench/README.md:9`) | Timings need medians over repeats and wide tolerances; memory and counts are reliable |
| Audio | No sound files exist | Audio cost and mixing cannot be tested |
| Human play | Bots only | Win rates are relative, not what a person sees (`design/BALANCE_AUDIT_PROCESS.md:40`) |
| App suspend and resume | Needs a mobile OS; I can only send the notification by hand | Phase 6 will simulate `NOTIFICATION_APPLICATION_PAUSED` (`scripts/autoload/SaveManager.gd:260`), which is weaker than a real suspend |
| Store checks | No built app | Download size, target API and 16 KB page checks stay as recorded in `audit/06-ship-readiness.md` |

## 4. Randomness and seeding (needed for Phase 4)

| RNG | Seeded? | Evidence | Label |
|---|---|---|---|
| Battle (`BattleEngine._rng`: draws, intents, conversions) | Yes when the config has `seed`, else `randi()` | `scripts/rules/BattleEngine.gd:51`, `:148` | Inferred |
| Opening deck (`Ledger`) | Optional seed | `scripts/rules/Ledger.gd:489-493` | Inferred |
| People draw (who is seated) | **No**, `randomize()` every time | `scripts/BattleSetup.gd:352-355` | Inferred |
| `BarModel` roll, a `GameState` roll, `PatronLevel` | **No** by default | `scripts/rules/BarModel.gd:237-238`, `scripts/autoload/GameState.gd:1613-1614`, `scripts/PatronLevel.gd:115-116` | Inferred |
| Global `randi()` / `randf()` users | Controlled only by the global `seed()` call, which `strategy_playtest.gd` makes | `tools/strategy_playtest.gd:146-148` | Inferred |

A fully reproducible game therefore needs both the global `seed()` and the per-battle seed, and still has unseeded local generators. My harness will seed globally and record which sources stay random.

## 5. Gaps in stated design intent (found while orienting)

I did not invent intents for these. Each affects what Phase 1 can source.

| Gap | Evidence |
|---|---|
| No stated target win rate for a person, only bot thresholds and "a fair room is won roughly half to most of the time" | `design/CONTENT_GUIDE.md:293`; `tools/balance_audit.py:20-35` |
| No stated run length or session length. "There is no final win screen. A run is the campaign; the player stops when they like" | `design/GAME_SYSTEMS.md:58` |
| No stated technical budget anywhere (frame time, memory, load time, draw calls). Only measured baselines exist | `design/bench/README.md:1-9`; `tools/benchmark.gd:1-24` |
| Election strength "fires nothing yet"; what it should unlock is undecided | `design/GAME_SYSTEMS.md:114`; `CLAUDE.md` section 9 |
| Audience segment favorability is stored and read by nothing | `design/GAME_SYSTEMS.md:112` |
| The design documents disagree with each other and with the data in places: `GAME_DESIGN.md:3` counts 101 levels and 273 stages, the data has 114 and 289; `GAME_DESIGN.md:158` says a stage is never saved mid-fight, `GAME_SYSTEMS.md:323` describes a checkpoint at each defeated opponent; `GAME_DESIGN.md:43` calls the TV debate a single meter, `GAME_SYSTEMS.md:192` a three-way room | cited lines; `data/levels.json`, `data/stages.json` |

Where two documents disagree I treat `design/GAME_SYSTEMS.md` as the source, because it says it was written from the code and that the data wins (`design/GAME_SYSTEMS.md:3`).
