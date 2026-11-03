class_name Difficulty
extends RefCounted
## Campaign Pressure (2026-11-02, Cameron): a setting the player picks at New
## Game, Relaxed, Standard or Harder, that raises or lowers the pressure of the
## whole campaign. It sits on top of each protagonist's own opening difficulty.
## Standard is the game as it always was; Relaxed and Harder change a short
## list of numbers, every one of them a Balance row named
## difficulty_<tier>_<lever> (design/proposals/difficulty_option.md).
##
## It never touches card values, energy, hand size, turn limits, intent
## patterns or any text.
##
## Pure and UI-free (CLAUDE.md section 12): GameState holds the tier and calls
## in here; every number comes from the Balance rows passed in.

const RELAXED := "relaxed"
const STANDARD := "standard"
const HARDER := "harder"
const TIERS := [RELAXED, STANDARD, HARDER]

## Balance levers a tier replaces outright (lever -> the Balance row it sets).
## The tier's own row holds the new value; Standard keeps the row as it is.
const REPLACES := {
	"dues_reward_percent": "dues_reward_percent",
	"dues_holiday_weeks": "dues_holiday_weeks",
	"week_decay_multiplier": "week_decay_multiplier",
	"promise_broken_standing": "promise_broken_standing",
	"election_gain_per_week": "election_gain_per_week",
	"election_fall_per_week": "election_fall_per_week",
	"draft_bill_funds_cost": "draft_bill_funds_cost",   # 2026-11-03: 200,000 / 300,000 / 400,000
}


static func is_tier(tier: String) -> bool:
	return TIERS.has(tier)


## 0 Relaxed, 1 Standard, 2 Harder.
static func rank(tier: String) -> int:
	return TIERS.find(tier) if is_tier(tier) else 1


## A tier can only be raised during a run, never lowered.
static func can_raise_to(current: String, wanted: String) -> bool:
	return is_tier(wanted) and rank(wanted) > rank(current)


static func row_key(tier: String, lever: String) -> String:
	return "difficulty_%s_%s" % [tier, lever]


## The tier's number for a lever, or `fallback` for Standard or a blank row.
static func number(base_balance: Dictionary, tier: String, lever: String, fallback: float) -> float:
	if tier == STANDARD or not is_tier(tier):
		return fallback
	var raw: Variant = base_balance.get(row_key(tier, lever))
	return fallback if raw == null else float(raw)


## An amount scaled by a percentage, rounded half away from zero.
static func scale(amount: int, percent: float) -> int:
	return int(round(float(amount) * percent / 100.0))


## Rewrites `live` (the Balance dictionary the game reads) for `tier`, starting
## from `base` (the workbook's numbers as loaded), in place, so every reference
## to the dictionary stays valid. Called whenever the tier changes.
static func apply_balance(live: Dictionary, base: Dictionary, tier: String) -> void:
	for lever: String in REPLACES.keys():
		var key: String = REPLACES[lever]
		if base.has(key):
			live[key] = number(base, tier, lever, float(base[key]))
	# A promise's default deadline scales as a percentage of the base hours.
	if base.has("promise_default_deadline_hours"):
		var hours := float(base["promise_default_deadline_hours"])
		live["promise_default_deadline_hours"] = maxi(1, scale(int(hours),
			number(base, tier, "promise_deadline_percent", 100.0)))


## Rewrites the shop's prices for `tier` from the workbook's own rows.
static func apply_shop(live: Array, base: Array, base_balance: Dictionary, tier: String) -> void:
	var percent := number(base_balance, tier, "item_price_percent", 100.0)
	for i in mini(live.size(), base.size()):
		var row: Dictionary = live[i]
		var original: Dictionary = base[i]
		for column in ["cost_yen", "cost_xp"]:
			var raw: Variant = original.get(column)
			if raw == null:
				continue
			row[column] = scale(int(raw), percent) if int(raw) > 0 else raw


## What a stage's reward pays on a win, scaled for the tier: positive Funds and
## XP only (a loss's penalty is never softened or sharpened here).
static func payout(amount: int, base_balance: Dictionary, tier: String) -> int:
	if amount <= 0:
		return amount
	return scale(amount, number(base_balance, tier, "reward_percent", 100.0))


## A copy of the stage with the tier's fight margin: a shared-pool room starts
## with more (or less) of the opponent's support; a single-bar room (press
## conference, TV debate) asks for more (or less) on the bar.
static func adjust_stage(stage: Dictionary, base_balance: Dictionary, tier: String) -> Dictionary:
	var points := int(number(base_balance, tier, "opponent_start", 0.0))
	if points == 0:
		return stage
	var adjusted := stage.duplicate()
	if str(stage.get("bar_model", "")) == "Single":
		adjusted["win_threshold"] = maxi(1, int(stage.get("win_threshold", 0)) + points)
	elif stage.get("opp_start") != null:
		adjusted["opp_start"] = maxi(0, int(stage.get("opp_start", 0)) + points)
	return adjusted


## The gaffe room change for the tier, never taking a room below `minimum`.
static func gaffe_limit_bonus(base_balance: Dictionary, tier: String, stage_limit: int,
		existing_bonus: int, minimum: int = 2) -> int:
	var delta := int(number(base_balance, tier, "gaffe_limit", 0.0))
	if delta == 0:
		return existing_bonus
	return maxi(existing_bonus + delta, minimum - stage_limit)


## What leftover gaffes cost awareness under the tier.
static func awareness_gaffes(leftover: int, base_balance: Dictionary, tier: String) -> int:
	if leftover <= 0:
		return leftover
	return scale(leftover, number(base_balance, tier, "awareness_gaffe_percent", 100.0))


## True while the party's dues holiday lasts: the first `holiday_weeks` weeks.
static func dues_holiday(week: int, holiday_weeks: int) -> bool:
	return holiday_weeks > 0 and week < holiday_weeks
