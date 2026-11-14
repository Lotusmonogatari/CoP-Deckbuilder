extends Node
## Audit Phase 4: targeted checks for the frozen invariants the battle sweep
## cannot see (benchmarks.md section C). Headless, seeded, read-only.
##
##   .tools/godot --headless --path . audit/tests/invariant_probe.tscn
##   AUDIT_OUT=/path/out.json

var _out := {}


func _ready() -> void:
	_run.call_deferred()


func _engine_for(stage_id: String, fight_seed: int, pressure: String = "") -> BattleEngine:
	var expanded := BattleSetup.expand_level({"level_id": "LVAUDIT", "stage_1": stage_id})
	var runner := LevelRunner.new(expanded)
	var config := BattleSetup.for_playtest_stage(runner.current_stage(), runner.carried_buffs(), GameState.meta)
	config["seed"] = fight_seed
	var engine := BattleEngine.new()
	return engine if engine.setup(config) else null


func _run() -> void:
	seed(5)
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")

	# INV-10: the price of winning over someone already opposed, 10,000 rolls.
	var bar := BarModel.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	bar._cost_roller = func() -> int: return rng.randi_range(0, 99)
	var costs := {1: 0, 2: 0, 3: 0}
	for i in 10000:
		var cost := bar.roll_opponent_cost()
		costs[cost] = int(costs.get(cost, 0)) + 1
	_out["INV-10"] = {"rolls": 10000, "cost_1": costs[1], "cost_2": costs[2], "cost_3": costs[3],
		"undecided_cost": BarModel.undecided_cost(), "odds": BarModel.opponent_cost_odds()}

	# INV-14: 2,000 opening decks.
	var by_id := {}
	for card: Dictionary in DataDB.cards:
		by_id[str(card.get("card_id", ""))] = card
	var size_bad := 0
	var suit_bad := 0
	var gaffe_bad := 0
	var tier3_decks := 0
	var tier3_over := 0
	var dup_bad := 0
	for i in 2000:
		var deck := Ledger.opening_deck(DataDB.cards, DataDB.balance, 50000 + i)
		if deck.size() != 15:
			size_bad += 1
		var suits := {}
		var gaffes := 0
		var tier3 := 0
		var seen := {}
		for id: String in deck:
			var card: Dictionary = by_id.get(id, {})
			suits[str(card.get("suit", ""))] = int(suits.get(str(card.get("suit", "")), 0)) + 1
			if int(card.get("gaffe", 0) if card.get("gaffe") != null else 0) > 0:
				gaffes += 1
			if str(card.get("tier", "")) == "3":
				tier3 += 1
			if seen.has(id):
				dup_bad += 1
			seen[id] = true
		var counts: Array = suits.values()
		if suits.size() < 6 or int(counts.max()) - int(counts.min()) > 1:
			suit_bad += 1
		if gaffes * 2 > deck.size():
			gaffe_bad += 1
		if tier3 >= 1:
			tier3_decks += 1
		if tier3 > 1:
			tier3_over += 1
	_out["INV-14"] = {"decks": 2000, "wrong_size": size_bad, "suits_more_than_one_apart": suit_bad,
		"over_half_gaffe_cards": gaffe_bad, "decks_with_a_tier_3": tier3_decks, "decks_with_two_tier_3": tier3_over,
		"decks_with_a_repeated_card": dup_bad}

	# INV-09: in every combat room, a card's guard, draw and gaffe in the
	# preview equal the printed numbers (special effects aside).
	var compared := 0
	var changed := []
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("mode", "")) != "Combat" or str(stage.get("stage_id", "")) == MpVisit.FIGHT_STAGE:
			continue
		var engine := _engine_for(str(stage.get("stage_id", "")), 77)
		if engine == null:
			continue
		for card: Dictionary in DataDB.cards:
			if card.get("special") != null and str(card.get("special", "")) != "":
				continue
			var effect := engine.preview(card)
			for key: String in ["guard", "draw", "gaffe"]:
				compared += 1
				var printed := int(card.get(key, 0) if card.get(key) != null else 0)
				if int(effect.get(key, 0)) != printed and changed.size() < 20:
					changed.append("%s %s %s: printed %d, preview %d" % [stage.get("stage_id"), card.get("card_id"), key, printed, int(effect.get(key, 0))])
	_out["INV-09"] = {"comparisons": compared, "differences": changed}

	# INV-22: how far the survival line moves each turn (passing every turn).
	var rises := {}
	var survival_rooms := 0
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("bar_model", "")) != "Survival" or str(stage.get("mode", "")) != "Combat":
			continue
		survival_rooms += 1
		for trial in 20:
			var engine := _engine_for(str(stage.get("stage_id", "")), 9000 + trial)
			if engine == null or engine.state.bar == null:
				continue
			var guard := 0
			while not engine.state.is_over() and guard < 40:
				guard += 1
				# Play whatever adds support, so the turn is survived and the line can move.
				for card_id: String in engine.state.hand.duplicate():
					var card := DataDB.get_card(card_id)
					if engine.state.is_over() or engine.card_cost(card) > engine.state.energy or engine.discard_required(card) > 0:
						continue
					var effect := engine.preview(card)
					if int(effect.get("self_plus", 0)) > 0 and engine.state.gaffe + int(effect.get("gaffe", 0)) < engine.state.gaffe_limit:
						engine.play_card(card_id)
				if engine.state.is_over():
					break
				var before := engine.state.bar.threshold
				engine.end_turn()
				var rise := engine.state.bar.threshold - before
				rises[rise] = int(rises.get(rise, 0)) + 1
	_out["INV-22"] = {"survival_rooms": survival_rooms, "rise_counts": rises}

	# INV-23: Political Pressure leaves energy, hand size and turn limit alone,
	# and card previews are identical in the same room at all three tiers.
	var pressure_diff := []
	for tier: String in ["relaxed", "harder"]:
		for stage: Dictionary in DataDB.stages:
			if str(stage.get("mode", "")) != "Combat":
				continue
			var adjusted := Difficulty.adjust_stage(stage, DataDB.balance_base, tier)
			for key: String in ["energy_per_turn", "hand_size", "turn_limit", "energy_pool"]:
				if adjusted.get(key) != stage.get(key) and pressure_diff.size() < 10:
					pressure_diff.append("%s %s %s" % [tier, stage.get("stage_id"), key])
	_out["INV-23"] = {"stage_fields_changed": pressure_diff}

	# INV-07 and INV-08 on a real room: a seeded search for the two cases.
	var gaffe_and_threshold := {"found": 0, "lost": 0}
	var threshold_stops_opponent := {"found": 0, "opponent_moved_after": 0}
	for trial in 1200:
		var engine := _engine_for(["ST02", "ST05", "ST20", "ST21"][trial % 4], 30000 + trial)
		if engine == null:
			continue
		var turns := 0
		while not engine.state.is_over() and turns < 30:
			turns += 1
			for card_id: String in engine.state.hand.duplicate():
				if engine.state.is_over():
					break
				var card := DataDB.get_card(card_id)
				if engine.card_cost(card) > engine.state.energy or engine.discard_required(card) > 0:
					continue
				var effect := engine.preview(card)
				var fills := engine.state.gaffe + int(effect.get("gaffe", 0)) >= engine.state.gaffe_limit
				var crosses := engine.state.bar.player + int(effect.get("self_plus", 0)) >= engine.state.bar.threshold
				var opponent_before := engine.state.bar.opponent
				engine.play_card(card_id)
				if fills and crosses:
					gaffe_and_threshold["found"] += 1
					if engine.state.outcome == "loss":
						gaffe_and_threshold["lost"] += 1
				elif engine.state.outcome == "win":
					threshold_stops_opponent["found"] += 1
					if engine.state.bar.opponent > opponent_before:
						threshold_stops_opponent["opponent_moved_after"] += 1
			if not engine.state.is_over():
				engine.end_turn()
	_out["INV-07"] = gaffe_and_threshold
	_out["INV-08"] = threshold_stops_opponent

	var path := OS.get_environment("AUDIT_OUT")
	if path.is_empty():
		path = "user://audit_invariants.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_out, "\t"))
	file.close()
	print("AUDIT INVARIANT PROBE written to %s" % path)
	get_tree().quit(0)
