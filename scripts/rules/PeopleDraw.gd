class_name PeopleDraw
extends RefCounted
## Who a stage seats, drawn from the people eligible for it (Cameron,
## 2026-10-13): the same person CAN come back, but the draw leans toward
## people the player has met the fewest times this run. Everyone eligible is
## grouped by how often they have been faced; the least-faced group is
## drawn from first (shuffled within the group), then the next, and so on.
## Nobody is ever seated twice in one stage, because each person appears
## once in the pool.
##
## Pure and UI-free (CLAUDE.md section 12): the caller supplies the random
## generator and the faced counts (GameState.faced_people).


## Up to `count` people from `pool`, least-faced first, skipping any whose id
## is in `exclude_ids` (a pinned person already seated). `id_key` is the field
## holding a person's id ("opp_id" or "visitor_id").
static func pick(pool: Array, id_key: String, faced: Dictionary, count: int,
		exclude_ids: Array, rng: RandomNumberGenerator) -> Array:
	var tiers := {}
	for person: Variant in pool:
		if not (person is Dictionary):
			continue
		var id := str((person as Dictionary).get(id_key, ""))
		if exclude_ids.has(id):
			continue
		var met := int(faced.get(id, 0))
		if not tiers.has(met):
			tiers[met] = []
		(tiers[met] as Array).append(person)

	var counts := tiers.keys()
	counts.sort()
	var chosen: Array = []
	for met: Variant in counts:
		var group: Array = tiers[met]
		for index in range(group.size() - 1, 0, -1):
			var swap := rng.randi_range(0, index)
			var held: Variant = group[index]
			group[index] = group[swap]
			group[swap] = held
		for person: Variant in group:
			if chosen.size() >= count:
				return chosen
			chosen.append(person)
	return chosen
