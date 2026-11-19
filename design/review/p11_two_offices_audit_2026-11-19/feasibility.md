# Feasibility: four questions the design depends on

Draft for Cameron. Read-only audit: nothing was changed. Where a claim was tested, the test is named (a pure function call on `tools/export_data.py`, nothing written).

## Executive summary

| Question | Answer | Work to make it work |
|---|---|---|
| 1. Does the loader accept a negative `win_delta_boXX`? | **Yes, with one spelling rule.** `-2` and `-3--1` load and apply. A typographic minus (U+2212, "−2") is rejected with a clear error | None to the code. Two real gaps: the briefing never previews level booster deltas (so a loss would be invisible until the result screen), and there is no test with a negative |
| 2. How is the Seasons column applied? | A row with a Seasons cell shows only in those months. Applied to **levels** (level list), **Random events** (draw) and **Buyable events** (Events list). **Not** applied to follow-ups, Dated events, visitors, staff tasks or the marketplace's random-level purchase | Nothing for the spec. Note the gaps if place content is seasonal |
| 3. Where would a Protagonist column on Levels be read? | Four places: the exporter's Levels columns and checks; the level-list loop; the marketplace's random-level purchase; and level reveal or start from events. **No data table is filtered by protagonist today**, so this is a first | Small to medium. One new optional column plus one shared filter function |
| 4. What would a place-ID token in `Text.say` touch? | Less than it sounds, in the wrong place: only about 1,160 Text rows go through `Text.say`, and **place words live mostly in data tables that bypass it** (events, intros, visitor questions, transitions). The codebase already has a load-time token fill (`DataDB._fill_name_tokens`) that fits protagonist-level tokens better | Two mechanisms are needed, not one (see 4.3) |

## 1. Negative `win_delta_boXX`

### What exists

- 32 Levels columns, `Win ΔBO01` to `Win ΔBO32`, exported as `win_delta_bo01` to `win_delta_bo32` with kind `"range"` (`tools/export_data.py:1606-1637`; the `Win ΔBO32` row is `:1637`).
- 198 non-null values across all 32 columns today. **None is negative.** Smallest minimum is 0, largest value 9 (`data/levels.json`).

### The loader (tested)

The `range` kind (`tools/export_data.py:2239`, called through `coerce()` `:2153`) was run on sample cells:

| Cell | Result |
|---|---|
| `-2` | `{min: -2, max: -2}`, accepted |
| `-3--1`, `-3 - -1` | `{min: -3, max: -1}`, accepted |
| `-3-1`, `-1-2` | `{min: -3, max: 1}`, `{min: -1, max: 2}`, accepted (a range that crosses zero) |
| `+2` | `{min: 2, max: 2}`, accepted |
| `0` | `null` (the "never happens" sentinel, as for every range column) |
| `-0` | `{min: 0, max: 0}`: not null, a roll of zero; harmless |
| `+1-3` | **error** ("is not a range, a number, or '0'"). A leading plus in a range is not accepted on this column |
| `−2` (U+2212) and `−3 to −1` | **error**. The workbook must use an ASCII hyphen-minus |

### The runtime

`GameState._apply_level_bonus_win()` (`GameState.gd:3878`) rolls each `win_delta_boNN` through `_roll_range()` (`:3926`, `randi_range(min, max)`, so negatives work) and hands the result to `_apply_booster_delta()` (`:5062`). That function does `clampi(before + delta, min, max)` using the booster standing bounds (`booster_standing.json`), so a negative delta lowers standing and cannot go below the floor. It also records the change for the result screen (`last_booster_change`, `last_booster_cause`) and follows standing links (`_follow_links`).

It is called on a **win only** (`GameState.gd:3613`), which matches the spec's example: "negative win deltas (for example -2 with the Consumer Advocacy Network on a casino win)".

### Gaps (not blockers)

| Gap | Evidence | Effect |
|---|---|---|
| The briefing does not preview a level's booster deltas | `BriefingSummary.stage_rewards()` (`scripts/rules/BriefingSummary.gd:16-22`) lists stage meta rewards and XP only; nothing else in the scripts reads `win_delta_boNN` except `_apply_level_bonus_win` | A negative delta, like every positive one today, shows only on the result screen (`OfficeScreen.gd:1410`, from `last_booster_change`). Information Standard 1 (say what a choice costs **before** it is made) argues that a *cost* must be previewed. This is a design decision for Cameron, and a code change if yes |
| No test uses a negative | `tests/test_game_state_level_bonus.gd` uses `{min: 3, max: 3}` and `{min: 4, max: 4}` | Add one before a level uses it |
| The delta is rolled, not shown as a range | `_roll_range` | A "-1 to -3" would be one roll; the player cannot see the spread |
| Two organizations linked by standing | `_follow_links` | A negative delta may drag a linked organization with it. Intended, but worth knowing |

**Verdict: feasible today with no loader change.** Use ASCII `-` in the workbook.

## 2. How the Seasons column is applied

### The mechanism

- `Seasons.in_season(row, month, table)` (`scripts/rules/Seasons.gd:20`): a row is in season when its `seasons` list is blank, or contains the season the current month falls in.
- The month-to-season table is the Rules tab's `seasons` row (`data/rules.json`): Spring 4 to 5, Summer 6 to 8, Autumn 9 to 11, Winter 12 to 3. Cameron's note: "Yezo's winter runs December through March; November is autumn."
- Exporter: an optional `Seasons` column read as `id_list` ("Autumn; Winter") on **Levels** (`tools/export_data.py:1653-1664`) and **Events** (`:1260-1263`).
- The month comes from the game calendar (`GameState.current_month()`, `:2220`).

### Where it is applied

| Place | Line | What it does |
|---|---|---|
| Level list | `OfficeScreen.gd:3674` (via `GameState.in_season`, `GameState.gd:2225`) | Hides out-of-season levels |
| Random event draw | `EventEngine.eligible_random()` `scripts/rules/EventEngine.gd:90` | Skips out-of-season events |
| Buyable events list | `GameState.buyable_events()` `:2251-2254` | Hides them |

### Where it is not

| Place | Effect |
|---|---|
| Follow-up events (`take_due_followup`, `:3008`) | A follow-up fires whatever the month |
| Dated events (`EventEngine.due_dated`) | Same |
| `GameState.buy_random_level()` (`:4525`) | May unlock an out-of-season level (it stays hidden from the list until its season, so this is harmless) |
| Visitors, staff tasks, visitor questions, ticker | No seasons column. The ticker has its own calendar gates (`OfficeTicker.calendar_met`: weekdays, from and to date) |

### Today's data

3 levels (LV92 Autumn, LV93 Winter, LV104 Summer and Autumn) and 10 Random events (EV01, EV02, EV41, EV48, EV49, EV56, EV66, EV67, EV69, EV72).

### What the spec needs

The eight new levels (LV115 to LV122) use seasons the same way (tuna season, the salmon run). **No code change.** Two cautions: seasonal *place* text (for example a snow festival at a protagonist's ski area) would have to be keyed by the same season, and a seasonal Random event in an office with few events may leave it quiet for months (the spec's "each office gets its own share of slots").

## 3. Where a Protagonist column on Levels would be read

### Today

No data-table row is filtered by protagonist. Protagonists differ through `data/player.json` only (starting meta, party, name), reached as `DataDB.player` (`scripts/autoload/DataDB.gd:189-196`, `use_protagonist()` `:542`). The two hand-written override files (`level_opponent_overrides`, `level_visitor_overrides`) are keyed by level, not by protagonist.

### The reading points (all four)

| # | Where | Line | What the column would do |
|---|---|---|---|
| 1 | Exporter | `tools/export_data.py:1653-1664` (Levels columns, `"optional": [...]`) and the Levels checks | Add `("Protagonist", "protagonist", "id_list")` as optional; check each ID against `data/player.json`. A blank cell means all four (matching the spec's "blank means all"). Cross-check: events that `unlocks_level` or `starts_level` a locked level (`GameState.gd:2385`, `:2412`, `:2515`) must not point a locked-out protagonist at it |
| 2 | The level list | `OfficeScreen._show_levels()` `:3620`; the filter loop `:3647+` | One more `continue`. It sits beside the Seasons filter at `:3674` and would use the same helper |
| 3 | Marketplace "random level" | `GameState.buy_random_level()` `:4525-4540` | The candidate loop checks tier, discovery, event-only, settled Act and unlocked; add the protagonist test, or a level the player cannot use could be "unlocked" and wasted |
| 4 | Reveal and start from events | `GameState.is_level_discovered()` `:2574`, `apply_event_choice()` `:2309` (reveal at `:2385`, start at `:2412`) | A District event (for example "A letter from the village office") reveals a level. If the event is one protagonist's, the level is too; if the event is shared, the reveal needs the same test |

Smaller places: `Ledger.is_level_unlocked()` (`scripts/rules/Ledger.gd:389`) and the unlock panel (`_on_unlock_level` `:4024`) never see a locked-out level if #2 filters first; the generated bill levels (`BattleSetup`) are protagonist-neutral.

### Shape of the change

One pure helper, for example `LevelAccess.allows(level, protagonist_id)` in `scripts/rules/`, used from #2 to #4, with a unit test. The tests use the default protagonist, so existing tests are unaffected as long as blank means all.

### Related (from the spec's eight new levels)

The spec's "a way to name one row" (levels that need one fixed place, such as Rokkasho's ports) is a separate need from the protagonist lock; see 4.

## 4. What a place-ID token in `Text.say` would touch

The spec's tokens (`{place:harbor}`, `{district}`, `{office_city}`) are new. Three facts decide the design.

### 4.1 Fact one: how `Text.say` treats tokens today

- `Text.say(key, values)` (`scripts/autoload/Text.gd:36`) calls `Phrase.say()` (`scripts/rules/Phrase.gd:36`), which fills only the names in `values`, with `"{%s}" % name` (`_fill`, `:84-92`). Any `{...}` left over prints literally and logs one warning ("still has a placeholder with no value").
- `Phrase` is pure (no autoloads), so it cannot look at the protagonist or the office by itself. A resolver would be **handed in** (`Phrase.new(lines, resolver)`), the way the rules are handed a phrase table. `Text.gd:31` builds the one instance, so the autoload is where the resolver would be attached.
- A key like `{place:harbor}` is a legal `values` name, but callers would have to pass every token; they will not. So it needs the resolver, not the callers.

### 4.2 Fact two: most place words are not in Text rows

Counting the audit's `place_references.csv` (14,131 hits in 52,000 player-facing rows):

| Where the words live | Hits | Goes through `Text.say`? |
|---|---|---|
| `strings` (the Text tab) | 26 | **Yes** |
| `events`, `event_choices`, `event_options`, `hosted_events` | about 310 | No: shown straight from data (`OfficeScreen._present_event`) |
| `visitor_questions`, `visit_questions`, `visit_answers` | about 1,170 | No |
| `level_intros`, `level_intro_thoughts`, `levels`, `stages` | about 370 | No |
| `transition_dialogue` | 807 | No |
| `office_ticker`, `office_notices` | about 155 | No; the ticker fills its own `{player}` (`OfficeTicker.fill_tokens`, `:38`) |
| `staff_tasks`, `how_to_play`, `shop`, `lobbyist_lines` | about 50 | Partly |
| Spoken cues and question pools (`player_cues`, `opponent_cues`, `questions.*`, `card_cues`) | about 11,200 | No (mostly generic words such as "district" and "committee", low signal) |
| `visitors` (names, titles, bios) | 53 | No |

So a token inside `Text.say` would reach about 26 rows. The 1,160 real-name hits and the casework are in tables that bypass it. Each of those tables already fills its own tokens in its own way (the ticker `{player}`, notices `{staff}`, components `{component}`, targets `{target}`), with no shared resolver.

### 4.3 Fact three: there are two kinds of token, and the code already has a precedent for one

| Kind | Depends on | Changes during play? | Example |
|---|---|---|---|
| **Protagonist-level** | which protagonist was chosen | No | the district name, the catalog of places (`{place:harbor}` picks a harbor from PC02's list) |
| **Office-level** | where the player is standing right now | Yes | `{office_city}` in an Either level's room text; the District office's own name |

Precedent: `DataDB._fill_name_tokens()` (`scripts/autoload/DataDB.gd:496`, called from `use_protagonist()` `:547`) replaces `{party}` **once, at protagonist selection**, in the playtest level's stage names, and keeps the template so a different protagonist refills it. Its own comment says it all: "everything downstream ... sees an ordinary name and no consumer has to know tokens exist." That fits protagonist-level tokens exactly: resolve every data table's place tokens when the protagonist is chosen and leave every screen untouched.

Office-level tokens cannot be resolved that way (the office changes). They need a display-time resolver at each site that shows data text, or a rule that Either rooms use **neutral** wording (settled rule 4 already allows "describe the place neutrally"), so that the token is only needed in the few Either rooms that want the office's name.

### 4.4 What a token system would touch

| Piece | File | Note |
|---|---|---|
| Resolver for protagonist-level tokens | `DataDB._fill_name_tokens()` `:496` (extend), `use_protagonist()` `:542` | Keep templates (`_name_template` pattern) so switching protagonist refills |
| Resolver for office-level tokens | `Phrase.gd` (accept a resolver), `Text.gd:31`; each data-text display site | New; sites: `_present_event`, the visitor and visit screens, `LevelIntroScreen`, `StageTransitionScreen`, ticker, notices, staff tasks |
| Exporter placeholder check | `tools/export_data.py:3576-3590` | Matches `\{(\w+)\}` only. `{place:harbor}` and `{place.harbor}` do **not** match, so they would be silently unchecked; `{place_harbor}` would match and warn "uses ... but does not list it in Placeholders". Needs a rule: known token types, known place types, and "this protagonist has that type" (the spec's checker) |
| Check of data tables | none exists for tokens outside Text | The exporter does not scan events, intros or questions for unresolved braces. New check |
| Wording snapshot | `tests/wording_snapshot.json`, `check_wording_snapshot()` `tools/export_data.py:4581` | Covers Text rows only; changing those rows needs `--accept-wording` |
| The "no game terms in speech" test | `tests/test_spoken_no_game_terms.gd` | Resolved names must not trip it; unresolved braces already would not |
| The text sweep | `tools/text_sweep.gd` (run per UI style in `tools/verify.sh`) | Natural place for "no unresolved token on any screen" (the spec's own test) |
| New data | a Places tab, `data/places.json`, DataDB loader, `check_*` in the exporter | Phase 2 per the task; not built here |
| Fixed pick by ID | token syntax `{place:PL012}` or `{place:harbor#2}` | Needed for levels that name one place; the exporter must verify the ID exists for the protagonist |

### 4.5 The cheap part

Roughly 4,300 of the 14,131 hits are generic words the catalog has **no type for** (streets, housing, forest, roads, banks, police and fire, studios, restaurants, airports, libraries, river works, sports venues; see `place_types.md`). They need no token at all if left generic. The work that actually needs tokens is the 1,162 real-name hits (91 distinct names) and the casework text (events, visitor questions, intros, transitions).

### Verdict

Feasible, and smaller than a single `Text.say` change suggests, but it is **two mechanisms** and a **new exporter check**, and the biggest cost is content (rewriting the text), not code. Recommended for the Phase 2 plan: protagonist-level tokens resolved at load (extend `_fill_name_tokens`), office-level text kept neutral or resolved at a few named sites, and one shared exporter check for unresolved braces in every table.
