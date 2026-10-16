class_name BoosterChange
extends RefCounted
## The net standing change each organisation gets from one stage.
##
## Pure arithmetic, no UI. The outcome panel uses it to tell the player how
## far each organisation moved. It mirrors GameState's own application
## (BoosterStanding.net_for(), then a flat penalty if one of their people was
## argued out), so the number shown is the number that lands.


## Returns [{booster_id, net}] in the order organisations were first touched:
## pleased, then annoyed, then crushed. `standing` is booster_standing.json.
## `tally` ({id: {pleased, displeased, opposed}}) counts every answer; without
## it each list entry counts once. `current` is {booster_id: standing now},
## which decides the diminishing-returns bands.
static func compute(pleased: Array, displeased: Array, crushed: Array,
		standing: Dictionary, opposed: Array = [], tally: Dictionary = {},
		current: Dictionary = {}) -> Array[Dictionary]:
	var penalty := int(standing.get("instant_win_penalty", 2))
	var counts := BoosterStanding.tallies(pleased, displeased, opposed, tally)

	var order: Array[String] = []
	for group: Array in [pleased, displeased, opposed, counts.keys(), crushed]:
		for booster_id: String in group:
			if not order.has(booster_id):
				order.append(booster_id)

	var out: Array[Dictionary] = []
	for booster_id: String in order:
		var net := 0
		if counts.has(booster_id):
			net = BoosterStanding.net_for(counts[booster_id],
				int(current.get(booster_id, int(standing.get("start", 30)))), standing)
		if crushed.has(booster_id):
			net -= penalty
		out.append({"booster_id": booster_id, "net": net})
	return out
