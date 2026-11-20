# Remaining screens redesign: spec (2026-11-19)

32 screens in seven groups, each drawn in all three UI styles (Living Office, Broadcast, Woodblock). Design canvas: "Remaining screens redesign: seven templates" (claude.ai artifact NXTPAefFVt66JckJo9dBVU). Values in the mockups are examples unless this spec says otherwise. P13 (Office screens) comes first: this panel reuses its shared frame.

## 1. Four shared layouts

| Layout | Used by | Rule |
|---|---|---|
| **Office frame** (from P13) | Staff Assignments, staff profile, Rhetoric Training, Your Deck, Inventory, Travel, Draft a Bill, Parties, Appearance and Music, How to Play, Characters | "‹ Office" back control, status chips, title with Japanese subtitle, optional tabs, scrolling body, optional fixed footer |
| **Pop-up card** (new) | Every group 1 screen, card offer, card look, a bill to carry, law detail, stage outcome | The current screen (or the room) dimmed behind; one card, centred (or at the bottom when a choice grid needs room); a header row with a **kind tag** and a meta line (day · office · hours); a title; a scrolling body; a fixed button row. One view with variants, not nine panels |
| **Conversation** (extend `VisitLayout`) | Office Hours, member visit, lobbyist trade, level intro | The room picture with the person large and centred, a name plate over its top-left corner, organization chips down the right edge; the question as a card under the picture; the choices as full-width buttons below |
| **Scene** | Stage transition, Floor Vote header, New Game | Full-bleed picture with the people in it; text on cards over the lower part |

### Kind tags on the pop-up card

| Tag | When | Colour |
|---|---|---|
| DECISION! | A scripted, dated event (Dated trigger), e.g. EV47 | Alarm (red) |
| SOMETHING COMES UP | A scenario (Random) event and its follow-ups | Accent |
| YOUR EVENT · n OF 3 / RESULT | An arranged event (walking tour, dinner) | Accent |
| WEEK'S END | Week over | Accent |
| PROMISES | The promises list | Accent |
| PROMISE BROKEN | Broken promises and trigger alerts | Alarm |
| MOVED FOR YOU | A forced move to the other office | Alarm |
| LEVEL IN PROGRESS | The resume choice | Accent |
| STAGE WON / STAGE LOST | Stage outcome | Good / alarm |

These make the three event classes (Decision!, scenario, arranged) visible. The tag text needs new Text rows (section 4).

## 2. Screens and where they live today

| # | Screen | Today | What changes |
|---|---|---|---|
| 1.1 | Decision! event | `_show_dated_event_if_due`, `EventEngine` | Pop-up card, DECISION! tag, scheduled date and speaker line, flavour, choices with their cost or reward line under each |
| 1.2 | Something comes up | `_show_random_event_if_due`, `_show_followup_if_due` | Same card, scenario tag; the organization involved shown with its icon; a choice that sends staff names who goes; a promise choice shows "Promise: … within N hours"; "Follow-up later" where it exists |
| 1.3 | Your event, in progress | `HostedEventPanel` | Card at the bottom over the event picture; step tag "1 OF 3"; guests as icon chips; options as a two-column grid, the picked one filled |
| 1.4 | Event result | `_show_gathering`, the hosted result | Net line, meta tiles, then "How your guests took it" with icon, name, reason and change per organization |
| 1.5 | Week over | `_show_week_over_if_due`, `WeekPaymentsView` | Payment rows (dues, each wage, total, funds after), the unpaid-wage warning, one button |
| 1.6 | Promises | `_show_promises` | One card per promise: icon, what and for whom, due time (red when close), a place chip, Keep button greyed with `promises.refuse_elsewhere` when elsewhere |
| 1.7 | Promise broken | `_show_broken_promises_if_any`, `_show_trigger_alerts_if_any` | Alarm tag, the broken promise, the standing and Reputation it cost |
| 1.8 | Moved to the Capitol | `_show_forced_special_if_due`, `travel.forced_move` | The primary staff member's reminder in a speech card, `travel.forced_move`, what is not open at this office, "The trip cost no hours." (forced moves are free, Balance `forced_travel_hours` = 0) |
| 1.9 | Level in progress | `_show_resume_choice_if_in_level` | Level, next stage, stage progress bar, `stage_menu.abandon_warning`, Abandon Level and Resume |
| 2.1 | Office Hours visitor | `VisitorScreen` | Conversation layout; caption "Visitor n of m" |
| 2.2 | Member visit | `VisitScreen` | Conversation layout; the researcher's brief as a speech card over the picture; each answer shows its rhetorical style under it |
| 2.3 | Lobbyist trade | `TradeScreen` | Conversation layout; leverage bar and the component they want gone above the question; Walk away last |
| 2.4 | Stage transition | `StageTransitionScreen` | Scene layout: speaker left, player right, the line on a card, the reply as a button, Continue |
| 2.5 | Level intro | `LevelIntroScreen` | Conversation layout with the staff cue; bill card (description, owner party, your party's position, Read the Bill), stance as a two-button switch, stakes line, "Let's go" |
| 3.1 | Floor Vote | `FloorVoteScreen` | Header scene with six party discs (colour, short name, stance word, seats); bill card with the requirement line; Vote Projections as three stacked bars; stance effects; Influence Status, Vote Intention Research, Whip Details as one row; three vote buttons fixed at the foot |
| 3.2 | Stage outcome | `OutcomePresenter` | Pop-up card over the room: STAGE WON/LOST tag, title, reason, meta tiles, Pleased/Annoyed icon rows (tap for the name), carried-over line, the 2-second hold on the button kept |
| 4.1 | Staff Assignments | `StaffAssignmentsView` | Office frame; today's tasks as dashed chips; **one card per hired person** (as P13: everyone shows) with picture, role and rank, Loyalty word, 8-block bar, drop box; "If you confirm"; Confirm fixed |
| 4.2 | Staff profile | `_show_staff_profile` | Picture and identity card (Primary tag, rank, Loyalty word and wage, gift tastes); Loyalty bar and why it moved; Raise pay / Thank buttons; bonuses by rank with upgrade; Fire as a red outline button last |
| 4.3 | Rhetoric Training | `_show_rhetoric_training` | One card per session tier with price; refusal on the card; coupon line |
| 5.1 | Your Deck | `_build_deck_screen` | Tabs In your deck / Collection; suit counts as chips; two-column card faces (art, cost badge, name, suit · type, effect) |
| 5.2 | Card offer | `_show_card_offer` | Pop-up card: "Your coach suggests", counter n/3, the card, Pass and Learn it |
| 5.3 | Card look | `_show_card_look` | Pop-up card: the card, Japanese name, suit · type · cost, effect, tier and where it is, Close |
| 5.4 | Inventory | `InventoryPanel` | Grid of items with ×count; the picked item's details in a bottom sheet with Use and Close (same view in the Office and the battle) |
| 6.1 | Travel | `_show_travel`, `TravelCard` | Where you are; one card per destination with the level waiting there and one button per travel mode (pass, ticket with count, car); the promise warning; the confirm as a bottom sheet with hours left after |
| 6.2 | Draft a Bill | `_open_draft` | Your bill (chosen parts with remove), the hearing line, add a part from (organizations with standing), if it passes, the extra visit as a checkbox, cost line over a fixed Draft button |
| 6.3 | A bill to carry | `_open_request` | Pop-up card: org icon, the bill name (`custom_bill.name_*`), the request line, current vote and party position, rewards, one amend option, Carry and Decline (with its cost) |
| 6.4 | Law detail | `_show_law` | Pop-up card: PASSED/FAILED marker, tally and your vote, dossier sections, what is now law |
| 6.5 | Party detail | `_show_party_detail` | Party colour band, seats and leader, how they see you (score, band, bar, breakdown), Allies and Rivals with standing and tag |
| 7.1 | Appearance and Music | `_show_cosmetics` | One card per slot (Office styles, Office Background, Music, Calendar, Walking route…), owned options as tiles, the equipped one filled |
| 7.2 | How to Play | `HowToPlayPanel` | Numbered entries with their screenshot slot; Watch the demo fixed |
| 7.3 | Characters | `CharacterCodexPanel` | Two headings; two-column name buttons with the character's colour as a left edge; unmet people dimmed as 誰ですか。 |
| 7.4 | New Game | `_show_new_game` | Four champions as a portrait row; the picked one's card (party, district, blurb, starting numbers); Political Pressure and Theme as three-way switches; "Play as {name}" fixed |

## 3. Per-style tokens

The P13 token table applies. New tokens for this panel:

| Token | Woodblock | Living Office | Broadcast |
|---|---|---|---|
| Scrim behind pop-ups | rgba(28,26,23,.55) | rgba(20,12,6,.62) | rgba(5,9,18,.66) |
| Alarm tag (DECISION!, PROMISE BROKEN, MOVED FOR YOU) | #B3311C, white text | #A3261A, white text | #C8102E, white text |
| Plate (name plates, speech cards over pictures) | #F8F1E3 | #FFF8EC | #141E33 |

Put them in the UI Styles tab as rows, as P12 did. Contrast 4.5:1 for text, 3:1 for icons and bars.

## 4. New text rows (drafts; ask Cameron before adding)

| Proposed key | English |
|---|---|
| `popup.tag_decision` | DECISION! |
| `popup.tag_scenario` | SOMETHING COMES UP |
| `popup.tag_arranged` | YOUR EVENT · {step} OF {steps} |
| `popup.tag_arranged_result` | YOUR EVENT · RESULT |
| `popup.tag_week_end` | WEEK'S END |
| `popup.tag_promises` | PROMISES |
| `popup.tag_broken` | PROMISE BROKEN |
| `popup.tag_moved` | MOVED FOR YOU |
| `popup.tag_resume` | LEVEL IN PROGRESS |
| `popup.tag_stage_won` · `popup.tag_stage_lost` | STAGE WON · STAGE LOST |
| `event.decision_note` | This is set by the calendar, not bought. |
| `travel.forced_free` | The trip cost no hours. |
| `travel.closed_here` | Not open while you are here |
| `travel.destination` | To {place} |
| `event.delegate_who` | {name} goes · 0 h of yours |
| `rhetoric.coupon_line` | You hold {count} coaching coupon: your next Tier {tier} session is free. |
| `outcome.hold_hint` | Hold for 2 seconds |

Everything else on the mockups uses rows that exist (`event.*`, `hosted.*`, `promises.*`, `visit.*`, `trade.*`, `floor_vote.*`, `outcome.*`, `assign.*`, `staff.*`, `rhetoric.*`, `item.*`, `travel.*`, `draft.*`, `request.*`, `dossier.*`, `party_opinion.*`, `characters.*`, `new_game.*`).

## 5. Done list

- The four shared layouts exist once each and every screen in section 2 uses one of them.
- Every pop-up shows its kind tag; a Decision! event never shows a price or a buy button.
- The conversation screens share one layout (VisitLayout extended), so Office Hours, the member visit, the trade and the level intro line up.
- Staff Assignments shows every hired person.
- Floor Vote's three vote buttons and the other screens' primary buttons stay fixed while the body scrolls.
- No rule moves; no number changes (equivalence tests); no hardcoded sentences; Text rows the screens stop using go on `design/CLEANUP_CANDIDATES.md`, not deleted.
