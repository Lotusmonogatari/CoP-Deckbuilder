class_name VoteProjection
extends RefCounted
## Hides part of a projected vote (draft 2026-11-08, Cameron). The Floor Vote
## screen shows what each choice would roughly give, but the exact tally is
## kept for the final outcome screen. A share of the house, a Balance number
## ("Vote Projection: Unknown Percent"), is moved out of Aye, Nay and Abstain
## in proportion to their size and shown as Unknown.
##
## Pure arithmetic: no screens, no autoloads.


## `totals` = { "Yes": n, "No": n, "Abstain": n }; `unknown_percent` = how much
## of the whole house to hide. Returns { "Yes", "No", "Abstain", "Unknown" }
## whole seats that add up to the same house size. The hidden seats are
## shared out by largest remainder, so no bucket is asked for more than it has.
static func split(totals: Dictionary, unknown_percent: float) -> Dictionary:
	var yes := maxi(int(totals.get("Yes", 0)), 0)
	var no := maxi(int(totals.get("No", 0)), 0)
	var abstain := maxi(int(totals.get("Abstain", 0)), 0)
	var house := yes + no + abstain
	var hidden := clampi(roundi(house * unknown_percent / 100.0), 0, house)
	var out := {"Yes": yes, "No": no, "Abstain": abstain, "Unknown": hidden}
	if hidden <= 0 or house <= 0:
		out["Unknown"] = 0
		return out
	var buckets := ["Yes", "No", "Abstain"]
	var taken := {}
	var remainders := []
	var assigned := 0
	for bucket: String in buckets:
		var exact := float(out[bucket]) * hidden / house
		taken[bucket] = mini(int(floor(exact)), out[bucket])
		assigned += int(taken[bucket])
		remainders.append([exact - floor(exact), bucket])
	remainders.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var index := 0
	while assigned < hidden and index < remainders.size() * 3:
		var bucket: String = remainders[index % remainders.size()][1]
		if taken[bucket] < out[bucket]:
			taken[bucket] += 1
			assigned += 1
		index += 1
	for bucket: String in buckets:
		out[bucket] = int(out[bucket]) - int(taken[bucket])
	out["Unknown"] = assigned
	return out


## The Unknown range after a research assistant narrows it (draft 2026-11-08):
## `points` come off both ends, never below 0, and the top never drops under
## the bottom. Returns [low, high].
static func narrowed_range(low: int, high: int, points: int) -> Array:
	var new_low := maxi(low - points, 0)
	var new_high := maxi(high - points, new_low)
	return [new_low, new_high]


## A tiered value picked by staff tier, not added up: Tier 2 gives its own
## number, not Tier 0 + 1 + 2. `by_tier` = [tier 0, tier 1, tier 2]; a tier
## below 0 (nobody hired) gives 0.
static func by_tier(by_tier_values: Array, tier: int) -> int:
	if tier < 0 or by_tier_values.is_empty():
		return 0
	return int(by_tier_values[mini(tier, by_tier_values.size() - 1)])
