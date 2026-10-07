class_name StaffProfile
extends RefCounted
## What a staff candidate offers, tier by tier — the content of the Staff
## Profile screen. Pure and UI-free (CLAUDE.md §12): OfficeScreen draws it.
##
## A candidate's rewards are one-time bonuses, paid the moment a tier is
## reached (GameState._apply_staff_reward()): standing with an organisation
## (a BOxx target) or sentiment among an audience group (an SGxx target).
## A tier is only listed if the candidate can actually be at it: from their
## own starting tier up to their highest tier. Someone who starts at tier 1
## has no tier 0 to show, and someone with no higher tiers has one row.

## One entry per tier the candidate can be at, lowest first:
##   tier     the tier number
##   on_hire  true for the tier they arrive at
##   cost     Yen to upgrade INTO this tier from the one below, or null
##            (the arrival tier, or a step whose cost cell is blank)
##   lines    the bonus lines for this tier, already in words
##
## `boosters` and `segments` are the data rows (for the names), `words` the
## wording table; nothing here reaches for an autoload.
static func tiers(candidate: Dictionary, boosters: Array, segments: Array,
		words: Phrase) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var first := int(candidate.get("starting_tier", 0))
	var last := maxi(int(candidate.get("highest_tier", 0)), first)

	for tier in range(first, last + 1):
		var cost: Variant = null
		if tier > first:
			cost = Ledger.staff_upgrade_cost(candidate, tier - 1)
		found.append({
			"tier": tier,
			"on_hire": tier == first,
			"cost": cost,
			"lines": reward_lines(candidate.get("tier_%d_reward" % tier), boosters, segments, words),
		})
	return found


## The bonus lines for one tier's reward list. A tier with no reward says so,
## rather than showing an empty gap that looks like missing text.
static func reward_lines(rewards: Variant, boosters: Array, segments: Array,
		words: Phrase) -> Array[String]:
	var lines: Array[String] = []
	if rewards is Array:
		for reward: Variant in rewards:
			if not (reward is Dictionary):
				continue
			var target := str((reward as Dictionary).get("target", ""))
			var delta := "%+d" % int((reward as Dictionary).get("delta", 0))
			if target.begins_with("BO"):
				lines.append(words.say("staff.reward_booster",
					{"delta": delta, "name": _name_of(target, "booster_id", boosters)}))
			elif target.begins_with("SG"):
				lines.append(words.say("staff.reward_segment",
					{"delta": delta, "name": _name_of(target, "segment_id", segments)}))
	if lines.is_empty():
		lines.append(words.say("staff.reward_none"))
	return lines


## An organisation's or audience group's own name, or its ID where the data
## has no row (the usual placeholder bargain, never a blank).
static func _name_of(id: String, key: String, rows: Array) -> String:
	for row: Variant in rows:
		if row is Dictionary and str((row as Dictionary).get(key, "")) == id:
			return str((row as Dictionary).get("name_en", id))
	return id
