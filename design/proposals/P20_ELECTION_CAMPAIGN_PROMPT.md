# P20: Election and campaign — Campaign Office, campaign staff, Campaign Moment!, polls, selection

**Branches:** four phases, each its own branch from `main`, merged in order:
`feature/p20a-campaign-rules`, `feature/p20b-campaign-office`, `feature/p20c-campaign-moments`, `feature/p20d-selection-polls`.

**Source:** Cameron's doc "Election and campaign: final guidance" (claude.ai, 2026-11-25). Everything needed from it is in this prompt and in `P20_CONTENT.md` (the scene, choice and Text rows to add).

**Approval.** Every schema, ID and data change listed here was decided or approved by Cameron on 2026-11-25. This prompt is that approval for the listed items and nothing beyond them (CLAUDE.md section 3 and 4). If something you need is not listed, stop and ask. Follow CLAUDE.md as usual: all numbers are Balance rows, all sentences are Text rows asked for by literal keys, pure rules in `scripts/rules/`, UI separate, heavy comments, and merge each phase only after `tools/verify.sh` prints "All checks passed".

**Out of scope (do not build):** Rumor! and Scandal!, Blunders!, credibility, XP decay (a later economy prompt); Election Day results beyond the stub in phase D; the samurai and gladiator UI schemes (later). Build the screens in the existing looks (Woodblock, Living Office, Broadcast).

---

## Vocabulary

| Design term (data and code) | In-game name (Text row) |
| --- | --- |
| `building` | (no banner) |
| `announcement` | Banners of War Rising |
| `mustering` | Mustering the War Campaign |
| `campaign` | Gladiators of War Unleashed |
| `election_day` | Sengoku no Hi (戦国の日) |

**Campaign fund:** a separate ledger, not Funds. **Campaign capital:** XP spent at the Campaign Office. **Campaign staff:** a second staff pool, never the regular office staff. Regular office staff never do campaign work.

---

## Phase A — data and pure rules (`feature/p20a-campaign-rules`)

No UI in this phase. Workbook, exporter, `DataDB` validation, rules, tests.

### A1. Workbook and exporter

| Tab | Change |
| --- | --- |
| **Election Cycles** (new → `data/election_cycles.json`) | Columns: Cycle ID (`EC##`), Banners Date, Campaign Open Date, Election Day (YY.MM.DD, checked like other dates; Banners < Open < Day), Player Runs (Y/N). Rows: EC01 21.10.11 / 21.11.30 / 21.12.12 / Y; EC02 24.10.07 / 24.11.26 / 24.12.08 / Y; EC03 27.10.11 / 27.11.30 / 27.12.12 / N. Exactly one row may have Player Runs N, and it must be the last |
| **Campaign Staff** (new → `data/campaign_staff.json`) | Same columns as the Staff tab where they apply (Staff ID, Role, Name, Name JP, Romaji, Starting Tier, Highest Tier, Biography, Role Flavor, Gift Likes, Gift Dislikes, gift Loyalty columns) plus **Available** (`office` or `chain`). No price or reward columns: those are Balance rows. Rows CS01–CS06 below. Roles: `Campaign Organizer`, `Campaign Fundraiser`, `Campaign Van Announcer` |
| Venues | Row VN10 Campaign Office, Name JP 選挙事務所, Romaji Senkyo Jimusho, zone District, Unlock `scene` (opened only by `venue:VN10`), Open Days Any |
| Venue Activities | Rows CA01–CA04 (IDs `CA##` allowed alongside `VA##`), venue VN10, kinds `campaign_fundraise`, `campaign_letters`, `campaign_mailings`, `campaign_van`. Leave numeric columns blank: the rules read Balance rows |
| Decision Scenes | New columns: **Card** (`Decision` default, `Campaign`), **Weight**, **Weight Late**, **Repeat** (Y), **Cooldown Weeks**, **Phase** (`any`, `building`, `mustering`, `campaign`, semicolon list), **Needs** (`office_open`, `van`, `van_speech_done`, `campaign_staff_hired`, `campaign_staff_free`). New Kind **`Random`** (needs Weight; no Opens). Speaker may also be `colleague` or a `CS##` ID. Activates gains `venue:VN10`, `campaign_staff:CS##`, `challenge:<activity>x<count>in<days>` (e.g. `challenge:CA01x3in14`). Follow If may also hold `challenge_met` or `challenge_failed` |
| Event Choices | New columns: **Campaign Fund Delta** (int), **Donate Funds** (int: moves that many Funds into the campaign fund), **Lend Campaign Staff Weeks** (int), **Favor Owed** (Y), **Needs** (same values as the scene's Needs; the choice is hidden when it fails) |
| Text | Every key listed in `P20_CONTENT.md` |

The exporter validates every new column and cross-reference (CS IDs, CA IDs, VN10, activity IDs inside `challenge:`, cycle dates) and errors with a readable message, as it does for today's tabs.

**Campaign staff rows (placeholder names, Cameron will rename):**

| ID | Role | Name | Available | Starting tier | Highest tier |
| --- | --- | --- | --- | --- | --- |
| CS01 | Campaign Organizer | Hiroto Ban | office | 0 | 1 |
| CS02 | Campaign Organizer | Dan Bronco | chain | 0 | 2 |
| CS03 | Campaign Fundraiser | Ren Fusenji | office | 0 | 1 |
| CS04 | Campaign Fundraiser | Umina Kota | chain | 0 | 2 |
| CS05 | Campaign Van Announcer | Hitomi Ota | office | 0 | 1 |
| CS06 | Campaign Van Announcer | Yuina Chanami | chain | 0 | 2 |

Leave Biography and Role Flavor as a Note-style `DRAFT` placeholder if the tab supports it; otherwise one neutral sentence each that names only the role.

### A2. Balance rows (new or changed)

| Row | Value | Note |
| --- | --- | --- |
| `election_capital_target` | 3000 | Replaces `election_experience_target` in `ElectionStrength` (keep the old row only if something else reads it) |
| `election_capital_fade_percent` | 5 | At week's end |
| `election_war_chest_target` | 25000000 | Was 500000, now read from the campaign fund |
| `election_war_chest_limit` | 100000000 | Campaign fund ceiling; extra income is lost, and the UI says so |
| `election_gain_per_week_mustering` | 6 | Weekly rise limit during `mustering` |
| `difficulty_relaxed_election_gain_per_week_mustering` / `difficulty_harder_…` | 7 / 5 | Same pattern as the existing gain rows |
| `campaign_sprint_multiplier` | 1.5 | Rewards only, during `mustering` |
| `campaign_actions_per_week` | 2 | During `building` and `mustering`; no count limit during `campaign` |
| `campaign_action_hours` | 4 | |
| `campaign_action_hours_with_organizer` | 2 | Letters and mailings, with an Organizer hired and present |
| `campaign_fundraise_xp` / `campaign_fundraise_yield` | 100 / 40000 | |
| `campaign_letters_xp` / `campaign_letters_standing` | 60 / 3 | |
| `campaign_mailings_xp` / `campaign_mailings_standing` / `campaign_mailings_district` | 200 / 1 / 1 | Standing to every organization with tier `Constituency` |
| `campaign_van_speech_cost` / `campaign_van_speech_district` / `campaign_van_speech_penalty` | 20000 / 2 / 2 | Penalty applies to BO18 and BO25 (put the two IDs in a Balance row too, `campaign_van_speech_penalty_orgs` = `BO18;BO25`, if the Balance tab takes text; else a Rules row) |
| `campaign_van_tier_0_cost` / `_tier_1_cost` / `_tier_2_cost` | 500000 / 1500000 / 3000000 | Paid from the campaign fund |
| `campaign_staff_hire_capital` / `campaign_staff_hire_yen` | 150 / 300000 | Each upgrade costs double the step before: tier 1 = 300 / 600000, tier 2 = 600 / 1200000 |
| `campaign_fundraiser_multiplier_tier_0` / `_1` / `_2` | 2 / 4 / 8 | |
| `campaign_organizer_letters_bonus` (tier 1+) / `campaign_organizer_mailings_national` (tier 2) | 1 / 1 | |
| `campaign_announcer_voters_bonus` (tier 1+) / `campaign_announcer_district_bonus` (tier 2) | 1 / 1 | |
| `selection_weight_strength` / `_alignment` / `_influence` | 50 / 25 / 25 | Percent |
| `selection_threshold_list` / `_smd` / `_safety_net` | 40 / 60 / 75 | |
| `campaign_moments_per_week_building` / `campaign_moments_per_week_late` | 1 / 2 | Late = `mustering` and `campaign` |
| `poll_every_weeks_building` / `poll_every_weeks_late` | 4 / 2 | |
| `poll_margin_building` / `_mustering` / `_campaign` / `_final` | 8 / 5 / 3 / 2 | |
| `campaign_office_open_date` | 18.11.01 | Only for tests and the how-to-play; the scene opens the venue |

`tests/test_balance_keys.gd` must know every new key.

### A3. Pure rules (new files in `scripts/rules/`, each with a header comment and tests)

**`ElectionCycle.gd`**
- `phase_on(date, cycles) -> {cycle_id, phase, player_runs}`: `announcement` is the Banners date itself (and starts `mustering`); `mustering` runs from the Banners date to the day before Campaign Open; `campaign` from Campaign Open to the day before Election Day; `election_day` is that day; everything else is `building` (the cycle is the next one ahead).
- `is_rehire_window(date, cycles)`: true from 1 January after an Election Day.
- `run_end_date(cycles)`: the Election Day of the Player Runs N cycle.

**`ElectionStrength.gd` (change)**
- Input `experience` becomes `capital`: `capital / election_capital_target`, max 10 points. Rename the ID to `capital` and update every reader and the Office display.
- Input `war_chest` reads `campaign_fund / election_war_chest_target`.
- `step()` takes the phase: during `mustering`, the gain limit is `election_gain_per_week_mustering` (with difficulty). Fall is unchanged.
- Stop reading `xp_earned_total` here. Do not delete `xp_earned_total` from the save.

**`CampaignOffice.gd`**
- `can_act(activity, state) -> {ok, reason_key}`: office open; work hours left (no action on weekend-only hours, as for every venue); the weekly count (`campaign_actions_per_week` outside `campaign`); costs affordable (XP for CA01–CA03, campaign fund for CA04); van owned for CA04; the player's own actions locked when Not Selected or in a Player Runs N cycle.
- `hours_for(activity, staff)`: 4, or 2 for letters and mailings with an Organizer hired and not lent.
- `resolve(activity, state) -> result`: the **order of effects**, always:
  1. base values from Balance;
  2. multipliers on the base: Fundraiser ×2/×4/×8 on yield; van tier 1 halves penalties; van tier 2 doubles rewards (tiers add up);
  3. ×`campaign_sprint_multiplier` on rewards only, during `mustering`;
  4. round half away from zero; a positive reward never rounds below 1;
  5. flat staff bonuses last: Organizer tier 1+ +1 standing on letters; Organizer tier 2 +1 National awareness on mailings; Announcer tier 1+ +1 BO18 standing on van speech; Announcer tier 2 +1 District awareness on van speech.
  A lent staff member gives no effect while lent.
- `capital_after_spend(capital, xp_spent)`: XP spent on CA01–CA03 adds to capital.
- `capital_after_week(capital)`: fades `election_capital_fade_percent`, floored to a whole number.
- `fund_after_income(fund, amount)`: capped at `election_war_chest_limit`; returns the overflow lost.

Van speech outcomes the tests must reproduce (BO18 / BO25 / District): tier 0: −2/−2/+2; tier 1: −1/−1/+2; tier 2: −1/−1/+4; tier 2 + Announcer 1: 0/−1/+4; tier 2 + Announcer 2: 0/−1/+5. In `mustering`, rewards ×1.5 before rounding (tier 0 district: +3).

**`CampaignStaff.gd`**
- Hire and upgrade prices from Balance (capital + campaign fund), the same flow and Loyalty rules as regular staff; highest tier from the row.
- Wages: reuse `StaffLoyalty.wage` with the **yen** invested only (capital does not count), paid from the campaign fund at week's end; a missed wage follows `StaffLoyalty.after_week`. Lent staff are still paid.
- `available(row, run)`: `office` rows once VN10 is open; `chain` rows once their `campaign_staff:` Activates has fired.
- Hiring is allowed any time the office is open and the date is not after the cycle's Election Day and before the next 1 January.
- The day after Election Day every campaign staff member leaves (no firing cost). From 1 January they can be hired again at the hire price, from tier 0. A chain candidate stays unlocked.
- Not Selected: campaign staff leave on the selection card.

**`PartyAlignment.gd`**
- Score 0–100 of how the player's record matches their own party.
- For each bill in the statute book where `StatuteBook.player_took_a_side` is true: find the player's party's disposition (floor vote: the party's position row; composed bill: `BillPositions.lean` against the usual threshold). Skip Neutral. Weight = |salience| (or |lean|). Agree when the player's side matches.
- `alignment = 50 + 50 × (agreed − disagreed) / total`; 50 when there is no such bill. Round to a whole number.

**`Selection.gd`**
- `score = strength × w_s + alignment × w_a + influence × w_i` (weights from Balance, percent), with `influence = (Party support + BO32 standing) / 2`.
- Outcomes: under 40 `not_selected`; 40–59 `list`; 60–74 `smd`; 75+ `smd_safety_net` (thresholds from Balance).

**`CampaignPolls.gd`**
- `due(date, last_poll_date, phase)`: Mondays; every `poll_every_weeks_building` weeks in `building` (starting with the first Monday after the office opens), every `poll_every_weeks_late` in `mustering` and `campaign`, plus a final poll on the last workday before Election Day. None in a Player Runs N cycle.
- `reading(strength, phase, is_final, run_seed, date)`: margin from Balance; the range is `strength ± margin`, shifted by a seeded offset in [−margin/2, +margin/2] from `hash(run_seed, date)`, clamped to 0–100; it always contains the true value; the same inputs give the same reading.
- `outlook(range, inputs)`: the selection outcome for the current inputs, and a second outcome when the range crosses a threshold ("likely X, could be Y").
- `movers(previous_parts, parts)`: the input that rose most and the one that fell most since the last poll (ties: input order), returned as Text keys `poll.up.<input>` / `poll.down.<input>`.
- Source: `building` = internal; later the three national outlets in turn (their names are Text rows).

### A4. Tests

One test file per rule, covering: phase boundaries for all three cycles; rehire window; capital in/fade; fund cap and overflow; the weekly count by phase; every van speech row above; Fundraiser yields (80k/160k/320k; ×1.5 in mustering); Organizer hours; lending turns effects off; wages from yen only; staff leave after Election Day and rehire at tier 0; alignment (no bills, all agree, all disagree, neutral skipped, weighted); selection thresholds at 39/40/59/60/74/75; poll range always holds the truth and is stable for the same seed and date.

---

## Phase B — the Campaign Office (`feature/p20b-campaign-office`)

- **VN10 Campaign Office** in the District zone, shown only once opened. Three screens: **Actions** (CA01–CA04 with hours, cost, effect preview, and the weekly count "1 of 2 this week"), **Campaign Staff** (a second staff screen built like the regular one: candidates, hire, upgrade, Loyalty, wage, lent status), **Campaign Van** (tiers 0–2, price, what each adds).
- **Letters** (CA02) asks the player to pick one organization (any of the 32), as other pickers do.
- **District office action "Donate to your campaign"**: moves an amount of the player's Funds into the campaign fund, one way. Steps from Balance (`campaign_donate_steps` = `10000;50000;100000;500000`). This is the only campaign step that spends Funds.
- **Office display**: campaign fund, campaign capital, campaign strength with its eight parts (rename "experience" to "campaign capital"), party alignment, and the current phase banner (in-game name).
- **Week's end** (in the existing order, after dues and staff wages): campaign staff wages from the campaign fund; capital fade; strength step with the phase's gain limit; reset the weekly action count.
- **Phase banners**: on the Banners date, a full-screen banner "Banners of War Rising"; on Campaign Open, "Gladiators of War Unleashed"; on Election Day, "Sengoku no Hi". Text rows only.
- **How-to-play pages** for the campaign (Text keys in `P20_CONTENT.md`), shown on the first visit to VN10.
- `tools/art_checklist.py` lists the new art IDs (venue background, icons `ACT_CAMPAIGN_*`, campaign staff portraits under `assets/characters/campaign/`); missing art uses the labelled placeholder.
- If `tools/economy_map.py` exists on `main`, add the new flows (campaign fund faucets and sinks, capital in and fade, the XP sink) so its `--check` passes.

---

## Phase C — Campaign Moment! (`feature/p20c-campaign-moments`)

- Extend `DecisionScenes.gd` and the scene screen: **Card** `Campaign` shows the **CAMPAIGN MOMENT!** card (same layout as DECISION!, its own colour per look and its own Text row for the label).
- **Random kind**: each day, if the phase's weekly budget (`campaign_moments_per_week_building` or `_late`) is not used up, draw at most one Random scene by weight (Weight in `building`, Weight Late in `mustering` and `campaign` when filled) from scenes whose Phase and Needs pass, that are not on cooldown, and that have not fired (unless Repeat). Use the run seed so a reload draws the same. A drawn Random scene behaves as a Mandatory scene that opens that day.
- **Speakers**: `colleague` picks a member of the player's own party from the opponents (never the leader or the three whips), fills `{colleague}` in the event's and choices' text, and is remembered for that scene's follow-ups. `CS##` speakers use the campaign staff portrait and name. `{campaign_staffer}` names the staff member a lending choice will lend (the one free staffer with the highest tier; ties by ID).
- **Activates**: `venue:VN10` opens the office; `campaign_staff:CS##` makes a chain candidate available; `challenge:CA01x3in14` starts a challenge (count completed CA01 actions within 14 days of the choice); the follow-up whose Follow If is `challenge_met` or `challenge_failed` opens on its Delay, judged at that moment.
- **Choice columns**: Campaign Fund Delta (a cost is refused, with the choice greyed out, when the fund cannot cover it); Donate Funds; Lend Campaign Staff Weeks (marks the staffer lent until that date: effects off, wage still paid); Favor Owed (add `{colleague_id, scene_id, date}` to the run's favor list; nothing spends favors yet); Needs hides the choice.
- **Pacing guard**: Campaign Moments! never count toward `campaign_actions_per_week`. Their hours come from the workweek like any event.
- **Content**: add every row in `P20_CONTENT.md` (DS11–DS24, EV120–EV133, their choices, and the Text rows). DS11 is Mandatory on 18.11.01.
- In a Player Runs N cycle, from its Banners date: only DS22–DS24 can draw; the chains and own-office scenes cannot.

---

## Phase D — selection, polls, Sengoku no Hi, the run's end (`feature/p20d-selection-polls`)

- **Selection card** (a system screen, every cycle the player runs): on the morning of Campaign Open, before anything else that day. Shows the score's three parts, the score and the outcome (Text rows `selection.outcome.<id>`). Store `{cycle_id, score, outcome}`.
- **Not Selected**: from the card on, the player's own campaign actions and Campaign Moments! stop for that cycle; campaign staff leave. On Election Day: **game over** with Text rows `game_over.not_selected.*`, using the existing game-over flow.
- **Selected**: on Election Day call `ElectionOutcome.resolve(cycle, selection, strength)`, a new pure stub that returns `seated` and records it. Leave a header comment describing the decided direction: an SMD seat can be lost on low strength (game over), the safety net falls back to a list seat, and results will feed party and personal success through thresholds like bill influence. No numbers yet.
- **Polls**: a read-only card (same family as the selection card) when `CampaignPolls.due` says so: source name, strength range, outlook (or the selection result once given), an arrow against the last poll, and the two mover lines. Keep a poll history the Office can list.
- **Stepping aside (Player Runs N)**: on its Banners date, the Mandatory narration scene DS25 / EV134 "Stepping Aside" (in `P20_CONTENT.md`) — add it in this phase with Kind Mandatory and Opens = the EC03 Banners date. No selection card, no polls. The player's own office actions are closed. On its Election Day the run ends on an ending screen (Text rows `run_end.stepped_aside.*`), using the existing end-of-run flow if there is one; if there is none, ask before building one.
- **Save**: add to the save keys (GameState's list near the `election_strength` key) every new field: campaign fund, capital, campaign staff (tier, Loyalty, invested yen, lent until), van tier, actions this week, the current cycle and phase, selection results, poll history, favors, open challenges, `van_speech_done`, Random scene cooldowns. Older saves load with defaults.

---

## Checks before each merge

- `tools/verify.sh` prints "All checks passed".
- The exporter runs clean on the workbook with the new tabs and rows.
- A bot or scripted run from 18.10.01 to 21.12.12 (Relaxed) opens the office on 18.11.01, takes campaign actions, hires an A candidate, sees a poll every 4 weeks then every 2, gets a selection card on 21.11.30 and reaches Sengoku no Hi. Note the final strength, alignment, score and outcome in the change log entry.
- Change log (CLAUDE.md section 15): one line per phase, "(2026-11-25, Cameron; branch …)".

## Finish

Report per phase: files changed, the new tabs and Balance rows, test counts, and anything you had to decide that this prompt did not (each as a question for Cameron, not a silent choice).
