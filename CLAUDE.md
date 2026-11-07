# Coliseum of Parliament — Build Brief for an AI Coding Agent

> **How to use:** This file is the brief: who you are working for, the hard constraints, canon, the data contract and the working rules. It is deliberately short. **How the game works is in `design/GAME_SYSTEMS.md`**, how the player must be told things is in `design/INFORMATION_STANDARDS.md`, how the code is organised is in `design/ARCHITECTURE.md`, and the state of the project for a new session is in `design/NEW_CHAT_STARTUP.md`. Rewritten 2026-11-06; the previous long version (with a dated milestone log) is in git history at commit `05b615e`.

---

## 1. Your role

You are the sole programmer on a solo-developer mobile game. The designer (Cameron) is a domain expert in legislatures and politics but **not a programmer**. He will not write or debug code. Your job is to build and maintain a working Godot 4 project from the design and data below, explain every change in plain English, and never make design or canon decisions on his behalf.

## 2. The game in one paragraph

*Coliseum of Parliament* (CoP) is a **single-player, portrait-mode, turn-based card battler** set in **Yezo**, the fictional parliamentary nation of Cameron's manga. The player is a legislator who fights rhetorical battles (committee hearings, floor debates, party caucuses, press conferences, town halls, TV debates, lobbyist meetings) with a hand of **argument cards** in six suits, answers dilemmas in Office Hours and events, and carries **bills** to a Floor Vote. Each battle is a race to push a **support bar** past a **threshold** before the turns run out or the **gaffe meter** fills. Battles ("stages") chain into **levels**, usually built around one bill. Between levels the **Office** turns results into strength: four meta numbers (Constituency support, Reputation, Funds, Party support) plus XP; **standing** with 32 organizations and 6 parties, which unlocks backings, requests and votes; staff, cards and items; and a **week** of 40 work hours, party dues, awareness, events and promises. Read `design/GAME_SYSTEMS.md` for the exact mechanics and `design/GAME_DESIGN.md` for the story of how the parts connect.

## 3. Hard constraints

| Constraint | Requirement |
|---|---|
| Engine | Godot 4 (latest stable 4.x), GDScript only. A **standard Godot project**: no proprietary SDKs, no paid plugins without asking. If running in Summer Engine, avoid Summer-specific SDK features so the project opens in stock Godot. |
| Platforms | iOS and Android. Portrait only. |
| Resolution | Base 1080 × 2340 (9:19.5). Stretch mode `canvas_items`, aspect `expand`. Respect device safe areas. |
| Data-driven | **All content comes from `/data/*.json`**, exported from the workbook. Never hardcode card values, stage rules, names, sentences or design numbers in scripts. |
| Art | 2D PNGs only, loaded by ID from `/assets/` with fallbacks; missing art falls back to a labelled placeholder. No 3D, no rigging. |
| Text | English is primary everywhere. Japanese appears only as a small, muted accent **next to** English, never alone. Fonts: cards use Antaka Brush Display; everything else Antaka Brush Text with Noto Sans JP as its fallback (Antaka is Latin-only, no ō, −, ×, • or →). `tools/build_theme.gd` builds the theme. |
| Code style | Heavily commented, small files, descriptive names. Pure game rules live separately from UI code. |
| Source control | Git. Commit at the end of each piece of work with a plain-English message. Merge to `main` only after `tools/verify.sh` prints "All checks passed". |

## 4. Canon rules (Yezo): do not break

- The parliament is **unicameral with 101 seats**; a floor majority is **51**.
- Yezo has **no early elections**: no recall or snap-election mechanics.
- Character names, parties, committees, places, political positioning and rhetorical elements come **only** from the data files. Never invent canon. Use neutral placeholders (such as "Visitor A") when data is missing.
- If any design choice seems to touch canon, **stop and ask**.

## 5. Where things are

| Path | What |
|---|---|
| `data/` | JSON exported from the workbook (the source of truth); a few hand-written files (section 6) |
| `design/Game_Workbook.xlsx` | The design workbook, exported by `tools/export_data.py` |
| `scripts/autoload/` | `DataDB`, `EventBus`, `Text`, `GameState`, `SaveManager`, `Audio`, `Layout` |
| `scripts/rules/` | Pure rules: no UI, no autoloads, no files (tests prove it) |
| `scripts/ui/`, `scenes/` | Screens and components |
| `assets/` | Characters, backgrounds, cards, icons, fonts, shaders, how-to images |
| `tests/`, `tests/interaction/` | GUT unit tests; real-click tests |
| `tools/` | Exporter, `workbook/wbx.py` (the only safe workbook editor), `verify.sh`, bots, audits, builders |
| `design/` | The guides below, the change log, and working papers (`proposals/`, `review/`, `bench/`) |

| Guide | For |
|---|---|
| `design/GAME_SYSTEMS.md` | **The mechanics**: resources, growth and decline, choices, and all run state |
| `design/INFORMATION_STANDARDS.md` | **How the player must be told things** |
| `design/ARCHITECTURE.md` | How the code is organised; pitfalls |
| `design/GAME_DESIGN.md` | The game as a story |
| `design/CONTENT_GUIDE.md`, `design/EDITING_TEXT.md` | Writing content and reworded text |
| `design/NEW_CHAT_STARTUP.md` | State of the project and working rules for a new session |
| `design/CHANGELOG.md` | Summary of Sept–Oct 2026, then every dated change |
| `design/CLEANUP_CANDIDATES.md` | Things that look removable (never delete without Cameron's say-so) |

## 6. Data contract

`design/Game_Workbook.xlsx` is exported by `tools/export_data.py` into `data/*.json`; the exporter maps each tab (some outputs are objects or nested structures) and validates cross-references, wording and ID ranges. `DataDB` loads every file, validates it again, and prints a readable error report. The current snapshot: 101 levels, 273 stages, 32 organizations, 53 backings, 70 cards, 131 opponents, 6 parties, 50 floor-vote bills, 166 visitors, 56 events, 34 shop items, 21 staff, 180 bill components, 6 cosmetic packages, about 916 Text rows (`design/NEW_CHAT_STARTUP.md` keeps the current counts).

| Group | Files (`data/`) |
|---|---|
| Numbers and switches | `balance` (every design number), `sanban` (the four meta numbers' ranges, starts, decay), `rules` (hand-written switches, below), `booster_standing`, `party_standing`, `awareness_effects`, `standing_links`, `vote_influence_triggers` |
| Cards and rooms | `cards`, `suits`, `affinity` (suit multipliers per room), `stages`, `segments`, `modifiers` (backings), `questions` (the room question pools and Stage Questions), `opponents`, `opponent_cues`, `player_cues`, `card_cues` |
| Levels and people | `levels`, `level_intros`, `level_intro_thoughts`, `level_opponent_overrides`, `level_visitor_overrides`, `visitors`, `visitor_questions`, `staff`, `staff_names`, `player` (the four protagonists) |
| Standing and parties | `boosters` (organizations), `parties`, `party_stakeholders`, `party_values`, `organization_tastes` |
| Bills and laws | `floor_votes` (bills and party positions), `law_effects`, `vote_influence_cues`, `bill_components`, `patron_bills`, `bill_level_templates`, `visit_questions`, `visit_answers`, `trade_questions`, `lobbyist_lines` |
| Week and events | `events`, `event_choices`, `event_options`, `hosted_events`, `reaction_lines`, `shop` (items), `cosmetic_packages`, `office_notices`, `office_ticker`, `transition_cast`, `transition_backgrounds`, `transition_dialogue` |
| Text and presentation | `strings` (**every sentence**), `how_to_play`, `lists`, `art`, `sounds` |
| Hand-written (the exporter never overwrites) | `rules`, `booster_standing`, `party_standing`, `art`, `sounds`, `staff_names`, `level_opponent_overrides`, `level_visitor_overrides`, `playtest_level`, `playtest_cards`; each carries its own `_README` |

**Data rules**

- **No sentence lives in a script.** Every line the game says is a row in the Text tab asked for by a literal key (`Text.say("a.b")`, never a built-up key). The exporter errors on a key the code asks for and the tab lacks, and notes a row nothing asks for. `design/EDITING_TEXT.md` is the guide.
- **No design number lives in a script.** It is a Balance-tab row read with `DataDB.balance.get("key")` (or `Levers` from a rules file); `tests/test_balance_keys.gd` fails the build on a missing key.
- **Four names are data, not just words:** "Constituency support", "Reputation", "Funds" and "Party support" are shown on screen *and* are how the code reaches the run's meta. Renaming one in the workbook alone is an export error.
- `effect_text` on a card is display only: never parse it. Conditional effects use the structured special-effect fields.
- A blank workbook cell exports as JSON `null`: guard `str(null)` and `int(null)`. Cells holding `"varies"` or `"—"` are null.
- The workbook's structured columns are the truth; when text and a column disagree, change the text.

## 7. Rules of play (moved)

The battle rules, bar models, win and loss, committees, opponent behavior, National Assembly Floor Voting (including the influence swing, whipping and per-party scope), the Level Intro and the Stage Transition used to be written here. They now live in **`design/GAME_SYSTEMS.md`**, rewritten against the code. Old subsection numbers, for the many code comments that cite them:

| Old | Now |
|---|---|
| 7.1 Setup, 7.2 Turn loop, 7.3 Bars, 7.4 Win and loss, 7.5 Committee, 7.6 Opponent behavior | `GAME_SYSTEMS.md` section 7 |
| 7.7 Floor Voting | `GAME_SYSTEMS.md` section 8; `GAME_DESIGN.md` "National Assembly Floor Voting" |
| 7.8 Level Intro | `GAME_SYSTEMS.md` sections 2 and 8; `INFORMATION_STANDARDS.md` section 1; `CONTENT_GUIDE.md` section 7.4 |
| 7.9 Stage Transition | `CONTENT_GUIDE.md` section 7.3 |

## 8. Meta systems (moved)

The meta numbers, stage rewards, crisis triggers (Town Hall, Steering Committee, funding freeze, free backing), office hours, party favorability, one-time levels, the XP checkpoint, saving, and cosmetic packages are described in **`design/GAME_SYSTEMS.md`** sections 3 to 6 (time, resources and standing, choices, growth and decline) and in `design/GAME_DESIGN.md` ("The Office loop"). The run's variables are listed in `GAME_SYSTEMS.md` section 9.

## 9. Open switches and unresolved decisions

`data/rules.json` holds hand-written switches, each with its question, its options and what each means; a value outside the options is rejected at startup. Current values: `turn_limit_outcome` loss; `opponent_can_win_by_threshold` false; `opponent_engine` `intent_patterns` (the only one built); `press_answer_timer` false; `discard_hand_end_of_turn` true; `pass_energy_penalty` 1; `guard_cap` 5; `level_gating_enabled` true; `open_card_collection` false; `funds_starting_cap` 100,000; `card_training_looks` 3; `default_consumable_stack_cap` 5; `default_intent_pattern` attack 1–6, gain 1–6, block 0–2. An item marked **[DEFAULT]** in code is an implementation choice behind such a switch or a Balance number, for Cameron to change.

**Unresolved: ask, don't guess.**

- **Party post titles:** which real-world post titles Yezo's parties use (`opponents.json`'s Title column overrides Role for display).
- **The Theme → organization mapping** (Question Themes tab) is a draft Claude wrote for Cameron to correct.
- **What Election Strength should unlock:** it is built and shown but fires nothing.
- **Audio:** the plan and brief exist (`design/proposals/AUDIO_PLAN_2026-10-26.md`); there are no sound files yet.

## 10. Information standards (the short version)

Full text and enforcement in `design/INFORMATION_STANDARDS.md`.

1. Say what a choice costs and gives **before** it is made, and what it did **after**.
2. A button the player cannot press shows **why**.
3. **One idea, one name**: the terms are fixed (Constituency support, Reputation, Funds in 円, Party support, organization, backing, Aye/Nay, Legislative Work, threshold, level and stage, Staff Rank); no internal IDs, romaji or code words on screen.
4. **No character mentions the machinery** (levels, stages, turns, energy, numbers); enforced by `test_spoken_no_game_terms.gd`.
5. **Choices are honest**: sincere options of similar length, costs charged as promised, no option the only thoughtful one.
6. English first, Japanese only as a muted accent beside it; American spelling; dates YY.MM.DD; thousands commas.
7. The hidden clock stays hidden. Portrait, safe areas, wrapping, a text-size setting, touch-sized controls.
8. All of Claude's writing is a **draft** for Cameron.

## 11. Status

Milestones M0 to M5 (project and data pipeline, rules engine, battle UI, committees and caucus, Office and saving, XP and the shop) are **done**, and the game has grown far beyond them: see `design/GAME_DESIGN.md`. **M6, an Android then iOS build tested on a real phone, has not been started**; layout has been checked only in desktop screenshots. Art is mostly undrawn (opponents, visitors, students, PC02/PC03, some icons), and every sound is silent.

## 12. Working agreement

- **Explain like a colleague, not a manual.** Keep it short and plain English: what changed and why. Cameron likes tables and an executive summary on medium and long answers; ask decisions as popup questions.
- **Ask before** you add a dependency, change a data schema, rename an ID, or resolve anything marked open or canon.
- **Never hardcode content** to get something working faster. If data is missing, use a placeholder and flag it.
- **Keep rules separate from visuals.** `scripts/rules/` must run without any UI. Every bug fix in the rules gets a test.
- **More than about 150 lines of new code: outline the plan first and wait for approval.** "Go" approves a plan; "merge" approves a merge.
- **Small commits**, each with a message a non-programmer can read.
- **No deletion or removal without Cameron's say-so** (candidates go in `design/CLEANUP_CANDIDATES.md`).
- **Add content, never mechanics**: new rooms, levels and events are workbook rows built like the nearest existing one; anything needing code is proposed first.
- When you are unsure, **say so** and offer 2–3 options with a recommendation.

## 13. Code organisation (moved)

How the code is organised (autoloads, the rules-versus-screens split, the battle screen's presenters, the cue banner, audio, art loading and fallbacks, touch, scene builders and the known pitfalls) is in **`design/ARCHITECTURE.md`**.

## 14. Working notes that still apply

- **Workbook edits.** Never save `design/Game_Workbook.xlsx` with openpyxl (it corrupts values and wipes formula caches). Edit raw XML with `tools/workbook/wbx.py` (`tools/workbook/README.md`). After every edit run `python3 tools/export_data.py` (it must say "No errors"); `--accept-wording` refreshes `tests/wording_snapshot.json` when Text rows change on purpose.
- **Verification.** `tools/verify.sh` (about 2 minutes: export, workbook check, boot, compile every script, unit tests, real-click tests; `--quick` skips the click tests). Wait for the real "All checks passed" line. GUT alone: `.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`. A new `class_name` script needs `.tools/godot --headless --path . --import` before tests see it.
- **Screenshots** need a real display (`xvfb-run -a -s "-screen 0 1080x2340x24" ... --path .`), not `--headless`. Click drivers must be added to the scene root; delete throwaway drivers before committing.
- **Memory leaks.** A lambda stored in a long-lived object must capture what it needs, not `self`; a Node must not `await` a timer.
- **Scene builders.** Only the builders listed in `design/ARCHITECTURE.md` section 8 may be re-run; the Office and battle scenes are edited by hand.
- **Content is draft.** Anything written by Claude in the workbook (cues, questions, bills, components) is a draft for Cameron to rewrite; never decide canon.
- **Documents.** When a change alters how the game works, update `design/GAME_SYSTEMS.md` (and `GAME_DESIGN.md` if the story changes), add a `##` section to the end of `design/CHANGELOG.md`, and add one line to the index below.

## 15. Change log index

The September and October 2026 work is summarized at the top of `design/CHANGELOG.md` (the old per-entry index is in git history at `05b615e`). Sections since 2026-11-01, oldest first:

- Playtest notes: bigger transition portraits, a clearer stage Details panel, a deck expansion (2026-11-01, Cameron)
- Bill-room replies fit the question (2026-11-01, Cameron)
- Every ticker line names an outlet (2026-11-01, Cameron)
- Open Debate: committees run out of questions, and now say so (2026-11-02, Cameron)
- The next opponent stepping up gets its own popup (2026-11-02, Cameron)
- Stage transitions reviewed: who speaks, repeats, the Floor Vote (2026-11-02, Cameron)
- Party leaders speak before the Floor Vote (2026-11-02, Cameron)
- Transitions: locked opponents, two speakers, more lines, ST30 tidied (2026-11-02, Cameron)
- Government bodies use the canon names (2026-11-02, Cameron)
- Playtest notes: card faces, soft boxes, week-end watch, Heritage Party rivals (2026-11-02, Cameron)
- Playtest notes, second round (2026-11-02, Cameron)
- Office Hours: promise and cost text reviewed (2026-11-02, Cameron)
- Promise deadlines fit the 48-hour week; Act Now choices reworded (2026-11-02, Cameron)
- Strategy playtest: 168 bot runs at Funds, Election Strength and Party support (2026-11-02, Cameron)
- Campaign Pressure: Relaxed, Standard, Harder (2026-11-02, Cameron)
- Decisions from the strategy playtest (2026-11-02, Cameron)
- Protagonist x Campaign Pressure playtest (2026-11-02, Cameron)
- Custom bill audit (2026-11-02, Cameron)
- Two-part bills get the member visit half the time (2026-11-03, Cameron)
- Member visit and lobbyist trade content review (2026-11-03, Cameron)
- Member visit and lobbyist trade fixes (2026-11-03, Cameron)
- Prompts for revising the component system (2026-11-03, Cameron)
- Bill Components audit (2026-11-03, Cameron)
- Member visit and lobbyist trade content, phase 3 (2026-11-03, Cameron)
- Component system code changes, phase 4 (2026-11-03, Cameron)
- Custom bill validation, phase 5 (2026-11-03, Cameron)
- Component questions written from each part, phase 2 (2026-11-03, Cameron)
- Lobbyist Lines: each lobbyist speaks in their organization's voice (2026-11-03, Cameron)
- Quality control audit (2026-11-03, Cameron)
- The bot plays discard cards; a discard card trial (2026-11-03, Cameron)
- Office Hours choices that promise something now cost something (2026-11-03, Cameron)
- Hosted events: a reply that promises nothing (2026-11-04, Cameron)
- In-universe content review (2026-11-04, Cameron)
- Press conference: the reporters' moves are shown (2026-11-04, Cameron)
- Journalists only attack, for 1-2 (2026-11-04, Cameron)
- The stage end screen no longer explains gaffes and awareness (2026-11-04, Cameron)
- Law, neglect and staff-audience wording; staff audience rewards become organizations (2026-11-04, Cameron)
- Stance, vote and outcome rewards shown together (2026-11-04, Cameron)
- Bill content review: grammar, coherence and honesty (2026-11-04, Cameron)
- Levels explain themselves: purpose line, bill card, Read the Bill (2026-11-04, Cameron)
- Characters never mention levels or stages (2026-11-04, Cameron)
- Opponents argue their own party's side of a bill (2026-11-04, Cameron)
- Opponent lines: no repeats, every side, demanding allies (2026-11-04, Cameron)
- Promise deadlines pause during a level; a level must end within the work week (2026-11-04, Cameron)
- Legislative Work: carried bills move into their law pop-ups (2026-11-05, Cameron)
- An extra member visit on drafted bills; "Convince <member>" (2026-11-05, Cameron)
- Bigger character portraits in rooms and visits (2026-11-05, Cameron)
- The hand's scroll bar moves above the cards, in gold (2026-11-05, Cameron)
- Score bars take the cue band's slant and gold edges (2026-11-05, Cameron)
- Documentation review: new references, a slim brief, September and October summarized (2026-11-06, Cameron)
- Mechanic Coherence and Clarity Test: expert pass, touch-target and keyword audits, player-test kit (2026-11-06, Cameron)
- MC²T follow-up: 144 px buttons, a save at each defeated opponent, "Backers" and wording (2026-11-06, Cameron)
- Buttons back to their earlier sizes (2026-11-06, Cameron)
- Five organization chips stay full size (2026-11-06, Cameron)
- The battle picture ends above the hand scroll bar (2026-11-06, Cameron)
- A two-second hold on a stage Continue button (2026-11-06, Cameron)
- Levels on cooldown leave the level list (2026-11-06, Cameron)
- Cameron's workbook update: bill votes, party positions, influence thresholds (2026-11-07, Cameron)
- 33 opponent lines for the bills whose party positions changed (2026-11-07, Cameron)
- Two empty event slots filled: EV01 Sapporo Grand Sumo and EV02 Temple Bell (2026-11-07, Cameron)
- Promises can owe Funds; EV01 option B uses it (2026-11-07, Cameron)
- Office Hours organization chips centered beside the visitor (2026-11-07, Cameron)
- Office Hours screen laid out around the spoken line (2026-11-07, Cameron)
