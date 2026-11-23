extends Node
## Holds the state of the current run: which level is being played, how far
## through it the player is, where the player's standing sits, and how the
## last level went.
##
## This is the campaign's memory. It is deliberately separate from the rules
## engine, which is the maths of a single battle and remembers nothing.
##
## Everything here is written to disk by SaveManager (to_save() and
## load_save() below), so quitting and reopening carries on the same run.
## A battle itself is not saved: reopening mid-stage starts that stage again.

## Which of the four protagonists (data/player.json) this run is played as.
var protagonist_id: String = ""

## True from boot until a protagonist is chosen, when there was no save to
## load. The Office opens the New Game screen while it is set. SaveManager
## sets it; tests and the editor never do, so they start as the default.
var awaiting_new_game := false

## True while a stage is being fought. A save is not taken then — the last
## one, from the stage boundary, is the one to come back to.
var mid_stage := false

## The share of the house the Floor Vote screen hides as Unknown (draft
## 2026-11-08). Drawn between two Balance numbers when a level begins and
## each time a stage ends, so it is fixed before the vote screen is built and
## cannot change by reopening it. 0 = not drawn yet (the screen draws it).
var vote_unknown_percent := 0

## True once the player has bought a Research Briefing for this vote (once
## per vote); reset whenever the share is drawn.
var vote_briefed := false

## A save point inside a stage with several opponents, taken when one is
## defeated: { "key": which stage, "item_bonuses": what the stage began with,
## "engine": BattleEngine.checkpoint() }. {} otherwise. Saved; cleared when
## the stage ends or a level begins.
var stage_checkpoint: Dictionary = {}

## The result of a stage that has just ended but has not been counted yet
## (2026-11-11, Cameron): written to the save the moment the result is shown,
## cleared by finish_stage(). Closing the game on a loss screen therefore comes
## back to a loss that is already counted, not a free retry. Holds the
## arguments finish_stage() takes, plus the stage's key.
var pending_stage_result: Dictionary = {}

## The level being played, or null when the player is in the Office.
var level_runner: LevelRunner = null

## How the last finished level went: "win", "loss", or empty if none yet.
var last_level_outcome: String = ""

## The player's standing: constituency support, reputation, funds and party
## support, by the English names sanban.json gives them. Seeded from that
## file's starting values and then moved by what happens in a stage.
var meta: Dictionary = {}

## What the last finished stage did to those variables, e.g.
## { "Reputation": 3 }. Cleared when the next stage starts. The battle screen
## reads it to tell the player what just happened to them.
var last_meta_change: Dictionary = {}
## Why each variable in last_meta_change moved: { name: [{cause, amount}, ...] },
## in the order they happened, one entry per cause with its amounts summed
## (Your Record shows them, 2026-10-15; amounts added 2026-10-18).
var last_meta_cause: Dictionary = {}
## The same for organizations: { booster_id: [{cause, amount}, ...] }, filed
## beside last_booster_change (Important Stakeholders shows them).
var last_booster_cause: Dictionary = {}
## The cause the next recorded change is filed under; set around a block of
## rewards, cleared after.
var _cause := ""

## Experience: earned from stages, events and laws (a stage's win_delta_xp),
## and spent in the Office on Rhetoric Training, level unlocks, staff, backings
## and some shop items. `last_xp_gained` is what the stage just finished paid.
## Lifetime XP earned (spending never lowers it) is `xp_earned_total`.
var xp := 0
var last_xp_gained := 0

## What the player owns, and what they are taking in.
##
## `owned_cards` starts as the Starter twelve and grows as XP is spent.
## `deck` is the subset carried into a battle — a fixed size, so unlocking a
## card means leaving another out. That trade is the whole point of the deck
## screen; without it an unlock would be a free upgrade.
##
## `owned_modifiers` is the organisations' backing bought with Funds. Held
## for the run rather than the level, like standing.
var owned_cards: Array[String] = []
var deck: Array[String] = []
var owned_modifiers: Array[String] = []

## Cosmetic packages (2026-09-28): purely decorative, bought with Funds/XP.
## `owned_cosmetic_packages` is what's been bought; `active_cosmetics` is
## what's currently equipped, independently per slot —
## { CosmeticPieces.OUTFIT/BACKGROUND/MUSIC : package_id }. A slot missing
## from the dictionary, or set to "", means Default (the base game look).
## See CosmeticPieces.gd, ArtLoader.gd's variant axis, Audio.gd's music
## override.
var owned_cosmetic_packages: Array[String] = []
var active_cosmetics: Dictionary = {}

## The inventory: shop items (SHxx) held and how many of each, e.g.
## { "SH04": 2 }. Filled by buying in the Office's Supplies shop and by an
## Office Hours visitor's reward; emptied one at a time by the Use button in
## the Office or during a stage. See design/proposals/inventory.md.
var inventory: Dictionary = {}
## Uses left on each held copy (Cameron, 2026-11-16): { item_id: [uses_left, ...] },
## one number per copy, fewest first, kept in step with `inventory` (see
## ItemUses and `item_copies`). An id missing here has full-use copies.
var item_uses: Dictionary = {}

## How many of each item have been bought during the current level. An
## item's Purchase Limit is checked against this; it resets when a level
## concludes, win or loss.
var shop_bought_this_level: Dictionary = {}

## A Rhetoric Training draw in progress: { item_id, card_id, look, seen }.
## Empty when none is. Saved, so quitting the app with a card on screen
## brings the same card back rather than a fresh draw — see
## offer_random_card().
var card_draw: Dictionary = {}

## Stage effects waiting for the next stage — an item with Duration "Stage"
## used in the Office. { "ENERGY": 1, ... }; handed to that stage's setup and
## then cleared (take_item_bonuses_for_stage()).
var pending_stage_bonuses: Dictionary = {}

## Stage effects waiting for the next LEVEL — an item with Duration "Level"
## used in the Office. They become level_bonuses when that level begins.
var pending_level_bonuses: Dictionary = {}

## Stage effects active for every stage of the level in progress: a level
## buff used in the Office before it, or one used mid-stage (which covers the
## rest of the level). Cleared when the level concludes.
var level_bonuses: Dictionary = {}

## Item effects that last a number of game-clock units from use (the Shop
## tab's Duration Units, 2026-10-18): [{"bonuses": {token: amount},
## "expires_at": clock}]. Merged into every stage's item bonuses until they
## run out (take_item_bonuses_for_stage()). Saved.
var timed_bonuses: Array = []

## { mod_id: the clock at which that bought backing lapses } for backings with
## a Duration Units (the Modifiers tab). Saved; a lapsed backing leaves
## owned_modifiers and can be bought again (_expire_modifiers()).
var modifier_expires: Dictionary = {}

## Where the player stands with each organization (boosters.json), by booster
## ID. Pleasing one with an answer, a vote, a law or a kept promise raises it;
## it is held between levels and drifts back toward where it started when
## neglected (see _apply_week_decay()) — unlike the pleased list, which lasts
## one level.
var booster_standing: Dictionary = {}

## What the last finished level did to those, e.g. { "BO08": 5 }.
var last_booster_change: Dictionary = {}

## Where the player stands with each of the 5 audience segments, by segment
## ID (SG01-05). Starts at that segment's "Initial Favorability %" from
## segments.json and is held between levels, the same way booster_standing
## is. This is a DIFFERENT number from a card's "segment_share" (how much of
## a STAGE's audience is a given segment — CardResolver.segment_share(),
## static per-stage data) or a modifier's audience trigger (MetaRules.
## active_modifiers(), same static per-stage data) — those two read
## stages.json's segment_mix and are unrelated to this. This is the
## PERSISTENT sentiment score Staff tier rewards move (Ledger.gd / Staff
## section; a reward's SGxx target lands here).
var segment_favorability: Dictionary = {}

## What the last staff hire/upgrade did to those, e.g. { "SG03": 2 }.
var last_segment_change: Dictionary = {}

## Where the player stands with each of the six real-world parties, by
## party name (parties.json's own "name" — the same string opponents.json/
## player.json already carry in their "party" column). National Assembly
## Floor Voting (ST23) is the first stage to move more than one at once.
##
## The player's OWN party is a special case: rather than a second number to
## keep in sync, party_favorability() reads that party's live entry
## straight out of `meta["Party support"]` — the existing sanban variable
## IS that party's favorability, per Cameron's "the existing party favor
## will feed into the player character's party". Only the other five
## parties actually live in this dictionary.
var party_standing: Dictionary = {}

## What the last Floor Vote did to those, e.g. { "Keizaijiyuutou": -3 }.
var last_party_change: Dictionary = {}

## Who is hired into each of the three Staff roles, and at what tier:
## { "Policy Research Assistant": { "staff_id": "SF04", "tier": 1 }, ... }.
## A role with no entry is vacant, either because nobody has ever been
## hired into it or because its hire was fired (see staff_fired below and
## fire_staff()) — see Ledger.gd's Staff section and
## hire_staff()/upgrade_staff()/fire_staff().
var staff_hired: Dictionary = {}

## Extra staff beyond each role's primary (Cameron, 2026-11-08): { role: [
## {"staff_id", "tier"}, ... ] }. `staff_hired[role]` stays the PRIMARY, the one
## person every scene, notice and item bonus reads; these are the others, who
## pay rank rewards and may speak in stage transitions. Saved.
var staff_extra: Dictionary = {}
## How many times the staff slot item was bought: each purchase adds one place
## to every role. Saved.
var staff_slot_buys := 0

## Every staff_id ever fired this run, { "SF04": true, ... }. Firing costs a
## severance (Ledger.staff_firing_cost()) and is permanent, Cameron's call,
## 2026-09-25 (design/proposals/staff_firing.md): a fired candidate never
## appears hireable again for the rest of this run, so the Recruitment shop
## checks this before listing anyone as a candidate.
var staff_fired: Dictionary = {}

## Staff wages and Loyalty (Cameron, 2026-11-16; StaffLoyalty.gd). All keyed by
## staff_id. Loyalty is 0 to 100; invested is everything paid for the person
## (hire plus upgrades), the base of their weekly wage; weeks counts weeks
## worked. `staff_quit` lists people who resigned: like the fired, they never
## return. `staff_raise_pay` and `staff_thanked` last one week.
## `staff_week_tasks` holds this week's Loyalty from daily tasks (StaffTasks.gd).
## `staff_last_week` keeps the last week-end breakdown for the profile.
var staff_loyalty: Dictionary = {}
var staff_invested: Dictionary = {}
var staff_weeks: Dictionary = {}
var staff_quit: Dictionary = {}
var staff_raise_pay: Dictionary = {}
var staff_thanked: Dictionary = {}
var staff_week_tasks: Dictionary = {}
var staff_last_week: Dictionary = {}

## The daily staff tasks (Cameron, 2026-11-16; StaffTasks.gd). `staff_day_key`
## is the calendar day the pool belongs to (-1 = none drawn); the pool is the
## day's offered tasks; the plan is { staff_id: [task uid, ...] }; once
## confirmed the plan is locked and is applied when the day ends. A day that
## is skipped over (a long level) goes out of effect with no rewards or
## penalties. `staff_day_delegated` holds blocks an event used from a person's
## day; `staff_full_days` counts days in a row a person's bar was full;
## `staff_report_pending` is the last day's result, waiting to be shown once.
var staff_day_key := -1
var staff_day_blocks_total := 8
var staff_day_pool: Array = []
var staff_day_plan: Dictionary = {}
var staff_day_confirmed := false
var staff_day_delegated: Dictionary = {}
var staff_full_days: Dictionary = {}
var staff_report_pending: Dictionary = {}
## Items given to staff for the day: { staff_id: item_id }, at most one each.
## They are only used up when the day is confirmed.
var staff_day_items: Dictionary = {}
## Changes to the next task pools left by items and events (Cameron,
## 2026-11-16): { family (or "MAX"), amount, draws_left, label }, each applied to
## the next `draws_left` pools drawn. `staff_office_item` is the item in the
## Office box, used up (and turned into one of these) when the day is confirmed.
## `staff_day_reasons` and `staff_day_max` say why today's pool looks as it does.
## `staff_taste_known` marks people whose gift taste has been found out.
var staff_pool_mods: Array = []
var staff_office_item := ""
var staff_day_reasons: Array = []
var staff_day_max := 0
## The task-count changes today's pool was drawn with, kept so a reshuffle (the
## Priority Inbox) can draw it again, and how many times that has happened today.
var staff_day_adds: Dictionary = {}
var staff_day_shuffles := 0
## What an Office item used on the Staff Assignments screen just did (shown once; not saved).
var staff_use_notes: Array = []
var staff_taste_known: Dictionary = {}
## What the gifts given at the last confirm did (shown once; not saved).
var staff_gift_notes: Array = []

## Level IDs the player has paid XP to unlock — only meaningful once
## rules.json's "level_gating_enabled" is true. A level whose relevant
## unlock_cost_* is already 0 does not need an entry here to be playable; see
## Ledger.is_level_unlocked().
var levels_unlocked: Array[String] = []

## How many levels have been FINISHED so far this run — win or loss both
## count. [DEFAULT] The workbook's own note on levels.json's cooldown column
## reads "# of OTHER LEVELS TO PLAY before this level is available to play
## again", and "play" most naturally means "finish", not "specifically win",
## so a loss burns down a cooldown exactly like a win does. If that reading
## is wrong, this is the one line to change (see Ledger.level_cooldown_remaining).
var levels_completed_count: int = 0

## { level_id -> the levels_completed_count value at the moment it last
## finished }. A level with no entry has never been finished and so is never
## on cooldown, no matter what its cooldown number says.
var level_last_completed_at: Dictionary = {}

## { level_id -> the game clock (time_units) when it last finished }. This is
## what a level's cooldown is measured against (2026-10-18; it used to count
## other levels played). Saved; cleared on a new run.
var level_cleared_units: Dictionary = {}

## The game-clock reading at which decay last ran; decay runs every Decay
## Interval units from here (_apply_time_decays()). Saved.
var last_decay_at := 0

## Organizations whose standing moved (other than by decay) since decay last
## ran -- the "dealt with" test for neglect decay. Saved.
var booster_moved_in_period: Dictionary = {}
var _decaying := false

## { level_id -> how many times that level has been WON }, unlike levels_
## completed_count above — this only counts a win, not any finish, and it's
## per level rather than one running total. "Your Record"'s own level-by-
## level tally; a level's own tier total is derived from this at display
## time (OfficeScreen._show_record()) rather than kept as a second counter.
var levels_cleared: Dictionary = {}

## How many of Staff's highest_tier steps are open to hire from, 0 at a
## fresh run (SF01/SF08/SF15, the three highest_tier-0 candidates, are the
## only ones hireable). the Staff Training Consultancy Session (SH12) raises
## this by 1 — Ledger.staff_hire_refusal() is where it actually gates a
## candidate.
var staff_recruitment_tier: int = 0

## Added to rules.json's own "funds_starting_cap" every time Funds is
## clamped (see _sanban_row()) — the Fund Limit Increase Petition (SH13) raises
## this by its own funds_cap_increase (100,000) each time it's bought.
##
## Redesigned 2026-10-04 (Cameron, from a playtest report that the cap
## "is not applied by default"): the EFFECTIVE cap used to just be
## sanban.json's own Funds "max" (1,000,000) with this bonus added on top
## — meaning a fresh run already sat at the full 1,000,000 ceiling before
## buying anything, and every petition after that pushed the cap
## PAST 1,000,000 with nothing to stop it. Now funds_starting_cap
## (100,000) is the real starting point, this bonus ratchets it up from
## there, and the sanban "max" is read as the one hard ceiling neither
## number is ever allowed to cross — see _sanban_row()'s own mini() call.
var funds_cap_bonus: int = 0

## Campaign Pressure (Difficulty.gd): "relaxed", "standard" or "harder". Chosen at
## New Game, raised but never lowered, saved with the run.
var difficulty: String = "standard"

## Leftover gaffes added up over the run, per meter (see apply_awareness_gaffes).
var awareness_gaffe_tally: Dictionary = {"district": 0, "national": 0}
## Extra deck slots bought (SH34-style items, Shop "Deck Size Increase";
## Cameron, 2026-10-31), and how many times such an item has been bought.
var deck_size_bonus: int = 0
var deck_expansions: int = 0


# ---------------------------------------------------------------------------
# Crisis triggers (CLAUDE.md §8) — Town Hall, Steering Committee, funding
# freeze, and lifetime win/loss/gaffe tracking. Wired 2026-09-25.
# ---------------------------------------------------------------------------
# Each "_active" flag tracks whether the trigger is CURRENTLY in its zone,
# not merely whether the condition is true this instant — that distinction
# is the whole mechanism (see _check_crisis_triggers()): a trigger fires
# once on the way IN and stays quiet, even while its condition keeps
# holding, until the player crosses back OUT. Cameron, 2026-09-25: losing
# the Town Hall while Jiban is still low must not immediately queue another
# one. Persisted, so this holds across levels, not just within one.

## Whether a Town Hall (ST05) is currently the queue's business — set the
## moment MetaRules.town_hall_triggered() first turns true, cleared the
## moment Jiban rises back above its threshold.
var town_hall_active := false

## How many times each person (an OPxx opponent or a VIxx visitor) has been
## seated against the player this run -- PeopleDraw leans the next draw toward
## whoever has been met least, so the same face can return but rarely back to
## back (Cameron, 2026-10-13). Saved; cleared on a new run.
var faced_people: Dictionary = {}

## Opponents and visitors the player has met once (id -> true), for the Characters list
## in Administration (CharacterCodex). Filled where a person actually appears (a bout, a transition, Office Hours,
## a visit, a trade), not at level start, so no one is spoiled.
var met_characters: Dictionary = {}

## Who spoke at the last stage transition and which lines this level has
## already heard ({"speaker": id, "lines": {key: true}}), so the next one can
## avoid repeating them (2026-11-02). Not saved; cleared when a level begins.
var transition_memory: Dictionary = {}

## The opponent lines this level has already heard ({line text: order said}),
## so OpponentCues can pick an unused one first (2026-11-04, Cameron). Not
## saved; cleared when a level begins.
var opponent_lines_said: Dictionary = {}

## Same shape, for the Party Steering Committee check-in (ST22).
var steering_committee_active := false

## The game clock (2026-10-18): units of time that have passed this run.
## Finishing a stage adds that stage's Time Units (Stages tab; blank = 1).
## Saved; cleared on a new run. Never shown to the player (TimeClock.gd).
var time_units := 0

## The week calendar (WeekCalendar.gd, 2026-10-23): { week, phase, hours }.
## Saved; cleared on a new run. Time units keep counting every hour too.
var calendar: Dictionary = WeekCalendar.fresh()

## Where the player is standing (two offices, 2026-11-20): Offices.CAPITOL or Offices.DISTRICT. Its own saved
## field, not part of `calendar` (WeekCalendar.normalized() would drop it on load). A save without it loads at
## the Capitol.
var office_location: String = Offices.CAPITOL
## While a level with built-in trips is in progress: { "start": office, "trips": n }. The trips' hours were spent
## when the level began; the player ends at the other office after an odd number of trips.
var level_travel: Dictionary = {}
## The train encounter the last trip brought, until the Office has shown it (not saved).
var travel_encounter: String = ""

## Scales decay steps while the week-end decay runs; 1.0 the rest of the time.
var _decay_scale := 1.0

## Party dues (PartyDues.gd, 2026-10-23): the Funds earned Monday to Friday this
## week (the share that adds to the dues), and the balance carried over from
## weeks the dues were not paid in full. Both saved; cleared on a new run.
var week_funds_earned := 0
var dues_balance := 0

## Name awareness (2026-10-23): how many people know the player, in their
## district and nationally, 0 to 100 each. Saved; cleared on a new run.
## `last_awareness_change` is the last stage's own movement, not saved.
var awareness: Dictionary = {"district": 0, "national": 0}
var last_awareness_change: Dictionary = {}

## Consecutive weeks each Week-end awareness effect has held { effect_id: n }.
var awareness_streaks: Dictionary = {}

## Election strength (ElectionStrength.gd, 2026-10-23): a slow stock from 0 to 100,
## and the lifetime XP earned (spending XP does not lower it). Both saved.
var election_strength := 0.0
var xp_earned_total := 0

## Events (EventEngine.gd, 2026-10-23): the clock when each event last happened,
## the levels an event has revealed, and whether a random event may arrive the
## next time the Office opens (not saved).
var event_last_at: Dictionary = {}
var discovered_levels: Array[String] = []
## Dated events already played (2026-10-23).
var dated_events_done: Array[String] = []
## Decision! scenes already answered (2026-11-21): {scene_id: {"day": day number, "choice": letter}}. A follow-up counts its
## Delay from "day" and may need the earlier "choice" (DecisionScenes.gd).
var decision_log: Dictionary = {}
## What answered Decision! scenes have started but the player has not yet played (2026-11-21, phase 3): [{"kind", "id", "scene_id"}]
## for kinds level, stage and vote. The Office offers the first each time it opens, until its level is begun.
var pending_activations: Array = []
## The one-stage level a stage or vote activation is playing, kept so a save mid-level can rebuild it (DecisionScenes.ad_hoc_level).
var scene_runtime: Dictionary = {}
## Whip scenes (P15, 2026-11-23): who whips the player in a scene picked by Party support, {scene_id: opp_id}, fixed when the scene
## first opens so its card, its stage and a reloaded game agree; and the locks lost whip fights put on a vote,
## {bill_id: [{"choice", "by", "scene_id"}]} (WhipPick.resolve).
var whip_picks: Dictionary = {}
var whip_locks: Dictionary = {}
## Capitol venues (P16, 2026-11-23): the run's own number, which (with the day and the venue) deals each venue's lines so a reload does
## not reshuffle them; per venue the day's dealt set and how many were heard {venue_id: {"day", "dealt", "heard", "dry"}}; the Once lines
## already heard {line_id: true}; and the rhetoric tips held (RhetoricTips.gd). An old save has none of them and starts with none.
var run_seed := 0
var venue_days: Dictionary = {}
var venue_heard_once: Dictionary = {}
var held_tips: Array = []
## The after-hours trip the staff made for a Mandatory scene when it opened (not saved): {"xp": cost, "place": office}, or {}.
var last_evening_trip: Dictionary = {}
## What the whip stage that just ended did to the vote (not saved): WhipPick.resolve's answer, or {} when it was won or not a whip.
var last_whip_lock: Dictionary = {}
## Promises owed (Promises.gd, 2026-10-31): records made by a choice's
## "Promise ..." commitment, kept from the Office's Promises panel.
var promises: Array = []
## Promises broken since the Office last said so, for its popup.
var promises_broken_unseen: Array = []
## A running number for promise IDs.
var promise_serial := 0
## The clock when the level in progress began, or -1 between levels. Promise
## deadlines are paused while it is set (Promises.resume_after_level()). Saved.
var level_clock_started := -1
## Why the last patron or drafted level could not start on the calendar, as a
## sentence; "" when the reason was something else. Not saved.
var last_level_start_refusal := ""
## Follow-up events a choice scheduled (2026-10-31): [{event_id, due_at}], each
## shown at the first Office visit on or after its time.
var scheduled_events: Array = []
var event_roll_due := false

## A dinner or walking tour in progress (HostedEvent.gd): { hosted_id, org, roster,
## hours, results: {step: [scored]}, tags: {step: [tag lists]} }. Not saved.
var hosted_session: Dictionary = {}

## Special Levels waiting on a countdown or due: { trigger: {"armed_at": clock
## units} } (SpecialLevels.gd). Saved; cleared on a new run. An entry stays
## until that special level has been played, win or lose.
var special_levels: Dictionary = {}

## Set when an ordinary level finishes with a special level due: the Office
## starts it at once the next time it opens (take_forced_special()). Saved, so
## closing the app in between does not lose it.
var special_forced := false

## Same shape, for the Funding Freeze (M32) — tracked here purely to detect
## the edge for the Office alert; the freeze's actual enforcement
## (MetaRules.party_support_modifiers()) is checked live and needs no latch.
var funding_frozen_active := false

## News from the level just finished, for the Office to show once and
## forget. Saved (2026-11-19, Cameron's crisis-level review): it used to be
## left out like last_level_outcome, so closing the app between a stage and
## the Office lost a crisis warning for good; it is cleared the moment the
## Office has shown it. Each entry is
## {"kind": "town_hall"/"steering_committee"/"funding_freeze"/"gaffe_penalty",
## "edge": "entered"/"left"}.
var pending_trigger_alerts: Array[Dictionary] = []

## { stage_id: {"wins": N, "losses": N} }, lazily created per stage_id the
## first time it's played — keying by the real stage_id rather than some
## coarser category is what makes this track a stage type nobody has
## invented yet for free, with no code change needed when it arrives.
var stage_type_results: Dictionary = {}

## Every gaffe made, summed across every stage this run, this run's own
## final gaffe count each time (BattleState.gaffe at finish_stage()) —
## never reset mid-run, unlike a single stage's own gaffe meter.
var lifetime_gaffes := 0

## How many stages this run have been lost specifically to the gaffe
## meter filling, as opposed to the clock or any other loss reason.
var stages_lost_to_gaffes := 0

## Whether the one-time lifetime-gaffe penalty (Balance tab:
## gaffes_lifetime_penalty_threshold/_jiban_delta) has already fired.
## Lifetime gaffes never go back down, so unlike the three triggers above
## this never resets — it is a single event, not a zone.
var gaffe_penalty_applied := false

## Every bill_id the Floor Vote influence swing has flipped (§7.7), in the
## order they happened — "Your Record"'s own list. See record_bill_flip().
var bills_flipped_by_influence: Array[String] = []

## The statute book (2026-10-12): one entry per bill that came to a Floor
## Vote, passed or failed, in the order they were voted. See StatuteBook.gd
## for an entry's shape and record_floor_vote() for where it is written.
var statute_book: Array = []

## Patron Bills (2026-10-19). patron_requests: {patron_bill_id: {"status",
## "components", "amended", "tries"}} (statuses are PatronRequests.*);
## enacted_components: every component that has become law (Option A never
## offers one again); patron_runtime: the level in progress, {"patron_bill_id",
## "level"} ({} when none); patron_composed: {patron_bill_id: the composed bill
## and its components}, kept so the statute book can name a bill after the run
## is saved and reloaded.
var patron_requests: Dictionary = {}
var enacted_components: Array = []
var patron_runtime: Dictionary = {}
## When each request's countdown began ({patron_bill_id: clock units}); a
## request shows once special_level_delay units have run (step 4).
## What the latest sponsored-bill vote did (empty otherwise); read once by the
## Floor Vote result and never saved.
## The organization/audience changes of the latest visitor answer, for the
## chip row. Not saved.
var last_visitor_effects: Array = []
var last_patron_outcome: Dictionary = {}
## Draft a Bill (2026-10-19): the player's own bills as runtime patron rows
## ({id: row}), how many have been drafted, and the clock when the last was
## (-1 for never). Saved.
var patron_drafts: Dictionary = {}
var draft_counter := 0
var last_draft_at := -1
var patron_armed: Dictionary = {}
var patron_composed: Dictionary = {}

## Help and hindrance on the vote in front of the player (BillAssist), cleared
## when the vote has resolved. patron_news: {story key: clock units it runs
## until}; the Office ticker shows a line for each story running.
var bill_assist: Dictionary = BillAssist.empty()
var patron_news: Dictionary = {}

## The stance taken on this level's bill (2026-10-18, BillStance): {} when the
## level has no bill or no lean was picked; otherwise { "bill_id", "lean"
## ("Support"/"Oppose"), "cost": { booster_id: how much the win drift has taken
## from it this level }, "voted": bool }. Saved, so a resumed level keeps it;
## cleared when a level begins, ends or is abandoned.
var bill_stance: Dictionary = {}


func _ready() -> void:
	protagonist_id = str(DataDB.player.get("player_id", ""))
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()
	reset_party_standing()


## A fresh run as `player_id`: every number back to its start. False, and
## nothing changes, when there is no such protagonist.
## Rewrites the live Balance and Shop numbers for the current tier.
func _apply_difficulty() -> void:
	Difficulty.apply_balance(DataDB.balance, DataDB.balance_base, difficulty)
	Difficulty.apply_shop(DataDB.shop, DataDB.shop_base, DataDB.balance_base, difficulty)


## Raises the pressure; never lowers it. False (nothing changed) when `tier`
## is not higher than the current one.
func raise_difficulty(tier: String) -> bool:
	if not Difficulty.can_raise_to(difficulty, tier):
		return false
	difficulty = tier
	_apply_difficulty()
	return true


## The Balance number for a Campaign Pressure lever under the current tier.
func pressure(lever: String, fallback: float) -> float:
	return Difficulty.number(DataDB.balance_base, difficulty, lever, fallback)


func start_new_run(player_id: String, pressure: String = "standard") -> bool:
	if not DataDB.use_protagonist(player_id):
		return false
	protagonist_id = player_id
	difficulty = pressure if Difficulty.is_tier(pressure) else Difficulty.STANDARD
	_apply_difficulty()
	_link_carry = {}
	level_runner = null
	last_level_outcome = ""
	mid_stage = false
	stage_checkpoint = {}
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()
	reset_party_standing()
	faced_people = {}
	met_characters = {}
	office_location = Offices.normalize(DataDB.get_rule("start_office", Offices.CAPITOL))
	if office_location == Offices.EITHER:
		office_location = Offices.CAPITOL
	level_travel = {}
	awaiting_new_game = false
	grant_default_ui_style()
	return true


## A run with no UI style picked owns and wears the default one free (Rules tab, default_ui_style: Woodblock). Called when a run
## starts and after a save loads; a run that already wears an owned style is left alone. New Game's pick replaces the default.
func grant_default_ui_style() -> void:
	var worn := str(active_cosmetics.get(CosmeticPieces.UI_STYLE, ""))
	if not worn.is_empty() and owned_cosmetic_packages.has(worn):
		return
	var wanted := str(DataDB.get_rule("default_ui_style", UiStyles.WOODBLOCK))
	var package_id := str(UiStyles.package_for(wanted if wanted in UiStyles.ALL else UiStyles.WOODBLOCK, DataDB.cosmetic_packages).get("package_id", ""))
	if package_id.is_empty():
		return
	if not owned_cosmetic_packages.has(package_id):
		owned_cosmetic_packages.append(package_id)
	active_cosmetics[CosmeticPieces.UI_STYLE] = package_id


# ---------------------------------------------------------------------------
# Saving
# ---------------------------------------------------------------------------
# One list of what a run is, used both ways, so a field added to the run and
# forgotten here is forgotten in both directions and caught by the round-trip
# test rather than half-saved.

const _SAVED_FIELDS := [
	"protagonist_id", "difficulty", "awareness_gaffe_tally", "stage_checkpoint", "pending_stage_result", "last_level_outcome", "meta", "xp",
	"owned_cards", "deck", "owned_modifiers",
	"owned_cosmetic_packages", "active_cosmetics",
	"inventory", "item_uses", "shop_bought_this_level", "card_draw",
	"pending_stage_bonuses", "pending_level_bonuses", "level_bonuses",
	"booster_standing", "segment_favorability", "party_standing", "staff_hired", "staff_extra", "staff_slot_buys", "staff_fired", "staff_loyalty", "staff_invested", "staff_weeks", "staff_quit", "staff_raise_pay", "staff_thanked", "staff_week_tasks", "staff_last_week", "staff_day_key", "staff_day_blocks_total", "staff_day_pool", "staff_day_plan", "staff_day_confirmed", "staff_day_delegated", "staff_full_days", "staff_report_pending", "staff_day_items", "staff_pool_mods", "staff_office_item", "staff_day_reasons", "staff_day_max", "staff_day_adds", "staff_day_shuffles", "staff_taste_known", "vote_unknown_percent", "vote_briefed",
	"levels_unlocked", "levels_completed_count", "level_last_completed_at", "levels_cleared", "level_cleared_units", "timed_bonuses", "modifier_expires", "last_decay_at", "booster_moved_in_period",
	"staff_recruitment_tier", "funds_cap_bonus", "deck_size_bonus", "deck_expansions",
	"town_hall_active", "steering_committee_active", "funding_frozen_active", "time_units", "calendar", "week_funds_earned", "dues_balance", "awareness", "awareness_streaks", "election_strength", "xp_earned_total", "event_last_at", "discovered_levels", "dated_events_done", "decision_log", "pending_activations", "scene_runtime", "whip_picks", "whip_locks", "run_seed", "venue_days", "venue_heard_once", "held_tips", "special_levels", "special_forced",
	"stage_type_results", "lifetime_gaffes", "stages_lost_to_gaffes",
	"gaffe_penalty_applied", "bills_flipped_by_influence", "statute_book", "faced_people", "met_characters",
	"bill_stance",
	"patron_requests", "enacted_components", "patron_runtime", "patron_composed", "patron_armed",
	"bill_assist", "patron_news", "patron_drafts", "draft_counter", "last_draft_at",
	"promises", "promises_broken_unseen", "promise_serial", "scheduled_events",
	"level_clock_started", "pending_trigger_alerts", "office_location", "level_travel",
]


## The run, as plain data.
func to_save() -> Dictionary:
	var saved := {}
	for field: String in _SAVED_FIELDS:
		var value: Variant = get(field)
		saved[field] = value.duplicate(true) if (value is Dictionary or value is Array) else value
	saved["level_runner"] = level_runner.snapshot() if level_runner != null else null
	return saved


## Puts a run from to_save() back. A field the save lacks (one written by an
## older build) keeps its fresh-run value rather than failing the load.
func load_save(saved: Dictionary) -> void:
	var player_id := str(saved.get("protagonist_id", protagonist_id))
	if not start_new_run(player_id):
		start_new_run(str(DataDB.player.get("player_id", "")))

	# An old save has no run number: one is made from what the save does hold, so its venue lines stay the same on every load.
	if not saved.has("run_seed"):
		run_seed = absi(("%s|%s" % [player_id, str(saved.get("time_units", 0))]).hash())
	for field: String in _SAVED_FIELDS:
		if not saved.has(field) or field == "protagonist_id":
			continue
		var current: Variant = get(field)
		var value: Variant = saved[field]
		if current is Array and value is Array:
			(current as Array).assign(value)   # keeps Array[String] typed
		elif current is Dictionary and value is Dictionary and field in _KEYED_BY_CURRENT_DATA:
			# A save from an older build lacks the newest entries (a new meta
			# variable, a new organisation), and one from a renamed workbook
			# has entries that no longer exist: start from the fresh run's
			# entries and take only the saved values for those.
			for key: Variant in (value as Dictionary):
				# Only a number replaces a number (audit E-05, 2026-11-16): a
				# hand-edited or damaged save once loaded the text "high" as a
				# standing.
				var saved_value: Variant = (value as Dictionary)[key]
				if (current as Dictionary).has(key) and (saved_value is int or saved_value is float):
					(current as Dictionary)[key] = saved_value
		elif typeof(current) == typeof(value):
			set(field, value)
	calendar = WeekCalendar.normalized(calendar)
	if not Difficulty.is_tier(difficulty):
		difficulty = Difficulty.STANDARD
	_apply_difficulty()

	_register_saved_patron_bills()
	var runner: Variant = saved.get("level_runner")
	level_runner = LevelRunner.restored(runner) if runner is Dictionary else null
	if level_runner != null and level_runner.is_finished():
		level_runner = null
	if level_runner == null:
		patron_runtime = {}
	drop_stale_ids()
	grant_default_ui_style()
	sanitize_loaded_run()


## Puts right whatever a loaded save can get wrong that the data can answer
## (audit E-05 and E-06, 2026-11-16): numbers outside their range, a negative
## clock, a deck of the wrong size. Returns how many things it changed, so a
## test can check it. A fresh, healthy save changes nothing.
##
## Funds over the CURRENT cap are left alone on purpose (see
## MetaRules.clamp_meta: a lowered cap must not take back what you hold); only
## the hard ceiling in the Sanban tab is enforced.
func sanitize_loaded_run() -> int:
	var changed := 0
	for variable: String in meta.keys():
		var row := DataDB.get_sanban(variable)
		if row.is_empty():
			continue
		var fixed := clampi(int(meta[variable]), int(row.get("min", 0)), int(row.get("max", 100)))
		if fixed != int(meta[variable]):
			meta[variable] = fixed
			changed += 1
	for table: Dictionary in [booster_standing, party_standing, awareness]:
		for key: String in table.keys():
			var fixed := clampi(int(table[key]), 0, 100)
			if fixed != int(table[key]):
				table[key] = fixed
				changed += 1
	for scalar: String in ["xp", "xp_earned_total", "time_units"]:
		if int(get(scalar)) < 0:
			set(scalar, 0)
			changed += 1
	# Staff from a save made before wages existed start with the usual
	# Loyalty and the price they cost; stored Loyalty stays inside 0 to 100.
	for member: Dictionary in staff_members():
		var id := str(member["staff_id"])
		if not staff_loyalty.has(id):
			staff_loyalty[id] = Levers.whole("staff_loyalty_start")
			changed += 1
		else:
			staff_loyalty[id] = clampi(int(staff_loyalty[id]), 0, 100)
		if not staff_invested.has(id):
			staff_invested[id] = StaffLoyalty.invested_for(DataDB.get_staff(id), int(member["tier"]))
			changed += 1
	return changed


## Brings the deck back to its legal size from cards the player owns, then
## from the opening recipe if that is not enough. Only used after a load that
## lost cards, so a saved deck of any other size is never touched.
func _refill_deck() -> void:
	var wanted := deck_size()
	if deck.size() > wanted:
		deck.resize(wanted)
	for card_id: String in owned_cards:
		if deck.size() >= wanted:
			break
		if not deck.has(card_id):
			deck.append(card_id)
	if deck.size() < wanted:
		deck = Ledger.opening_deck(DataDB.cards, DataDB.balance)


## Fields whose keys are fixed by the current workbook (see load_save()).
const _KEYED_BY_CURRENT_DATA := ["meta", "booster_standing", "party_standing"]


## Forgets anything a loaded run names that the current data no longer has:
## a card, modifier, level, staff member, shop item or cosmetic package that
## was renumbered or removed in a workbook update. Without this a stale ID
## reached the screens as a blank name. Returns how many entries were dropped
## (also reported once as a warning), so tests can check it.
func drop_stale_ids() -> int:
	var dropped := 0
	dropped += _keep_known(owned_cards, DataDB.get_card)
	var deck_dropped := _keep_known(deck, DataDB.get_card)
	dropped += deck_dropped
	if deck_dropped > 0 or deck.is_empty():
		_refill_deck()   # a deck that lost cards to a data update must stay a legal size (audit E-05)
	dropped += _keep_known(owned_modifiers, DataDB.get_modifier)
	dropped += _keep_known(owned_cosmetic_packages, DataDB.get_cosmetic_package)
	dropped += _keep_known(levels_unlocked, DataDB.get_level)
	for item_id: String in inventory.keys():
		if DataDB.get_shop_item(item_id).is_empty():
			inventory.erase(item_id)
			dropped += 1
	for role: String in staff_hired.keys():
		var hired: Variant = staff_hired[role]
		if not (hired is Dictionary) or DataDB.get_staff(str((hired as Dictionary).get("staff_id", ""))).is_empty():
			staff_hired.erase(role)
			dropped += 1
	for role: String in staff_extra.keys():
		var kept: Array = []
		for entry: Variant in (staff_extra[role] as Array):
			if entry is Dictionary and not DataDB.get_staff(str((entry as Dictionary).get("staff_id", ""))).is_empty():
				kept.append(entry)
			else:
				dropped += 1
		staff_extra[role] = kept
	for slot: String in active_cosmetics.keys():
		if str(active_cosmetics[slot]) not in owned_cosmetic_packages:
			active_cosmetics.erase(slot)
			dropped += 1
	for level_id: String in level_last_completed_at.keys():
		if DataDB.get_level(level_id).is_empty():
			level_last_completed_at.erase(level_id)
	for level_id: String in levels_cleared.keys():
		if DataDB.get_level(level_id).is_empty():
			levels_cleared.erase(level_id)
	for mod_id: String in modifier_expires.keys():
		if DataDB.get_modifier(mod_id).is_empty():
			modifier_expires.erase(mod_id)
	for level_id: String in level_cleared_units.keys():
		if DataDB.get_level(level_id).is_empty():
			level_cleared_units.erase(level_id)
	if not card_draw.is_empty() and (DataDB.get_card(str(card_draw.get("card_id", ""))).is_empty() \
			or DataDB.get_shop_item(str(card_draw.get("item_id", ""))).is_empty()):
		card_draw = {}
		dropped += 1
	# A deck emptied by the above is rebuilt from what the player still owns.
	if deck.is_empty() and not owned_cards.is_empty():
		var size := int(DataDB.get_balance("starter_deck_size", 15))
		for card_id: String in owned_cards:
			if deck.size() >= size:
				break
			deck.append(card_id)
	if dropped > 0:
		push_warning("GameState: dropped %d saved entries the current data no longer has." % dropped)
	return dropped


## Removes from `ids` every entry `lookup` finds nothing for; returns how
## many were removed.
func _keep_known(ids: Array[String], lookup: Callable) -> int:
	var kept: Array[String] = []
	for id: String in ids:
		if not (lookup.call(id) as Dictionary).is_empty():
			kept.append(id)
	var removed := ids.size() - kept.size()
	if removed > 0:
		ids.assign(kept)
	return removed


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}
	last_meta_cause = {}
	xp = BattleSetup.starting_xp()
	last_xp_gained = 0
	funds_cap_bonus = 0
	deck_size_bonus = 0
	deck_expansions = 0
	reset_collection()
	reset_staff()
	reset_levels()
	reset_crisis_triggers()


## Every crisis trigger back to its rest state, and the lifetime counters
## back to zero, for a fresh run.
func reset_crisis_triggers() -> void:
	town_hall_active = false
	steering_committee_active = false
	time_units = 0
	calendar = WeekCalendar.fresh()
	week_funds_earned = 0
	dues_balance = 0
	reset_awareness()
	election_strength = 0.0
	xp_earned_total = 0
	event_last_at = {}
	discovered_levels = []
	dated_events_done = []
	decision_log = {}
	pending_activations = []
	scene_runtime = {}
	whip_picks = {}
	whip_locks = {}
	last_evening_trip = {}
	run_seed = randi()
	venue_days = {}
	venue_heard_once = {}
	held_tips = []
	promises = []
	promises_broken_unseen = []
	promise_serial = 0
	level_clock_started = -1
	scheduled_events = []
	event_roll_due = false
	last_decay_at = 0
	booster_moved_in_period = {}
	timed_bonuses = []
	modifier_expires = {}
	special_levels = {}
	special_forced = false
	funding_frozen_active = false
	pending_trigger_alerts = []
	stage_type_results = {}
	lifetime_gaffes = 0
	stages_lost_to_gaffes = 0
	gaffe_penalty_applied = false
	bills_flipped_by_influence = []
	statute_book = []
	patron_requests = {}
	enacted_components = []
	patron_runtime = {}
	patron_composed = {}
	patron_armed = {}
	patron_drafts = {}
	draft_counter = 0
	last_draft_at = -1
	bill_assist = BillAssist.empty()
	patron_news = {}
	DataDB.clear_runtime()


## Every Staff role back to vacant, every firing forgotten, and recruitment
## back to only highest_tier-0 candidates.
func reset_staff() -> void:
	staff_hired = {}
	staff_extra = {}
	staff_slot_buys = 0
	staff_fired = {}
	staff_loyalty = {}
	staff_invested = {}
	staff_weeks = {}
	staff_quit = {}
	staff_raise_pay = {}
	staff_thanked = {}
	staff_week_tasks = {}
	staff_last_week = {}
	_staff_clear_day()
	staff_pool_mods = []
	staff_office_item = ""
	staff_taste_known = {}
	staff_full_days = {}
	staff_report_pending = {}
	staff_recruitment_tier = 0


## Every level back to locked-by-its-price and off cooldown.
func reset_levels() -> void:
	levels_unlocked = []
	levels_completed_count = 0
	level_last_completed_at = {}
	level_cleared_units = {}
	levels_cleared = {}


## Back to the opening collection and a freshly rolled opening deck.
##
## A new run needs no decisions before the first battle: the opening deck is
## every Starter card, and the deck screen is where the player changes it.
func reset_collection() -> void:
	owned_cards = []
	owned_cosmetic_packages = []
	active_cosmetics = {}

	# PLAYTEST SETTING, rules.json's own "open_card_collection" (moved off a
	# hardcoded source constant 2026-09-22, so this is a switch like every
	# other open decision rather than a line only a programmer can flip).
	# True hands the player every card in the workbook from the first
	# moment, so a session can try the whole slate without earning it —
	# Cameron asked for the XP and card economy to be left aside while he
	# prices xp_to_unlock by playing. Flip it false and the collection
	# starts at the opening tier again; nothing else changes, because the
	# Ledger still refuses anything unaffordable.
	var open: bool = DataDB.get_rule("open_card_collection", true)
	for card: Dictionary in DataDB.cards:
		if open or str(card.get("tier", "")) == Ledger.OPENING_TIER:
			owned_cards.append(str(card.get("card_id", "")))

	deck = Ledger.opening_deck(DataDB.cards, DataDB.balance)

	# opening_deck() fills past the opening tier from the suits above it (see
	# its own test, "the rest is filled from above") whenever there aren't
	# enough opening-tier cards to fill a deck. Whatever it picked has to be
	# owned too, or the very first deck of a run would contain cards the
	# collection screen says the player doesn't have.
	if not open:
		for card_id: String in deck:
			if not owned_cards.has(card_id):
				owned_cards.append(card_id)
	owned_modifiers = []
	inventory = {}
	item_uses = {}
	# A new run starts with the protagonist's own Starting Items (the Player
	# tab, 2026-10-30: a coupon and some drinks). Starting coupons are listed
	# there too (Cameron, 2026-10-31); the older Balance lever "Starting
	# Training Session Coupons" is no longer read (a cleanup candidate).
	var starting: Variant = DataDB.player.get("starting_items")
	if starting is Dictionary:
		for item_id: String in starting:
			if not DataDB.get_shop_item(item_id).is_empty():
				inventory[item_id] = int(inventory.get(item_id, 0)) + int(starting[item_id])
	shop_bought_this_level = {}
	card_draw = {}
	pending_stage_bonuses = {}
	pending_level_bonuses = {}
	level_bonuses = {}


# ---------------------------------------------------------------------------
# Spending
# ---------------------------------------------------------------------------
# Every purchase goes through the Ledger first, so a screen cannot spend
# what the rules would have refused. Each returns the refusal reason, or an
# empty string when it went through.

## Spends Funds and/or XP on a cosmetic package — purely decorative, no
## gameplay effect. Buying does not equip it: see equip_cosmetic().
func buy_cosmetic_package(package_id: String) -> String:
	var package := DataDB.get_cosmetic_package(package_id)
	var refusal := CosmeticPieces.buy_refusal(
		package, owned_cosmetic_packages, xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal

	var price := CosmeticPieces.cost(package)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	owned_cosmetic_packages.append(package_id)
	return ""


## Sets which owned package (or "" for Default) is active for one cosmetic
## slot. Each slot is independent — equipping an outfit does not touch the
## background or music slots. No refusal path: the UI only ever offers a
## slot's owned, piece-bearing packages plus Default.
func equip_cosmetic(slot: String, package_id: String) -> void:
	if package_id.is_empty():
		active_cosmetics.erase(slot)
	else:
		active_cosmetics[slot] = package_id


## Spends XP to unlock a level (rules.json's "level_gating_enabled" only —
## OfficeScreen does not offer this button while gating is off, but the
## Ledger refusal is the real gate either way).
func unlock_level(level_id: String) -> String:
	var level := DataDB.get_level(level_id)
	var refusal := Ledger.level_unlock_refusal(level, levels_unlocked, staff_hired, xp, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_xp(-Ledger.level_unlock_cost(level, staff_hired))
	levels_unlocked.append(level_id)
	return ""


## True while unpaid party dues lock the party's backings (audit W-2,
## 2026-11-16, Cameron: dues must bite). Balance "Dues Debt Locks Backings"
## switches it; 0 turns the lock off.
func dues_debt_locks_backings() -> bool:
	return dues_balance > 0 and Levers.whole("dues_debt_locks_backings") != 0


## Why a backing cannot be taken right now, as a sentence; "" when it can.
## The Ledger's own reasons first, then the dues lock for a party backing.
func backing_refusal(modifier: Dictionary) -> String:
	var refusal := Ledger.modifier_refusal(modifier, owned_modifiers,
		meta, booster_standing, DataDB.booster_standing,
		DataDB.boosters, Text.phrase())
	if not refusal.is_empty():
		return refusal
	if dues_debt_locks_backings() and not PartyDues.party_backings(
			[str(modifier.get("mod_id", ""))], [modifier], DataDB.boosters).is_empty():
		return Text.say("backing.refuse_dues_owed")
	return ""


## Spends an organisation's activation cost (Funds, and since 2026-09-22
## sometimes Reputation and/or Constituency support too) on its backing.
func buy_modifier(mod_id: String) -> String:
	var modifier := DataDB.get_modifier(mod_id)
	var refusal := backing_refusal(modifier)
	if not refusal.is_empty():
		return refusal

	# Announced, the same as spending XP is. This used to write the number
	# straight in, so the Office's two spending doors behaved differently:
	# buying a card told the world and buying backing did not. Every
	# non-zero currency the modifier charges is spent, not just Funds.
	var costs := Ledger.modifier_costs(modifier)
	for name: String in costs.keys():
		var cost: int = costs[name]
		if cost > 0:
			_move_meta(name, -cost)

	owned_modifiers.append(mod_id)
	var lasts := ModifierEffects.duration_units(modifier)
	if lasts > 0:
		modifier_expires[mod_id] = time_units + lasts
	return ""


## Backings with a Duration Units lapse once the clock reaches their expiry:
## they leave owned_modifiers (and can be bought again), and the Office tells
## the player which one lapsed. Runs each time the clock moves.
func _expire_modifiers() -> void:
	for mod_id: String in modifier_expires.keys():
		if time_units < int(modifier_expires[mod_id]):
			continue
		modifier_expires.erase(mod_id)
		if owned_modifiers.has(mod_id):
			owned_modifiers.erase(mod_id)
			pending_trigger_alerts.append({"kind": "backing_lapsed", "edge": "entered",
				"name": str(DataDB.get_modifier(mod_id).get("name_en", mod_id))})


## Everyone hired in a role, the primary first, then the extras.
func staff_in_role(role: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var primary: Dictionary = staff_hired.get(role, {})
	if not primary.is_empty():
		out.append(primary)
	for entry: Variant in (staff_extra.get(role, []) as Array):
		out.append(entry as Dictionary)
	return out


## How many people each role holds now: one, plus a place per slot item bought.
func staff_slots() -> int:
	return 1 + staff_slot_buys


## The ids of every hired person, primaries and extras (who may speak in a
## stage transition).
func all_hired_staff_ids() -> Array[String]:
	var ids: Array[String] = []
	for role: String in staff_hired.keys():
		for member: Dictionary in staff_in_role(role):
			ids.append(str(member.get("staff_id", "")))
	for role: String in staff_extra.keys():
		if not staff_hired.has(role):
			for member: Dictionary in staff_in_role(role):
				ids.append(str(member.get("staff_id", "")))
	return ids


## The hired record for this person (primary or extra), {} when not hired, with
## "role" and "primary" added for the caller.
func hired_member(staff_id: String) -> Dictionary:
	for role: String in DataDB.staff.map(func(row: Dictionary) -> String: return str(row.get("role", ""))):
		var members := staff_in_role(role)
		for i in members.size():
			if str(members[i].get("staff_id", "")) == staff_id:
				var found := (members[i] as Dictionary).duplicate()
				found["role"] = role
				found["primary"] = i == 0
				return found
	return {}


## Hires a candidate into their role, spending Funds, if the role has a free
## place and the price is affordable. The first hire in a role is its primary;
## later ones (once the slot item is bought) are extras. Immediately applies
## whichever tier_N_reward matches the tier they START at (candidates do not
## all start at tier 0, SF05 and SF07 start at tier 1).
func hire_staff(staff_id: String) -> String:
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var role := str(candidate.get("role", ""))
	if not hired_member(staff_id).is_empty():
		return Text.say("shop.already_yours")
	if bool(staff_quit.get(staff_id, false)):
		return Text.say("staff.quit_never_returns")
	var members := staff_in_role(role)
	if members.size() >= staff_slots():
		return Text.say("office.staff_slots_full") if staff_slots() > 1 else Text.say("shop.already_yours")
	var funds := int(meta.get("Funds", 0))
	# The role has a free place, so the Ledger sees it as vacant.
	var refusal := Ledger.staff_hire_refusal(candidate, {},
		bool(staff_fired.get(staff_id, false)), funds, staff_recruitment_tier, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -int(candidate.get("hiring_cost_yen", 0)))
	var starting_tier := int(candidate.get("starting_tier", 0))
	var record := {"staff_id": staff_id, "tier": starting_tier}
	if members.is_empty():
		staff_hired[role] = record
	else:
		if not staff_extra.has(role):
			staff_extra[role] = []
		(staff_extra[role] as Array).append(record)
	staff_loyalty[staff_id] = Levers.whole("staff_loyalty_start")
	staff_invested[staff_id] = int(candidate.get("hiring_cost_yen", 0))
	staff_weeks[staff_id] = 0
	_apply_staff_reward(candidate, starting_tier)
	return ""


## Upgrades a role's primary to the next tier (see upgrade_staff_member()).
func upgrade_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return Text.say("staff.nobody_hired")
	return upgrade_staff_member(str(hired.get("staff_id", "")))


## Upgrades a hired person (primary or extra) to the next tier, spending Funds,
## if that step exists for them and is affordable. Applies the new tier's
## reward on top of whatever hiring (and any earlier upgrade) already gave:
## these are one-time bonuses per tier reached, not a repeating income, the
## same way a modifier's RESOURCE_BONUS_ON_WIN tier is a flat payment rather
## than a rate (see ModifierEffects.gd).
func upgrade_staff_member(staff_id: String) -> String:
	var found := hired_member(staff_id)
	if found.is_empty():
		return Text.say("staff.nobody_hired")
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var tier := int(found.get("tier", 0))
	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_upgrade_refusal(candidate, tier, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal
	if StaffLoyalty.band(staff_loyalty_of(staff_id)) != StaffLoyalty.BAND_NORMAL:
		return Text.say("staff.upgrade_refused_restless", {"name": str(candidate.get("name", staff_id))})

	var cost := int(Ledger.staff_upgrade_cost(candidate, tier))
	_move_meta("Funds", -cost)
	staff_invested[staff_id] = staff_invested_in(staff_id) + cost

	var new_tier := tier + 1
	_set_member_tier(str(found["role"]), staff_id, new_tier)
	_apply_staff_reward(candidate, new_tier)
	return ""


func _set_member_tier(role: String, staff_id: String, tier: int) -> void:
	var primary: Dictionary = staff_hired.get(role, {})
	if str(primary.get("staff_id", "")) == staff_id:
		primary["tier"] = tier
		staff_hired[role] = primary
		return
	for entry: Variant in (staff_extra.get(role, []) as Array):
		if str((entry as Dictionary).get("staff_id", "")) == staff_id:
			(entry as Dictionary)["tier"] = tier


## Fires a role's primary (see fire_staff_member()).
func fire_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return Text.say("staff.nobody_hired")
	return fire_staff_member(str(hired.get("staff_id", "")))


## Fires a hired person, spending a severance (Ledger.staff_firing_cost())
## from Funds. Their place goes vacant and can be filled with a different
## candidate right away, but not with this one: whatever the hire and every
## upgrade already paid out (Funds spent, standing and favourability gained)
## stands; nothing is refunded or clawed back, and the fired candidate is
## marked in staff_fired so they never appear hireable again this run.
## Cameron's decision, 2026-09-25 (design/proposals/staff_firing.md). When the
## primary is fired and extras remain, the first extra becomes the primary.
func fire_staff_member(staff_id: String) -> String:
	var found := hired_member(staff_id)
	if found.is_empty():
		return Text.say("staff.nobody_hired")
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_fire_refusal(candidate, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -Ledger.staff_firing_cost(candidate))
	# Firing costs standing with the people's allies, but no Reputation
	# (Cameron, 2026-11-16); quitting costs more (_staff_leave).
	_apply_leaving_penalty(candidate, int(found.get("tier", 0)), false)
	_remove_staff_record(found)
	staff_fired[staff_id] = true
	return ""


## Takes a person off the staff list (promoting the first extra when they were
## the primary) and forgets their wage and Loyalty. Used by firing and quitting.
func _remove_staff_record(found: Dictionary) -> void:
	var staff_id := str(found.get("staff_id", ""))
	var role := str(found["role"])
	if bool(found.get("primary", false)):
		staff_hired.erase(role)
		var extras: Array = staff_extra.get(role, [])
		if not extras.is_empty():
			staff_hired[role] = extras.pop_front()
	else:
		var extras: Array = staff_extra.get(role, [])
		for i in extras.size():
			if str((extras[i] as Dictionary).get("staff_id", "")) == staff_id:
				extras.remove_at(i)
				break
	for table: Dictionary in [staff_loyalty, staff_invested, staff_weeks, staff_raise_pay, staff_thanked, staff_week_tasks, staff_last_week]:
		table.erase(staff_id)


# ---------------------------------------------------------------------------
# Staff wages and Loyalty (Cameron, 2026-11-16). StaffLoyalty.gd holds the
# rules; the run state is the staff_* dictionaries near the top of this file.

## A person's Loyalty (the starting value for someone with no record yet).
func staff_loyalty_of(staff_id: String) -> int:
	return int(staff_loyalty.get(staff_id, Levers.whole("staff_loyalty_start")))


## Everything paid for a person so far: what the run recorded, or (an older
## save) the hire and the upgrades up to the rank they hold.
func staff_invested_in(staff_id: String) -> int:
	if staff_invested.has(staff_id):
		return int(staff_invested[staff_id])
	var found := hired_member(staff_id)
	return StaffLoyalty.invested_for(DataDB.get_staff(staff_id), int(found.get("tier", 0)))


## This week's wage for a person (more when their pay was raised).
func staff_wage_of(staff_id: String) -> int:
	return StaffLoyalty.wage(staff_invested_in(staff_id), bool(staff_raise_pay.get(staff_id, false)))


## Everyone hired, each { staff_id, role, primary, tier }, role by role.
func staff_members() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for role: String in Ledger.staff_roles(DataDB.staff):
		var members := staff_in_role(role)
		for i in members.size():
			out.append({"staff_id": str(members[i].get("staff_id", "")), "role": role,
				"primary": i == 0, "tier": int(members[i].get("tier", 0))})
	return out


## What all staff cost this week, and whether Funds after the party dues would
## cover it (the warning before the week ends).
func staff_wage_preview() -> Dictionary:
	var total := 0
	for member: Dictionary in staff_members():
		total += staff_wage_of(str(member["staff_id"]))
	var after_dues := int(meta.get("Funds", 0)) - int(dues_preview()["total"])
	return {"total": total, "funds_after_dues": after_dues, "short": total > maxi(0, after_dues)}


func staff_loyalty_add(staff_id: String, amount: int) -> void:
	if not staff_loyalty.has(staff_id) and hired_member(staff_id).is_empty():
		return
	staff_loyalty[staff_id] = clampi(staff_loyalty_of(staff_id) + amount, 0, 100)


## Why this person cannot have their pay raised this week, or "".
func raise_pay_refusal(staff_id: String) -> String:
	if hired_member(staff_id).is_empty():
		return Text.say("staff.nobody_hired")
	if bool(staff_raise_pay.get(staff_id, false)):
		return Text.say("staff.raise_pay_done")
	return ""


## Pays one person half as much again this week for a one-time Loyalty gain.
func raise_pay(staff_id: String) -> String:
	var refusal := raise_pay_refusal(staff_id)
	if not refusal.is_empty():
		return refusal
	staff_raise_pay[staff_id] = true
	staff_loyalty_add(staff_id, Levers.whole("staff_raise_pay_loyalty"))
	return ""


## Why the public thank-you is not open now, or "".
func thank_refusal(staff_id: String) -> String:
	if hired_member(staff_id).is_empty():
		return Text.say("staff.nobody_hired")
	if bool(staff_thanked.get(staff_id, false)):
		return Text.say("staff.thank_done")
	var need := Levers.whole("staff_thank_in_public_minimum_reputation")
	if int(meta.get("Reputation", 0)) < need:
		return Text.say("staff.thank_reputation", {"count": need})
	var hours := Levers.whole("staff_thank_in_public_hours")
	if hours > WeekCalendar.hours_left(calendar, calendar_config()) or is_in_level():
		return Text.say("staff.thank_hours", {"count": hours})
	return ""


## Thanks a person in public: takes a few hours, once a week each, for a
## one-time Loyalty gain.
func thank_in_public(staff_id: String) -> String:
	var refusal := thank_refusal(staff_id)
	if not refusal.is_empty():
		return refusal
	spend_hours(Levers.whole("staff_thank_in_public_hours"))
	staff_thanked[staff_id] = true
	staff_loyalty_add(staff_id, Levers.whole("staff_thank_in_public_loyalty"))
	return ""


## Quit or fire penalty: standing with every ally (times its weight), and for a
## resignation Reputation. Returns StaffLoyalty.leaving_penalty()'s result.
func _apply_leaving_penalty(candidate: Dictionary, tier: int, quit: bool) -> Dictionary:
	var penalty := StaffLoyalty.leaving_penalty(StaffLoyalty.allies(candidate, tier), quit)
	var standing: Dictionary = penalty["standing"]
	_under_cause(Text.say("record.cause_staff"), func() -> void:
		for organization: String in standing.keys():
			_apply_booster_delta(organization, int(standing[organization])))
	if int(penalty["reputation"]) != 0:
		_under_cause(Text.say("record.cause_staff"),
			func() -> void: _move_meta("Reputation", int(penalty["reputation"])))
	return penalty


## The person resigns for good: off the list, never hireable again, with the
## penalty. Returns what the report shows { name, reputation, allies }.
func _staff_leave(staff_id: String) -> Dictionary:
	var found := hired_member(staff_id)
	var candidate := DataDB.get_staff(staff_id)
	if found.is_empty() or candidate.is_empty():
		return {}
	var penalty := _apply_leaving_penalty(candidate, int(found.get("tier", 0)), true)
	var names: Array[String] = []
	for organization: String in (penalty["standing"] as Dictionary).keys():
		names.append(str(DataDB.get_booster(organization).get("name_en", organization)))
	_remove_staff_record(found)
	staff_quit[staff_id] = true
	return {"name": str(candidate.get("name", staff_id)), "reputation": int(penalty["reputation"]), "allies": names}


## One rank lost: the rank's rewards are taken back (the standing they gave),
## and it can be bought again at the normal price.
func _staff_lose_rank(staff_id: String) -> void:
	var found := hired_member(staff_id)
	var candidate := DataDB.get_staff(staff_id)
	if found.is_empty() or candidate.is_empty():
		return
	var tier := int(found.get("tier", 0))
	_apply_staff_reward(candidate, tier, -1)
	_set_member_tier(str(found["role"]), staff_id, tier - 1)


# ---------------------------------------------------------------------------
# Daily staff tasks (Cameron, 2026-11-16). StaffTasks.gd holds the rules.

## The game state the drivers read, as plain numbers (StaffPoolModifiers).
func staff_driver_state() -> Dictionary:
	var members := staff_members()
	var loyalty_sum := 0
	for member: Dictionary in members:
		loyalty_sum += staff_loyalty_of(str(member["staff_id"]))
	return {
		"dues_owed": dues_balance,
		"open_promises": promises.size(),
		"district_awareness": int(awareness.get("district", 0)),
		"national_awareness": int(awareness.get("national", 0)),
		"reputation": int(meta.get("Reputation", 0)),
		"constituency_support": int(meta.get("Constituency support", 0)),
		"party_support": int(meta.get("Party support", 0)),
		"level_in_progress": 1 if is_in_level() else 0,
		"avg_staff_loyalty": -1 if members.is_empty() else int(float(loyalty_sum) / float(members.size())),
		"weekday": WeekCalendar.weekday_index(calendar, calendar_config()),
	}


## Leaves a change for the next `days` task pools: extra (or fewer) tasks of a
## family, or `MAX` to change the day's maximum. `label` is what the screen
## says caused it.
func staff_add_pool_change(family: String, amount: int, days: int, label: String) -> void:
	if amount == 0 or family.is_empty():
		return
	staff_pool_mods.append({"family": family, "amount": amount, "draws_left": maxi(1, days), "label": label})


## Blocks in one person's day: one per hour of the calendar day (8 on a
## weekday, 4 on a weekend day).
func staff_day_blocks() -> int:
	return WeekCalendar.day_limit(str(calendar["phase"]), calendar_config())


func _staff_today_key() -> int:
	return WeekCalendar.today_number(calendar, calendar_config())


func _staff_clear_day() -> void:
	staff_day_key = -1
	staff_day_pool = []
	staff_day_plan = {}
	staff_day_confirmed = false
	staff_day_delegated = {}
	staff_day_items = {}
	staff_day_reasons = []
	staff_day_adds = {}
	staff_day_shuffles = 0


## Brings the staff day up to the calendar. A confirmed plan whose day has just
## ended (the next day, or the week was ended) is applied; a day that was
## skipped over by a long level goes out of effect, no rewards or penalties.
## `force_resolve` is the week's end, which always settles the day it leaves.
func staff_day_sync(force_resolve: bool = false) -> void:
	if staff_day_key < 0:
		return
	var today := _staff_today_key()
	if staff_day_key == today and not force_resolve:
		return
	# A delivered day settles when it ends, confirmed or not, with staff or not
	# (Cameron, 2026-11-16): at least the Due tasks nobody took cost their penalty.
	if not staff_day_pool.is_empty() and (force_resolve or today - staff_day_key == 1):
		_staff_resolve_day()
	_staff_clear_day()


## Makes sure today has a pool of tasks (drawn once, seeded by the date and
## the protagonist so it is the same however often the screen opens).
func staff_ensure_day() -> void:
	staff_day_sync()
	if staff_day_key >= 0 or DataDB.staff_tasks.is_empty():
		return
	var today := _staff_today_key()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [protagonist_id, today])
	var weekend := in_weekend()
	# What changes today's pool: the drivers (game state) and the items and
	# events that left a change for it, then the day's maximum from the ramp.
	var driver_rng := RandomNumberGenerator.new()
	driver_rng.seed = hash("drivers:%s:%d" % [protagonist_id, today])
	var changes := StaffPoolModifiers.merged(
		StaffPoolModifiers.from_drivers(DataDB.staff_task_drivers, staff_driver_state(), driver_rng),
		StaffPoolModifiers.from_mods(staff_pool_mods))
	staff_pool_mods = StaffPoolModifiers.after_draw(staff_pool_mods)
	var maximum := StaffTasks.day_maximum(DataDB.staff_task_ramp, int(calendar.get("week", 0)), weekend,
		int(changes["max_delta"]))
	staff_day_pool = StaffTasks.draw_pool(DataDB.staff_tasks, DataDB.staff_task_families, _staff_task_targets(),
		maximum, weekend, changes["adds"], rng)
	staff_day_reasons = changes["reasons"]
	staff_day_max = maximum
	staff_day_adds = changes["adds"]
	staff_day_shuffles = 0
	staff_day_key = today
	staff_day_blocks_total = staff_day_blocks()
	staff_day_plan = {}
	staff_day_confirmed = false
	staff_day_delegated = {}
	staff_day_items = {}


## The named things the tasks need, all from the data: organizations (Boosters
## tab), committees and ministers' posts (the opponents' Title column).
func _staff_task_targets() -> Dictionary:
	var organizations: Array[Dictionary] = []
	for booster: Dictionary in DataDB.boosters:
		organizations.append({"id": str(booster.get("booster_id", "")), "name": str(booster.get("name_en", ""))})
	var committees: Array[Dictionary] = []
	var officials: Array[Dictionary] = []
	var seen := {}
	var prefixes: Array = DataDB.rules.get("staff_task_official_prefixes", [])
	var marker := str(DataDB.rules.get("staff_task_committee_marker", ""))
	for opponent: Dictionary in DataDB.opponents:
		var committee := StaffTasks.committee_in(opponent.get("title"), marker)
		if not committee.is_empty() and not seen.has(committee):
			seen[committee] = true
			committees.append({"id": committee, "name": committee})
		for post: String in StaffTasks.official_posts(opponent.get("title"), prefixes):
			if not seen.has(post):
				seen[post] = true
				officials.append({"id": str(opponent.get("opp_id", "")), "name": post})
	return {"organization": organizations, "committee": committees, "official": officials}


## The people the evaluation reads: { staff_id, role, tier, loyalty }.
func _staff_eval_members() -> Array:
	var out: Array = []
	for member: Dictionary in staff_members():
		var id := str(member["staff_id"])
		out.append({"staff_id": id, "role": str(member["role"]), "tier": int(member["tier"]),
			"loyalty": staff_loyalty_of(id)})
	return out


func _staff_day_info() -> Dictionary:
	var bonus := {}
	for member: Dictionary in staff_members():
		var rank_hours := staff_rank_hours(str(member["staff_id"])) + staff_office_hours()
		if rank_hours > 0:
			bonus[str(member["staff_id"])] = rank_hours
	var strong := {}
	var percent := {}
	var quiet := {}
	var no_penalty := {}
	var double_best := {}
	for id: String in staff_day_items.keys():
		var info := staff_item_info(str(staff_day_items[id]))
		match str(info["effect"]):
			"HOURS":
				bonus[id] = int(bonus.get(id, 0)) + int(info["value"])
			"STRONG_FAMILY":
				strong[id] = str(info["target"])
			"REWARD_MULT":
				percent[id] = int(info["value"])
			"QUIET":
				quiet[id] = true
			"NO_PENALTY":
				no_penalty[id] = true
			"DOUBLE_BEST":
				double_best[id] = int(info["value"])
	return {"blocks": staff_day_blocks_total, "delegated": staff_day_delegated, "full_days": staff_full_days,
		"bonus": bonus, "strong_family": strong, "reward_percent": percent, "quiet": quiet,
		"no_penalty": no_penalty, "double_best": double_best}


## What the plan, as it stands, would do: the same numbers the day's end applies.
func staff_projection() -> Dictionary:
	return StaffTasks.evaluate(staff_day_pool, DataDB.staff_tasks, staff_day_plan, _staff_eval_members(), _staff_day_info())


## Hours in one person's day today: the day's hours plus any item given to them.
func staff_day_hours(staff_id: String) -> int:
	return staff_day_blocks_total + staff_rank_hours(staff_id) + staff_office_hours() \
		+ staff_item_hours(str(staff_day_items.get(staff_id, "")))


## Hours an item in the Office box adds to EVERY staff member's day today
## (the Kaiju-sized coffee and tea), 0 when the box holds something else.
func staff_office_hours() -> int:
	var info := staff_item_info(staff_office_item)
	return maxi(0, int(info.get("value", 0))) if str(info["effect"]) == "HOURS_ALL" else 0


## The extra hours a person's rank gives them on a weekday (Cameron,
## 2026-11-16): one per rank (Balance `Staff Tasks: Hours Per Tier`), so Tier 0
## works 8 hours, Tier 1 works 9 and Tier 2 works 10. It is the rank they hold
## now, whatever they were hired at or the player has bought, and a weekend day
## (shorter than a workday) has no bonus.
func staff_rank_hours(staff_id: String) -> int:
	if staff_day_blocks_total < int(calendar_config()["workday_hours"]):
		return 0
	return maxi(0, int(hired_member(staff_id).get("tier", 0))) * Levers.whole("staff_tasks_hours_per_tier")


## What a staff item does (the Shop's Staff Effect columns): { effect, value,
## target, slot, days }, effect "" for any other item. An item with only the
## older Staff Hours cell counts as an HOURS item.
func staff_item_info(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {"effect": ""}
	var item := DataDB.get_shop_item(item_id)
	var effect := str(item.get("staff_effect", "")) if item.get("staff_effect") != null else ""
	if effect.is_empty() and item.get("staff_hours") != null and int(item["staff_hours"]) > 0:
		return {"effect": "HOURS", "value": int(item["staff_hours"]), "target": "", "slot": "Person", "days": 1,
			"uses": ItemUses.full_uses(item)}
	if effect.is_empty():
		return {"effect": ""}
	return {"effect": effect, "value": int(item.get("staff_value", 0)) if item.get("staff_value") != null else 0,
		"target": str(item.get("staff_target", "")) if item.get("staff_target") != null else "",
		"slot": str(item.get("staff_slot", "Person")) if item.get("staff_slot") != null else "Person",
		"days": maxi(1, int(item.get("staff_days", 1)) if item.get("staff_days") != null else 1),
		"uses": ItemUses.full_uses(item)}


## The hours an item adds to a staff member's day; 0 for any other item.
func staff_item_hours(item_id: String) -> int:
	var info := staff_item_info(item_id)
	return maxi(0, int(info.get("value", 0))) if str(info["effect"]) == "HOURS" else 0


## The items that can be used on the Staff Assignments screen, each { item_id,
## name, effect, slot, value, target, hours, held, free, icon }: how many you
## hold and how many are not yet promised. Only items you hold are listed.
func staff_usable_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item: Dictionary in DataDB.shop:
		var id := str(item.get("item_id", ""))
		var info := staff_item_info(id)
		var held := item_count(id)
		if str(info["effect"]).is_empty() or held <= 0:
			continue
		var planned := 0
		for value: Variant in staff_day_items.values():
			if str(value) == id:
				planned += 1
		if staff_office_item == id:
			planned += 1
		out.append({"item_id": id, "name": str(item.get("name", id)), "effect": str(info["effect"]),
			"slot": str(info["slot"]), "value": int(info["value"]), "target": str(info["target"]),
			"hours": staff_item_hours(id), "held": held, "free": maxi(0, held - planned),
			"uses": int(info.get("uses", 1)), "uses_left": item_uses_left(id),
			"icon": str(item.get("icon", "")) if item.get("icon") != null else ""})
	return out


## The place an item goes: a person's staff_id, or OFFICE for the Office box.
const OFFICE_BOX := "OFFICE"

## Office items that act the moment they are used (the day's tasks are already
## delivered, so they cannot wait for the day to be confirmed): the Printer, the
## Shredder and the Priority Inbox. Each spends one use when it acts.
const INSTANT_EFFECTS := ["ADD_TASKS", "CLEAR_TASKS", "RESHUFFLE"]


func staff_item_is_instant(item_id: String) -> bool:
	return str(staff_item_info(item_id)["effect"]) in INSTANT_EFFECTS


## Why an item cannot go to a person (or the Office box) now: one of
## StaffTasks.REFUSE_*, or "".
func staff_item_refusal(item_id: String, target: String) -> String:
	if staff_day_confirmed:
		return StaffTasks.REFUSE_LOCKED
	var info := staff_item_info(item_id)
	if str(info["effect"]).is_empty():
		return StaffTasks.REFUSE_UNKNOWN
	var to_office := target == OFFICE_BOX
	if to_office != (str(info["slot"]) == "Office"):
		return StaffTasks.REFUSE_ITEM_SLOT
	if not to_office and hired_member(target).is_empty():
		return StaffTasks.REFUSE_UNKNOWN
	if staff_item_is_instant(item_id):
		if staff_day_pool.is_empty():
			return StaffTasks.REFUSE_UNKNOWN
		if str(info["effect"]) == "CLEAR_TASKS" and StaffTasks.clearable(staff_day_pool, DataDB.staff_tasks, staff_day_plan).is_empty():
			return StaffTasks.REFUSE_NOTHING
	elif (to_office and staff_office_item == item_id) or (not to_office and str(staff_day_items.get(target, "")) == item_id):
		return StaffTasks.REFUSE_ITEM_HAVE
	for entry: Dictionary in staff_usable_items():
		if str(entry["item_id"]) == item_id and int(entry["free"]) > 0:
			return ""
	return StaffTasks.REFUSE_ITEM_NONE


## Gives a person an item for the day (one each; a second replaces the first),
## or puts an Office item in the Office box.
func staff_assign_item(item_id: String, target: String) -> String:
	var refusal := staff_item_refusal(item_id, target)
	if not refusal.is_empty():
		return refusal
	if staff_item_is_instant(item_id):
		_staff_use_instant(item_id)
	elif target == OFFICE_BOX:
		staff_office_item = item_id
	else:
		staff_day_items[target] = item_id
	return ""


## Uses an Office item that acts at once, spending one use, and leaves a line
## in `staff_use_notes` for the screen to show.
func _staff_use_instant(item_id: String) -> void:
	staff_use_notes = []
	var info := staff_item_info(item_id)
	var label := str(DataDB.get_shop_item(item_id).get("name", item_id))
	var rng := RandomNumberGenerator.new()
	staff_day_shuffles += 1
	rng.seed = hash("use:%s:%d:%d:%s" % [protagonist_id, staff_day_key, staff_day_shuffles, item_id])
	match str(info["effect"]):
		"ADD_TASKS":
			var extra := StaffTasks.draw_extra(DataDB.staff_tasks, _staff_task_targets(), staff_day_pool, int(info["value"]), rng)
			for entry: Dictionary in extra:
				staff_day_pool.append(entry)
			staff_day_max += extra.size()
			staff_use_notes.append(Text.say("assign.use_added", {"item": label, "count": extra.size()}))
		"CLEAR_TASKS":
			var gone := StaffTasks.pick_to_clear(staff_day_pool, DataDB.staff_tasks, staff_day_plan, int(info["value"]), rng)
			var kept: Array[Dictionary] = []
			for entry: Dictionary in staff_day_pool:
				if not gone.has(str(entry.get("uid", ""))):
					kept.append(entry)
			staff_day_pool = kept
			staff_use_notes.append(Text.say("assign.use_cleared", {"item": label, "count": gone.size()}))
		"RESHUFFLE":
			staff_day_pool = StaffTasks.draw_pool(DataDB.staff_tasks, DataDB.staff_task_families, _staff_task_targets(),
				staff_day_max, in_weekend(), staff_day_adds, rng)
			staff_day_plan = {}
			staff_use_notes.append(Text.say("assign.use_reshuffled", {"item": label}))
	_spend_use(item_id)


## Takes a person's item back, or empties the Office box (nothing once the day is confirmed).
func staff_unassign_item(target: String) -> void:
	if staff_day_confirmed:
		return
	if target == OFFICE_BOX:
		staff_office_item = ""
	else:
		staff_day_items.erase(target)


## The person's taste in gifts: { likes, dislikes } (item ids), and the Loyalty each gives.
func staff_gift_taste(staff_id: String) -> Dictionary:
	var row := DataDB.get_staff(staff_id)
	var likes: Array = row.get("gift_likes", []) if row.get("gift_likes") != null else []
	var dislikes: Array = row.get("gift_dislikes", []) if row.get("gift_dislikes") != null else []
	return {"likes": likes, "dislikes": dislikes,
		"like_loyalty": int(row["gift_like_loyalty"]) if row.get("gift_like_loyalty") != null else Levers.whole("staff_gift_like_loyalty"),
		"neutral_loyalty": int(row["gift_neutral_loyalty"]) if row.get("gift_neutral_loyalty") != null else Levers.whole("staff_gift_neutral_loyalty"),
		"dislike_loyalty": int(row["gift_dislike_loyalty"]) if row.get("gift_dislike_loyalty") != null else Levers.whole("staff_gift_dislike_loyalty")}


## What a gift does to this person's Loyalty (no change made).
func staff_gift_loyalty(staff_id: String, item_id: String) -> int:
	var taste := staff_gift_taste(staff_id)
	if (taste["likes"] as Array).has(item_id):
		return int(taste["like_loyalty"])
	if (taste["dislikes"] as Array).has(item_id):
		return int(taste["dislike_loyalty"])
	return int(taste["neutral_loyalty"])


## Hands a gift over: Loyalty by taste, and their taste becomes known.
func _give_gift(staff_id: String, item_id: String) -> void:
	var change := staff_gift_loyalty(staff_id, item_id)
	staff_loyalty_add(staff_id, change)
	staff_taste_known[staff_id] = true
	var taste := staff_gift_taste(staff_id)
	var key := "assign.gift_loved" if (taste["likes"] as Array).has(item_id) \
		else ("assign.gift_disliked" if (taste["dislikes"] as Array).has(item_id) else "assign.gift_fine")
	var name := str(DataDB.get_staff(staff_id).get("name", staff_id))
	match key:
		"assign.gift_loved":
			staff_gift_notes.append(Text.say("assign.gift_loved", {"name": name, "count": "%+d" % change}))
		"assign.gift_disliked":
			staff_gift_notes.append(Text.say("assign.gift_disliked", {"name": name, "count": "%+d" % change}))
		_:
			staff_gift_notes.append(Text.say("assign.gift_fine", {"name": name, "count": "%+d" % change}))


## Blocks of a person's day already taken (tasks and delegated work).
func staff_blocks_used(staff_id: String) -> int:
	return StaffTasks.blocks_used(staff_id, staff_day_pool, DataDB.staff_tasks, staff_day_plan, staff_day_delegated)


## Why a task cannot go to a person now: one of StaffTasks.REFUSE_*, or "".
func staff_assign_refusal(uid: String, staff_id: String) -> String:
	return StaffTasks.assign_refusal(uid, staff_id, staff_day_pool, DataDB.staff_tasks, staff_day_plan,
		staff_day_delegated, staff_day_hours(staff_id), staff_day_confirmed)


## Gives a task to a person (taking it off whoever had it). Returns a refusal code or "".
func staff_assign(uid: String, staff_id: String) -> String:
	if staff_day_confirmed:
		return StaffTasks.REFUSE_LOCKED
	if hired_member(staff_id).is_empty():
		return StaffTasks.REFUSE_UNKNOWN
	var holder := ""
	for id: String in staff_day_plan.keys():
		if (staff_day_plan[id] as Array).has(uid):
			holder = id
	staff_unassign(uid)
	var refusal := staff_assign_refusal(uid, staff_id)
	if not refusal.is_empty():
		# Nothing moved: it goes back to whoever had it.
		if not holder.is_empty():
			if not staff_day_plan.has(holder):
				staff_day_plan[holder] = []
			(staff_day_plan[holder] as Array).append(uid)
		return refusal
	if not staff_day_plan.has(staff_id):
		staff_day_plan[staff_id] = []
	(staff_day_plan[staff_id] as Array).append(uid)
	return ""


## Takes a task back off whoever holds it (nothing once the day is confirmed).
func staff_unassign(uid: String) -> void:
	if staff_day_confirmed:
		return
	for id: String in staff_day_plan.keys():
		(staff_day_plan[id] as Array).erase(uid)
	for id: String in staff_day_plan.keys():
		if (staff_day_plan[id] as Array).is_empty():
			staff_day_plan.erase(id)


## Why the day cannot be confirmed yet, or "".
func staff_confirm_refusal() -> String:
	if staff_day_confirmed:
		return Text.say("assign.confirmed_already")
	if staff_day_pool.is_empty():
		return Text.say("assign.no_tasks")
	if staff_day_plan.is_empty():
		return Text.say("assign.nothing_assigned")
	return ""


## Locks the day's plan; it is applied when the day ends.
func staff_confirm_day() -> String:
	var refusal := staff_confirm_refusal()
	if not refusal.is_empty():
		return refusal
	staff_day_confirmed = true
	# The items given out are used up now: gifts are handed over, and an item in
	# the Office box leaves a change for the next pool.
	staff_gift_notes = []
	staff_use_notes = []
	for id: String in staff_day_items.keys():
		var item_id := str(staff_day_items[id])
		if str(staff_item_info(item_id)["effect"]) == "GIFT":
			_give_gift(id, item_id)
			_take_item(item_id)   # a gift is handed over whole
		else:
			_spend_use(item_id)
	if not staff_office_item.is_empty():
		var office := staff_item_info(staff_office_item)
		var label := str(DataDB.get_shop_item(staff_office_item).get("name", staff_office_item))
		match str(office["effect"]):
			"POOL_FAMILY":
				staff_add_pool_change(str(office["target"]), int(office["value"]), int(office["days"]), label)
			"POOL_MAX":
				staff_add_pool_change(StaffPoolModifiers.MAX, int(office["value"]), int(office["days"]), label)
		_spend_use(staff_office_item)
		staff_office_item = ""
	for note: Variant in staff_use_notes:
		staff_gift_notes.append(note)
	staff_use_notes = []
	return ""


## Applies a confirmed day: meta, XP, awareness and standing from the tasks,
## and Loyalty into the week's task bucket. Leaves a report for the screen.
func _staff_resolve_day() -> void:
	# A day that was not confirmed (or has no staff) is judged as if nothing was
	# given out: only the Due tasks nobody took cost anything.
	var confirmed := staff_day_confirmed and not staff_members().is_empty()
	var result := StaffTasks.evaluate(staff_day_pool, DataDB.staff_tasks, staff_day_plan if confirmed else {},
		_staff_eval_members() if confirmed else [], _staff_day_info() if confirmed else {"blocks": staff_day_blocks_total})
	if (result["lines"] as Array).is_empty() and (result["undone"] as Array).is_empty():
		return
	_under_cause(Text.say("record.cause_staff"), func() -> void:
		for name: String in (result["meta"] as Dictionary).keys():
			_move_meta(name, int(result["meta"][name]))
		for organization: String in (result["standing"] as Dictionary).keys():
			_apply_booster_delta(organization, int(result["standing"][organization])))
	_move_xp(int(result["xp"]))
	for meter: String in (result["awareness"] as Dictionary).keys():
		apply_awareness_delta(meter.to_lower(), int(result["awareness"][meter]))
	var cap := Levers.whole("staff_tasks_week_loyalty_cap")
	for id: String in (result["loyalty"] as Dictionary).keys():
		staff_week_tasks[id] = clampi(int(staff_week_tasks.get(id, 0)) + int(result["loyalty"][id]), -cap, cap)
	for id: String in (result["full_days"] as Dictionary).keys():
		staff_full_days[id] = int(result["full_days"][id])
	staff_report_pending = {"date": WeekCalendar.date_label(staff_day_key), "result": result,
		"pool": staff_day_pool.duplicate(true)}


## The last day's result, once: the Office shows it and it is forgotten.
func take_staff_report() -> Dictionary:
	var report := staff_report_pending
	staff_report_pending = {}
	return report


## The week's end for the staff: wages are paid (in order, in full, while Funds
## last), every person's Loyalty moves, ranks are lost, and people resign.
## Called by go_home() after the party dues. Returns what the new-week popup
## lists: { paid_total, paid [names], missed [names], rank_lost [names],
## quit [{name, reputation, allies}] }.
func _settle_staff_week() -> Dictionary:
	var report := {"paid_total": 0, "paid": [], "missed": [], "rank_lost": [], "quit": []}
	var members := staff_members()
	if members.is_empty():
		return report

	var entries: Array = []
	for member: Dictionary in members:
		var id := str(member["staff_id"])
		entries.append({"staff_id": id, "primary": member["primary"], "loyalty": staff_loyalty_of(id),
			"wage": staff_wage_of(id)})
	var settled := StaffLoyalty.settle_wages(StaffLoyalty.pay_order(entries), int(meta.get("Funds", 0)))
	if int(settled["spent"]) > 0:
		_links_suspended = true
		_under_cause(Text.say("record.cause_staff_wages"),
			func() -> void: _move_meta("Funds", -int(settled["spent"])))
		_links_suspended = false
	report["paid_total"] = int(settled["spent"])

	var leaving: Array[String] = []
	for member: Dictionary in members:
		var id := str(member["staff_id"])
		var candidate := DataDB.get_staff(id)
		var name := str(candidate.get("name", id))
		var paid := (settled["paid"] as Array).has(id)
		var tier := int(member["tier"])
		var starting := int(candidate.get("starting_tier", 0))
		var weeks := int(staff_weeks.get(id, 0)) + 1
		staff_weeks[id] = weeks
		var parts := {
			"paid": paid,
			"affinity": StaffLoyalty.affinity(StaffLoyalty.allies(candidate, tier), booster_standing),
			"tenure": StaffLoyalty.tenure_gain(weeks),
			"pride": StaffLoyalty.pride_gain(tier, starting),
			"tasks": int(staff_week_tasks.get(id, 0)),
		}
		var change := StaffLoyalty.weekly_total(paid, int(parts["affinity"]), int(parts["tenure"]),
			int(parts["pride"]), int(parts["tasks"]))
		parts["total"] = change
		staff_last_week[id] = parts
		var outcome := StaffLoyalty.after_week(clampi(staff_loyalty_of(id) + change, 0, 100), not paid, tier, starting)
		staff_loyalty[id] = int(outcome["loyalty"])
		if paid:
			(report["paid"] as Array).append(name)
		else:
			(report["missed"] as Array).append(name)
		if bool(outcome["quits"]):
			leaving.append(id)
		elif bool(outcome["rank_lost"]):
			_staff_lose_rank(id)
			(report["rank_lost"] as Array).append(name)
	for id: String in leaving:
		var gone := _staff_leave(id)
		if not gone.is_empty():
			(report["quit"] as Array).append(gone)
	staff_raise_pay = {}
	staff_thanked = {}
	staff_week_tasks = {}
	return report


## Makes a hired extra the role's primary, the person every scene, notice and
## item bonus reads; the old primary becomes an extra. "" when done.
func make_primary(staff_id: String) -> String:
	var found := hired_member(staff_id)
	if found.is_empty():
		return Text.say("staff.nobody_hired")
	if bool(found.get("primary", false)):
		return ""
	var role := str(found["role"])
	var old_primary: Dictionary = staff_hired.get(role, {})
	var extras: Array = staff_extra.get(role, [])
	for i in extras.size():
		if str((extras[i] as Dictionary).get("staff_id", "")) == staff_id:
			staff_hired[role] = extras[i]
			extras[i] = old_primary
			return ""
	return Text.say("staff.nobody_hired")


## True for the Shop item that adds a place to every staff role (SH plus the
## Balance number "Staff Slots: Item Number").
func is_staff_slot_item(item: Dictionary) -> bool:
	var number := Levers.whole("staff_slots_item_number")
	return number > 0 and str(item.get("item_id", "")) == "SH%d" % number


## True once the staff slot item has been bought the most times allowed
## (Balance "Staff Slots: Maximum Purchases").
func staff_slots_maxed() -> bool:
	return staff_slot_buys >= Levers.whole("staff_slots_maximum_purchases")


## Why the staff slot item cannot be bought now, in words, or "". The item's
## XP and Funds prices go through Items; its Reputation price is a Balance
## number (Cameron, 2026-11-08: no Shop column for it).
func staff_slot_refusal(item: Dictionary) -> String:
	var refusal := Items.buy_refusal(item, item_count(str(item.get("item_id", ""))), 0,
		xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal
	if staff_slots_maxed():
		return Text.say("shop.staff_slots_maxed")
	var need := Levers.whole("staff_slots_reputation_cost")
	if int(meta.get("Reputation", 0)) < need:
		return Text.say("shop.reputation_short", {"count": need - int(meta.get("Reputation", 0))})
	return ""


## The staff slot item: pays XP, Funds and Reputation, then every role holds one
## more person. { ok, message }.
func buy_staff_slots(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := staff_slot_refusal(item)
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	_move_meta("Reputation", -Levers.whole("staff_slots_reputation_cost"))
	staff_slot_buys += 1
	return {"ok": true, "message": Text.say("shop.staff_slots_bought")}


## A staff tier's reward, applied the moment it is reached (on hire, and
## again on every upgrade that reaches a new tier).
##
## Each reward is {"delta": int, "target": "BOxx or SGxx"}.
func _apply_staff_reward(candidate: Dictionary, tier: int, sign: int = 1) -> void:
	var rewards: Variant = candidate.get("tier_%d_reward" % tier)
	if not (rewards is Array):
		return

	for reward: Variant in rewards:
		if not (reward is Dictionary):
			continue
		var target := str((reward as Dictionary).get("target", ""))
		var delta := int((reward as Dictionary).get("delta", 0)) * sign
		if target.begins_with("BO"):
			_under_cause(Text.say("record.cause_staff"), func() -> void: _apply_booster_delta(target, delta))
		elif target.begins_with("SG"):
			_apply_segment_delta(target, delta)


## Replaces the deck, if the new one is legal.
func set_deck(chosen: Array[String]) -> String:
	var refusal := Ledger.deck_refusal(chosen, owned_cards, deck_balance(), Text.phrase())
	if not refusal.is_empty():
		return refusal

	deck = chosen.duplicate()
	return ""


## Every organisation back to where it starts — its own "Starting Standing"
## column on the workbook's Boosters tab (`boosters.json`'s own
## `starting_standing`, Cameron's to write per organisation), or
## booster_standing.json's flat "start" for any booster that column leaves
## blank (2026-09-28: the flat 50 for every organisation read the same on
## the Backing screen whatever the group, so standing now differs per
## booster). A blank cell exports as JSON null, not 0 — the usual
## <null>-safe check, since a real "start at zero" has to stay possible.
func reset_booster_standing() -> void:
	booster_standing = {}
	last_booster_change = {}
	last_booster_cause = {}

	var start := int(DataDB.booster_standing.get("start", 30))
	for booster: Dictionary in DataDB.boosters:
		var own_start: Variant = booster.get("starting_standing")
		booster_standing[str(booster.get("booster_id"))] = start if own_start == null else int(own_start)

## Decay now runs on the game clock (2026-10-18): once for every Decay Interval
## units (Balance tab; 0 = off) that have passed since it last ran. Organizations
## nobody dealt with since then drift toward their starting standing, every
## organization settles by its own Decay Percent, and meta values with a Decay
## Percent settle. It used to run once at the end of every level.
func _apply_time_decays() -> void:
	var interval := Levers.whole("decay_interval")
	if interval <= 0:
		last_decay_at = time_units
		return
	while time_units - last_decay_at >= interval:
		last_decay_at += interval
		_decaying = true
		_apply_neglect_decay()
		_apply_standing_decay()
		_apply_meta_decay()
		_decaying = false
		booster_moved_in_period = {}


# ---------------------------------------------------------------------------
# Name awareness (2026-10-23, Cameron): two meters, district and national.

## Both meters back to their starting values (Balance), for a fresh run.
func reset_awareness() -> void:
	awareness_gaffe_tally = {"district": 0, "national": 0}
	awareness = {
		"district": clampi(Levers.whole("awareness_start_district"), 0, awareness_max()),
		"national": clampi(Levers.whole("awareness_start_national"), 0, awareness_max()),
	}
	last_awareness_change = {}
	awareness_streaks = {}


func awareness_max() -> int:
	return maxi(1, Levers.whole("awareness_maximum"))


## Moves one meter ("district" or "national"), clamped to 0 to the maximum.
func apply_awareness_delta(meter: String, delta: int) -> void:
	if delta == 0 or not awareness.has(meter):
		return
	var before := int(awareness[meter])
	var after := clampi(before + delta, 0, awareness_max())
	awareness[meter] = after
	if after != before:
		last_awareness_change[meter] = int(last_awareness_change.get(meter, 0)) + (after - before)


## Gaffes still on the counter when a stage ends count against BOTH meters, one
## point each. A player who clears them before the end loses nothing; a stage
## lost to gaffes costs the stage's whole gaffe limit.
func apply_awareness_gaffes(gaffes: int) -> void:
	gaffes = Difficulty.awareness_gaffes(gaffes, DataDB.balance_base, difficulty)
	if gaffes <= 0:
		return
	# Gaffes left over add up across the whole run (Cameron, 2026-11-02): every
	# "Awareness Gaffes Per District Point" cost 1 District awareness, and every
	# "... Per National Point" cost 1 National.
	for meter: String in ["district", "national"]:
		var per := maxi(1, Levers.whole("awareness_gaffes_per_%s_point" % meter))
		var before := int(awareness_gaffe_tally.get(meter, 0))
		awareness_gaffe_tally[meter] = before + gaffes
		apply_awareness_delta(meter, -((before + gaffes) / per - before / per))


# ---------------------------------------------------------------------------
# Election strength (2026-10-23, Cameron): built and shown, fires no outcome.

## What the campaign's inputs read right now (ElectionStrength.components()).
func election_inputs() -> Dictionary:
	var cfg := ElectionStrength.settings(DataDB.balance)
	var on_side := 0
	for id: String in booster_standing.keys():
		if int(booster_standing[id]) >= int(cfg["org_standing"]):
			on_side += 1
	var laws := 0
	for law: Dictionary in statute_book:
		if bool(law.get("passed", false)):
			laws += 1
	return {
		"district": int(awareness.get("district", 0)),
		"national": int(awareness.get("national", 0)),
		"constituency": int(meta.get("Constituency support", 0)),
		"org_share": float(on_side) / maxf(1.0, float(booster_standing.size())),
		"funds": int(meta.get("Funds", 0)),
		"xp_earned": xp_earned_total,
		"laws_passed": laws,
		"party_support": int(meta.get("Party support", 0)),
		"dues_overdue": dues_balance > 0,
	}


## Each input's points and maximum, for the Your Record page.
func election_parts() -> Array:
	return ElectionStrength.components(ElectionStrength.settings(DataDB.balance), election_inputs())


## What the inputs add up to right now (the strength grows toward this).
func election_potential() -> float:
	return ElectionStrength.potential(election_parts())


## At each week end the strength moves toward the potential, by at most the
## weekly cap.
func _update_election_strength() -> void:
	election_strength = ElectionStrength.step(election_strength, election_potential(),
		ElectionStrength.settings(DataDB.balance))


# ---------------------------------------------------------------------------
# Events (2026-10-23, Cameron): bought or arriving on their own.

## Time spent outside a stage (an event): hours off the calendar and onto the clock.
func spend_hours(hours: int) -> void:
	if hours <= 0:
		return
	calendar = WeekCalendar.advance(calendar, hours, calendar_config())
	_advance_clock(hours)


func event_context() -> Dictionary:
	var cfg := calendar_config()
	return {"weekend": in_weekend(), "week_full": work_week_is_full(),
		"hours_left": WeekCalendar.hours_left(calendar, cfg),
		"funds": int(meta.get("Funds", 0)), "xp": xp, "now": time_units, "last_at": event_last_at,
		"default_cooldown": Levers.whole("event_default_cooldown_hours"),
		"district": int(awareness.get("district", 0)), "national": int(awareness.get("national", 0)), "dues_owed": dues_balance,
		"month": current_month(), "seasons": DataDB.rules.get("seasons", {}), "office": office_location,
		"place_types": DataDB.place_types_for(protagonist_id)}


## Today's calendar month, 1-12 (for seasonal levels and events).
func current_month() -> int:
	return int(WeekCalendar.civil_from_days(WeekCalendar.today_number(calendar, calendar_config()))[1])


## True when a seasonal level or event (its Seasons cell) may show today.
func in_season(row: Dictionary) -> bool:
	return Seasons.in_season(row, current_month(), DataDB.rules.get("seasons", {}))


func get_event(event_id: String) -> Dictionary:
	for event: Dictionary in DataDB.events:
		if str(event.get("event_id", "")) == event_id:
			return event
	return {}


## The dated event due today, as an Event ID; "" when none is. It stays due
## until the player has made its choice.
func due_dated_event() -> String:
	var today := WeekCalendar.today_number(calendar, calendar_config())
	# An Optional scene's event is opened from the Events screen, never by itself.
	var held_back: Array[String] = dated_events_done.duplicate()
	for scene: Dictionary in DataDB.decision_scenes:
		if DecisionScenes.is_optional(scene):
			held_back.append(str(scene.get("event_id", "")))
	var due := EventEngine.due_dated(DataDB.events, today, held_back)
	if not due.is_empty():
		return str(due[0].get("event_id", ""))
	# A Decision! follow-up whose Delay has run out comes next (Mandatory: it opens by itself). One waits while what its earlier
	# scene started (a whip fight, a vote) has not been played yet, and a whip scene for a party with no line never opens (P15).
	for scene: Dictionary in DecisionScenes.due_follow_ups(DataDB.decision_scenes, decision_log, today):
		if _scene_waits_for_activation(str(scene.get("follows", ""))):
			continue
		if DecisionScenes.whip_is_banded(scene) and whip_line(scene).is_empty():
			decision_log[str(scene.get("scene_id", ""))] = {"day": today, "choice": WHIP_SKIPPED_LETTER}
			continue
		return str(scene.get("event_id", ""))
	return ""


## The reserved choice letter a whip scene is remembered under when the player's party has no line on its bill: the scene never
## opens and never comes later.
const WHIP_SKIPPED_LETTER := "S"


## True while a scene's answer has started a level, stage or vote the player has not played yet.
func _scene_waits_for_activation(scene_id: String) -> bool:
	for entry: Dictionary in pending_activations:
		if str(entry.get("scene_id", "")) == scene_id:
			return true
	return false


# --- Whip scenes (P15, 2026-11-23) -------------------------------------------------------------------------------------------

## The Floor Vote bill a whip scene is about, as its data row; {} when the scene is not a whip scene.
func whip_bill_of(scene: Dictionary) -> Dictionary:
	return DataDB.floor_votes.get(DecisionScenes.whip_bill(scene), {}) if DecisionScenes.is_whip(scene) else {}


## What the whip of this scene asks of the player: "Yes" or "No", or "" for a free vote (no line).
func whip_line(scene: Dictionary) -> String:
	return WhipPick.line_for(scene, whip_bill_of(scene), own_party_id())


## Who whips the player in this scene, as an opponent ID: the scene's own Speaker, or, for a scene picked by Party support, the
## party's whip for the band (WhipPick). Fixed the first time it is asked, so the card, the stage and a reload agree.
func whip_pick_for(scene: Dictionary) -> String:
	var speakers := DecisionScenes.speaker_ids(scene)
	if not speakers.is_empty():
		return speakers[0]
	var scene_id := str(scene.get("scene_id", ""))
	if not whip_picks.has(scene_id):
		var bands: Dictionary = DataDB.rules.get("whip_bands", {})
		var minister := DataDB.get_opponent(str(scene.get("minister", ""))) if scene.get("minister") != null else {}
		whip_picks[scene_id] = WhipPick.pick(party_support_effective(), bands, DataDB.get_party(str(DataDB.player.get("party", ""))), minister)
	return str(whip_picks[scene_id])


## The opponent a whip fights as: the pick, with the player's own party written on a Party Whip's Office row (their party cell is
## blank so one row serves every party), so the cue lines "the party backs / opposes joining" read the player's party's line.
func whip_opponent(opp_id: String) -> Dictionary:
	var opponent := DataDB.get_opponent(opp_id).duplicate(true)
	if opponent.is_empty():
		return opponent
	var written: Variant = opponent.get("party")
	if written == null or str(written).strip_edges().is_empty():
		var party := DataDB.get_party(str(DataDB.player.get("party", "")))
		opponent["party"] = str(party.get("name", ""))
		opponent["party_acronym"] = str(party.get("short_name", ""))
	return opponent


## What the player may press on a Floor Vote for this bill: WhipPick.resolve over the locks lost whip fights put on it.
func vote_lock(bill_id: String) -> Dictionary:
	return WhipPick.resolve(whip_locks.get(bill_id, []))


## A whip stage has ended: losing it locks the bill's vote to what the whip asked (the level carries "whip"). Returns the lock
## state after, {} when the stage was not a whip fight or was won.
func _record_whip_result(level: Dictionary, outcome: String) -> Dictionary:
	var whip: Variant = level.get("whip")
	if not (whip is Dictionary) or outcome != LevelRunner.LOST:
		return {}
	var bill_id := str((whip as Dictionary).get("bill", ""))
	var lock := {"choice": str((whip as Dictionary).get("line", "")), "by": str((whip as Dictionary).get("opp_id", "")),
		"scene_id": str((whip as Dictionary).get("scene_id", ""))}
	whip_locks[bill_id] = WhipPick.with_lock(whip_locks.get(bill_id, []), lock)
	var state := vote_lock(bill_id)
	pending_trigger_alerts.append({"kind": "whip_lost", "edge": "abstain" if str(state["state"]) == "abstain" else "entered",
		"name": str(DataDB.get_opponent(str(lock["by"])).get("name", "")), "bill": str(DataDB.get_bill(bill_id).get("bill_name", bill_id)),
		"vote": Text.say("whip.aye" if str(lock["choice"]) == WhipPick.YES else "whip.nay")})
	return state


## What answering a scene with choice `letter` starts (Activates column, phase 3): an unlock and a queued event happen at once;
## a level, stage or vote waits in pending_activations for the Office to offer. Returns the lines that tell the player.
func _start_scene_activations(scene: Dictionary, letter: String) -> Array[String]:
	var lines: Array[String] = []
	for entry: Dictionary in DecisionScenes.activations_for(scene, letter):
		var kind := str(entry["kind"])
		var id := str(entry["id"])
		match kind:
			DecisionScenes.KIND_UNLOCK:
				if not discovered_levels.has(id):
					discovered_levels.append(id)
					lines.append(Text.say("event.level_revealed", {"name": str(DataDB.get_level(id).get("description", id))}))
			DecisionScenes.KIND_EVENT:
				if not get_event(id).is_empty():
					scheduled_events.append({"event_id": id, "due_at": time_units})
			_:
				if DecisionScenes.LEVEL_KINDS.has(kind) and not _activation_pending(kind, id):
					var started := {"kind": kind, "id": id, "scene_id": str(scene.get("scene_id", ""))}
					# A whip scene's stage is the fight with its whip: who it is and what they asked go with it.
					if kind == DecisionScenes.KIND_STAGE and DecisionScenes.is_whip(scene):
						started["whip"] = {"opp_id": whip_pick_for(scene), "bill": DecisionScenes.whip_bill(scene),
							"line": whip_line(scene), "scene_id": str(scene.get("scene_id", ""))}
					pending_activations.append(started)
					lines.append(Text.say("decision.activation_ready", {"name": activation_name(kind, id)}))
	return lines


## Puts a scene's Activates cell back as it was (a test changes it on the loaded data and undoes it here).
func scene_decision_scene_restore(event_id: String, activates: Variant) -> void:
	decision_scene_of(event_id)["activates"] = activates


func _activation_pending(kind: String, id: String) -> bool:
	for entry: Dictionary in pending_activations:
		if str(entry.get("kind")) == kind and str(entry.get("id")) == id:
			return true
	return false


## What the briefing and the notice call an activation: the level's description, the stage's name or the bill's name.
func activation_name(kind: String, id: String) -> String:
	match kind:
		DecisionScenes.KIND_LEVEL:
			return str(DataDB.get_level(id).get("description", id))
		DecisionScenes.KIND_STAGE:
			return str(DataDB.get_stage(id).get("name_en", id))
		_:
			return str(DataDB.get_bill(id).get("bill_name", id))


## The first level a scene has started and the player has not yet played, as {"kind", "id", "scene_id", "level"}; {} when none.
## A stage or vote becomes a one-stage level here (registered so the briefing and the level runner can find it by its ID).
func next_activation() -> Dictionary:
	for entry: Dictionary in pending_activations:
		var kind := str(entry.get("kind", ""))
		var id := str(entry.get("id", ""))
		var scene := DecisionScenes.find(DataDB.decision_scenes, str(entry.get("scene_id", "")))
		var level := {}
		if kind == DecisionScenes.KIND_LEVEL:
			level = DataDB.get_level(id)
		else:
			level = DecisionScenes.ad_hoc_level(kind, id, activation_name(kind, id), DecisionScenes.office(scene))
			var whip: Variant = entry.get("whip")
			if whip is Dictionary:
				level["whip"] = whip
				level["opponent_pin"] = str((whip as Dictionary).get("opp_id", ""))
				level["whip_bill"] = str((whip as Dictionary).get("bill", ""))
			DataDB.register_runtime_level(level)
		if not level.is_empty():
			return {"kind": kind, "id": id, "scene_id": str(entry.get("scene_id", "")), "level": level}
	return {}


## The level has begun: its activation is no longer pending, and a one-stage level is remembered for a mid-level save.
func finish_activation(level_id: String) -> void:
	for entry: Dictionary in pending_activations.duplicate():
		var kind := str(entry.get("kind", ""))
		var id := str(entry.get("id", ""))
		var made := DecisionScenes.AD_HOC_PREFIX + kind + "_" + id
		if (kind == DecisionScenes.KIND_LEVEL and id == level_id) or made == level_id:
			pending_activations.erase(entry)
			if made == level_id:
				scene_runtime = {"level": DataDB.get_level(level_id)}


# --- Optional scenes (phase 4) ---------------------------------------------------------------------------------------------------

## The Optional scenes that can be opened today, as [{scene, event, days_left, refusal}]: refusal is "" when the player stands at
## the scene's office, else why not.
func optional_scenes_open() -> Array:
	var today := WeekCalendar.today_number(calendar, calendar_config())
	var out: Array = []
	for scene: Dictionary in DecisionScenes.open_now(DataDB.decision_scenes, decision_log, today):
		var event := get_event(str(scene.get("event_id", "")))
		if event.is_empty():
			continue
		var office := Offices.normalize(DecisionScenes.office(scene))
		var refusal := ""
		if office != Offices.EITHER and office != office_location:
			refusal = Text.say("event.optional_elsewhere", {"place": TravelText.place_name(office)})
		out.append({"scene": scene, "event": event, "days_left": DecisionScenes.days_left(scene, decision_log, today), "refusal": refusal})
	return out


## Whether an Optional scene's event can be opened now; "" when it can, else why not.
func optional_scene_refusal(event_id: String) -> String:
	for entry: Dictionary in optional_scenes_open():
		if str((entry["event"] as Dictionary).get("event_id", "")) == event_id:
			return str(entry["refusal"])
	return Text.say("event.optional_closed")


## Optional scenes whose window closed unopened apply their lapse penalty (the reserved choice L) and are remembered as lapsed.
## Returns what happened, one entry each: {event_id, result_text, lines}, for the Office to tell the player.
func apply_scene_lapses() -> Array:
	var today := WeekCalendar.today_number(calendar, calendar_config())
	var told: Array = []
	for scene: Dictionary in DecisionScenes.lapsed(DataDB.decision_scenes, decision_log, today):
		var event_id := str(scene.get("event_id", ""))
		var result := apply_event_choice(event_id, DecisionScenes.LAPSE_LETTER, "", true)
		# A scene with no penalty row still lapses (and is remembered), so it is not checked again every day.
		if not decision_log.has(str(scene.get("scene_id", ""))):
			decision_log[str(scene.get("scene_id", ""))] = {"day": today, "choice": DecisionScenes.LAPSE_LETTER}
		if bool(result.get("ok", false)):
			told.append({"event_id": event_id, "result_text": str(result.get("result_text", "")), "lines": result.get("lines", [])})
	return told


## The opponent row an event is about, or {}: the Decision Scenes tab's Speaker when the event is a scene (and that speaker is
## an opponent), else the event's Speaker Title.
func event_speaker(event_id: String) -> Dictionary:
	var scene := decision_scene_of(event_id)
	# A whip scene with no Speaker is spoken by the whip the player's Party support picks (P15).
	if DecisionScenes.whip_is_banded(scene):
		return whip_opponent(whip_pick_for(scene))
	for id: String in DecisionScenes.speaker_ids(scene):
		if DecisionScenes.person_kind(id) == "opponent":
			return DataDB.get_opponent(id)
	var title: Variant = get_event(event_id).get("speaker_title")
	return EventEngine.speaker(DataDB.opponents, "" if title == null else str(title))


## The Decision Scenes row that holds this event, or {} when it is not a scene (2026-11-21).
func decision_scene_of(event_id: String) -> Dictionary:
	return DecisionScenes.of_event(DataDB.decision_scenes, event_id)


## The people on a Decision! card, first speaker then second: {id, name, title, face}. Each id may be an opponent, a staff
## member or a visitor (the Decision Scenes tab's Speaker columns). With no scene, the event's own speaker (a title lookup), if any.
func event_speakers(event_id: String) -> Array:
	var scene := decision_scene_of(event_id)
	var out: Array = []
	if scene.is_empty():
		var lone := event_speaker(event_id)
		if not lone.is_empty():
			out.append({"id": str(lone.get("opp_id", "")), "name": str(lone.get("name", "")),
				"title": OpponentDisplay.title_for(lone), "face": "neutral"})
		return out
	var ids := DecisionScenes.speaker_ids(scene)
	# A whip scene with no Speaker is spoken by the whip the player's Party support picks (P15).
	if DecisionScenes.whip_is_banded(scene):
		ids = [whip_pick_for(scene)]
	for id: String in ids:
		var kind := DecisionScenes.person_kind(id)
		var opponent := DataDB.get_opponent(id) if kind == "opponent" else {}
		var staff := DataDB.get_staff(id) if kind == "staff" else {}
		var visitor := DataDB.get_visitor(id) if kind == "visitor" else {}
		var name := str(opponent.get("name", staff.get("name", visitor.get("name_en", ""))))
		var title := OpponentDisplay.title_for(opponent) if not opponent.is_empty() \
			else str(staff.get("role", visitor.get("title", "")))
		out.append({"id": id, "name": name, "title": title, "face": DecisionScenes.face(scene)})
	return out


# ---------------------------------------------------------------------------
# Capitol venues (P16, 2026-11-23, Cameron): Step out from the Capitol office to the Cafeteria, the Gardens and the Speech Coach.
# The pure rules are VenueRules.gd, VenueLines.gd and RhetoricTips.gd; this is the state they read and write.
# ---------------------------------------------------------------------------

## Whether the player may step out now: one of VenueRules's reason codes (VenueRules.OPEN when they may).
func step_out_state() -> String:
	return VenueRules.step_out_state(office_location == Offices.CAPITOL, is_in_level(), work_hours_left())


## Today as a day number (the venue lines' day).
func venue_today() -> int:
	return WeekCalendar.today_number(calendar, calendar_config())


## The venue row, its activity row and the Rules rows' walking hours, for the screens.
func venue_row(venue_id: String) -> Dictionary:
	for venue: Dictionary in DataDB.venues:
		if str(venue.get("venue_id", "")) == venue_id:
			return venue
	return {}


func venue_walk_hours(venue_id: String) -> int:
	return VenueRules.walk_hours(str(venue_row(venue_id).get("zone", "")), int(DataDB.get_rule("venue_walk_hours_building", 0)),
		int(DataDB.get_rule("venue_walk_hours_area", 0)))


func venue_limit() -> int:
	return int(DataDB.get_rule("venue_daily_heard", 8))


## What the lines' conditions, dates and seasons read today.
func venue_context() -> Dictionary:
	return {"today": venue_today(), "month": current_month(), "seasons": DataDB.rules.get("seasons", {}),
		"meta": effective_meta(), "laws": law_statuses(), "staff_hired": staff_hired, "heard": venue_heard_once}


## How many Text rows each hint kind and suit has, {"stage_suit.earnest": 3, ...}, counted from the Text tab.
func hint_phrasings() -> Dictionary:
	var counts := {}
	for key: Variant in DataDB.strings.keys():
		var text := str(key)
		for kind: String in [RhetoricTips.STAGE, RhetoricTips.OPPONENT]:
			var prefix := "hint.%s." % kind
			if text.begins_with(prefix):
				var rest := text.substr(prefix.length())
				var suit := rest.substr(0, rest.rfind("_"))
				counts["%s.%s" % [kind, suit]] = int(counts.get("%s.%s" % [kind, suit], 0)) + 1
	return counts


## The stages and people a rhetoric tip may be about this week: the rooms of the levels on offer here and of the next Decision! scene.
func tip_targets() -> Dictionary:
	var stage_ids: Array = []
	var by_stage := {}
	for level: Dictionary in levels_on_offer():
		for slot in range(1, 11):
			var raw: Variant = level.get("stage_%d" % slot)
			var stage_id := "" if raw == null else str(raw)
			if stage_id.is_empty() or stage_id == "N/A" or BattleSetup._is_bill_id(stage_id) or stage_ids.has(stage_id):
				continue
			stage_ids.append(stage_id)
			by_stage[stage_id] = BattleSetup.eligible_opponents(stage_id)
	var stage_rows := {}
	for stage_id: Variant in stage_ids:
		stage_rows[str(stage_id)] = DataDB.get_stage(str(stage_id))
	var extra: Array = []
	var today := venue_today()
	for scene: Dictionary in DataDB.decision_scenes:
		if decision_log.has(str(scene.get("scene_id", ""))):
			continue
		for id: String in DecisionScenes.speaker_ids(scene):
			if DecisionScenes.person_kind(id) == "opponent":
				extra.append(DataDB.get_opponent(id))
		for entry: Dictionary in DecisionScenes.parse_activates(scene.get("activates")):
			if str(entry["kind"]) == DecisionScenes.KIND_STAGE and not stage_ids.has(str(entry["id"])):
				stage_ids.append(str(entry["id"]))
				stage_rows[str(entry["id"])] = DataDB.get_stage(str(entry["id"]))
		break   # only the next scene (the first unanswered one in the tab's order)
	if today < 0:
		extra = []
	return RhetoricTips.targets(stage_ids, stage_rows, by_stage, extra)


## Today's dealt set for a venue, dealt once and kept (so a reload never reshuffles): {"day", "dealt", "heard", "dry"}.
func venue_day(venue_id: String) -> Dictionary:
	var today := venue_today()
	var kept: Variant = venue_days.get(venue_id)
	if kept is Dictionary and int((kept as Dictionary).get("day", -1)) == today:
		return kept as Dictionary
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	var dealt: Array = []
	if VenueRules.deals_lines(activity):
		dealt = VenueLines.deal(DataDB.venue_lines, str(activity.get("pool", "")), venue_context(),
			VenueLines.seed_for(run_seed, today, venue_id), int(DataDB.get_rule("venue_daily_set", 12)),
			int(DataDB.get_rule("venue_hint_share", 8)), tip_targets(), hint_phrasings())
	var entry := {"day": today, "dealt": dealt, "heard": 0, "dry": false}
	venue_days[venue_id] = entry
	return entry


## Lines the player may still hear at a venue today before the dry line (0 when the set is used up).
func venue_lines_left(venue_id: String) -> int:
	var entry := venue_day(venue_id)
	return maxi(mini((entry["dealt"] as Array).size(), venue_limit()) - int(entry["heard"]), 0)


## Why a venue's activity cannot be started: "" when it can, else a Text row's sentence. A visit with nothing left to hear today is
## refused ("Come back tomorrow") without taking the hour.
func venue_visit_refusal(venue_id: String) -> String:
	match step_out_state():
		VenueRules.ELSEWHERE: return Text.say("venue.refuse_elsewhere")
		VenueRules.IN_LEVEL: return Text.say("venue.refuse_in_level")
		VenueRules.WEEK_FULL: return Text.say("venue.refuse_week_full")
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	if activity.is_empty() or not VenueRules.is_built(activity):
		return Text.say("venue.coming_soon")
	if VenueRules.deals_lines(activity) and venue_lines_left(venue_id) <= 0 and bool(venue_day(venue_id)["dry"]):
		return Text.say("venue.come_back")
	match VenueRules.visit_refusal(activity, work_hours_left() - venue_walk_hours(venue_id), int(meta.get("Funds", 0)), xp):
		"hours": return Text.say("venue.refuse_hours")
		"funds": return Text.say("venue.refuse_funds")
		"xp": return Text.say("venue.refuse_xp")
	return ""


## Starts a visit: takes the walking and the activity's hours (once) and its Funds and XP. {"ok": false, "reason"} when it cannot.
func venue_visit(venue_id: String) -> Dictionary:
	var why := venue_visit_refusal(venue_id)
	if not why.is_empty():
		return {"ok": false, "reason": why}
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	var cost := VenueRules.visit_cost(activity)
	spend_hours(venue_walk_hours(venue_id) + int(cost["hours"]))
	if int(cost["funds"]) > 0:
		_apply_meta_reward("Funds", -int(cost["funds"]))
	if int(cost["xp"]) > 0:
		_move_xp(-int(cost["xp"]))
	venue_day(venue_id)
	return {"ok": true, "reason": ""}


## The next line at a venue, free of hours: {"ok", "number", "limit", "kind": "gossip", "watch", "hint" or "dry", "speaker", "text",
## "hint": {...}, "last": true when no line is left}. After the limit (or the set) one dry line is shown, once; {"ok": false} after it.
func venue_hear_next(venue_id: String) -> Dictionary:
	var entry := venue_day(venue_id)
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	var heard := int(entry["heard"])
	var next := VenueLines.next_dealt(entry["dealt"] as Array, heard, venue_limit())
	if next.is_empty():
		if bool(entry["dry"]):
			return {"ok": false}
		var dry := VenueLines.dry_line(DataDB.venue_lines, venue_context(), VenueLines.seed_for(run_seed, venue_today(), venue_id + "|dry"))
		entry["dry"] = true
		return {"ok": true, "number": heard, "limit": venue_limit(), "kind": "dry", "speaker": str(dry.get("speaker", "")),
			"text": str(dry.get("text", Text.say("venue.nothing_new"))), "hint": {}, "last": true, "where": str(activity.get("pool", ""))}
	var row := VenueLines.find(DataDB.venue_lines, str(next["line_id"]))
	entry["heard"] = heard + 1
	if str(row.get("once", "")).strip_edges().to_upper() == "Y":
		venue_heard_once[str(row.get("line_id", ""))] = true
	var hint: Dictionary = next.get("hint", {})
	var text := str(row.get("text", ""))
	if not hint.is_empty():
		text = _hint_text(hint)
		held_tips = RhetoricTips.add(held_tips, RhetoricTips.make(hint, str(activity.get("pool", "")), venue_today()),
			int(DataDB.get_rule("tips_max_held", 10)))
	var raw_speaker: Variant = row.get("speaker")
	return {"ok": true, "number": heard + 1, "limit": venue_limit(), "kind": "hint" if not hint.is_empty() else str(row.get("topic", "")),
		"speaker": "" if raw_speaker == null else str(raw_speaker), "text": text, "hint": hint,
		"last": VenueLines.next_dealt(entry["dealt"] as Array, heard + 1, venue_limit()).is_empty(), "where": str(activity.get("pool", ""))}


## The sentence of a dealt hint: its Text row with the stage's or the person's name filled in.
func _hint_text(hint: Dictionary) -> String:
	var target := str(hint.get("target", ""))
	if str(hint.get("kind", "")) == RhetoricTips.STAGE:
		return Text.say(str(hint.get("text_key", "")), {"stage": str(DataDB.get_stage(target).get("name_en", target))})
	return Text.say(str(hint.get("text_key", "")), {"name": str(DataDB.get_opponent(target).get("name", target))})


## The rhetoric tips still held today (expired ones are dropped).
func tips_held() -> Array:
	held_tips = RhetoricTips.unexpired(held_tips, venue_today(), int(DataDB.get_rule("tips_days", 14)))
	return held_tips


func tip_days_left(tip: Dictionary) -> int:
	return RhetoricTips.days_left(tip, venue_today(), int(DataDB.get_rule("tips_days", 14)))


## The office an event belongs to ("Capitol", "District", "Either"): its Decision Scenes row's Office when it is a scene, else
## its own Location cell.
func event_office(event: Dictionary) -> String:
	var scene := decision_scene_of(str(event.get("event_id", "")))
	return Offices.normalize(DecisionScenes.office(scene) if not scene.is_empty() else event.get("location"))


## The Buyable events, in workbook order.
func buyable_events() -> Array:
	var found: Array = []
	for event: Dictionary in DataDB.events:
		if str(event.get("trigger", "")) == "Buyable" and in_season(event) \
				and Offices.is_here(event.get("location"), office_location) \
				and PlaceTokens.has_types(PlaceTokens.names_by_type(DataDB.places, protagonist_id), event.get("needs_place")):
			found.append(event)
	return found


## Why this event cannot be arranged right now, as a sentence; "" when it can.
func event_refusal(event: Dictionary) -> String:
	match EventEngine.refusal(event, event_context()):
		EventEngine.REFUSE_WEEK_OVER: return Text.say("event.refuse_week_over")
		EventEngine.REFUSE_WEEKDAY: return Text.say("event.refuse_weekday")
		EventEngine.REFUSE_WEEKEND: return Text.say("event.refuse_weekend")
		EventEngine.REFUSE_HOURS: return Text.say("event.refuse_hours")
		EventEngine.REFUSE_COOLDOWN: return Text.say("event.refuse_cooldown")
		EventEngine.REFUSE_FUNDS: return Text.say("event.refuse_funds")
		EventEngine.REFUSE_XP: return Text.say("event.refuse_xp")
	return ""


## Arranges a bought event: its price is paid now. False (nothing paid) when it
## cannot be arranged.
func start_event(event_id: String) -> bool:
	var event := get_event(event_id)
	if event.is_empty() or not event_refusal(event).is_empty():
		return false
	var cost_funds := int(event.get("cost_funds", 0)) if event.get("cost_funds") != null else 0
	var cost_xp := int(event.get("cost_xp", 0)) if event.get("cost_xp") != null else 0
	_links_suspended = true
	_under_cause(Text.say("record.cause_event"), func() -> void:
		if cost_funds > 0:
			_apply_meta_reward("Funds", -cost_funds))
	_links_suspended = false
	if cost_xp > 0:
		_move_xp(-cost_xp)
	return true


## At the Office after a level or a week end: maybe an event arrives. Returns
## its id, or "" for a quiet day. Consumes the roll either way.
func roll_random_event() -> String:
	if not event_roll_due:
		return ""
	event_roll_due = false
	# Real-click tests turn random events off (tools/verify.sh) so a chance
	# pop-up never lands on top of the button they are about to press.
	if OS.has_environment("COP_NO_RANDOM_EVENTS"):
		return ""
	if randf() * 100.0 >= Levers.num("event_random_chance_percent"):
		return ""
	var pool := EventEngine.eligible_random(DataDB.events, event_context())
	return str(EventEngine.pick_weighted(pool, randf()).get("event_id", ""))


## The player's choice: pays any choice price, rolls and applies every reward,
## reveals a level, spends the event's hours and starts its cooldown.
## Returns { ok, result_text, lines: [String], chips: [..], revealed: level name }.
## `lapse` is for an Optional Decision! scene whose window closed unopened: its reserved choice L is applied as the penalty, no
## hours pass, no price can refuse it and the player is not asked.
func apply_event_choice(event_id: String, letter: String, delegate_id: String = "", lapse: bool = false) -> Dictionary:
	var event := get_event(event_id)
	var chosen := EventEngine.lapse_choice(DataDB.event_choices, event_id) if lapse else {}
	if not lapse:
		for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
			if str(row.get("choice", "")) == letter:
				chosen = row
	if event.is_empty() or chosen.is_empty():
		return {"ok": false}
	var price := int(chosen.get("funds_cost", 0)) if chosen.get("funds_cost") != null else 0
	if lapse:
		price = mini(price, maxi(0, int(meta.get("Funds", 0))))   # a penalty takes what there is
	# A choice that hands the job to a role needs a named person (Cameron,
	# 2026-11-16): how well they do it decides the result.
	var delegate_role := event_delegate_role(chosen)
	var fit := StaffTasks.STRONG
	var delegate_blocks := 0
	if not delegate_role.is_empty():
		var found := hired_member(delegate_id)
		if delegate_id.is_empty() or found.is_empty():
			return {"ok": false}
		staff_ensure_day()
		delegate_blocks = event_delegate_blocks(event, chosen)
		if staff_blocks_left(delegate_id) < delegate_blocks:
			return {"ok": false}
		fit = StaffTasks.delegate_fit(delegate_role, str(found["role"]), staff_loyalty_of(delegate_id))
		if fit == StaffTasks.STRONG:
			price = 0   # the right person handles it without the spend
	if price > 0 and int(meta.get("Funds", 0)) < price:
		return {"ok": false}
	var commitments := [] if lapse else Commitments.of(chosen)
	if not commitment_refusal(commitments).is_empty():
		return {"ok": false}

	var lines: Array[String] = []
	var cause := Text.say("record.cause_event")
	if price > 0:
		_links_suspended = true
		_under_cause(cause, func() -> void: _apply_meta_reward("Funds", -price))
		_links_suspended = false
	var meta_columns := {"funds_delta": "Funds", "constituency_delta": "Constituency support",
		"reputation_delta": "Reputation", "party_support_delta": "Party support"}
	for column: String in meta_columns.keys():
		var rolled := StaffTasks.delegate_gain(_roll_range(chosen.get(column)), fit)
		if rolled == 0:
			continue
		var variable: String = meta_columns[column]
		_under_cause(cause, func() -> void: _apply_meta_reward(variable, rolled))
		lines.append(Text.say("event.effect_line", {"name": variable,
			"change": Phrase.meta_amount(variable, rolled, true)}))
	var xp_rolled := StaffTasks.delegate_gain(_roll_range(chosen.get("xp_delta")), fit)
	if xp_rolled != 0:
		_move_xp(xp_rolled)
		lines.append(Text.say("event.effect_line", {"name": "XP", "change": "%+d" % xp_rolled}))
	for meter: String in ["district", "national"]:
		var meter_rolled := StaffTasks.delegate_gain(_roll_range(chosen.get(meter + "_delta")), fit)
		if meter_rolled == 0:
			continue
		apply_awareness_delta(meter, meter_rolled)
		lines.append(Text.say("event.effect_line", {"change": "%+d" % meter_rolled,
			"name": Text.say("awareness.district") if meter == "district" else Text.say("awareness.national")}))

	# A negative Dues change writes down the balance carried over from an
	# unpaid week (never below nothing); a positive one is ignored.
	var dues_rolled := _roll_range(chosen.get("dues_delta"))
	if dues_rolled < 0 and dues_balance > 0:
		var cleared := mini(-dues_rolled, dues_balance)
		dues_balance -= cleared
		lines.append(Text.say("event.dues_line", {"change": Phrase.meta_amount("Funds", -cleared, true)}))

	var chips: Array = []
	var rewards: Variant = chosen.get("rewards")
	if rewards is Array and not (rewards as Array).is_empty():
		var before := _cause
		_cause = cause
		chips = _effect_chips(_apply_reward_entries(_delegated_rewards(rewards as Array, fit)))
		_cause = before

	var revealed := ""
	var unlock: Variant = chosen.get("unlocks_level")
	if unlock != null and not str(unlock).is_empty():
		var level_id := str(unlock)
		if not discovered_levels.has(level_id):
			discovered_levels.append(level_id)
		revealed = str(DataDB.get_level(level_id).get("description", level_id))

	# The event's own hours pass first, so a promise's deadline or a
	# follow-up's delay counts from when the event is over (2026-10-31).
	var pool_family: Variant = chosen.get("task_pool_family")
	if pool_family != null and not str(pool_family).is_empty():
		staff_add_pool_change(str(pool_family), int(chosen.get("task_pool_change", 0)),
			int(chosen.get("task_pool_days", 1)) if chosen.get("task_pool_days") != null else 1, str(event.get("title", "")))
	var hours := 0 if lapse else EventEngine.hours_of(event)
	if not delegate_role.is_empty():
		hours = StaffTasks.delegate_hours(hours)
		lines.append_array(_apply_delegation(delegate_id, delegate_blocks, fit))
	spend_hours(hours)
	lines.append_array(pay_commitments(commitments, str(event.get("title", "")), _first_pleased_org(chosen.get("rewards")),
		Promises.terms_of(chosen), str(chosen.get("location", "")) if chosen.get("location") != null else ""))
	hours += Commitments.hours(commitments)
	event_last_at[event_id] = time_units
	if str(event.get("trigger", "")) == "Dated" and not dated_events_done.has(event_id):
		dated_events_done.append(event_id)
	# A Decision! scene is remembered with the day it was answered and the choice made, so its follow-ups can count their Delay.
	var scene := decision_scene_of(event_id)
	if not scene.is_empty() and not decision_log.has(str(scene.get("scene_id", ""))):
		decision_log[str(scene.get("scene_id", ""))] = {"day": WeekCalendar.today_number(calendar, calendar_config()), "choice": letter}
		lines.append_array(_start_scene_activations(scene, letter))
	check_crisis_triggers()
	return {"ok": true, "result_text": str(chosen.get("result_text", "")), "lines": lines,
		"chips": chips, "revealed": revealed, "hours": hours,
		"starts_level": event_choice_level(chosen)}


## The staff role an event choice hands the job to (its Delegate Role cell), or "".
static func event_delegate_role(choice: Dictionary) -> String:
	var raw: Variant = choice.get("delegate_role")
	return "" if raw == null else str(raw).strip_edges()


## How many blocks of a person's day a delegated choice takes: its Delegate
## Blocks cell, else the event's own hours (at least one).
func event_delegate_blocks(event: Dictionary, choice: Dictionary) -> int:
	var raw: Variant = choice.get("delegate_blocks")
	return maxi(1, int(raw) if raw != null else EventEngine.hours_of(event))


## Blocks of a person's day not yet used by tasks or delegated work.
func staff_blocks_left(staff_id: String) -> int:
	return maxi(0, staff_day_hours(staff_id) - staff_blocks_used(staff_id))


## Everyone who could take a delegated choice, each { staff_id, name, role, fit,
## left, refusal } (refusal "" when they can). Opens today's staff day first.
func event_delegates(event: Dictionary, choice: Dictionary) -> Array[Dictionary]:
	staff_ensure_day()
	var needed := event_delegate_role(choice)
	var blocks := event_delegate_blocks(event, choice)
	var out: Array[Dictionary] = []
	for member: Dictionary in staff_members():
		var id := str(member["staff_id"])
		var left := staff_blocks_left(id)
		out.append({"staff_id": id, "name": str(DataDB.get_staff(id).get("name", id)), "role": str(member["role"]),
			"fit": StaffTasks.delegate_fit(needed, str(member["role"]), staff_loyalty_of(id)),
			"left": left, "blocks": blocks, "refusal": "" if left >= blocks else Text.say("event.delegate_person_no_time", {"name": str(DataDB.get_staff(id).get("name", id))})})
	return out


## Whether anyone on staff could take a delegated choice now: "" or the reason.
func event_delegate_refusal(event: Dictionary, choice: Dictionary) -> String:
	if staff_members().is_empty():
		return Text.say("event.refuse_no_staff")
	for candidate: Dictionary in event_delegates(event, choice):
		if str(candidate["refusal"]).is_empty():
			return ""
	return Text.say("event.delegate_no_time")


## A choice's reward list with its gains scaled by how the delegate did.
func _delegated_rewards(entries: Array, fit: String) -> Array:
	if fit == StaffTasks.STRONG:
		return entries
	var scaled: Array = []
	for raw: Variant in entries:
		if not (raw is Dictionary):
			scaled.append(raw)
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate()
		var delta: Variant = entry.get("delta")
		if delta is Dictionary and (delta as Dictionary).has("min"):
			var range_copy: Dictionary = (delta as Dictionary).duplicate()
			range_copy["min"] = StaffTasks.delegate_gain(int(range_copy["min"]), fit)
			range_copy["max"] = StaffTasks.delegate_gain(int(range_copy["max"]), fit)
			entry["delta"] = range_copy
		elif delta != null and not (delta is String):
			entry["delta"] = StaffTasks.delegate_gain(int(delta), fit)
		scaled.append(entry)
	return scaled


## "Strong fit", "Fair fit" or "Poor fit", in words.
func _fit_label(fit: String) -> String:
	match fit:
		StaffTasks.STRONG:
			return Text.say("assign.fit_strong")
		StaffTasks.POOR:
			return Text.say("assign.fit_poor")
	return Text.say("assign.fit_fair")


## Books a delegation: the person's blocks, a little Loyalty for the right (or
## wrong) hands, and the lines the result screen adds.
func _apply_delegation(staff_id: String, blocks: int, fit: String) -> Array[String]:
	staff_day_delegated[staff_id] = int(staff_day_delegated.get(staff_id, 0)) + blocks
	var change := 0
	match fit:
		StaffTasks.STRONG:
			change = Levers.whole("staff_delegate_loyalty")
		StaffTasks.POOR:
			change = -Levers.whole("staff_delegate_loyalty")
	if change != 0:
		var cap := Levers.whole("staff_tasks_week_loyalty_cap")
		staff_week_tasks[staff_id] = clampi(int(staff_week_tasks.get(staff_id, 0)) + change, -cap, cap)
	var lines: Array[String] = [Text.say("event.delegate_line", {"name": str(DataDB.get_staff(staff_id).get("name", staff_id)),
		"fit": _fit_label(fit)})]
	if fit == StaffTasks.FAIR:
		lines.append(Text.say("event.delegate_fair"))
	elif fit == StaffTasks.POOR:
		lines.append(Text.say("event.delegate_poor"))
	return lines


## The level an event choice starts (its Starts Level cell), or "" (2026-10-31).
static func event_choice_level(choice: Dictionary) -> String:
	var raw: Variant = choice.get("starts_level")
	return "" if raw == null else str(raw).strip_edges()


## True for a level only an event can start (Levels tab, Event Only = Yes):
## it never shows in the Office's list.
static func is_event_only(level: Dictionary) -> bool:
	return str(level.get("event_only", "")).strip_edges().to_lower() == "yes"


## How long a choice commits the player: the event's own hours, plus the
## whole level it starts, if any (2026-10-31).
func event_choice_hours(event: Dictionary, choice: Dictionary) -> int:
	var hours := EventEngine.hours_of(event) + Commitments.hours(Commitments.of(choice))
	var level_id := event_choice_level(choice)
	if not level_id.is_empty():
		hours += level_hours(DataDB.get_level(level_id))
	return hours


## The least and most an event can take, over its choices: [low, high].
func event_hours_range(event: Dictionary) -> Array[int]:
	var low := -1
	var high := 0
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, str(event.get("event_id", ""))):
		var hours := event_choice_hours(event, choice)
		low = hours if low < 0 else mini(low, hours)
		high = maxi(high, hours)
	if low < 0:
		low = EventEngine.hours_of(event)
		high = low
	return [low, high]


## "2" or "1–4", for an event's duration.
func event_hours_text(event: Dictionary) -> String:
	var span := event_hours_range(event)
	if span[0] == span[1]:
		return str(span[0])
	return Text.say("event.hours_range", {"low": span[0], "high": span[1]})


## Why a choice that starts a level cannot be taken now, or "": the event and
## its level must fit the hours left (Cameron, 2026-10-31: "Insufficient Work
## Hours"), and a weekend needs a level that allows the weekend.
func event_choice_refusal(event: Dictionary, choice: Dictionary) -> String:
	var level_id := event_choice_level(choice)
	if level_id.is_empty():
		return ""
	var level := DataDB.get_level(level_id)
	var cfg := calendar_config()
	if WeekCalendar.is_full(calendar, cfg) or event_choice_hours(event, choice) > WeekCalendar.hours_left(calendar, cfg) \
			or not level_calendar_refusal(level).is_empty():
		return Text.say("event.refuse_work_hours")
	return ""


## Whether a level is offered to this protagonist (the Levels tab's Protagonist column; blank means everyone): the eight
## levels of slice 6 belong to one protagonist each.
func level_is_for_player(level: Dictionary) -> bool:
	var who: Variant = level.get("protagonist")
	return not (who is Array) or (who as Array).is_empty() or (who as Array).has(protagonist_id)


## Whether a level an event can reveal is open to the player. Levels not
## marked "Needs Discovery" always are.
func is_level_discovered(level: Dictionary) -> bool:
	if str(level.get("needs_discovery", "")).strip_edges().to_lower() != "yes":
		return true
	return discovered_levels.has(str(level.get("level_id", "")))


# ---------------------------------------------------------------------------
# Hosted events (2026-10-23, Cameron): the walking tour and the dinner.

func get_hosted_event(hosted_id: String) -> Dictionary:
	for row: Dictionary in DataDB.hosted_events:
		if str(row.get("hosted_id", "")) == hosted_id:
			return row
	return {}


## Every character who could be a guest, by organization: opponents by their
## Affiliation, visitors by the organizations their reward pleases. Party
## bodies are left out. { org_id: [{ id, name, title, org }] }.
func hosted_people_by_org() -> Dictionary:
	var party_orgs := {}
	for booster: Dictionary in DataDB.boosters:
		if str(booster.get("tier", "")) == HostedEvent.PARTY_TIER:
			party_orgs[str(booster.get("booster_id", ""))] = true
	var found := {}
	for opponent: Dictionary in DataDB.opponents:
		var org := str(opponent.get("affiliation", "")) if opponent.get("affiliation") != null else ""
		if org.is_empty() or party_orgs.has(org):
			continue
		if not found.has(org):
			found[org] = []
		(found[org] as Array).append({"id": str(opponent.get("opp_id", "")),
			"name": str(opponent.get("name", "")), "title": OpponentDisplay.title_for(opponent), "org": org})
	for visitor: Dictionary in DataDB.visitors:
		var rewards: Variant = visitor.get("reward")
		if not (rewards is Array):
			continue
		var seen := {}
		for entry: Variant in (rewards as Array):
			var target := str((entry as Dictionary).get("target", ""))
			if not RewardTargets.is_booster(target) or party_orgs.has(target) or seen.has(target):
				continue
			seen[target] = true
			if not found.has(target):
				found[target] = []
			(found[target] as Array).append({"id": str(visitor.get("visitor_id", "")),
				"name": str(visitor.get("name_en", "")), "title": str(visitor.get("title", "")), "org": target})
	return found


## Starts the evening: picks the guests. `hours` is spent when it ends.
func begin_hosted_event(hosted_id: String, org_id: String, hours: int = 0) -> Dictionary:
	var cfg := HostedEvent.settings(DataDB.balance)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var allies := HostedEvent.allies(org_id, DataDB.party_stakeholders, DataDB.boosters)
	var roster := HostedEvent.pick_roster(org_id, hosted_people_by_org(), allies, int(cfg["roster"]), rng)
	hosted_session = {"hosted_id": hosted_id, "org": org_id, "roster": roster, "hours": hours,
		"results": {}, "tags": {}, "picked": {}}
	return hosted_session


## The options a screen offers: step 1 to 3, and a slot ("Entree") where the step has them.
func hosted_options(step: int, slot: String = "") -> Array:
	return HostedEvent.options_for_slot(DataDB.event_options, str(hosted_session.get("hosted_id", "")), step, slot)


## The guests' reactions to what was picked on a step (`option_ids`), kept for
## the evening's total. Returns [{ guest, reaction, level, line }].
func hosted_record_step(step: int, option_ids: Array) -> Array:
	var tag_lists: Array = []
	for row: Dictionary in DataDB.event_options:
		if str(row.get("hosted_id", "")) == str(hosted_session.get("hosted_id", "")) \
				and option_ids.has(str(row.get("option_id", ""))):
			tag_lists.append(row.get("tags", []) if row.get("tags") != null else [])
	var scored := HostedEvent.score_step(hosted_session.get("roster", []) as Array,
		DataDB.organization_tastes, tag_lists)
	(hosted_session["results"] as Dictionary)[step] = scored
	(hosted_session["tags"] as Dictionary)[step] = tag_lists
	if not hosted_session.has("picked"):
		hosted_session["picked"] = {}
	(hosted_session["picked"] as Dictionary)[step] = option_ids.duplicate()
	var shown: Array = []
	var pick := 0
	for entry: Dictionary in scored:
		var guest: Dictionary = entry["guest"]
		var level := HostedEvent.level_of(int(entry["reaction"]))
		shown.append({"guest": guest, "reaction": int(entry["reaction"]), "level": level,
			"line": HostedEvent.line_for(DataDB.reaction_lines, level, str(guest.get("name", "")), step + pick)})
		pick += 1
	return shown


## The evening ends: standing moves with the guests, awareness and Reputation
## with the total, the hours pass, and a hidden bill may come up (the patron's
## Host Org). Returns { net, deltas, awareness, meter, reputation, revealed, hours, lines }.
func finish_hosted_event() -> Dictionary:
	if hosted_session.is_empty():
		return {}
	var session := hosted_session
	hosted_session = {}
	var cfg := HostedEvent.settings(DataDB.balance)
	var results: Array = []
	for step: Variant in (session["results"] as Dictionary).keys():
		results.append((session["results"] as Dictionary)[step])
	var org := str(session["org"])
	var total := HostedEvent.totals(results, org, cfg)
	var cause := Text.say("record.cause_hosted")
	for guest_org: String in (total["org_deltas"] as Dictionary).keys():
		var change := int((total["org_deltas"] as Dictionary)[guest_org])
		if change != 0:
			_under_cause(cause, func() -> void: _apply_booster_delta(guest_org, change))
	var meter := str(get_hosted_event(str(session["hosted_id"])).get("meter", "District")).to_lower()
	apply_awareness_delta(meter, int(total["awareness"]))
	if int(total["reputation"]) != 0:
		_under_cause(cause, func() -> void: _apply_meta_reward("Reputation", int(total["reputation"])))
	var hours := int(session.get("hours", 0))
	spend_hours(hours)
	# What the picks cost or owe (Event Options' Commitment, 2026-10-31): step
	# 3's promise is owed to the guest organization the evening pleased most.
	var lines := pay_commitments(hosted_commitments(session),
		str(get_hosted_event(str(session["hosted_id"])).get("title", "")),
		HostedEvent.most_pleased(total["org_deltas"], org), hosted_promise_terms(session))
	var revealed := reveal_by_hosting(org)
	return {"net": int(total["net"]), "deltas": total["org_deltas"], "awareness": int(total["awareness"]),
		"meter": meter, "reputation": int(total["reputation"]), "revealed": revealed, "hours": hours,
		"lines": lines}


## The kept line of whichever picked option makes the evening's promise.
func hosted_promise_terms(session: Dictionary) -> Dictionary:
	var picked: Dictionary = session.get("picked", {})
	for step: Variant in picked.keys():
		for row: Dictionary in DataDB.event_options:
			if str(row.get("hosted_id", "")) == str(session.get("hosted_id", "")) \
					and (picked[step] as Array).has(str(row.get("option_id", ""))):
				var terms := Promises.terms_of(row)
				if terms.has("kept_text"):
					return terms
	return {}


## Every commitment the picked options of a hosted evening carry, in step order.
func hosted_commitments(session: Dictionary) -> Array:
	var picked: Dictionary = session.get("picked", {})
	var found: Array = []
	var steps := picked.keys()
	steps.sort()
	for step: Variant in steps:
		for row: Dictionary in DataDB.event_options:
			if str(row.get("hosted_id", "")) == str(session.get("hosted_id", "")) \
					and (picked[step] as Array).has(str(row.get("option_id", ""))):
				found.append_array(Commitments.of(row))
	return found


# ---------------------------------------------------------------------------
# The week calendar (2026-10-23, Cameron). WeekCalendar.gd holds the rules;
# these are the run's own entry points.

func calendar_config() -> Dictionary:
	return WeekCalendar.settings(DataDB.balance)


## The Office calendar's date row, in the equipped calendar style
## (CalendarStyles): plain "YY.MM.DD", Japanese era years, or the Ainu form.
func calendar_date_text() -> String:
	var style := calendar_style()
	if style == CalendarStyles.GREGORIAN:
		return WeekCalendar.date_text(calendar, calendar_config())
	var date := WeekCalendar.civil_from_days(WeekCalendar.today_number(calendar, calendar_config()))
	if style == CalendarStyles.AINU:
		return CalendarStyles.ainu_text(date, [
			Text.say("calendar.ainu_month_01"), Text.say("calendar.ainu_month_02"),
			Text.say("calendar.ainu_month_03"), Text.say("calendar.ainu_month_04"),
			Text.say("calendar.ainu_month_05"), Text.say("calendar.ainu_month_06"),
			Text.say("calendar.ainu_month_07"), Text.say("calendar.ainu_month_08"),
			Text.say("calendar.ainu_month_09"), Text.say("calendar.ainu_month_10"),
			Text.say("calendar.ainu_month_11"), Text.say("calendar.ainu_month_12")])
	var eras: Array = DataDB.rules.get("calendar_eras", {}).get("eras", [])
	var parts := CalendarStyles.era_parts(date, eras,
		str(DataDB.rules.get("calendar_eras", {}).get("first_year_word", "")))
	if parts.is_empty():
		return WeekCalendar.date_text(calendar, calendar_config())
	return Text.say("calendar.era_date", parts)


## Which calendar style is equipped: "" (plain), "era" or "ainu".
func calendar_style() -> String:
	var package_id := str(active_cosmetics.get(CosmeticPieces.CALENDAR, ""))
	if package_id.is_empty():
		return CalendarStyles.GREGORIAN
	return CosmeticPieces.field(DataDB.get_cosmetic_package(package_id), "calendar_style")


## The calendar square's third row: the day of the week in English and
## Japanese, from the Text tab ("Tuesday 火曜日").
func calendar_weekday_text() -> String:
	var style := calendar_style()
	if style == CalendarStyles.AINU:
		match WeekCalendar.weekday_index(calendar, calendar_config()):
			0: return Text.say("calendar.ainu_weekday_sun")
			1: return Text.say("calendar.ainu_weekday_mon")
			2: return Text.say("calendar.ainu_weekday_tue")
			3: return Text.say("calendar.ainu_weekday_wed")
			4: return Text.say("calendar.ainu_weekday_thu")
			5: return Text.say("calendar.ainu_weekday_fri")
			_: return Text.say("calendar.ainu_weekday_sat")
	if style == CalendarStyles.ERA:
		match WeekCalendar.weekday_index(calendar, calendar_config()):
			0: return Text.say("calendar.weekday_jp_sun")
			1: return Text.say("calendar.weekday_jp_mon")
			2: return Text.say("calendar.weekday_jp_tue")
			3: return Text.say("calendar.weekday_jp_wed")
			4: return Text.say("calendar.weekday_jp_thu")
			5: return Text.say("calendar.weekday_jp_fri")
			_: return Text.say("calendar.weekday_jp_sat")
	match WeekCalendar.weekday_index(calendar, calendar_config()):
		0: return Text.say("calendar.weekday_sun")
		1: return Text.say("calendar.weekday_mon")
		2: return Text.say("calendar.weekday_tue")
		3: return Text.say("calendar.weekday_wed")
		4: return Text.say("calendar.weekday_thu")
		5: return Text.say("calendar.weekday_fri")
		_: return Text.say("calendar.weekday_sat")


## The calendar square's second row: hours left today.
func calendar_hours_text() -> String:
	var weekend := str(calendar["phase"]) == WeekCalendar.WEEKEND
	return Text.say("calendar.hours_weekend" if weekend else "calendar.hours_work",
		{"hours": WeekCalendar.hours_left_today(calendar, calendar_config()), "count": WeekCalendar.hours_left_today(calendar, calendar_config())})


func in_weekend() -> bool:
	return str(calendar["phase"]) == WeekCalendar.WEEKEND


## The work week has run out of hours (finished, not ended early).
func work_week_is_full() -> bool:
	return not in_weekend() and WeekCalendar.is_full(calendar, calendar_config())


func work_hours_left() -> int:
	return WeekCalendar.hours_left(calendar, calendar_config())


func can_end_work_week_early() -> bool:
	return WeekCalendar.can_end_work_week_early(calendar, calendar_config())


## How many hours a level takes: the Stages tab's hours for each room, with a
## bill vote counting as the Floor Vote room (ST23).
func level_hours(level: Dictionary) -> int:
	var total := 0
	for slot_number in range(1, 11):
		var raw: Variant = level.get("stage_%d" % slot_number)
		if raw == null:
			continue
		var slot := str(raw)
		if slot.is_empty() or slot == "N/A":
			continue
		# A bill's vote counts as the Floor Vote room: a written bill ("BI..") or
		# a sponsored or drafted one (its runtime id).
		if BattleSetup._is_bill_id(slot):
			slot = str(DataDB.get_rule("bill_vote_stage", ""))
		total += TimeClock.units_for_stage(DataDB.get_stage(slot))
	return total


## The ordinary levels on offer at the office the player stands at, in the Levels tab's order (P16 moved the filters here from the
## Levels list so the rhetoric tips can read the same list): not special levels (listed above the rest, once due), not a One-Time level
## already completed, not an Act already voted on, not a level cooling down, not one an event has yet to reveal, not out of season,
## not Event Only, and only levels that start at this office and are for this protagonist.
func levels_on_offer() -> Array:
	var out: Array = []
	for level: Dictionary in DataDB.levels:
		if SpecialLevels.is_special(level):
			continue
		# A One-Time level already completed, win or loss, disappears outright.
		if Ledger.level_is_hidden(level, level_last_completed_at):
			continue
		# An Act the player voted Aye or Nay on never comes back (2026-11-13); one they were absent for or abstained on returns
		# once its replay timer is over, like any cooling-down level.
		if act_is_settled(level):
			continue
		# A level still cooling down is off the list until its cooldown is over (Cameron, 2026-11-06).
		if DataDB.get_rule("level_gating_enabled", false) and Ledger.level_cooldown_remaining(level, time_units, level_cleared_units) > 0:
			continue
		# A level only an event can reveal ("Needs Discovery") stays out of sight until then.
		if not is_level_discovered(level):
			continue
		# A seasonal level (its Seasons cell) only shows in its season (2026-10-30).
		if not in_season(level):
			continue
		# An Event Only level is started from an event choice, never the list.
		if is_event_only(level):
			continue
		# A level starts only at its own office (Either levels from both; two offices, 2026-11-20), and a protagonist's own levels
		# (slice 6) are listed only for them.
		if not level_at_this_office(level) or not level_is_for_player(level):
			continue
		out.append(level)
	return out


## Why this level cannot be started on the calendar right now, as a sentence;
## "" when it can.
func level_calendar_refusal(level: Dictionary, mode: String = Travel.PASS) -> String:
	var weekend_ok := str(level.get("weekend_ok", "")).strip_edges().to_lower() == "yes"
	match WeekCalendar.level_refusal(calendar, calendar_config(), level_total_hours(level, mode), weekend_ok):
		WeekCalendar.REFUSE_WEEK_OVER:
			return Text.say("calendar.refuse_week_over")
		WeekCalendar.REFUSE_NOT_WEEKEND:
			return Text.say("calendar.refuse_not_weekend")
		WeekCalendar.REFUSE_TOO_LONG:
			return Text.say("calendar.refuse_too_long")
	return decision_clash_refusal(level_total_hours(level, mode))


## A level that would still be running when a Mandatory Decision! opens is refused (P15, 2026-11-23, Cameron): the sentence saying
## which day it would run into; "" when it clears them all.
func decision_clash_refusal(level_hours: int) -> String:
	var cfg := calendar_config()
	var clash := DecisionClash.mandatory_clash(DataDB.decision_scenes, decision_log, calendar, cfg, level_hours)
	if clash.is_empty():
		return ""
	return Text.say("calendar.refuse_decision", {"day": EventsModel.weekday_name(int(clash["day"]))})


## An unanswered Optional Decision! whose window a level of this length would outlast, as {"title", "closes"}; {} when it fits
## them all. The Office asks the player before starting the level (they may still choose to).
func optional_decision_clash(level_hours: int) -> Dictionary:
	var clash := DecisionClash.optional_clash(DataDB.decision_scenes, decision_log, calendar, calendar_config(), level_hours)
	if clash.is_empty():
		return {}
	var event := get_event(str((clash["scene"] as Dictionary).get("event_id", "")))
	return {"title": str(event.get("title", "")), "closes": WeekCalendar.date_label(int(clash["closes"]))}


## Why a sponsored or drafted bill's level cannot start now: the work week is
## over, or the level would not end within it. "" when it can. (The weekend is
## not checked here; those levels have never asked for a weekend flag.)
func work_week_level_refusal(level: Dictionary) -> String:
	var cfg := calendar_config()
	if in_weekend():
		return ""
	if WeekCalendar.is_full(calendar, cfg):
		return Text.say("calendar.refuse_week_over")
	if level_total_hours(level) > WeekCalendar.hours_left(calendar, cfg):
		return Text.say("calendar.refuse_too_long")
	return ""


## Time passing with no stage played (hours skipped at a week's end).
func _advance_clock(hours: int) -> void:
	time_units += maxi(0, hours)
	_expire_modifiers()
	_break_overdue_promises()
	check_crisis_triggers()


## The three crisis triggers (Funding Freeze, Town Hall, Steering Committee),
## checked whenever the values they watch can have moved: after a stage, and
## (Cameron, 2026-10-31) straight after Office time, an event, a kept promise
## or the week's end, so a line crossed outside a stage starts its freeze or
## countdown at once. Each check only acts on an edge, so repeats are harmless.
func check_crisis_triggers() -> void:
	_check_funding_freeze()
	_check_town_hall()
	_check_steering_committee()


## Promises that fell due unkept are broken: the organization they were made
## to loses standing and Reputation drops (Balance levers), and the Office says
## so next time it opens.
func _break_overdue_promises() -> void:
	# Paused while a level is played: the Office, where promises are kept,
	# cannot be reached until it ends (Cameron, 2026-11-04).
	if level_clock_started >= 0:
		return
	for promise: Dictionary in Promises.overdue(promises, time_units):
		promises.erase(promise)
		_drop_followups_of(promise)
		var org := str(promise.get("for_org", ""))
		var cause := Text.say("record.cause_promise_broken")
		if Promises.has_own(promise, "broken"):
			_apply_promise_effects(promise["broken"], cause)
			promises_broken_unseen.append(promise)
			continue
		if not org.is_empty():
			var drop := Levers.whole("promise_broken_standing")
			_under_cause(cause, func() -> void: _apply_booster_delta(org, drop))
		var rep := Levers.whole("promise_broken_reputation")
		if rep != 0:
			_under_cause(cause, func() -> void: _apply_meta_reward("Reputation", rep))
		promises_broken_unseen.append(promise)


## The level is over: promise deadlines move on by the hours it took, then any
## that are still overdue break.
func _resume_promise_deadlines() -> void:
	if level_clock_started < 0:
		return
	Promises.resume_after_level(promises, level_clock_started, time_units)
	level_clock_started = -1
	_break_overdue_promises()


## A promise's own kept or broken effects (Event Choices' Promise Kept /
## Promise Broken): organizations, Sanban values and the awareness meters.
func _apply_promise_effects(effects: Array, cause: String) -> void:
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var target := str(entry.get("target", ""))
		var delta := int(entry.get("delta", 0))
		if delta == 0:
			continue
		if target.begins_with("BO"):
			_under_cause(cause, func() -> void: _apply_booster_delta(target, delta))
		elif target == "District" or target == "National":
			apply_awareness_delta(target.to_lower(), delta)
		else:
			_under_cause(cause, func() -> void: _apply_meta_reward(target, delta))


## Who a promise was made to, in words: the organization, else where it came from.
func promise_who(promise: Dictionary) -> String:
	var org := str(promise.get("for_org", ""))
	if not org.is_empty():
		return str(DataDB.get_booster(org).get("name_en", org))
	return str(promise.get("source", ""))


## What a promise owes, in words.
func promise_what(promise: Dictionary) -> String:
	if str(promise.get("kind", "")) == Promises.PROMISE_ITEM:
		var item_id := str(promise.get("item_id", ""))
		return Text.say("promise.what_item", {"item": str(DataDB.get_shop_item(item_id).get("name", item_id))})
	if str(promise.get("kind", "")) == Promises.PROMISE_FUNDS:
		return Text.say("promise.what_funds", {"yen_amount": int(promise.get("funds", 0))})
	return Text.say("promise.what_hours", {"count": int(promise.get("hours", 0))})


## Why a promise cannot be kept now, in words, or "".
func promise_keep_refusal(promise: Dictionary) -> String:
	var cfg := calendar_config()
	var hours := 0 if WeekCalendar.is_full(calendar, cfg) else WeekCalendar.hours_left(calendar, cfg)
	match Promises.keep_refusal(promise, inventory, hours, int(meta.get("Funds", 0)), office_location):
		"office":
			return Text.say("promises.refuse_elsewhere", {"place": TravelText.place_name(Offices.normalize(promise.get("location")))})
		"item":
			var item_id := str(promise.get("item_id", ""))
			return Text.say("commit.refuse_item", {"item": str(DataDB.get_shop_item(item_id).get("name", item_id))})
		"hours":
			return Text.say("event.refuse_work_hours")
		"funds":
			return Text.say("event.refuse_funds")
	return ""


## Keeps a promise: the item is handed over or the hours spent, and the
## organization it was made to gains standing. "" when kept, else the refusal.
func keep_promise(promise_id: String) -> String:
	for promise: Dictionary in promises:
		if str(promise.get("id", "")) != promise_id:
			continue
		var why := promise_keep_refusal(promise)
		if not why.is_empty():
			return why
		promises.erase(promise)
		if str(promise.get("kind", "")) == Promises.PROMISE_ITEM:
			_take_item(str(promise.get("item_id", "")))
		var org := str(promise.get("for_org", ""))
		if Promises.has_own(promise, "kept"):
			_apply_promise_effects(promise["kept"], Text.say("record.cause_promise_kept"))
		elif not org.is_empty():
			var gain := Levers.whole("promise_kept_standing")
			_under_cause(Text.say("record.cause_promise_kept"), func() -> void: _apply_booster_delta(org, gain))
		if str(promise.get("kind", "")) == Promises.PROMISE_HOURS:
			spend_hours(int(promise.get("hours", 0)))
		if str(promise.get("kind", "")) == Promises.PROMISE_FUNDS:
			var owed := int(promise.get("funds", 0))
			_under_cause(Text.say("record.cause_commitment"), func() -> void: _apply_meta_reward("Funds", -owed))
		check_crisis_triggers()
		return ""
	return ""


## The first scheduled follow-up event that is due now, removed from the
## queue, or "" (the Office shows it).
func take_due_followup() -> String:
	for entry: Dictionary in scheduled_events:
		# A follow-up tied to a promise waits while that promise is still open.
		if _group_promise_open(str(entry.get("group", ""))):
			continue
		if time_units >= int(entry.get("due_at", 0)) and not get_event(str(entry.get("event_id", ""))).is_empty():
			# A follow-up arrives at its own office (two offices, 2026-11-20); away from it, it waits.
			if not Offices.is_here(get_event(str(entry.get("event_id", ""))).get("location"), office_location):
				continue
			scheduled_events.erase(entry)
			return str(entry.get("event_id", ""))
	return ""


## True while a promise made with follow-up group `group` is still open.
func _group_promise_open(group: String) -> bool:
	if group.is_empty():
		return false
	for promise: Dictionary in promises:
		if str(promise.get("group", "")) == group:
			return true
	return false


## Drops the follow-ups queued with a promise that has just broken.
func _drop_followups_of(promise: Dictionary) -> void:
	var group := str(promise.get("group", ""))
	if group.is_empty():
		return
	for entry: Dictionary in scheduled_events.duplicate():
		if str(entry.get("group", "")) == group:
			scheduled_events.erase(entry)


## True when some promise owes this item (the Marketplace marks it).
func item_is_promised(item_id: String) -> bool:
	for promise: Dictionary in promises:
		if str(promise.get("item_id", "")) == item_id:
			return true
	return false


## The work week is over, finished or ended early on Friday: the weekend starts.
## Unused work hours still count as time passing (cooldowns keep running).
func end_work_week() -> void:
	if in_weekend():
		return
	var moved := WeekCalendar.end_work_week(calendar, calendar_config())
	calendar = moved["state"]
	_advance_clock(int(moved["skipped"]))


## "Pay Party Dues and Go Home": the weekend (played or not) ends and a new
## week begins on Monday. Standing and meta decay run here, once a week.
## Returns what the popup needs: { date }.
func go_home() -> Dictionary:
	if not in_weekend():
		end_work_week()
	var dues := _settle_dues()
	staff_day_sync(true)   # the day being left counts if it was confirmed
	var staff_report := _settle_staff_week()
	var awareness_lines := _apply_awareness_week_end()
	_update_election_strength()
	var moved := WeekCalendar.go_home(calendar, calendar_config())
	calendar = moved["state"]
	_advance_clock(int(moved["skipped"]))
	_apply_week_decay()
	check_crisis_triggers()
	event_roll_due = true
	return {"date": calendar_date_text(), "dues": dues, "awareness": awareness_lines, "staff": staff_report}


## What the awareness effects take off the base dues (National Awareness at 80
## or more). Filled in with the Awareness Effects tab; nothing yet.
func _dues_reduction() -> int:
	return AwarenessEffects.dues_reduction(DataDB.awareness_effects, awareness)


## Starting support a room gets from awareness (State rows), for BattleSetup.
func awareness_start_bonus(stage_id: String) -> int:
	return AwarenessEffects.stage_start_bonus(DataDB.awareness_effects, awareness, stage_id)


## At each week end, once the dues are settled: standing, XP and coupons the
## awareness meters earn or cost. Returns lines for the popup (Text rows).
func _apply_awareness_week_end() -> Array[String]:
	var lines: Array[String] = []
	var result := AwarenessEffects.week_end(DataDB.awareness_effects, awareness, awareness_streaks)
	awareness_streaks = result["streaks"]
	for entry: Dictionary in result["applied"]:
		var effect: Dictionary = entry["effect"]
		var amount := int(entry["amount"])
		match str(effect.get("effect_type", "")):
			AwarenessEffects.STANDING_CHANGE:
				var names: Array[String] = []
				for id: String in _awareness_standing_targets(effect):
					_under_cause(Text.say("record.cause_awareness"),
						func() -> void: _apply_booster_delta(id, amount))
					names.append(str(DataDB.get_booster(id).get("name_en", id)))
				if not names.is_empty():
					lines.append(Text.say("awareness.week_standing",
						{"names": ", ".join(PackedStringArray(names)), "count": amount}))
			AwarenessEffects.XP_CHANGE:
				_move_xp(amount)
				lines.append(Text.say("awareness.week_xp", {"count": amount}))
			AwarenessEffects.FREE_TRAINING_COUPON:
				if _give_training_coupons(amount):
					lines.append(Text.say("awareness.week_coupon"))
	return lines


## The organization ids a STANDING_CHANGE row hits: named ids, or every
## organization of a tier ("TIER:National").
func _awareness_standing_targets(effect: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for target: String in AwarenessEffects.targets_of(effect):
		if target.begins_with("TIER:"):
			for booster: Dictionary in DataDB.boosters:
				if str(booster.get("tier", "")) == target.substr(5):
					found.append(str(booster.get("booster_id", "")))
		else:
			found.append(target)
	return found


## Adds Training Session Coupons (Rules: training_coupon_item) up to the item's own stack cap.
func _give_training_coupons(count: int) -> bool:
	var coupon := str(DataDB.get_rule("training_coupon_item", ""))
	var item := DataDB.get_shop_item(coupon)
	if item.is_empty() or count <= 0:
		return false
	var cap := int(item.get("stack_cap", 5)) if item.get("stack_cap") != null else 5
	var before := int(inventory.get(coupon, 0))
	inventory[coupon] = mini(cap, before + count)
	return int(inventory[coupon]) > before


## What the party is owed at this week's end: { week_dues, owed (carried),
## total, funds }. Shown above the week button.
func dues_preview() -> Dictionary:
	var cfg := PartyDues.settings(DataDB.balance)
	var week_dues := PartyDues.week_dues(cfg, int(meta.get("Party support", 0)),
		week_funds_earned, _dues_reduction())
	# The first weeks of a run owe nothing (Balance "Dues Holiday Weeks"; Campaign Pressure sets it).
	if Difficulty.dues_holiday(int(calendar.get("week", 0)), Levers.whole("dues_holiday_weeks")):
		week_dues = 0
	return {"week_dues": week_dues, "owed": dues_balance, "total": week_dues + dues_balance,
		"funds": int(meta.get("Funds", 0))}


## What going home will cost and pay (panel P4, 2026-11-17), worked out with the very
## functions that settle the week (PartyDues.settle and overdue_penalties and party_backings,
## StaffLoyalty.pay_order and settle_wages), in the order go_home() uses them: dues first, then
## the confirmed staff day's Funds, then wages. Returns:
##   dues:   { base, share, earned, relief, week_dues, carried, total, paid, owed }
##   staff:  { wages, count, wages_paid, wages_missed, funds_before_wages }
##   funds:  { now, after }  (after dues, the confirmed staff day and wages)
##   short:  the Funds the dues fall short by (0 when they can be paid)
##   penalties: PartyDues.overdue_penalties for what stays owed ({} when nothing is owed)
##   withdrawn: names of the party's backings that would be withdrawn
func week_end_preview() -> Dictionary:
	var cfg := PartyDues.settings(DataDB.balance)
	var due := dues_preview()
	var support := int(meta.get("Party support", 0))
	var reduction := _dues_reduction()
	var holiday := Difficulty.dues_holiday(int(calendar.get("week", 0)), Levers.whole("dues_holiday_weeks"))
	var base_full := PartyDues.base_dues(cfg, support, 0)
	var base_after := PartyDues.base_dues(cfg, support, reduction)
	var share := PartyDues.week_dues(cfg, support, week_funds_earned, reduction) - base_after
	var settled := PartyDues.settle(int(due["total"]), int(due["funds"]))
	var penalties := PartyDues.overdue_penalties(cfg, int(settled["owed"]))
	var withdrawn: Array[String] = []
	if int(settled["owed"]) > 0:
		for mod_id: String in PartyDues.party_backings(owned_modifiers, DataDB.modifiers, DataDB.boosters):
			withdrawn.append(str(DataDB.get_modifier(mod_id).get("name_en", mod_id)))
	# The confirmed staff day settles before wages and may move Funds.
	var staff_funds := 0
	if staff_day_confirmed and not staff_day_pool.is_empty() and not staff_members().is_empty():
		staff_funds = int((staff_projection()["meta"] as Dictionary).get("Funds", 0))
	var entries: Array = []
	for member: Dictionary in staff_members():
		var id := str(member["staff_id"])
		entries.append({"staff_id": id, "name": str(DataDB.get_staff(id).get("name", id)), "primary": member["primary"],
			"loyalty": staff_loyalty_of(id), "wage": staff_wage_of(id), "raised": bool(staff_raise_pay.get(id, false))})
	# The same functions the week end uses, in the same order (WeekPayments).
	var payments := WeekPayments.build(int(due["total"]), dues_balance, int(due["funds"]), staff_funds, entries)
	var wage_result := {"spent": int(payments["wages_paid"]), "missed": payments["unpaid"]}
	var wages_total := int(payments["wages_total"])
	var funds_before_wages := int(due["funds"]) - int(settled["paid"]) + staff_funds
	return {
		"dues": {"base": 0 if holiday else base_after, "share": 0 if holiday else share, "earned": week_funds_earned,
			"relief": 0 if holiday else base_full - base_after,
			"week_dues": int(due["week_dues"]), "carried": dues_balance, "total": int(due["total"]),
			"paid": int(settled["paid"]), "owed": int(settled["owed"]), "holiday": holiday},
		"staff": {"wages": wages_total, "count": entries.size(), "wages_paid": int(wage_result["spent"]),
			"wages_missed": (wage_result["missed"] as Array).size(), "funds_before_wages": funds_before_wages},
		"funds": {"now": int(due["funds"]), "after": funds_before_wages - int(wage_result["spent"])},
		"short": int(settled["owed"]), "penalties": penalties, "withdrawn": withdrawn,
		"payments": payments,
	}


## Pays the party at the week's end with whatever Funds there are. Anything
## unpaid rolls over; an unpaid week costs Party support, withdraws the
## party's backings, and applies the scaled overdue penalties.
## Returns { week_dues, carried, total, paid, owed, penalized, withdrawn }.
func _settle_dues() -> Dictionary:
	var cfg := PartyDues.settings(DataDB.balance)
	var preview := dues_preview()
	var settled := PartyDues.settle(int(preview["total"]), int(preview["funds"]))
	var report := {"week_dues": int(preview["week_dues"]), "carried": dues_balance,
		"total": int(preview["total"]), "paid": int(settled["paid"]),
		"owed": int(settled["owed"]), "penalized": false, "withdrawn": []}
	var cause := Text.say("record.cause_dues")
	if int(settled["paid"]) > 0:
		# Paying the party is not "spending Funds" to the Standing Links.
		_links_suspended = true
		_under_cause(cause, func() -> void: _apply_meta_reward("Funds", -int(settled["paid"])))
		_links_suspended = false
	dues_balance = int(settled["owed"])
	week_funds_earned = 0
	if dues_balance <= 0:
		return report

	var penalties := PartyDues.overdue_penalties(cfg, dues_balance)
	report["penalized"] = true
	report["penalties"] = penalties
	_under_cause(cause, func() -> void:
		_apply_meta_reward("Party support", -int(penalties["party_support"]))
		_apply_booster_delta(str(DataDB.get_rule("party_dues_hq_organization", "")), -int(penalties["hq"]))
		_apply_booster_delta(str(DataDB.get_rule("party_dues_selection_organization", "")), -int(penalties["selection"])))
	var own_party := str(DataDB.player.get("party", ""))
	for party: Dictionary in DataDB.parties:
		var party_name := str(party.get("name", ""))
		if not party_name.is_empty() and party_name != own_party:
			_apply_party_delta(party_name, int(penalties["other_parties"]))
	var withdrawn: Array = []
	for mod_id: String in PartyDues.party_backings(owned_modifiers, DataDB.modifiers, DataDB.boosters):
		owned_modifiers.erase(mod_id)
		modifier_expires.erase(mod_id)
		withdrawn.append(str(DataDB.get_modifier(mod_id).get("name_en", mod_id)))
	report["withdrawn"] = withdrawn
	return report


## Decay at a week's end, in bigger steps (Week Decay Multiplier) because a
## week is about two and a half levels. Replaces the per-hour decay interval
## (Balance "Decay Interval", now 0).
func _apply_week_decay() -> void:
	_decay_scale = maxf(0.0, Levers.num("week_decay_multiplier"))
	_decaying = true
	_apply_neglect_decay()
	_apply_standing_decay()
	_apply_meta_decay()
	_decaying = false
	_decay_scale = 1.0
	booster_moved_in_period = {}



## Neglect (2026-10-16, Cameron): at the end of a level, every organisation
## whose standing did not move at all this level (last_booster_change, which
## covers answers, visitors, items and laws alike) drifts `neglect_decay`
## points toward its own starting standing. Standing has to be maintained.
func _apply_neglect_decay() -> void:
	var step := int(DataDB.booster_standing.get("neglect_decay", 0))
	if step <= 0:
		return
	step = maxi(1, roundi(step * _decay_scale))
	var default_start := int(DataDB.booster_standing.get("start", 30))
	var touched := booster_moved_in_period.keys()
	var starts := {}
	for booster: Dictionary in DataDB.boosters:
		var own_start: Variant = booster.get("starting_standing")
		starts[str(booster.get("booster_id"))] = default_start if own_start == null else int(own_start)
	for booster_id: String in booster_standing.keys():
		if touched.has(booster_id):
			continue
		var now := int(booster_standing[booster_id])
		var target := BoosterStanding.decayed(now, int(starts.get(booster_id, default_start)), step)
		if target != now:
			_links_suspended = true
			_under_cause(Text.say("record.cause_neglect"),
				func() -> void: _apply_booster_delta(booster_id, target - now))
			_links_suspended = false


## Meta values that carry a Decay Percent on the Sanban tab (Reputation and
## Constituency support today) settle back toward the protagonist's starting
## value by that percent of the distance (at least 1 point) at the end of
## every level (2026-10-18, balance audit: they sat at 100 from level 40).
func _apply_meta_decay() -> void:
	var starts := BattleSetup.starting_meta_for(DataDB.player)
	for variable: Dictionary in DataDB.sanban:
		var percent: Variant = variable.get("decay_percent")
		if percent == null:
			continue
		var name := str(variable.get("name_en", ""))
		var now := int(meta.get(name, 0))
		var target := BoosterStanding.decayed_percent(now, int(starts.get(name, now)), float(percent) * _decay_scale)
		if target != now:
			_links_suspended = true
			_cause = Text.say("record.cause_decay")
			_apply_meta_reward(name, target - now)
			_cause = ""
			_links_suspended = false


## Every organization settles back toward its starting standing by its own
## Decay Percent of the distance (the Boosters tab; blank falls back to
## booster_standing.json's decay_percent). Triggers no Standing Links.
func _apply_standing_decay() -> void:
	var default_percent := float(DataDB.booster_standing.get("decay_percent", 0))
	var default_start := int(DataDB.booster_standing.get("start", 30))
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		if not booster_standing.has(id):
			continue
		var own_start: Variant = booster.get("starting_standing")
		var own_percent: Variant = booster.get("decay_percent")
		var now := int(booster_standing[id])
		var target := BoosterStanding.decayed_percent(now,
			default_start if own_start == null else int(own_start),
			(default_percent if own_percent == null else float(own_percent)) * _decay_scale)
		if target != now:
			_links_suspended = true
			_under_cause(Text.say("record.cause_decay"),
				func() -> void: _apply_booster_delta(id, target - now))
			_links_suspended = false


## The five parties the player isn't in, back to where party_standing.json
## starts them. The player's own party is never in here — see
## party_favorability()'s own comment.
func reset_party_standing() -> void:
	party_standing = {}
	last_party_change = {}

	var start := int(DataDB.party_standing.get("start", 50))
	var own_party := str(DataDB.player.get("party", ""))
	for party: Dictionary in DataDB.parties:
		var name := str(party.get("name", ""))
		if not name.is_empty() and name != own_party:
			party_standing[name] = start


## Every segment back to its own "Initial Favorability %" from the workbook.
## Unlike booster_standing, there's no hand-written config file for this —
## the workbook already gives each segment its own starting number, so there
## is nothing left for a config file to add. 50 is the fallback only for a
## segment row that somehow has no value at all.
func reset_segment_favorability() -> void:
	segment_favorability = {}
	last_segment_change = {}

	for segment: Dictionary in DataDB.segments:
		var segment_id := str(segment.get("segment_id"))
		var start: Variant = segment.get("initial_favorability_pct")
		segment_favorability[segment_id] = int(start) if start != null else 50


## Draws the hidden share for the next Floor Vote (see vote_unknown_percent).
func lock_vote_unknown_percent() -> void:
	var low := Levers.whole("vote_projection_unknown_minimum_percent")
	var high := Levers.whole("vote_projection_unknown_maximum_percent")
	var span := VoteProjection.narrowed_range(mini(low, high), maxi(low, high), research_passive_points())
	vote_unknown_percent = randi_range(span[0], span[1])
	vote_briefed = false


## The tier of the primary Policy Research Assistant; -1 when none is hired.
## (Extra staff do not count: the primary is the one every scene reads.)
func research_tier() -> int:
	var primary: Dictionary = staff_hired.get("Policy Research Assistant", {})
	return int(primary.get("tier", 0)) if not primary.is_empty() else -1


## Points the assistant takes off the Unknown range by simply being on staff.
func research_passive_points() -> int:
	return VoteProjection.by_tier([
		Levers.whole("research_assistant_passive_points_tier_0"),
		Levers.whole("research_assistant_passive_points_tier_1"),
		Levers.whole("research_assistant_passive_points_tier_2")], research_tier())


## Percent of the house a Research Briefing clears at the assistant's tier.
func research_briefing_points() -> int:
	return VoteProjection.by_tier([
		Levers.whole("research_assistant_briefing_clears_tier_0"),
		Levers.whole("research_assistant_briefing_clears_tier_1"),
		Levers.whole("research_assistant_briefing_clears_tier_2")], research_tier())


## Why a Research Briefing cannot be bought now, as a sentence; "" when it can.
func research_briefing_refusal() -> String:
	if research_tier() < 0:
		return Text.say("floor_vote.research_no_assistant")
	if vote_briefed:
		return Text.say("floor_vote.research_done")
	if vote_unknown_percent <= 0:
		return Text.say("floor_vote.research_nothing_left")
	var hours_refusal := _hours_refusal(Levers.whole("research_assistant_briefing_hours"))
	if not hours_refusal.is_empty():
		return hours_refusal
	var cost := Levers.whole("research_assistant_briefing_xp")
	if xp < cost:
		return Text.say("floor_vote.research_no_xp", {"xp": cost})
	return ""


## Buys the briefing: hours and XP are paid, and the Unknown share shrinks by
## the tier's points. Returns false (and charges nothing) when refused.
func buy_research_briefing() -> bool:
	if not research_briefing_refusal().is_empty():
		return false
	spend_hours(Levers.whole("research_assistant_briefing_hours"))
	_move_xp(-Levers.whole("research_assistant_briefing_xp"))
	vote_unknown_percent = maxi(vote_unknown_percent - research_briefing_points(), 0)
	vote_briefed = true
	return true


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	lock_vote_unknown_percent()
	_resume_promise_deadlines()
	level_clock_started = time_units
	level_runner = runner
	transition_memory = {}
	opponent_lines_said = {}
	bill_stance = {}
	bill_assist = BillAssist.empty()
	mid_stage = false
	stage_checkpoint = {}
	last_level_outcome = ""
	last_meta_change = {}
	last_meta_cause = {}
	last_xp_gained = 0
	last_booster_change = {}
	last_booster_cause = {}

	# A level buff used in the Office now runs for every stage of this level.
	level_bonuses = pending_level_bonuses.duplicate()
	pending_level_bonuses = {}

	for stage: Variant in runner.stages:
		record_faced(stage)
	# A save at the start of the level (2026-11-16, Cameron: save at stage
	# start). Until now the save before the first stage depended on a button
	# press being written after the scene had changed, which is not guaranteed.
	SaveManager.autosave()


## Notes that the player has met this opponent or visitor (Characters list).
## Safe to call again and again; blank ids are ignored.
func meet_character(id: String) -> void:
	if not id.is_empty():
		met_characters[id] = true


## Counts everyone seated in `stage` (opponents and visitors) as met once
## more, so PeopleDraw leans away from them next time.
func record_faced(stage: Variant) -> void:
	if not (stage is Dictionary):
		return
	for person: Variant in ((stage as Dictionary).get("opponents", []) as Array):
		var id := str((person as Dictionary).get("opp_id", ""))
		if not id.is_empty():
			faced_people[id] = int(faced_people.get(id, 0)) + 1
	for person: Variant in ((stage as Dictionary).get("visitors", []) as Array):
		var id := str((person as Dictionary).get("visitor_id", ""))
		if not id.is_empty():
			faced_people[id] = int(faced_people.get(id, 0)) + 1


## Seats `opponents` in the level's current stage in place of those drawn when
## the level began (a transition locked its speakers into the stage that
## follows, StageTransition.lock_opponents()), and moves the met-people counts
## with them so PeopleDraw keeps leaning the right way (2026-11-02).
func reseat_current_stage(opponents: Array) -> void:
	if level_runner == null:
		return
	var stage := level_runner.current_stage()
	if stage.is_empty():
		return
	for person: Variant in (stage.get("opponents", []) as Array):
		var id := str((person as Dictionary).get("opp_id", ""))
		if not id.is_empty():
			faced_people[id] = maxi(int(faced_people.get(id, 0)) - 1, 0)
	stage["opponents"] = opponents
	for person: Variant in opponents:
		var id := str((person as Dictionary).get("opp_id", ""))
		if not id.is_empty():
			faced_people[id] = int(faced_people.get(id, 0)) + 1


## True while a level is in progress.
func is_in_level() -> bool:
	return level_runner != null and not level_runner.is_finished()


## Records how a stage went and moves the level on. Returns true when the
## level is now over, which is the battle screen's cue to head back.
##
## `gaffe_caused_loss` (BattleScreen: `state.gaffe >= state.gaffe_limit`,
## false from VisitorScreen, which has no gaffe meter at all — see
## test_game_state_meta_tracking.gd) and `gaffes` (the stage's own final
## BattleState.gaffe) feed the lifetime tracking below; neither changes
## what a stage is WORTH, only what gets counted about it.
##
## `gaffe_caused_loss` is a plain boolean rather than BattleState.
## outcome_reason's own text on purpose: that text is already translated
## by the time BattleScreen sees it (Phrase.say()), so comparing it against
## a key string never matches in a real build — only in a hand-built test
## fixture with an empty wording table, which is exactly the bug a first
## version of this parameter had (caught in review, 2026-09-25, before it
## shipped anywhere real).
##
## `displeased_boosters` (2026-09-28, Cameron) is kept separate from
## `boosters` on purpose: `boosters` (the pleased list) also carries a buff
## into a later stage of the level (LevelRunner.carried_buffs()) — a weak
## answer must never grant that, so it is never mixed into that list, only
## used for the standing penalty below.
##
## `crushed_boosters` (2026-09-29, Cameron) is the organisations behind any
## opponent argued all the way down to zero support (BattleEngine.
## crushed_opponent_boosters()) — a separate, flat penalty from the
## please/displease netting above, since it is never about a question's
## own grade.
func finish_stage(outcome: String, score: int = 0, boosters: Array = [],
		gaffe_caused_loss: bool = false, gaffes: int = 0,
		displeased_boosters: Array = [], crushed_boosters: Array = [],
		opposed_boosters: Array = [], booster_tally: Dictionary = {}) -> bool:
	lock_vote_unknown_percent()
	mid_stage = false
	stage_checkpoint = {}
	pending_stage_result = {}
	if level_runner == null:
		return true

	var stage := level_runner.current_stage()
	var stage_hours := TimeClock.units_for_stage(stage)
	calendar = WeekCalendar.advance(calendar, stage_hours, calendar_config())
	# The same clock step Office time takes, so backings lapse AND promises
	# that fell due during the stage are broken now, not at the next event
	# or week end (mechanics audit, 2026-10-31).
	_advance_clock(stage_hours)
	_record_stage_type_result(str(stage.get("stage_id", "")), outcome)
	_record_lifetime_gaffes(gaffes, outcome, gaffe_caused_loss)
	last_awareness_change = {}
	if str(stage.get("mode", "")) == "Combat":
		apply_awareness_gaffes(gaffes)

	# What the stage just played did to the player's standing, before the
	# runner moves on and current_stage() becomes the next one.
	if outcome == LevelRunner.WON and str(stage.get("stage_id", "")) == MpVisit.FIGHT_STAGE:
		_won_over_member()
	_apply_stage_rewards(stage, outcome, score)
	last_whip_lock = _record_whip_result(level_runner.level, outcome)
	if outcome == LevelRunner.WON:
		apply_awareness_delta("district", MetaRules.stage_delta(stage, "win_delta_awareness_district"))
		apply_awareness_delta("national", MetaRules.stage_delta(stage, "win_delta_awareness_national"))
	_apply_question_boosters(boosters, displeased_boosters, opposed_boosters, booster_tally)
	_apply_instant_win_penalties(crushed_boosters)
	if outcome == LevelRunner.WON and str(stage.get("mode", "")) == "Combat":
		_apply_stance_win_drift()

	level_runner.finish_stage(outcome, score, boosters)

	# Funding freeze has nothing to insert into the queue, so both its edges
	# are always checked — a level ending on this very stage doesn't stop
	# the player finding out their money is frozen (or freed) once they're
	# back in the Office. Town Hall/Steering Committee insert a stage, so
	# their own checks internally skip entering a zone when there is
	# nowhere left to put one (level_runner.is_finished()) — leaving a zone
	# never needs anywhere to put anything, so that half always fires.
	_apply_time_decays()
	arm_patron_requests()
	_check_funding_freeze()
	var level_id := str(level_runner.level.get("level_id", ""))
	_check_town_hall()
	_check_steering_committee()

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()
		event_roll_due = true

		# Cooldown counts every completion, win or loss (see the comment on
		# levels_completed_count) — recorded here regardless of which way
		# last_level_outcome comes out, right where the level as a whole (not
		# just the stage just played) is known to be over.
		var patron_level := DataDB.is_runtime_level(level_id)
		if not level_id.is_empty() and not patron_level:
			levels_completed_count += 1
			level_last_completed_at[level_id] = levels_completed_count
			level_cleared_units[level_id] = time_units

		# The level has concluded, success or failure: each Supplies item's
		# Purchase Limit starts counting again, and level buffs run out.
		_conclude_level_items()

		# Laws with an "each level" effect pay out at the end of every level
		# after the one that passed them, win or loss (Law Effects tab).
		_apply_law_effect_rows(StatuteBook.ongoing_effects(
			statute_book, DataDB.law_effects, levels_completed_count))

		if last_level_outcome == LevelRunner.WON:
			_cause = Text.say("record.cause_level_win")
			_pay_level_rewards()
			_apply_level_bonus_win(level_runner.level)
			_cause = ""
			if not level_id.is_empty() and not patron_level and not DecisionScenes.is_ad_hoc_level_id(level_id):
				levels_cleared[level_id] = int(levels_cleared.get(level_id, 0)) + 1
		if patron_level:
			_conclude_patron_level()
		record_absent_vote_if_lost_act()

		# A special level, once played (win or lose), is done until its trigger
		# comes round again; after an ordinary level, any special level that is
		# due is forced in next.
		var finished_trigger := SpecialLevels.trigger_of(DataDB.get_level(level_id))
		if not finished_trigger.is_empty():
			special_levels.erase(finished_trigger)
		elif not due_special_levels().is_empty():
			special_forced = true
		SaveManager.autosave(true)
		return true
	SaveManager.autosave(true)
	return false


# ---------------------------------------------------------------------------
# Crisis triggers and lifetime tracking (finish_stage()'s own helpers)
# ---------------------------------------------------------------------------

## Wins/losses for this stage_id, lazily bucketed.
func _record_stage_type_result(stage_id: String, outcome: String) -> void:
	if stage_id.is_empty():
		return
	var bucket: Dictionary = stage_type_results.get(stage_id, {"wins": 0, "losses": 0})
	if outcome == LevelRunner.WON:
		bucket["wins"] = int(bucket.get("wins", 0)) + 1
	elif outcome == LevelRunner.LOST:
		bucket["losses"] = int(bucket.get("losses", 0)) + 1
	stage_type_results[stage_id] = bucket


## Adds this stage's own gaffe count to the run's lifetime total, counts a
## gaffe-caused loss, and applies the one-time Jiban penalty the moment the
## lifetime total crosses the Balance tab's own threshold.
func _record_lifetime_gaffes(gaffes: int, outcome: String, gaffe_caused_loss: bool) -> void:
	if gaffes > 0:
		lifetime_gaffes += gaffes
	if outcome == LevelRunner.LOST and gaffe_caused_loss:
		stages_lost_to_gaffes += 1

	if gaffe_penalty_applied:
		return
	var threshold := Levers.whole("gaffes_lifetime_penalty_threshold")
	if lifetime_gaffes < threshold:
		return

	gaffe_penalty_applied = true
	var delta := Levers.whole("gaffes_lifetime_penalty_jiban_delta")
	_cause = Text.say("record.cause_gaffes")
	_apply_meta_reward("Constituency support", delta)
	_cause = ""
	pending_trigger_alerts.append({"kind": "gaffe_penalty", "edge": "entered",
		"count": lifetime_gaffes, "amount": absi(delta)})


## Funding freeze inserts nothing, so both edges always fire — there is no
## "nowhere to put it" case the way there is for a forced-in stage.
func _check_funding_freeze() -> void:
	var frozen := MetaRules.funding_frozen(party_support_effective(), DataDB.balance)
	if frozen and not funding_frozen_active:
		funding_frozen_active = true
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "entered"})
	elif not frozen and funding_frozen_active:
		funding_frozen_active = false
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "left"})


## Starts the Town Hall countdown the moment Constituency support first
## crosses its threshold (2026-10-18, Cameron: it used to insert a Town Hall
## into the level being played). The special level appears Special Level Delay
## units of the game clock later (due_special_levels()). Says nothing further
## until support has climbed back out again -- losing the Town Hall while
## support is still low must not immediately start a second countdown
## (Cameron, 2026-09-25).
func _check_town_hall() -> void:
	var jiban := int(meta.get("Constituency support", 0))
	var triggered := MetaRules.town_hall_triggered(jiban, DataDB.balance)
	if triggered and not town_hall_active:
		town_hall_active = true
		_arm_special(SpecialLevels.TOWN_HALL)
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "entered", "count": jiban})
	elif not triggered and town_hall_active:
		town_hall_active = false
		_cancel_special(SpecialLevels.TOWN_HALL)
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "left"})


## Same shape, for the Party Steering Committee Check-In, started when party
## support falls below its own threshold.
func _check_steering_committee() -> void:
	var party_support := party_support_effective()
	var triggered := MetaRules.steering_committee_triggered(party_support, DataDB.balance)
	if triggered and not steering_committee_active:
		steering_committee_active = true
		_arm_special(SpecialLevels.STEERING_COMMITTEE)
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "entered", "count": party_support})
	elif not triggered and steering_committee_active:
		steering_committee_active = false
		_cancel_special(SpecialLevels.STEERING_COMMITTEE)
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "left"})


## Begins a special level's countdown on the game clock, unless one is
## already running or waiting.
func _arm_special(trigger: String) -> void:
	if not special_levels.has(trigger):
		special_levels[trigger] = {"armed_at": time_units}


## The meter that queued a special level has climbed back out (2026-11-19,
## Cameron): the level is no longer needed, so a countdown still running, or a
## level already due, is dropped and the Office does not force it in. The
## player has been told ("... has recovered"). If the crisis crosses in again
## it starts a fresh countdown. A level the player is already playing is
## untouched: its own end clears it. Nothing is forced when nothing is due.
func _cancel_special(trigger: String) -> void:
	special_levels.erase(trigger)
	if due_special_levels().is_empty():
		special_forced = false


## The special levels whose countdown has run out, in the order they come due.
func due_special_levels() -> Array[String]:
	return SpecialLevels.due(special_levels, time_units,
		Levers.whole("special_level_delay"))


## The due special level rows, for the top of the level list.
func due_special_level_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for trigger: String in due_special_levels():
		var level := SpecialLevels.level_for(trigger, DataDB.levels)
		# A crisis level waits at its own office (two offices, 2026-11-20): it is neither listed nor forced
		# until the player is there, and it never moves them.
		if not level.is_empty() and level_at_this_office(level):
			rows.append(level)
	return rows


## If an ordinary level just ended with a special level due, the one to start
## now (and forget the order); {} otherwise. The Office calls this when it opens.
func take_forced_special() -> Dictionary:
	if not special_forced:
		return {}
	var rows := due_special_level_rows()
	if rows.is_empty():
		return {}   # still waiting at the other office: the order stays until the player arrives there
	special_forced = false
	return rows[0]


## Everything a finished stage is worth, in the order the brief sets out.
##
## Two separate things, and they stack:
##
##   Win deltas — flat rewards for winning, straight off the stage row.
##   These have been in the workbook and in MetaRules since milestone 1 and
##   have never had a caller, so winning a stage moved nothing at all.
##
##   Score effects — what the closing number was worth, for the stages that
##   produce one. The conversion lives in the stage's own data, so what a
##   press conference is worth is a number Cameron can change rather than a
##   rule written in code.
##
## The playtest stages carry zeroes for the win deltas until Cameron fills
## them in; the wiring is here so the moment he does, they land.
func _apply_stage_rewards(stage: Dictionary, outcome: String, score: int) -> void:
	# NOT reset here (2026-09-30): last_meta_change is scoped to the whole
	# level, the same as last_booster_change — resetting it per stage would
	# wipe out a Floor Vote's own favorability/influence-bonus moves, which
	# land on Sanban before finish_stage() (and this function) ever runs.
	last_xp_gained = 0
	if stage.is_empty():
		return

	# A win pays the stage's win_delta_* columns; a loss charges its
	# loss_delta_* columns (2026-09-27 — before this a loss cost nothing,
	# though every stage's penalties were already in the workbook).
	# 2026-09-22 workbook: xp_reward was renamed win_delta_xp.
	if outcome == LevelRunner.WON or outcome == LevelRunner.LOST:
		var side := "win" if outcome == LevelRunner.WON else "loss"
		_cause = Text.say("record.cause_stage_win" if side == "win" else "record.cause_stage_loss",
			{"stage": str(stage.get("name_en", ""))})
		var paid_stage := stage
		# Campaign Pressure: a win pays more or less Funds and XP.
		if side == "win" and difficulty != Difficulty.STANDARD:
			paid_stage = stage.duplicate(true)
			for column in ["win_delta_yen", "win_delta_xp"]:
				paid_stage[column] = Difficulty.payout(MetaRules.stage_delta(stage, column), DataDB.balance_base, difficulty)
		# Funding Freeze (M32) — party support at or below the Balance tab's
		# own threshold. Zeroed at the source rather than undone afterward,
		# so this is the one and only place Funds income can be frozen. Only
		# INCOME freezes: a Funds penalty for losing still lands.
		if funds_frozen() \
				and MetaRules.stage_delta(stage, side + "_delta_yen") > 0:
			paid_stage = paid_stage.duplicate(true)
			paid_stage[side + "_delta_yen"] = 0
		var moved := (MetaRules.apply_win_deltas(meta, paid_stage, sanban_rows_with_bonuses()) if side == "win"
			else MetaRules.apply_loss_deltas(meta, paid_stage, sanban_rows_with_bonuses()))
		meta = moved["meta"]
		_record_meta_change(moved["applied"])
		last_xp_gained = MetaRules.stage_delta(paid_stage, side + "_delta_xp")
		_move_xp(last_xp_gained)

	var scored := MetaRules.apply_score_effects(meta, stage, score, sanban_rows_with_bonuses())
	meta = scored["meta"]
	_record_meta_change(scored["applied"])
	_cause = ""


## owned_modifiers, plus M09 (Party Backing) when party_support_modifiers()
## currently grants it for free — CLAUDE.md §8: "> 75 gives M09", never
## added to owned_modifiers
## itself, so losing the standing later correctly turns the free grant back
## off and buying one yourself is never made pointless by already having it
## free. M32 (Funding Freeze) is deliberately excluded here: it is a
## penalty enforced directly in _apply_stage_rewards(), not a bonus a
## reward-paying function should ever hand out.
func _effectively_owned_modifiers() -> Array:
	var mod_ids: Array[String] = owned_modifiers.duplicate()
	for mod_id: String in MetaRules.party_support_modifiers(party_support_effective(), DataDB.balance):
		# Owing dues also switches the free Party Backing off (W-2, 2026-11-16).
		if mod_id == "M09" and dues_debt_locks_backings():
			continue
		if mod_id != "M32" and not mod_ids.has(mod_id):
			mod_ids.append(mod_id)

	var found: Array = []
	for id: String in mod_ids:
		var modifier := DataDB.get_modifier(id)
		if not modifier.is_empty():
			found.append(modifier)
	return found


## What the organisations backing you pay out for winning a LEVEL — not a
## single stage. RESOURCE_BONUS_ON_WIN's own workbook wording says "after
## successful completion of a level", so this is called once, when
## finish_stage() sees the level itself is won, rather than after every stage.
##
## Unlike the battle-start effects, this does not care who was in the
## room: a business circle pays for the result, not the audience.
func _pay_level_rewards() -> void:
	# M09's RESOURCE_BONUS_ON_WIN is what this function pays out.
	var owned := _effectively_owned_modifiers()
	# An organisation-triggered backing only pays while that organisation's
	# standing is at or above its number (Cameron, 2026-10-12).
	owned = owned.filter(func(m: Dictionary) -> bool:
		return m.get("trigger_booster_ids", []).is_empty() \
			or MetaRules.booster_trigger_met(m, booster_standing))
	if owned.is_empty():
		return

	# XP first — it is not a sanban row, so it goes through _move_xp rather
	# than the clamp-and-record path the other three share.
	var xp_bonus := ModifierEffects.level_win_resource_bonus(owned, "XP")
	if xp_bonus != 0:
		_move_xp(xp_bonus)
		last_xp_gained += xp_bonus

	for name: String in ["Funds", "Constituency support", "Party support"]:
		_apply_meta_reward(name, _unless_frozen(name, ModifierEffects.level_win_resource_bonus(owned, name)))


## The level's own "bonus_win_range_*" and "win_delta_bo01..32" columns,
## rolled and applied. Called on the same LEVEL win as _pay_level_rewards().
##
## [DEFAULT] "bonus win" is not a concept CLAUDE.md or the rest of the code
## defines anywhere — there is no separate "ordinary win" the workbook
## contrasts it with, and no flag anywhere marking some level wins as bonus
## and others not. Rather than invent that distinction, every one of these
## ranges is rolled on every win of the level that carries it, per the
## brief's own fallback for this case. If Cameron means something more
## specific by "bonus" — a clean win, a win within the turn limit, a
## first-time clear — that is a design decision for him to make, not one
## to guess at here.
func _apply_level_bonus_win(level: Dictionary) -> void:
	# Which columns are the bonus is LevelBonus's to say (2026-11-19), so the briefing's preview
	# (LevelBonus.preview) and this payout read the same ones.
	for key: String in LevelBonus.META_COLUMNS.keys():
		var meta_name: String = LevelBonus.META_COLUMNS[key]
		var rolled := _roll_range(level.get(key))
		if meta_name == "Funds":
			rolled = Difficulty.payout(rolled, DataDB.balance_base, difficulty)
		_apply_meta_reward(meta_name, _unless_frozen(meta_name, rolled))

	var xp_amount := Difficulty.payout(_roll_range(level.get(LevelBonus.XP_COLUMN)), DataDB.balance_base, difficulty)
	if xp_amount != 0:
		_move_xp(xp_amount)
		last_xp_gained += xp_amount

	# Every booster gets a chance at its own win_delta_boNN column, not just
	# the 16 that exist today — sorted by ID first so a booster added to the
	# workbook later rolls in the same order these always have (each roll
	# consumes the unseeded RNG, so the ORDER of these calls is part of what
	# "behaviour-neutral" means here, not just the set of keys read).
	var booster_ids: Array[String] = []
	for booster: Dictionary in DataDB.boosters:
		booster_ids.append(str(booster.get("booster_id", "")))
	booster_ids.sort()
	for booster_id: String in booster_ids:
		var rolled := _roll_range(level.get(LevelBonus.column_for(booster_id)))
		_under_cause(Text.say("record.cause_level_win"),
			func() -> void: _apply_booster_delta(booster_id, rolled))


## A stage or level reward to one meta-variable: clamped, and filed under
## what the last stage was worth.
func _apply_meta_reward(name: String, amount: int) -> void:
	if amount == 0:
		return
	var before := int(meta.get(name, 0))
	var after := MetaRules.clamp_meta(before, amount, _sanban_row(name))
	meta[name] = after
	_record_meta_change({name: after - before})


## A level's range columns are {"min": x, "max": y} or null ("this level
## carries no such bonus"). Rolled inclusively; null or a malformed value
## rolls nothing, same as an unset flat reward pays nothing.
func _roll_range(range_value: Variant) -> int:
	if not (range_value is Dictionary) or not (range_value as Dictionary).has("min"):
		return 0
	var low := int((range_value as Dictionary)["min"])
	var high := int((range_value as Dictionary)["max"])
	if high <= low:
		return low
	return randi_range(low, high)


## True while Party support has the Funding Freeze (M32) on.
func funds_frozen() -> bool:
	return "M32" in MetaRules.party_support_modifiers(party_support_effective(), DataDB.balance)


## A stage or level reward amount, or 0 when it is Funds income during the
## Funding Freeze (Cameron, 2026-10-31: the freeze covers stage and level
## rewards; events, visitors and laws still pay). Costs still land.
func _unless_frozen(name: String, amount: int) -> int:
	return 0 if name == "Funds" and amount > 0 and funds_frozen() else amount


func _sanban_row(name: String) -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == name:
			if name == "Funds":
				var with_cap := row.duplicate()
				var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
				var hard_max := int(row.get("max", 0))
				# The hard ceiling (sanban.json's own Funds "max") is the one
				# number nothing — not the starting cap, not any number of
				# Fund Limit purchases — is ever allowed to push past.
				with_cap["max"] = mini(starting_cap + funds_cap_bonus, hard_max)
				return with_cap
			return row
	return {"min": 0, "max": 999, "start": 0}


## The Funds row's own real ceiling: sanban.json's "max" cell, untouched by
## funds_starting_cap or funds_cap_bonus. Used wherever something needs to
## know the absolute number rather than the player's own current cap — e.g.
## buy_funds_cap()'s own "nothing left to buy" refusal.
func _funds_hard_max() -> int:
	return int(DataDB.get_sanban("Funds").get("max", 0))


## The most Funds the player can hold right now: the starting cap plus every
## Funds-cap increase bought, never past the hard ceiling. Shown at the top of
## the Marketplace, so it follows a purchase automatically.
func funds_limit() -> int:
	return int(_sanban_row("Funds").get("max", 0))


## DataDB.sanban, with Funds' own "max" replaced by _sanban_row()'s own
## already-correct current-cap version — the same adjustment _sanban_row()
## already makes for a single lookup, but MetaRules.apply_win_deltas()/
## apply_loss_deltas()/apply_score_effects() each take the whole array, not
## one row at a time, so DataDB.sanban was being passed to them raw. A stage
## reward's own Funds delta was clamping against the workbook's flat max
## even after the player paid to raise it — bug found 2026-09-30, Cameron:
## "the yen/funds cap is not working." Always overridden for Funds now
## (2026-10-04), not just when funds_cap_bonus != 0 — the DEFAULT cap
## (funds_starting_cap) is lower than the raw sanban max too, not only the
## bonus-adjusted one.
func sanban_rows_with_bonuses() -> Array:
	var rows: Array = []
	for row: Dictionary in DataDB.sanban:
		rows.append(_sanban_row(str(row.get("name_en", ""))))
	return rows


## Earns or spends XP, and says so.
##
## Every change to the total goes through here so that nothing can move it
## quietly. The shop screens want to know the moment it changes, and so will
## anything that wants to make a sound about it.
func _move_xp(delta: int) -> void:
	if delta == 0:
		return
	xp += delta
	if delta > 0:
		xp_earned_total += delta
	EventBus.xp_changed.emit(xp, delta)


## Moves one meta-variable outside a stage, and says so.
##
## The sibling of _move_xp, and separate from _record_meta_change on purpose:
## that one also files the change under "what the last stage was worth", and
## money spent in the Office is not a stage reward. Both announce.
## Clamped like every other meta write, and announced with what ACTUALLY
## moved rather than what was asked for — a ceiling that swallows half a
## payment should not be reported as a full one.
func _move_meta(name: String, delta: int) -> void:
	if delta == 0:
		return

	var before := int(meta.get(name, 0))
	var after := MetaRules.clamp_meta(before, delta, _sanban_row(name))
	if after == before:
		return

	meta[name] = after
	EventBus.meta_changed.emit(name, after, after - before)


## Standing Links (2026-10-18). Leftover fractions of a point, per target, so
## small changes add up instead of vanishing.
var _link_carry: Dictionary = {}
## True while a link's own change is being applied (a followed change never
## starts another link) and during neglect decay.
var _links_suspended := false


## The source moved by `points`: every link from it moves its target by
## weight x points, a rivalry (negative weight) the other way.
func _follow_links(source: String, points: float) -> void:
	if _links_suspended or points == 0.0:
		return
	for row: Dictionary in StandingLinks.from_source(DataDB.standing_links, source):
		var target := str(row.get("target", ""))
		var weight := float(row.get("weight", 0.0))
		var settled := StandingLinks.settle(points * weight, float(_link_carry.get(target, 0.0)))
		_link_carry[target] = settled["carry"]
		var whole: int = settled["whole"]
		if whole == 0:
			continue
		var source_name := source if not source.begins_with("BO") else str(DataDB.get_booster(source).get("name_en", source))
		var cause := Text.say("record.cause_link_rival" if weight < 0.0 else "record.cause_link_follow",
			{"source": source_name})
		_links_suspended = true
		_under_cause(cause, func() -> void: _apply_booster_delta(target, whole))
		_links_suspended = false


## Files `amount` under the current cause for `key`, summing with an earlier
## entry for the same cause so a reason appears once with its total.
func _note_cause(store: Dictionary, key: String, amount: int) -> void:
	if amount == 0:
		return
	var cause := _cause if not _cause.is_empty() else Text.say("record.cause_other")
	var entries: Array = store.get(key, [])
	for entry: Dictionary in entries:
		if entry["cause"] == cause:
			entry["amount"] = int(entry["amount"]) + amount
			store[key] = entries
			return
	entries.append({"cause": cause, "amount": amount})
	store[key] = entries


## Runs a block of booster changes under a named cause, then puts the
## previous cause back.
func _under_cause(cause: String, change: Callable) -> void:
	var before := _cause
	_cause = cause
	change.call()
	_cause = before


## Folds one lot of changes into what the screen will report.
##
## A stage can move the same variable twice — a flat reward for winning and
## again for the score it closed on — and the player should be told the
## total, not shown the second overwriting the first.
func _record_meta_change(applied: Dictionary) -> void:
	for name: String in applied.keys():
		last_meta_change[name] = int(last_meta_change.get(name, 0)) + int(applied[name])
		# Funds earned on a weekday add to that week's dues (PartyDues.gd).
		if name == "Funds" and int(applied[name]) > 0 and not in_weekend():
			week_funds_earned += int(applied[name])
		if int(applied[name]) != 0 and not _cause.is_empty():
			_note_cause(last_meta_cause, name, int(applied[name]))
		if int(applied[name]) != 0 and not DataDB.standing_links.is_empty():
			_follow_links(name, StandingLinks.points_for_meta(name, int(applied[name]),
				_sanban_row(name), Levers.whole("standing_links_yen_per_point")))
		# Announced as well as recorded. The recording is for the result
		# screen, which asks afterwards; the announcement is for anything that
		# wants to react as it happens — a sound, or the Office lighting up a
		# number that just moved.
		if int(applied[name]) != 0:
			EventBus.meta_changed.emit(name, int(meta.get(name, 0)), int(applied[name]))


## Moves the player's standing with everyone a stage's question answers
## touched — pleased organisations up, annoyed ones down (2026-09-28,
## Cameron: a weak answer costs the organisation it would have pleased
## `per_displease`, currently 1).
##
## Standing is what survives the level; the pleased list is also what the
## floor debate draws on inside it (LevelRunner.carried_buffs()) — the
## displeased list is never used for that, only for the penalty here.
##
## Net, not additive: an organisation both pleased and annoyed in the same
## stage (two different questions) settles to one number, clamped to
## `question_swing_cap` either way — the hard ceiling on how far a single
## stage's question-answering can move any one organisation, whatever the
## please/displease amounts happen to be tuned to.
func _apply_question_boosters(pleased: Array, displeased: Array,
		opposed: Array = [], tally: Dictionary = {}) -> void:
	if pleased.is_empty() and displeased.is_empty() and opposed.is_empty() and tally.is_empty():
		return
	# One shared piece of arithmetic (BoosterStanding) with the outcome panel,
	# read against where each organisation stands right now.
	for entry: Dictionary in BoosterChange.compute(pleased, displeased, [],
			DataDB.booster_standing, opposed, stance_adjust_tally(tally), booster_standing):
		_under_cause(Text.say("record.cause_answers"),
			func() -> void: _apply_booster_delta(str(entry["booster_id"]), int(entry["net"])))


## An opponent argued all the way down to zero support (§7.2's instant-win
## rule, BattleEngine.crushed_opponent_boosters()) costs their own
## organisation standing — a flat, one-time hit per organisation touched
## this stage, regardless of how many of their own people went down the
## same way. Separate from _apply_question_boosters() above: this is never
## about a question's own grade, so it is never netted or capped alongside
## please/displease.
func _apply_instant_win_penalties(crushed_boosters: Array) -> void:
	if crushed_boosters.is_empty():
		return
	var penalty := int(DataDB.booster_standing.get("instant_win_penalty", 2))
	for booster_id: String in crushed_boosters:
		_under_cause(Text.say("record.cause_crush"),
			func() -> void: _apply_booster_delta(booster_id, -penalty))


## Office Hours (design/proposals/office_hours.md): applies one visitor's
## Reward column (on a correct answer) or Penalty column (on a wrong one) —
## OfficeHoursEngine.answer() hands back the raw, unresolved list exactly as
## stored on the visitor (it has no DataDB access, same as every other rules
## class), so resolving each target's real kind and record, and rolling any
## range delta, both happen here, once, at the moment the reward is actually
## applied — not shown to the player as a range and not rolled earlier at
## setup (open point 5 in the proposal).
func apply_visitor_reward_entries(entries: Array) -> String:
	var before := _cause
	_cause = Text.say("record.cause_visitor")
	var applied := _apply_reward_entries(entries)
	_cause = before
	last_visitor_effects = _effect_chips(applied)
	return _describe_grant_outcomes(applied)


## The one place a target_delta_list entry becomes a real effect — a
## visitor's Reward/Penalty, or a shop item's own Grants when it is used.
##
## A pooled entry ("BO01|BO02 +1") or a tier ("TIER:Party +1") picks one of
## its targets first, then applies like any other — UNLESS `chosen_target`
## is given, in which case that target is used instead of picking (an item
## marked Player Choice, design/proposals/inventory.md; the player already
## chose in the UI, so there is nothing left to roll). `extra_delta` is a
## flat amount added to every booster/segment entry's own delta — an item's
## staff bonus (Items.staff_bonus_rows()), already totalled by the caller,
## layered on top of the base effect wherever it lands.
##
## A shop item (SHxx) named here goes INTO THE INVENTORY, the same as
## buying one — Cameron, 2026-09-25: one consistent place for items to land
## — so there is nothing to recurse into and no way for two items to loop on
## each other. A stage effect (ENERGY, GUARD, ...) named here, outside an
## item being used, waits for the next stage.
##
## Returns every entry actually applied — {"kind","id","delta"} — so a
## caller whose grant was a random pick (a Commission item's "TIER:Party",
## say) can tell the player which organisation it actually landed on
## (2026-09-29, Cameron: a random outcome has to show up on screen, not
## only be inferable later from Important Stakeholders' own "(+1)" line).
## A BOOSTER_TIER pick is recorded as a plain BOOSTER, since by the time it
## is applied it IS one. STAGE_EFFECT is left out — it never names an
## organisation, and the caller reads it from split["stage"] separately.
func _apply_reward_entries(entries: Array, chosen_target: String = "",
		extra_delta: int = 0) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for raw: Variant in entries:
		if not (raw is Dictionary):
			continue
		var entry := _choose_target(raw, chosen_target)
		var resolved := DataDB.resolve_reward_target(entry)
		var kind: String = resolved.get("kind", "")
		var target_id: String = resolved.get("id", "")
		match kind:
			RewardTargets.BOOSTER:
				var delta := _resolve_delta(resolved.get("delta")) + extra_delta
				_apply_booster_delta(target_id, delta)
				applied.append({"kind": kind, "id": target_id, "delta": delta})
			RewardTargets.BOOSTER_TIER:
				# Only reached when nothing was chosen — a chosen target
				# already replaced this with a plain BOOSTER above.
				var pool: Array = (resolved.get("record", {}) as Dictionary).get("boosters", [])
				if not pool.is_empty():
					var picked: Dictionary = pool[randi() % pool.size()]
					var picked_id := str(picked.get("booster_id", ""))
					var delta := _resolve_delta(resolved.get("delta")) + extra_delta
					_apply_booster_delta(picked_id, delta)
					applied.append({"kind": RewardTargets.BOOSTER, "id": picked_id, "delta": delta})
			RewardTargets.MODIFIER:
				_grant_backing_for(target_id, ModifierEffects.duration_units(DataDB.get_modifier(target_id)))
				applied.append({"kind": kind, "id": target_id, "delta": 0})
			RewardTargets.SEGMENT:
				var delta := _resolve_delta(resolved.get("delta")) + extra_delta
				_apply_segment_delta(target_id, delta)
				applied.append({"kind": kind, "id": target_id, "delta": delta})
			RewardTargets.SHOP_ITEM:
				# A delta, when given, is how many; a bare "SH04" is one.
				var count := maxi(_resolve_delta(resolved.get("delta")), 1)
				add_item(target_id, count)
				applied.append({"kind": kind, "id": target_id, "delta": count})
			RewardTargets.STAGE_EFFECT:
				_add_bonus(pending_stage_bonuses, target_id, _stage_effect_amount(resolved.get("delta")))
			_:
				push_warning("GameState: reward/penalty target '%s' did not resolve to anything." % target_id)
	return applied


## A grant's outcome in plain English — "Chamber of Commerce +1" — for
## whichever entries named an organisation or a segment. Only those two
## kinds are ever picked at random (a modifier or a shop item's own name
## already says exactly what was granted), so this is deliberately narrow:
## it answers "which one did the roll land on," not "what did I get."
## The standing changes in `applied` as chip entries ({ "id", "delta" }):
## organizations and audience groups only.
func _effect_chips(applied: Array) -> Array:
	var out: Array = []
	for entry: Dictionary in applied:
		if str(entry.get("kind", "")) in [RewardTargets.BOOSTER, RewardTargets.SEGMENT]:
			out.append({"id": str(entry.get("id", "")), "delta": int(entry.get("delta", 0))})
	return out


func _describe_grant_outcomes(applied: Array) -> String:
	var parts: Array[String] = []
	for entry: Dictionary in applied:
		var id: String = str(entry.get("id", ""))
		var delta := int(entry.get("delta", 0))
		match str(entry.get("kind", "")):
			RewardTargets.BOOSTER:
				parts.append("%s %+d" % [DataDB.get_booster(id).get("name_en", id), delta])
			RewardTargets.SEGMENT:
				parts.append("%s %+d" % [DataDB.get_segment(id).get("name_en", id), delta])
	return ", ".join(parts)


## A pool-shaped entry ("BO01|BO02 +1" or "TIER:Party +1"), decided:
## `chosen_target` wins when given (the player already picked it in the
## UI); otherwise a pool is randomly narrowed to one plain target here —
## unseeded, like every other roll here — and a tier is left for
## resolve_reward_target()/_apply_reward_entries() to pick from, since only
## DataDB knows which boosters currently belong to it. A plain entry
## (neither) comes back unchanged either way.
func _choose_target(entry: Dictionary, chosen_target: String) -> Dictionary:
	if not chosen_target.is_empty() and RewardTargets.is_pool_shaped(entry):
		return {"target": chosen_target, "delta": entry.get("delta")}

	var pool: Variant = entry.get("target_pool")
	if not (pool is Array) or (pool as Array).is_empty():
		return entry
	var picked := entry.duplicate()
	picked.erase("target_pool")
	picked["target"] = str((pool as Array)[randi() % (pool as Array).size()])
	return picked


# ---------------------------------------------------------------------------
# The inventory (design/proposals/inventory.md)
# ---------------------------------------------------------------------------

func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


## The uses left on each held copy of an item, fewest first (Cameron, 2026-11-16).
## Kept in step with the count held: a copy with no record (a starting item, a
## coupon, a save from before uses) has full uses.
func item_copies(item_id: String) -> Array[int]:
	var count := item_count(item_id)
	if count <= 0:
		item_uses.erase(item_id)
		return []
	var copies := ItemUses.normalize(item_uses.get(item_id), count, ItemUses.full_uses(DataDB.get_shop_item(item_id)))
	item_uses[item_id] = copies
	return copies


## Uses left on the copy the next use would spend (0 when none is held).
func item_uses_left(item_id: String) -> int:
	return ItemUses.next_left(item_copies(item_id))


## Spends one use of an item (the most-used copy first). A copy with no uses left
## is thrown away and a line says so in `staff_use_notes`. Returns true when a
## copy wore out.
func _spend_use(item_id: String) -> bool:
	var result := ItemUses.spend(item_copies(item_id))
	item_uses[item_id] = result["copies"]
	var worn_out := bool(result["worn_out"])
	if worn_out:
		_drop_copy_count(item_id)
		var full := ItemUses.full_uses(DataDB.get_shop_item(item_id))
		if full > 1:
			staff_use_notes.append(Text.say("item.worn_out", {"item": str(DataDB.get_shop_item(item_id).get("name", item_id))}))
	return worn_out


func _drop_copy_count(item_id: String) -> void:
	var left := item_count(item_id) - 1
	if left > 0:
		inventory[item_id] = left
	else:
		inventory.erase(item_id)
		item_uses.erase(item_id)


## Adds up to `count` of an item, never past its Stack Cap. Returns how many
## actually went in — a visitor's gift beyond the cap is lost, not banked.
func add_item(item_id: String, count: int = 1) -> int:
	var item := DataDB.get_shop_item(item_id)
	var cap := Items.stack_cap(item)
	var room := count if cap <= 0 else clampi(cap - item_count(item_id), 0, count)
	if room > 0:
		item_copies(item_id)   # lock in the uses of the copies already held
		inventory[item_id] = item_count(item_id) + room
		item_copies(item_id)   # the new copies start with full uses
	return room


## Buys one item from the Supplies shop: the Ledger-style refusal first, then
## every non-zero price (XP and/or Funds) is spent and announced, and the item
## goes into the inventory. Returns the refusal, or "" when it went through.
func buy_shop_item(item_id: String) -> String:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	add_item(item_id, 1)
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1
	return ""


## Rhetoric Training (Cameron, 2026-09-27) — where new cards come from.
## SH09-SH11 (XP), each naming a "card_tier" in shop.json, and the free
## Training Session Coupon (SH21).
## A draw shows the player a card BEFORE they pay for it:
##
##   offer_random_card()  starts a draw: one random card of that tier the
##                        player does not own yet, look 1. Nothing is paid.
##                        A draw already in progress is returned as it is.
##   pass_offered_card()  swaps it for another card of the same tier, look
##                        2, then 3 — rules.json's card_training_looks (3).
##   learn_offered_card() pays the item's price, adds exactly the card on
##                        screen, and ends the draw.
##
## The last look cannot be passed and a draw cannot be walked away from
## (Cameron, 2026-09-27: "must learn it") — seeing a card commits the
## player to learning one of up to three. The draw is saved, so closing
## the app does not reroll it; learning a card is what starts a fresh one.
##
## Each returns { "ok": bool, "message": String }; an ok offer or pass also
## carries { "card_id", "look", "looks" } for the pop-up's "#/3" counter.
func offer_random_card(item_id: String) -> Dictionary:
	if not card_draw.is_empty():
		return _draw_result()
	var item := DataDB.get_shop_item(item_id)
	var refusal := card_training_refusal(item_id)
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	var choices := _unowned_cards_at_tier(_draw_tier(item))
	var card_id: String = choices[randi() % choices.size()]
	# The session takes its hours when it begins; passing on a card or two costs no more.
	spend_hours(training_hours(int(item.get("card_tier", 0))))
	card_draw = {"item_id": item_id, "card_id": card_id, "look": 1, "seen": [card_id]}
	return _draw_result()


func pass_offered_card() -> Dictionary:
	if card_draw.is_empty():
		return {"ok": false, "message": ""}
	if not can_pass_offered_card():
		return {"ok": false, "message": ""}
	var tier := _draw_tier(DataDB.get_shop_item(str(card_draw["item_id"])))
	var seen: Array = card_draw.get("seen", [])
	# Something not shown yet in this draw where possible; with fewer unowned
	# cards left than looks, anything but the card on screen now.
	var fresh := _unowned_cards_at_tier(tier).filter(func(id: String) -> bool: return not seen.has(id))
	if fresh.is_empty():
		fresh = _unowned_cards_at_tier(tier).filter(
			func(id: String) -> bool: return id != str(card_draw["card_id"]))
	var card_id: String = fresh[randi() % fresh.size()]
	card_draw["card_id"] = card_id
	card_draw["look"] = int(card_draw["look"]) + 1
	seen.append(card_id)
	card_draw["seen"] = seen
	return _draw_result()


## True while the card on screen is not the draw's last look, and there is
## some other card of that tier to swap it for.
func can_pass_offered_card() -> bool:
	if card_draw.is_empty() or int(card_draw["look"]) >= card_training_looks():
		return false
	var tier := _draw_tier(DataDB.get_shop_item(str(card_draw["item_id"])))
	return _unowned_cards_at_tier(tier).size() > 1


## How many cards one draw may show — rules.json's card_training_looks.
func card_training_looks() -> int:
	return maxi(int(DataDB.get_rule("card_training_looks", 3)), 1)


func learn_offered_card() -> Dictionary:
	if card_draw.is_empty():
		return {"ok": false, "message": ""}
	var item_id := str(card_draw["item_id"])
	var card_id := str(card_draw["card_id"])
	var item := DataDB.get_shop_item(item_id)
	var free := _is_free_draw(item)
	var refusal := "" if free else _card_training_refusal(item)
	if refusal.is_empty() and not _unowned_cards_at_tier(_draw_tier(item)).has(card_id):
		refusal = Text.say("shop.no_cards_left_at_tier", {"tier": _draw_tier(item)})
	if not refusal.is_empty():
		# Nothing the player did on this screen can cause this (the price was
		# checked when the draw began), so a draw that can no longer be paid
		# for is let go rather than left stuck on screen.
		card_draw = {}
		return {"ok": false, "message": refusal}

	if not free:
		var price := Items.costs(item)
		_move_xp(-int(price["XP"]))
		_move_meta("Funds", -int(price["Funds"]))
		shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1
	owned_cards.append(card_id)
	card_draw = {}
	var card_name := str(DataDB.get_card(card_id).get("name_en", card_id))
	return {"ok": true, "card_id": card_id,
		"message": Text.say("shop.card_unlocked", {"name": card_name})}


func _draw_result() -> Dictionary:
	return {"ok": true, "message": "", "item_id": str(card_draw["item_id"]),
		"card_id": str(card_draw["card_id"]), "look": int(card_draw["look"]),
		"looks": card_training_looks()}


## Why a training session cannot be had right now, or "": the item's own
## price and stock (Items.buy_refusal), then whether any card of its tier
## is left to learn. Shared by the Office's row (to grey its button) and
## both steps above.
func card_training_refusal(item_id: String) -> String:
	var item := DataDB.get_shop_item(item_id)
	var refusal := _card_training_refusal(item)
	# Starting a session takes its hours; reopening a draw already in progress does not (they were taken when it began).
	if refusal.is_empty() and (card_draw.is_empty() or str(card_draw.get("item_id", "")) != item_id):
		refusal = _hours_refusal(training_hours(int(item.get("card_tier", 0))))
	return refusal


func _card_training_refusal(item: Dictionary) -> String:
	var item_id := str(item.get("item_id", ""))
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal
	var tier := int(item.get("card_tier", 0))
	if _unowned_cards_at_tier(tier).is_empty():
		return Text.say("shop.no_cards_left_at_tier", {"tier": tier})
	return ""


## The card tier an item draws from: a coupon's Free Card Tier, else a
## training session's Card Tier.
func _draw_tier(item: Dictionary) -> int:
	var free: Variant = item.get("free_card_tier")
	return int(free) if free != null else int(item.get("card_tier", 0))


## True for a Training Session Coupon: its draw costs nothing (the coupon was
## the payment).
func _is_free_draw(item: Dictionary) -> bool:
	return item.get("free_card_tier") != null


## Whether a Rhetoric Training draw from this item costs nothing (a coupon), so the offer can say so.
func draw_is_free(item: Dictionary) -> bool:
	return _is_free_draw(item)


func _unowned_cards_at_tier(tier: int) -> Array[String]:
	var choices: Array[String] = []
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == tier and not owned_cards.has(str(card.get("card_id", ""))):
			choices.append(str(card.get("card_id", "")))
	return choices


## A shop item with a "level_tier" (none in the current Shop tab; the code is
## kept and tested): the same on-purchase shape as
## the old one-step random-card purchase, and for the same reason — pays, then
## immediately unlocks one random not-yet-unlocked level of shop.json's
## own "level_tier". Ledger.is_level_unlocked() (not a bare levels_unlocked
## check) is what decides "not-yet-unlocked", so a level that is already
## open for some other reason (its own unlock cost is 0) is correctly
## never offered here.
func buy_random_level(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	var tier := int(item.get("level_tier", 0))
	var choices: Array[String] = []
	for level: Dictionary in DataDB.levels:
		if int(level.get("tier", -1)) == tier and is_level_discovered(level) and not is_event_only(level) and level_is_for_player(level) \
				and not act_is_settled(level) \
				and not Ledger.is_level_unlocked(level, levels_unlocked, staff_hired):
			choices.append(str(level.get("level_id", "")))
	if choices.is_empty():
		return {"ok": false, "message": Text.say("shop.no_levels_left_at_tier", {"tier": tier})}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	var level_id: String = choices[randi() % choices.size()]
	levels_unlocked.append(level_id)
	var level_name := str(DataDB.get_level(level_id).get("description", level_id))
	return {"ok": true, "message": Text.say("shop.level_unlocked", {"name": level_name})}


## The Staff Training Consultancy Session (SH12): pays, then raises
## staff_recruitment_tier by 1 — Ledger.staff_hire_refusal() is where that
## actually opens up candidates. Refuses once every candidate's own
## highest_tier is already open, rather than let a purchase do nothing.
## The highest staff rank any candidate can reach (the Staff tab's own
## Highest Tier), so a new tier added to the workbook raises the ceiling.
func staff_recruitment_max() -> int:
	var highest := 0
	for candidate: Dictionary in DataDB.staff:
		highest = maxi(highest, int(candidate.get("highest_tier", 0)))
	return highest


## True once recruitment has reached the top tier: the Staff Training
## Consultancy Session leaves the Marketplace (Cameron, 2026-10-31).
func staff_recruitment_maxed() -> bool:
	return staff_recruitment_tier >= staff_recruitment_max()


func buy_staff_recruitment_tier(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	if staff_recruitment_maxed():
		return {"ok": false, "message": Text.say("shop.recruitment_tier_maxed")}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	staff_recruitment_tier += 1
	return {"ok": true, "message": Text.say("shop.recruitment_tier_unlocked")}


## The Fund Limit Increase Petition (SH13): pays, then permanently raises how
## high Funds can go by the item's own "funds_cap_increase" — repeatable
## until the player's own current cap (rules.json's funds_starting_cap
## plus every funds_cap_bonus bought so far) reaches the hard ceiling
## (sanban.json's own Funds "max", 1,000,000). See _sanban_row(), where
## funds_cap_bonus is actually applied.
## The Balance levers with the deck size raised by any expansions bought, for
## everything that checks or builds the player's own deck.
func deck_balance() -> Dictionary:
	var balance := DataDB.balance.duplicate()
	balance["starter_deck_size"] = Ledger.deck_size(DataDB.balance) + deck_size_bonus
	return balance


## How many cards the player's deck holds now.
func deck_size() -> int:
	return Ledger.deck_size(deck_balance())


## True once deck expansions have been bought the most times allowed (Balance
## "Deck Expansion: Maximum Purchases"): the item leaves the Marketplace.
func deck_expansion_maxed() -> bool:
	return deck_expansions >= Levers.whole("deck_expansion_maximum_purchases")


## A deck expansion: pays, then the deck holds `deck_size_increase` more cards
## for the rest of the run. Owned cards not yet in the deck fill the new
## slots at once, so the deck stays legal; it is refused when there are not
## enough of them. Returns { ok, message }.
func buy_deck_expansion(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if deck_expansion_maxed():
		return {"ok": false, "message": Text.say("shop.deck_expansion_maxed")}
	var increase := maxi(int(item.get("deck_size_increase", 1)), 1)
	var spare: Array[String] = []
	for card_id: String in owned_cards:
		if not deck.has(card_id) and spare.size() < increase:
			spare.append(card_id)
	if spare.size() < increase:
		return {"ok": false, "message": Text.say("shop.deck_no_spare")}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1
	deck_size_bonus += increase
	deck_expansions += 1
	deck.append_array(spare)
	return {"ok": true, "message": Text.say("shop.deck_expanded", {"count": deck_size()})}


## True once the Funds limit has reached the hard ceiling, so no petition can
## raise it further (2026-11-11, Cameron: the Marketplace then stops listing it).
func funds_cap_maxed() -> bool:
	var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
	return starting_cap + funds_cap_bonus >= _funds_hard_max()


func buy_funds_cap(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	if funds_cap_maxed():
		return {"ok": false, "message": Text.say("shop.funds_cap_maxed")}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	var increase := int(item.get("funds_cap_increase", 0))
	funds_cap_bonus += increase
	return {"ok": true, "message": Text.say("shop.funds_cap_increased", {"count": increase})}


## Uses one item from the Office. Its standing effects (boosters, segments,
## modifiers) apply now; its stage effects wait for the next stage, or the
## whole next level when its Duration is "Level".
##
## `chosen_target` is which of a Player Choice item's pool to use — required
## the moment Items.is_player_choice(item) is true; left empty first, this
## returns { "ok": false, "needs_choice": true } instead of a refusal, which
## tells the UI to open the picker and call this again with the answer,
## rather than a reason to show the player.
##
## Returns { "ok": bool, "message": String } or { "ok": false, "needs_choice": true }.
## Why an item that hosts an event cannot be used at the office the player stands in, or "" (the dinner is locked to the
## Capitol and the walking tour to the District, by the Hosted Events tab's Location).
func item_office_refusal(item: Dictionary) -> String:
	var hosted_id := str(item.get("hosted_event", "")) if item.get("hosted_event") != null else ""
	if hosted_id.is_empty():
		return ""
	var hosted := get_hosted_event(hosted_id)
	return Items.office_refusal(hosted, office_location, TravelText.place_name(Offices.normalize(hosted.get("location"))), Text.phrase())


func use_item_in_office(item_id: String, chosen_target: String = "") -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.use_refusal(item, Items.OFFICE, item_count(item_id), Text.phrase())
	if refusal.is_empty():
		refusal = item_office_refusal(item)
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if Items.is_player_choice(item) and chosen_target.is_empty():
		return {"ok": false, "needs_choice": true}

	# Some Office items take time (the dinner and the walking tour: Shop "Hours"); a coaching coupon's session takes its tier's hours.
	var hours := _item_hours(item)
	var hours_refusal := _hours_refusal(hours)
	if not hours_refusal.is_empty():
		return {"ok": false, "message": hours_refusal}

	var name := str(item.get("name", item_id))
	# A dinner or a walking tour starts a hosted event: what comes of it depends
	# on how the guests react, not on whom you chose (Cameron, 2026-10-23).
	var hosted_id := str(item.get("hosted_event", "")) if item.get("hosted_event") != null else ""
	if not hosted_id.is_empty():
		_take_item(item_id)
		begin_hosted_event(hosted_id, chosen_target, hours)
		return {"ok": true, "opens_hosted": hosted_id, "org": chosen_target, "message": ""}
	if _is_free_draw(item):
		# A Training Session Coupon: a free Rhetoric Training draw. Refused
		# (coupon kept) while another draw is open or no card of the tier is left.
		if not card_draw.is_empty():
			return {"ok": false, "message": Text.say("rhetoric.draw_in_progress")}
		var choices := _unowned_cards_at_tier(_draw_tier(item))
		if choices.is_empty():
			return {"ok": false, "message": Text.say("shop.no_cards_left_at_tier", {"tier": _draw_tier(item)})}
		_take_item(item_id)
		spend_hours(hours)
		var card_id: String = choices[randi() % choices.size()]
		card_draw = {"item_id": item_id, "card_id": card_id, "look": 1, "seen": [card_id]}
		return {"ok": true, "opens_draw": true,
			"message": Text.say("rhetoric.coupon_used", {"name": name})}

	_spend_use(item_id)
	var split := Items.split_grants(item)
	var cause_before := _cause
	_cause = Text.say("record.cause_item", {"item": str(item.get("name_en", ""))})
	var applied := _apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	_cause = cause_before
	var outcome := _describe_grant_outcomes(applied)
	# A gathering takes its hours, and hosting an organization can bring up a
	# bill that was hidden until now (a level's Host Org).
	var gathering := _after_gathering(hours, chosen_target)
	if (split["stage"] as Array).is_empty():
		return {"ok": true, "message": (Text.say("item.used_with_outcome",
			{"name": name, "outcome": outcome}) if not outcome.is_empty()
			else Text.say("item.used", {"name": name})) + gathering,
			"plain": Text.say("item.used", {"name": name}), "effects": _effect_chips(applied),
			"image": str(item.get("image", "")) if item.get("image") != null else ""}

	var level := Items.duration(item) == Items.DURATION_LEVEL
	var lasts := Items.duration_units(item)
	var target := pending_level_bonuses if level else pending_stage_bonuses
	if lasts > 0:
		# A timed item runs from now for that many clock units, whichever
		# stage or level it lands in (take_item_bonuses_for_stage()).
		target = {}
	for effect: Dictionary in _resolve_stage_effects(split["stage"]):
		_add_bonus(target, str(effect["token"]), int(effect["amount"]))
	if lasts > 0:
		timed_bonuses.append({"bonuses": target, "expires_at": time_units + lasts})
	if not outcome.is_empty():
		return {"ok": true, "message": Text.say(
			"item.queued_level_with_outcome" if level else "item.queued_with_outcome",
			{"name": name, "outcome": outcome}),
			"plain": Text.say("item.queued_level" if level else "item.queued", {"name": name}),
			"effects": _effect_chips(applied)}
	return {"ok": true, "message": Text.say(
		"item.queued_level" if level else "item.queued", {"name": name})}


## Why an item that takes `hours` cannot be used now, as a sentence; "" when it can.
## Why an Office item that takes hours (the dinner, the walking tour) cannot be
## used right now for lack of time, else blank. The item pop-up shows it on a
## disabled Use button (2026-11-12, Cameron).
func item_hours_refusal(item: Dictionary) -> String:
	return _hours_refusal(_item_hours(item))


## The hours using an item takes: its Shop Hours cell, or for a coaching coupon the hours of its tier's session.
func _item_hours(item: Dictionary) -> int:
	if item.get("free_card_tier") != null:
		return training_hours(int(item.get("free_card_tier", 0)))
	return int(item.get("hours", 0)) if item.get("hours") != null else 0


## The hours a Rhetoric Training session of `tier` takes (Balance: Rhetoric Training: Hours Per Tier, times the tier).
func training_hours(tier: int) -> int:
	return maxi(0, tier) * Levers.whole("rhetoric_training_hours_per_tier")


func _hours_refusal(hours: int) -> String:
	if hours <= 0:
		return ""
	# The rule that decides whether a level can be played (WeekCalendar.
	# level_refusal, Cameron 2026-11-12): a full week refuses, and so does an
	# item that needs more hours than are left, on a weekday as well as in a
	# weekend. Items may be used in a weekend, so the weekend flag is "yes".
	match WeekCalendar.level_refusal(calendar, calendar_config(), hours, true):
		WeekCalendar.REFUSE_WEEK_OVER:
			return Text.say("item.refuse_week_over")
		WeekCalendar.REFUSE_TOO_LONG:
			return Text.say("item.refuse_hours")
	return ""


## What happens after a gathering: its hours pass, and hosting the organization
## `chosen_target` may reveal a level. Returns the sentences to add to the
## item's message ("" when there is nothing to add).
func _after_gathering(hours: int, chosen_target: String) -> String:
	if hours <= 0:
		return ""
	spend_hours(hours)
	var text := " " + Text.say("item.hosted_hours", {"hours": hours, "count": hours})
	var revealed := reveal_by_hosting(chosen_target)
	if not revealed.is_empty():
		text += " " + Text.say("item.hosted_reveal", {"name": revealed})
	return text


## Hosting `org_id` reveals the first hidden level naming it as its Host Org.
## Returns that level's name, or "" when there is none left.
func reveal_by_hosting(org_id: String) -> String:
	if org_id.is_empty():
		return ""
	for level: Dictionary in DataDB.levels:
		if str(level.get("host_org", "")) != org_id or is_level_discovered(level):
			continue
		var level_id := str(level.get("level_id", ""))
		discovered_levels.append(level_id)
		return str(level.get("description", level_id))
	return ""


## Uses one item during a stage. Its stage effects land on the battle now
## (BattleEngine.use_item(), which also enforces Uses Per Turn); a level
## buff keeps running for the rest of the level too. Standing effects apply
## now, the same as in the Office. Nothing is taken from the inventory if
## the battle refuses.
##
## `chosen_target` — see use_item_in_office()'s own note; the same
## needs_choice contract applies here.
func use_item_in_stage(item_id: String, engine: BattleEngine, chosen_target: String = "") -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.use_refusal(item, Items.STAGE, item_count(item_id), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if Items.is_player_choice(item) and chosen_target.is_empty():
		return {"ok": false, "needs_choice": true}

	var split := Items.split_grants(item)
	var effects := _resolve_stage_effects(split["stage"])
	var result := engine.use_item(item_id, effects, Items.uses_per_turn(item))
	if not result.get("ok", false):
		return {"ok": false, "message": str(result.get("reason", ""))}

	_spend_use(item_id)
	var cause_before := _cause
	_cause = Text.say("record.cause_item", {"item": str(item.get("name_en", ""))})
	var applied := _apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	_cause = cause_before
	var stage_lasts := Items.duration_units(item)
	if stage_lasts > 0:
		var carried := {}
		for effect: Dictionary in effects:
			_add_bonus(carried, str(effect["token"]), int(effect["amount"]))
		timed_bonuses.append({"bonuses": carried, "expires_at": time_units + stage_lasts})
	elif Items.duration(item) == Items.DURATION_LEVEL:
		for effect: Dictionary in effects:
			_add_bonus(level_bonuses, str(effect["token"]), int(effect["amount"]))
	var name := str(item.get("name", item_id))
	var outcome := _describe_grant_outcomes(applied)
	if not outcome.is_empty():
		return {"ok": true, "message": Text.say("item.used_with_outcome", {"name": name, "outcome": outcome}),
			"plain": Text.say("item.used", {"name": name}), "effects": _effect_chips(applied)}
	return {"ok": true, "message": Text.say("item.used", {"name": name})}


## Everything item-driven the next stage starts with: the level's running
## buffs plus anything used in the Office for "the next stage", which is
## spent by asking. { "ENERGY": 2, ... }.
func take_item_bonuses_for_stage() -> Dictionary:
	var bonuses := level_bonuses.duplicate()
	for token: String in pending_stage_bonuses.keys():
		_add_bonus(bonuses, token, int(pending_stage_bonuses[token]))
	pending_stage_bonuses = {}
	# Timed items still running (the rest are dropped as they run out).
	var still_running: Array = []
	for entry: Variant in timed_bonuses:
		var timed: Dictionary = entry
		if int(timed.get("expires_at", 0)) <= time_units:
			continue
		still_running.append(timed)
		var carried: Dictionary = timed.get("bonuses", {})
		for token: String in carried.keys():
			_add_bonus(bonuses, token, int(carried[token]))
	timed_bonuses = still_running
	return bonuses


## Why a choice's commitments (Commitments.gd) cannot be paid now, in words,
## or "" when they can (2026-10-31).
func commitment_refusal(list: Array) -> String:
	if list.is_empty():
		return ""
	var cfg := calendar_config()
	var hours_left := 0 if WeekCalendar.is_full(calendar, cfg) else WeekCalendar.hours_left(calendar, cfg)
	var why := Commitments.refusal(list, hours_left, int(meta.get("Funds", 0)), inventory)
	match why:
		"":
			return ""
		Commitments.HOURS:
			return Text.say("event.refuse_work_hours")
		Commitments.FUNDS:
			return Text.say("event.refuse_funds")
	return Text.say("commit.refuse_item", {"item": str(DataDB.get_shop_item(why).get("name", why))})


## A choice's text with what it costs, e.g. "Commission a study (30,000円)".
func commitment_label(text: String, list: Array) -> String:
	# What is paid the moment the choice is made (hours, Funds, an item) is
	# headed "Act Now:"; what comes later (a promise, a follow-up) is not, so the
	# two cannot be mistaken for each other (2026-11-02, Cameron).
	var now_parts: Array[String] = []
	var later_parts: Array[String] = []
	var hours := Commitments.hours(list)
	if hours > 0:
		now_parts.append(Text.say("commit.hours", {"count": hours}))
	var funds := Commitments.funds(list)
	if funds > 0:
		now_parts.append(Text.say("commit.funds", {"yen_amount": funds}))
	for item_id: String in Commitments.items(list):
		now_parts.append(Text.say("commit.item", {"item": str(DataDB.get_shop_item(item_id).get("name", item_id))}))
	for entry: Variant in list:
		if entry is Dictionary and str(entry.get("kind", "")) == "followup":
			later_parts.append(Text.say("commit.followup"))
		if Promises.is_promise(entry):
			var shown := Promises.make(entry, 0, Levers.whole("promise_default_deadline_hours"), "", "", 0)
			later_parts.append(Text.say("commit.promise", {"what": promise_what(shown), "count": int(shown["due_at"])}))
	var parts: Array[String] = []
	if not now_parts.is_empty():
		parts.append(Text.say("commit.act_now", {"costs": ", ".join(now_parts)}))
	parts.append_array(later_parts)
	if parts.is_empty():
		return text
	return Text.say("commit.label", {"text": text, "cost": "; ".join(parts)})


## What to tell the player once a choice's commitments have been paid: the hours
## that passed on the spot, then each line pay_commitments() returned (the
## promise made, Funds spent, an item handed over). Office Hours used to drop
## all of it, so an hour could pass or a promise be made without a word
## (2026-11-02).
func commitment_note(list: Array, paid_lines: Array[String]) -> String:
	var lines: Array[String] = []
	var hours := Commitments.hours(list)
	if hours > 0:
		lines.append(Text.say("commit.hours_passed", {"count": hours}))
	lines.append_array(paid_lines)
	return "\n".join(lines)


## Pays a choice's commitments: the hours pass, the Funds are spent, the items
## are handed over. Returns lines for a result screen.
func pay_commitments(list: Array, source: String = "", fallback_org: String = "",
		terms: Dictionary = {}, location: String = "") -> Array[String]:
	var lines: Array[String] = []
	# A promise is kept at the office of the choice that made it (two offices, 2026-11-20): the choice's own
	# Location when it sets one, else where the player stands now.
	var promise_office := Offices.normalize(location) if not location.is_empty() else office_location
	# A choice that owes more than one thing (hours and Funds) carries its own
	# kept and broken terms on the first only; the rest use the Balance defaults.
	var terms_given := false
	# Hours a choice costs on the spot pass before any promise or follow-up is
	# dated, so those count from when the choice is done (2026-10-31).
	var hours := Commitments.hours(list)
	if hours > 0:
		spend_hours(hours)
	# A follow-up from a choice that also made a promise belongs with that
	# promise: it waits while the promise is open and is dropped if the promise
	# breaks, so a follow-up never describes a promise kept that was not
	# (Cameron, 2026-11-09). The group ties them; a choice with no promise
	# ("follow up later") leaves its follow-up free.
	var group := ""
	for entry: Variant in list:
		if Promises.is_promise(entry):
			group = "%s#%d" % [source, promise_serial + 1]
			break
	for entry: Variant in list:
		if entry is Dictionary and str(entry.get("kind", "")) == "followup":
			var scheduled := {"event_id": str(entry.get("event_id", "")),
				"due_at": time_units + int(entry.get("after", 0))}
			if not group.is_empty():
				scheduled["group"] = group
			scheduled_events.append(scheduled)
			continue
		if Promises.is_promise(entry):
			promise_serial += 1
			var promise := Promises.make(entry, time_units, Levers.whole("promise_default_deadline_hours"),
				fallback_org, source, promise_serial, promise_office)
			# The choice's own kept/broken effects and kept line, when it has
			# them (Event Choices, 2026-10-31); otherwise the Balance defaults.
			for key: String in ["kept", "broken", "kept_text"]:
				if terms.has(key) and not terms_given:
					promise[key] = terms[key]
			terms_given = true
			if not group.is_empty():
				promise["group"] = group
			promises.append(promise)
			lines.append(Text.say("promise.made", {"what": promise_what(promise), "who": promise_who(promise),
				"count": int(promise["due_at"]) - time_units}))
	var funds := Commitments.funds(list)
	if funds > 0:
		_under_cause(Text.say("record.cause_commitment"), func() -> void: _apply_meta_reward("Funds", -funds))
		lines.append(Text.say("event.effect_line", {"name": "Funds", "change": Phrase.meta_amount("Funds", -funds, true)}))
	for item_id: String in Commitments.items(list):
		_take_item(item_id)
		lines.append(Text.say("commit.item_given", {"item": str(DataDB.get_shop_item(item_id).get("name", item_id))}))
	return lines


## The first organization a reward list raises, or "" (who a promise is owed to
## when its cell does not say).
static func _first_pleased_org(rewards: Variant) -> String:
	if rewards is Array:
		for entry: Variant in rewards:
			if entry is Dictionary and str(entry.get("target", "")).begins_with("BO"):
				var delta: Variant = entry.get("delta")
				var amount := float((delta as Dictionary).get("max", 0)) if delta is Dictionary else float(delta if delta != null else 0)
				if amount > 0:
					return str(entry["target"])
	return ""


## One whole copy leaves the inventory (handed over, promised, given away): the
## copy with the fewest uses left, whatever it had left.
func _take_item(item_id: String) -> void:
	item_uses[item_id] = ItemUses.remove_copy(item_copies(item_id))
	_drop_copy_count(item_id)


## An item's stage-effect entries as [ { "token", "amount" } ], each pool
## picked and each range rolled once, here, at the moment of use.
func _resolve_stage_effects(entries: Array) -> Array:
	var effects: Array = []
	for raw: Variant in entries:
		if not (raw is Dictionary):
			continue
		var entry := _choose_target(raw, "")
		effects.append({
			"token": str(entry.get("target", "")).to_upper(),
			"amount": _stage_effect_amount(entry.get("delta")),
		})
	return effects


## A stage effect written bare ("ENERGY") means +1 — the natural reading,
## unlike a booster target where a bare ID has no amount to apply.
func _stage_effect_amount(delta: Variant) -> int:
	return 1 if delta == null else _resolve_delta(delta)


func _add_bonus(bonuses: Dictionary, token: String, amount: int) -> void:
	if amount == 0:
		return
	var key := token.to_upper()
	bonuses[key] = int(bonuses.get(key, 0)) + amount


## The sum of an item's Bonus 1/2/3 rows whose named Staff role is hired at
## or above that row's Min Tier — 0 where nobody qualifies. Cameron,
## 2026-09-25: SH01-03 work without the role; having it layers this on top.
func _staff_bonus_total(item: Dictionary) -> int:
	var total := 0
	for row: Dictionary in Items.staff_bonus_rows(item):
		var hired: Dictionary = staff_hired.get(str(row["role"]), {})
		if hired.is_empty():
			continue
		if int(hired.get("tier", -1)) >= int(row["min_tier"]):
			var amount := int(row["amount"])
			# A restless person's boosts count for less (Balance "Staff Loyalty: Restless Boost Percent").
			if StaffLoyalty.band(staff_loyalty_of(str(hired.get("staff_id", "")))) != StaffLoyalty.BAND_NORMAL:
				amount = int(amount * Levers.num("staff_loyalty_restless_boost_percent") / 100.0)
			total += amount
	return total


## Every booster standing change goes through here: clamped to
## booster_standing.json's range, and added to what the last level did.
func _apply_booster_delta(booster_id: String, delta: int) -> void:
	if delta == 0:
		return
	var low := int(DataDB.booster_standing.get("min", 0))
	var high := int(DataDB.booster_standing.get("max", 100))
	var before := int(booster_standing.get(booster_id, 50))
	var after := clampi(before + delta, low, high)
	booster_standing[booster_id] = after
	if after != before:
		if not _decaying:
			booster_moved_in_period[booster_id] = true
		last_booster_change[booster_id] = int(last_booster_change.get(booster_id, 0)) + (after - before)
		_note_cause(last_booster_cause, booster_id, after - before)
		_follow_links(booster_id, float(after - before))


## Where the player stands with `party_name`. The player's own party reads
## straight off `meta["Party support"]` — see party_standing's own doc
## comment for why that is the one deliberate exception.
func party_favorability(party_name: String) -> int:
	if party_name == str(DataDB.player.get("party", "")):
		return int(meta.get("Party support", 0))
	return int(party_standing.get(party_name, 50))


## ---------------------------------------------------------------------------
## Party opinion (2026-10-10, Cameron): how each party sees the player. See
## PartyOpinion.gd for the maths. DIRECT is party_favorability() (the Party
## support meta for the player's own party, party_standing for the rest);
## STAKEHOLDER is the weighted standing of the organisations the workbook's
## Party Standing tab ties to that party.
## ---------------------------------------------------------------------------

## The player's own party as a party_id ("" when there is none).
func own_party_id() -> String:
	var own := DataDB.get_party(str(DataDB.player.get("party", "")))
	return str(own.get("party_id", ""))


## Everything the Parties page and the rules need about one party:
## {party_id, name, direct, stakeholder (-1 = none), opinion, band,
## contributions}.
func party_opinion_detail(party_id: String) -> Dictionary:
	var party := {}
	for row: Dictionary in DataDB.parties:
		if str(row.get("party_id", "")) == party_id:
			party = row
	var party_name := str(party.get("name", ""))
	var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, party_id, own_party_id())
	var held := PartyOpinion.stakeholder(rows, booster_standing,
		int(DataDB.booster_standing.get("start", 30)))
	var direct := party_favorability(party_name)
	var score := PartyOpinion.opinion(direct, int(held["score"]), DataDB.balance)
	return {"party_id": party_id, "name": party_name, "direct": direct,
		"stakeholder": int(held["score"]), "opinion": score,
		"band": PartyOpinion.band(score, DataDB.balance),
		"contributions": held["contributions"]}


func party_opinion(party_id: String) -> int:
	return int(party_opinion_detail(party_id)["opinion"])


## What every "Party support" rule reads for the player's own party (Option A,
## Cameron 2026-10-10): the blended opinion, so organisations matter. Stage
## rewards, votes and leans still add to the stored meta number. With no
## player party, or no data for it, this is simply the stored number.
func party_support_effective() -> int:
	var own := own_party_id()
	if own.is_empty():
		return int(meta.get("Party support", 0))
	return party_opinion(own)


## How far the live Party support number (party_support_effective()) moved
## this level, counting both halves: what votes/rewards did to the stored
## number AND what the level did to the organisations tied to the party.
## Works backwards from the current state: the direct number minus its change,
## each organisation's standing minus its own change, then the same blend.
func party_support_change_this_level() -> int:
	var own := own_party_id()
	if own.is_empty():
		return int(last_meta_change.get("Party support", 0))
	var before_standing := booster_standing.duplicate()
	for booster_id: String in last_booster_change.keys():
		before_standing[booster_id] = int(before_standing.get(booster_id, 0)) \
			- int(last_booster_change[booster_id])
	var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, own, own)
	var held := PartyOpinion.stakeholder(rows, before_standing,
		int(DataDB.booster_standing.get("start", 30)))
	var direct_before := int(meta.get("Party support", 0)) - int(last_meta_change.get("Party support", 0))
	return party_support_effective() - PartyOpinion.opinion(direct_before, int(held["score"]), DataDB.balance)


## `meta` with Party support replaced by the effective (blended) number, for
## rules that read the whole dictionary (the Floor Vote influence gate).
func effective_meta() -> Dictionary:
	var copy := meta.duplicate()
	copy["Party support"] = party_support_effective()
	return copy


## Every OTHER party's favorability change goes through here: clamped to
## party_standing.json's range, added to what the last vote did. The
## player's own party is routed through _move_meta() instead (the ordinary
## "Party support" path every other stage already uses), never through
## here — see party_favorability().
func _apply_party_delta(party_name: String, delta: int) -> void:
	if delta == 0 or party_name == str(DataDB.player.get("party", "")):
		return
	var low := int(DataDB.party_standing.get("min", 0))
	var high := int(DataDB.party_standing.get("max", 100))
	var before := int(party_standing.get(party_name, 50))
	var after := clampi(before + delta, low, high)
	party_standing[party_name] = after
	if after != before:
		last_party_change[party_name] = int(last_party_change.get(party_name, 0)) + (after - before)


## Applies what a Floor Vote (ST23) did to every party's favorability —
## { party_name: delta, ... }, straight from FloorVoteEngine.choose()'s own
## "favorability_deltas". The player's own party's share lands on "Party
## support" the same way any other stage's win_delta_party_support does;
## everything else lands on party_standing.
func apply_floor_vote_favorability(deltas: Dictionary, cause: String = "") -> void:
	_cause = cause
	var own_party := str(DataDB.player.get("party", ""))
	for party_name: String in deltas:
		var delta := int(deltas[party_name])
		if party_name == own_party:
			_apply_meta_reward("Party support", delta)
		else:
			_apply_party_delta(party_name, delta)
	_cause = ""


## The Floor Vote influence swing's own bonus (2026-09-28, §7.7): a bill's
## optional "Influence Bonus (Reputation)"/"Influence Bonus (Party support)"
## columns, applied only when the swing actually flipped that bill's own
## pass/fail outcome. Both blank read as 0, same as every other delta column
## — a no-op call is fine and expected for the common case of no bonus set.
func apply_floor_vote_influence_bonus(reputation_delta: int, party_support_delta: int,
		cause: String = "") -> void:
	_cause = cause
	_apply_meta_reward("Reputation", reputation_delta)
	_apply_meta_reward("Party support", party_support_delta)
	_cause = ""


## Spends stored Party support (whipping a vote, 2026-10-22). Refused, changing
## nothing, when it would leave less than the floor (Balance: Whip: Party
## Support Floor) so a whip can never push the player into the party crisis.
func spend_party_support(amount: int, cause: String = "") -> bool:
	if amount <= 0:
		return true
	var floor_value := Levers.whole("whip_party_support_floor")
	if int(meta.get("Party support", 0)) - amount < floor_value:
		return false
	_cause = cause
	_apply_meta_reward("Party support", -amount)
	_cause = ""
	return true


## M48-style backing (PARTY_BILL_FLIP_BONUS): when the player's influence
## turns a bill their own party backs from failing to passing, an owned
## backing whose organization still holds pays its Party support. Returns the
## amount paid (0 when nothing applies).
func apply_flip_backing(bill: Dictionary, result: Dictionary) -> int:
	if not bool(result.get("outcome_flipped_by_influence", false)) or not bool(result.get("passed", false)):
		return 0
	var own := own_party_id()
	var backed := false
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own and str(position.get("disposition", "")) == "Supportive":
			backed = true
	if not backed:
		return 0
	var total := 0
	for modifier: Dictionary in _effectively_owned_modifiers():
		if ModifierEffects.type_of(modifier) == ModifierEffects.PARTY_BILL_FLIP_BONUS \
				and MetaRules.booster_trigger_met(modifier, booster_standing):
			total += int(round(ModifierEffects.value_of(modifier)))
	if total != 0:
		_cause = Text.say("record.cause_flip_backing", {"bill": str(bill.get("bill_name", ""))})
		_apply_meta_reward("Party support", total)
		_cause = ""
	return total


## Every bill_id the influence swing has flipped (§7.7), in the order they
## happened. A bill can only be voted once — every real Floor Vote level is
## One-Time (§8) — so this never needs deduplicating in practice, but
## guarded anyway, the same caution FloorVoteEngine._reallocate_player_
## vote() already takes for its own single-seat move.
func record_bill_flip(bill_id: String) -> void:
	if bill_id.is_empty() or bills_flipped_by_influence.has(bill_id):
		return
	bills_flipped_by_influence.append(bill_id)
	apply_awareness_delta("national", Levers.whole("awareness_flipped_bill_national"))


## An Act whose bill the player voted Aye or Nay on never comes back; one they
## were absent for or abstained on returns after its replay timer (Cameron,
## 2026-11-13). The level list and level purchases leave a settled Act out.
func act_is_settled(level: Dictionary) -> bool:
	var bill := DataDB.get_floor_vote(str(level.get("level_id", "")))
	return not bill.is_empty() and StatuteBook.player_took_a_side(statute_book, str(bill.get("bill_id", "")))


## A bill level (an Act) that the player lost or abandoned still comes to a vote,
## with the player abstaining (2026-11-12, Cameron). The bill's own engine runs
## with no whips and no influence; whichever way it goes is recorded as a
## limited "absent" entry and takes effect like any vote, with nothing added.
## Does nothing outside a lost bill level, for a patron bill, or when the bill
## is already in the book.
func record_absent_vote_if_lost_act() -> void:
	if level_runner == null or last_level_outcome != LevelRunner.LOST:
		return
	var level_id := str(level_runner.level.get("level_id", ""))
	if DataDB.is_runtime_level(level_id):
		return
	var source := level_bill()
	if source.is_empty() or StatuteBook.has_bill(statute_book, str(source.get("bill_id", ""))):
		return
	var bill := BattleSetup.enriched_floor_vote(source)
	var vote := FloorVoteEngine.new()
	if not vote.setup({
		"bill": bill,
		"player_party": str(DataDB.player.get("party", "")),
		"meta": effective_meta(),
		"booster_standing": booster_standing,
		"triggers": DataDB.vote_influence_triggers,
		"default_threshold": Levers.whole("vote_influence_default_threshold"),
		"default_resistance": Levers.whole("vote_swing_resistance_default"),
		"supermajority_percent": Levers.whole("supermajority_percent_of_house"),
		"assist": bill_assist,
	}):
		return
	record_floor_vote(bill, vote.choose("Abstain"), "Absent", true)


## Writes one Floor Vote into the statute book and applies that bill's
## "once" Law Effects for how it went (passed or failed). A bill already in
## the book is ignored, so a replayed screen can never apply it twice.
## Called from FloorVoteScreen._on_vote() (and the playtest bot).
func record_floor_vote(bill: Dictionary, result: Dictionary, choice: String, absent: bool = false) -> void:
	last_patron_outcome = {}
	var bill_id := str(bill.get("bill_id", ""))
	if bill_id.is_empty():
		return
	if StatuteBook.has_bill(statute_book, bill_id):
		# Only an entry where the player was absent or abstained can be
		# replaced, and only by a later real vote on the bill (it came back after
		# its replay timer, 2026-11-13). Aye or Nay is final.
		if absent or not StatuteBook.is_replaceable(statute_book, bill_id):
			return
		StatuteBook.remove_bill(statute_book, bill_id)
	var level_id := ""
	if level_runner != null:
		level_id = str(level_runner.level.get("level_id", ""))
	var law := StatuteBook.entry(bill, result, choice, level_id, levels_completed_count, absent)
	statute_book.append(law)
	_apply_law_effect_rows(StatuteBook.effects_for(
		DataDB.law_effects, bill_id, bool(law["passed"]), StatuteBook.ONCE))
	_apply_party_tier_lean(bill_id, bool(law["passed"]))
	if patron_requests.has(bill_id):
		_resolve_patron_vote(bill_id, bool(law["passed"]))


## Party-tier organisations (Party Headquarters, Party Faction) answer to
## where the player's own party stood on the bill, not to a fixed row, so
## each protagonist's party sees a bill differently. Sizes come from the
## Balance tab (law_lean_party_tier_pass_delta / law_lean_party_tier_fail_delta).
func _lean_multiplier(booster: Dictionary) -> float:
	var raw: Variant = booster.get("party_lean_multiplier")
	return 1.0 if raw == null else float(raw)


func _apply_party_tier_lean(bill_id: String, passed: bool) -> void:
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var own := own_party_id()
	var disposition := ""
	var scale := 1.0
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own:
			disposition = str(position.get("disposition", ""))
			scale = BattleSetup.salience_factor(position)
	var delta := StatuteBook.party_tier_delta(disposition, passed,
		PartySalience.scaled(Levers.whole("law_lean_party_tier_pass_delta"), scale),
		PartySalience.scaled(Levers.whole("law_lean_party_tier_fail_delta"), scale))
	if delta == 0:
		return
	for booster: Dictionary in DataDB.boosters:
		if str(booster.get("tier", "")) == "Party":
			var party_body := str(booster.get("booster_id", ""))
			# Each Party Body reacts at its own strength (Boosters tab, Party
			# Lean Multiplier; blank = 1.0).
			var own_delta := PartySalience.scaled(delta, _lean_multiplier(booster))
			_under_cause(Text.say("record.cause_party_lean", {"bill": str(bill.get("bill_name", ""))}),
				func() -> void: _apply_booster_delta(party_body, own_delta))


# ---------------------------------------------------------------------------
# A bill level's stance (BillStance, 2026-10-18)
# ---------------------------------------------------------------------------

## The Floor Vote bill the level in progress votes on ({} when it has none).
func level_bill() -> Dictionary:
	if level_runner == null:
		return {}
	return DataDB.get_floor_vote(str(level_runner.level.get("level_id", "")))


## Records the lean picked on the Level Intro screen. Ignored for a bill with
## nobody on either side to hear it.
func set_bill_lean(bill_id: String, lean: String) -> void:
	if bill_id.is_empty() or not BillStance.is_lean(lean):
		return
	bill_stance = {"bill_id": bill_id, "lean": lean, "cost": {}, "voted": false}


func stance_lean() -> String:
	return str(bill_stance.get("lean", ""))


## { "supporters": [...], "opponents": [...] } for the stance's bill. Party
## Bodies are left out: they follow your party, not the bill's Law Effects.
func stance_sides() -> Dictionary:
	if bill_stance.is_empty():
		return {"supporters": [], "opponents": []}
	var bill: Dictionary = DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {})
	return BillStance.sides(bill, DataDB.law_effects, _party_tier_booster_ids())


func _party_tier_booster_ids() -> Array:
	var ids: Array = []
	for booster: Dictionary in DataDB.boosters:
		if str(booster.get("tier", "")) == "Party":
			ids.append(str(booster.get("booster_id", "")))
	return ids


## The Balance numbers BillStance.vote() reads.
func stance_config() -> Dictionary:
	var balance := DataDB.balance
	return {
		"vote_delta": int(balance.get("stance_vote_delta", 0)),
		"abandoned_penalty": int(balance.get("stance_flip_abandoned_penalty", balance.get("stance_vote_delta", 0))),
		"recovery_percent": int(balance.get("stance_flip_recovery_percent", 0)),
		"party_away": int(balance.get("stance_flip_party_support_away", 0)),
		"party_toward": int(balance.get("stance_flip_party_support_toward", 0)),
	}


## A stage's booster tally with the rhetoric rule applied: answers that would
## please an organization on the side against your lean count for less. A copy;
## the same tally the Outcome panel and the preview read.
## The organisations whose backing the player owns (each owned modifier's
## trigger organisations). Their tastes in rhetoric show on the battle screen.
func backed_booster_ids() -> Array[String]:
	var out: Array[String] = []
	for mod_id: String in owned_modifiers:
		for booster_id: String in (DataDB.get_modifier(mod_id).get("trigger_booster_ids", []) as Array):
			if not out.has(booster_id):
				out.append(booster_id)
	return out


func stance_adjust_tally(tally: Dictionary) -> Dictionary:
	var lean := stance_lean()
	if lean.is_empty() or tally.is_empty():
		return tally
	return BillStance.adjust_tally(tally, BillStance.other_side(stance_sides(), lean),
		Levers.whole("stance_other_side_please_percent"))


func _stance_bill_name() -> String:
	return str(DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {}).get("bill_name", ""))


## Winning a Combat stage in a bill level: the side against your lean loses,
## your own side gains. What the far side lost is remembered, because a switch
## at the vote can win a quarter of it back.
func _apply_stance_win_drift() -> void:
	var lean := stance_lean()
	if lean.is_empty():
		return
	var drift := BillStance.win_drift(stance_sides(), lean, Levers.whole("stance_win_drift"))
	var cost: Dictionary = bill_stance.get("cost", {})
	for id: String in drift:
		var delta := int(drift[id])
		_under_cause(Text.say("record.cause_stance_drift", {"bill": _stance_bill_name()}),
			func() -> void: _apply_booster_delta(id, delta))
		if delta < 0:
			cost[id] = int(cost.get(id, 0)) - delta
	bill_stance["cost"] = cost


## Your own vote on the stance's bill: moves its supporters and opponents, and
## prices a switch (the side you leave loses more, the side you join wins a
## little back, Party support moves). Returns BillStance.vote()'s result, or {}
## when there is no stance or it was already applied.
func apply_stance_vote(choice: String) -> Dictionary:
	if bill_stance.is_empty() or bool(bill_stance.get("voted", false)):
		return {}
	bill_stance["voted"] = true
	var result := preview_stance_vote(choice)
	var bill: Dictionary = DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {})
	var vote_cause := Text.say("record.cause_stance_switch" if bool(result.get("flip", false))
		else "record.cause_stance_vote", {"bill": str(bill.get("bill_name", ""))})
	for id: String in (result["deltas"] as Dictionary):
		var moved := int((result["deltas"] as Dictionary)[id])
		_under_cause(vote_cause, func() -> void: _apply_booster_delta(id, moved))
	var party_delta := int(result["party_delta"])
	if party_delta != 0:
		apply_floor_vote_favorability({str(DataDB.player.get("party", "")): party_delta},
			Text.say("record.cause_stance_switch", {"bill": str(bill.get("bill_name", ""))}))
	# Kept on the bill's statute entry so Your Record can show what the vote
	# itself moved, next to what the outcome did (2026-11-04, Cameron).
	for law: Dictionary in statute_book:
		if str(law.get("bill_id", "")) == str(bill_stance.get("bill_id", "")):
			law["vote_effects"] = (result["deltas"] as Dictionary).duplicate()
	return result


## What voting `choice` would do under the current stance, without doing it
## (the vote screen's preview and apply_stance_vote() share this). { } with no
## stance.
func preview_stance_vote(choice: String) -> Dictionary:
	if bill_stance.is_empty():
		return {}
	var bill_id := str(bill_stance.get("bill_id", ""))
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var own := own_party_id()
	var disposition := ""
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own:
			disposition = str(position.get("disposition", ""))
	var result := BillStance.vote(stance_sides(), stance_lean(), choice,
		bill_stance.get("cost", {}), disposition, stance_config())
	result["bill_id"] = bill_id
	return result


## What winning a Combat stage would do to the stance's stakeholders, for the
## Outcome panel. { } with no stance.
func stance_drift_preview() -> Dictionary:
	var lean := stance_lean()
	if lean.is_empty():
		return {}
	return BillStance.win_drift(stance_sides(), lean, Levers.whole("stance_win_drift"))


## bill_id -> "passed"/"failed", for Office Notices and the Ticker.
func law_statuses() -> Dictionary:
	return StatuteBook.status_map(statute_book)


## Applies Law Effects rows: their Effects cell through the same reward path
## shop items and visitors use (boosters, segments, modifiers, items), and
## their meta and XP columns as rewards, so Your Record shows the change.
func _apply_law_effect_rows(rows: Array) -> void:
	for row: Dictionary in rows:
		var effects: Variant = row.get("effects")
		if effects is Array:
			_apply_reward_entries(effects)
		var deltas := StatuteBook.meta_deltas(row)
		var bill_id := str(row.get("bill_id", ""))
		_cause = Text.say("record.cause_law", {"bill": str(
			DataDB.floor_votes.get(bill_id, {}).get("bill_name", bill_id))})
		for name: String in deltas:
			_apply_meta_reward(name, int(deltas[name]))
		_cause = ""
		_move_xp(StatuteBook.xp_delta(row))


## Every segment favorability change goes through here, clamped 0-100
## (segments.json carries no range of its own).
func _apply_segment_delta(segment_id: String, delta: int) -> void:
	if delta == 0:
		return
	var before := int(segment_favorability.get(segment_id, 50))
	var after := clampi(before + delta, 0, 100)
	segment_favorability[segment_id] = after
	if after != before:
		last_segment_change[segment_id] = int(last_segment_change.get(segment_id, 0)) + (after - before)


## A target_delta_list entry's delta, resolved to a real number: null is no
## magnitude (0), a plain number passes through, and a {"min","max"} range is
## rolled — unseeded, the same as every other range roll in the game
## (_roll_range() itself, BattleSetup._opponent_count()).
func _resolve_delta(delta: Variant) -> int:
	if delta is Dictionary and (delta as Dictionary).has("min"):
		return _roll_range(delta)
	if delta == null:
		return 0
	return int(delta)


## Clears the level, on the way back to the Office.
func end_level() -> void:
	level_runner = null
	_resume_promise_deadlines()
	patron_runtime = {}
	scene_runtime = {}
	bill_assist = BillAssist.empty()
	bill_stance = {}
	# Level buffs belong to the level; nothing else here to clear, since
	# finish_stage() already reset the purchase counts when it concluded.
	level_bonuses = {}
	_arrive_after_level()


## Throws away a level in progress without recording a win, a loss, or a
## completion of any kind — the level goes right back to being just another
## choice in the Levels panel, not shown-locked like a cooldown and not
## hidden like a finished One-Time level, since neither
## level_last_completed_at nor levels_completed_count are touched here.
##
## Whatever the player already banked from stages they actually finished
## earlier in this same attempt stays banked — finish_stage() already
## applied those rewards and saved the game at the time. Only the stage
## still ahead of them, and this attempt's own per-level purchase limits,
## are thrown away; picking the level again starts it over from stage one.
##
## The only real caller is the Office's own "a level was in progress"
## choice (OfficeScreen._show_resume_choice_if_in_level()), reached only
## when the app was closed and reopened mid-level — normal play never
## returns to the Office until a level actually concludes, so this can
## never fire mid-stage by accident.
func abandon_level() -> void:
	if not patron_runtime.is_empty():
		# An abandoned patron level leaves the request open to accept again.
		var abandoned := str(patron_runtime.get("patron_bill_id", ""))
		if patron_requests.has(abandoned) and patron_requests[abandoned]["status"] == PatronRequests.ACCEPTED:
			# A drafted bill cannot be offered again: its cost is spent.
			patron_requests[abandoned]["status"] = PatronRequests.LAPSED if patron_drafts.has(abandoned) else PatronRequests.OPEN
		patron_runtime = {}
	scene_runtime = {}
	bill_assist = BillAssist.empty()
	level_runner = null
	_resume_promise_deadlines()
	bill_stance = {}
	level_bonuses = {}
	shop_bought_this_level = {}
	_arrive_after_level()


func _conclude_level_items() -> void:
	shop_bought_this_level = {}
	level_bonuses = {}


# ---------------------------------------------------------------------------
# Patron Bills (2026-10-19)
# ---------------------------------------------------------------------------

## Patron bills that are due now: standing high enough, not yet asked, a
## Flagship only after its organization's Favor is resolved. Step 4's Requests
## block reads this; it moves nothing.
func patron_bills_due() -> Array:
	var statuses := {}
	for id: String in patron_requests:
		statuses[id] = str((patron_requests[id] as Dictionary).get("status", ""))
	return PatronRequests.due(DataDB.patron_bills, booster_standing, statuses, DataDB.balance)


## Starts the countdown for every request that has just become due (idempotent).
func arm_patron_requests() -> void:
	# A due request whose every alternative component is already law can never
	# be offered. It is closed (lapsed, with no standing cost: it was never
	# shown), so an organization's Flagship, which waits for its Favor to be
	# resolved, is not held up behind it forever.
	for retired: int in range(8):
		var closed_one := false
		for id: String in patron_bills_due():
			if not bool(PatronLevel.compose(id, enacted_components)["ok"]):
				patron_requests[id] = {"status": PatronRequests.LAPSED, "components": [], "amended": false, "tries": 0}
				patron_armed.erase(id)
				closed_one = true
		if not closed_one:
			break
	for id: String in patron_bills_due():
		if not patron_armed.has(id):
			patron_armed[id] = time_units


## The requests the Requests block shows right now, oldest first: those whose
## countdown has run out, plus any returned to the queue, up to
## `patron_requests_waiting_at_once`. Requests that cannot be composed (every
## alternative already law) are left out. Moves nothing but the countdown.
func patron_requests_shown() -> Array:
	arm_patron_requests()
	var delay := Levers.whole("special_level_delay")
	var candidates: Array = []
	for id: String in patron_armed:
		var status := str((patron_requests.get(id, {}) as Dictionary).get("status", ""))
		var ready: bool = status == "" and time_units - int(patron_armed[id]) >= delay
		if ready or status == PatronRequests.WAITING or status == PatronRequests.OPEN:
			candidates.append(id)
	candidates.sort_custom(func(a: String, b: String) -> bool:
		return int(patron_armed[a]) < int(patron_armed[b]) or (int(patron_armed[a]) == int(patron_armed[b]) and a < b))
	var out: Array = []
	var cap := Levers.whole("patron_requests_waiting_at_once")
	for id: String in candidates:
		if out.size() >= cap:
			break
		if bool(PatronLevel.compose(id, enacted_components)["ok"]):
			out.append(id)
	return out


## Accepts a patron bill (optionally amended) and starts its level. Returns
## false, changing nothing, when a level is already running or the bill cannot
## be composed. `replace`/`with_id` are an Amend swap, both blank for none.
func start_patron_level(patron_bill_id: String, replace: String = "", with_id: String = "") -> bool:
	if is_in_level():
		return false
	var current := str((patron_requests.get(patron_bill_id, {}) as Dictionary).get("status", ""))
	if current in [PatronRequests.PASSED, PatronRequests.FAILED, PatronRequests.DECLINED, PatronRequests.LAPSED]:
		return false
	last_level_start_refusal = ""
	var built := PatronLevel.register(patron_bill_id, enacted_components, replace, with_id)
	if not built["ok"]:
		return false
	# The same rule as a written level: it must end within the work week
	# (Cameron, 2026-11-04). Sponsored and drafted bills are work-week levels.
	last_level_start_refusal = level_office_refusal(built["level"] as Dictionary)
	if last_level_start_refusal.is_empty():
		last_level_start_refusal = work_week_level_refusal(built["level"] as Dictionary)
	if not last_level_start_refusal.is_empty():
		return false
	var tries := int((patron_requests.get(patron_bill_id, {}) as Dictionary).get("tries", 0))
	patron_requests[patron_bill_id] = {
		"status": PatronRequests.ACCEPTED, "components": built["component_ids"],
		"amended": built["amended"], "tries": tries,
	}
	patron_composed[patron_bill_id] = {"bill": built["bill"], "component_ids": built["component_ids"]}
	patron_runtime = {"patron_bill_id": patron_bill_id, "level": built["level"]}
	var runner := LevelRunner.new(BattleSetup.expand_level(built["level"] as Dictionary))
	begin_level(runner)
	SaveManager.autosave(true)
	return true


## Declines a request: the organization's standing drops and the request is
## gone for the run.
func decline_patron_bill(patron_bill_id: String) -> void:
	var row := PatronLevel.patron_bill(patron_bill_id)
	if row.is_empty():
		return
	for entry: Dictionary in PatronRequests.decline_deltas(row, DataDB.balance):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))
	patron_requests[patron_bill_id] = {"status": PatronRequests.DECLINED, "components": [], "amended": false, "tries": 0}
	SaveManager.autosave(true)


## The vote on a patron bill has happened: standing moves for the patron, the
## ally and the organizations the bill hurts, the components' own effects
## apply, and a passed bill's components become law.
func _resolve_patron_vote(patron_bill_id: String, passed: bool) -> void:
	var state: Dictionary = patron_requests[patron_bill_id]
	var row := PatronLevel.patron_bill(patron_bill_id)
	var bill: Dictionary = (patron_composed.get(patron_bill_id, {}) as Dictionary).get("bill", {})
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var org := str(row.get("organization", ""))
	var effects: Array = bill.get("effects", []) as Array
	var rivals := PatronRequests.rivals_of(effects, org, ally)
	var outcome := PatronRequests.outcome(row, ally, rivals, passed, bool(state.get("amended", false)), DataDB.balance)
	for entry: Dictionary in (outcome["standing"] as Array):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))
	# What the vote did, for the result pop-up. Not saved: it is only read
	# right after the vote, on the same screen.
	last_patron_outcome = {"patron_bill_id": patron_bill_id, "passed": passed,
		"standing": (outcome["standing"] as Array).duplicate(true),
		"backing_org": org if passed and int(outcome["free_backing_units"]) > 0 else "",
		"components": (state.get("components", []) as Array).duplicate()}
	if passed:
		apply_awareness_delta("national", Levers.whole("awareness_passed_own_bill_national"))
		apply_awareness_delta("district", Levers.whole("awareness_passed_own_bill_district"))
		_apply_reward_entries(effects)
		for component_id: Variant in (state.get("components", []) as Array):
			if not enacted_components.has(component_id):
				enacted_components.append(component_id)
		_grant_free_backing(org, int(outcome["free_backing_units"]))
	state["status"] = PatronRequests.PASSED if passed else PatronRequests.FAILED
	patron_requests[patron_bill_id] = state
	# What the special stages did for (or against) this vote becomes a news
	# story the Office ticker runs for a while, then the record is spent.
	if BillAssist.total(bill_assist, "won_over") > 0:
		record_news("visit_success")
	if BillAssist.total(bill_assist, "worked_against") > 0:
		record_news("lobbyist_work")
	bill_assist = BillAssist.empty()


## Why a bill of `ids` cannot be drafted now ("" when it can).
func draft_refusal(ids: Array, extra_visit: bool = false) -> String:
	# A custom bill is carried at the Capitol only (Cameron, 2026-11-21): refused first, with where to go.
	var elsewhere := level_office_refusal({"location": PatronLevel.office()})
	if not elsewhere.is_empty():
		return elsewhere
	return DraftBill.refusal(ids, {"enacted": enacted_components, "xp": xp, "funds": int(meta.get("Funds", 0)),
		"time_units": time_units, "last_draft_at": last_draft_at, "in_level": is_in_level(),
		"extra_visit": extra_visit, "funds_limit": funds_limit(), "petition": funds_cap_item_name()})


## The Marketplace item that raises the Funds limit (the one with a Funds Cap Increase), by name.
func funds_cap_item_name() -> String:
	for item: Dictionary in DataDB.shop:
		if item.get("funds_cap_increase") != null:
			return str(item.get("name", ""))
	return ""


## Drafts a bill from `ids`: pays the cost, files it as a runtime patron row
## and starts its level. False (nothing paid) when it cannot be drafted.
func start_draft(ids: Array, extra_visit: bool = false) -> bool:
	if not draft_refusal(ids, extra_visit).is_empty():
		return false
	var draft_id := DraftBill.id_for(draft_counter + 1)
	patron_drafts[draft_id] = DraftBill.row_for(draft_id, ids, extra_visit)
	if not start_patron_level(draft_id):
		patron_drafts.erase(draft_id)
		return false
	draft_counter += 1
	last_draft_at = time_units
	var xp_cost := Levers.whole("draft_bill_xp_cost")
	# The extra member visit's XP, only when the level really got its second
	# visit (a bill with no one left to win over never charges for it).
	if extra_visit and not (DataDB.get_level(PatronLevel.level_id_for(draft_id)).get("visit_2", {}) as Dictionary).is_empty():
		xp_cost += DraftBill.extra_visit_xp_cost()
	_move_xp(-xp_cost)
	_move_meta("Funds", -Levers.whole("draft_bill_funds_cost"))
	return true


## A passed Flagship gives the patron's backing for free for a while, using the
## same clock-expiry machinery as a timed backing.
func _grant_free_backing(org: String, units: int) -> void:
	if units <= 0:
		return
	for mod_id: Variant in (DataDB.get_booster(org).get("linked_modifiers", []) as Array):
		_grant_backing_for(str(mod_id), units)


## Gives a backing for free, for `units` of the clock (0 = for good). One
## already held on a timer keeps the later of its own expiry and this grant's
## (Cameron, 2026-10-31); one held for good stays held for good.
func _grant_backing_for(mod_id: String, units: int) -> void:
	if not owned_modifiers.has(mod_id):
		owned_modifiers.append(mod_id)
		if units > 0:
			modifier_expires[mod_id] = time_units + units
		return
	if units > 0 and modifier_expires.has(mod_id):
		modifier_expires[mod_id] = maxi(int(modifier_expires[mod_id]), time_units + units)
	elif units <= 0:
		modifier_expires.erase(mod_id)


## A patron level ended. If the vote never happened (a stage lost ended the
## level first) the request returns once; a second time it lapses.
func _conclude_patron_level() -> void:
	var patron_bill_id := str(patron_runtime.get("patron_bill_id", ""))
	patron_runtime = {}
	if not patron_requests.has(patron_bill_id):
		return
	var state: Dictionary = patron_requests[patron_bill_id]
	if state["status"] != PatronRequests.ACCEPTED:
		return
	if patron_drafts.has(patron_bill_id):
		# A drafted bill that never reached its vote is lost; no organization is owed anything.
		state["status"] = PatronRequests.LAPSED
		patron_requests[patron_bill_id] = state
		return
	state["tries"] = int(state.get("tries", 0)) + 1
	if int(state["tries"]) >= Levers.whole("patron_request_tries"):
		state["status"] = PatronRequests.LAPSED
		_apply_booster_delta(str(PatronLevel.patron_bill(patron_bill_id).get("organization", "")),
				-Levers.whole("patron_fail_standing"))
	else:
		state["status"] = PatronRequests.WAITING
	patron_requests[patron_bill_id] = state


## Re-files every composed bill (and the level in progress) with DataDB after a
## load, so the statute book can name them and a resumed level finds its bill.
func _register_saved_patron_bills() -> void:
	DataDB.clear_runtime()
	for patron_bill_id: String in patron_composed:
		var entry: Dictionary = patron_composed[patron_bill_id]
		DataDB.register_runtime_bill(entry.get("bill", {}) as Dictionary, entry.get("component_ids", []) as Array)
	var level: Variant = patron_runtime.get("level")
	if level is Dictionary:
		DataDB.register_runtime_level(level as Dictionary)
	var scene_level: Variant = scene_runtime.get("level")
	if scene_level is Dictionary:
		DataDB.register_runtime_level(scene_level as Dictionary)


## A story about the player's sponsored legislation starts running on the
## Office ticker for `news_ticker_units` clock units.
func record_news(key: String) -> void:
	patron_news[key] = time_units + Levers.whole("news_ticker_units")


## The stories still running (expired ones are dropped).
func active_news() -> Array:
	for key: String in patron_news.keys():
		if int(patron_news[key]) <= time_units:
			patron_news.erase(key)
	return patron_news.keys()


## What ticker rows and Office notices test their conditions against: the
## laws on the books, plus "news:<key>" for each story running.
func ticker_facts() -> Dictionary:
	var facts := law_statuses()
	for key: Variant in active_news():
		facts["news:%s" % str(key)] = "active"
	# Today, for ticker lines gated to days or dates (OfficeTicker.calendar_met).
	var cfg := calendar_config()
	facts["today"] = WeekCalendar.today_number(calendar, cfg)
	facts["weekday"] = WeekCalendar.weekday_index(calendar, cfg)
	facts["office"] = office_location   # a notice or a line can belong to one office (2026-11-20)
	return facts


## Seats a visit or a lobbyist adds to or takes from the vote (BillAssist).
func add_won_over(party_id: String, seats: int = 1) -> void:
	BillAssist.add(bill_assist, "won_over", party_id, seats)


func add_worked_against(party_id: String, seats: int = 1) -> void:
	BillAssist.add(bill_assist, "worked_against", party_id, seats)


## The visit in progress, or {} (the dictionary is the level's own, so changes
## to it are saved with the patron level).
func current_visit() -> Dictionary:
	var level: Variant = patron_runtime.get("level")
	if not (level is Dictionary):
		return {}
	# A drafted bill may have a second visit (2026-11-05): the stage in progress
	# says which one it belongs to; with no stage in progress it is the first.
	var index := 1
	if level_runner != null and not level_runner.is_finished():
		index = int(level_runner.current_stage().get("visit_index", 1))
	var visit: Variant = (level as Dictionary).get(PatronLevel.visit_key(index))
	return visit if visit is Dictionary else {}


## The one-on-one fight was won: the member is won over for this vote.
func _won_over_member() -> void:
	var visit := current_visit()
	if visit.is_empty() or bool(visit.get("won", false)):
		return
	visit["won"] = true
	add_won_over(str(visit.get("party_id", "")), Levers.whole("mp_visit_seats_won"))


## The player declined the visit: both of its stages pass with nothing earned
## (no rewards, no fight, no cost, no time).
func skip_member_visit() -> void:
	if level_runner == null or str(level_runner.current_stage().get("stage_id", "")) != MpVisit.VISIT_STAGE:
		return
	level_runner.finish_stage(LevelRunner.WON)
	if str(level_runner.current_stage().get("stage_id", "")) == MpVisit.FIGHT_STAGE:
		level_runner.finish_stage(LevelRunner.WON)
	SaveManager.autosave(true)


# ---------------------------------------------------------------------------
# The lobbyist trade (influence building step C, 2026-10-19)
# ---------------------------------------------------------------------------

## The trade in progress, or {} (the level's own dictionary, so changes are saved).
func current_trade() -> Dictionary:
	var level: Variant = patron_runtime.get("level")
	if level is Dictionary and (level as Dictionary).get("trade") is Dictionary:
		return (level as Dictionary)["trade"]
	return {}


func _patron_kind() -> String:
	return str(PatronLevel.patron_bill(str(patron_runtime.get("patron_bill_id", ""))).get("kind", PatronRequests.FAVOR))


## The bill's party positions as they stand now (the trade may have recomposed it).
func _bill_positions() -> Array:
	return DataDB.get_bill(str(patron_runtime.get("patron_bill_id", ""))).get("positions", []) as Array


## The player met the lobbyist (or refused to) and no deal was made: on a
## Flagship the lobbyists take seats from the bill (BillAssist worked_against),
## fewer for meeting than for refusing; on a Favor, none by default. Returns
## {"seats", "party_id"}.
func conclude_trade_without_deal(refused: bool) -> Dictionary:
	var trade := current_trade()
	if trade.is_empty() or bool(trade.get("done", false)):
		return {"seats": 0, "party_id": ""}
	trade["done"] = true
	trade["deal"] = false
	var seats := LobbyistTrade.seats_lost(_patron_kind(), refused, DataDB.balance)
	var party_id := LobbyistTrade.party_for_org(str(trade.get("org", "")), DataDB.party_stakeholders, _bill_positions())
	if seats > 0 and not party_id.is_empty():
		add_worked_against(party_id, seats)
	else:
		seats = 0
	return {"seats": seats, "party_id": party_id}


## A deal: `dropped_id` leaves the bill, and the chosen `rewards` (LobbyistTrade
## DONATION, SENTIMENT, PARTY_FAVOR, HELP) are paid, if `leverage` covers them.
## The bill is recomposed without the component and the vote stage is updated.
## Returns {"ok", "gains": [{...}]}; ok is false (nothing changes) when the
## deal is not allowed.
func conclude_trade_deal(dropped_id: String, rewards: Array, leverage: int) -> Dictionary:
	var trade := current_trade()
	var patron_bill_id := str(patron_runtime.get("patron_bill_id", ""))
	if trade.is_empty() or bool(trade.get("done", false)) or not patron_requests.has(patron_bill_id):
		return {"ok": false, "gains": []}
	var state: Dictionary = patron_requests[patron_bill_id]
	var ids: Array = (state.get("components", []) as Array).duplicate()
	if not (trade.get("drops", []) as Array).has(dropped_id) or not ids.has(dropped_id) \
			or not LobbyistTrade.can_close(rewards, leverage, DataDB.balance):
		return {"ok": false, "gains": []}

	var row := PatronLevel.patron_bill(patron_bill_id)
	var org := str(trade.get("org", ""))
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var by_id := ComposedBill.index(DataDB.bill_components)
	var dropped_owner := str((by_id.get(dropped_id, {}) as Dictionary).get("owner", ""))
	var phrase := str((by_id.get(dropped_id, {}) as Dictionary).get("phrase", ""))

	# The party each reward works on is chosen against the bill as it stands.
	var ties := DataDB.party_stakeholders
	var positions := _bill_positions()
	var help_party := LobbyistTrade.party_for_help(org, ties, positions)
	var favor_party_id := LobbyistTrade.party_for_org(org, ties, positions)
	if favor_party_id.is_empty():
		favor_party_id = help_party

	ids.erase(dropped_id)
	var bill := PatronLevel.compose_ids(patron_bill_id, ids)
	DataDB.register_runtime_bill(bill, ids)
	patron_composed[patron_bill_id] = {"bill": bill, "component_ids": ids}
	state["components"] = ids
	patron_requests[patron_bill_id] = state
	_refresh_vote_stage(patron_bill_id)

	for entry: Dictionary in LobbyistTrade.drop_costs(dropped_owner, str(row.get("organization", "")), ally, DataDB.balance):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))

	var gains: Array = []
	for reward: Variant in rewards:
		match str(reward):
			LobbyistTrade.DONATION:
				var funds := Levers.whole("trade_donation_funds")
				var xp_gain := Levers.whole("trade_donation_xp")
				_apply_meta_reward("Funds", funds)
				_move_xp(xp_gain)
				gains.append({"type": LobbyistTrade.DONATION, "funds": funds, "xp": xp_gain})
			LobbyistTrade.SENTIMENT:
				_apply_booster_delta(org, Levers.whole("trade_sentiment_standing"))
				gains.append({"type": LobbyistTrade.SENTIMENT, "org": org})
			LobbyistTrade.PARTY_FAVOR:
				var party := DataDB.get_party_by_id(favor_party_id)
				if not party.is_empty():
					apply_floor_vote_favorability({str(party.get("name", "")): Levers.whole("trade_party_favor")})
					gains.append({"type": LobbyistTrade.PARTY_FAVOR, "party": str(party.get("name", ""))})
			LobbyistTrade.HELP:
				var seats := Levers.whole("trade_help_seats")
				if not help_party.is_empty():
					add_won_over(help_party, seats)
					gains.append({"type": LobbyistTrade.HELP, "count": seats})
	trade["done"] = true
	trade["deal"] = true
	return {"ok": true, "gains": gains, "dropped": phrase}


## The vote stage was built when the level began; after a trade it must carry
## the recomposed bill.
func _refresh_vote_stage(patron_bill_id: String) -> void:
	if level_runner == null:
		return
	for stage: Dictionary in level_runner.stages:
		if str(stage.get("mode", "")) == "Vote":
			stage["floor_vote"] = BattleSetup.enriched_floor_vote(DataDB.get_bill(patron_bill_id))


## Which stage a checkpoint belongs to: the level, the place in it and the
## stage, so a save point is never applied to a different fight.
## The player resigns (2026-11-11, Cameron): the run ends on the spot and its
## save is deleted, so Continue is gone. Nothing saves again until a new run
## starts (awaiting_new_game). A manual backup, if the player made one, stays.
func resign_run() -> void:
	level_runner = null
	mid_stage = false
	stage_checkpoint = {}
	pending_stage_result = {}
	if SaveManager.enabled:
		SaveManager.delete_save()
	awaiting_new_game = true


## Notes that the stage in front of the player has ended, and saves it, so the
## result survives the app being closed before the result panel is dismissed.
## `args` are finish_stage()'s arguments by name (see BattleScreen).
func record_pending_stage_result(args: Dictionary) -> void:
	if level_runner == null:
		return
	var noted := args.duplicate(true)
	noted["key"] = stage_checkpoint_key()
	pending_stage_result = noted
	SaveManager.save_checkpoint()


## The recorded result if it belongs to the stage now in front of the player,
## else empty. Does not clear it: finish_stage() does.
func pending_result_for_current_stage() -> Dictionary:
	if pending_stage_result.is_empty() or level_runner == null:
		return {}
	if str(pending_stage_result.get("key", "")) != stage_checkpoint_key():
		pending_stage_result = {}
		return {}
	return pending_stage_result


func stage_checkpoint_key() -> String:
	if level_runner == null:
		return ""
	return "%s:%d:%s" % [str(level_runner.level.get("level_id", "")), level_runner.index,
		str(level_runner.current_stage().get("stage_id", ""))]


# ---------------------------------------------------------------------------
# Two offices (2026-11-20, Cameron): the Capitol and a District office.
# A level starts only at its own office (Either levels from both); a trip
# between the offices costs hours from the same week as everything else; a
# "mixed" level has its trips built in and charges them with its own hours.
# The rules are in Offices and Travel (pure); this is the run's side of them.
# ---------------------------------------------------------------------------

## The town or neighborhood of this protagonist's District office ("Noheji"); "" if the data has none.
func district_office_name() -> String:
	return str(DataDB.player.get("district_office", ""))


## One-way hours for `mode` for this protagonist; -1 when they do not have that mode.
func trip_hours(mode: String = Travel.PASS) -> int:
	return Travel.hours(DataDB.balance, protagonist_id, mode)


## The modes this player can travel by now: the member's rail pass always, and a paid train ticket or this
## protagonist's fast mode (a private car, or a plane ticket for PC04) while they hold one.
func travel_modes() -> Array[String]:
	var modes: Array[String] = [Travel.PASS]
	for mode: String in [Travel.TICKET, Travel.fast_mode(DataDB.balance, protagonist_id)]:
		if not mode.is_empty() and travel_tickets(mode) > 0:
			modes.append(mode)
	return modes


## Whether a Shop item is sold to this protagonist (Offered For blank means everyone).
func item_offered(item: Dictionary) -> bool:
	var offered: Variant = item.get("offered_for")
	return not (offered is Array) or (offered as Array).is_empty() or (offered as Array).has(protagonist_id)


## The Shop item that pays for a travel mode, or "" for the rail pass (free) and a mode nothing pays for.
func travel_item_id(mode: String) -> String:
	if mode == Travel.PASS:
		return ""
	for item: Dictionary in DataDB.shop:
		if str(item.get("travel_mode", "")) == mode and item_offered(item):
			return str(item.get("item_id", ""))
	return ""


## How many trips by `mode` the player has paid for (tickets held).
func travel_tickets(mode: String) -> int:
	var id := travel_item_id(mode)
	return item_count(id) if not id.is_empty() else 0


## Pays for `uses` trips by `mode`: that many tickets are handed over, and each use applies the ticket's own
## standing grants (the paid train ticket: +2 with three organizations). The rail pass costs nothing.
func _use_travel_tickets(mode: String, uses: int) -> void:
	var id := travel_item_id(mode)
	if id.is_empty():
		return
	var item := DataDB.get_shop_item(id)
	for _i in uses:
		if item_count(id) <= 0:
			break
		_take_item(id)
		var split := Items.split_grants(item)
		var cause_before := _cause
		_cause = Text.say("record.cause_item", {"item": str(item.get("name", id))})
		_apply_reward_entries(split["meta"], "", 0)
		_cause = cause_before


## An encounter on the train, or "": one trip in `travel_encounter_one_in` by the rail pass or a paid ticket (a car
## or a plane skips it). Real-click tests turn chance events off with COP_NO_RANDOM_EVENTS.
func roll_travel_encounter(mode: String) -> String:
	if mode == Travel.CAR or mode == Travel.PLANE or OS.has_environment("COP_NO_RANDOM_EVENTS"):
		return ""
	var one_in := Levers.whole("travel_encounter_one_in")
	if one_in <= 0 or randi_range(1, one_in) != 1:
		return ""
	var pool := EventEngine.train_events(DataDB.events)
	return str(EventEngine.pick_weighted(pool, randf()).get("event_id", ""))


## The encounter a trip just brought, said once and forgotten ("" when none).
func take_travel_encounter() -> String:
	var found := travel_encounter
	travel_encounter = ""
	return found


## Why a trip cannot be taken now, as a sentence; "" when it can.
func travel_refusal(mode: String = Travel.PASS) -> String:
	var hours := trip_hours(mode)
	if mode != Travel.PASS and travel_tickets(mode) < 1:
		return Text.say("travel.refuse_no_ticket", {"mode": TravelText.mode_name(mode).to_lower()})
	var why := Travel.refusal({
		"in_level": is_in_level(), "weekend": in_weekend(),
		"travel_at_weekend": bool(DataDB.get_rule("travel_at_weekend", false)),
		"hours_left": work_hours_left(), "trip_hours": hours,
	})
	match why:
		Travel.REFUSE_IN_LEVEL:
			return Text.say("travel.refuse_in_level")
		Travel.REFUSE_WEEKEND:
			return Text.say("travel.refuse_weekend")
		Travel.REFUSE_HOURS:
			return Text.say("travel.refuse_hours", {"count": hours})
	return ""


## Takes the trip: spends its hours (so promise deadlines keep running, as decided), crosses to the other
## office and saves. False, changing nothing, when it is refused.
func travel(mode: String = Travel.PASS) -> bool:
	if not travel_refusal(mode).is_empty():
		return false
	spend_hours(trip_hours(mode))
	_use_travel_tickets(mode, 1)
	office_location = Offices.other(office_location)
	travel_encounter = roll_travel_encounter(mode)
	SaveManager.autosave()
	return true


## True when `level` (or anything with a Location) can be started where the player stands.
func level_at_this_office(level: Dictionary) -> bool:
	return Offices.is_here(level.get("location"), office_location)


## Why `level` cannot start at this office, as a sentence; "" when it can.
func level_office_refusal(level: Dictionary) -> String:
	if level_at_this_office(level):
		return ""
	if Offices.normalize(level.get("location")) == Offices.CAPITOL:
		return Text.say("travel.refuse_elsewhere_capitol")
	return Text.say("travel.refuse_elsewhere_district")


## The hours a level's built-in trips add at `mode` (0 when it has none).
func level_trip_hours(level: Dictionary, mode: String = Travel.PASS) -> int:
	return Travel.level_hours(level, DataDB.balance, protagonist_id, mode)


## A level's own hours plus its built-in trips at `mode`: what it takes from the week.
func level_total_hours(level: Dictionary, mode: String = Travel.PASS) -> int:
	return level_hours(level) + level_trip_hours(level, mode)


## Why a level's trips cannot be paid by `mode`: fewer tickets than trips. "" for the rail pass or enough tickets.
func level_travel_refusal(level: Dictionary, mode: String) -> String:
	var trips := Travel.level_trips(level)
	if trips == 0 or mode == Travel.PASS or travel_tickets(mode) >= trips:
		return ""
	return Text.say("briefing.refuse_tickets", {"count": trips, "mode": TravelText.mode_name(mode).to_lower()})


## The ways to pay for a mixed level's trips, for the briefing's row: [ { mode, hours, enough } ].
func level_travel_options(level: Dictionary) -> Array:
	var options: Array = []
	if Travel.level_trips(level) == 0:
		return options
	for mode: String in travel_modes():
		options.append({"mode": mode, "hours": level_trip_hours(level, mode), "owned": travel_tickets(mode),
			"enough": level_travel_refusal(level, mode).is_empty()})
	return options


## Charges a level's built-in trips as it begins: their hours come off the week, and the level remembers where
## the player started and how many trips it has, so it can end them at the right office. Call before begin_level.
func pay_level_travel(level: Dictionary, mode: String = Travel.PASS) -> void:
	var trips := Travel.level_trips(level)
	if trips == 0:
		level_travel = {}
		return
	spend_hours(level_trip_hours(level, mode))
	_use_travel_tickets(mode, trips)
	level_travel = {"start": office_location, "trips": trips}


## A level that had built-in trips is over (or abandoned): the player is where its trips left them.
func _arrive_after_level() -> void:
	if level_travel.is_empty():
		return
	office_location = Offices.end_office(str(level_travel.get("start", office_location)), int(level_travel.get("trips", 0)))
	level_travel = {}


## A Dated event that belongs to one office opens the week there: the player is taken to it, at the Balance
## row's hours (0 = free). True when it moved them.
func arrive_for_event(event: Dictionary) -> bool:
	last_evening_trip = {}
	var office := event_office(event)
	if office == Offices.EITHER or office == office_location:
		return false
	var cost := Levers.whole("travel_forced_hours")
	if cost > 0:
		spend_hours(cost)
	# A Mandatory Decision! scene sends the staff to bring the player back the evening before (P15, 2026-11-23, Cameron): no work
	# hours, but the after-hours trip costs XP, all they have up to the Balance cap.
	var scene := decision_scene_of(str(event.get("event_id", "")))
	if not scene.is_empty() and DecisionScenes.is_mandatory(scene):
		var xp_cost := DecisionClash.evening_xp_cost(xp, Levers.whole("evening_travel_xp_cap"))
		last_evening_trip = {"xp": xp_cost, "place": office}
		if xp_cost > 0:
			_move_xp(-xp_cost)
	office_location = office
	return true

