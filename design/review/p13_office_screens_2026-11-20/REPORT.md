# P13 Office screens: report (draft, grows with each commit)

Branch `panel/p13-office-screens`. Mockups are in `design/proposals/img/office_screens/previews/png/`. Screenshots here are the real game at 1080 x 2340, 1080 x 1920 and Large text, made with `tools/office_screen_shots.tscn` (command in its header).

## Commits

| # | Commit | State |
|---|---|---|
| 1 | The shared frame (`OfficeScreenFrame`, `OfficeFrameStyles`, `Overlay.open_frame`) | Gate passed |
| 2 | Administration (and two click tests updated on purpose) | Gate passed |
| 3 | Reputation and Results | Gate pending |

## Your answers

| Question | Answer |
|---|---|
| Branches | Two `panel/` branches |
| Where Resign lives | Stays in Reputation and Results (so it is **not** on the Administration screen) |
| Where it sits on the Overview tab | Top |
| Text rows | Add as written, drafts for you to reword |
| Events "Coming up" reader | Yes |

## Administration (commit 2)

| Style | Mockup | Built (1080 x 2340) | 1080 x 1920 | Large text | Bottom, Political Pressure at Harder |
|---|---|---|---|---|---|
| Woodblock | ![](../../proposals/img/office_screens/previews/png/administration_woodblock_full_length.png) | ![](administration_woodblock_1080x2340.png) | ![](administration_woodblock_1080x1920.png) | ![](administration_woodblock_large.png) | ![](administration_woodblock_bottom_harder.png) |
| Living Office | ![](../../proposals/img/office_screens/previews/png/administration_living_full_length.png) | ![](administration_living_office_1080x2340.png) | ![](administration_living_office_1080x1920.png) | ![](administration_living_office_large.png) | ![](administration_living_office_bottom_harder.png) |
| Broadcast | ![](../../proposals/img/office_screens/previews/png/administration_broadcast_full_length.png) | ![](administration_broadcast_1080x2340.png) | ![](administration_broadcast_1080x1920.png) | ![](administration_broadcast_large.png) | ![](administration_broadcast_bottom_harder.png) |

### What differs from the mockup, and why

| Difference | Why |
|---|---|
| The "Saved" chip is always shown | Your decision of 2026-11-20. The game keeps no "last saved" state, so it is a fixed label; every button press saves. |
| Scroll speed row is new on this screen | The spec's Display group lists it; the old menu only had it in the stage menu. Haptics (also only in the stage menu) is not in the spec's list, so it is not here. |
| Load Game and Undo rows appear only when there is a saved game or something to undo | Exactly as the old menu did. The mockup shows Load Game with a summary chip; the summary text stays in the Load confirmation, as before. |
| The Calendar, Music and Office Background rows all open Appearance and Music | The spec says Calendar opens it; the other two do the same. Music shows Default because no music package exists yet. |
| "Report a problem" is a label with the Reporter's own lines, not a button | It is a gesture (hold three fingers), so a button would promise something it cannot do. The lines come from `Reporter.hint_lines()`. |
| Resign is not shown | Your decision of 2026-11-20. |
| Political Pressure box shows the next tier's blurb | At the top tier it shows the tier in force, as there is no next one. |

### New Text rows (all drafts for you)

| Key | English | Note |
|---|---|---|
| `ui.back_office` | ‹ Office | The back control |
| `admin.group_display` · `admin.group_save` · `admin.group_help` | Display · Save · Help | In the approved list |
| `admin.pressure_now` | Now: {name} | In the approved list |
| `admin.label_text_size` · `admin.label_scroll_speed` · `admin.label_image_scroll` · `admin.label_image_pan` | Text size · Scroll speed · Image Scroll · Image Pan | **Not in the approved list**: the mockup's row labels, separate from their values |
| `admin.chip_open` · `admin.chip_save` · `admin.chip_load` · `admin.chip_undo` | Open · Save · Load · Undo | **Not in the approved list**: the value chips |
| `office.subtitle_jp_administration` | 管理 | **Not in the approved list**: the Japanese accent from the mockup |

### Tests

`tests/test_office_screen_frame.gd` (9) and `tests/test_administration_screen.gd` (11): values equal what the old buttons said, every old node name is kept, a tap runs its action, Resign is not on the screen, Load and Undo follow the save, chips never wrap, the Political Pressure box has one button, and the frame closes by Back and escape. `tests/interaction/image_pan_driver.gd` was updated on purpose: it read the old button's text and now reads the value chip.


## Reputation and Results (commit 3)

One screen with six tabs (Overview, Stakeholders, Backers, Parties, Election, Laws) replaces the menu of five buttons and the five panels they opened. Resign sits at the top of the Overview while it is available (your decisions of 2026-11-20).

| Style | Mockup | Overview, built (1080 x 2340) | 1080 x 1920 | Large text | Resign available | Reasons pop-up | Stakeholders tab | Laws tab |
|---|---|---|---|---|---|---|---|---|
| Woodblock | ![](../../proposals/img/office_screens/previews/png/results_woodblock_full_length.png) | ![](reputation_overview_woodblock_1080x2340.png) | ![](reputation_overview_woodblock_1080x1920.png) | ![](reputation_overview_woodblock_large.png) | ![](reputation_resign_woodblock.png) | ![](reputation_factors_woodblock.png) | ![](reputation_stakeholders_woodblock.png) | ![](reputation_laws_woodblock.png) |
| Living Office | ![](../../proposals/img/office_screens/previews/png/results_living_full_length.png) | ![](reputation_overview_living_office_1080x2340.png) | ![](reputation_overview_living_office_1080x1920.png) | ![](reputation_overview_living_office_large.png) | ![](reputation_resign_living_office.png) | ![](reputation_factors_living_office.png) | ![](reputation_stakeholders_living_office.png) | ![](reputation_laws_living_office.png) |
| Broadcast | ![](../../proposals/img/office_screens/previews/png/results_broadcast_full_length.png) | ![](reputation_overview_broadcast_1080x2340.png) | ![](reputation_overview_broadcast_1080x1920.png) | ![](reputation_overview_broadcast_large.png) | ![](reputation_resign_broadcast.png) | ![](reputation_factors_broadcast.png) | ![](reputation_stakeholders_broadcast.png) | ![](reputation_laws_broadcast.png) |

The screenshots use demo numbers (three organizations moved, one law passed) so the Overview has something to show.

### What differs from the mockup, and why

| Difference | Why |
|---|---|
| "Biggest moves **last level**", not "this week" | The game measures these changes per level (`last_booster_change` resets each level), so "this week" would be wrong. This is a reword of a row you approved; say so if you prefer the mockup's wording and want the data changed instead. |
| Every list change is a button showing only the signed number | Your 2026-11-19 rule. The reasons show only in the pop-up. The pop-up now starts with "Standing {old} → {new}" for an organization (spec section 2.1); it has no icon, as it is the old plain pop-up. |
| The factors pop-up is the old plain panel, not drawn on the frame | The spec asks for icon, name, standing line and rows; it gets the standing line and the same rows as before. A framed pop-up comes with the P14 pop-up card, which every pop-up shares. |
| Your Record is gone as a page | Its sections moved: the four numbers, Political Pressure line and Levels cleared (with clears per tier) are on the Overview; Legislative Work and the bills your influence flipped are on the Laws tab. Nothing was dropped. |
| The party list on the Overview shows each party's opinion score as a number beside a colour swatch | As the mockup does; the Parties tab keeps today's full cards (score, band, breakdown and the allies button). |
| Tabs scroll sideways (the last two are off the edge at first), with no scrollbar | As the spec says; the cut-off tab shows there is more. |
| The Resign button keeps its crimson fill and black text | It is the existing button (`ResignScreen.button`); I did not restyle it. Black on that crimson reads at about 3.6:1, below the 4.5:1 target, so you may want it changed. |
| Backers and Parties keep today's buttons (Take their backing, See allies and rivals) inside cards | Presentation of those rows was not part of the spec beyond the frame; they are the old rows in cards. |

### New Text rows (all drafts for you)

| Key | English | Note |
|---|---|---|
| `record.tab_overview` · `record.tab_stakeholders` · `record.tab_election` · `record.tab_laws` | Overview · Stakeholders · Election · Laws | **Not in the approved list**: the tab names (Backers and Parties reuse `office.backing` and `office.parties`) |
| `record.biggest_moves` | Biggest moves last level | Reworded, see above |
| `record.tap_change_hint` | Tap a change to see what moved it. | In the approved list |
| `record.factors_standing` | Standing {old} → {new} | In the approved list |
| `record.all_stakeholders` · `record.all_laws` · `record.all_parties` | All {count} › · All laws › · All parties › | **Not in the approved list**: the links to the tabs |
| `record.resign_title` | Resign | **Not in the approved list**: the Resign box heading |
| `office.subtitle_jp_reputation` | 評判と成績 | **Not in the approved list**: the Japanese accent |

### Tests

`tests/test_reputation_screen.gd` (14): the biggest-moves pick, the four tiles equal what Your Record showed, the moves and parties and latest law, six tabs in every style, every organization on the Stakeholders tab with its change button, no reason text in any list, a tap on a change opens the factors pop-up with the same rows `_open_factors` has always built, Resign first on the Overview while available and nowhere else, the danger box contrast. `tests/interaction/office_menus_driver.gd` was rewritten on purpose for the tabbed screen (it clicked the five old buttons and read the five old panels); `party_plate_test` and `resign_hold_test` pass unchanged.
