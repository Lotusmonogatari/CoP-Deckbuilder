class_name WhipFightDriver
extends Node
## Real clicks through the party whip (P15, 2026-11-23): the whip scene opens on its day with the whip the player's Party support
## picks, pushing back (choice C) starts "Whipped into Line" against that person with 6 energy and 3 turns, the fight is lost by
## passing, the Office tells the player the vote is locked, and the Floor Vote on the final bill has only the party-line button
## live, with the line "You gave the whip your word.".

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 3, "phase": "work", "hours": 8 * 4}   # Friday 18.10.26
	GameState.dated_events_done = ["EV47", "EV111"]
	var monday := WeekCalendar.parse_date("18.10.22")
	var thursday := WeekCalendar.parse_date("18.10.25")
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": monday, "choice": "A"},
		"DS03": {"day": thursday, "choice": "A"}, "DS05": {"day": thursday, "choice": "A"}, "DS06": {"day": thursday, "choice": "A"}}
	GameState.pending_activations = []
	GameState.whip_picks = {}
	GameState.whip_locks = {}
	var scene := DecisionScenes.find(DataDB.decision_scenes, "DS07")
	var picked := GameState.whip_pick_for(scene)
	var role := WhipPick.role_for(GameState.party_support_effective(), DataDB.rules.get("whip_bands", {}))
	print("  Party support %d -> the %s band -> %s" % [GameState.party_support_effective(), role, picked])
	_expect(not picked.is_empty(), "the party support picks a whip")
	var line := GameState.whip_line(scene)
	_expect(not line.is_empty(), "the player's party has a line on the final bill")
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	await _open_office()
	var office := get_tree().current_scene
	var panel := office.get_node("EventPanel") as Overlay
	_expect(panel.visible, "the whip scene opens by itself")
	_expect(panel.find_child("Speaker_" + picked, true, false) != null, "the picked whip is the speaker")
	_expect(_texts(panel).contains(Text.say("whip.aye" if line == WhipPick.YES else "whip.nay")), "the card says what the whip asks")
	await _click(panel.find_child("EventChoice_C", true, false))
	_expect(GameState.pending_activations.size() == 1, "pushing back starts a fight")
	await _click(panel.find_child("EventContinueButton", true, false))
	await get_tree().create_timer(0.4).timeout
	var briefing := office.get_node("%BriefingPanel") as Overlay
	_expect(briefing.visible, "Continue opens the fight's briefing")
	await _click(briefing.find_child("Confirm", true, false))
	await get_tree().create_timer(0.9).timeout
	_expect(GameState.is_in_level(), "Go in begins the fight")
	var screen := get_tree().current_scene
	_expect(screen.get("engine") != null, "the battle screen is up")
	if screen.get("engine") == null:
		_finish()
		return
	_expect(str(GameState.level_runner.current_stage().get("stage_id", "")) == "ST290", "it is Whipped into Line")
	var state = screen.engine.state
	_expect(str((screen.engine.current_opponent() as Dictionary).get("opp_id", "")) == picked, "against the whip that was picked")
	_expect(state.energy == 6 and state.energy_mode == "pool", "6 energy for the whole fight")
	_expect(screen.engine.turn_limit() == 3, "3 turns")
	_expect(state.bar.player == 12 and state.bar.threshold == 1, "Resolve starts at 12 and the line is 1")
	# Lose it. Passing alone is not a sure loss (the whip's attacks of 4 to 6 leave a passive player one or two Resolve about
	# two times in three), so the Resolve is spent and the turn is passed with a real click.
	state.bar.player = 0
	var guard := 0
	while not screen.engine.state.is_over() and guard < 6:
		guard += 1
		await _click(screen.get_node("%EndTurnButton"))
	print("  fight ended: %s, Resolve %d of line %d, turn %d (%s)" % [screen.engine.state.outcome, screen.engine.state.bar.player,
		screen.engine.state.bar.threshold, screen.engine.state.turn, screen.engine.state.outcome_reason])
	_expect(screen.engine.state.is_over() and screen.engine.state.outcome == "loss", "running out of Resolve loses the fight")
	await get_tree().create_timer(0.3).timeout
	await _click(screen.get_node("%OutcomeClose"))
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.vote_lock("BI52")["state"] == "locked", "the final vote is locked")
	_expect(GameState.vote_lock("BI52")["allowed"] == [line], "to the party line")

	# The final vote, with the lock.
	DataDB.register_runtime_level(DecisionScenes.ad_hoc_level("vote", "BI52", "Joining the CPTPP", "Capitol"))
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("DSL_vote_BI52")))
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout
	var vote := get_tree().current_scene
	var yes := vote.get_node("%VoteYes") as Button
	var no := vote.get_node("%VoteNo") as Button
	var abstain := vote.get_node("%VoteAbstain") as Button
	var live := {"Yes": not yes.disabled, "No": not no.disabled, "Abstain": not abstain.disabled}
	_expect(live[line] and (live.values() as Array).count(true) == 1, "only the party-line button is live (%s)" % str(live))
	var note := vote.find_child("WhipLockNote", true, false) as Label
	_expect(note != null and note.text == Text.say("floor_vote.whip_word"), "and the screen says why")
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	_finish()


func _texts(node: Node) -> String:
	var out := ""
	for child in node.find_children("*", "Label", true, false):
		out += (child as Label).text + "\n"
	return out


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _click(control: Variant) -> void:
	if not (control is Control):
		_failures.append("a control this test needed does not exist")
		return
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * (control as Control).get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("WHIP FIGHT TEST: PASS")
		get_tree().quit(0)
	else:
		print("WHIP FIGHT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
