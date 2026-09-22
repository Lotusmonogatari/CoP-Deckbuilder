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
## Built from the RESOLVED stage — the one BattleSetup.resolve_type has
## already merged out of stage_types.json — so every number here is the
## number the battle is actually running on.
##
## Static and given everything it needs, so the details panel and the
## briefing screen can print the same sentences rather than drifting apart.


## One line per rule of the room, ready to join with newlines.
##
## `state` may be null: the briefing screen describes a stage before there is
## a battle, and then only the things written on the stage can be said.
static func how_this_room_works(stage: Dictionary, state: BattleState = null) -> Array[String]:
	var lines: Array[String] = [Text.say("brief.heading")]

	lines.append(_bullet("brief.label.turns", _turns(stage)))
	lines.append(_bullet("brief.label.energy", _energy(stage, state)))

	var questions: Array = stage.get("questions", [])
	if not questions.is_empty():
		lines.append(_bullet("brief.label.questions", _questions(stage, questions.size())))

	lines.append(_bullet("brief.label.gaffes", _gaffes(stage)))
	lines.append(_bullet("brief.label.guard", _guard(state)))
	lines.append(_bullet("brief.label.hand", _hand(stage)))
	lines.append(_bullet("brief.label.winning", _winning(stage)))

	var decay := int(stage.get("affinity_decay", 0))
	if decay > 0:
		lines.append(_bullet("brief.label.decay",
			Text.say("brief.decay", {"count": decay})))

	return lines


## One line of the list: its label and what it says.
static func _bullet(label_key: String, detail: String) -> String:
	return Text.say("brief.bullet",
		{"label": Text.say(label_key), "detail": detail})


static func _turns(stage: Dictionary) -> String:
	var limit := int(stage.get("turn_limit", 0))
	if limit <= 0:
		return Text.say("brief.turns.none")
	return Text.say("brief.turns.limit", {"count": limit})


static func _energy(stage: Dictionary, state: BattleState) -> String:
	if str(stage.get("energy_mode", "per_turn")) == "pool":
		var pool := int(stage.get("energy_pool", 0))
		var left := ("" if state == null
			else Text.say("brief.energy.left", {"count": state.energy}))
		return Text.say("brief.energy.pool", {"count": pool, "left": left})

	# The sentence that prompted all of this: "when you end the turn" is the
	# step the player could not see.
	return Text.say("brief.energy.per_turn",
		{"count": int(stage.get("energy_per_turn", 3))})


static func _questions(stage: Dictionary, total: int) -> String:
	var per_turn := maxi(int(stage.get("questions_per_turn", 1)), 1)
	var sentence := ""
	if per_turn == 1:
		sentence = Text.say("brief.questions.one_a_turn", {"total": total})
	else:
		sentence = Text.say("brief.questions.several",
			{"per_turn": per_turn, "total": total})

	sentence += Text.say("brief.questions.decline")
	if bool(stage.get("decline_ends_stage", false)):
		return sentence + Text.say("brief.questions.ends_stage")

	var cost := int(stage.get("decline_tone_cost", 3))
	if cost > 0:
		return sentence + Text.say("brief.questions.costs", {"count": cost})
	return sentence + Text.say("brief.questions.free")


static func _gaffes(stage: Dictionary) -> String:
	var limit := int(stage.get("gaffe_limit", 5))
	var multiplier := maxi(int(stage.get("gaffe_multiplier", 1)), 1)
	if multiplier > 1:
		return Text.say("brief.gaffes.multiplied",
			{"count": limit, "multiplier": multiplier})
	return Text.say("brief.gaffes.plain", {"count": limit})


static func _guard(state: BattleState) -> String:
	var cap := 5 if state == null else state.guard_cap
	return Text.say("brief.guard", {"count": cap})


static func _hand(stage: Dictionary) -> String:
	if str(stage.get("draw_mode", "refill")) == "none":
		return Text.say("brief.hand.none",
			{"count": int(stage.get("opening_hand", 8))})
	return Text.say("brief.hand.refill",
		{"count": int(stage.get("hand_size", 5))})


static func _winning(stage: Dictionary) -> String:
	if str(stage.get("win_mode", "threshold")) == "score":
		return Text.say("brief.winning.score")

	var threshold := int(stage.get("win_threshold", 0))
	var unit := str(stage.get("bar_unit", "support")).to_lower()
	if threshold <= 0:
		return Text.say("brief.winning.hold")

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
