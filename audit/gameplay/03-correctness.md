# Phase 3: Correctness

Read-only review of 2026-11-10 at the same commit as the project audit. "Unverified" means I read the code but did not run it on that path. Nothing was changed outside `audit/gameplay/`.

Finding format:
ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

## Executive summary

| Area | Result |
|---|---|
| Frame-rate dependence | **None found in rules.** The battle is turn-based and no rule reads delta time. `Time.get_ticks_msec` is used only by `DragScroll.gd:78,118` (scroll flick). Gameplay does not read the real-time clock at all, so changing the phone's clock does nothing (see Phase 5). |
| Simultaneous events | One ordering rule matters: gaffe loss is checked before win (`BattleEngine.gd:858-866`). Deliberate, but it means the last card that crosses the threshold and the gaffe limit together is a loss. Flagged for a design decision. |
| Awaits after the scene is gone | Clean. Four awaits, each re-checks `is_instance_valid` (already established in `audit/02-code.md`). |
| Persistence | **The main weakness.** Nothing inside a stage is saved except at an opponent's defeat, and a loss is only applied when the result panel is closed. Two consequences below (G-01, G-02). |
| Boundaries | Mostly guarded (`maxi`, clamps, `int(null)` guards). Two unbounded values: the overdue multiplier and the one-time level consumption (G-04, G-05). |

Findings: 1 High, 5 Medium, 3 Low. No crash or softlock was found in the code paths I read.

## Findings

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| G-01 | High | Stage loss / save | `scripts/ui/BattleScreen.gd:1332-1362` (`_on_outcome_closed`); `GameState.gd:2440` (`finish_stage`); `SaveManager.gd` (`autosave` returns early while `mid_stage`) | A loss is applied only when the player presses Close on the result panel. The engine has already decided the outcome, and the panel shows it, but `finish_stage` (which charges loss deltas, bumps loss counters, consumes a one-time level and autosaves) runs only from the close handler. A player who sees "Lost" can force-close the app, reopen at the last save (before the stage, because `mid_stage` blocks saving), and get a free retry with no loss cost. The same applies to Abandon Level. Winning is symmetric, so a win is also lost on a force-close, which limits the abuse to "retry only what you lost". | `BattleScreen.gd:1354` `GameState.finish_stage(state.outcome, ...)` is called only inside `_on_outcome_closed`; `BattleScreen.gd:164` connects `%OutcomeClose.pressed` to it; `_save_checkpoint` (L287) only runs at opponent defeats (L1066, L1189). **Not executed**: I did not kill a running game. | Apply `finish_stage` the moment the outcome is reached and show the panel afterward; or write a "pending result" into the save when the outcome is decided. | M | Medium |
| G-02 | Medium | Mid-stage progress | `BattleScreen.gd:354-356`; `SaveManager.gd:11-13` | A stage in progress is not saved. Already reported as C-02 (project audit). New here: the battle RNG is not seeded per stage, so the retry gets a different shuffle, which turns the app-kill into a re-roll of luck as well as a rewind. | `scripts/BattleSetup.gd:351-355` (`_rng`, "unseeded, like every roll here") draws the people for a bout; I did not find a per-stage seed used by `BattleEngine` (unverified: I read the setup path, not every RNG call). | Same fix as C-02; if a checkpoint is added, store the RNG state with it. | M | Medium |
| G-03 | Medium | Gaffe vs threshold | `scripts/rules/BattleEngine.gd:861-866` | Gaffe loss is evaluated before the win check, so a card that both fills the gaffe meter and pushes support past the threshold is a loss. This is an intentional order ("Losing on gaffes happens the moment it happens") but it is not mentioned in `GAME_SYSTEMS.md` section 7 (unverified: I searched for the phrase and did not find it) and the player is not told. | `_check_outcome` returns after the gaffe test, before any threshold test. | Decide whether a simultaneous cross is a win or a loss and say so in How to Play. If it should be a win, test the threshold first for the same card. | S | High |
| G-04 | Medium | Party dues | `scripts/rules/PartyDues.gd:55-56`; `data/balance.json` dues rows | The overdue multiplier is `scale_factor ^ (owed / scale_per)` with no ceiling. In the 30-week sims the baseline strategy ended with 5.2 M owed (median) and 26 weeks overdue. The next week's dues can then become arbitrarily large while Funds are capped at 100,000 to 1,000,000, so a player who falls behind cannot recover by play (see 04-balance). | `overdue_multiplier` uses `pow` and `maxi(0, owed)` only. Sims: `audit/gameplay/sim/analysis_output.txt`. | Cap the multiplier (new Balance row) or cap total owed. Cameron has previously seen and left the cap/dues cliff (strategy playtest 2026-11-02), so this is a flag, not a new surprise. | S | High |
| G-05 | Medium | One-time levels | `data/levels.json` (`one_time`, 50 of 114 levels); `GameState.finish_stage` | A one-time level vanishes after it ends, whether it was won or lost. A loss on a bill level therefore removes that bill from the run permanently. Combined with G-01 (loss only registers on Close) and with a 98 % bot win rate this is rare for bots, but for a human who loses a flagship bill it is a one-shot with no second try. | Established in the earlier stretch from `cooldown`/`one_time` fields; the 5994 sentinel appears on 51 of 114 levels. Which loss paths consume a level was read, not exercised. | Confirm with Cameron whether a lost one-time level should return after a cooldown. | S | Medium |
| G-06 | Medium | Patron request start | `GameState.gd:4457-4481` (`start_patron_level`); `tools/playtest_optimal.gd:944-950` | The strategy bot reported "a due patron bill could not be started" 1,472 times in 48 of 56 runs. The likely cause is the work-week rule (`work_week_level_refusal`, `GameState.gd:1834-1842`): the level needs more hours than are left in the week. The bot then calls `decline_patron_bill`, which costs standing. A real player would wait for next week, so this is probably a bot artifact, but it shows a due request can be un-startable for hours at a time with nothing but a refusal string. | Bot code declines on `false`; `start_patron_level` returns false for work-week refusal, an already-final status, or a failed compose. I did not log which of the three triggered. | Have the bot log `GameState.last_level_start_refusal`; check the Office shows the reason when a due request cannot start. | S | Low |
| G-07 | Low | Press conference end | `BattleEngine.gd:872-910` | The conference ends "at the end of the turn" once questions run out, and the empty-hand rule differs by `draw_mode`. Two rules with their own history comments (2026-09-25, 2026-10-10, 2026-10-16) is a boundary-heavy area; a test exists per past bug, but a hand that empties exactly as the last question is answered in a `draw_mode != "none"` conference was not found in the tests I searched. | Comments in the function; I did not search `tests/` exhaustively. | Add one test for "last question answered with last card in hand, deck and discard empty". | S | Low |
| G-08 | Low | Abandon patron level | `GameState.gd:4374-4381` | An abandoned patron level returns to OPEN (or LAPSED if drafted) with no standing cost shown here. If the Leave button charges its penalty elsewhere that is fine; if it does not, abandon is a free retry of an un-drafted patron bill. | `abandon_level` itself writes no deltas; the penalty path was not traced. | Trace what the in-stage "Abandon Level" button charges and add a test. | S | Low |
| G-09 | Low | Quit fallbacks | `BattleScreen.gd:1336-1337` | `_on_outcome_closed` quits the app when no level is in progress. Already C-05 in the project audit. Listed here because it is also a state-machine hole: any state slip at the result panel ends the game. | `if not GameState.is_in_level(): get_tree().quit()` | See C-05. | S | High |

## Mechanic by mechanic

| Mechanic | State machine | Frame rate | Timing | Boundaries | Persistence |
|---|---|---|---|---|---|
| Play a card | `play_card` rejects when over, short of energy or card not in hand (read, L331) | n/a | One card resolves synchronously, so no ordering race | Zero-energy and full-hand cases guarded | Not saved mid-stage (G-02) |
| End turn / pass | `_pass_penalty` charges energy after a pass (rules switch `pass_energy_penalty` 1) | n/a | Opponent intent resolves after the player's turn, synchronously | Energy cannot go negative (`maxi`) in what I read | Same |
| Gaffe meter | Loss at `gaffe >= gaffe_limit` | n/a | Checked before threshold (G-03) | Limit 3 to 5 per stage | Same |
| Turn limit | Rule switch `turn_limit_outcome` = loss | n/a | End-of-turn check | Last turn: win by the final card still counts | Same |
| Win bar | `BarModel` win-over costs | n/a | n/a | 100 % of bar cap clamps | Same |
| Stage result | Result panel then `finish_stage` | n/a | Close handler is the only trigger (G-01) | Rewards clamped by `_move_meta` | Autosave at finish |
| Week and dues | `_settle_dues`, `_apply_week_decay` | n/a | Run at week change, synchronously | Overdue multiplier unbounded (G-04) | Saved |
| Promises | Deadlines pause during a level | n/a | Resume on `abandon_level` and `finish_stage` | A promise due exactly at a week boundary was not exercised | Saved |
| Floor vote | Whip, influence, Unknown 10 to 25 % | n/a | Computed once when the screen opens | Rounding of percentages unverified | Not saved mid-vote |

## What I could not settle from code

| Question | Why code cannot answer it |
|---|---|
| Does a force-close on the result panel really give a free retry? (G-01) | Needs a run on a device or editor with a kill at that moment. |
| Does the OS pause/resume cycle leave a battle in a usable state? | No build on a device. |
| Does the app resume mid-turn animation correctly after a phone call? | Presentation timers (tweens) were not exercised in background. |
