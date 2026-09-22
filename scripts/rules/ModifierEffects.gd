class_name ModifierEffects
extends RefCounted
## What an organisation's backing actually does.
##
## 2026-09-22 workbook: modifiers.json now carries the machine-readable half
## directly — "Effect Type" / "Effect Target" / "Effect Value" columns — so
## the hand-written bridge (data/modifier_effects.json) that used to fill in
## for a missing "effect key" column is gone, and so is this file's old
## key/magnitude scheme. Every modifier row now says exactly what it does.
##
## THE FIVE TYPES (CLAUDE.md's migration brief, 2026-09-22):
##
##   RESOURCE_BONUS_ON_WIN  target XP/Yen/Jiban/PartySupport, value a flat
##                          amount paid out when a LEVEL is won — not a
##                          stage. The workbook's own Effect column says so
##                          ("...after successful completion of a level"),
##                          which is why GameState pays this out only once
##                          the whole level finishes, not stage by stage.
##   STAGE_START_BONUS      target an STxx, value added to that stage's
##                          starting support before the first turn.
##   HAND_SIZE_BONUS        target an STxx, value +N cards drawn at the start
##                          of that stage.
##   GAFFE_LIMIT_BONUS      target an STxx, value +N to the gaffe limit for
##                          that stage.
##   UNLOCK_DISCOUNT        target XPCost or Tier1Cost, value a fraction
##                          (0.1 = 10%) off that unlock cost.
##
## All five are genuinely wired now — the old file only ever implemented two
## of eleven hand-written keys and called the rest "not active yet". Where a
## modifier is not owned, or its trigger condition (MetaRules.active_modifiers)
## is not met in this stage's room, it simply contributes nothing; that is a
## normal day for a modifier, not a bug.

const RESOURCE_BONUS_ON_WIN := "RESOURCE_BONUS_ON_WIN"
const STAGE_START_BONUS := "STAGE_START_BONUS"
const HAND_SIZE_BONUS := "HAND_SIZE_BONUS"
const GAFFE_LIMIT_BONUS := "GAFFE_LIMIT_BONUS"
const UNLOCK_DISCOUNT := "UNLOCK_DISCOUNT"

const KNOWN_TYPES := [
	RESOURCE_BONUS_ON_WIN, STAGE_START_BONUS, HAND_SIZE_BONUS,
	GAFFE_LIMIT_BONUS, UNLOCK_DISCOUNT,
]

## Which sanban.json meta-variable a RESOURCE_BONUS_ON_WIN target name means.
## "XP" is not a sanban row (it lives on GameState instead), so it is handled
## separately wherever this map is used.
const RESOURCE_TARGET_TO_META := {
	"Yen": "Funds",
	"Jiban": "Constituency support",
	"PartySupport": "Party support",
}


## The effect_value column, as a float — the workbook stores it as a real
## number already (10, 0.1, ...), never a "Magnitude" placeholder to resolve.
static func value_of(modifier: Dictionary) -> float:
	var value: Variant = modifier.get("effect_value")
	return 0.0 if value == null else float(value)


static func type_of(modifier: Dictionary) -> String:
	return str(modifier.get("effect_type", ""))


static func target_of(modifier: Dictionary) -> String:
	return str(modifier.get("effect_target", ""))


## True where the modifier's effect_type is one this file knows how to run.
## Every modifier in the 2026-09-22 workbook has one of the five, so this is
## really "is the Effect Type column filled in", but it is asked the same way
## a missing/blank value would be.
static func is_implemented(modifier: Dictionary) -> bool:
	return KNOWN_TYPES.has(type_of(modifier))


## What a modifier does, in words for the player.
##
## RESOURCE_BONUS_ON_WIN targeting Yen has a Text tab line already
## (modifier.reputation_per_stage_win) from when this used to be the one
## hand-built case; every other combination is shown straight from the
## workbook's own "Effect" column, which — unlike the old "+Magnitude..."
## wording — already reads as a finished sentence with the real number in it.
## That column is exactly what CLAUDE.md calls display-only prose: showing it
## verbatim is not the rules engine parsing a sentence, any more than showing
## a card's effect_text is.
static func describe(modifier: Dictionary, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	if type_of(modifier) == RESOURCE_BONUS_ON_WIN and target_of(modifier) == "Yen":
		return say.say("modifier.reputation_per_stage_win", {"count": int(round(value_of(modifier)))})
	return str(modifier.get("effect", "")).strip_edges()


## What the owned, active modifiers add to a stage before its first turn.
##
## `active` is already filtered to modifiers whose trigger condition is met
## in this stage's room (MetaRules.active_modifiers). `stage_id` narrows the
## three stage-scoped types to the ones actually aimed at this stage — a
## STAGE_START_BONUS written for ST04 does nothing in ST02.
static func battle_start_bonus(active: Array, stage_id: String) -> Dictionary:
	var bonus := {"start_support": 0, "hand_size_bonus": 0, "gaffe_limit_bonus": 0}

	for modifier: Dictionary in active:
		if target_of(modifier) != stage_id:
			continue
		var value := int(round(value_of(modifier)))
		match type_of(modifier):
			STAGE_START_BONUS:
				bonus["start_support"] += value
			HAND_SIZE_BONUS:
				bonus["hand_size_bonus"] += value
			GAFFE_LIMIT_BONUS:
				bonus["gaffe_limit_bonus"] += value

	return bonus


## What the owned modifiers pay a resource when a LEVEL is won.
##
## `resource` is "XP", or one of RESOURCE_TARGET_TO_META's meta-variable
## names ("Funds", "Constituency support", "Party support") — whichever the
## caller is about to pay out. Unlike battle_start_bonus this does not filter
## by room: the workbook's own wording says these pay out for winning the
## level, not for who was watching.
static func level_win_resource_bonus(owned: Array, resource: String) -> int:
	var target := resource
	for key: String in RESOURCE_TARGET_TO_META.keys():
		if RESOURCE_TARGET_TO_META[key] == resource:
			target = key
			break

	var total := 0
	for modifier: Dictionary in owned:
		if type_of(modifier) == RESOURCE_BONUS_ON_WIN and target_of(modifier) == target:
			total += int(round(value_of(modifier)))
	return total


## The fraction knocked off an unlock cost by the owned UNLOCK_DISCOUNT
## modifiers, e.g. 0.1 for 10% off. `cost_kind` is "XPCost" or "Tier1Cost" —
## the two target names the workbook's Levels-unlock costs use. Discounts
## from more than one modifier add together rather than compounding, which is
## the simpler reading and the one worth changing first if Cameron wants
## something else.
static func unlock_discount(owned: Array, cost_kind: String) -> float:
	var discount := 0.0
	for modifier: Dictionary in owned:
		if type_of(modifier) == UNLOCK_DISCOUNT and target_of(modifier) == cost_kind:
			discount += value_of(modifier)
	return discount
