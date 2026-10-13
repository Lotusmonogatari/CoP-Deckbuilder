class_name TextScale
extends RefCounted
## The text-size setting (plan step 5, design/DYNAMIC_SCREEN_PLAN.md): Small,
## Normal or Large, which multiplies every font size in the project theme.
## Pure: the percentages live on the Balance tab (`text_scale_small`,
## `text_scale_large`; Normal is always 100).

const SMALL := "small"
const NORMAL := "normal"
const LARGE := "large"
const ORDER := [SMALL, NORMAL, LARGE]


## The setting after `current` when the player taps the button.
static func next(current: String) -> String:
	var i := ORDER.find(current)
	return ORDER[(i + 1) % ORDER.size()] if i >= 0 else NORMAL


## The multiplier for a setting, from the Balance levers (percent).
## Unknown settings and missing levers mean "no change".
static func factor(setting: String, balance: Dictionary) -> float:
	var percent := 100.0
	match setting:
		SMALL: percent = float(balance.get("text_scale_small", 100))
		LARGE: percent = float(balance.get("text_scale_large", 100))
	return maxf(percent, 50.0) / 100.0


## A font size under a factor, never below 8 px.
static func scaled(size: int, factor_value: float) -> int:
	return maxi(8, roundi(float(size) * factor_value))
