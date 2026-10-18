class_name OrgPreview
extends RefCounted
## What playing a card would do to the organisations listening (2026-10-18,
## Cameron). Nothing here changes the battle: it asks the engine what the
## card would tally against the open question, then compares the stage's net
## standing change for each organisation with and without it. The comparison
## goes through the same BoosterChange arithmetic (bands, caps, stance) that
## the Outcome panel and the real application use, so the number shown is the
## number that lands.


## [{booster_id, delta}] for every organisation the card would move; empty
## when no question is open or the card moves nobody.
static func changes(engine: BattleEngine, card: Dictionary) -> Array[Dictionary]:
	var effect := engine.answer_effect(card)
	if effect.is_empty():
		return []
	var now := engine.booster_tally()
	var after := now.duplicate(true)
	for kind: String in ["pleased", "displeased", "opposed"]:
		for booster_id: String in (effect.get(kind, []) as Array):
			var row: Dictionary = after.get(booster_id,
				{"pleased": 0, "displeased": 0, "opposed": 0})
			row[kind] = int(row[kind]) + 1
			after[booster_id] = row
	var standing := DataDB.booster_standing
	var current := GameState.booster_standing
	var before_net := _nets(now, standing, current)
	var after_net := _nets(after, standing, current)
	var out: Array[Dictionary] = []
	for booster_id: String in after_net:
		var delta := int(after_net[booster_id]) - int(before_net.get(booster_id, 0))
		if delta != 0:
			out.append({"booster_id": booster_id, "delta": delta})
	return out


static func _nets(tally: Dictionary, standing: Dictionary, current: Dictionary) -> Dictionary:
	var out := {}
	if tally.is_empty():
		return out
	var adjusted := GameState.stance_adjust_tally(tally)
	for row: Dictionary in BoosterChange.compute([], [], [], standing, [], adjusted, current):
		out[str(row["booster_id"])] = int(row["net"])
	return out
