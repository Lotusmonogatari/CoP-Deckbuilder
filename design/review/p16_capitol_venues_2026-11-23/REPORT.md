# P16 report: Capitol venues, phase 1 (draft for Cameron, 2026-11-23)

Branch `feature/p16-capitol-venues`. **Not merged.** Writing is Claude's draft (the 90 lines and 56 hint and UI Text rows are your package, in as written, as you answered).

## Executive summary

| Question | Answer |
|---|---|
| Built | Step out, the place map, the Cafeteria and the Gardens (lines, tips), the Tips button and pop-up, level badges, briefing marks, and the Speech Coach as a Capital Area venue. Rhetoric Training left Office Management. |
| Greyed as Coming soon | **National Assembly Library, Sapporo Stage, Sapporo Super Station** (VN02, VN05, VN06). |
| Pictures | 30 screenshots in this folder (ten screens, three styles), `<style>_<screen>.png`; the seven mocked-up screens are compared with the mockup shots below. |
| Checks | Unit tests, the click test `venue_test`, the text sweep (118 screens, 0 stacking or off-screen), the touch-target audit (new screens as the others), chip contrast 4.5:1. |

## IDs used

VN01 to VN06, VA01 to VA06, VL001 to VL090 (your package's IDs, unchanged). Text keys: `hint.*` (40), `venue.*`, `tips.*`. Rules: `venue_walk_hours_building`, `venue_walk_hours_area`, `venue_daily_set`, `venue_daily_heard`, `venue_hint_share`, `tips_max_held`, `tips_days`. Art IDs on the checklist: six `CAPITOL_*` and `AREA_*` backgrounds, six `VEN_*` icons, six `ACT_*` icons.

## Screens beside the mockups

Mockup shots are in `design/proposals/img/capitol_venues/previews/shots/`.

| Screen | Style | Built | Mockup |
|---|---|---|---|
| Tip heard (Cafeteria) | Woodblock | ![](./woodblock_tip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tip_woodblock.png) |
| Tip heard (Cafeteria) | Yezo Office / Living | ![](./living_office_tip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tip_living.png) |
| Tip heard (Cafeteria) | Broadcast | ![](./broadcast_tip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tip_broadcast.png) |
| Gossip | Woodblock | ![](./woodblock_gossip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_gossip_woodblock.png) |
| Gossip | Yezo Office / Living | ![](./living_office_gossip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_gossip_living.png) |
| Gossip | Broadcast | ![](./broadcast_gossip.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_gossip_broadcast.png) |
| Overheard in the Gardens | Woodblock | ![](./woodblock_overheard.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_overheard_woodblock.png) |
| Overheard in the Gardens | Yezo Office / Living | ![](./living_office_overheard.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_overheard_living.png) |
| Overheard in the Gardens | Broadcast | ![](./broadcast_overheard.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_overheard_broadcast.png) |
| Dry state | Woodblock | ![](./woodblock_dry.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_dry_woodblock.png) |
| Dry state | Yezo Office / Living | ![](./living_office_dry.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_dry_living.png) |
| Dry state | Broadcast | ![](./broadcast_dry.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_dry_broadcast.png) |
| Briefing mark | Woodblock | ![](./woodblock_briefing.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_briefing_woodblock.png) |
| Briefing mark | Yezo Office / Living | ![](./living_office_briefing.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_briefing_living.png) |
| Briefing mark | Broadcast | ![](./broadcast_briefing.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_briefing_broadcast.png) |
| Levels list | Woodblock | ![](./woodblock_levels.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_levels_woodblock.png) |
| Levels list | Yezo Office / Living | ![](./living_office_levels.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_levels_living.png) |
| Levels list | Broadcast | ![](./broadcast_levels.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_levels_broadcast.png) |
| Tips you hold | Woodblock | ![](./woodblock_tips.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tips_woodblock.png) |
| Tips you hold | Yezo Office / Living | ![](./living_office_tips.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tips_living.png) |
| Tips you hold | Broadcast | ![](./broadcast_tips.png) | ![](../../proposals/img/capitol_venues/previews/shots/Venues_tips_broadcast.png) |

Also drawn: `<style>_map.png` (the place map), `<style>_cafeteria.png` (a venue's screen) and `<style>_coach.png` (the Speech Coach's Rhetoric Training page).

## Not built as written, or different from the mockups

| Item | What I did |
|---|---|
| Line pop-up buttons | The pop-up card stacks Keep listening above Back (the card's foot), where the mockup puts Back and Keep listening side by side. |
| Tip box | No light-bulb icon (none drawn); the saved line for an opponent reads "Saved: shown when you next face {name}." instead of the mockup's card-specific line. The sentence `venue.tip_responds` lost its `{suit}` token (the suit is the chip beside it). |
| Levels list | The Levels list is not yet on the Office frame, so it has no Here / Done tabs; the Tips button with its count sits under the hours line and each tipped level has a "1 tip" line. |
| Opponent tips in the briefing | The briefing and the fight draw their opponents separately, so an opponent's tip is marked on every room they may sit in, not only the room they will. |
| `venue_hint_share` | Stored as 8 (one in eight), not the text "1 in 8". |
| `tips.rule` | Reads the 14 and the 10 from the Rules rows (`{days}`, `{max}`), so it says "14 days", not "2 weeks". |
| Cafeteria hints | The hint rows have no speaker, so a Cafeteria tip shows as narration; the Gardens tip leads with "You overhear two aides on the bench behind the hedge." as mocked. |
| Venue Lines columns | `Unlocks Doc`, `Effects` and the Venues `Unlock` column are imported but nothing reads them yet. |
| Line count | The package's "Read me" tab says 120 lines; the sheet and the brief have 90, which is what is in. |
| Pictures | None drawn: the venue screens show labelled placeholders (`CAPITOL_CAFETERIA` and so on). |

## Decisions for you

1. **Gardens only leads with "You overhear..." for tips.** Plain Gardens lines show as narration. Do you want the lead on every Gardens line?
2. **Opponent tips**: marking every room the person may sit in is honest but wider than "on their room". Mark only when the person is certain to be there (a pinned or Decision! opponent)?
