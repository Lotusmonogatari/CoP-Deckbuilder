class_name LevelPurpose
extends RefCounted
## What a level is for, said first on its Level Intro screen (2026-11-04,
## Cameron). The text is the Levels tab's own "Level Purpose" cell; who says it
## is its "Purpose Speaker" cell, a staff role name.
##
## The speaker is the hired staff member in that role. With nobody hired in it
## (or the cell blank), it is the first hired staff member in staff.json's own
## order, and with no staff at all it is narration with no speaker (2026-11-08;
## it used to be put in the player's mouth, but it is written to "you"). Pure and
## UI-free (CLAUDE.md §12): callers hand in the level, who is hired and the
## staff directory.


## The purpose text, or "" when the level has none (a blank cell, a runtime
## patron or drafted level).
static func text_for(level: Dictionary) -> String:
	var raw: Variant = level.get("purpose")
	return "" if raw == null else str(raw).strip_edges()


## { "text", "staff_id", "staff_name", "role" } for the line; staff_id is ""
## when no staff member says it (shown as narration). {} when the level has no purpose text.
static func resolve(level: Dictionary, staff_hired: Dictionary, staff_directory: Array) -> Dictionary:
	var text := text_for(level)
	if text.is_empty():
		return {}
	var wanted_raw: Variant = level.get("purpose_speaker")
	var wanted := "" if wanted_raw == null else str(wanted_raw).strip_edges()

	var role := ""
	if not wanted.is_empty() and not (staff_hired.get(wanted, {}) as Dictionary).is_empty():
		role = wanted
	else:
		for member: Dictionary in staff_directory:
			var candidate := str(member.get("role", ""))
			if not (staff_hired.get(candidate, {}) as Dictionary).is_empty():
				role = candidate
				break

	if role.is_empty():
		return {"text": text, "staff_id": "", "staff_name": "", "role": ""}
	var staff_id := str((staff_hired[role] as Dictionary).get("staff_id", ""))
	var staff_name := staff_id
	for member: Dictionary in staff_directory:
		if str(member.get("staff_id", "")) == staff_id:
			staff_name = str(member.get("name", staff_id))
			break
	return {"text": text, "staff_id": staff_id, "staff_name": staff_name, "role": role}
