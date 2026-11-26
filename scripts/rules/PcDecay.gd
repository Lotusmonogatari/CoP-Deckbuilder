class_name PcDecay
extends RefCounted
## Political Capital decay, meter decay and decay holds (P21 phase A, 2026-11-26, Cameron). Pure and UI-free (CLAUDE.md section 12): every number is
## a Balance row read through Levers. What the game calls XP in the data and the code is Political Capital (PC) on the screen.
##
## At each week's end, after the week's gains: Political Capital above the floor loses a share; Party support steps down (5 from 50 to 74, 8 from 75,
## never below 50 from this rule); District and National awareness lose a share of their distance above their start (at least 1 while above it).
## A hold stops one meter's (or one organization's) decay for the week it is bought; each consecutive week on the same one costs a step more.


## Political Capital lost at a week's end: floor((xp - floor) x percent / 100) when above the floor, else 0.
static func xp_loss(xp: int) -> int:
	var floor_value := Levers.whole("xp_decay_floor")
	if xp <= floor_value:
		return 0
	return int(floor(float(xp - floor_value) * Levers.num("xp_decay_percent") / 100.0))


## Party support lost at a week's end: 5 while 50 to 74, 8 while 75 or more, never taking it below 50. Nothing below 50.
static func party_support_loss(support: int) -> int:
	if support <= 50:
		return 0
	var step := Levers.whole("party_support_decay_at_75") if support >= 75 else Levers.whole("party_support_decay_at_50")
	return mini(step, support - 50)


## Awareness lost at a week's end: `percent` of the distance above `start`, rounded down, at least 1 while above the start.
static func awareness_loss(value: int, start: int) -> int:
	if value <= start:
		return 0
	return maxi(1, int(floor(float(value - start) * Levers.num("awareness_decay_percent") / 100.0)))


## The price of a hold: its base plus a step for each week in a row the same thing was already held (`streak`).
static func hold_price(base: int, step: int, streak: int) -> int:
	return base + step * maxi(0, streak)


## The streaks after a week's end: each key held this week goes up one, every other key starts again.
static func next_streaks(streaks: Dictionary, held: Array) -> Dictionary:
	var out := {}
	for key: Variant in held:
		out[str(key)] = int(streaks.get(str(key), 0)) + 1
	return out


## A Political Capital price on the current difficulty: Relaxed and Harder scale it (Balance xp_price_*_percent), rounded to the nearest 5.
static func scaled_price(price: int, tier: String) -> int:
	var percent := 100.0
	if tier == Difficulty.RELAXED:
		percent = Levers.num("xp_price_relaxed_percent")
	elif tier == Difficulty.HARDER:
		percent = Levers.num("xp_price_harder_percent")
	return roundi(float(price) * percent / 100.0 / 5.0) * 5
