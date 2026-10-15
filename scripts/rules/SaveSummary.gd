class_name SaveSummary
extends RefCounted
## What a saved run looks like at a glance (2026-10-15): the last level it
## cleared, how many items it holds, its XP and its Funds. Pure: it only reads
## the run dictionary GameState.to_save() writes, so the backup label and the
## restore warning can describe both the backup and the current run the same way.


## { "level_id": "" (none cleared yet), "items": n, "xp": n, "funds": n }.
static func of(run: Dictionary) -> Dictionary:
	var cleared: Dictionary = run.get("levels_cleared", {}) as Dictionary
	var when_done: Dictionary = run.get("level_last_completed_at", {}) as Dictionary
	var last_id := ""
	var last_at := -1
	for level_id: Variant in cleared.keys():
		if int(cleared[level_id]) <= 0:
			continue
		var at := int(when_done.get(level_id, 0))
		if at >= last_at:
			last_at = at
			last_id = str(level_id)
	var items := 0
	var inventory: Dictionary = run.get("inventory", {}) as Dictionary
	for item_id: Variant in inventory.keys():
		items += int(inventory[item_id])
	var meta: Dictionary = run.get("meta", {}) as Dictionary
	return {
		"level_id": last_id,
		"items": items,
		"xp": int(run.get("xp", 0)),
		"funds": int(meta.get("Funds", 0)),
	}
