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
