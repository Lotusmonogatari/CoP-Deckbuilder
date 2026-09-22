# CoP-Deckbuilder

*Coliseum of Parliament* — a single-player, portrait-mode, turn-based card
battler set in Yezo. Built in Godot 4, GDScript only.

The full design brief is in [`CLAUDE.md`](CLAUDE.md). It is the source of
truth for rules, canon, and milestones.

**Build status as of 2026-09-21.** 437 unit tests passing, four automated
checks green, and the browser playtest agreeing with the Godot engine on all
148 shared assertions.

---

## What you can play today

Six levels, twenty-four stages, nine kinds of room, fifty-four cards.

| Level | Stages | What it is |
|---|---|---|
| LV01 Committee Hearing | 2 | A study session, then the committee itself |
| LV02 Bill on the Floor | 2 | The chamber, then the cameras waiting outside |
| LV03 Media Marathon | 2 | A conference and a studio, back to back |
| LV04 Policy Research Circuit | 5 | Five rooms in a day, the last one an ambush |
| LV05 Party Bill Advocacy | 4 | Win the party first, then the country |
| LV06 Sponsored Fisheries Bill Gauntlet | 9 | The long one |

A run starts in the Office, where you pick a level, change your deck, and
spend what you have earned. Winning a stage moves your standing — constituency
support, reputation, funds, party support — and the next stage is fought with
the standing you actually have.

## Milestones

| Milestone | Status |
|---|---|
| M0 — project setup, data export, validation, placeholder art, font | **done** |
| M1 — headless rules engine + tests | **done** |
| M2 — Floor Debate battle UI | **done** |
| M3 — Committee and Party Caucus | **done** |
| M4 — Office hours, level runner, meta-variables, auto-save | **part done** — the Office, the level runner and the meta-variables work. **Saving does not exist yet**, so closing the app loses the run. Office hours (ST07) and its visitor events are not built |
| M5 — XP checkpoint shop | **part done** — the shops, the prices and the deck screen all work. The economy is switched off for playtesting: `open_collection` in `GameState` hands you every card, so XP has nothing to buy |
| M6 — Android export, then iOS | not started |

Also built, ahead of the schedule in the brief: the press conference, the TV
debate, the town hall, the policy study session, the media ambush and the
lobbyist meeting; the shoji card frames; the browser playtest build.

### Known gaps, deliberately

- **No saving.** `SaveManager` is a stub. A run lives for one sitting.
- **Four rules from brief §8 do nothing.** The Town Hall trigger, the Steering
  Committee trigger, the funding freeze and the party-support modifiers are
  written and tested but nothing calls them. They wait for M4. `MetaRules.gd`
  says so at the top, so a green test run is not mistaken for a finished
  feature.
- **Six of the fifteen modifiers are inert.** They need level-wide machinery
  that arrives with M4. The shop says "Not active yet" rather than selling
  something that does nothing.
- **The game is silent.** The audio wiring is complete and there are no sound
  files. See `assets/audio/README.md`.
- **Character art is placeholder.** Coloured rectangles labelled with the
  asset ID. Portrait expressions are wired and change the placeholder, so
  dropping in a PNG is the whole job.

### Balance findings, for Cameron

Measured, not guessed, and left alone because balance is his call:

- **LV06's floor debate is won about 2 times in 20** by a bot that spends what
  it has. It may be intended to be brutal; it is worth knowing it is.
- **The TV debate is a reliable reputation loss.** It opens at 45 against a
  baseline of 50 and closes around 30, so playing it costs standing whatever
  you do.

---

## Where things live

| Path | What it is |
|---|---|
| `design/` | The design workbook. **The source of truth for all content.** |
| `design/proposals/` | Proposed workbook changes awaiting Cameron's review. Not read by the game. |
| `data/` | JSON exported from the workbook, plus the hand-written files below. |
| `scripts/rules/` | Pure game rules. No UI, no Godot nodes. Fully unit-tested. |
| `scripts/autoload/` | Always-loaded singletons: data, events, game state, audio, saving. |
| `scripts/ui/` | Screen and component scripts. |
| `scenes/` | Godot scenes, grouped by screen. |
| `tools/` | The workbook exporter, the web build, and helper scripts. |
| `tests/` | Unit tests for the rules, plus interaction tests that click real screens. |
| `web/` | The browser playtest. See [`web/README.md`](web/README.md). |

### The hand-written data files

Most of `data/` is generated and must never be edited by hand. These five are
the exceptions — the exporter leaves them alone:

| File | Why it is hand-written |
|---|---|
| `rules.json` | The switches for design decisions still open (brief §9) |
| `player.json` | Who the protagonist is. A placeholder until Cameron casts one |
| `levels.json`, `playtest_level.json` | The playtest levels, whose shape is still being tried |
| `stage_types.json` | The nine kinds of room and their defaults |
| `sounds.json` | What plays when. Every filename is blank, so the game is silent |
| `modifier_effects.json`, `intent_patterns.json` | Bridges standing in until the workbook carries the column. Each says so in its own README |

## Changing game content

Never edit the generated `data/*.json` by hand — the exporter overwrites them.

1. Edit `design/CoP_Starter_Card_Stage_Data.xlsx`.
2. Run `python3 tools/export_data.py`.
3. Read the validation report it prints. Fix any errors it names.
4. Run `python3 tools/build_web_playtest.py` so the browser build matches.
5. Commit the workbook and the regenerated JSON together.

## Playing it

**In Godot.** Open the project folder in Godot 4.5.1 or newer and press
**F5**. You start in the Office.

Tap a card to look at it properly, then "Play this" to commit — tapping a card
never plays it by accident. "Details" explains the room you are in, including
the things that are at their defaults. "Office Management" is the one door to
everything you can spend.

**In a browser.** Open `web/playtest.html`, or the published link. Same rules,
same data, no install. It scrolls to a line at the bottom reporting how many
assertions the two engines agree on.

**The data report.** Open `scenes/menus/BootCheck.tscn` and press **F6** to
see every file loading, every cross-reference checked, and the Japanese font.

## Running the checks

```sh
tools/get_godot.sh     # one-time: downloads Godot into .tools/ (gitignored)
tools/verify.sh        # export, validate, boot, unit tests, and click the buttons
```

`verify.sh` is the single command that proves the project is healthy. It does
four things and exits non-zero if any of them fail:

1. Re-exports the workbook and validates every cross-reference.
2. Boots the game and confirms the data, font and art loaders work.
3. Runs the unit tests.
4. Clicks through a whole level on a real screen, under `xvfb`.

## Still Cameron's to decide

Listed here so they do not get lost. None of these are blocked on code:

- The **`Effect key` column** in the Modifiers tab, so the bridge file can go.
- The **Visitors sheet**, for Office hours (ST07).
- The **Yoron starting values** — every topic still sits at 50, so every
  bill's difficulty works out to zero and the system does nothing.
- The **six levels' reward numbers**.
- The **`Modifier surcharge` formula bug** — it compares a numeric Tier column
  against the text `"Tier 2"`, so it never matches.
- **`win_text` for LV03 and LV04**.
- A **stage type for ST08**, the Party Steering Committee, if that trigger is
  to be wired at M4. There is no such type in `stage_types.json` today.
- The **protagonist's identity and party** (brief §9). `player.json` holds
  "Hiro, Frontier Party" as a placeholder, chosen so the screens have a name
  to show. Frontier Party is canon — it is OP02's — so nothing is invented.
