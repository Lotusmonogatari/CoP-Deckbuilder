class_name PartySalience
extends RefCounted
## How much a bill matters to a party (2026-10-14, Cameron): the party's
## "salience" on the bill is the sum, over the policy areas the bill touches,
## of (how far the bill pushes that area) x (the party's salience for that
## area, value x priority). The Party Positions tab carries the size of that
## number in its Salience column. A party's opinion of the player moves more
## on a bill that sits on the party's own priorities, and less on one it
## barely cares about.
##
## Pure and UI-free (CLAUDE.md section 12).


## Multiplier for a party's movement on a bill. `salience` is the Salience
## cell (null/blank = no data = 1.0, so a bill with no score behaves exactly
## as before). Linear around `reference`, kept inside [low, high].
static func factor(salience: Variant, reference: float, low: float, high: float) -> float:
	if salience == null or reference <= 0.0:
		return 1.0
	return clampf(absf(float(salience)) / reference, low, high)


## `base` scaled by `scale`, rounded half away from zero. A move that was
## not zero never rounds down to nothing: salience changes how big it is,
## it never switches it off.
static func scaled(base: int, scale: float) -> int:
	if base == 0:
		return 0
	var out := int(roundf(float(base) * scale))
	if out == 0:
		out = 1 if base > 0 else -1
	return out
