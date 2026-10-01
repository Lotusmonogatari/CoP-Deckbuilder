class_name LevelIntroCues
extends RefCounted
## Resolves data/level_intros.json against the current save: which hired
## staff have something written for the level the player is about to play,
## shown on the Level Intro screen between the Office and the level's first
## stage (2026-09-27).
##
## A role speaks only if BOTH hold: that role is hired, and a row exists for
## this exact (level_id, role) pair. Most levels/roles have no row at all —
## that role just stays silent for that level, the same "nothing written yet"
## bargain every other optional content table in this project strikes. Every
## qualifying role speaks, in staff.json's own row order (not
## staff_hired.keys(), which has no defined order) — so a level can have more
## than one staff member weigh in, each queued in turn.
##
## Pure and UI-free (CLAUDE.md §12): everything it needs is passed in, no
## autoload access, so it is tested headless like every other rules file.


## One entry per hired role with a written line for this level, in
## staff_directory's own row order: { role, staff_id, staff_name, text }.
static func resolve(cues: Array, level_id: String, staff_hired: Dictionary,
		staff_directory: Array) -> Array[Dictionary]:
	var cue_by_role: Dictionary = {}
	for row: Dictionary in cues:
		if str(row.get("level_id", "")) != level_id:
			continue
		var role := str(row.get("role", ""))
		if not cue_by_role.has(role):
			cue_by_role[role] = str(row.get("cue_text", ""))

	var result: Array[Dictionary] = []
	var seen_roles: Dictionary = {}
	for candidate: Dictionary in staff_directory:
		var role := str(candidate.get("role", ""))
		if seen_roles.has(role):
			continue
		seen_roles[role] = true
		if not cue_by_role.has(role):
			continue
		var hired: Dictionary = staff_hired.get(role, {})
		if hired.is_empty():
			continue
		var staff_id := str(hired.get("staff_id", ""))
		var staff_name := staff_id
		for member: Dictionary in staff_directory:
			if str(member.get("staff_id", "")) == staff_id:
				staff_name = str(member.get("name", staff_id))
				break
		result.append({
			"role": role,
			"staff_id": staff_id,
			"staff_name": staff_name,
			"text": cue_by_role[role],
		})
	return result


## The player's own internal thought about this level, from
## data/level_intro_thoughts.json — entirely optional, one row per level_id.
## "" when nothing is written. Kept as its own lookup (not folded into
## resolve()'s staff loop above) because a thought is the level's own, not
## any one staff member's role.
static func player_thought(thoughts: Array, level_id: String) -> String:
	for row: Dictionary in thoughts:
		if str(row.get("level_id", "")) == level_id:
			return str(row.get("thought_text", ""))
	return ""
