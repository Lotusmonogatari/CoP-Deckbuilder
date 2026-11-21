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
		# An Optional follow-up is opened by the player from the Events screen, never by itself.
		if not (scene is Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))) or is_optional(scene as Dictionary):
			continue
		var day := due_day(scene as Dictionary, log)
		if day >= 0 and day >= first and day <= last:
			found.append({"day": day, "scene": scene})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	var out: Array = []
	for entry: Dictionary in found:
		out.append(entry["scene"])
	return out


# --- Optional scenes (phase 4) -------------------------------------------------------------------------------------------------
# An Optional scene is opened by the player from the Events screen, at its own office, while its window is open. The window runs
# from Opens (a first scene) or the day its Delay runs out (a follow-up) to Closes. If it closes unopened the scene LAPSES: it is
# remembered as answered with the reserved choice letter L, and that choice's effects are the penalty. Optional scenes never open
# by themselves and never move the player.

## The reserved choice letter an Optional scene's penalty lives under. It is never shown as a button.
const LAPSE_LETTER := "L"


static func is_optional(scene: Dictionary) -> bool:
	return str(scene.get("kind", MANDATORY)) == OPTIONAL


## [first day, last day] a scene can be opened, as day numbers; [-1, -1] when it has no window yet (a follow-up whose earlier
## scene is not answered, or a cell that is not a date).
static func window(scene: Dictionary, log: Dictionary) -> Array[int]:
	var closes := WeekCalendar.parse_date(str(scene.get("closes", ""))) if scene.get("closes") != null else -1
	var opens := due_day(scene, log) if is_follow_up(scene) \
		else (WeekCalendar.parse_date(str(scene.get("opens", ""))) if scene.get("opens") != null else -1)
	if opens < 0 or closes < 0:
		return [-1, -1]
	return [opens, closes]


## The Optional scenes that can be opened today and have not been answered or lapsed, earliest closing first.
static func open_now(scenes: Array, log: Dictionary, today: int) -> Array:
	var found: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or not is_optional(scene as Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))):
			continue
		var span := window(scene as Dictionary, log)
		if span[0] >= 0 and span[0] <= today and today <= span[1]:
			found.append({"closes": span[1], "scene": scene})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["closes"]) < int(b["closes"]))
	var out: Array = []
	for entry: Dictionary in found:
		out.append(entry["scene"])
	return out


## The Optional scenes whose window opens after today and within `days_ahead` days.
static func optional_upcoming(scenes: Array, log: Dictionary, today: int, days_ahead: int) -> Array:
	var out: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or not is_optional(scene as Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))):
			continue
		var span := window(scene as Dictionary, log)
		if span[0] > today and span[0] <= today + days_ahead:
			out.append(scene)
	return out


## The Optional scenes whose window closed before today without being opened.
static func lapsed(scenes: Array, log: Dictionary, today: int) -> Array:
	var out: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or not is_optional(scene as Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))):
			continue
		var span := window(scene as Dictionary, log)
		if span[1] >= 0 and span[1] < today:
			out.append(scene)
	return out


## Days left to open a scene, counting today (1 on its last day); 0 when it is not open today.
static func days_left(scene: Dictionary, log: Dictionary, today: int) -> int:
	var span := window(scene, log)
	return span[1] - today + 1 if span[0] >= 0 and span[0] <= today and today <= span[1] else 0


# --- Activations (phase 3) -----------------------------------------------------------------------------------------------------
# The Activates column lists what answering a scene starts: `kind:ID` entries separated by `;`, each optionally limited to some
# of the earlier choices with `@A,B` ("level:LV12@A; event:EV30"). Kinds: level (an existing level), stage (one room on its own),
# vote (a Floor Vote on a named bill or motion), event (an event queued for the next Office visit), unlock (a level made
# available). level, stage and vote begin as a level; event and unlock are applied at once.

const KIND_LEVEL := "level"
const KIND_STAGE := "stage"
const KIND_VOTE := "vote"
const KIND_EVENT := "event"
const KIND_UNLOCK := "unlock"
const ACTIVATION_KINDS: Array[String] = [KIND_LEVEL, KIND_STAGE, KIND_VOTE, KIND_EVENT, KIND_UNLOCK]
## The kinds that begin as a level, in a battle or vote screen.
const LEVEL_KINDS: Array[String] = [KIND_LEVEL, KIND_STAGE, KIND_VOTE]
## The ID prefix of the one-stage levels built for stage and vote activations.
const AD_HOC_PREFIX := "DSL_"


## The entries of an Activates cell as [{"kind", "id", "letters"}], in order. A piece that is not `kind:ID` is skipped (the
## exporter rejects it); `letters` is [] for "any choice".
static func parse_activates(cell: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if cell == null:
		return out
	for piece: String in str(cell).split(";"):
		var text := piece.strip_edges()
		var letters: Array[String] = []
		if text.contains("@"):
			for letter: String in text.get_slice("@", 1).split(","):
				if not letter.strip_edges().is_empty():
					letters.append(letter.strip_edges().to_upper())
			text = text.get_slice("@", 0).strip_edges()
		if not text.contains(":"):
			continue
		var kind := text.get_slice(":", 0).strip_edges().to_lower()
		var id := text.get_slice(":", 1).strip_edges()
		if not kind.is_empty() and not id.is_empty():
			out.append({"kind": kind, "id": id, "letters": letters})
	return out


## The activations of a scene that the choice `letter` triggers.
static func activations_for(scene: Dictionary, letter: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in parse_activates(scene.get("activates")):
		var letters: Array = entry["letters"]
		if letters.is_empty() or letters.has(letter.to_upper()):
			out.append(entry)
	return out


## The one-stage level a stage or vote activation plays: the stage (or the bill, whose Floor Vote stage it is) as its only
## stage. `description` is what the briefing calls it; `office` is where it happens.
static func ad_hoc_level(kind: String, id: String, description: String, office: String) -> Dictionary:
	return {"level_id": AD_HOC_PREFIX + kind + "_" + id, "description": description, "tier": 0, "stage_1": id,
		"event_only": "Yes", "location": office if office != "Either" else null, "decision_scene": true}


static func is_ad_hoc_level_id(level_id: String) -> bool:
	return level_id.begins_with(AD_HOC_PREFIX)


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
