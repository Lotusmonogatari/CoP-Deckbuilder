class_name BoosterChange
extends RefCounted
## The net standing change each organisation gets from one stage.
##
## Pure arithmetic, no UI. The outcome panel uses it to tell the player how
## far each organisation moved. It mirrors GameState's own application (a
## question's pleased/annoyed amounts settle to one number clamped to the
## swing cap, then a flat penalty if one of their people was argued out), so
## the number shown is the number that lands.


## Returns [{booster_id, net}] in the order organisations were first touched:
## pleased, then annoyed, then crushed. `standing` is booster_standing.json.
static func compute(pleased: Array, displeased: Array, crushed: Array,
		standing: Dictionary) -> Array[Dictionary]:
	var please_step := int(standing.get("per_please", 5))
	var displease_step := int(standing.get("per_displease", 1))
	var cap := int(standing.get("question_swing_cap", 5))
	var penalty := int(standing.get("instant_win_penalty", 2))

	var order: Array[String] = []
	for group: Array in [pleased, displeased, crushed]:
		for booster_id: String in group:
			if not order.has(booster_id):
				order.append(booster_id)

	var out: Array[Dictionary] = []
	for booster_id: String in order:
		var net := 0
		if pleased.has(booster_id):
			net += please_step
		if displeased.has(booster_id):
			net -= displease_step
		net = clampi(net, -cap, cap)
		if crushed.has(booster_id):
			net -= penalty
		out.append({"booster_id": booster_id, "net": net})
	return out
