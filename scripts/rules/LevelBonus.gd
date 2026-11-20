class_name LevelBonus
extends RefCounted
## A level's end-of-level bonus, as the briefing previews it (2026-11-19, Cameron: "Show all of it").
##
## A level that is won also pays its own bonus: a range for each of Constituency support, Funds,
## Reputation, XP and Party support (the Levels tab's "Bonus Win Range" columns) and a range of standing
## for each organization (its "Win ΔBOxx" columns). GameState._apply_level_bonus_win() rolls and pays them.
## Until now the briefing showed only each room's own rewards, so none of this was said first (Information
## Standard 1). This file is the one place that knows which columns are the bonus, so the preview and
## the payout read the same ones and cannot drift apart.
##
## Pure and UI-free (CLAUDE.md section 12).

## The Levels columns that pay a meta number, and the meta number each pays. The order is the order the
## payout rolls them in (each roll uses the random generator, so the order is part of what a payout is).
const META_COLUMNS := {
	"bonus_win_range_jiban": "Constituency support",
	"bonus_win_range_yen": "Funds",
	"bonus_win_range_reputation": "Reputation",
	"bonus_win_range_party_support": "Party support",
}

## The Levels column that pays XP.
const XP_COLUMN := "bonus_win_range_xp"

## An organization's column is this plus its id in lower case ("win_delta_" + "bo05").
const ORG_COLUMN_START := "win_delta_"
const ORG_ID_START := "bo"


## The column that holds `org_id`'s ("BO05") bonus range.
static func column_for(org_id: String) -> String:
	return ORG_COLUMN_START + org_id.to_lower()


## The organization id a column belongs to ("win_delta_bo05" -> "BO05"), or "" for any other column.
static func org_for(column: String) -> String:
	if not column.begins_with(ORG_COLUMN_START + ORG_ID_START):
		return ""
	return column.substr(ORG_COLUMN_START.length()).to_upper()


## One range cell as {"min", "max"}, or {} for a blank or malformed cell. A max below the min counts as the
## min, as the payout's roll does.
static func range_of(cell: Variant) -> Dictionary:
	if not (cell is Dictionary) or not (cell as Dictionary).has("min"):
		return {}
	var low := int((cell as Dictionary)["min"])
	var high := int((cell as Dictionary).get("max", low))
	return {"min": low, "max": maxi(low, high)}


## What winning `level` pays on top of its rooms, as
## { "meta": { name: {min, max} }, "orgs": [ {id, min, max} ] }. The name XP is BriefingSummary.XP. Funds
## and XP are after the Campaign Pressure's payout scaling (Difficulty.payout, the same call the payout
## makes), so a number shown is a number that can be paid. A range that can only pay zero is left out.
## Not previewed, as with the rooms' rewards: backings the player owns, a Funding Freeze, and the standing
## other organizations pass along.
static func preview(level: Dictionary, tier: String, base_balance: Dictionary) -> Dictionary:
	var meta := {}
	for column: String in META_COLUMNS.keys():
		var name: String = META_COLUMNS[column]
		_add_meta(meta, name, range_of(level.get(column)), name == "Funds", tier, base_balance)
	_add_meta(meta, BriefingSummary.XP, range_of(level.get(XP_COLUMN)), true, tier, base_balance)

	var orgs: Array = []
	var columns: Array = level.keys()
	columns.sort()
	for column: String in columns:
		var org_id := org_for(column)
		if org_id.is_empty():
			continue
		var bounds := range_of(level.get(column))
		if bounds.is_empty() or (int(bounds["min"]) == 0 and int(bounds["max"]) == 0):
			continue
		orgs.append({"id": org_id, "min": int(bounds["min"]), "max": int(bounds["max"])})
	return {"meta": meta, "orgs": orgs}


## True when the level pays no bonus at all.
static func is_empty(bonus: Dictionary) -> bool:
	return (bonus.get("meta", {}) as Dictionary).is_empty() and (bonus.get("orgs", []) as Array).is_empty()


static func _add_meta(meta: Dictionary, name: String, bounds: Dictionary, scaled: bool, tier: String,
		base_balance: Dictionary) -> void:
	if bounds.is_empty():
		return
	var low := int(bounds["min"])
	var high := int(bounds["max"])
	if scaled:
		low = Difficulty.payout(low, base_balance, tier)
		high = Difficulty.payout(high, base_balance, tier)
	if low == 0 and high == 0:
		return
	meta[name] = {"min": low, "max": high}
