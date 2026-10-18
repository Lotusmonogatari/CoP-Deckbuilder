class_name TimeClock
extends RefCounted
## The game's quiet clock (2026-10-18, Cameron). Finishing a stage moves it on
## by that stage's Time Units (the Stages tab; blank = 1). The player never
## sees the number or any word for it: it only decides WHEN things happen --
## when a special level appears, how long an effect lasts, when a cooldown ends.
##
## Pure and UI-free (CLAUDE.md section 12).

## What a stage with a blank Time Units cell costs.
const DEFAULT_STAGE_UNITS := 1


## How many units finishing this stage costs: its own Time Units cell, or one.
## A blank cell is JSON null (the <null> trap); a negative number counts as 0.
static func units_for_stage(stage: Dictionary) -> int:
	var raw: Variant = stage.get("time_units")
	if raw == null or str(raw).strip_edges().is_empty():
		return DEFAULT_STAGE_UNITS
	return maxi(0, int(raw))


## Whether a countdown started at `started_at` has run its `delay` by `now`.
static func has_elapsed(started_at: int, delay: int, now: int) -> bool:
	return now - started_at >= delay
