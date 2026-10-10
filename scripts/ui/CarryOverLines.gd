class_name CarryOverLines
extends RefCounted

## The "what resets between opponents" lines for a stage with several of them
## (empty for a one-opponent stage). Shared by the level briefing and the
## Details panel so both say the same thing.
static func for_stage(stage: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var carry := StageCarryOver.between_opponents(stage)
	if carry.is_empty():
		return lines
	var resource_words := {
		"support": Text.say("briefing.res_support"), "energy": Text.say("briefing.res_energy"),
		"gaffes": Text.say("briefing.res_gaffes"), "turns": Text.say("briefing.res_turns"),
		"guard": Text.say("briefing.res_guard"), "hand": Text.say("briefing.res_hand"),
	}
	for pair: Array in [["resets", "briefing.between_resets"], ["carries", "briefing.between_carries"]]:
		var names: Array[String] = []
		for resource: String in carry[pair[0]]:
			names.append(str(resource_words[resource]))
		if not names.is_empty():
			lines.append(Text.say(str(pair[1]), {"things": ", ".join(names)}))
	return lines
