extends Node
## Holds the state of the current run: which level is being played, how far
## through it the player is, where the player's standing sits, and how the
## last level went.
##
## This is the campaign's memory. It is deliberately separate from the rules
## engine, which is the maths of a single battle and remembers nothing.
##
## STILL PARTLY A PLACEHOLDER. Saving to disk and the deck arrive at milestone
## M4. The meta-variables now live here, but only the press conference moves
## them so far — the stage win deltas in the workbook are still unwired.

## The level being played, or null when the player is in the Office.
var level_runner: LevelRunner = null

## How the last finished level went: "win", "loss", or empty if none yet.
## Lives only for this sitting until M4 adds saving.
var last_level_outcome: String = ""

## The player's standing: constituency support, reputation, funds and party
## support, by the English names sanban.json gives them. Seeded from that
## file's starting values and then moved by what happens in a stage.
##
## Lives only for this sitting until M4 adds saving.
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
##
## Lives only for this sitting until M4 adds saving.
## PLAYTEST SETTING. True hands the player every card in the workbook from
## the first moment, so a session can try the whole slate without earning
## it. Cameron asked for the XP and Yen economy to be left aside while he
## prices it by playing, and an unreachable card cannot be playtested.
##
## Set it false and the collection starts at the opening tier again; nothing
## else changes, because the Ledger still refuses anything unaffordable.
var open_collection := true

var owned_cards: Array[String] = []
var deck: Array[String] = []
var owned_modifiers: Array[String] = []

## Where the player stands with each of the ten organisations, by booster ID.
## Pleasing one at a press conference raises it, and it is held between
## levels — unlike the pleased list, which lasts one level.
##
## Lives only for this sitting until M4 adds saving.
var booster_standing: Dictionary = {}

## What the last finished level did to those, e.g. { "BO08": 5 }.
var last_booster_change: Dictionary = {}


func _ready() -> void:
	reset_meta()
	reset_booster_standing()


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}
	xp = 0
	last_xp_gained = 0
	reset_collection()


## Back to the Starter twelve, owned and in the deck.
##
## A new run needs no decisions before the first battle: the opening deck is
## every Starter card, and the deck screen is where the player changes it.
func reset_collection() -> void:
	owned_cards = []
	for card: Dictionary in DataDB.cards:
		if open_collection or str(card.get("tier", "")) == Ledger.OPENING_TIER:
			owned_cards.append(str(card.get("card_id", "")))

	deck = Ledger.opening_deck(DataDB.cards, DataDB.balance)
	owned_modifiers = []


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


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	level_runner = runner
	last_level_outcome = ""
	last_meta_change = {}
	last_xp_gained = 0
	last_booster_change = {}


## True while a level is in progress.
func is_in_level() -> bool:
	return level_runner != null and not level_runner.is_finished()


## Records how a stage went and moves the level on. Returns true when the
## level is now over, which is the battle screen's cue to head back.
func finish_stage(outcome: String, score: int = 0, boosters: Array = []) -> bool:
	if level_runner == null:
		return true

	# What the stage just played did to the player's standing, before the
	# runner moves on and current_stage() becomes the next one.
	_apply_stage_rewards(level_runner.current_stage(), outcome, score)
	_please_organisations(boosters)

	level_runner.finish_stage(outcome, score, boosters)

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()
		if last_level_outcome == LevelRunner.WON:
			_pay_level_rewards()
			_apply_level_bonus_win(level_runner.level)
		return true
	return false


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
		var won := MetaRules.apply_win_deltas(meta, stage, DataDB.sanban)
		meta = won["meta"]
		_record_meta_change(won["applied"])
		last_xp_gained = int(stage.get("win_delta_xp", 0))
		_move_xp(last_xp_gained)

	var scored := MetaRules.apply_score_effects(meta, stage, score, DataDB.sanban)
	meta = scored["meta"]
	_record_meta_change(scored["applied"])


## What the organisations backing you pay out for winning a LEVEL — not a
## single stage. RESOURCE_BONUS_ON_WIN's own workbook wording says "after
## successful completion of a level", so this is called once, when
## finish_stage() sees the level itself is won, rather than after every stage.
##
## Unlike the battle-start effects, this does not care who was in the
## room: a business circle pays for the result, not the audience.
func _pay_level_rewards() -> void:
	var owned: Array = []
	for mod_id: String in owned_modifiers:
		var modifier := DataDB.get_modifier(mod_id)
		if not modifier.is_empty():
			owned.append(modifier)
	if owned.is_empty():
		return

	# XP first — it is not a sanban row, so it goes through _move_xp rather
	# than the clamp-and-record path the other three share.
	var xp_bonus := ModifierEffects.level_win_resource_bonus(owned, "XP")
	if xp_bonus != 0:
		_move_xp(xp_bonus)
		last_xp_gained += xp_bonus

	for name: String in ["Funds", "Constituency support", "Party support"]:
		var bonus := ModifierEffects.level_win_resource_bonus(owned, name)
		if bonus == 0:
			continue
		var variable := _sanban_row(name)
		var before := int(meta.get(name, 0))
		var after := MetaRules.clamp_meta(before + bonus, variable)
		meta[name] = after
		_record_meta_change({name: after - before})


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
		var amount := _roll_range(level.get(key))
		if amount == 0:
			continue
		var name: String = RANGE_TO_META[key]
		var variable := _sanban_row(name)
		var before := int(meta.get(name, 0))
		var after := MetaRules.clamp_meta(before + amount, variable)
		meta[name] = after
		_record_meta_change({name: after - before})

	var xp_amount := _roll_range(level.get("bonus_win_range_xp"))
	if xp_amount != 0:
		_move_xp(xp_amount)
		last_xp_gained += xp_amount

	var low := int(DataDB.booster_standing.get("min", 0))
	var high := int(DataDB.booster_standing.get("max", 100))
	for n in range(1, 17):
		var booster_id := "BO%02d" % n
		var amount := _roll_range(level.get("win_delta_bo%02d" % n))
		if amount == 0:
			continue
		var before := int(booster_standing.get(booster_id, 50))
		var after := clampi(before + amount, low, high)
		booster_standing[booster_id] = after
		if after != before:
			last_booster_change[booster_id] = int(last_booster_change.get(booster_id, 0)) + (after - before)


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
	var low := int(DataDB.booster_standing.get("min", 0))
	var high := int(DataDB.booster_standing.get("max", 100))

	for booster_id: String in boosters:
		var before := int(booster_standing.get(booster_id, 50))
		var after := clampi(before + step, low, high)
		booster_standing[booster_id] = after
		if after != before:
			last_booster_change[booster_id] = after - before


## Clears the level, on the way back to the Office.
func end_level() -> void:
	level_runner = null
