class_name StageTransitionDriver
extends Node
## Walks the Stage Transition screen (CLAUDE.md section 7.9) with real data
## and a real click on Continue: a level reaching a stage whose Show
## Transition is Yes must open the transition, show a real speaker with a
## real line, and Continue must land on that stage's own battle.
##
## Added 2026-10-13: the screen had never been opened against real content
## (the three pools shipped empty), and the first wildcard row exposed that
## PoolPicker read a blank Stage ID as "<null>", so no wildcard ever matched.
## This test would have caught it.
##
## Skips (and says so) when the workbook turns no transition on, so it stays
## green while Cameron has not written any.

const BATTLE_SCENE_NAME := "BattleScreen"
const TRANSITION_SCENE_NAME := "StageTransitionScreen"
const ROUNDS := 2
const MAX_TARGETS := 8   # spread across the catalogue; every stage would take minutes

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var targets := _targets()
	if targets.is_empty():
		print("STAGE TRANSITION TEST: SKIP (no level has a later stage with Show Transition = Yes and written dialogue)")
		get_tree().quit(0)
		return
	for target: Dictionary in targets:
		for round_number in ROUNDS:
			await _check(target)
	print("")
	if _failures.is_empty():
		print("STAGE TRANSITION TEST: PASS (%d level(s) x %d rounds)" % [targets.size(), ROUNDS])
		get_tree().quit(0)
	else:
		print("STAGE TRANSITION TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


## One level per distinct combat stage that shows a transition after the
## first slot, thinned to MAX_TARGETS spread across the catalogue.
func _targets() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var seen_stage := {}
	for level: Dictionary in DataDB.levels:
		var expanded := BattleSetup.expand_level(level)
		var stages: Array = expanded.get("stages", [])
		for i in range(1, stages.size()):
			var stage: Dictionary = stages[i]
			var sid := str(stage.get("stage_id", ""))
			if StageTransition.should_show(stage) and not seen_stage.has(sid) \
					and str(stage.get("mode", "")) == "Combat":
				seen_stage[sid] = true
				found.append({"level_id": str(level.get("level_id", "")), "index": i, "stage_id": sid})
	# Spread the picks across the catalogue rather than testing every room.
	var step := maxi(1, found.size() / MAX_TARGETS)
	var spread: Array[Dictionary] = []
	for i in range(0, found.size(), step):
		spread.append(found[i])
	return spread


func _check(target: Dictionary) -> void:
	GameState.start_new_run("PC01")
	# Staff only speak once hired, so hire one of each role in memory.
	var cast_ids: Array = DataDB.transition_cast.map(
		func(row: Dictionary) -> String: return str(row.get("character_id", "")))
	for candidate in DataDB.staff:
		if str(candidate.get("staff_id", "")) in cast_ids:
			GameState.staff_hired[str(candidate.get("role", ""))] = {
				"staff_id": str(candidate.get("staff_id", "")), "tier": 0}
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(str(target["level_id"]))))
	GameState.begin_level(runner)
	runner.index = int(target["index"])
	var label := "%s / %s" % [target["level_id"], target["stage_id"]]

	StageRouting.go_to_next_stage(get_tree(), "res://nothing.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout

	var screen := get_tree().current_scene
	if screen == null or screen.name != TRANSITION_SCENE_NAME:
		_failures.append("%s: expected the transition screen, got %s" % [label, screen.name if screen else "(null)"])
		return
	var speaker_name: Label = screen.get_node("%SpeakerName")
	var portrait: PlaceholderArt = screen.get_node("%SpeakerPortrait")
	if not speaker_name.visible or speaker_name.text.is_empty() or not portrait.visible:
		_failures.append("%s: no speaker was shown (the pools resolved to nothing)" % label)
		return
	if screen.get_node_or_null("CueBanner") == null:
		_failures.append("%s: no cue banner on the transition screen" % label)
		return

	var button: Button = screen.get_node("%ContinueButton")
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var landed := get_tree().current_scene
	if landed == null or landed.name != BATTLE_SCENE_NAME:
		_failures.append("%s: Continue did not land on the battle (got %s)" % [label, landed.name if landed else "(null)"])
		return
	GameState.end_level()
