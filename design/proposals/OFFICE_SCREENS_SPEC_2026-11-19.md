# Office screens redesign: spec (2026-11-19)

Five Office screens, one shared layout each, drawn in all three UI styles (Living Office, Broadcast, Woodblock). Design canvas: "Office screens redesign: five templates" (claude.ai artifact PHSsJEf2LWh9bEVuUvTi24). Values in the mockups are examples unless this spec says otherwise.

## 1. Shared frame (all five screens)

| Part | Rule |
|---|---|
| Top bar | "‹ Office" back control (44 px tall) on the left; status chips on the right (Funds, XP, week, office, hours left, Saved) |
| Title | Screen title in the style's display font, Japanese subtitle beside it in small muted text |
| Tabs | Optional row of tabs under the title. Scrolls sideways when it doesn't fit. Tabs only map to sections the game already has (section 2) |
| Body | Cards in a single scrolling column. The top bar, title and tabs stay put |
| Footer | Optional fixed primary button (Office Management only) |
| Touch targets | Every button and tappable chip is at least 44 px tall in the mockup scale (390 × 844); the game's own minimums in `UiKit` win where larger |
| Text | Every word comes from `data/strings.json`. New rows are listed in section 4 |

## 2. Screens

### 2.1 Reputation and Results (`_show_reputation_menu` and the panels it opens)

| Tab | Content | Existing source |
|---|---|---|
| Overview | "Where you stand": four tiles (the meta numbers) with a ± button each · "Biggest moves this week": the three organizations with the largest absolute change, each with icon, name, standing bar, standing number and a ± button · Parties summary · Legislative Work (latest law, PASSED/FAILED marker, tally, your vote) · Levels cleared (below the fold) | `_show_record`, `_build_record` |
| Stakeholders | Today's grouped list (Party Bodies / Constituency / National) | `_show_organisations` |
| Backers | Today's Backers list | `_show_backing` |
| Parties | Today's parties list and party detail | `_show_parties`, `_show_party_detail` |
| Election | Election Strength | `_show_election` |
| Laws | Full law list and law detail | record statute section, `_show_law` |

**± change buttons (Cameron, 2026-11-19 review).** A change is a button reading only the signed number (`%+d`, or the `Phrase.meta_amount` form for Funds). The reasons ("because of …") never show in the list. Tapping the button opens the factors pop-up: icon, name, "Standing {old} → {new}", one row per factor (signed amount, then the `record.cause_*` wording), Close. This extends the rule already in `_organisation_row` (2026-11-09) to the Overview tiles and the "Biggest moves" rows, and reuses `_show_standing_factors` / `_show_meta_factors` / `_open_factors`. Unchanged rows (0) show no button.

### 2.2 Marketplace (`_show_marketplace`)

| Part | Rule |
|---|---|
| Chips | `shop.funds_limit` (Funds / limit) and XP |
| Tabs | The three tabs Cameron set on 2026-10-31: Personal, Office, Styles (existing `shop.tab_*` keys). No new tabs |
| "You have" strip | Compact chips of owned items with ×count (`inventory.entry`), from `_inventory_panel.inventory_rows(tab)`. Empty: `inventory.empty` |
| Buy list | One row shape per item: icon tile, name, effect line, price (`shop.item_price_yen` / `shop.item_price_xp`), Buy (`shop.buy`). When it can't be bought, the button is greyed and the refusal shows as a red line on the card (`shop.out_of_stock`, `shop.stack_full`, `shop.funds_short`, `shop.xp_short`, …) |
| Styles tab | Today's style cards, restyled to the same card shape |

### 2.3 Office Management (`_show_management`, `_show_staff`)

| Part | Rule |
|---|---|
| Tabs | Staff · Your Deck · Rhetoric Training (today's buttons become tabs) |
| Summary card | Wages this week · staff count (hired of all places) · places per role (`GameState.staff_slots()`) |
| Role sections | One section per role: role heading and "{filled} of {places} places filled" (`office.staff_role_places`) |
| Person cards | **Every hired person has their own card** (Cameron's review, 2026-11-19): portrait, name, weekly wage, a **Primary** tag on the first hire in the role (the one every scene reads; others say "Second"/"Third"), "Rank {n} of {m}", Loyalty word from `StaffLoyaltyView`. Tapping a card opens `_show_staff_profile`. The staff count in the summary must equal the number of person cards |
| Open places | Each open place is its own dashed "+ Hire a {role}" row that opens today's candidate rows |
| Footer | Fixed primary button: Staff Assignments (`_show_staff_assignments`) |
| XP / Funds / deck count | Move to the top-bar chips |

### 2.4 Events (`_show_events_list`)

| Part | Rule |
|---|---|
| Chips | Current office, hours left |
| Tabs | Arrange here · Coming up |
| Hint | `event.list_hint` |
| Decision! banner | A dated scripted event coming this week (e.g. EV47 The Prime Minister's Opening Address) shows as a red banner: "DECISION! · COMING UP", day · office · hours, title, one line. Not buyable, no button |
| Rows | Only events arrangeable at the current office (the slice-3 filtering already on main). Each: title, location badge (District / Capitol / Either from the `location` column), cost · hours, "Arrange it" (`event.arrange`). Refusal text (`event.refuse_*`) shows as a red line and the button is greyed |
| Coming up tab | Dated events and the week's scheduled items |

### 2.5 Administration (`_show_administration_menu`)

Grouped settings cards, each row label on the left, current value as a chip on the right:

| Group | Rows (existing controls) |
|---|---|
| Display | Text size, Scroll speed, Image Scroll, Image Pan |
| Appearance and Music | Office Background, Music, Calendar (opens `_show_cosmetics`) |
| Save | Save Game, Load Game (with `office.backup_label` summary), New game |
| Help | How to Play, Characters, Report a problem (`Reporter.hint_lines()`) |

Then **two separate boxes, each with its own button** (Cameron, 2026-11-19 review):

| Box | Content |
|---|---|
| Political Pressure | Current tier, the next tier's blurb (`pressure.*.blurb`), one button: `admin.raise_pressure`. At the top tier the button is greyed with `admin.pressure_top` |
| Resign | Danger styling. Shown only while `ResignRules.available()` is true. One hold button (`ResignScreen.button`, `ResignHold`) with `resign.hold_hint` |

**Decision for Cameron:** Resign is in Reputation and Results today. The mockup shows it in Administration. Prompt step 2 asks.

## 3. Per-style table

| Token | Woodblock | Living Office | Broadcast |
|---|---|---|---|
| Background | #EFE4CF | #2B1D12 | #0B1220 |
| Card | #F8F1E3, 2 px ink border, square, offset shadow 4 px #C23B22 | #FFF8EC, radius 18, soft shadow | #141E33, gold top and bottom rules, no side borders |
| Accent / primary button | #22305A with paper text | #FFD58A with dark text, pill | #E3B341 with navy text, slanted clip |
| Display font | Antaka Brush Display | Antaka Brush Display | Barlow Condensed italic 700, uppercase |
| Body font | Shippori Mincho B1 (stand-in) | Zen Kaku Gothic New (stand-in) | Noto Sans JP |
| Up / down colour | #2F6B3A / #A42A17 | #2E6B34 / #A3261A | #7BD88F / #FF8A80 |

Use the game's real fonts and `UiStyle` tokens where they differ from the stand-ins. Contrast must reach 4.5:1.

## 4. New text rows (drafts; ask Cameron before adding)

| Proposed key | English |
|---|---|
| `record.biggest_moves` | Biggest moves this week |
| `record.tap_change_hint` | Tap a change to see what moved it. |
| `record.factors_standing` | Standing {old} → {new} |
| `shop.you_have` | You have |
| `shop.you_have_hint` | Use from the Office or during a stage |
| `office.wages_week` | Wages this week |
| `office.staff_count` | Staff |
| `office.paid_on` | Paid on |
| `office.hire_slot` | + Hire a second |
| `event.tab_here` | Arrange here |
| `event.tab_coming` | Coming up |
| `event.decision_banner` | DECISION! · COMING UP |
| `event.decision_moves_you` | Your staff will move you to the Capitol for this. |
| `admin.group_display` · `admin.group_save` · `admin.group_help` | Display · Save · Help |
| `admin.pressure_now` | Now: {name} |
| `resign.box_hint` | Shows only while all three standings are far down. |

## 5. Done list

- All five screens use the shared frame in all three styles.
- No "because of" text appears in any list; every non-zero change is a button that opens the factors pop-up.
- Raise Pressure and Resign are separate boxes with one button each.
- Marketplace tabs are exactly Personal / Office / Styles.
- Events lists only what can be arranged at the current office; a dated Decision! event is a banner, never a buy row.
- No hardcoded sentences; old rows the screens stop using are listed on `design/CLEANUP_CANDIDATES.md`, not deleted.
