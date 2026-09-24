class_name Items
extends RefCounted
## The rules for shop items (SHxx): what one costs, whether it can be bought,
## where it can be used, and what using it does.
##
## Every answer comes from the item's own row in the Shop tab
## (design/proposals/inventory.md), so changing whether a cosmetic can be
## used mid-stage, or how many Coffees a player may carry, is a workbook
## edit rather than a code change:
##
##   Use In Office / Use In Stage   Yes/No: where the Use button works
##   Duration                       Stage or Level: how long a stage effect lasts
##   Uses Per Turn                  how often it may be used in one turn of a stage
##   Stack Cap                      how many the player may hold (blank = no cap)
##   Purchase Limit                 how many may be bought per level (blank = no limit)
##   Grants                         what using it does (target_delta_list)
##
## Pure, like everything in scripts/rules/: no autoload, no file, no scene.
## Callers hand over the item row and the counts; refusals come back as the
## words the player reads, from the Text tab.

const OFFICE := "office"
const STAGE := "stage"

const DURATION_STAGE := "stage"
const DURATION_LEVEL := "level"


## A workbook Yes/No cell. Blank, null or anything but a yes is No, so an
## item nobody has filled in yet is safely unusable rather than surprising.
static func is_yes(value: Variant) -> bool:
	if value == null:
		return false
	return ["yes", "y", "true", "1"].has(str(value).strip_edges().to_lower())


static func usable_in(item: Dictionary, context: String) -> bool:
	match context:
		OFFICE:
			return is_yes(item.get("use_in_office"))
		STAGE:
			return is_yes(item.get("use_in_stage"))
	return false


## "stage" or "level". Blank means one stage.
static func duration(item: Dictionary) -> String:
	var value: Variant = item.get("duration")
	if value == null:
		return DURATION_STAGE
	return DURATION_LEVEL if str(value).strip_edges().to_lower() == DURATION_LEVEL else DURATION_STAGE


## How many times it may be used in one turn of a stage. Blank means once —
## Cameron's default, 2026-09-25.
static func uses_per_turn(item: Dictionary) -> int:
	return _positive_int(item.get("uses_per_turn"), 1)


## How many may be held at once. 0 means no cap.
static func stack_cap(item: Dictionary) -> int:
	return _positive_int(item.get("stack_cap"), 0)


## How many may be bought per level. 0 means no limit. The count resets when
## a level concludes, win or loss (GameState.finish_stage()).
static func purchase_limit(item: Dictionary) -> int:
	return _positive_int(item.get("purchase_limit"), 0)


## { "XP": n, "Funds": n } — either or both may be charged.
static func costs(item: Dictionary) -> Dictionary:
	return {
		"XP": maxi(_positive_int(item.get("cost_xp"), 0), 0),
		"Funds": maxi(_positive_int(item.get("cost_yen"), 0), 0),
	}


## The item's Grants list, split into what moves standing right away (a
## booster, a segment, a modifier, another item) and what changes a stage
## (ENERGY, GUARD, DRAW, TURNS, GAFFE_CAP).
static func split_grants(item: Dictionary) -> Dictionary:
	var meta: Array = []
	var stage: Array = []
	var grants: Variant = item.get("grants")
	if grants is Array:
		for entry: Variant in grants:
			if not (entry is Dictionary):
				continue
			if RewardTargets.kind_of(RewardTargets.first_target(entry)) == RewardTargets.STAGE_EFFECT:
				stage.append(entry)
			else:
				meta.append(entry)
	return {"meta": meta, "stage": stage}


## True when using it would do something. An item whose Grants cell is still
## blank is refused rather than silently used up.
static func has_effect(item: Dictionary) -> bool:
	var split := split_grants(item)
	return not ((split["meta"] as Array).is_empty() and (split["stage"] as Array).is_empty())


## Why this item cannot be bought, in the player's words, or "" when it can.
## `held` is how many the player has, `bought` how many this level.
static func buy_refusal(item: Dictionary, held: int, bought: int, xp: int, funds: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	if str(item.get("item_id", "")).is_empty():
		return say.say("shop.item_no_id")

	var limit := purchase_limit(item)
	if limit > 0 and bought >= limit:
		return say.say("shop.out_of_stock")

	var cap := stack_cap(item)
	if cap > 0 and held >= cap:
		return say.say("shop.stack_full")

	var price := costs(item)
	if xp < int(price["XP"]):
		return say.say("shop.xp_short", {"count": int(price["XP"]) - xp})
	if funds < int(price["Funds"]):
		return say.say("shop.funds_short", {"count": int(price["Funds"]) - funds})
	return ""


## True when the reason an item cannot be bought is its purchase limit — the
## Supplies row greys it out and says "Out of Stock" rather than a price.
static func is_out_of_stock(item: Dictionary, bought: int) -> bool:
	var limit := purchase_limit(item)
	return limit > 0 and bought >= limit


## Why this item cannot be used here, or "" when it can. The per-turn limit
## is the battle's to enforce (BattleEngine.use_item()), since only the
## battle knows when a turn ends.
static func use_refusal(item: Dictionary, context: String, held: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	if held <= 0:
		return say.say("item.refused.none_left")
	if not usable_in(item, context):
		return say.say("item.refused.not_here")
	if not has_effect(item):
		return say.say("item.refused.no_effect")
	return ""


## The line in the item pop-up saying when its effect lands.
static func timing_line(item: Dictionary, context: String, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	if (split_grants(item)["stage"] as Array).is_empty():
		return say.say("item.timing.now")
	var level := duration(item) == DURATION_LEVEL
	if context == STAGE:
		return say.say("item.timing.level_now" if level else "item.timing.stage_now")
	return say.say("item.timing.level_next" if level else "item.timing.stage_next")


static func _positive_int(value: Variant, fallback: int) -> int:
	if value == null:
		return fallback
	var text := str(value).strip_edges()
	if text.is_empty() or not text.is_valid_float():
		return fallback
	return maxi(int(float(text)), 0)
