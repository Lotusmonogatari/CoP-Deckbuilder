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
