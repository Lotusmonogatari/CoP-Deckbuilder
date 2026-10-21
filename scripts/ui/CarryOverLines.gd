class_name CarryOverLines
extends RefCounted

## What starts over between opponents in a stage with several of them (empty
## for a one-opponent stage). One short line that names only the exception
## (2026-10-21): "Everything starts over" for a committee, otherwise just the
## things that do, since the rest carries. Used by the level briefing; the
## Details panel's winning line already says the same in its own words.
static func for_stage(stage: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var carry := StageCarryOver.between_opponents(stage)
	if carry.is_empty():
		return lines
	if (carry["carries"] as Array).is_empty():
		lines.append(Text.say("briefing.between_all"))
		return lines
	var resource_words := {
		"support": Text.say("briefing.res_support"), "energy": Text.say("briefing.res_energy"),
		"gaffes": Text.say("briefing.res_gaffes"), "turns": Text.say("briefing.res_turns"),
		"guard": Text.say("briefing.res_guard"), "hand": Text.say("briefing.res_hand"),
	}
	var names: Array[String] = []
	for resource: String in carry["resets"]:
		names.append(str(resource_words[resource]))
	lines.append(Text.say("briefing.between_resets", {"things": ", ".join(names)}))
	return lines
