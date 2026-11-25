class_name VenueChoices
extends RefCounted
## Seats and meals at a venue, and the chance of an extra (2026-11-25, Cameron's playtest ideas). A venue's Eat with Colleagues first asks where
## to sit (three seats drawn from the venue's seat rows) and what to eat (its meal rows); each choice gives its sure reward and, 1 time in N,
## an extra. Catch Up on Paperwork uses the same chance rule. Pure: no screens, no autoloads, no files (the tests prove it). Every draw is
## from a seed, so a reload shows the same three seats and the same luck.

const SEAT := "seat"
const MEAL := "meal"


## The rows of one step at a venue, in the tab's order.
static func rows_for(rows: Array, venue_id: String, step: String) -> Array:
	var out: Array = []
	for row: Variant in rows:
		var entry := row as Dictionary
		if str(entry.get("venue_id", "")) == venue_id and str(entry.get("step", "")) == step:
			out.append(entry)
	return out


## True when the venue has seats (so its visit starts with a choice).
static func has_choices(rows: Array, venue_id: String) -> bool:
	return not rows_for(rows, venue_id, SEAT).is_empty()


## `count` different seats drawn by Weight (blank counts 1) from the pool, from a seed; every row if there are no more than `count`.
static func draw(pool: Array, count: int, seed_value: int) -> Array:
	if pool.size() <= count:
		return pool.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value)
	var left := pool.duplicate()
	var out: Array = []
	while out.size() < count and not left.is_empty():
		var total := 0
		for row: Dictionary in left:
			total += weight_of(row)
		var roll := rng.randi_range(0, total - 1)
		for index in left.size():
			roll -= weight_of(left[index] as Dictionary)
			if roll < 0:
				out.append(left[index])
				left.remove_at(index)
				break
	return out


static func weight_of(row: Dictionary) -> int:
	var raw: Variant = row.get("weight")
	return maxi(1 if raw == null else int(raw), 1)


## The name with its {party} filled in.
static func display_name(text: String, party_name: String) -> String:
	return text.replace("{party}", party_name)


## Whether a 1-in-`chance` extra comes up, from a seed; false for no chance (blank or 0).
static func hits(chance: Variant, seed_value: int) -> bool:
	if chance == null or int(chance) < 1:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value)
	return rng.randi_range(1, int(chance)) == 1


## Reward entries with every pool ("BO28|BO29") settled to one of its members, from a seed; other entries are unchanged. A "TIER:" group is
## left for the game to pick from.
static func settle_pools(entries: Variant, seed_value: int) -> Array:
	var out: Array = []
	if not (entries is Array):
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value)
	for raw: Variant in entries as Array:
		if not (raw is Dictionary):
			continue
		var entry := (raw as Dictionary).duplicate()
		var pool: Variant = entry.get("target_pool")
		if pool is Array and not (pool as Array).is_empty():
			entry["target"] = str((pool as Array)[rng.randi_range(0, (pool as Array).size() - 1)])
			entry.erase("target_pool")
		out.append(entry)
	return out
