# Proposal: an Intro (title) screen

**Status: built (2026-09-26).** Cameron asked for "an intro screen with
options to Continue (Load Game); Start New Game (opens prompt to select a
main character)." Built exactly as planned below, plus one addition §3
didn't call out by name: New Game warns before overwriting a save on disk
nobody has loaded yet, the same words Office Management's own "New game"
uses, built in code the same way (`IntroScreen._overwrite_warning`,
an `Overlay`) rather than as a fourth Text-tab key.

## 0. What happens today, for contrast

There is no title screen. `project.godot`'s main scene is `OfficeScreen.
tscn` directly. `SaveManager` is an autoload, so it runs before any scene:
at boot it tries `load_game()`; if there's no save, it sets `GameState.
awaiting_new_game = true` instead. `OfficeScreen._ready()` then either
shows the Office as normal (a save loaded) or auto-opens its New Game
panel — the protagonist picker, already fully built and tested
(`tests/interaction/new_game_test.tscn`) — over the top of it (no save).

So a returning player is dropped straight into the Office with no tap at
all; a new player sees the Office appear with the picker already open on
top of it. Nothing asks "Continue or New Game?" — the save's mere existence
decides it.

## 1. The target flow

A new scene, shown first, always:

```
IntroScreen
  Continue    — enabled only if SaveManager.has_save() is true
  New Game    — always enabled
```

**Continue**: calls `SaveManager.load_game()` (not auto-run at boot
anymore — see §3), then opens the Office. Office behaves exactly as it
does today once a save is loaded: mid-level resumes are already Office's
own job, untouched here.

**New Game**: opens the **existing** protagonist picker — reusing
`OfficeScreen`'s already-built, already-tested `NewGamePanel`/`_show_new_
game()` rather than building a second one (see open question 1). If a save
already exists, this warns first — reusing the exact confirmation
(`_confirm_new_game()`, "this will throw the run away") Office Management's
own "New game" button already shows, so starting over is never a silent
surprise no matter which door you came in through.

## 2. Decisions (Cameron, 2026-09-26)

| # | Question | Answer |
|---|---|---|
| 1 | New Game's picker: reuse the existing one inside `OfficeScreen`, or build a second one directly on the Intro screen? | **Reuse** — hand off by setting `awaiting_new_game = true` and changing scene. Nothing new to keep in sync. |
| 2 | First-ever launch, no save at all: show the Intro screen anyway with Continue disabled, or skip straight to the picker like today? | **Show it anyway**, Continue disabled/greyed. The game reads the same on every launch. |

## 3. What changes, file by file

| File | Change |
|---|---|
| `scenes/menus/IntroScreen.tscn` (new) | Background (art id `TITLE`, new — falls back to a labelled placeholder like every other missing background), title, Continue button, New Game button. Built by a generator script, same convention as `tools/build_battle_scene.gd`/`build_visitor_scene.gd`. **No Japanese accent on the title** — Cameron hasn't given the game an official Japanese name, and inventing a translation isn't this build's call (CLAUDE.md §4/§12) |
| `tools/build_intro_scene.gd` (new) | Generates the `.tscn` above |
| `scripts/ui/IntroScreen.gd` (new) | Wires the two buttons; `_ready()` sets `%ContinueButton.disabled = not SaveManager.has_save()`. New Game builds and owns its own overwrite-warning `Overlay`, same pattern as `OfficeScreen._new_game_panel` |
| `project.godot` | `run/main_scene` → `res://scenes/menus/IntroScreen.tscn` |
| `scripts/autoload/SaveManager.gd` | `_ready()` stops calling `load_game()` eagerly — it only sets `awaiting_new_game = true` when there's no save, same as today. The actual load moves to the Continue button, as an explicit, checkable action rather than something that has already silently happened by the time a screen shows anything. `has_save()` (already exists) is what Continue's enabled state reads |
| `data/strings.json` (via the workbook, the usual XML-surgery pass) | New Text-tab rows: `intro.title`, `intro.continue`, `intro.new_game`. The overwrite warning reuses `office.new_game`/`office.new_game_warning`/`office.new_game_confirm` verbatim rather than adding a fourth |
| `data/sounds.json` | New `music_title` entry (blank file, same as every other named moment — silent until one is drawn/recorded) |
| `tests/interaction/intro_test.tscn` + driver (new) | Real clicks: no save → Continue disabled, New Game opens the picker directly; a save on disk → Continue is enabled and loads it into the Office as that protagonist, and New Game warns first and leaves the save untouched if you back out |
| `tools/shot_intro.gd`/`.tscn` + driver (new) | Same screenshot-tool convention as `shot_town_hall.gd` — walks all four states (no save, picker open, save present, overwrite warning) and photographs them |

Nothing in `scripts/rules/` changes — this is presentation only, the same
boundary every other screen in this project already keeps.

## 4. What does NOT change

- Office Management's own "New game" button (inside a run) — untouched,
  still the way to start over without quitting to the title screen first.
- Save timing/triggers (§8 of CLAUDE.md) — unchanged; this only moves
  *when the existing save gets read back in*, not when it's written.
- The protagonist picker itself, its warning-before-overwrite, its art,
  its starting-numbers sheet — all reused as-is (open question 1).

## 5. Build order (all done)

1. ~~`tools/build_intro_scene.gd` + the `.tscn` it produces.~~ **Built.**
2. ~~`scripts/ui/IntroScreen.gd`...~~ **Built**, plus the overwrite-warning
   `Overlay` (§0).
3. ~~`project.godot`'s main scene switch, and the `SaveManager._ready()`
   change.~~ **Built.**
4. ~~The three new Text-tab rows...~~ **Built** (real workbook, XML
   surgery, verified byte-identical against every other cell before the
   file was replaced, same as every prior pass).
5. ~~`tests/interaction/intro_test.tscn` + its driver.~~ **Built** — covers
   both save states and the overwrite warning, including backing out of it.
6. Full pipeline: export (0 errors), boot check (0 warnings), GUT suite
   (715/715), all 6 interaction tests including the new one, web-parity
   check (172/172). The 5 pre-existing interaction tests were confirmed
   unaffected, as predicted — they open their own scene directly and never
   go through `project.godot`'s main scene.
