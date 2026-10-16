class_name BoosterStanding
extends RefCounted
## How far one organisation's standing moves from the answers given in one
## stage (2026-10-16, Cameron). Pure arithmetic, no UI: the outcome panel and
## GameState both call it, so the number shown is the number that lands.
##
## Three rules, all levers in data/booster_standing.json:
##  - every answer counts (a strong answer pleases, a weak one annoys, a strong
##    answer on an opposed theme sets back), not just the first of a stage;
##  - gains shrink and penalties grow as standing rises (`gain_bands`,
##    `loss_bands`: ordered {below, factor} steps, the last with no "below");
##  - the stage's total for one organisation is clamped to +/- `question_swing_cap`.


## Builds {booster_id: {pleased, displeased, opposed}} counts. A caller that
## only has the old deduplicated lists gets one answer each.
static func tallies(pleased: Array, displeased: Array, opposed: Array,
		tally: Dictionary = {}) -> Dictionary:
	if not tally.is_empty():
		return tally
	var out := {}
	for pair: Array in [["pleased", pleased], ["displeased", displeased], ["opposed", opposed]]:
		for booster_id: String in (pair[1] as Array):
			var row: Dictionary = out.get(booster_id, {"pleased": 0, "displeased": 0, "opposed": 0})
			row[pair[0]] = int(row[pair[0]]) + 1
			out[booster_id] = row
	return out


## The multiplier for a standing from an ordered band list; 1.0 with no bands.
static func band_factor(bands: Array, standing: int) -> float:
	for band: Variant in bands:
		var step: Dictionary = band
		if not step.has("below") or standing < int(step["below"]):
			return float(step.get("factor", 1.0))
	return 1.0


## One organisation's net change for the stage, before any crush penalty.
static func net_for(row: Dictionary, current: int, cfg: Dictionary) -> int:
	var gain := int(row.get("pleased", 0)) * int(cfg.get("per_please", 5))
	var loss := int(row.get("displeased", 0)) * int(cfg.get("per_displease", 3)) \
		+ int(row.get("opposed", 0)) * int(cfg.get("per_opposed", 3))
	var gained := _scaled(gain, band_factor(cfg.get("gain_bands", []), current))
	var lost := _scaled(loss, band_factor(cfg.get("loss_bands", []), current))
	var cap := int(cfg.get("question_swing_cap", 10))
	return clampi(gained - lost, -cap, cap)


## A non-zero amount never rounds away to nothing.
static func _scaled(amount: int, factor: float) -> int:
	if amount == 0:
		return 0
	return maxi(roundi(amount * factor), 1)


## The standing an organisation drifts toward when ignored for a level, one
## step (`neglect_decay`) closer to `start`.
static func decayed(current: int, start: int, step: int) -> int:
	if step <= 0 or current == start:
		return current
	if current > start:
		return maxi(current - step, start)
	return mini(current + step, start)
