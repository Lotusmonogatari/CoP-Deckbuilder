class_name ScrollSpeed
extends RefCounted
## The scrolling-speed setting (Cameron, 2026-11-13): five levels, level 1
## being the speed the game always had. Pure: each level's percent is a
## Balance lever (`scroll_speed_level_1` to `scroll_speed_level_5`), and
## DragScroll multiplies how far a list moves by the result (a finger drag,
## a wheel notch and the glide after a flick alike).

const LEVELS := 5
const SLOWEST := 1


## The level after `current` when the player taps the button (5 wraps to 1).
static func next(current: int) -> int:
	return clampi(current, SLOWEST, LEVELS) % LEVELS + 1


## A saved value turned into a safe level (anything odd means level 1).
static func clean(value: Variant) -> int:
	if value is int or value is float:
		return clampi(int(value), SLOWEST, LEVELS)
	return SLOWEST


## The multiplier for a level, from the Balance levers (percent). A missing
## lever or an unknown level means "no change".
static func factor(level: int, balance: Dictionary) -> float:
	var percent := 100.0
	match clean(level):
		1: percent = float(balance.get("scroll_speed_level_1", 100))
		2: percent = float(balance.get("scroll_speed_level_2", 100))
		3: percent = float(balance.get("scroll_speed_level_3", 100))
		4: percent = float(balance.get("scroll_speed_level_4", 100))
		5: percent = float(balance.get("scroll_speed_level_5", 100))
	return maxf(percent, 50.0) / 100.0
