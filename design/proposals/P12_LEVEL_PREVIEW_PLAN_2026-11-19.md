# P12 plan: the level preview (briefing) redesign

Draft for Cameron's approval. **Nothing is built.** Branch `panel/p12-level-preview`. Spec: `design/proposals/LEVEL_PREVIEW_SPEC_2026-11-19.md` (the updated copy from the second package); mockup sources: `design/proposals/img/level_preview/mockups/`; plain-HTML previews and 1080 × 2337 pictures of all six: `design/proposals/img/level_preview/previews/`.

## Executive summary

| | |
|---|---|
| What you chose | **A hybrid**: Template A for the top and first visuals (header, purpose, week bar, totals tiles, organizations card), and **Template B's timeline for "Rooms, in order"** (an hour ruler and one block per room). One screen layout, no switch. |
| Words | The spec's 13 rows **with my corrections** (the bonus is "paid when you win the level", not "win all"), plus singular and plural rows, vote, visit and trade labels, and a weekend line. About 24 rows. All drafts for you to rewrite. |
| Loss costs | **Left out for now.** The data the new view receives keeps each room's loss cost, so a later change can show them. The standards document claims "If you lose" costs are shown, which is not true today, so I would correct that sentence. |
| Size | About 650 lines of code (pure data builder 150, view 300, styles 100, panel 100), about 250 lines of tests, 24 Text rows, a few UI Styles tokens. No schema change. |
| What stays | `OfficeScreen._show_briefing`'s reading of the data, `BriefingSummary`, `LevelBonus` and their tests. `LevelBonusView.rows()` stops being used by the screen and goes on the cleanup list (not deleted). |
| What I need | Your **go**, and a quick yes or no on the five small points at the end. |

## 1. The screen (the hybrid, top to bottom)

```
 Levels            [location badge: hidden until a Location column exists]
 Meeting with Student Organizers                           ( 6 )
 Tier 1 · 3 rooms                                         hours
 District Representative: "Student organizers want a hearing. ..."
 This week: 28 hours left            22 left after this level
 [=== used ===][== this level ==]........ left after ........     <- 40-hour bar
 +-- If you win every room -------------------------------------+
 | +2          | +11                    | +1                    |   tiles: big total,
 | Reputation  | Constituency support   | Party support         |   label, bonus range
 | +1 to +2 bonus | 0 to +1 bonus       | +1 to +4 bonus        |   in small type
 | +175        | 55,000円               | [Each room pays when  |
 | XP Growth   | Funds                  |  you win it. The bonus|
 | +15 to +30  | +3,000 to +12,000円    |  is paid when you win |
 |  bonus      |  bonus                 |  the level.]          |
 +--------------------------------------------------------------+
 +-- Organizations, if you win ----------------------------------+
 | (icon) Students United                              +2 to +4  |
 | (icon) Local Kōenkai                                0 to +1   |
 +--------------------------------------------------------------+
 Rooms, in order                                  <- Template B's timeline
  0 h |[1] Office Hours      2 hours · Conversation · no cards
      |    chips: Constituency support +5 · XP Growth +50 · Funds 10,000円
  2 h |[2] Town Hall        2 hours · Debate
      |    chips: Reputation +1 · ...
      |    (small) Losing this stage costs you, but the level carries on.   <- only where it applies
  4 h |[3] Policy Study Session ...
 ----------------------------------------------------------------------
 [ Back ]   [ Go in · 6 hours ]                                   <- fixed bottom bar
```

- **Header, purpose, week bar, tiles, organizations card:** from Template A. The two cards use each style's card look.
- **Timeline:** the hour ruler runs down the left; each block is numbered and shows the room's name, its hours and kind, and its rewards as small chips. Block height follows the room's hours with a floor (so a one-hour room is still readable), and the timeline **scrolls with the rest of the middle region**, never the header or the bottom bar.
- **No finish block with numbers.** Template B puts the bonus and organizations in a closing block. Here they are already in the tiles and the organizations card, so the timeline ends with a **slim finish marker** only (a flag and "Level bonus, paid when you win the level"). That avoids saying the same numbers twice.
- **Bottom bar:** Back (secondary) and "Go in · 6 hours" (primary), at least 48 px tall and fixed. When the level cannot start it is greyed out and shows the `GameState.level_calendar_refusal()` text.
- **Hidden rooms** (Media Ambush) never appear in the timeline or hint at themselves; their hours stay in the total and the week bar.
- **A one-shown-room level** shows the header, tiles, organizations and bottom bar, and **no timeline** (as `BriefingSummary.lists_stages` does today).
- **Unset rewards:** today's `reward.stage_not_set` and `reward.nothing_set` lines stay.

## 2. Files

### New

| File | What it is | Lines |
|---|---|---|
| `scripts/rules/LevelBriefing.gd` | **Pure** data builder: from the expanded level, the shown rooms, the Campaign Pressure and the week's numbers, returns one plain dictionary: title, tier, shown-room count, total hours, purpose and speaker, week (phase, pool, used, left, after), totals, bonus ranges, organization ranges, and a list of rooms (number, name, start hour, hours, kind, rewards, `loss_continues`, unset flag, and the room's loss cost, carried but not shown). It reuses `BriefingSummary` and `LevelBonus`; it contains no wording and no nodes. | about 150 |
| `scripts/ui/LevelBriefingView.gd` | Builds the nodes from the dictionary: header, purpose, week bar, tiles, organizations card, timeline, finish marker, bottom bar. Every sentence is a Text row. Organization rows use `OrgChip` for the icon, with the name and range beside it. | about 300 |
| `scripts/ui/LevelBriefingStyles.gd` | The per-style presenter (section 3). | about 100 |
| `scripts/ui/LevelBriefingPanel.gd` | `extends Overlay`, so every caller and test that treats panels as Overlays keeps working. A fixed header and bottom bar with only the middle scrolling. Same `closed` and `confirmed` signals; adds `open_brief(view)`. | about 100 |
| `tests/test_level_briefing.gd`, `tests/fixtures/level_briefing_golden.json`, `tests/test_level_briefing_contrast.gd`, `tests/interaction/level_briefing_test.tscn`, `level_briefing_test.gd`, `level_briefing_driver.gd` | The tests (section 4). | about 250 |

### Edited

| File | Change |
|---|---|
| `scripts/ui/OfficeScreen.gd` | `_show_briefing()` keeps its reading (expanded level, shown stages, the reveal rule) and now builds the dictionary and calls `_briefing_panel.open_brief(view)`. The row-building code and `_reward_bullets` leave the screen. `_on_start`, `_on_briefing_closed` and the event-launch path are untouched. |
| `scenes/office_hours/OfficeScreen.tscn` | One line, by hand: the `BriefingPanel` node's script becomes `LevelBriefingPanel` (the scene is edited by hand, as the brief says). |
| `scripts/ui/OrgChip.gd` | A small helper for the icon-only chip beside a name (no number on the icon), if the existing `make(..., numbered=false)` is not enough. |
| Workbook: Text and UI Styles tabs (via `wbx.py`) | About 24 Text rows; a few UI Styles tokens if the mockups need a colour the tab lacks (for example Broadcast's tile fill). |
| `design/GAME_SYSTEMS.md`, `design/INFORMATION_STANDARDS.md`, `design/CHANGELOG.md`, `CLAUDE.md` index, `design/CLEANUP_CANDIDATES.md` | Docs (section 6). |

## 3. How each style draws it

The layout is identical in all three styles; only the look changes, as in P9. The view asks `UiStyle.current()` while it builds and takes colours and numbers from `UiStyle.colour(...)` and `UiStyle.number(...)`, the way `DuesBox` and `CalendarSquare` do. `LevelBriefingStyles.look(style)` returns one small dictionary of what differs, so the view has no `if style == ...` scattered through it.

| Element | Woodblock | Living Office | Broadcast |
|---|---|---|---|
| Ground | `colour.ground` | `colour.panel` | `colour.ground` |
| Cards and tiles | `colour.paper`, ink border (`border_px.ink`), vermilion offset shadow; tiles on the ground colour | `colour.paper`, rounded (`radius_px.panel`); tiles `colour.paper_alt` | `colour.panel`, gold lines top and bottom; tiles a darker panel (a new token) |
| Title and headings | Antaka Brush Display | Antaka Brush Display | Barlow Condensed italic, capitals |
| Body | Shippori Mincho B1 | Zen Kaku Gothic New | Noto Sans JP |
| Hours badge | Vermilion seal, tilted (`StyleMarks` SEAL) | Amber ring | Gold slanted chip (`StyleMarks` DIAGONAL, `slant_px`) |
| Room numbers and ruler | Indigo squares | Amber circles | Gold squares |
| Go in | Indigo plank | Amber pill | Gold slanted bar |
| Week bar | Ink outline, vermilion for this level | Light outline, amber | Gold outline and fill |

The three fonts are already in `assets/fonts` (added 2026-11-17), so the spec's fallback is not needed. Sizes follow the styles' `size_pt` tokens and the text-size setting.

## 4. Tests

| Test | What it proves |
|---|---|
| **Golden equivalence** (`test_level_briefing.gd` with `tests/fixtures/level_briefing_golden.json`) | **Before I change any code**, a throwaway script records today's numbers for all 114 levels from the current briefing path: total hours, shown-room totals, each room's rewards, the bonus ranges on all three Campaign Pressures, and the organization ranges. The file is committed. The test then checks the new dictionary equals it for every level. This is the "equals what today's briefing shows" check, against a fixed record of today. |
| Pure data tests | A hidden room is absent from the rooms list and the shown count but present in the hours; a one-room level has no timeline; the room kind is right for combat, non-combat and vote rooms; `loss_continues` is set only for combat rooms whose loss does not end the level; the week numbers are right in a work week and at the weekend; the refusal text comes through; no wording contains "win all". |
| **Contrast** (`test_level_briefing_contrast.gd`) | Every text-on-fill pair the view uses has contrast 4.5:1 or better in all three styles (3:1 for icons), computed from the tokens. |
| **Real clicks** (`level_briefing_test`) | For LV11 in each style: the header, tiles, organization names and ranges, three timeline blocks, the fixed bottom bar; the Go in label "Go in · 6 hours"; a tap on Go in starts the level; Back closes. A level that cannot start shows the greyed button with its reason. A long level scrolls only the middle: the header and the bottom bar do not move. |
| Existing checks | The text sweep (every screen at every text size and style, which already opens LV04's briefing), the style-parity and aspect tests, `tools/ui_target_audit.py` (touch targets of 44 pt or more) and `tools/verify.sh` ("All checks passed"). The earlier `level_bonus_test` and `test_level_bonus` keep passing: `LevelBonus` is unchanged, and the old rows builder stays as the reference. |

## 5. Screenshots and the report

- **Cases:** LV11; a one-room level; a level with a hidden Media Ambush; the longest level (LV19: 10 rooms, 35 hours); a level with no organization changes (45 of the 114); a level that cannot start (a full week, set up by a throwaway driver, since the level list greys those levels out); a room with `loss_continues` (LV11's Policy Study Session).
- **Sizes:** 1080 × 2340, 1080 × 1920 and Large text, in all three styles: 63 pictures, saved at 720 px wide, in `design/review/p12_level_preview_2026-11-19/`.
- **`REPORT.md`** sets each screenshot beside the mockup pictures in `previews/png/` (the second package, 1080 × 2337). Because the layout is a hybrid, no single mockup matches it, so each comparison shows the matching **crops**: the top of the A picture beside the top of the screenshot, and the timeline of the B picture beside the timeline. Those mockup pictures used fallback fonts for Shippori Mincho B1 and Zen Kaku Gothic New (the repo has both), so letter shapes will differ a little; the layout, spacing and colours are what the comparison checks. The report also says what did not match and why.

## 6. Documents

- `GAME_SYSTEMS.md`: the briefing's description (week context, Level Bonus, the timeline).
- `INFORMATION_STANDARDS.md`: the briefing row. **It says "If you lose: …" costs are shown. They are not, and your answer is to leave them out for now**, so I would correct the sentence to say they are not yet shown. Doc only.
- `CHANGELOG.md` section and one `CLAUDE.md` index line.
- `CLEANUP_CANDIDATES.md`: the Text rows the screen stops using (`briefing.level_hours`, `briefing.total_rewards`, `briefing.rewards`, `briefing.bullet`, `briefing.stage_hours`, `briefing.stage_fallback`, `briefing.level_bonus`, `briefing.level_bonus_orgs`, `briefing.xp_growth_range`, `reward.delta_range`, `reward.chip_range`) and `LevelBonusView.rows()`. Nothing deleted.

## 7. The new Text rows (drafts, with the corrections)

| Key | Draft English |
|---|---|
| `briefing.meta` / `.one` | Tier {tier} · {count} rooms / Tier {tier} · 1 room |
| `briefing.week_left` / `.one` | This week: {count} hours left / This week: 1 hour left |
| `briefing.weekend_left` / `.one` | This weekend: {count} hours left / This weekend: 1 hour left |
| `briefing.week_after` | {count} left after this level |
| `briefing.win_every_room` | If you win every room |
| `briefing.bonus_range` / `briefing.bonus_fixed` | {low} to {high} bonus / {amount} bonus |
| `briefing.how_it_pays` | Each room pays when you win it. The bonus is paid when you win the level. |
| `briefing.orgs_if_win` | Organizations, if you win |
| `briefing.rooms_in_order` | Rooms, in order |
| `briefing.kind_conversation` / `kind_debate` / `kind_vote` / `kind_visit` / `kind_trade` | Conversation / Debate / Vote / Member visit / Trade (the spec's section 6 says "Conversation · no cards", but all six mockups show plain "Conversation · 2 h", so I follow the mockups) |
| `briefing.finish_bonus` | Level bonus, paid when you win the level |
| `briefing.go_in_hours` / `.one` | Go in · {count} hours / Go in · 1 hour |
| `briefing.hour_mark` | {count} h |
| `briefing.back_levels` | Levels |
| `briefing.badge_hours` / `.one` | hours / hour |
| `briefing.purpose` | {speaker}: “{line}” |

## 8. Order of work (after your go)

1. Record the golden numbers from today's code and commit them.
2. The pure data builder and its tests.
3. The Text rows and UI Styles tokens (`wbx.py`, then export with `--accept-wording`).
4. The styles presenter, the view and the panel; the one scene line; `_show_briefing`.
5. The click and contrast tests; the screenshots driver (deleted before the commit); the report.
6. Docs, the full `tools/verify.sh`, push `panel/p12-level-preview`, and stop. **No merge.**

## 9. Small points to confirm (my defaults in bold)

1. **The finish marker:** a slim marker with no numbers (not Template B's full finish block), because the tiles and the organizations card already carry them. **Yes.**
2. **Block height:** follows the room's hours with a minimum, so the longest level scrolls (the middle region only). **Yes.**
3. **Back twice:** the header's "Levels" link and the bottom bar's Back both go to the level list, as in the mockups. **Keep both.**
4. **Level that cannot start:** reachable only from an event today (the level list greys such levels out), so the greyed Go in is built for that case and photographed with a driver. **Yes.**
5. **"Conversation" without "· no cards"**, as the mockups show it, not as the spec's text-row table says. **Follow the mockups.**
