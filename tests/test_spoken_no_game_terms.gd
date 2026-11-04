extends GutTest
## No character talks about the game itself (2026-11-04, Cameron): spoken
## lines never say "this level", "the next stage" and the like. Ordinary
## English stays allowed: "at this stage" (a hedge), "the stage" a speaker
## stands on, a "level" voice or playing field.

const MECHANIC := "(?i)\\b(this|next|each|every|previous|last|the next|that|whole|later) (levels?|stages?)\\b"
const IDIOMS := ["at this stage", "share this stage", "take the stage", "from the stage"]

## [file, fields] of everything a character says. An empty field list means
## every string field of the file.
const SPOKEN := [
	["levels", ["purpose"]], ["player_cues", []], ["opponent_cues", []], ["card_cues", []],
	["transition_dialogue", []], ["level_intro_thoughts", []], ["level_intros", []],
	["vote_influence_cues", []], ["visitor_questions", []], ["lobbyist_lines", []],
]


func test_no_character_line_names_a_level_or_stage() -> void:
	var rx := RegEx.create_from_string(MECHANIC)
	var bad: Array[String] = []
	for entry: Array in SPOKEN:
		var path := "res://data/%s.json" % entry[0]
		if not FileAccess.file_exists(path):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		for text: String in _strings(data, entry[1]):
			var low := text.to_lower()
			var cleaned := low
			for idiom: String in IDIOMS:
				cleaned = cleaned.replace(idiom, "")
			if rx.search(cleaned) != null:
				bad.append("%s: %s" % [entry[0], text])
	assert_eq(bad, [] as Array[String], "characters must not talk about levels or stages")


func _strings(value: Variant, fields: Array, key: String = "") -> Array[String]:
	var out: Array[String] = []
	if value is Dictionary:
		for k: Variant in value:
			if str(k).ends_with("_id") or str(k) in ["stages", "note", "_README"]:
				continue
			out.append_array(_strings(value[k], fields, str(k)))
	elif value is Array:
		for item: Variant in value:
			out.append_array(_strings(item, fields, key))
	elif value is String and (fields.is_empty() or key in fields):
		out.append(value)
	return out
