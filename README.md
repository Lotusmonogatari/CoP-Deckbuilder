# Coliseum of Parliament

A single-player, portrait-mode, turn-based card battler built in Godot 4 (GDScript), set in Yezo, a fictional parliamentary nation of 101 seats. The player is a legislator who argues their way through committee hearings, floor debates, party caucuses, press conferences, town halls and TV debates with a hand of argument cards in six rhetorical suits, then carries bills to a Floor Vote. Between fights the Office turns results into strength: organization and party standing, backings, staff, cards, and a week of hours, dues and events.

Cameron (the designer) owns every design and canon decision. `CLAUDE.md` is the build brief: hard constraints, canon rules and working rules.

## Reading order

| Read | For |
|---|---|
| `design/GAME_DESIGN.md` | What the game is and how its parts connect |
| `design/GAME_SYSTEMS.md` | The exact mechanics: resources, growth and decline, choices, and every piece of run state |
| `design/INFORMATION_STANDARDS.md` | How the player must be told things |
| `design/ARCHITECTURE.md` | How the code is organised |
| `design/CONTENT_GUIDE.md`, `design/EDITING_TEXT.md` | Writing levels, stages, events and wording |
| `design/NEW_CHAT_STARTUP.md` | The current state and the working rules, for a new session |
| `design/CHANGELOG.md` | A summary of September and October 2026, then every dated change since |

## Running it

Open the project in the Godot 4 editor (`project.godot` at the repo root), or run it headless if Godot is on the PATH; `tools/get_godot.sh` downloads one into `.tools/`. The main scene is the Office (`scenes/office_hours/OfficeScreen.tscn`).

To check the whole project in one go (re-exports the workbook, boots the game, compiles every script, runs the GUT tests and clicks through the UI with a real display; needs `xvfb-run`; about 2 minutes):

```
tools/verify.sh            # everything
tools/verify.sh --quick    # data, boot, compile and unit tests only
```

## Where things live

| | |
|---|---|
| `data/*.json` | The source of truth for content, exported from the workbook. Never hand-edited except the few files the exporter's own comments mark as hand-maintained (`rules.json`, `booster_standing.json`, `party_standing.json`, `art.json`, `sounds.json`, `staff_names.json`, the two level override files and the playtest fixtures) |
| `design/Game_Workbook.xlsx` | The design workbook. Cameron's. Edited only with `tools/workbook/wbx.py` |
| `scripts/rules/` | The game's rules as plain GDScript with no scene or autoload access |
| `scripts/autoload/` | The data loader, run state, saves, text, audio and layout singletons |
| `scripts/ui/`, `scenes/` | Everything the player sees |
| `tests/` | GUT unit tests, and real click-driven tests under `tests/interaction/` |
| `tools/` | The workbook exporter and editor, verification, bots and audits, theme and scene builders |
| `design/proposals/`, `design/review/`, `design/bench/` | Working papers: plans, reviews and benchmark results kept for the record (several are historical; see `design/CLEANUP_CANDIDATES.md`) |
