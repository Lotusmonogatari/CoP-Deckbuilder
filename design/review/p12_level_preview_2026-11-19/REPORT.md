# P12 level preview: build report (2026-11-19)

Branch `panel/p12-level-preview`. **Not merged**, as asked. All wording on the screen is Claude's draft for Cameron.

## Executive summary

| Question | Answer |
|---|---|
| Which template was built? | **Hybrid, as Cameron chose:** Template A for the top (header, purpose, week bar, totals tiles, organizations card) and Template B's timeline for "Rooms, in order", one block per room. |
| Does it look the same in all three styles? | Same layout in Woodblock, Living Office and Broadcast; each style draws the badge, cards, tiles, buttons and edges its own way (palette in the UI Styles tab, rows `brief_*`). |
| Did any number change? | No. A test compares the new briefing's data with a record of the old one on all 114 levels at every Campaign Pressure. |
| Do the checks pass? | `tools/verify.sh` prints "All checks passed" (2,206 unit tests, every click test, text sweep in all three styles at all three text sizes: 0 letter-stacking or off-screen). |
| Anything that does not match a mockup? | Yes, 14 small differences, each with its reason, in the table below. Two bugs showed up in these pictures and were fixed (second table). |
| What waits for Cameron? | Rewriting the 31 draft Text rows; the "District office" badge (needs a Location column); whether to show "If you lose" costs again; the old Text rows listed in `CLEANUP_CANDIDATES.md`. |

## What is on the screen

| Part | Contents |
|---|---|
| Fixed at the top | "‹ Levels" (back to the list) |
| Header (scrolls) | Name, "Tier N · N rooms", the hours badge, the purpose line, the week bar with "This week: N hours left" and "N left after this level" |
| Totals card | "If you win every room": a tile for each meter, XP Growth and Funds, each with the level bonus in small type; a dashed note on when rooms and the bonus pay |
| Organizations card | "Organizations, if you win": icon, name and range; absent when the level changes none |
| Timeline | "Rooms, in order": hour ruler and rail, a block per room with a number square, name, kind and hours, reward chips, and the "carries on" line where true; a bonus marker at the end |
| Fixed at the foot | Back and **Go in · N hours** (greyed, with the game's reason, when the level cannot start) |

## Screenshots

The folder `shots/` holds **78 pictures at 720 px wide**: 63 top-of-screen pictures (7 cases × 3 styles × 3 sizes) and 15 scrolled-to-the-end pictures at the standard size for the cases that scroll. File names read `<case>_<size>_<style>_<top|end>.png`; sizes are `2340` (1080 × 2340), `1920` (1080 × 1920) and `large_text` (Large text setting at 1080 × 2340); styles are `woodblock`, `living_office`, `broadcast`.

| Case | Level | What it shows | Files start with |
|---|---|---|---|
| Typical | LV11, 3 rooms, 6 h | Everything: tiles with bonus lines, three organizations, three rooms, one that carries on after a loss, the bonus marker | `lv11_standard_` |
| One room | LV85, 1 room, 2 h | No timeline, no organizations card; the note speaks only of the rooms (no bonus) | `lv85_one_room_` |
| Hidden room | LV05, 4 of 5 rooms shown, 12 h | The Media Ambush is not named; its hours are in the 12 | `lv05_hidden_ambush_` |
| Longest | LV19, 10 rooms, 35 h | The whole timeline, scrolled; Go in says 35 hours | `lv19_longest_` |
| No organization changes | LV32, 5 rooms, 15 h | No organizations card; the note speaks only of the rooms | `lv32_no_org_changes_` |
| Cannot start | LV11 with 2 hours left in the week | Go in greyed and reading "Too long for the hours left"; the week bar full; "0 left after this level" | `lv11_cannot_start_` (top only) |
| Loss carries on | LV04, Press Conference in room 2 | "Losing this stage costs you, but the level carries on." | `lv04_loss_carries_on_` (see the `end` picture) |

## Beside the mockups

`compare/` puts the mockup on the left and the build on the right, for LV11, once per style: `top_<style>_...` (Template A against the top of the screen) and `timeline_<style>_...` (Template B's timeline against "Rooms, in order"). The mockups are the pictures in `design/proposals/img/level_preview/previews/png/`.

### What did not match, and why

| # | Mockup | Build | Why |
|---|---|---|---|
| 1 | "District office" badge at the top right | Not shown | There is no Location column yet. The data builder carries an empty `location`, and the badge appears when it is filled (two-offices build). The prompt said not to add the column. |
| 2 | "win all 3 for the bonus", "Win all three: level bonus", "The bonus comes only if you win all three." | "Each room pays when you win it. The bonus is paid when you win the level." and "Level bonus, paid when you win the level" | Cameron's correction. In the code a level is won when every room is reached without a loss that ends the level, so a room whose loss lets the level carry on does not cost the bonus. |
| 3 | A level with no bonus still shows the bonus sentence | The note says only "Each room pays when you win it." | Found in the LV85 picture: promising a bonus the level does not pay would break the information standards. One extra Text row, `briefing.how_it_pays_rooms`. |
| 4 | Loss costs not drawn in the mockups | Not shown; carried in the data | Cameron: leave them out for now. `INFORMATION_STANDARDS.md` is corrected (it said the briefing listed "If you lose" costs). |
| 5 | Funds drawn without a sign ("55,000円") | "+55,000円" | The build uses the game's own formatter for meter numbers (`Phrase.meta_amount`), so the briefing reads the same as the rest of the game. |
| 6 | "bonus in small type" caption on the totals card | Left out | It explains the screen to a reviewer; a player sees the small lines directly under each number. |
| 7 | Organization icons are illustrations | The game's own organization chips (round green icons) | The prompt asked to reuse `OrgChip`, so a tap names the organization and the art stays one set. |
| 8 | Titles at 28 px | 22 px (19 in Living Office, 26 in Broadcast), up to two lines | Antaka Brush Display draws wider than the font in the mockup page. Sizes were set per style to keep two lines. |
| 9 | Purpose speaker's name in bold | Same weight | The speaker and line come from one Text row, `briefing.purpose`; bold would need two rows. Only visible once staff are hired (no staff: narration, no name, as before). |
| 10 | Flag icon on the bonus marker; Template B lists the bonus amounts in it | One line of words | The amounts are already in the tiles and the organizations card (Template A on top), so the marker only ends the timeline. A flag glyph can be added with the other marks later. |
| 11 | Room titles on one line | Two or three lines in Living Office for long titles | The wide Display font and the kind label share the row. Nothing is cut off. |
| 12 | No scroll bar | A scroll bar when the level is tall; Woodblock, Living Office and Broadcast reserve its width | The project's own themes reserve space for scroll bars; cards stop a little short of the right edge on tall levels. |
| 13 | Flat colour behind everything | Flat colour | Same as the mockups. The build does not draw the BASE picture that other scrolling screens have behind them; the palette's contrast pairs are measured on the flat ground. Say if you want the picture back. |
| 14 | Week line and Levels link both at the top | Only the Levels link is fixed; the title, purpose and week scroll with the content | Template A's header is part of the content. The bottom bar holds Back and Go in only. |

### Two bugs the pictures caught (fixed)

| Picture | Bug | Fix |
|---|---|---|
| LV85 (one room) | The whole middle collapsed into a narrow column and every line stacked letter by letter | The scroll box gives its child the box's width only if that child asks to expand; it now does. A click test (`level_briefing_test`) covers a one-room level. |
| LV11 at Large text, Woodblock | The panel was wider than the phone, so the right edge of Go in ran off screen; the Living Office hours ring was too small for its word | The bonus marker now wraps (its single line set the panel's width), and the badge grows with the text-size setting. The click test checks, at Large text, that the scroll box, bottom bar, Go in and every control stay on screen. |

## Checks

| Check | Result |
|---|---|
| `tools/verify.sh` | **All checks passed** (export no errors, workbook check, boot, compile, 2,206 unit tests, click tests) |
| Data equivalence | `tests/test_level_briefing.gd`: all 114 levels, every Campaign Pressure: hours, rooms, rewards, totals, bonus and hidden rooms equal the record of the old briefing |
| Contrast | `tests/test_level_briefing_contrast.gd`: every text pair ≥ 4.5:1, greyed Go in ≥ 4.5:1, icons, bars and rails ≥ 3:1, in all three styles |
| Wording | `tests/test_level_briefing_wording.gd`: no `briefing.*` row says "win all" or "the whole level" (the two retired old rows are excluded) |
| Click tests | `level_briefing_test` (all three styles: header, tiles, organizations with names and ranges, a block per room in order, hour ruler, bonus marker, fixed foot, Go in carries the hours, Back closes, tall levels scroll only the middle, a full week greys Go in with the game's reason, hidden rooms stay hidden but count, a one-room level lists no rooms, Large text fits the screen); `level_bonus_test` rewritten for the new layout; loop, event-level, level-intro and inventory tests still pass |
| Text sweep | `tools/text_sweep.sh` in all three styles at Small, Normal and Large, both phone shapes: 0 letter-stacking, 0 off-screen. Three briefing screens are in it now (LV04, LV85 one room, LV19 longest) |
| Touch targets | `tools/ui_target_audit` now measures the briefing. Back and Go in are 133 px tall and "‹ Levels" 127 px, all above the 122 px (44 pt) line. The three organization icons are 72 px; tapping one only names the organization, whose name is printed beside it |
| Report-only rows | The sweep lists "OrgChip overlaps Back" for a few chips at 1080 × 1920 and Large text. Those chips are inside the scroll box, below the visible part, behind the fixed foot; the scroll box clips them, so nothing is pressable there. `LayoutWatch` does not know about scroll clipping |

## Not built, on purpose

- The Location badge ("District office"), until a Location column exists.
- Loss costs ("If you lose"), by Cameron's decision.
- Any change to what a level pays, its hours, or the rules of the week.

## For Cameron

- The 31 `briefing.*` Text rows and the 30 `brief_*` colour rows are Claude's drafts.
- The Text rows and code the old briefing used are in `design/CLEANUP_CANDIDATES.md`; nothing was deleted.
