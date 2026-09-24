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
const UNKNOWN := ""

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


static func _digits_after(id: String, prefix_length: int) -> bool:
	var rest := id.substr(prefix_length)
	return not rest.is_empty() and rest.is_valid_int()
