class_name RewardTargets
extends RefCounted
## What kind of thing a reward/penalty target ID is, from its own prefix.
##
## Office Hours (design/proposals/office_hours.md): a Visitor's Reward and
## Penalty columns hold a mixed list like "BO05 +1; M12; SH04" — a booster
## standing bump, a modifier grant, a shop item grant, any combination, in
## one cell. Nothing in that cell says which kind each target is; the ID
## prefix already says it, the same way the rest of the game already tells
## a BOxx from an SGxx from a card ID everywhere else. This is that one
## rule, written once, so nowhere else has to re-guess it.
##
## Pure prefix matching — no DataDB lookup, no autoload access, so it runs
## the same in a GUT test as it will in the real game. Whether a given ID
## actually EXISTS is a separate question, answered by DataDB's own
## cross-reference validation, not by this file.

const BOOSTER := "booster"
const MODIFIER := "modifier"
const SHOP_ITEM := "shop_item"
const SEGMENT := "segment"
const STAGE_EFFECT := "stage_effect"
const BOOSTER_TIER := "booster_tier"
const UNKNOWN := ""

## A booster tier group, written "TIER:Party"/"TIER:Constituency"/
## "TIER:National" — every booster of that tier is one thing to pick from
## (design/proposals/inventory.md, Cameron 2026-09-25: SH01-03/SH25-26).
## Which boosters currently belong to a tier is read live from
## DataDB.boosters, so a booster added later joins the pool with no
## workbook edit to the item itself — unlike an explicit "BO01|BO02" pool,
## which only ever means those exact IDs.
const TIER_PREFIX := "TIER:"

## The closed list of stage-effect words a Grants/Reward cell may name
## (design/proposals/inventory.md §2.2). Each is a number added to one part
## of a stage: energy per turn, starting guard, hand size, the turn limit,
## the gaffe limit. A closed list for the same reason Modifiers' Effect Type
## is one: an unknown word is a typo to report, not something to guess at.
const STAGE_EFFECT_TOKENS := ["ENERGY", "GUARD", "DRAW", "TURNS", "GAFFE_CAP"]

## Boosters (BOxx), shop items (SHxx) and segments (SGxx) checked before
## modifiers (Mxx) — not because of any real ambiguity (no real ID matches
## more than one of these four patterns) but so a typo'd "M" family prefix
## can never shadow the three two-letter ones by accident.
##
## SEGMENT (SGxx, segment_favorability) added 2026-09-25 alongside the Shop
## "Grants" column: GameState._apply_staff_reward() already moved
## segment_favorability by an SGxx target for Staff rewards, its own
## separate copy of this exact prefix rule — this is that rule made
## reusable, not a new idea.
static func kind_of(target_id: String) -> String:
	var id := target_id.strip_edges()
	if STAGE_EFFECT_TOKENS.has(id.to_upper()):
		return STAGE_EFFECT
	if id.begins_with(TIER_PREFIX) and id.length() > TIER_PREFIX.length():
		return BOOSTER_TIER
	if id.begins_with("BO") and _digits_after(id, 2):
		return BOOSTER
	if id.begins_with("SH") and _digits_after(id, 2):
		return SHOP_ITEM
	if id.begins_with("SG") and _digits_after(id, 2):
		return SEGMENT
	if id.begins_with("M") and _digits_after(id, 1):
		return MODIFIER
	return UNKNOWN


static func is_booster(target_id: String) -> bool:
	return kind_of(target_id) == BOOSTER


static func is_modifier(target_id: String) -> bool:
	return kind_of(target_id) == MODIFIER


static func is_shop_item(target_id: String) -> bool:
	return kind_of(target_id) == SHOP_ITEM


static func is_segment(target_id: String) -> bool:
	return kind_of(target_id) == SEGMENT


static func is_booster_tier(target_id: String) -> bool:
	return kind_of(target_id) == BOOSTER_TIER


## An entry's target, or the first of its pool — a pool ("BO01|BO02 +1",
## exported as "target_pool") is one kind of thing to pick from, so its
## first member speaks for its kind. Empty when neither is present.
static func first_target(entry: Dictionary) -> String:
	var pool: Variant = entry.get("target_pool")
	if pool is Array and not (pool as Array).is_empty():
		return str((pool as Array)[0])
	return str(entry.get("target", ""))


## True when an entry offers more than one thing to pick from — an explicit
## "BO01|BO02" pool, or a "TIER:X" group — either randomly (the default) or
## by a player's own choice (Items.is_player_choice()). A plain single
## target ("BO05", "M12") is neither.
static func is_pool_shaped(entry: Dictionary) -> bool:
	var pool: Variant = entry.get("target_pool")
	if pool is Array and not (pool as Array).is_empty():
		return true
	return is_booster_tier(str(entry.get("target", "")))


static func _digits_after(id: String, prefix_length: int) -> bool:
	var rest := id.substr(prefix_length)
	return not rest.is_empty() and rest.is_valid_int()
