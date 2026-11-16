class_name ItemUses
extends RefCounted
## Items with a number of uses (Cameron, 2026-11-16). Pure rules, no UI, no
## autoloads: an item's copies are kept as a list of "uses left", one number per
## copy, and these functions say how that list changes.
##
##   - A *use* takes one use off the copy with the FEWEST uses left (the most-used
##     copy is finished first); a copy at 0 uses is worn out and thrown away.
##   - Handing an item over (a gift, a promise) removes a whole copy, the same
##     most-used one.
##   - The list is kept in step with how many copies are held (`normalize`).
## The Shop's Uses column says how many uses a fresh copy has (blank = 1).


## How many uses a fresh copy of the item has: the Shop row's Uses, at least 1.
static func full_uses(item: Dictionary) -> int:
	var value: Variant = item.get("uses")
	return maxi(1, int(value)) if value != null else 1


## `copies` made to hold exactly `count` entries, each a whole number from 1 up
## to `full`: missing copies are new (full uses), surplus ones are dropped from
## the fullest end, nonsense numbers are repaired. Always sorted, fewest first.
static func normalize(copies: Variant, count: int, full: int) -> Array[int]:
	var out: Array[int] = []
	if copies is Array:
		for value: Variant in copies:
			if value is int or value is float:
				out.append(clampi(int(value), 1, maxi(1, full)))
	out.sort()
	while out.size() > count:
		out.pop_back()
	while out.size() < count:
		out.append(maxi(1, full))
	out.sort()
	return out


## One use spent: { "copies": the new list, "worn_out": bool }. A list with
## nothing in it is returned as it is, nothing worn out.
static func spend(copies: Array[int]) -> Dictionary:
	if copies.is_empty():
		return {"copies": copies, "worn_out": false}
	var next: Array[int] = copies.duplicate()
	next.sort()
	var left := next[0] - 1
	next.remove_at(0)
	if left > 0:
		next.append(left)
		next.sort()
	return {"copies": next, "worn_out": left <= 0}


## One whole copy handed over: the one with the fewest uses left goes.
static func remove_copy(copies: Array[int]) -> Array[int]:
	var next: Array[int] = copies.duplicate()
	next.sort()
	if not next.is_empty():
		next.remove_at(0)
	return next


## The uses left of the copy that the next use would spend (0 with no copies).
static func next_left(copies: Array[int]) -> int:
	var low := 0
	for value: int in copies:
		if low == 0 or value < low:
			low = value
	return low
