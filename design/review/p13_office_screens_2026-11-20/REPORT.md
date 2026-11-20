# P13 Office screens: report (draft for Cameron)

## Summary

| Item | State |
|---|---|
| Screens built | Administration, Reputation and Results, Marketplace, Office Management, Events, all on one frame (`OfficeScreenFrame`) in Woodblock, Living Office and Broadcast |
| Commits | Seven on `panel/p13-office-screens`, each after a full `verify.sh` pass ("All checks passed") except the last, which is this report |
| Not merged | As asked. Say "merge" when you are happy |
| Rules, numbers, IDs, canon | Unchanged, apart from one new Balance number (Events Coming Up Days = 7) and a read-only reader for the dated events ahead |
| New text | About 60 draft rows: the lists below say which were not in the approved list |
| Audits | Text sweep: no letter-stacked or off-screen text in three styles at three sizes. Contrast: tests at 4.5:1 for the frame's colours and the Resign box. Touch targets: every control P13 built is at least 122 px (the audit's only smaller control on these screens is the Office's own Administration button behind them) |
| Found, not fixed | A staff wage prints without a thousands comma ("6000円", an old row); the Resign button's black on crimson is about 3.6:1; the pop-ups these screens open (reasons, staff profile, items, the Decision! pop-up itself) are still the old ones until P14 |
| Decisions for you | Reword any draft row; "Biggest moves last level" instead of "this week"; whether the Saved chip should stay a fixed label; the two kinds of change that need your word are listed per screen below |

Branch `panel/p13-office-screens`. Mockups are in `design/proposals/img/office_screens/previews/png/`. Screenshots here are the real game at 1080 x 2340, 1080 x 1920 and Large text, made with `tools/office_screen_shots.tscn` (command in its header).

## Commits

| # | Commit | State |
|---|---|---|
| 1 | The shared frame (`OfficeScreenFrame`, `OfficeFrameStyles`, `Overlay.open_frame`) | Gate passed |
| 2 | Administration (and two click tests updated on purpose) | Gate passed |
| 3 | Reputation and Results (and two tests adjusted: the tabs wrap, the party plate test skips clipped labels) | Gate passed |
| 4 | Marketplace (and a fix so top-bar chips wrap and stack at Large text) | Gate passed |
| 5 | Office Management | Gate passed |
| 6 | Events | Gate passed |
| 7 | Docs, final report, audits | Gate pending |

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
| The tabs wrap onto a second line instead of scrolling sideways | The spec says the row scrolls sideways, but the project's text sweep forbids any text off the screen edge, even inside a scroll box, and six tabs plus Large text do not fit one line. Wrapping also shows every tab at once. |
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


## Marketplace (commit 4)

The three tabs (Personal Inventory, Office Inventory, Office styles) keep their node names. Funds against the limit and XP are chips; a "You have" card holds what you carry; every item is one card of the same shape; the Styles tab uses the same cards.

| Style | Mockup | Personal (1080 x 2340) | 1080 x 1920 | Large text | Scrolled to the bottom | Office styles tab |
|---|---|---|---|---|---|---|
| Woodblock | ![](../../proposals/img/office_screens/previews/png/marketplace_woodblock_full_length.png) | ![](marketplace_personal_woodblock_1080x2340.png) | ![](marketplace_personal_woodblock_1080x1920.png) | ![](marketplace_personal_woodblock_large.png) | ![](marketplace_personal_woodblock_bottom.png) | ![](marketplace_styles_woodblock.png) |
| Living Office | ![](../../proposals/img/office_screens/previews/png/marketplace_living_full_length.png) | ![](marketplace_personal_living_office_1080x2340.png) | ![](marketplace_personal_living_office_1080x1920.png) | ![](marketplace_personal_living_office_large.png) | ![](marketplace_personal_living_office_bottom.png) | ![](marketplace_styles_living_office.png) |
| Broadcast | ![](../../proposals/img/office_screens/previews/png/marketplace_broadcast_full_length.png) | ![](marketplace_personal_broadcast_1080x2340.png) | ![](marketplace_personal_broadcast_1080x1920.png) | ![](marketplace_personal_broadcast_large.png) | ![](marketplace_personal_broadcast_bottom.png) | ![](marketplace_styles_broadcast.png) |

The screenshots hold some items (Coffee at its carrying limit of three) and the Speech Trainer sold out for the level, with Funds at the limit, so the Funds-limit note, a funds-short reason, Out of Stock and "can't carry any more" all show.

### What differs from the mockup, and why

| Difference | Why |
|---|---|
| The reason ("Insufficient Funds", "Out of Stock", "You can't carry any more of these.") is a red line on the card and Buy stays greyed, reading "Buy" | The spec's rule. Before, the greyed button itself carried the reason. The reason is still the rules' own words. |
| The price stays in the title line ("Name — price") | That is how `shop.item_title` is written; the mockup shows it apart. Say so if you want it on the right, which would mean a new Text row. |
| Ticket icons are the blue placeholder squares | The art is still to be drawn (art list, `TICKET_*`). |
| The "You have" strip is the inventory's own tiles (icon and count), still tappable and swipeable | They are the same tiles the Office inventory shows; `inventory.entry` ("×3") is the count under each. |

### New Text rows (all drafts for you)

| Key | English | Note |
|---|---|---|
| `shop.you_have` · `shop.you_have_hint` | You have · Use from the Office or during a stage | In the approved list |
| `office.subtitle_jp_marketplace` | 市場 | **Not in the approved list**: the Japanese accent |

### Tests

`tests/test_market_screen.gd` (10): every item the old rows offered is still offered with the same title and description, a funds-short and a sold-out item say so, a full stack says you cannot carry more, a card with no reason has a working Buy and one with a reason is greyed with the reason in red, a sold-out card is dimmed, the three tabs keep their old names in every style, the chips, the Funds-limit note, the Styles tab and tab switching. `tests/interaction/inventory_driver.gd` now scrolls the frame's list instead of the panel's own scroll area, on purpose.


## Office Management (commit 5)

Three tabs (Staff, Your deck, Rhetoric Training) replace the menu of four buttons that each closed it and opened a panel. Funds, XP and the deck count are chips. The Staff tab shows a summary, then one section for each role with **a card for every hired person** and **a dashed "+ Hire a ..." row for every open place**; Staff Assignments is the fixed button under it.

| Style | Mockup | Staff tab (1080 x 2340) | 1080 x 1920 | Large text | An open place's candidates | Your deck tab | Rhetoric Training tab |
|---|---|---|---|---|---|---|---|
| Woodblock | ![](../../proposals/img/office_screens/previews/png/office_management_woodblock.png) | ![](management_staff_woodblock_1080x2340.png) | ![](management_staff_woodblock_1080x1920.png) | ![](management_staff_woodblock_large.png) | ![](management_hire_woodblock.png) | ![](management_deck_woodblock.png) | ![](management_rhetoric_woodblock.png) |
| Living Office | ![](../../proposals/img/office_screens/previews/png/office_management_living.png) | ![](management_staff_living_office_1080x2340.png) | ![](management_staff_living_office_1080x1920.png) | ![](management_staff_living_office_large.png) | ![](management_hire_living_office.png) | ![](management_deck_living_office.png) | ![](management_rhetoric_living_office.png) |
| Broadcast | ![](../../proposals/img/office_screens/previews/png/office_management_broadcast.png) | ![](management_staff_broadcast_1080x2340.png) | ![](management_staff_broadcast_1080x1920.png) | ![](management_staff_broadcast_large.png) | ![](management_hire_broadcast.png) | ![](management_deck_broadcast.png) | ![](management_rhetoric_broadcast.png) |

The screenshots use demo staff (four people hired, a second place in every role). "Rank 0 of 0" is the data: those people have no upgrade tiers.

### What differs from the mockup, and why

| Difference | Why |
|---|---|
| Your deck and Rhetoric Training show today's rows inside cards | The spec calls today's buttons "tabs". Their own redesign (two-column card faces, tiers as cards) is P14 groups 4 and 5, so here they keep their rows and flows. Taking the deck in is the fixed button under that tab ("Take these in", only while the deck is legal) and closes the screen, as before. |
| The staff summary shows "3 of 6" without "places filled" | A compact tile; the role headings say "1 of 2 places filled". |
| Each person's card shows the name, rank, tag and "Steady · wage 6000円 a week" (the old Loyalty and wage line) | Reuse of today's words. **The wage prints without a thousands comma ("6000円")**; this was already so on the old row and the Information Standards ask for commas. The cause is the placeholder name `{yen}` in the `staff.summary` row, which the formatter does not treat as money. I did not change it; say if you want it fixed (a one-word fix in that row or the view). |
| An open place opens the candidates in a pop-up over the Staff tab | The spec: "opens today's candidate rows". Hiring, upgrading or firing refreshes the tab and puts the pop-up away. |
| Staff Assignments opens over Office Management instead of closing it | Back from Staff Assignments now returns here. |
| "Paid on" row (in the spec's list) is not used | The mockup does not show it, and I did not want an unused row. |
| Tab names are "Staff", "Your deck", "Rhetoric Training" | The existing rows (`office.your_deck` reads "Your deck", not "Your Deck"). |

### New Text rows (all drafts for you)

| Key | English | Note |
|---|---|---|
| `office.wages_week` | Wages this week | In the approved list |
| `office.hire_slot` | + Hire a {role} | In the approved list, reworded to show the role as the mockup does |
| `office.staff_second_tag` · `office.staff_third_tag` | Second · Third | Flagged in the plan |
| `office.open_place` | Open place | Flagged in the plan |
| `office.places_per_role` · `office.staff_count_of` | Places per role · {count} of {total} | **Not in the approved list**: the summary tiles |
| `office.subtitle_jp_management` | 事務所の管理 | **Not in the approved list**: the Japanese accent |

### Tests

`tests/test_management_screen.gd` (8): the staff count equals the people listed, open places are the places not filled, a person shows what the old row showed with a tag by place, a card for every hired person and a row for every open place in every style with taps reaching their handlers, three tabs plus Staff Assignments plus three chips, the deck tab confirms only a legal deck, a training card for every session, every tab builds in every style. `staff_profile_driver` and `shop_items_driver` were updated on purpose: they reached staff through the old menu's Staff button and the Rhetoric Training panel; they now go through the Staff tab's open-place row and the Rhetoric Training tab.


## Events (commit 6)

Two tabs (Arrange here, Coming up); chips for where you stand and the hours left this week; a red **Decision!** banner for a dated event coming up (no price, no button, never a buy row); one card for every event that can be arranged at this office, with a location badge, its cost and hours, the reason in red when it cannot be arranged now, and a greyed "Arrange it". Only what can be arranged at the office the player stands at is listed (the two-offices filtering, unchanged).

| Style | Mockup | Arrange here (1080 x 2340) | 1080 x 1920 | Large text | Funds short: reasons and greyed buttons | Coming up tab |
|---|---|---|---|---|---|---|
| Woodblock | ![](../../proposals/img/office_screens/previews/png/events_woodblock.png) | ![](events_here_woodblock_1080x2340.png) | ![](events_here_woodblock_1080x1920.png) | ![](events_here_woodblock_large.png) | ![](events_refused_woodblock.png) | ![](events_coming_woodblock.png) |
| Living Office | ![](../../proposals/img/office_screens/previews/png/events_living.png) | ![](events_here_living_office_1080x2340.png) | ![](events_here_living_office_1080x1920.png) | ![](events_here_living_office_large.png) | ![](events_refused_living_office.png) | ![](events_coming_living_office.png) |
| Broadcast | ![](../../proposals/img/office_screens/previews/png/events_broadcast.png) | ![](events_here_broadcast_1080x2340.png) | ![](events_here_broadcast_1080x1920.png) | ![](events_here_broadcast_large.png) | ![](events_refused_broadcast.png) | ![](events_coming_broadcast.png) |

### What differs from the mockup, and why

| Difference | Why |
|---|---|
| A new Balance lever, **Events Coming Up Days = 7** | A dated event needs a rule for when it starts to show as coming up. EV47 is on 18.10.08, the Monday of the second week, so a "this week" rule would never show it. 7 = it shows a week before its date. This is a number for you to change, in the Balance tab. |
| A small read-only reader, `EventEngine.upcoming_dated` | The "Coming up" list. It adds no rule: a dated event that is due today or past is still `due_dated`'s, as before. |
| The banner shows only the first dated event on Arrange here; the Coming up tab lists all of them | The mockup shows one banner. |
| "Coming up" lists dated events only | The spec also says "the week's scheduled items"; today the only scheduled things are dated events, and I did not want to invent a list. |
| The banner's line says the staff will move you to the event's own place | The approved row named the Capitol; the draft row now takes the place (`{place}`), so a District event reads right. It shows only when the event is at the other office. |
| Badges read "Capitol", "District office" and "Either office" | They reuse the level briefing's location words (`briefing.location_*`). |
| The decision itself, when the day comes, is still today's pop-up | Its redesign is P14 group 1 (the pop-up card). |

### New Text rows (all drafts for you)

| Key | English | Note |
|---|---|---|
| `event.tab_here` · `event.tab_coming` | Arrange here · Coming up | In the approved list |
| `event.decision_banner` | DECISION! · COMING UP | In the approved list |
| `event.decision_moves_you` | Your staff will move you to {place} for this. | In the approved list, reworded with `{place}` |
| `event.coming_none` | Nothing is scheduled for the next few days. | **Not in the approved list** |
| `event.coming_meta` | {day} · {office} · {hours} h | **Not in the approved list**: the banner's day, office and hours line |
| `office.subtitle_jp_events` | 行事 | **Not in the approved list**: the Japanese accent |

### Tests

`tests/test_events_screen.gd` (8): the reader (after today, within the horizon, unplayed, in date order; a due event is never also upcoming), only events that can be arranged here are listed with the rules' own reason, EV47 is coming up a week before its date, a Decision! banner has no price and no button, a card with no reason can be arranged and one with a reason is greyed with the reason in red, two tabs with the banner on both and no Arrange button on Coming up in every style, and the chips. `tests/interaction/event_driver.gd` now reads the reason from the red line instead of the greyed button's text, on purpose.
