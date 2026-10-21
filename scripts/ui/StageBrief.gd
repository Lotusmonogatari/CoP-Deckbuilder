class_name StageBrief
extends RefCounted
## How a room works, in plain sentences.
##
## Nine kinds of stage now differ in how they hand out energy, how many
## questions they ask, how hard a gaffe hits and what winning even means —
## and until a playtest caught it, the details panel explained only the two
## cases that were unusual and said nothing about the rest.
##
## THE POINT IS THAT IT STATES THE DEFAULT. A policy study refills energy at
## the end of the turn, like almost every stage, and asks two questions a
## turn rather than one. Neither was written down anywhere, so energy looked
## finite to the player: they spent it, saw it not come back, and had no way
## to learn that ending the turn is what refills it.
##
## Built from the stage the battle was set up with, so every number here is
## the number the battle is actually running on.
##
## Static and given everything it needs, so the details panel and the
## briefing screen can print the same sentences rather than drifting apart.


## The two lines that always show: the key numbers on one row, then what
## winning means in this room. Short by design (2026-10-21): rules every room
## shares (guard, the usual energy and hand) are in How to Play, and a number
## is printed only when this room differs from the standard one.
static func headline(stage: Dictionary, state: BattleState = null) -> Array[String]:
	var lines: Array[String] = [" · ".join(_stats(stage, state))]
	lines.append(_winning(stage))
	return lines


## The rest of the room's rules, shown behind the Room rules toggle: how many
## questions it asks and what skipping one costs, and any cooling of interest.
static func details(stage: Dictionary, _state: BattleState = null) -> Array[String]:
	var lines: Array[String] = []
	var questions: Array = stage.get("questions", [])
	if not questions.is_empty():
		lines.append(_questions(stage, questions.size()))
	var decay := int(stage.get("affinity_decay", 0))
	if decay > 0:
		lines.append(Text.say("brief.decay", {"count": decay}))
	return lines


## Every line, headline first. `state` may be null: the briefing screen
## describes a stage before there is a battle.
static func how_this_room_works(stage: Dictionary, state: BattleState = null) -> Array[String]:
	var lines := headline(stage, state)
	lines.append_array(details(stage, state))
	return lines


## "Turns 7 · Gaffes 5 = loss", plus Energy and Hand only where this room
## differs from the standard (Balance: Brief: Standard Energy / Hand).
static func _stats(stage: Dictionary, state: BattleState) -> Array[String]:
	var stats: Array[String] = []
	var limit := int(stage.get("turn_limit", 0))
	stats.append(Text.say("brief.stat.turns", {"count": limit}) if limit > 0
		else Text.say("brief.stat.turns_none"))

	var gaffe_limit := int(stage.get("gaffe_limit", 5))
	var multiplier := maxi(int(stage.get("gaffe_multiplier", 1)), 1)
	stats.append(Text.say("brief.stat.gaffes_multiplied",
		{"count": gaffe_limit, "multiplier": multiplier}) if multiplier > 1
		else Text.say("brief.stat.gaffes", {"count": gaffe_limit}))

	if str(stage.get("energy_mode", "per_turn")) == "pool":
		var left := ("" if state == null
			else Text.say("brief.energy.left", {"count": state.energy}))
		stats.append(Text.say("brief.stat.energy_pool",
			{"count": int(stage.get("energy_pool", 0)), "left": left}))
	else:
		var energy := int(stage.get("energy_per_turn", 3))
		if energy != int(DataDB.balance.get("brief_standard_energy", 3)):
			stats.append(Text.say("brief.stat.energy", {"count": energy}))

	if str(stage.get("draw_mode", "refill")) == "none":
		stats.append(Text.say("brief.stat.hand_none", {"count": int(stage.get("opening_hand", 8))}))
	else:
		var hand := int(stage.get("hand_size", 5))
		if hand != int(DataDB.balance.get("brief_standard_hand", 5)):
			stats.append(Text.say("brief.stat.hand", {"count": hand}))
	return stats


static func _questions(stage: Dictionary, total: int) -> String:
	var per_turn := maxi(int(stage.get("questions_per_turn", 1)), 1)
	var sentence := (Text.say("brief.q.one_a_turn", {"total": total}) if per_turn == 1
		else Text.say("brief.q.several", {"per_turn": per_turn, "total": total}))
	if bool(stage.get("decline_ends_stage", false)):
		return sentence + " " + Text.say("brief.q.skip_ends")
	var cost := int(stage.get("decline_tone_cost", 3))
	if cost > 0:
		return sentence + " " + Text.say("brief.q.skip_costs", {"count": cost})
	return sentence + " " + Text.say("brief.q.skip_free")


static func _winning(stage: Dictionary) -> String:
	if str(stage.get("win_mode", "threshold")) == "score":
		return Text.say("brief.winning.score")

	var threshold := int(stage.get("win_threshold", 0))
	var unit := str(stage.get("bar_unit", "support")).to_lower()
	if threshold <= 0:
		return Text.say("brief.winning.hold")

	# A TV debate whose line rises each turn says by how much.
	if (str(stage.get("bar_model", "")) == "Survival"
			and stage.get("threshold_rise_min") != null
			and stage.get("threshold_rise_max") != null
			and int(stage.get("threshold_rise_max")) > 0):
		return Text.say("brief.winning.survival_rising", {"count": threshold, "unit": unit,
			"min": int(stage.get("threshold_rise_min")), "max": int(stage.get("threshold_rise_max"))})

	match str(stage.get("sequence_mode", "single")):
		"reset":
			return Text.say("brief.winning.reset", {"count": threshold, "unit": unit})
		"continuous":
			return Text.say("brief.winning.continuous",
				{"count": threshold, "unit": unit})
		"stream":
			return Text.say("brief.winning.stream", {"count": threshold, "unit": unit})
		_:
			return Text.say("brief.winning.single",
				{"count": threshold, "unit": unit})
