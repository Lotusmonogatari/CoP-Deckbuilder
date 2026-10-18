class_name StandingLinks
extends RefCounted
## One organization's standing following, or opposing, something else
## (2026-10-18, Cameron). Rows come from the Standing Links tab: Source is a
## booster ID or a meta-variable name, Target a booster ID, Weight the share
## of the source's change (in standing points) the target takes: positive
## follows, negative is a rivalry. Pure arithmetic; GameState does the moving.


## The link rows whose Source is `source`.
static func from_source(links: Array, source: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Dictionary in links:
		if str(row.get("source", "")) == source:
			out.append(row)
	return out


## A meta change in standing points. Funds counts `yen_per_point` yen as one
## point (it swings in thousands); every other variable is read against its
## own min-to-max range as a 0-100 scale.
static func points_for_meta(name: String, delta: int, sanban_row: Dictionary,
		yen_per_point: int) -> float:
	if name == "Funds":
		return float(delta) / float(maxi(yen_per_point, 1))
	var span := float(int(sanban_row.get("max", 100)) - int(sanban_row.get("min", 0)))
	return float(delta) * 100.0 / maxf(span, 1.0)


## Adds a fractional change to what was left over before, and splits it into
## the whole points to apply now and the remainder to carry: {whole, carry}.
## Truncates toward zero, so small changes build up instead of vanishing.
static func settle(change: float, carried: float) -> Dictionary:
	var total := change + carried
	var whole := int(total)
	return {"whole": whole, "carry": total - float(whole)}
