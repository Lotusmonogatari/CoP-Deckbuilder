extends Node
## A press conference shows what the reporters do (2026-11-04, Cameron: the
## tone dropped every turn with nothing on screen). Plays a real press
## conference (the first level that opens with one) through the real screen:
## before each turn the reporter's move is printed in the opponent row
## ("Attacking · −3"); after it, the banner names the reporter who asked and
## says what the move did, naming them.

var _failures: PackedStringArray = []


func _first_press_level() -> String:
	for level: Dictionary in DataDB.levels:
		var first := str(level.get("stage_1", ""))
		if str(DataDB.get_stage(first).get("bar_model", "")) == "Single":
			return str(level.get("level_id", ""))
	return ""


func _ready() -> void:
	var level_id := _first_press_level()
	if level_id.is_empty():
		_failures.append("no level opens with a press conference")
	else:
		await _check(level_id)

	print("")
	if _failures.is_empty():
		print("PRESS TEST: PASS")
		get_tree().quit(0)
	else:
		print("PRESS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check(level_id: String) -> void:
	GameState.start_new_run("PC01")
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_id))))
	var screen: Node = load("res://scenes/battle/BattleScreen.tscn").instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var engine: BattleEngine = screen.engine
	if not engine.is_press_conference():
		_failures.append("%s did not open with a press conference" % level_id)
		return
	var presenter: OpponentPresenter = screen.get("_speaker")
	if presenter == null:
		_failures.append("the battle screen has no opponent presenter")
		return
	var intent_label: Label = presenter._intent_label
	var banner: Node = screen.get("_banner")

	for turn in 3:
		if engine.state.is_over():
			break
		var expected := IntentRunner.describe(engine.current_intent(), Text.phrase())
		if intent_label.text != expected:
			_failures.append("turn %d: the row shows '%s', not the reporter's move '%s'"
				% [turn + 1, intent_label.text, expected])
		var asker := OpponentPresenter.question_speaker_name(engine)
		var queue: Array = banner.get("_queue")
		var before := queue.size()
		screen._on_end_turn()
		await get_tree().process_frame
		queue = banner.get("_queue")
		var said := false
		for i in range(before, queue.size()):
			var entry: Dictionary = queue[i]
			var text := "%s\n%s" % [entry.get("line", ""), entry.get("detail", "")]
			if str(entry.get("speaker", "")) == asker and text.contains(asker):
				said = true
		if not said:
			_failures.append("turn %d: nothing on the banner from %s says what the move did"
				% [turn + 1, asker])
