# P9: Three UI styles and End of Week Payments (Claude Code prompt)

**Before pasting:**
1. Copy the three companion files into `design/proposals/` in the repo:
   - `UI_STYLES_2026-11-17.md`
   - `END_OF_WEEK_PAYMENTS_2026-11-17.md`
   - `ui_styles_tokens_2026-11-17.json`
2. Export the canvas artboards as PNGs into `design/proposals/img/ui_styles/`: the `C_`, `A_` and `B_` Office, Battle, Levels and Zoom boards, plus `C_Styles`.

Then paste everything below the line into Claude Code at the root of `cop-deckbuilder`.

---

You are working on Coliseum of Parliament (Godot 4.5, GDScript). Read `CLAUDE.md` first and follow it. Cameron is the owner; "ask Cameron" means a popup question, and you wait for the answer.

## Read first

| File | Why |
|---|---|
| `design/proposals/UI_STYLES_2026-11-17.md` | The design spec: decisions D1 to D4, what a style is, screens, done list |
| `design/proposals/END_OF_WEEK_PAYMENTS_2026-11-17.md` | The Office payments box and the week-end breakdown |
| `design/proposals/ui_styles_tokens_2026-11-17.json` | Starting colours, fonts, sizes for each style |
| `design/proposals/img/ui_styles/*.png` | The mockups. Match their layout and tokens; their wording is draft |
| `design/INFORMATION_STANDARDS.md` | Standards 1, 2, 3 and 9 apply to every screen you touch |
| `scripts/rules/CosmeticPieces.gd`, `data/cosmetic_packages.json`, `OfficeScreen._build_cosmetics()` | The system the styles plug into |
| `scripts/rules/PartyDues.gd`, `scripts/rules/StaffLoyalty.gd`, `scripts/ui/DuesBox.gd` | What End of Week Payments shows |
| `scripts/ui/SlantBar.gd`, `SupportBar.gd`, `CueBanner.gd` | The gold lines Broadcast must keep |
| `scripts/ui/CardView.gd`, `CardBackView.gd`, `tests/interaction/card_faces_test.gd` | The card faces no style may change |

If the mockup PNGs are missing, ask Cameron for them; don't build a layout from the spec's words alone. If the spec and the code disagree, the code is the fact. Say so in the report and ask Cameron which should change.

## Fixed decisions (do not reopen)

1. **Three styles:**
   - **Living Office** is the default and is free.
   - **Broadcast** and **Woodblock** are unlocked in the Marketplace.
   - Players switch between owned styles at any time.
2. **Broadcast keeps the gold lines** on the support bar (top, bottom and threshold) and on the cue band (top and bottom). Reuse `SlantBar` and `CueBanner`; don't redraw them.
3. **Card fronts and backs are identical in every style.** Don't edit `CardView.gd`, `CardBackView.gd`, `data/art.json` "card_frames" or any card art. `card_faces_test` must pass unchanged in all three styles.
4. **End of Week Payments** replaces the Office dues box: party dues plus staff wages, with both parts shown.
5. **A style changes look and arrangement only.** No rule, number or Text row may depend on the style. Nothing in `scripts/rules/` may read it.

## Before you write code: ask Cameron (one popup, all at once)

| # | Question | Options to offer |
|---|---|---|
| 1 | Base branch? `main` lacks `claude/new-session-klhgm8` and `panel/p2-card-faces`. | Branch from `panel/p2-card-faces` (recommended: it has the card-face fix the done list relies on) / Branch from `main` |
| 2 | Build order? | Phase A then stop for review (recommended) / Phases A and B together |
| 3 | Add a `UI Style` column to the Cosmetic Packages tab and a new `UI Styles` tab for tokens? | Yes / Other approach |
| 4 | Prices and currency for Broadcast and Woodblock? | Free text |
| 5 | Save the style with the run, or per device like text size? | With the run (recommended, matches other cosmetics) / Per device |
| 6 | May I add Barlow Condensed, Shippori Mincho B1 and Zen Kaku Gothic New (SIL OFL) to `assets/fonts/`? | Yes / Use fonts already in the repo |
| 7 | Seats in Living Office battles: 20 seats of 5 people? | Yes / Other count |
| 8 | Are the Living Office room objects right (Phone = Events, Bookshelf = Reputation and Results, Notice board = Promises, Front desk = Staff, Errand list = Marketplace)? | Yes / Change |

Then create branch `panel/p9-ui-styles` from the chosen base.

## Phase A: style framework, Living Office, End of Week Payments

**A1. Framework**
- Add the `ui_style` slot to `CosmeticPieces.SLOTS`, and `has_piece()` support reading the new column. Empty means Living Office.
- Add `scripts/ui/UiStyle.gd` with:
  - `static func current() -> String`, returning "living_office", "broadcast" or "woodblock";
  - a signal or a hook so screens rebuild on the next screen change.
- Tokens:
  - Add the workbook tab through `tools/workbook/wbx.py` and export to `data/ui_styles.json` through `tools/export_data.py`.
  - Load the tokens in one place.
  - Seed them from the tokens JSON.
- Extend `tools/build_theme.gd` to build one theme per style:
  - `cop_theme_living.tres`, `cop_theme_broadcast.tres` and `cop_theme_woodblock.tres`;
  - today's `cop_theme.tres` becomes the Broadcast base.
- Switching style must not touch the save's numbers, deck or progress. `GameState`'s load must keep its existing "drop unowned equips" check for this slot.

**A2. End of Week Payments** (build this before the restyle, so all three styles draw the same content)
- Add one pure function in `scripts/rules/`. It returns the week-end breakdown (dues, owed, each wage, total, short-by, who goes unpaid) by calling `PartyDues` and `StaffLoyalty`, the same functions the week end calls.
- Change `DuesBox` to show the title, the total and "Dues … · Wages …". A tap opens the breakdown panel.
- Show the same breakdown in the week-end popup before the Work the Weekend / Go Home choice. If P4 item 1 is open, this closes it.
- Make all wording Text rows. The spec's section 5 has drafts; retire the old dues box rows through the workbook.
- Test: the preview equals the settlement line for line, including raised pay and a shortfall.

**A3. Living Office**, matching `C_*` mockups:
- **Office:**
  - room objects with lamp pins, using positions from a new hand-written `office_hotspots` key in `data/art.json` for both `OFFICE` and `OFFICE_UPGRADED`;
  - the "Open today's docket" card;
  - the calendar;
  - the narration bubble;
  - the End of Week Payments tray;
  - a gear for Administration.
  
  Every pin is at least 44 pt with its label always visible.
- **Battle:**
  - seats semicircle with exact numbers underneath;
  - speech-bubble cue (tap still skips; hold timing unchanged);
  - intent pill;
  - lamp energy dots;
  - the hand as a fan of real `CardView` fronts with every card visible for hand sizes 3 to 6;
  - drag-up 220 px to play and tap to zoom, unchanged.
- **Levels:** manila folders, tier tabs and a "+ Draft a bill" tab. A level that can't start shows `GameState.level_calendar_refusal()` text.
- **Card zoom:** the room backdrop, a paper note with the "In this room" result and cost, and the two buttons. The card face is untouched. The cue stays paused while the zoom is open.
- Every other screen takes the Living Office theme only.

**Gate A.** Stop, write the report, and wait for Cameron and the panel to review before Phase B.

## Phase B: Broadcast, Woodblock, buying and switching

- **B1. Broadcast**, matching `A_*` mockups:
  - slanted plates;
  - today's `SlantBar` support bar and `CueBanner` band with their gold lines;
  - red intent tag;
  - the hand as an overlapping row of real fronts;
  - gold slanted End Turn.
- **B2. Woodblock**, matching `B_*` mockups:
  - washi ground;
  - hanging-scroll cue;
  - 攻 / 守 / 得 intent seals;
  - framed bar with a threshold flag;
  - plaque buttons;
  - framed prints in the levels list.

  Check every glyph exists in the chosen font, and fall back to Noto Sans JP per glyph (the Antaka fonts lack − and ≥).
- **B3. Buying and switching:**
  - Add two Cosmetic Packages rows.
  - Add a Marketplace "Office styles" tab (mockup `C_Styles`) using `CosmeticPieces.buy_refusal()` and `cost()`, with a reason on every refusal.
  - The Appearance and Music panel can switch styles as it does other slots.
  - Footer text: "Card fronts and backs look the same in every style."

## Tests to add

| Test | Fails when |
|---|---|
| `tests/interaction/ui_style_parity_test.gd` | A restyled screen shows a different set of Text rows or numbers in one style than another |
| `tests/interaction/broadcast_gold_lines_test.gd` | In Broadcast, the support bar or cue band lacks its gold top or bottom line, or the threshold mark |
| `tests/interaction/card_faces_test.gd` (existing) | Run it once per style; it must pass unchanged |
| `tests/rules/week_payments_test.gd` | The preview and the week-end settlement differ |
| `tests/interaction/hand_visible_test.gd` | Any card in a hand of 3 to 6 is hidden or off screen, in any style |
| Style switch round-trip | Switching styles changes anything in the save other than the equipped slot |

## Screenshots (timed capture rule)

Shots go in `design/review/p9_ui_styles_<date>/` (add a `.gdignore` there). For each style, capture Office, Battle, Levels, card zoom and the Office styles tab at 1080 × 2340, 1080 × 1920 and Large text.

Capture Battle three times:
- with the cue band showing;
- after it clears (wait out the hold or tap);
- mid-drag with a card lifted.

Never infer what a screen shows from one frame. Name files `<style>_<screen>_<size>[_<moment>].png`.

## Rules

- Use the workbook for every number and word (`wbx.py`, then `export_data.py`). Don't hand-edit `data/*.json`, except the hand-written `art.json` keys.
- Ask Cameron before any schema, ID or canon change, or new fonts.
- Use no internal IDs on screen (Standard 3). Show costs before choices (Standard 1). Give a reason on every refusal (Standard 2).
- Make every touch target at least 44 pt (`tools/ui_target_audit.py`), and make every restyled screen pass at Large text.
- Run `tools/verify.sh` before each commit. Make small commits with clear messages.
- Update `GAME_SYSTEMS.md`, `ARCHITECTURE.md`, `CHANGELOG.md` and the `CLAUDE.md` index.
- Push the branch. Don't merge.

## Report (`design/review/p9_ui_styles_<date>/REPORT.md`)

1. Cameron's answers to the eight questions.
2. An acceptance table: each "Done means" line from both specs, then pass/fail, then the evidence (a test name or a shot file).
3. The `tools/verify.sh` result, and the commit hash for each phase.
4. Where you departed from a mockup, and why.
5. Contrast readings (text and icons) per style, measured from pixels.
6. Open issues for the panel.
