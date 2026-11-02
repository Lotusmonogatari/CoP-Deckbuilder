extends "res://tools/playtest_optimal.gd"
## Probe of the Draft a Bill lifecycle (2026-11-02): start a draft for a strong
## player, play the level with the bot, then check what the game recorded and
## what it refuses next. Prints one block per drafted bill.
##     godot --headless --path . tools/bill_draft_probe.tscn

func _run() -> void:
	MAX_STAGES = 100000
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ids: Array = []
	for component: Dictionary in DataDB.bill_components:
		ids.append(str(component["component_id"]))
	var by_id := ComposedBill.index(DataDB.bill_components)
	var tried := 0
	var summary := {"started": 0, "passed": 0, "failed": 0, "lapsed": 0, "refused": 0}
	while tried < 14:
		var pick: Array = []
		var count := 2 if tried % 2 == 0 else 3
		var pool := ids.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t: Variant = pool[i]; pool[i] = pool[j]; pool[j] = t
		for i in count:
			pick.append(pool[i])
		tried += 1
		GameState.start_new_run("PC01")
		_strengthen()
		var refusal := GameState.draft_refusal(pick)
		var names := ", ".join(pick.map(func(x: Variant) -> String: return str((by_id[x] as Dictionary).get("short_label", x))))
		if not refusal.is_empty():
			summary["refused"] += 1
			print("PROBE [%s] REFUSED: %s" % [names, refusal])
			continue
		var xp0 := GameState.xp
		var funds0 := int(GameState.meta["Funds"])
		var standing0 := GameState.booster_standing.duplicate()
		var party0 := int(GameState.meta["Party support"])
		if not GameState.start_draft(pick):
			print("PROBE [%s] start_draft FAILED" % names)
			continue
		summary["started"] += 1
		var draft_id := DraftBill.id_for(GameState.draft_counter)
		var level_id := PatronLevel.level_id_for(draft_id)
		var stages_before := _stages_played
		_play_current_level(level_id)
		var status := str((GameState.patron_requests.get(draft_id, {}) as Dictionary).get("status", "?"))
		summary[("passed" if status == "passed" else "failed" if status == "failed" else "lapsed")] += 1
		var moved: Array[String] = []
		for org: String in GameState.booster_standing:
			var d := int(GameState.booster_standing[org]) - int(standing0.get(org, 0))
			if d != 0:
				moved.append("%s%+d" % [org, d])
		var level_hours := 0
		print("PROBE [%s] status=%s xp %+d funds %+d party %+d stages=%d enacted=%s cooldown_refusal='%s' repeat_refusal='%s'\n        standing moves: %s\n        statute entries: %d (draft rows: %s)" % [
			names, status, GameState.xp - xp0, int(GameState.meta["Funds"]) - funds0, int(GameState.meta["Party support"]) - party0,
			_stages_played - stages_before, GameState.enacted_components,
			GameState.draft_refusal(pick).left(60), GameState.draft_refusal(pick).left(60),
			", ".join(moved), GameState.statute_book.size(),
			str(GameState.statute_book.filter(func(e: Dictionary) -> bool: return str(e.get("bill_id", "")).begins_with("PD")).size())])
	print("PROBE SUMMARY %s" % [summary])
	get_tree().quit(0)


## A late-game player: gates met, cap raised, plenty of XP and Funds.
func _strengthen() -> void:
	GameState.funds_cap_bonus = 900000
	GameState.meta["Funds"] = 1000000
	GameState.meta["Reputation"] = 90
	GameState.meta["Party support"] = 80
	GameState.meta["Constituency support"] = 90
	GameState.xp = 2000
	for org: String in GameState.booster_standing.keys():
		GameState.booster_standing[org] = 80
	for card: Dictionary in DataDB.cards:
		var id := str(card.get("card_id", ""))
		if not GameState.owned_cards.has(id):
			GameState.owned_cards.append(id)
	_rebuild_deck()
