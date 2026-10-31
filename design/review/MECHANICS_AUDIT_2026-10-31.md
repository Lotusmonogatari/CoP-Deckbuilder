# Mechanics audit (2026-10-31)

Cameron asked for a review of every game mechanic: code, workbook,
interdependence, activation and deactivation, timing, rewards and penalties.

## Executive summary

- **Two real bugs, both fixed:** promises that fell due during a stage were not
  broken until later Office time passed; and EV14 C charged its 20,000円 twice.
- **Two design questions, now decided and built:** the Funding Freeze also
  stops level rewards, and crisis triggers react straight away to changes made
  outside a stage.
- **Two balance flags** from the bot: Media Ambush (ST19) and the Committee on
  Finance (ST16) are almost never won. Cameron chose to leave both as they are.
- **The data checks came back clean:** every Balance and Rules lever is read,
  no room or visitor is orphaned, and four full bot runs (one per protagonist)
  hit no script errors.

## How it was checked

| Layer | Method |
|---|---|
| Workbook ↔ code | A script cross-checked stages against levels, visitors against rooms, and Balance and Rules keys against the scripts, including keys built at runtime such as `trade_%s_%s_seats` and `patron_visit_%s_%s`. |
| Code paths | Read the clock and calendar, decay, backing expiry, timed item bonuses, special levels, events, commitments and promises, follow-ups, level end (laws, cooldowns, one-time levels, patron levels), stage rewards and penalties, and the Funding Freeze. |
| Runtime | `tools/playtest_optimal.tscn`: a full run for each of PC01-PC04. |

## Findings

| # | Area | Severity | Finding | Status |
|---|---|---|---|---|
| 1 | Timing: promises | Medium | A stage's hours moved the clock and lapsed timed backings, but never checked promises. A promise that fell due during a level stayed open until the next event, kept promise or week end. | **Fixed.** `finish_stage()` now takes the same clock step as Office time (`_advance_clock`). Test: `test_promises.gd`. |
| 2 | Cost: EV14 C | Medium | "Pay a consultant to calm it" had both a Funds Cost (20,000) and a `Funds 20000` Commitment. It charged 40,000 and showed the price twice. | **Fixed.** The Commitment cell, which came from the commitments rewrite, is cleared. The exporter now gives an error when a choice has both. |
| 3 | Activation: Funding Freeze | Decision | The freeze zeroes only a **stage's** Funds win reward. It still pays the level's win bonus range (`bonus_win_range_yen`), the Funds bonus a backing gives for a level win, event, visitor and law Funds, and promise and trade donations. CLAUDE.md §8 says "Funds income becomes 0". | **Decided: stage + level rewards.** The level's win bonus range and a backing's level-win Funds bonus are now frozen too. Events, visitors and laws still pay. Test added. |
| 4 | Timing: crisis triggers | Decision (low) | The Funding Freeze, Town Hall and Steering Committee triggers are checked only when a stage ends. If an event, a broken promise, dues or weekly decay pushes a value over a line, the trigger starts at the next stage end. The Special Level countdown begins then too. | **Decided: react straight away.** `check_crisis_triggers()` now also runs after Office time passes, after an event, after a kept promise and at the week's end. Test added. |
| 5 | Balance: ST19 Media Ambush | Flag | The bot won 0 of 15 across four runs. A loss does not end the level (`loss_ends_level` = No), so it only costs the loss deltas. Media Ambush was left alone on 2026-10-13. | **Decided: leave as is.** |
| 6 | Balance: ST16 Committee on Finance | Flag | The bot won 10 of 81 (threshold 84, three opponents). By comparison it won ST15 43 of 78 and ST03 53 of 64. | **Decided: leave as is.** |
| 7 | Timing: deadlines | Low | A promise's deadline and a follow-up's delay start counting **before** the event's own hours are spent, so a 2-hour event takes 2 hours off a "within 72". The longest event is 2 hours, so the effect is small. | Noted; left as is |
| 8 | Rewards: backing grants | Low | A reward or a passed Flagship that grants a backing the player already holds on a timer does not extend that timer. | Noted; left as is |
| 9 | Rewards: promises with no organization | Known | 12 visitor-room promises have no organization to owe: the choice only lowers standing and the cell has no `for BOxx`. Breaking one costs Reputation only. This was accepted earlier ("unnamed OK"). | Unchanged |

## Checked and sound

| System | What was confirmed |
|---|---|
| Decay | `decay_interval` is 0, so decay runs once a week (×2.5) and never also on the clock. |
| Backing expiry | `_expire_modifiers()` runs on every clock step. Withdrawing the party backings for unpaid dues also clears their timers. |
| Timed item bonuses | They are filtered by `expires_at` each time they are read. |
| Event panel | It cannot be dismissed, so a follow-up event is never lost without a choice (each follow-up has a Decline). |
| Event → level | The event's hours plus the level's hours must fit in the hours left. A weekend start needs a level marked weekend-OK. Back returns to the event with nothing spent. |
| Promised items | SH30-SH32 are all on sale in the Marketplace, with no purchase limit. |
| Level end | Cooldowns count wins and losses. Patron levels are excluded from cooldowns. "Each level" laws pay on wins and losses. Level rewards are paid only on a win. |
| Workbook levers | Every Balance and Rules key is read by a script or by the exporter. |
| Runtime | No `SCRIPT ERROR` in four full bot runs. |
