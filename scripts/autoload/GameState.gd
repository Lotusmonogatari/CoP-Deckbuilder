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

## Experience earned so far, and by the stage just finished.
##
## CLAUDE.md puts the XP checkpoint at milestone M5, so nothing spends this
## yet. It is banked rather than discarded so the checkpoint has a real
## number to open with, and so a stage's win_delta_xp stops being a column the
## workbook exports and no code has ever read.
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

## The inventory: shop items (SHxx) held and how many of each, e.g.
## { "SH04": 2 }. Filled by buying in the Office's Supplies shop and by an
## Office Hours visitor's reward; emptied one at a time by the Use button in
## the Office or during a stage. See design/proposals/inventory.md.
var inventory: Dictionary = {}

## How many of each item have been bought during the current level. An
## item's Purchase Limit is checked against this; it resets when a level
## concludes, win or loss.
var shop_bought_this_level: Dictionary = {}

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

## Where the player stands with each of the ten organisations, by booster ID.
## Pleasing one at a press conference raises it, and it is held between
## levels — unlike the pleased list, which lasts one level.
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

## Who is hired into each of the three Staff roles, and at what tier:
## { "Policy Research Assistant": { "staff_id": "SF04", "tier": 1 }, ... }.
## A role with no entry is vacant, either because nobody has ever been
## hired into it or because its hire was fired (see staff_fired below and
## fire_staff()) — see Ledger.gd's Staff section and
## hire_staff()/upgrade_staff()/fire_staff().
var staff_hired: Dictionary = {}

## Every staff_id ever fired this run, { "SF04": true, ... }. Firing costs a
## severance (Ledger.staff_firing_cost()) and is permanent, Cameron's call,
## 2026-09-25 (design/proposals/staff_firing.md): a fired candidate never
## appears hireable again for the rest of this run, so the Recruitment shop
## checks this before listing anyone as a candidate.
var staff_fired: Dictionary = {}

## Level IDs the player has paid XP to unlock — only meaningful once
## rules.json's "level_gating_enabled" is true. A level whose relevant
## unlock_cost_* is already 0 does not need an entry here to be playable; see
## Ledger.is_level_unlocked().
var levels_unlocked: Array[String] = []

## How many levels have been FINISHED so far this sitting — win or loss both
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

## Same shape, for the Party Steering Committee check-in (ST22).
var steering_committee_active := false

## Same shape, for the Funding Freeze (M32) — tracked here purely to detect
## the edge for the Office alert; the freeze's actual enforcement
## (MetaRules.party_support_modifiers()) is checked live and needs no latch.
var funding_frozen_active := false

## News from the level just finished, for the Office to show once and
## forget — NOT in _SAVED_FIELDS on purpose, the same lifetime as
## last_level_outcome/last_meta_change. Each entry is
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


func _ready() -> void:
	protagonist_id = str(DataDB.player.get("player_id", ""))
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()


## A fresh run as `player_id`: every number back to its start. False, and
## nothing changes, when there is no such protagonist.
func start_new_run(player_id: String) -> bool:
	if not DataDB.use_protagonist(player_id):
		return false
	protagonist_id = player_id
	level_runner = null
	last_level_outcome = ""
	mid_stage = false
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()
	awaiting_new_game = false
	return true


# ---------------------------------------------------------------------------
# Saving
# ---------------------------------------------------------------------------
# One list of what a run is, used both ways, so a field added to the run and
# forgotten here is forgotten in both directions and caught by the round-trip
# test rather than half-saved.

const _SAVED_FIELDS := [
	"protagonist_id", "last_level_outcome", "meta", "xp",
	"owned_cards", "deck", "owned_modifiers",
	"inventory", "shop_bought_this_level",
	"pending_stage_bonuses", "pending_level_bonuses", "level_bonuses",
	"booster_standing", "segment_favorability", "staff_hired", "staff_fired",
	"levels_unlocked", "levels_completed_count", "level_last_completed_at",
	"town_hall_active", "steering_committee_active", "funding_frozen_active",
	"stage_type_results", "lifetime_gaffes", "stages_lost_to_gaffes",
	"gaffe_penalty_applied",
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

	for field: String in _SAVED_FIELDS:
		if not saved.has(field) or field == "protagonist_id":
			continue
		var current: Variant = get(field)
		var value: Variant = saved[field]
		if current is Array and value is Array:
			(current as Array).assign(value)   # keeps Array[String] typed
		elif typeof(current) == typeof(value):
			set(field, value)

	var runner: Variant = saved.get("level_runner")
	level_runner = LevelRunner.restored(runner) if runner is Dictionary else null
	if level_runner != null and level_runner.is_finished():
		level_runner = null


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}
	xp = BattleSetup.starting_xp()
	last_xp_gained = 0
	reset_collection()
	reset_staff()
	reset_levels()
	reset_crisis_triggers()


## Every crisis trigger back to its rest state, and the lifetime counters
## back to zero, for a fresh run.
func reset_crisis_triggers() -> void:
	town_hall_active = false
	steering_committee_active = false
	funding_frozen_active = false
	pending_trigger_alerts = []
	stage_type_results = {}
	lifetime_gaffes = 0
	stages_lost_to_gaffes = 0
	gaffe_penalty_applied = false


## Every Staff role back to vacant, and every firing forgotten.
func reset_staff() -> void:
	staff_hired = {}
	staff_fired = {}


## Every level back to locked-by-its-price and off cooldown.
func reset_levels() -> void:
	levels_unlocked = []
	levels_completed_count = 0
	level_last_completed_at = {}


## Back to the Starter twelve, owned and in the deck.
##
## A new run needs no decisions before the first battle: the opening deck is
## every Starter card, and the deck screen is where the player changes it.
func reset_collection() -> void:
	owned_cards = []

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
	shop_bought_this_level = {}
	pending_stage_bonuses = {}
	pending_level_bonuses = {}
	level_bonuses = {}


# ---------------------------------------------------------------------------
# Spending
# ---------------------------------------------------------------------------
# Every purchase goes through the Ledger first, so a screen cannot spend
# what the rules would have refused. Each returns the refusal reason, or an
# empty string when it went through.

## Spends XP on a card. The card joins the collection, not the deck: what
## you take in is a separate decision, made on the deck screen.
func buy_card(card_id: String) -> String:
	var card := DataDB.get_card(card_id)
	var refusal := Ledger.card_refusal(card, owned_cards, xp, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_xp(-Ledger.card_cost(card))
	owned_cards.append(card_id)
	return ""


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


## Spends an organisation's activation cost (Funds, and since 2026-09-22
## sometimes Reputation and/or Constituency support too) on its backing.
func buy_modifier(mod_id: String) -> String:
	var modifier := DataDB.get_modifier(mod_id)
	var refusal := Ledger.modifier_refusal(modifier, owned_modifiers,
		meta, booster_standing, DataDB.booster_standing,
		DataDB.boosters, Text.phrase())
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
	return ""


## Hires a candidate into their role, spending Funds, if the role is vacant
## and the price is affordable. Immediately applies whichever tier_N_reward
## matches the tier they START at (candidates do not all start at tier 0 —
## SF05 and SF07 start at tier 1).
func hire_staff(staff_id: String) -> String:
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return "Unknown staff candidate."

	var role := str(candidate.get("role", ""))
	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_hire_refusal(candidate, staff_hired.get(role, {}),
		bool(staff_fired.get(staff_id, false)), funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -int(candidate.get("hiring_cost_yen", 0)))
	var starting_tier := int(candidate.get("starting_tier", 0))
	staff_hired[role] = {"staff_id": staff_id, "tier": starting_tier}
	_apply_staff_reward(candidate, starting_tier)
	return ""


## Upgrades a role's hired candidate to the next tier, spending Funds, if that
## step exists for them and is affordable. Applies the new tier's reward on
## top of whatever hiring (and any earlier upgrade) already gave — these are
## one-time bonuses per tier reached, not a repeating income, the same way a
## modifier's RESOURCE_BONUS_ON_WIN tier is a flat payment rather than a rate
## (see ModifierEffects.gd).
func upgrade_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return "Nobody is hired for this role yet."

	var candidate := DataDB.get_staff(str(hired.get("staff_id", "")))
	if candidate.is_empty():
		return "Unknown staff candidate."

	var tier := int(hired.get("tier", 0))
	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_upgrade_refusal(candidate, tier, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	var cost := int(Ledger.staff_upgrade_cost(candidate, tier))
	_move_meta("Funds", -cost)

	var new_tier := tier + 1
	hired["tier"] = new_tier
	staff_hired[role] = hired
	_apply_staff_reward(candidate, new_tier)
	return ""


## Fires a role's hired candidate, spending a severance (Ledger.
## staff_firing_cost()) from Funds. The role goes vacant and can be filled
## with a different candidate right away — but not with this one: whatever
## the hire and every upgrade already paid out (Funds spent, standing and
## favourability gained) stands; nothing is refunded or clawed back, and the
## fired candidate is marked in staff_fired so they never appear hireable
## again this run. Cameron's decision, 2026-09-25
## (design/proposals/staff_firing.md).
func fire_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return "Nobody is hired for this role yet."

	var staff_id := str(hired.get("staff_id", ""))
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return "Unknown staff candidate."

	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_fire_refusal(candidate, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -Ledger.staff_firing_cost(candidate))
	staff_hired.erase(role)
	staff_fired[staff_id] = true
	return ""


## A staff tier's reward, applied the moment it is reached (on hire, and
## again on every upgrade that reaches a new tier).
##
## Each reward is {"delta": int, "target": "BOxx or SGxx"}.
func _apply_staff_reward(candidate: Dictionary, tier: int) -> void:
	var rewards: Variant = candidate.get("tier_%d_reward" % tier)
	if not (rewards is Array):
		return

	for reward: Variant in rewards:
		if not (reward is Dictionary):
			continue
		var target := str((reward as Dictionary).get("target", ""))
		var delta := int((reward as Dictionary).get("delta", 0))
		if target.begins_with("BO"):
			_apply_booster_delta(target, delta)
		elif target.begins_with("SG"):
			_apply_segment_delta(target, delta)


## Replaces the deck, if the new one is legal.
func set_deck(chosen: Array[String]) -> String:
	var refusal := Ledger.deck_refusal(chosen, owned_cards, DataDB.balance, Text.phrase())
	if not refusal.is_empty():
		return refusal

	deck = chosen.duplicate()
	return ""


## Every organisation back to where booster_standing.json starts them.
func reset_booster_standing() -> void:
	booster_standing = {}
	last_booster_change = {}

	var start := int(DataDB.booster_standing.get("start", 50))
	for booster: Dictionary in DataDB.boosters:
		booster_standing[str(booster.get("booster_id"))] = start


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


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	level_runner = runner
	mid_stage = false
	last_level_outcome = ""
	last_meta_change = {}
	last_xp_gained = 0
	last_booster_change = {}

	# A level buff used in the Office now runs for every stage of this level.
	level_bonuses = pending_level_bonuses.duplicate()
	pending_level_bonuses = {}


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
func finish_stage(outcome: String, score: int = 0, boosters: Array = [],
		gaffe_caused_loss: bool = false, gaffes: int = 0) -> bool:
	mid_stage = false
	if level_runner == null:
		return true

	var stage := level_runner.current_stage()
	_record_stage_type_result(str(stage.get("stage_id", "")), outcome)
	_record_lifetime_gaffes(gaffes, outcome, gaffe_caused_loss)

	# What the stage just played did to the player's standing, before the
	# runner moves on and current_stage() becomes the next one.
	_apply_stage_rewards(stage, outcome, score)
	_please_organisations(boosters)

	level_runner.finish_stage(outcome, score, boosters)

	# Funding freeze has nothing to insert into the queue, so both its edges
	# are always checked — a level ending on this very stage doesn't stop
	# the player finding out their money is frozen (or freed) once they're
	# back in the Office. Town Hall/Steering Committee insert a stage, so
	# their own checks internally skip entering a zone when there is
	# nowhere left to put one (level_runner.is_finished()) — leaving a zone
	# never needs anywhere to put anything, so that half always fires.
	_check_funding_freeze()
	var level_id := str(level_runner.level.get("level_id", ""))
	_check_town_hall(level_id)
	_check_steering_committee(level_id)

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()

		# Cooldown counts every completion, win or loss (see the comment on
		# levels_completed_count) — recorded here regardless of which way
		# last_level_outcome comes out, right where the level as a whole (not
		# just the stage just played) is known to be over.
		if not level_id.is_empty():
			levels_completed_count += 1
			level_last_completed_at[level_id] = levels_completed_count

		# The level has concluded, success or failure: each Supplies item's
		# Purchase Limit starts counting again, and level buffs run out.
		_conclude_level_items()

		if last_level_outcome == LevelRunner.WON:
			_pay_level_rewards()
			_apply_level_bonus_win(level_runner.level)
		SaveManager.autosave()
		return true
	SaveManager.autosave()
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
	var threshold := int(DataDB.balance.get("gaffes_lifetime_penalty_threshold", 50))
	if lifetime_gaffes < threshold:
		return

	gaffe_penalty_applied = true
	var delta := int(DataDB.balance.get("gaffes_lifetime_penalty_jiban_delta", -15))
	_move_meta("Constituency support", delta)
	pending_trigger_alerts.append({"kind": "gaffe_penalty", "edge": "entered",
		"count": lifetime_gaffes, "amount": absi(delta)})


## Funding freeze inserts nothing, so both edges always fire — there is no
## "nowhere to put it" case the way there is for a forced-in stage.
func _check_funding_freeze() -> void:
	var frozen := MetaRules.funding_frozen(int(meta.get("Party support", 0)), DataDB.balance)
	if frozen and not funding_frozen_active:
		funding_frozen_active = true
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "entered"})
	elif not frozen and funding_frozen_active:
		funding_frozen_active = false
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "left"})


## Inserts ST05 the moment Jiban first crosses the Town Hall threshold, and
## says nothing further until Jiban has climbed back out again — losing the
## inserted Town Hall while Jiban is still low must not immediately queue
## a second one (Cameron, 2026-09-25). Entering with nowhere left to put a
## stage (the level just ended) simply does nothing this call; the same
## check runs again at the next finish_stage(), in the level after this one.
func _check_town_hall(level_id: String) -> void:
	var jiban := int(meta.get("Constituency support", 0))
	var triggered := MetaRules.town_hall_triggered(jiban, DataDB.balance)
	if triggered and not town_hall_active:
		if level_runner == null or level_runner.is_finished():
			return
		level_runner.insert_stage(BattleSetup.build_inserted_stage(level_id, "ST05"), level_runner.index)
		town_hall_active = true
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "entered", "count": jiban})
	elif not triggered and town_hall_active:
		town_hall_active = false
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "left"})


## Same shape as _check_town_hall(), for the Party Steering Committee
## check-in (ST22, Non-combat, VI04 — see design's Part D) forced in when
## party support falls below its own threshold.
func _check_steering_committee(level_id: String) -> void:
	var party_support := int(meta.get("Party support", 0))
	var triggered := MetaRules.steering_committee_triggered(party_support, DataDB.balance)
	if triggered and not steering_committee_active:
		if level_runner == null or level_runner.is_finished():
			return
		level_runner.insert_stage(BattleSetup.build_inserted_stage(level_id, "ST22"), level_runner.index)
		steering_committee_active = true
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "entered", "count": party_support})
	elif not triggered and steering_committee_active:
		steering_committee_active = false
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "left"})


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
	last_meta_change = {}
	last_xp_gained = 0
	if stage.is_empty():
		return

	# Losing a stage earns nothing. A score the player reached on the way to
	# losing still is not a result.
	# 2026-09-22 workbook: xp_reward was renamed win_delta_xp, alongside the
	# other stage win_delta_* columns MetaRules.apply_win_deltas already reads.
	if outcome == LevelRunner.WON:
		var reward_stage := stage
		# Funding Freeze (M32) — party support at or below the Balance tab's
		# own threshold. Zeroed at the source rather than undone afterward,
		# so this is the one and only place Funds income can be frozen; XP
		# and every other win delta are untouched.
		if "M32" in MetaRules.party_support_modifiers(int(meta.get("Party support", 0)), DataDB.balance):
			reward_stage = stage.duplicate(true)
			reward_stage["win_delta_yen"] = 0
		var won := MetaRules.apply_win_deltas(meta, reward_stage, DataDB.sanban)
		meta = won["meta"]
		_record_meta_change(won["applied"])
		last_xp_gained = int(stage.get("win_delta_xp", 0))
		_move_xp(last_xp_gained)

	var scored := MetaRules.apply_score_effects(meta, stage, score, DataDB.sanban)
	meta = scored["meta"]
	_record_meta_change(scored["applied"])


## owned_modifiers, plus whichever of M09 (Party Backing)/M10 (Cold
## Shoulder) party_support_modifiers() currently grants for free — CLAUDE.md
## §8: "> 75 gives M09, < 50 gives M10", never added to owned_modifiers
## itself, so losing the standing later correctly turns the free grant back
## off and buying one yourself is never made pointless by already having it
## free. M32 (Funding Freeze) is deliberately excluded here: it is a
## penalty enforced directly in _apply_stage_rewards(), not a bonus a
## reward-paying function should ever hand out.
func _effectively_owned_modifiers() -> Array:
	var mod_ids: Array[String] = owned_modifiers.duplicate()
	for mod_id: String in MetaRules.party_support_modifiers(int(meta.get("Party support", 0)), DataDB.balance):
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
	# M10's own effect (UNLOCK_DISCOUNT) has no consumer anywhere in the
	# project yet — a pre-existing gap, not one this wiring pass opened —
	# so granting M10 free changes nothing observable today. M09's
	# RESOURCE_BONUS_ON_WIN is the one of the two this function actually
	# pays out.
	var owned := _effectively_owned_modifiers()
	if owned.is_empty():
		return

	# XP first — it is not a sanban row, so it goes through _move_xp rather
	# than the clamp-and-record path the other three share.
	var xp_bonus := ModifierEffects.level_win_resource_bonus(owned, "XP")
	if xp_bonus != 0:
		_move_xp(xp_bonus)
		last_xp_gained += xp_bonus

	for name: String in ["Funds", "Constituency support", "Party support"]:
		_apply_meta_reward(name, ModifierEffects.level_win_resource_bonus(owned, name))


## The level's own "bonus_win_range_*" and "win_delta_bo01..16" columns,
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
	const RANGE_TO_META := {
		"bonus_win_range_jiban": "Constituency support",
		"bonus_win_range_yen": "Funds",
		"bonus_win_range_reputation": "Reputation",
		"bonus_win_range_party_support": "Party support",
	}
	for key: String in RANGE_TO_META.keys():
		_apply_meta_reward(RANGE_TO_META[key], _roll_range(level.get(key)))

	var xp_amount := _roll_range(level.get("bonus_win_range_xp"))
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
		var key := "win_delta_" + booster_id.to_lower()
		_apply_booster_delta(booster_id, _roll_range(level.get(key)))


## A stage or level reward to one meta-variable: clamped, and filed under
## what the last stage was worth.
func _apply_meta_reward(name: String, amount: int) -> void:
	if amount == 0:
		return
	var before := int(meta.get(name, 0))
	var after := MetaRules.clamp_meta(before + amount, _sanban_row(name))
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


func _sanban_row(name: String) -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == name:
			return row
	return {"min": 0, "max": 999, "start": 0}


## Earns or spends XP, and says so.
##
## Every change to the total goes through here so that nothing can move it
## quietly. The shop screens want to know the moment it changes, and so will
## anything that wants to make a sound about it.
func _move_xp(delta: int) -> void:
	if delta == 0:
		return
	xp += delta
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
	var after := MetaRules.clamp_meta(before + delta, _sanban_row(name))
	if after == before:
		return

	meta[name] = after
	EventBus.meta_changed.emit(name, after, after - before)


## Folds one lot of changes into what the screen will report.
##
## A stage can move the same variable twice — a flat reward for winning and
## again for the score it closed on — and the player should be told the
## total, not shown the second overwriting the first.
func _record_meta_change(applied: Dictionary) -> void:
	for name: String in applied.keys():
		last_meta_change[name] = int(last_meta_change.get(name, 0)) + int(applied[name])
		# Announced as well as recorded. The recording is for the result
		# screen, which asks afterwards; the announcement is for anything that
		# wants to react as it happens — a sound, or the Office lighting up a
		# number that just moved.
		if int(applied[name]) != 0:
			EventBus.meta_changed.emit(name, int(meta.get(name, 0)), int(applied[name]))


## Raises the player's standing with everyone pleased in a stage.
##
## Standing is what survives the level; the pleased list is what the floor
## debate draws on inside it. The two are separate on purpose: pleasing the
## same organisation twice in one level counts once for the floor debate, and
## once for the standing too, because the pleased list is deduplicated before
## it ever gets here.
func _please_organisations(boosters: Array) -> void:
	if boosters.is_empty():
		return

	var step := int(DataDB.booster_standing.get("per_please", 5))
	for booster_id: String in boosters:
		_apply_booster_delta(booster_id, step)


## Office Hours (design/proposals/office_hours.md): applies one visitor's
## Reward column (on a correct answer) or Penalty column (on a wrong one) —
## OfficeHoursEngine.answer() hands back the raw, unresolved list exactly as
## stored on the visitor (it has no DataDB access, same as every other rules
## class), so resolving each target's real kind and record, and rolling any
## range delta, both happen here, once, at the moment the reward is actually
## applied — not shown to the player as a range and not rolled earlier at
## setup (open point 5 in the proposal).
func apply_visitor_reward_entries(entries: Array) -> void:
	_apply_reward_entries(entries)


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
func _apply_reward_entries(entries: Array, chosen_target: String = "", extra_delta: int = 0) -> void:
	for raw: Variant in entries:
		if not (raw is Dictionary):
			continue
		var entry := _choose_target(raw, chosen_target)
		var resolved := DataDB.resolve_reward_target(entry)
		var kind: String = resolved.get("kind", "")
		var target_id: String = resolved.get("id", "")
		match kind:
			RewardTargets.BOOSTER:
				_apply_booster_delta(target_id, _resolve_delta(resolved.get("delta")) + extra_delta)
			RewardTargets.BOOSTER_TIER:
				# Only reached when nothing was chosen — a chosen target
				# already replaced this with a plain BOOSTER above.
				var pool: Array = (resolved.get("record", {}) as Dictionary).get("boosters", [])
				if not pool.is_empty():
					var picked: Dictionary = pool[randi() % pool.size()]
					_apply_booster_delta(str(picked.get("booster_id", "")),
						_resolve_delta(resolved.get("delta")) + extra_delta)
			RewardTargets.MODIFIER:
				if not owned_modifiers.has(target_id):
					owned_modifiers.append(target_id)
			RewardTargets.SEGMENT:
				_apply_segment_delta(target_id, _resolve_delta(resolved.get("delta")) + extra_delta)
			RewardTargets.SHOP_ITEM:
				# A delta, when given, is how many; a bare "SH04" is one.
				add_item(target_id, maxi(_resolve_delta(resolved.get("delta")), 1))
			RewardTargets.STAGE_EFFECT:
				_add_bonus(pending_stage_bonuses, target_id, _stage_effect_amount(resolved.get("delta")))
			_:
				push_warning("GameState: reward/penalty target '%s' did not resolve to anything." % target_id)


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


## Adds up to `count` of an item, never past its Stack Cap. Returns how many
## actually went in — a visitor's gift beyond the cap is lost, not banked.
func add_item(item_id: String, count: int = 1) -> int:
	var item := DataDB.get_shop_item(item_id)
	var cap := Items.stack_cap(item)
	var room := count if cap <= 0 else clampi(cap - item_count(item_id), 0, count)
	if room > 0:
		inventory[item_id] = item_count(item_id) + room
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


## SH27/28/29 ("Purchase Random Tier N Card"): its own Description says
## "takes effect immediately", and it always did — it just had nowhere to
## do it, since Use In Office/Stage were both blank ("No") and Grants was
## empty, so a bought one only ever sat in the inventory refusing "This
## can't be used here." (Cameron, 2026-09-26). This is that immediate
## effect: pay the same way any shop item does, then grant ownership of one
## random card of shop.json's own "card_tier" that the player does not
## already own — no inventory step at all, unlike every other item here.
##
## Returns { "ok": bool, "message": String }: a refusal (not ok), or what
## to tell the player about which card they got.
func buy_random_card(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	var tier := int(item.get("card_tier", 0))
	var choices: Array[String] = []
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == tier and not owned_cards.has(str(card.get("card_id", ""))):
			choices.append(str(card.get("card_id", "")))
	if choices.is_empty():
		return {"ok": false, "message": Text.say("shop.no_cards_left_at_tier", {"tier": tier})}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	var card_id: String = choices[randi() % choices.size()]
	owned_cards.append(card_id)
	var card_name := str(DataDB.get_card(card_id).get("name_en", card_id))
	return {"ok": true, "message": Text.say("shop.card_unlocked", {"name": card_name})}


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
func use_item_in_office(item_id: String, chosen_target: String = "") -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.use_refusal(item, Items.OFFICE, item_count(item_id), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if Items.is_player_choice(item) and chosen_target.is_empty():
		return {"ok": false, "needs_choice": true}

	_take_item(item_id)
	var split := Items.split_grants(item)
	_apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	var name := str(item.get("name", item_id))
	if (split["stage"] as Array).is_empty():
		return {"ok": true, "message": Text.say("item.used", {"name": name})}

	var level := Items.duration(item) == Items.DURATION_LEVEL
	var target := pending_level_bonuses if level else pending_stage_bonuses
	for effect: Dictionary in _resolve_stage_effects(split["stage"]):
		_add_bonus(target, str(effect["token"]), int(effect["amount"]))
	return {"ok": true, "message": Text.say(
		"item.queued_level" if level else "item.queued", {"name": name})}


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

	_take_item(item_id)
	_apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	if Items.duration(item) == Items.DURATION_LEVEL:
		for effect: Dictionary in effects:
			_add_bonus(level_bonuses, str(effect["token"]), int(effect["amount"]))
	return {"ok": true, "message": Text.say("item.used", {"name": str(item.get("name", item_id))})}


## Everything item-driven the next stage starts with: the level's running
## buffs plus anything used in the Office for "the next stage", which is
## spent by asking. { "ENERGY": 2, ... }.
func take_item_bonuses_for_stage() -> Dictionary:
	var bonuses := level_bonuses.duplicate()
	for token: String in pending_stage_bonuses.keys():
		_add_bonus(bonuses, token, int(pending_stage_bonuses[token]))
	pending_stage_bonuses = {}
	return bonuses


func _take_item(item_id: String) -> void:
	var left := item_count(item_id) - 1
	if left > 0:
		inventory[item_id] = left
	else:
		inventory.erase(item_id)


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
			total += int(row["amount"])
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
		last_booster_change[booster_id] = int(last_booster_change.get(booster_id, 0)) + (after - before)


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
	# Level buffs belong to the level; nothing else here to clear, since
	# finish_stage() already reset the purchase counts when it concluded.
	level_bonuses = {}


func _conclude_level_items() -> void:
	shop_bought_this_level = {}
	level_bonuses = {}
