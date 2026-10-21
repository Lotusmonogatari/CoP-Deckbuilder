class_name RoomMix
extends RefCounted
## A room's audience as whole percentages that add up to exactly 100
## (2026-10-21). A stage's mix is its named audience groups (segment_mix) plus
## an "Other" share (pct_other); the two do not always reach 1.0 in the
## workbook, so whatever is missing is counted as Other, and rounding is shared
## out by largest remainder so the shown numbers never add to 99 or 101.
##
## Pure and UI-free (CLAUDE.md section 12): the caller passes the word "Other".


## [{ "name": String, "pct": int }] in segments.json order, Other last. A group
## with no share is left out; Other is left out when it is 0.
static func entries(stage: Dictionary, segments: Array, other_name: String) -> Array[Dictionary]:
	var mix: Dictionary = stage.get("segment_mix", {})
	if mix.is_empty() and stage.get("pct_other") == null:
		return []   # no audience is written for this room at all
	var names: Array[String] = []
	var raw: Array[float] = []
	for segment: Dictionary in segments:
		var share := float(mix.get(segment.get("segment_id"), 0.0))
		if share > 0.0:
			names.append(str(segment.get("name_en", "")))
			raw.append(share * 100.0)
	var named_total := 0.0
	for value: float in raw:
		named_total += value
	var other := maxf(100.0 - named_total, 0.0)
	var declared: Variant = stage.get("pct_other")
	if declared != null:
		other = maxf(other, float(declared) * 100.0)
	if other > 0.0:
		names.append(other_name)
		raw.append(other)
	if raw.is_empty():
		return []

	# Scale to exactly 100 first if the named shares overshoot it.
	var total := 0.0
	for value: float in raw:
		total += value
	var floors: Array[int] = []
	var fractions: Array[float] = []
	var given := 0
	for value: float in raw:
		var scaled := value * 100.0 / total
		floors.append(int(floor(scaled)))
		fractions.append(scaled - floor(scaled))
		given += floors[-1]
	var order: Array = range(raw.size())
	order.sort_custom(func(a: int, b: int) -> bool: return fractions[a] > fractions[b])
	var i := 0
	while given < 100 and i < order.size():
		floors[order[i]] += 1
		given += 1
		i += 1
	var out: Array[Dictionary] = []
	for index in names.size():
		if floors[index] > 0:
			out.append({"name": names[index], "pct": floors[index]})
	return out
