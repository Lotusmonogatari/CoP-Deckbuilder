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
	var lines: Array[String] = ["How this room works"]

	lines.append("• Turns — %s" % _turns(stage))
	lines.append("• Energy — %s" % _energy(stage, state))

	var questions: Array = stage.get("questions", [])
	if not questions.is_empty():
		lines.append("• Questions — %s" % _questions(stage, questions.size()))

	lines.append("• Gaffes — %s" % _gaffes(stage))
	lines.append("• Guard — %s" % _guard(state))
	lines.append("• Your hand — %s" % _hand(stage))
	lines.append("• Winning — %s" % _winning(stage))

	var decay := int(stage.get("affinity_decay", 0))
	if decay > 0:
		lines.append("• Every turn costs you — their interest cools by %d, "
			% decay + "whatever you say.")

	return lines


static func _turns(stage: Dictionary) -> String:
	var limit := int(stage.get("turn_limit", 0))
	if limit <= 0:
		return "no limit. It ends when the questions run out."
	return "%d. Running out of them is a loss." % limit


static func _energy(stage: Dictionary, state: BattleState) -> String:
	if str(stage.get("energy_mode", "per_turn")) == "pool":
		var pool := int(stage.get("energy_pool", 0))
		var left := "" if state == null else "  %d left." % state.energy
		return ("%d for the whole thing. They do NOT come back at the start " % pool
			+ "of a turn — spend them as a budget.%s" % left)

	# The sentence that prompted all of this: "when you end the turn" is the
	# step the player could not see.
	return ("%d a turn, back in full when you end the turn." % int(
		stage.get("energy_per_turn", 3)))


static func _questions(stage: Dictionary, total: int) -> String:
	var per_turn := maxi(int(stage.get("questions_per_turn", 1)), 1)
	var sentence := ""
	if per_turn == 1:
		sentence = "one a turn, %d in all. " % total
	else:
		sentence = ("%d a turn, %d in all. " % [per_turn, total]
			+ "A further card still plays, but nobody is waiting for it. ")

	sentence += "Leave one unanswered when the turn ends and you have declined it"
	if bool(stage.get("decline_ends_stage", false)):
		return sentence + ", and here that ends the stage."

	var cost := int(stage.get("decline_tone_cost", 3))
	if cost > 0:
		return sentence + ", which costs %d and pleases nobody." % cost
	return sentence + "."


static func _gaffes(stage: Dictionary) -> String:
	var limit := int(stage.get("gaffe_limit", 5))
	var multiplier := maxi(int(stage.get("gaffe_multiplier", 1)), 1)
	if multiplier > 1:
		return ("%d ends the stage at once — and every slip here counts %d times."
			% [limit, multiplier])
	return "%d ends the stage at once." % limit


static func _guard(state: BattleState) -> String:
	var cap := 5 if state == null else state.guard_cap
	return ("it banks up to %d and carries between turns. " % cap
		+ "Only an attack takes it, and it is spent stopping one.")


static func _hand(stage: Dictionary) -> String:
	if str(stage.get("draw_mode", "refill")) == "none":
		return ("%d cards, and you draw no more. " % int(stage.get("opening_hand", 8))
			+ "Run out and there is nothing left to say.")
	return "drawn back up to %d at the end of every turn." % int(
		stage.get("hand_size", 5))


static func _winning(stage: Dictionary) -> String:
	if str(stage.get("win_mode", "threshold")) == "score":
		return ("there is nothing to reach. However high the support gets by "
			+ "the end is the result, and later stages draw on it.")

	var threshold := int(stage.get("win_threshold", 0))
	var unit := str(stage.get("bar_unit", "support")).to_lower()
	if threshold <= 0:
		return "hold the room until the questions run out."

	match str(stage.get("sequence_mode", "single")):
		"reset":
			return ("%d %s wins the argument in front of you. " % [threshold, unit]
				+ "The next one starts again from nothing, gaffes included.")
		"continuous":
			return ("%d %s finishes the one in front of you, not the stage. " % [
				threshold, unit]
				+ "Your record, your hand and the clock carry across all of them.")
		"stream":
			return ("%d %s moves the queue along. " % [threshold, unit]
				+ "The clock and your record carry; each new face is fresh energy.")
		_:
			return "%d %s." % [threshold, unit]
