# CoP-Deckbuilder

*Coliseum of Parliament* — a single-player, portrait-mode, turn-based card
battler set in Yezo. Built in Godot 4, GDScript only.

The full design brief is in [`CLAUDE.md`](CLAUDE.md). It is the source of
truth for rules, canon, and milestones.

## What's here so far

| Milestone | Status |
|---|---|
| M0 — project setup, data export, validation, placeholder art, font | done |
| M1 — headless rules engine + tests | done |
| M2 — Floor Debate battle UI | not started |

## Where things live

| Path | What it is |
|---|---|
| `design/` | The design workbook. **The source of truth for all content.** |
| `design/proposals/` | Proposed workbook changes awaiting Cameron's review. Not read by the game. |
| `data/` | JSON exported from the workbook, plus the hand-written `rules.json`. |
| `scripts/rules/` | Pure game rules. No UI, no Godot nodes. Fully unit-tested. |
| `scripts/autoload/` | Always-loaded singletons: data, events, game state, saving. |
| `scripts/ui/` | Screen and component scripts. |
| `scenes/` | Godot scenes, grouped by screen. |
| `tools/` | The workbook exporter and helper scripts. |
| `tests/` | Unit tests for `scripts/rules/`. |

## Changing game content

Never edit `data/*.json` by hand — the exporter overwrites it. Instead:

1. Edit `design/CoP_Starter_Card_Stage_Data.xlsx`.
2. Run `python3 tools/export_data.py`.
3. Read the validation report it prints. Fix any errors it names.
4. Commit both the workbook and the regenerated JSON together.

The one exception is `data/rules.json`, which is hand-written. It holds the
switches for design decisions that are still open — see `CLAUDE.md` section 9.

## Playing it

Open the project folder in Godot 4.5.1 or newer and press **F5**. That runs
Module 01's floor debate: 101 seats, 51 to win, eight turns.

Tap a card to look at it properly, then "Play this" to commit to it — tapping
a card never plays it by accident. "Details" shows your deck and discard
counts. When the debate ends, "Close" quits.

To see the data report instead — every file loading, every cross-reference
checked, and the Japanese font — open `scenes/menus/BootCheck.tscn` and press
**F6**, which runs just that scene.

## Running the checks

```sh
tools/get_godot.sh     # one-time: downloads Godot into .tools/ (gitignored)
tools/verify.sh        # export + validate + run all unit tests
```

`verify.sh` is the single command that proves the project is healthy. It
exits non-zero if anything fails.
