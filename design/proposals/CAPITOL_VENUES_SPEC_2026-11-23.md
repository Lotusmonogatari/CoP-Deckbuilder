# Capitol venues: spec (2026-11-23)

Full design with diagrams: "Capitol Building and Capital Area: places system design" (claude.ai doc). Writing guide and the 120 draft lines: "Capitol venues: writing guide and content" (claude.ai doc). Screens: "Capitol venues: tips and gossip" (design canvas). This file is the part Claude Code builds in P16.

## 1. World flow

District Office ↔ Capitol Office (existing travel) → **Step out** → Capitol Building (Cafeteria VN01, National Assembly Library VN02, Capitol Gardens VN03) → Capital Area (Speech Coach VN04, Sapporo Stage VN05, Sapporo Super Station VN06). Walking is free (Rules: `venue_walk_hours_building` 0, `venue_walk_hours_area` 0). Venues open every day, only from the Capitol office, not during a level, not once the work week is full.

| Venue | Kind | P16 |
|---|---|---|
| VN01 Cafeteria | chat (Eat with Colleagues, 1 h) | Built |
| VN02 Library | read | Coming soon |
| VN03 Gardens | watch (People Watching, 1 h) | Built |
| VN04 Speech Coach | train (the existing Rhetoric Training page) | Built; leaves Office Management |
| VN05 Sapporo Stage | show | Coming soon |
| VN06 Super Station | travel | Coming soon |

## 2. Workbook

**Venues:** Venue ID, Name, Name JP, Romaji, Zone (Capitol Building or Capital Area), Order, Icon, Background, Blurb, Open Days (Any for now), Unlock (blank, `level:`, `date:`, `law:`, `doc:`).

**Venue Activities:** Activity ID, Venue ID, Kind, Name, Icon, Pool, Hours, Funds, XP, Per Day, Per Week, Condition Type / Target / Op / Value.

**Venue Lines:** Line ID, Pool (`cafeteria`, `gardens`, `dry`), Topic, Speaker (opponent, staff, visitor or Capital Area ID; `colleague`; blank = narration), Text, Condition Type / Target / Op / Value (as Office Notices, plus `party`, `law`, `seen`), On Date, Date From, Date To, Seasons, After Law (`BIxx passed` or `BIxx failed`), Weight, Once, Hint Kind (`stage_suit`, `opponent_suit` or blank), Hint Target (`STxx`, `OPxx` or blank = picked), Unlocks Doc, Effects (Event Choices reward columns, mostly blank).

**Text:** `hint.stage_suit.<suit>_<n>` with `{stage}`; `hint.opponent_suit.<suit>_<n>` with `{name}`; `venue.*`; `tips.*`. Suits: earnest, emotional, appeal, data_driven, divisive, duplicitous.

**Rules:** `venue_daily_set` 12, `venue_daily_heard` 8, `venue_hint_share` 1 in 8, `tips_max_held` 10, `tips_days` 14.

## 3. Lines and tips

1. Each day, each line-giving venue deals 12 lines from those eligible that day (conditions, dates, seasons, law), seeded by run and day. About 1 in 8 is a hint slot.
2. A visit costs its activity's hours once. Each Keep listening reveals the next dealt line, free, up to 8 per venue per day. After 8: one `dry` line; Keep listening greyed, "Come back tomorrow".
3. A hint slot picks an eligible target: a stage with a Favored Suit, or an opponent, in a level on offer at the Capitol this week or in the next Decision! scene. Stage tips use the stage's Favored Suit; opponent tips use suit_1. The phrasing is a random Text row for that kind and suit.
4. A heard tip is saved: target, suit, where heard, day. At most 10; a new one replaces the oldest; the same target refreshes its day. A tip expires after 14 days.
5. Tips show in the tip box, the Levels list's Tips button and pop-up, and on the briefing (the tipped room, or the room of a tipped opponent).

## 4. Writing rules (for CONTENT_GUIDE)

- One or two sentences, 8–25 words, no exclamation marks; dry and observational.
- Attributed lines: "Line." — Name. The speaker's lead suit sets the tone (Earnest plain, Emotional personal, Appeal rallying, Data Driven a figure, Divisive needling, Duplicitous a wink); party position sets the subject (governing: the coalition and ministries; opposition: its cracks).
- No organization named in plain gossip; a bill or stage only in a law line or a hint.
- A line about a moment fills its date, season or After Law.
- Hint phrasing keeps its token and never names the suit; at least three phrasings per suit per kind; a hint is a tilt, never a promise.
- Protagonists (OP06, OP22, OP35, OP40) are never speakers.
