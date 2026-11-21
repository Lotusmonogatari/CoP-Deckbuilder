class_name DecisionScenes
extends RefCounted
## Decision! scenes (2026-11-21, Cameron): the calendar's own moments, one row each in the Decision Scenes tab. A scene names the
## event that holds its title, flavor, choices and effects, and adds what only a scene has: Mandatory or Optional, the office it
## happens at, who speaks, the face they wear and the pictures behind it. Pure: no screens, no autoloads, no files (the tests
## prove it). The design is in design/proposals/DECISION_SCENES_SCHEME_2026-11-21.md.

const MANDATORY := "Mandatory"
const OPTIONAL := "Optional"
const FACES: Array[String] = ["neutral", "attacking", "gaining"]


## The scene row that holds an event, or {} when the event is not a scene.
static func of_event(scenes: Array, event_id: String) -> Dictionary:
	for scene: Variant in scenes:
		if scene is Dictionary and str((scene as Dictionary).get("event_id", "")) == event_id:
			return scene as Dictionary
	return {}


## The scene row with this Scene ID, or {}.
static func find(scenes: Array, scene_id: String) -> Dictionary:
	for scene: Variant in scenes:
		if scene is Dictionary and str((scene as Dictionary).get("scene_id", "")) == scene_id:
			return scene as Dictionary
	return {}


## Mandatory scenes open by themselves and take the player to their office; an unknown or blank Kind counts as Mandatory (the
## exporter refuses anything else, so this only guards a hand-edited file).
static func is_mandatory(scene: Dictionary) -> bool:
	return str(scene.get("kind", MANDATORY)) != OPTIONAL


## The speaker IDs of a scene, first speaker then second, blanks left out.
static func speaker_ids(scene: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for column: String in ["speaker", "second_speaker"]:
		var raw: Variant = scene.get(column)
		if raw != null and not str(raw).strip_edges().is_empty():
			out.append(str(raw).strip_edges())
	return out


## The face a speaker wears: neutral, attacking or gaining. A blank or unknown cell is neutral.
static func face(scene: Dictionary) -> String:
	var raw := str(scene.get("speaker_face", "")).strip_edges().to_lower() if scene.get("speaker_face") != null else ""
	return raw if FACES.has(raw) else "neutral"


## The office a scene happens at ("Capitol" or "District"); blank means Either.
static func office(scene: Dictionary) -> String:
	var raw: Variant = scene.get("office")
	return "Either" if raw == null or str(raw).strip_edges().is_empty() else str(raw).strip_edges()


# --- Follow-ups (phase 2) ------------------------------------------------------------------------------------------------------
# A follow-up is a scene row that names the scene it Follows, a Delay in days counted from the day the earlier scene was ANSWERED,
# and (optionally) the choice letters of the earlier scene that lead to it (Follow If; blank = any). Different choices can lead to
# different follow-ups (branching). `log` is {scene_id: {"day": <day number it was answered>, "choice": "<letter>"}}.

## The most follow-ups one first scene may have in total, down every branch (Cameron, 2026-11-21).
const MAX_FOLLOW_UPS := 5


static func is_follow_up(scene: Dictionary) -> bool:
	var raw: Variant = scene.get("follows")
	return raw != null and not str(raw).strip_edges().is_empty()


## The scene IDs an earlier scene's choice has to be one of, for a follow-up to come; [] means any choice.
static func follow_if(scene: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = scene.get("follow_if")
	if raw is Array:
		for letter: Variant in raw as Array:
			if not str(letter).strip_edges().is_empty():
				out.append(str(letter).strip_edges().to_upper())
	return out


## The scenes that follow `scene_id` directly, in the tab's order.
static func children_of(scenes: Array, scene_id: String) -> Array:
	var out: Array = []
	for scene: Variant in scenes:
		if scene is Dictionary and str((scene as Dictionary).get("follows", "")) == scene_id:
			out.append(scene)
	return out


## How many follow-ups hang under `scene_id`, down every branch. A loop is cut off rather than followed forever.
static func descendant_count(scenes: Array, scene_id: String) -> int:
	var seen := {scene_id: true}
	var queue: Array = [scene_id]
	var count := 0
	while not queue.is_empty():
		var next := str(queue.pop_front())
		for child: Dictionary in children_of(scenes, next):
			var id := str(child.get("scene_id", ""))
			if not seen.has(id):
				seen[id] = true
				count += 1
				queue.append(id)
	return count


## The day a follow-up comes due: the day its earlier scene was answered plus its Delay; -1 when it cannot come (the earlier
## scene has not been answered, the choice made is not in Follow If, or the scene is not a follow-up).
static func due_day(scene: Dictionary, log: Dictionary) -> int:
	if not is_follow_up(scene):
		return -1
	var parent: Variant = log.get(str(scene.get("follows")))
	if not (parent is Dictionary):
		return -1
	var wanted := follow_if(scene)
	if not wanted.is_empty() and not wanted.has(str((parent as Dictionary).get("choice", "")).to_upper()):
		return -1
	var delay: Variant = scene.get("delay")
	return int((parent as Dictionary).get("day", 0)) + (0 if delay == null else int(delay))


## The follow-ups due on or before `today` that have not happened, earliest first (ties in the tab's order).
static func due_follow_ups(scenes: Array, log: Dictionary, today: int) -> Array:
	return _follow_ups_between(scenes, log, -1000000, today)


## The follow-ups that will come due after `today` and within `days_ahead` days, earliest first.
static func upcoming_follow_ups(scenes: Array, log: Dictionary, today: int, days_ahead: int) -> Array:
	return _follow_ups_between(scenes, log, today + 1, today + days_ahead)


static func _follow_ups_between(scenes: Array, log: Dictionary, first: int, last: int) -> Array:
	var found: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))):
			continue
		var day := due_day(scene as Dictionary, log)
		if day >= 0 and day >= first and day <= last:
			found.append({"day": day, "scene": scene})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	var out: Array = []
	for entry: Dictionary in found:
		out.append(entry["scene"])
	return out


## What kind of person an ID names, by its prefix: "opponent" (OP..), "staff" (SF..), "visitor" (VI..), or "" for anything else.
static func person_kind(id: String) -> String:
	if id.begins_with("OP"):
		return "opponent"
	if id.begins_with("SF"):
		return "staff"
	if id.begins_with("VI"):
		return "visitor"
	return ""


## The pictures a scene names, in order; blank gives none.
static func pictures(scene: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = scene.get("scene_picture")
	if raw is Array:
		for id: Variant in raw as Array:
			if not str(id).strip_edges().is_empty():
				out.append(str(id).strip_edges())
	return out
