# Coliseum of Parliament

A single-player, portrait-mode, turn-based card battler built in Godot 4
(GDScript). The player is a legislator who fights rhetorical battles —
committee hearings, floor debates, party caucuses, press conferences, town
halls, TV debates — with a hand of argument cards, in the fictional
parliamentary nation of Yezo.

Cameron (the designer) owns every design and canon decision. See
`CLAUDE.md` for the full build brief: hard constraints, canon rules, the
data contract, and the milestone log.

## Running it

Open the project in the Godot 4 editor (`project.godot` at the repo root),
or run it headless if Godot is on the PATH — `tools/get_godot.sh` downloads
one into `.tools/` if it is not. The main scene is the Office
(`scenes/office_hours/OfficeScreen.tscn`).

To check the whole project in one go — re-exports the workbook, boots the
game, checks every script compiles, runs the GUT tests, and clicks through the
UI with a real display (needs `xvfb-run`, about 2 minutes) — run:

```
tools/verify.sh            # everything
tools/verify.sh --quick    # data, boot, compile and unit tests only
```

Starting points: `design/NEW_CHAT_STARTUP.md` (the current state and working
rules), `design/CONTENT_GUIDE.md` (how to write levels, stages, events and the
content they depend on) and `design/EDITING_TEXT.md` (rewording existing text).

## Where things live

| | |
|---|---|
| `data/*.json` | The source of truth for all content, exported from the design workbook. Never hand-edited except a few files `tools/export_data.py`'s own comments mark as hand-maintained. |
| `design/Game_Workbook.xlsx` | The design workbook itself. Cameron's. |
| `design/proposals/` | Design docs and plans written for Cameron's review, one per feature area. |
| `scripts/rules/` | The battle and meta rules, as plain GDScript with no scene or autoload access — provably headless. |
| `scripts/autoload/` | Game state, the data loader, and the other singletons the screens read from. |
| `scripts/ui/`, `scenes/` | Everything the player sees. |
| `tests/` | GUT unit tests for `scripts/rules/`, plus a few real click-driven interaction tests under `tests/interaction/`. |
| `tools/` | The workbook exporter, the scene builders, and `verify.sh`. |
