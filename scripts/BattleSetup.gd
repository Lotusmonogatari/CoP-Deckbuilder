class_name BattleSetup
extends RefCounted
## Builds the configuration a battle needs, out of the game's data files.
##
## WHY THIS EXISTS
## The rules engine in scripts/rules/ is deliberately cut off from everything
## else: it never reads a file and never asks an autoload for anything. That
## separation is what lets the whole of it be tested without the game running.
##
## But something has to fetch the stage, the opponent and the deck and hand
## them over. That is this file's only job. It knows about DataDB, and it
## knows what shape BattleEngine.setup() wants, and nothing else.
##
## It sits at the top of scripts/ rather than in rules/ or ui/, because it is
## neither: putting it in rules/ would break the rule that rules code touches
## no autoloads, and it draws nothing on screen.
##
## USE
##     var config := BattleSetup.for_module_step("MOD01", 4)
##     var engine := BattleEngine.new()
##     engine.setup(config)


## Builds a battle from a row of the module plan — the normal route in.
##
## `meta` is the player's current standing; leave it out and the starting
## values from sanban.json are used, which is what you want before the
## campaign proper exists.
static func for_module_step(module_id: String, seq: int, meta: Dictionary = {}) -> Dictionary:
	for row: Dictionary in DataDB.get_module_steps(module_id):
		if int(row.get("seq", -1)) == seq:
			return from_row(row, meta)

	push_error("BattleSetup: %s has no step %d." % [module_id, seq])
	return {}


## Builds a battle from a stage of the playtest level.
##
## The playtest level describes its own stages rather than pointing at rows
## in the workbook, because its shape is still being tried out and should not
## disturb the canon stages while it settles. The two routes produce the same
## kind of dictionary, so BattleEngine cannot tell them apart.
##
## `buffs` is whatever earlier stages of the level left behind, from
## LevelRunner.carried_buffs().
static func for_playtest_stage(stage: Dictionary, buffs: Dictionary = {},
		meta: Dictionary = {}) -> Dictionary:
	if stage.is_empty():
		return {}

	if meta.is_empty():
		meta = starting_meta()

	var opponents: Array = stage.get("opponents", [])

	var config := {
		"stage": with_audience(stage),
		# The first opponent; the rest arrive as the stage's sequencing is
		# built in phase 3. Until then a stage plays its opening opponent.
		"opponent": opponents[0] if not opponents.is_empty() else {},
		"opponents": opponents,
		"cards": card_table(),
		"affinity": affinity_table(),
		"rules": DataDB.rules,
		"meta": meta,
		"deck": player_deck(),
		# A good caucus earlier in the level starts this stage ahead, and so
		# does an organisation whose backing you have bought.
		"start_adjustment": int(buffs.get("support_bonus", 0))
			+ int(backing_bonus(stage).get("start_support", 0)),
		"starting_gaffe": int(backing_bonus(stage).get("starting_gaffe", 0)),
	}

	return config


## What the organisations backing you are worth in this room.
##
## Backing only counts where the audience it cares about is actually here:
## a friendly beat reporter does nothing in a caucus with no press in it.
## MetaRules.active_modifiers decides that, off the stage's own mix.
static func backing_bonus(stage: Dictionary) -> Dictionary:
	var owned: Array = []
	for mod_id: String in GameState.owned_modifiers:
		var modifier := DataDB.get_modifier(mod_id)
		if not modifier.is_empty():
			owned.append(modifier)

	if owned.is_empty():
		return {"start_support": 0, "starting_gaffe": 0}

	var active := MetaRules.active_modifiers(owned, with_audience(stage), "Player")
	return ModifierEffects.battle_start_bonus(active, DataDB.modifier_effects)


## Fills in who is in the room, where a stage does not say.
##
## Every stage in the workbook carries a segment_mix — how much of the
## audience is Press, Loyalists, Constituents, Donors, Bureaucrats — and the
## hand-written playtest stages carry none, so every card aimed at a
## particular audience currently reads that audience as zero per cent of the
## room.
##
## Rather than invent percentages, a playtest stage borrows the mix of the
## canon stage it already names in affinity_stage_id: the playtest press
## conference is modelled on ST04, so it gets ST04's room. A stage that
## declares its own mix keeps it.
static func with_audience(stage: Dictionary) -> Dictionary:
	if stage.has("segment_mix"):
		return stage

	var modelled_on := str(stage.get("affinity_stage_id", ""))
	if modelled_on.is_empty():
		return stage

	var canon := DataDB.get_stage(modelled_on)
	if not canon.has("segment_mix"):
		return stage

	var filled := stage.duplicate(true)
	filled["segment_mix"] = canon["segment_mix"]
	return filled


## Builds a battle from a module row that has already been looked up.
static func from_row(row: Dictionary, meta: Dictionary = {}) -> Dictionary:
	var stage := DataDB.get_stage(str(row.get("stage_id", "")))
	var opponent := DataDB.get_opponent(str(row.get("opp_id", "")))
	var bill := DataDB.get_bill(str(row.get("bill_id", "")))

	if meta.is_empty():
		meta = starting_meta()

	var config := {
		"stage": stage,
		"opponent": opponent,
		"cards": card_table(),
		"affinity": affinity_table(),
		"rules": DataDB.rules,
		"meta": meta,
		"deck": player_deck(),
		"bill_difficulty": bill_difficulty(bill),
	}

	# Reputation opens a press stage for or against the player. It has no
	# effect anywhere else, so it is only looked up where it applies.
	if str(stage.get("stage_id", "")) in ["ST04", "ST06"]:
		config["start_adjustment"] = MetaRules.press_start_adjustment(
			int(meta.get("Reputation", 50)), DataDB.sanban)

	# A committee stage is played against people rather than a bar, so it
	# needs the member list from the workbook.
	if str(stage.get("stage_id", "")) == "ST01":
		config["committee_members"] = DataDB.get_committee_members(
			str(row.get("module", "")), int(row.get("seq", -1)))

	return config


## How much harder this bill is because of where public opinion sits.
static func bill_difficulty(bill: Dictionary) -> int:
	if bill.is_empty():
		return 0
	var topic := DataDB.get_topic(str(bill.get("topic_id", "")))
	if topic.is_empty():
		return 0
	return MetaRules.bill_difficulty_from_data(bill, topic, DataDB.balance)


## The player's opening deck: every Starter-tier card in the workbook.
##
## There are 12 of them, and balance.json's "starter deck size" is also 12,
## so the two agree today. They are not the same thing though, so if the
## counts ever diverge this says so rather than quietly dealing a wrong deck.
## The deck the player is taking in.
##
## The run's chosen deck where there is one, and the Starter twelve
## otherwise — a battle started outside a run, or before anything has been
## chosen, still deals a playable hand rather than nothing.
static func player_deck() -> Array[String]:
	if GameState.deck.is_empty():
		return starter_deck()
	return GameState.deck.duplicate()


static func starter_deck() -> Array[String]:
	var deck: Array[String] = []
	for card: Dictionary in DataDB.get_cards_by_tier("Starter"):
		deck.append(str(card.get("card_id")))

	# Cards written by hand for the playtest are not the workbook's to count,
	# so they are taken off before comparing. Otherwise adding one to
	# playtest_cards.json would make the workbook look wrong.
	var from_workbook := deck.size()
	for card_id: String in deck:
		if DataDB.playtest_card_ids.has(card_id):
			from_workbook -= 1

	var expected := int(DataDB.get_balance("starter_deck_size", float(from_workbook)))
	if from_workbook != expected:
		push_warning(
			("BattleSetup: the workbook has %d Starter cards but says the starter deck "
			+ "should be %d. Using the %d that exist.") % [from_workbook, expected, deck.size()])

	return deck


## Every card, keyed by ID, for the engine to look up as they are played.
static func card_table() -> Dictionary:
	var table := {}
	for card: Dictionary in DataDB.cards:
		table[str(card.get("card_id"))] = card
	return table


## What each organisation is called, keyed by ID. The rules engine deals in
## IDs; anything shown to the player needs the name.
## Every organisation's ID, so the Ledger can tell a real backer from a
## modifier that names a meta-variable in the same column.
static func booster_ids() -> Array:
	var ids: Array = []
	for booster: Dictionary in DataDB.boosters:
		ids.append(str(booster.get("booster_id")))
	return ids


static func booster_names() -> Dictionary:
	var names := {}
	for booster: Dictionary in DataDB.boosters:
		names[str(booster.get("booster_id"))] = str(booster.get("name_en", ""))
	return names


## The suit-by-stage multipliers, in the shape the engine reads.
static func affinity_table() -> Dictionary:
	var table := {}
	for row: Dictionary in DataDB.affinity:
		table[str(row.get("element"))] = row.get("multipliers", {})
	return table


## The player's standing at the very start of a run, from sanban.json.
static func starting_meta() -> Dictionary:
	var meta := {}
	for variable: Dictionary in DataDB.sanban:
		meta[str(variable.get("name_en"))] = int(variable.get("start", 0))
	return meta
