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
	await _check_two_speakers()
	await _check_continue_delay(targets[0])
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


## Continue is held back for the Balance delay when a stage's opening scene
## first appears (Cameron, 2026-11-06). verify.sh switches the delay off for
## every other test, so this one turns it back on for itself.
func _check_continue_delay(target: Dictionary) -> void:
	var delay := float(DataDB.balance.get("stage_continue_delay_seconds", 0))
	if delay <= 0.0:
		return
	OS.unset_environment("COP_NO_CONTINUE_DELAY")
	GameState.start_new_run("PC01")
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(str(target["level_id"]))))
	GameState.begin_level(runner)
	runner.index = int(target["index"])
	StageRouting.go_to_next_stage(get_tree(), "res://nothing.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var screen := get_tree().current_scene
	if screen == null or screen.name != TRANSITION_SCENE_NAME:
		_failures.append("continue delay: the transition screen did not open")
		OS.set_environment("COP_NO_CONTINUE_DELAY", "1")
		return
	var button: Button = screen.get_node("%ContinueButton")
	await get_tree().create_timer(delay * 0.4).timeout
	if not button.disabled:
		_failures.append("Continue was active before the %.0f second delay was over" % delay)
	await get_tree().create_timer(delay * 0.8).timeout
	if button.disabled:
		_failures.append("Continue was still inactive after the %.0f second delay" % delay)
	OS.set_environment("COP_NO_CONTINUE_DELAY", "1")
	GameState.end_level()


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

	var spoke := StageTransition.opponent_speakers(screen._speakers)
	var button: Button = screen.get_node("%ContinueButton")
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var landed := get_tree().current_scene
	if landed == null or landed.name != BATTLE_SCENE_NAME:
		_failures.append("%s: Continue did not land on the battle (got %s)" % [label, landed.name if landed else "(null)"])
		return
	_check_locked(label, spoke, landed)
	GameState.end_level()


## An opponent who spoke in the transition is the opponent in the battle that
## follows, seated in the order they spoke (2026-11-02).
func _check_locked(label: String, spoke: Array[String], battle: Node) -> void:
	var seated: Array = []
	for opponent: Variant in battle.engine._opponents:
		seated.append(str((opponent as Dictionary).get("opp_id", "")))
	for i in spoke.size():
		if i >= seated.size() or seated[i] != spoke[i]:
			_failures.append("%s: %s spoke in the transition but the battle seats %s" % [label, spoke[i], str(seated)])
			return


## Two speakers: both appear in turn, and both are the opponents who fight.
func _check_two_speakers() -> void:
	var target := {}
	for level: Dictionary in DataDB.levels:
		var stages: Array = BattleSetup.expand_level(level).get("stages", [])
		for i in range(1, stages.size()):
			if StageTransition.speaker_count(stages[i]) >= 2 and target.is_empty():
				target = {"level_id": str(level.get("level_id", "")), "index": i, "stage_id": str(stages[i].get("stage_id", ""))}
	if target.is_empty():
		print("  (no stage asks for two speakers; skipping that check)")
		return
	GameState.start_new_run("PC01")
	GameState.staff_hired = {}   # nobody hired, so both speakers are opponents
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(str(target["level_id"]))))
	GameState.begin_level(runner)
	runner.index = int(target["index"])
	var label := "two speakers, %s / %s" % [target["level_id"], target["stage_id"]]
	StageRouting.go_to_next_stage(get_tree(), "res://nothing.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout
	var screen := get_tree().current_scene
	if screen == null or screen.name != TRANSITION_SCENE_NAME:
		_failures.append("%s: no transition screen" % label)
		return
	var speakers: Array = screen._speakers
	if speakers.size() != 2:
		_failures.append("%s: %d speaker(s) drawn, wanted 2" % [label, speakers.size()])
		return
	var names: Array[String] = []
	var waited := 0.0
	while waited < 30.0 and screen._current_speaker_index < 1:
		if names.is_empty():
			names.append(screen.get_node("%SpeakerName").text)
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	if screen._current_speaker_index < 1:
		_failures.append("%s: the second speaker never stepped in" % label)
		return
	await get_tree().create_timer(0.9).timeout   # the first one slides out, the second slides in
	names.append(screen.get_node("%SpeakerName").text)
	if names[0] == names[1]:
		_failures.append("%s: the name under the portrait did not change (%s)" % [label, names[0]])
	var spoke := StageTransition.opponent_speakers(speakers)
	screen.get_node("%ContinueButton").pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var landed := get_tree().current_scene
	if landed == null or landed.name != BATTLE_SCENE_NAME:
		_failures.append("%s: Continue did not land on the battle" % label)
		return
	_check_locked(label, spoke, landed)
	print("  two speakers: %s then %s, both seated in the battle" % [names[0], names[1]])
	GameState.end_level()
