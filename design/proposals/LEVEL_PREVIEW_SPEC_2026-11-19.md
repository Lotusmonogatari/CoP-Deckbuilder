# Level preview (briefing) redesign: two templates (design spec, 2026-11-19)

**Status:** draft for Cameron. Every wording below is a draft, and every new text row needs his OK.
**Mockups:** the design canvas "Level preview redesign: two templates" (https://claude.ai/artifact/T5Y24ratCVPodAusFT7qi9). Its artboard sources are in `mockups/`. They need the canvas runtime (`support.js`), which the canvas serves and can't be exported, so they don't open on their own. `previews/` has the same six screens as plain HTML that opens in any browser, plus PNG screenshots in `previews/png/`. The row-1 artboards are `Main` (A, Woodblock), `A_Living` and `A_Broadcast`. The row-2 artboards are `B_Planner` (B, Woodblock), `B_Living` and `B_Broadcast`.
**Today's screen:** `reference/current_briefing_LV11_woodblock.png` (LV11, Meeting with Student Organizers).
**Builds on:** branch `feature/level-bonus-briefing` (head 6f08f5a3, not merged at the time of writing). It added the Level Bonus section, `LevelBonusView.gd`, the `OrgChip` changes and their tests.

## 1. What is wrong today

| # | Problem | Effect |
|---|---|---|
| 1 | Every line is the same full-width dark bar (`UiKit.line`) | No hierarchy: the title, section labels and values look alike |
| 2 | The five rewards are listed three or more times: Total Rewards, Level Bonus, then once per room | A 3-room level is about two screens; a 6-room level is five or six |
| 3 | "Total Rewards" and "Level Bonus" sit side by side | Unclear which is earned room by room and which only for winning the whole level |
| 4 | Organization icons carry a range but no name | Players guess who "+2–4" is for |
| 5 | No week context | The screen doesn't say how many hours are left after the level (Standard 1: the cost before the choice) |
| 6 | "Total Workload Duration: 6 Hours" | Heavy wording for one number |

## 2. Shared rules (both templates, every style)

- **One screen** for a level of up to 3 shown rooms at 1080 × 2340, Normal text. Longer levels scroll the middle region only. The bottom bar stays fixed.
- **Header:**
  - Back to Levels (44 pt target), the level title, and a meta line ("Tier 1 · 3 rooms · win all 3 for the bonus").
  - An hours badge whose look depends on the style.
  - A **location badge**, shown only once the two-offices Location column exists. Until then, hide it. Don't fake it.
- **Purpose line:** shown once, with its speaker (`purpose`, `purpose_speaker`).
- **Week context:** "This week: {left} hours left · {after} left after this level", from the same numbers as `GameState.level_hours` and the week's hours left. Template A also draws a thin bar of the 40-hour week: used, this level, left after.
- **Rewards:**
  - A room's rewards are earned when that room is won (`BriefingSummary.stage_rewards`, `total_rewards`).
  - The level bonus is earned only by winning the whole level (the `bonus_win_range_*` fields, as `LevelBonusView` reads them).
  - The two are always labelled differently ("If you win every room" against "bonus"), and the bonus never appears inside a room.
- **Organizations:** each chip shows its icon, the organization's **name**, and the range ("+2 to +4"), from the `win_delta_boXX` fields. Reuse `OrgChip`, adding a name label.
- **Rooms:** listed in order, numbered, each with its hours and a kind label. "Conversation" means a non-combat room; "Debate" means a combat room.
  - A room whose `briefing.loss_continues` applies shows that line, small.
  - Rooms with `reveal_in_briefing` = No stay **hidden** and never hint at themselves. Their hours still count in the total, as today.
- **A level with one shown room:** totals only, no room list, as `BriefingSummary.lists_stages` does today.
- **Unset rewards:** keep today's `reward.stage_not_set` and `reward.nothing_set` lines.
- **Bottom bar:** Back (secondary) and "Go in · {hours} hours" (primary), at least 48 px tall. If the level can't start, the primary button is greyed out and shows `GameState.level_calendar_refusal()` text (Standard 2).
- **Terms (Standard 3):** Reputation, Constituency support, Party support, XP Growth, Funds 円. Keep the game's reward order: Reputation, Constituency support, Party support, XP Growth, Funds.

## 3. Template A: Summary card (totals first)

| Region | Content |
|---|---|
| Header | Back, location badge, title, meta line, hours badge |
| Purpose | One paragraph: "District Representative: “…”" |
| Week | Hours line plus a thin 40-hour bar |
| Card "If you win every room" | 3-column grid of 5 tiles: big total, label, and "{range} bonus" in small type. The 6th cell is a dashed note: "Each room pays when you win it. The bonus comes only if you win all three." |
| Card "Organizations, if you win" | One row each: icon, name, range |
| Card "Rooms, in order" | One row per room: number, name, hours, kind, and a one-line reward summary |
| Bottom bar | Back, "Go in · 6 hours" |

Best for deciding quickly whether a level is worth its hours. It grows by one short row per room.

## 4. Template B: Day planner (sequence first)

| Region | Content |
|---|---|
| Header | Back, location badge, title, purpose (no speaker label) |
| Strip "If you win every room" | Wrapping chips of the five totals |
| Timeline | An hour ruler on the left (0 h, 2 h, 4 h…), one block per room. Each block: number, name, kind and hours, then the room's rewards as chips. Block height follows the room's hours (about 49 px per hour at the canvas size) |
| Finish block "Win all three: level bonus" | A flag icon, the bonus ranges in one line, then the organization rows (icon, name, range) |
| Bottom bar | The week line above Back and "Go in · 6 hours" |

Best for seeing what you'll face, room by room. For 6 or more rooms the timeline scrolls.

## 5. The three styles (layout is identical; only the look changes)

The tokens come from `data/ui_styles.json` through `UiStyle`. The values below are what the mockups used.

| Element | Woodblock | Living Office | Broadcast |
|---|---|---|---|
| Ground | Washi `#EFE4CF` | Dark wood `#2B1D12` | Navy `#0B1220` |
| Cards | Paper `#F8F1E3`, 2 px ink border, vermilion offset shadow | Paper `#FFF8EC`, radius 18, soft shadow | `#141E33` with gold top and bottom lines (D2) |
| Title | Antaka Brush Display | Antaka Brush Display | Barlow Condensed italic 700, capitals |
| Body | Shippori Mincho B1 | Zen Kaku Gothic New | Noto Sans JP |
| Hours badge | Vermilion seal, tilted: "6 / hours" | Amber ring: "6 / hours" | Gold slanted chip: "6 HOURS" |
| Room numbers | Indigo squares | Amber circles | Gold squares |
| Primary button | Indigo plank | Amber pill | Gold slanted bar |
| Finish block (B) | Indigo | Amber | Gold, slanted |
| Week bar (A) | Ink outline, vermilion "this level" | Light outline, amber | Gold outline, gold |

If Cameron hasn't yet approved the three Google fonts (Q7 in the UI styles spec), fall back to the fonts the style uses today.

## 6. New text rows (drafts; the Text tab, never in scripts)

| Draft key | Draft English |
|---|---|
| `briefing.meta` | Tier {tier} · {rooms} rooms · win all {rooms} for the bonus |
| `briefing.meta.one` | Tier {tier} · 1 room |
| `briefing.week_left` | This week: {count} hours left |
| `briefing.week_after` | {count} left after this level |
| `briefing.win_every_room` | If you win every room |
| `briefing.bonus_range` | {low} to {high} bonus |
| `briefing.how_it_pays` | Each room pays when you win it. The bonus comes only if you win all {rooms}. |
| `briefing.orgs_if_win` | Organizations, if you win |
| `briefing.rooms_in_order` | Rooms, in order |
| `briefing.kind_conversation` | Conversation · no cards |
| `briefing.kind_debate` | Debate |
| `briefing.finish_bonus` | Win all {rooms}: level bonus |
| `briefing.go_in_hours` | Go in · {count} hours |

Rows this replaces (`briefing.level_hours`, `briefing.total_rewards`, `briefing.rewards`, `briefing.bullet`, and the Level Bonus rows) go on `design/CLEANUP_CANDIDATES.md`. Don't delete them.

## 7. Done means

- [ ] The chosen template matches its mockup in all three styles at 1080 × 2340, 1080 × 1920 and Large text.
- [ ] Screenshots of these cases:
  - LV11 (3 rooms)
  - a 1-room level
  - a level with a hidden Media Ambush (no hint of it)
  - the longest level (scrolls in the middle only)
  - a level with no organization changes
  - a level that can't start (greyed Go in with the reason)
  - a room with `loss_continues`
- [ ] The numbers shown equal today's: a test compares the old and new briefing's totals, bonus ranges and organization ranges for every level.
- [ ] The text sweep passes at every size; touch targets of 44 pt or more (`tools/ui_target_audit.py`); contrast 4.5:1.
- [ ] No sentence in a script; the new rows exported; `tools/verify.sh` prints "All checks passed".
