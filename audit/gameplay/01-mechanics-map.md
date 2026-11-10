# Phase 1: Mechanics map

Godot 4.5.1 (`project.godot:16` `config/features` "4.5"), GL Compatibility, GDScript only. Commit reviewed: `149dad5`/`cdb19ee` on `main`, 2026-11-10.

**About "the intended feel":** the brief's context section arrived blank, so there is no stated target feel or session length to measure against. I judged against the project's own design documents (`design/GAME_DESIGN.md` "two loops wearing one skin: a card battle and a resource loop that decides how hard the next battle will be"). Where a session-length target would matter, I say what the code does and mark the comparison as needing your target.

This is a card-battler with a management layer, so "movement" and "combat" map to turns, hands and rooms. The code keeps rules and screens apart: rules in `scripts/rules/` (no UI, no autoloads), state in `scripts/autoload/GameState.gd`, screens in `scripts/ui/`.

## The mechanics

Legend: **R** = reads, **W** = writes, **T** = touches (other mechanics it feeds or is fed by).

### A. The battle (one room)

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| A1 | **Turn loop**: intent shown, energy refills, hand draws, player plays cards, end turn, opponent acts, check outcome | `BattleEngine.gd` `end_turn` (L551), `_draw_up_to_hand_size` (L1617) | Player taps End turn | R: stage row (energy, hand size, turn limit), `rules.json` (discard hand, pass penalty). W: `BattleState` (turn, energy, hand, deck, discard, bar, block, gaffe) | A2-A9, B-series |
| A2 | **Play a card**: pay energy, resolve effect, apply support / guard / gaffe / draw, then answer the open question | `BattleEngine.play_card` (L331), `CardResolver.gd`, `_apply_effect` (L440) | Tap a card | R: card row, affinity, question grade, standing context, `next_card_bonus`. W: bar, guard, gaffe, hand | A3, A4, A6, A8 |
| A3 | **Affinity** (suit x room multiplier ~0.5x to 1.5x) | `BattleEngine.affinity_for` (L532), `data/affinity.json` | Every card play | R: card suit, stage id | A2, deck building (D2) |
| A4 | **Support bar models**: Shared pool (you / them / undecided), Single (press tone), Survival (TV debate, rising line), Committee (several opponents, reset) | `BarModel.gd`, `_build_bar` (L289) | Stage setup, every card | W: player / opponent / undecided counts | A5, A7 |
| A5 | **Winning people over**: undecided cost 1; opposed cost 1/2/3 at 60/30/10%, rolled per person | `BarModel.player_gains` | `_apply_effect` | R: bar, RNG (seeded). W: bar | A4 |
| A6 | **Guard bank**: carries between turns, capped (`guard_cap` 5), absorbs attacks first | `_apply_effect` (L478-486), `_resolve_intent` (L819) | Guard cards, opponent attack | R/W: `state.block` | A1 |
| A7 | **Opponent intents** (attack / gain / block with ranges, shown one turn ahead) | `IntentRunner.gd`, `_arm_intents` (L251), `_resolve_intent` (L819) | End turn | R: opponent row (patterns). W: player bar, opponent bar, opponent guard | A4, A6 |
| A8 | **Gaffe meter**: some cards add, apologies clear; at the limit the stage is lost at once | `_apply_effect` (L488-499), `_check_outcome` (L858) | Card effects | R/W: `state.gaffe`; Campaign Pressure moves the limit | F-series (awareness), stage loss |
| A9 | **Pass penalty**: ending a turn with no card costs energy next turn (or pool energy at once) and declines the open question | `_pass_penalty` (L787), `_decline_question` (L805) | End turn with zero cards | R: `rules.json` pass_energy_penalty, stage `decline_tone_cost`. W: energy, bar | A10 |
| A10 | **Questions**: a room draws questions (own Stage Questions up to a third, then pool; bill questions up to 50% in bill levels); answers are graded Strong / Medium / Weak per suit | `_draw_questions` (L692), `_answer_question` (L1330), `_grade_of` (L1409) | Card played while a question is open | R: `data/questions.json`. W: pleased / displeased organizations tally, multipliers 1.3x / 0.7x | G-series (standing) |
| A11 | **Win / loss rules**: threshold, opponent at 0, player at 0, gaffe limit, turn limit (loss), survival line, press close | `_check_outcome` (L858), `_check_turn_limit` (L1003) | After every card and end of turn | W: `state.outcome` | B2 |
| A12 | **Multi-opponent stages**: committee (full reset between bouts), floor debate / caucus (carry over) | `_advance_to_next_opponent` (L1514), `_reset_for_new_bout` (L1540), `StageCarryOver.gd` | An opponent reaches the threshold or 0 | W: `state.opponent_index`; checkpoint save | H4 (save) |
| A13 | **Items in a stage**: use a consumable mid-battle (extra energy, hand, guard, etc.) | `BattleEngine.use_item` (L1672), `GameState.use_item_in_stage` (L3650) | Inventory tap | R/W: `inventory`, battle bonuses | C-series (shop) |
| A14 | **Abandon Level** (new 2026-11-10): asks, then loses the stage and ends the level | `BattleEngine.forfeit`, `LevelRunner.abandoned`, `BattleScreen._abandon_level` | Stage info panel | W: outcome loss, level over | B2, penalties |

### B. Levels and stages

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| B1 | **Level runner**: an ordered chain of stages; a loss ends the level unless the stage says otherwise; crisis stages can be inserted | `LevelRunner.gd` (L166 `finish_stage`) | Start a level | W: index, results, outcome | B2, B5 |
| B2 | **Finish stage / end of level**: clock and calendar advance, deltas apply, crisis checks, level rewards, laws, cooldown, autosave | `GameState.finish_stage` (L2440) | Result panel closed | R: stage, outcome. W: nearly all run state | everything |
| B3 | **Level selection rules**: unlock cost (XP by researcher rank), cooldown, hours fit, weekend flag, season, discovery, one-time, event-only | `Ledger.gd`, `OfficeScreen._show_levels` (L2851), `GameState.level_calendar_refusal` (L1819) | Office Levels panel | R: `levels.json`, clock, calendar, XP | C, E |
| B4 | **Level Intro**: purpose line, staff lines, bill card, lean choice | `LevelIntroScreen.gd`, `BillLean.gd` | Start a level | W: `bill_stance` | F5 (bills) |
| B5 | **Stage transitions** (who speaks between stages) | `StageTransitionScreen.gd`, `StageTransition.gd` | Between two stages | presentation only | none |
| B6 | **Special levels**: Town Hall when Constituency support <= 15, Steering check-in when party opinion < 25, forced after the next ordinary level | `GameState._check_town_hall` (L2598), `_check_steering_committee` (L2612), `SpecialLevels.gd` | After any stage or Office time | W: `special_levels`, `special_forced` | D (decline), recovery |
| B7 | **Non-combat levels** (Office Hours, festivals, walkabouts; Tiers 0-2) | stages with mode "Non-combat", `OfficeHoursEngine.gd`, `VisitorScreen.gd` | Pick the level | R: visitor questions. W: organization standing, Funds, XP, hours | G, E |

### C. Economy: meta numbers, XP, shop, backings, staff

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| C1 | **Four meta numbers** (Constituency support, Reputation, Funds, Party support), clamped to ranges, Funds capped | `GameState._move_meta` (L2920), `MetaRules.gd`, `data/sanban.json` | Stage wins and losses, events, purchases, decay | R: sanban rows. W: `meta` | everything |
| C2 | **XP** earned and spent; lifetime XP never falls | `GameState._move_xp` (L2903) | Stage / level wins, shop, unlocks | W: `xp`, `xp_earned_total` | C5, B3 |
| C3 | **Level rewards**: stage win deltas + level bonus ranges + per-organization deltas, scaled by Campaign Pressure | `_apply_stage_rewards` (L2672), `_pay_level_rewards` (L2745), `_apply_level_bonus_win` (L2779) | Stage / level win | R: stage, level rows, difficulty. W: meta, XP, standing | C1, G |
| C4 | **Funds cap and funding freeze** (cap 100,000円 + petitions up to 1,000,000; at Party support 0 stage and level Funds income is 0) | `funds_limit` (L2876), `_check_funding_freeze` (L2581), `_unless_frozen` (L2845) | Any Funds gain | W: capped Funds | F3 |
| C5 | **Rhetoric Training**: pay XP or Funds, see one random unowned card, learn or pass (up to 3 looks, last must be learned) | `offer_random_card` (L3245), `pass_offered_card` (L3258), `learn_offered_card` (L3293) | Office | R/W: `card_draw`, `owned_cards`, XP/Funds | D2 (deck) |
| C6 | **Deck**: fixed size (15 + bought slots), owned cards only, legality rules | `set_deck` (L1155), `Ledger.deck_is_legal` | Office Deck panel | W: `deck` | A2 |
| C7 | **Shop and inventory**: stack caps, per-level purchase limits, consumables (stage/level buffs, standing actions, hosted dinners, gifts) | `buy_shop_item` (L3210), `add_item` (L3198), `Items.gd` | Office Marketplace | W: `inventory`, XP/Funds | A13, E |
| C8 | **Backings** (53): standing and price gates, permanent or timed effects, lapse and rebuy | `buy_modifier` (L858), `ModifierEffects.gd`, `_expire_modifiers` (L886) | Office Boosters | W: `owned_modifiers`, `modifier_expires` | A (start bonuses), F |
| C9 | **Staff** (3 roles, ranks, extras, primary, firing severance) | `hire_staff` (L946), `upgrade_staff` (L978), `fire_staff` (L1026), `make_primary` (L1073) | Office Staff | W: `staff_hired`, `staff_extra` | B4, F5 (research) |
| C10 | **Cosmetics** | `buy_cosmetic_package` (L817) | Office Appearance | decorative | none |
| C11 | **Promises**: owed items / hours / Funds, 48-hour default deadline, paused during levels, kept in the Office | `Promises.gd`, `keep_promise` (L1953), `_break_overdue_promises` (L1867) | Visitor / event choices | W: `promises`; standing | D, G |

### D. Time, week and decline

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| D1 | **Two clocks**: visible calendar (40 work hours + 8 weekend) and hidden `time_units` | `WeekCalendar.gd`, `TimeClock.gd`, `GameState._advance_clock` (L1846) | Stage end, events, week end | W: `calendar`, `time_units` | B3, cooldowns |
| D2 | **Go home / week end**: settle dues, awareness effects, election strength, decay, advance to Monday, roll event | `go_home` (L2033), `_settle_dues` (L2129) | Office weekly button | W: Funds, standing, `calendar` | all decay |
| D3 | **Party dues**: 50,000円 base + 50,000円 per 15 Party support over 40 + 15% (Standard: 15%) of the week's Funds earned; unpaid dues roll over; shortfall penalties | `PartyDues.gd`, `_settle_dues`, `dues_preview` (L2114) | Week end | R: `week_funds_earned`, Party support. W: Funds, `dues_balance`, standing | C4, F |
| D4 | **Decay**: neglect drift, per-organization decay %, Constituency support and Reputation decay, all x multiplier (2.5 Standard) | `_apply_week_decay` (L2170), `_apply_neglect_decay` (L2186), `_apply_meta_decay` (L2213) | Week end | W: standing, meta | C1, G |
| D5 | **Awareness** (District / National) and **consequences** (dues cut, free coupon, room start bonus, standing / XP penalties) | `AwarenessEffects.gd`, `apply_awareness_delta` (L1221), `_apply_awareness_week_end` (L2061) | Wins, gaffes, week end | W: `awareness`, `awareness_gaffe_tally` | A8, D3, G |
| D6 | **Election strength**: slow score toward eight inputs; fires nothing yet | `ElectionStrength.gd`, `_update_election_strength` (L1287) | Week end | W: `election_strength` | scoring only |
| D7 | **Events**: random (rolled at week end), dated, arranged (bought); follow-ups tied to kept promises | `EventEngine.gd`, `apply_event_choice` (L1403), `roll_random_event` (L1386) | Office | W: meta, XP, standing, `scheduled_events`, `promises` | C, G |
| D8 | **Crisis latches**: Town Hall, Steering, funding freeze, Party Backing, lifetime gaffes (-15 once at 50) | `check_crisis_triggers` (L1858), `_record_lifetime_gaffes` (L2558) | After stages | W: latches in `GameState` | B6 |

### E. Standing (people)

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| E1 | **Organization standing** (32): question answers (net +/-10 per stage, banded gains/losses), visitor answers, laws, promises, hosted events, links | `BoosterStanding.gd`, `BoosterChange.gd`, `_apply_booster_delta` (L3891), `StandingLinks.gd` | Many | W: `booster_standing` | C8 (backings), F (bills), E3 |
| E2 | **Party opinion** (6 parties): direct number blended with linked organizations, scaled by salience | `PartyOpinion.gd`, `PartySalience.gd`, `party_opinion` (L3950), `party_support_effective` (L3958) | Votes, rewards | W: `party_standing`; own party into Party support | D3, F |
| E3 | **Hosted events** (walking tour / dinner) reveal hidden levels, add standing | `HostedEvent.gd`, `begin_hosted_event` (L1598), `reveal_by_hosting` (L3630) | Marketplace items | W: standing, `discovered_levels` | B3 |
| E4 | **Audience segment favorability** | `_apply_segment_delta` (L4323) | none now | stored, **read by nothing** (see finding in Phase 3) | none |

### F. Bills, votes, laws, patrons

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| F1 | **Lean** (Support / Oppose) at the Level Intro, standing drift on wins, flip penalty at the vote | `BillLean.gd`, `BillStance.gd`, `set_bill_lean` (L4160), `apply_stance_vote` (L4247) | Level Intro, vote | W: `bill_stance`, standing | A10, E |
| F2 | **Floor Vote**: 101 seats, 51 to pass (abstain counts against), supermajority bills, your seat, party splits | `FloorVoteEngine.gd` (`choose` L243), `FloorVoteScreen.gd` | Vote stage | R: party positions. W: tally, favorability | F3-F6, E2 |
| F3 | **Whip**: Party support spent to move own-party seats, floor 30, max 3 | `VoteWhip.gd`, `_apply_whips` | Floor Vote | W: Party support, seats | D, C1 |
| F4 | **Influence swing**: when all gate rows clear, other parties give seats up to a resistance | `VoteInfluence.gd`, `_apply_influence_swing` | Floor Vote | R: Reputation, standing. W: seats | E |
| F5 | **Member visit / win over a member**, **Lobbyist trade**, **Patron visit** | `MpVisit.gd`, `LobbyistTrade.gd`, `PatronVisit.gd`, `BillAssist.gd` | Sponsored / drafted levels | W: seats, standing, Funds, XP | F2 |
| F6 | **Vote Projections and Vote Intention Research** (new) | `VoteProjection.gd`, `GameState.buy_research_briefing` (L2334) | Floor Vote screen | W: XP, hours, `vote_unknown_percent` | C9 |
| F7 | **Laws** (Legislative Work): effects pay once, some every later level | `StatuteBook.gd`, `record_floor_vote` (L4097), `_apply_law_effect_rows` (L4306) | After a vote | W: meta, standing | D |
| F8 | **Patron requests**: carry, amend, decline for standing 50 / 70 | `PatronRequests.gd`, `patron_bills_due` (L4402), `start_patron_level` (L4457), `PatronLevel.gd` | Standing reaches threshold | W: `patron_requests`, `enacted_components` | F2, E |
| F9 | **Drafting your own bill**: 350 XP + 300,000円, 90-hour cooldown, optional extra visit | `DraftBill.gd`, `start_draft` (L4545) | Office | W: XP, Funds, `patron_drafts` | F8 |

### G. Failure, retry, persistence

| # | Mechanic | Lives in | Triggered by | R / W | Touches |
|---|---|---|---|---|---|
| G1 | **Loss**: the level ends (unless the stage says no), loss deltas apply, cooldown starts, next level free to try | `LevelRunner.finish_stage`, `finish_stage` (L2440) | Stage lost | W: meta, standing | B3 |
| G2 | **Autosave** after every stage, Office actions and when the OS pauses (not mid-stage) | `SaveManager.gd` | Many | writes `user://savegame.json` + `.bak` | all |
| G3 | **Checkpoint** inside a multi-opponent stage when an opponent falls | `BattleEngine.checkpoint` (L1440), `GameState.stage_checkpoint` | Opponent defeated | W: saved stage state | A12 |
| G4 | **Manual backup / restore / undo** | `SaveManager.backup_now`, `restore_backup`, `restore_undo` | Administration | extra files | G2 |

## The core loop, as the code implements it

1. **Choose** a level in the Office (price, cooldown, hours, season, discovery all checked).
2. **Intro**: staff lines, bill card, choose a lean.
3. **Fight** one to ten stages. Each stage is a short race: you see the intent, spend 3-6 energy on cards from a 5-card hand, finish a turn, take a hit or lose a pool share. Ends in a win, loss or (non-combat) completion.
4. **Result**: a panel shows what moved. Win pays Funds, XP, Reputation, Constituency support and organization standing; a loss charges the loss deltas and usually ends the level.
5. **Back to the Office**, with hours spent on the calendar and the hidden clock advanced.

## The meta loop

1. **Spend** XP and Funds: Rhetoric Training for new cards (the only source), backings, staff, items, level unlocks, deck slots, Funds-cap petitions.
2. **Stay solvent**: the work week is 40 hours; going home pays party dues, runs decay (2.5x at Standard), advances to Monday and may roll an event.
3. **Grow standing** with organizations so they offer backings and sponsored bills; carry bills to a Floor Vote for laws.
4. **React** to crisis latches: low Constituency support forces a Town Hall; low party opinion forces a check-in; Party support 0 freezes income.
5. Run **forever**: there is no ending. Election strength grows toward a campaign that fires nothing yet.

## Where the code differs from the design intent

| Design intent (from `GAME_DESIGN.md`) | What the code does | Note |
|---|---|---|
| "Two loops that feed each other tightly" | The battle loop feeds the resource loop strongly (rewards, standing). The resource loop feeds the battle through three channels only: deck (cards from Rhetoric Training), backings (start bonuses, guard) and items. Meta numbers affect room starts only in press-style and town-hall rooms (Reputation/awareness +/-5). | A strong run of Funds and standing does not make a combat room easier by much once the deck is fixed (Phase 4). |
| Election strength is a campaign score | Built, shown, wired to no outcome | There is no ending, win state or lose state for the run: the only failure is slowly sinking numbers. A human should judge whether that gives enough purpose (playtest item). |
| Audience segment favorability | Stored and saved; nothing reads it (`GAME_SYSTEMS.md` says so) | Dead state; harmless; see Phase 3. |
| "Cards are the only way new cards arrive" and "deck is fixed size" | True. 70 cards, the opening deck is 15, so collecting tiers 1-3 means leaving cards out | Fine; it makes Training a tradeoff. |
| Weekly pressure (dues, decay) | Dues scale with Party support and income; decay is 2.5x at Standard | The earlier strategy playtests found dues larger than the Funds cap allows (Phase 4 re-runs this). |
| Sound and feedback | No audio files exist; haptics are not used anywhere | Feedback is visual only (Phase 6). |
